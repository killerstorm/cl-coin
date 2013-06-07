;;;; package.lisp

(defpackage #:cl-coin
  (:use #:cl)
  (:import-from :com.gigamonkeys.binary-data 
                #:read-value
                #:write-value
                #:define-binary-type
                #:define-binary-class))

