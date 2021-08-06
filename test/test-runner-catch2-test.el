;;; test-runner-catch2-test.el -- Unit test for test runner catch2 -*- lexical-binding: t; -*-

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

(require 'test-runner-catch2)

(defvar backend (test-runner-backend-catch2) "Backend to test against.")

(ert-deftest test-test-runner-catch2-section-args () ; nofmt
  (test-runner-catch2-with-test-buffer
   (search-forward "the size changes but not capacity")
   (end-of-line)
   (should
    (equal
     '("Scenario: vectors can be sized and resized" "--section" "Given: A vector with some items" "--section" "When: the size is reduced")
     (test-runner-backend-catch2-section-args backend nil 12)))))

(ert-deftest test-test-runner-backend-test-at-point () ; nofmt
  (test-runner-catch2-with-test-buffer
   (search-forward "the size changes but not capacity")
   (should
    (equal "make hello-world-test && hello-world-test --reporter compact Scenario\\:\\ vectors\\ can\\ be\\ sized\\ and\\ resized --section Given\\:\\ A\\ vector\\ with\\ some\\ items --section When\\:\\ the\\ size\\ is\\ reduced"
           (test-runner-backend-test-at-point backend)))))

(ert-deftest test-test-runner-backend-test-file () ; nofmt
  (test-runner-catch2-with-test-buffer
   (search-forward "the size changes but not capacity")
   (should
    (equal "make hello-world-test && hello-world-test --reporter compact -\\# \\[\\#app_test\\]"
           (test-runner-backend-test-file backend)))))

(ert-deftest test-test-runner-backend-test-project () ; nofmt
  (test-runner-catch2-with-test-buffer
   (search-forward "the size changes but not capacity")
   (should
    (equal "make hello-world-test && hello-world-test --reporter compact -\\#"
           (test-runner-backend-test-project backend)))))
(provide 'test-runner-catch2-test)

;;; test-runner-catch2-test.el ends here
