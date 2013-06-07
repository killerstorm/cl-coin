;;;; cl-coin.lisp

(in-package #:cl-coin)

(define-binary-type u4/le ()
  (:reader (in)
           (nibbles:read-ub32/le in))
  (:writer (out value)
           (nibbles:write-ub32/le value out)))


(define-binary-type u8/le ()
  (:reader (in)
           (nibbles:read-ub64/le in))
  (:writer (out value)
           (nibbles:write-ub64/le value out)))


(define-binary-type varint ()
  (:reader (in)
           (let ((byte (read-byte in)))
             (cond
               ((< byte #xFD)
                byte)
               ((= byte #xFD)
                (nibbles:read-ub16/le in))
               ((= byte #xFF)
                (nibbles:read-ub32/le in))
               ((= byte #xFF)
                (nibbles:read-ub64/le in))
               (t (error "wtf")))))
  (:writer (out value)
           (cond
             ((< value #xFD)
              (write-byte value out))
             ((< value #xFFFF)
              (write-byte #xFD out)
              (nibbles:write-ub16/le value out))
             ((< value #xFFFFFFFF)
              (write-byte #xFE out)
              (nibbles:write-ub32/le value out))
             ((< value #xFFFFFFFFFFFFFFFF)
              (write-byte #xFF out)
              (nibbles:write-ub64/le value out))
             (t (error "value too large")))))

(define-binary-type blob (bytes)
  (:reader (in)
           (let ((seq (make-array (list bytes) :element-type '(unsigned-byte 8) :initial-element 0)))
             (read-sequence seq in)
             seq))
  (:writer (out seq)
           (write-sequence seq out)))

(define-binary-type lp-blob ()
  (:reader (in)
           (let ((size (read-value 'varint in)))
             (read-value 'blob in :bytes size)))
  (:writer (out blob)
           (write-value 'varint out (length blob))
           (write-value 'blob out blob :bytes (length blob))))

(define-binary-type opcode ()
  (:reader (in)
           (let ((byte (read-byte in)))
             (cond
               ((<= 1 byte 75)
                (cons byte 
                      (read-value 'blob in :bytes byte)))
               ((= byte 76)
                (let ((sz (read-byte in)))
                  (cons byte
                        (read-value 'blob in :bytes sz))))
               ((= byte 77)
                (let ((sz (nibbles:read-ub16/le in)))
                  (cons byte 
                        (read-value 'blob in :bytes sz))))
               ((= byte 78)
                (let ((sz (nibbles:read-ub32/le in)))
                  (cons byte
                        (read-value 'blob in :bytes sz))))
               (t byte))))
  (:writer (out value)
           (etypecase value
               (cons (destructuring-bind (opcode . vector)
                         value
                       (write-byte opcode out)
                       (cond
                         ((<= 1 opcode 75)
                          (write-value 'blob out vector))
                         ((= opcode 76)
                          (write-byte (length vector) out)
                          (write-value 'blob out vector))
                         ((= opcode 77)
                          (nibbles:write-ub16/le (length vector) out)
                          (write-value 'blob out vector))
                         ((= opcode 78)
                          (nibbles:write-ub32/le (length vector) out)
                          (write-value 'blob out vector))
                         (t (error "wtf")))))
             (integer (write-byte value out)))))

(define-binary-type script ()
  (:reader (in)
           (let ((bytes (read-value 'lp-blob in)))
             (let ((sin (ironclad:make-octet-input-stream bytes)))
               (loop while (< (ironclad::index sin) (ironclad::end sin))
                  collect (read-value 'opcode sin)))))
  (:writer (out value)
           (let ((sout (ironclad:make-octet-output-stream)))
             (dolist (op value)
               (write-value 'opcode sout op))
             (let ((oct (ironclad:get-output-stream-octets sout)))
               (write-value 'lp-blob out oct)))))



(define-binary-class tx-in ()
  ((prevout-hash (blob :bytes 32))
   (prevput-index u4/le)
   (script script)
   (seq u4/le)))

(define-binary-class tx-out ()
  ((value u8/le)
   (script script)))

(define-binary-type many (type)
  (:reader (in)
           (let ((n (read-value 'varint in)))
             (loop for i from 1 to n
                collect (read-value type in))))
  (:writer (out inps)
           (write-value 'varint out (length inps))
           (dolist (i inps)
             (write-value type out i))))

(define-binary-class transaction ()
  ((version u4/le)
   (inputs (many :type 'tx-in))
   (outputs (many :type 'tx-out))
   (lock-time u4/le)))
   

(defun test-parse-tx ()
  (let ((s (ironclad:make-octet-input-stream 
            (ironclad:hex-string-to-byte-array 
             "01000000010c432f4fb3e871a8bda638350b3d5c698cf431db8d6031b53e3fb5159e59d4a9000000006b48304502201123d735229382f75496e84ae5831871796ef78726805adc2c6edd36d23e7210022100faceab822a4943309c4b6b61240ae3a9e18ed90a75117c5dc4bfd8f7e17a21d301210367ce0a1c3b3e84cece6dad1a181d989d8e490b84f5431a1f778a88b284c935e6ffffffff0100f2052a010000001976a9143744841e13b90b4aca16fe793a7f88da3a23cc7188ac000000007822dda72d9bf421d2f3eedc678bf58c6e4c10cdd047b9e137559ad384933ef5"))))
    (read-value 'transaction s)))
