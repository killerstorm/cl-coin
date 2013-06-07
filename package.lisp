;;;; package.lisp

(defpackage #:cl-coin
  (:use #:cl)
  (:import-from :com.gigamonkeys.binary-data 
                #:define-binary-type
                #:define-binary-class))

