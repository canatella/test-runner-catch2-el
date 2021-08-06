;; test-helper.el --- Test helpers for test-runner-catch2  -*- lexical-binding: t; -*-

;; Copyright (C) Nicolas Lamirault <nicolas.lamirault@gmail.com>

;; Copyright (C) 2014  Nicolas Lamirault

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

;;; Code:

(defconst test-runner-catch2-test-path
  (file-name-as-directory (file-name-directory (or load-file-name buffer-file-name)))
  "The test directory.")
(defconst test-runner-catch2-test-data-path
  (file-name-as-directory (concat test-runner-catch2-test-path "data"))
  "The test data directory.")
(defconst test-runner-catch2-root-path
  (file-name-as-directory (file-name-directory (directory-file-name test-runner-catch2-test-path)))
  "The test-runner-catch2 project root path.")
(add-to-list 'load-path test-runner-catch2-root-path)

(defmacro test-runner-catch2-with-test-content (file-name &rest body)
  "Setup a buffer backing FILE-NAME with CONTENT and run BODY in it."
  (declare (indent 1))
  `(let ((file-path (concat test-runner-catch2-test-data-path ,file-name)))
     (unless (file-exists-p file-path) (error "File %s does not exists" file-path))
     (save-excursion
       (with-current-buffer (find-file-noselect file-path)
         (goto-char (point-min))
         ,@body
         (kill-buffer)))))

(defmacro test-runner-catch2-with-test-buffer (&rest body)
  "Setup a buffer with our test data and run BODY in it."
  (declare (indent 0))
  `(let ((test-runner-catch2-executable "hello-world-test")
         (compile-command "make hello-world-test"))
     (test-runner-catch2-with-test-content "tests/app_test.cpp"
                                           (require 'test-runner-catch2)
                                           ,@body)))
(provide 'test-helper)
;;; test-helper.el ends here
