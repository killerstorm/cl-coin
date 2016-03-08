;;;; cl-coin.asd

(asdf:defsystem #:cl-coin
  :serial t
  :description "Bitcoin utilities for Common Lisp"
  :author "Alex Mizrahi  <alex.mizrahi@gmail.com>"
  :license "MIT"
  :depends-on (#:ironclad
               #:com.gigamonkeys.binary-data)
  :components ((:file "package")
               (:file "cl-coin")))
