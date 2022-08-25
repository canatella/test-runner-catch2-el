;;; test-runner-catch2.el --- Test runner for catch2 -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Damien Merenne <dam@cosinux.org>

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(require 'test-runner)
(require 'subr-x)

(defgroup test-runner-catch2 nil "Running catch2 tests from emacs." :group 'test-runner)

(defcustom test-runner-catch2-executable nil "Executable for running project catch2 tests."
  :group 'test-runner-catch2
  :type 'file
  :local t)

(defvar test-runner-catch2-section-types
  '(("SCENARIO" . scenario)
    ("SCENARIO_METHOD" . scenario)
    ("TEST_CASE" . test-case)
    ("TEST_CASE_METHOD" . test-case)
    ("SECTION" . section)
    ("GIVEN" . given)
    ("AND_GIVEN" . and-given)
    ("WHEN" . when)
    ("AND_WHEN" . and-when))
  "List of catch2 section macro and the corresponding Lisp type.")

(defun test-runner-catch2-beginning-of-section-regexp ()
  "Regular expression for a c++ catch2 test section."
  (format
   "^\\([[:space:]]*\\)\\(%s\\) *(\\([^\",]+,\\)?[[:space:]\n]*\"\\([^\"]+\\)\"\\(,[[:space:]\n]*\"\\([^\"]+\\)\"\\)?"
   (string-join (seq-map #'car test-runner-catch2-section-types) "\\|")))

(defun test-runner-catch2-section-type (macro)
  "Return section type for MACRO."
  (alist-get macro test-runner-catch2-section-types nil nil #'string=))

(defun test-runner-catch2-previous-section (indent)
  "Find the previous catch2 description with indent less than INDENT."
  (when (re-search-backward (test-runner-catch2-beginning-of-section-regexp) nil t)
    (let ((i (length (match-string 1)))
          (type (test-runner-catch2-section-type (match-string 2)))
          (descr (substring-no-properties (match-string 4)))
          (supl
           (when (match-string 5) (substring-no-properties (match-string 6)))))
      (if (< i indent)
          (if supl
              (list type (list descr supl) i)
            (list type (list descr) i))
        (if (> indent 0) (test-runner-catch2-previous-section indent))))))

(defun test-runner-catch2-find-path (&optional path indent)
  "Return the test description path, accumulating PATH and INDENT."
  (let ((max-lisp-eval-depth 2000)
        (previous (test-runner-catch2-previous-section (or indent 1000))))
    (if previous
        (test-runner-catch2-find-path
         (cons (cons (car previous) (cadr previous)) path)
         (caddr previous))
      path)))

(defclass test-runner-backend-catch2 (test-runner-backend-compile) ())

(cl-defmethod test-runner-backend-catch2-section-type ((_backend test-runner-backend-catch2)
                                                       macro)
  "Return section type for MACRO."
  (alist-get macro test-runner-catch2-section-types nil nil #'string=))

(cl-defmethod test-runner-backend-exec-binary ((_backend test-runner-backend-catch2))
  "Return the executable to run catch2 tests."
  (unless test-runner-catch2-executable (user-error "`test-runner-catch2-executable' is not set"))
  test-runner-catch2-executable)

(cl-defmethod test-runner-backend-catch2-option ((_backend test-runner-backend-catch2)
                                                 type title extra-arg)
  "Return Catch2 --section argument for section TYPE with TITLE and EXTRA-ARG.

This functions works by looking up the type in
`test-runner-catch2-section-types'.  If the lookup value is one of
the default symbol `scenario', `test-case', `section', `given',
`and-given', `when', `and-when', `then', `and-then', then it will
return a `--section' Catch2 command line argument to select the
matching scetion.  If the lookup value is a function, it will call
that function to get the argument to pass to the Catch2
executable.  This can be use to handle user defined Catch2 like
macros."
  (cond
   ((eq type 'scenario)
    (list (format "Scenario: %s" title)))
   ((eq type 'test-case)
    (list title))
   ((eq type 'section)
    (list "--section" title))
   ((eq type 'given)
    (list "--section" (format "Given: %s" title)))
   ((eq type 'and-given)
    (list "--section" (format "And given: %s" title)))
   ((eq type 'when)
    (list "--section" (format "When: %s" title)))
   ((eq type 'and-when)
    (list "--section" (format "And when: %s" title)))
   ((eq type 'then)
    (list "--section" (format "Then: %s" title)))
   ((eq type 'and-then)
    (list "--section" (format "And then: %s" title)))
   ((functionp type)
    (let ((options (funcall type title extra-arg)))
      (unless (listp options)
        (user-error "Catch2 option type function must return a list of strings"))
      options))))

(cl-defmethod test-runner-backend-exec-command ((backend test-runner-backend-catch2)
                                                &rest arguments)
  "Return catch2 BACKEND command with ARGUMENTS.

If `compile-command' is set, it will first run it to compile the executable."
  (apply #'cl-call-next-method backend `("--reporter" "console" ,@arguments)))

(cl-defmethod test-runner-backend-catch2-section-args ((backend test-runner-backend-catch2)
                                                       args indent)
  "Return list of --section arguments for running test at point with BACKEND.

This function uses indent to establish hierarchy of Catch2
sections.  This is not very robust but works in practice.

ARGS is the already collected list of arguments.

INDENT is the current section indentation level and is used to
determine if the current section is a children."
  ;; Lookup the previous section.
  (when (re-search-backward (test-runner-catch2-beginning-of-section-regexp) nil t)
    ;; Extract section type, title and extra argument.
    (let ((i (length (match-string 1)))
          (type (test-runner-backend-catch2-section-type backend (match-string 2)))
          (title (substring-no-properties (match-string 4)))
          (extra-arg
           (when (match-string 5) (substring-no-properties (match-string 6)))))
      ;; If indent is smaller, it means it is indeed a parent section
      (if (< i indent)
          (let ((parent (test-runner-backend-catch2-section-args backend args i))
                (option (test-runner-backend-catch2-option backend type title extra-arg)))
            (unless (listp option) (error "Catch2 backend option should be a list"))
            (append parent option))
        ;; If it is not a parent section and indent is not 0, continue looking up for parent section
        (if (> indent 0) (test-runner-backend-catch2-section-args backend args indent))))))

(cl-defmethod test-runner-backend-exec-arguments-test-at-point ((backend test-runner-backend-catch2))
  "Return catch2 BACKEND command to run the test at point."
  (save-excursion (end-of-line) (test-runner-backend-catch2-section-args backend nil 1000)))

(cl-defmethod test-runner-backend-exec-arguments-test-file ((backend test-runner-backend-catch2))
  "Return catch2 BACKEND command to run the tests in file."
  `("-#" ,(format "[#%s]" (file-name-base (buffer-file-name)))))

(cl-defmethod test-runner-backend-exec-arguments-test-project ((backend test-runner-backend-catch2))
  "Return catch2 BACKEND command to run the tests in project."
  '("-#"))

(test-runner-define-compilation-mode catch2)

(provide 'test-runner-catch2)

;;; test-runner-catch2.el ends here
