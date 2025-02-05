(in-package #:cl-jupyter)

#|

# The stdin dealer socket #

See: http://jupyter-client.readthedocs.org/en/latest/messaging.html#messages-on-the-stdin-router-dealer-sockets

|#

(defclass stdin-channel ()
  ((kernel :initarg :kernel :reader stdin-kernel)
   (socket :initarg :socket :initform nil :accessor stdin-socket)))

(defun make-stdin-channel (kernel)
  (let ((socket (pzmq:socket (kernel-ctx kernel) :dealer)))
    (let ((stdin (make-instance 'stdin-channel
                                :kernel kernel
                                :socket socket)))
      (let ((config (slot-value kernel 'config)))
        (let ((endpoint (format nil "~A://~A:~A"
                                  (config-transport config)
                                  (config-ip config)
                                  (config-stdin-port config))))
          (format t "stdin endpoint is: ~A~%" endpoint)
          (pzmq:bind socket endpoint)
          (setf (slot-value kernel 'stdin) stdin)
          stdin)))))

#|

### Message type: input_request ###

|#

(defclass content-input-request (message-content)
  ((prompt :initarg :prompt :type string)
   (password :initarg :password :type boolean)))

(defmethod encode-json (stream (object content-input-request) &key (indent nil) (first-line nil))
  (with-slots (prompt password) object
    (encode-json stream `(("prompt" . ,prompt)
                          ("password" . ,password))
                 :indent indent :first-line first-line)))

(defclass content-input-reply (message-content)
  ((value :initarg :value :type string)))

(defmethod encode-json (stream (object content-input-reply) &key (indent nil) (first-line nil))
  (with-slots (value) object
    (encode-json stream `(("value" . ,value))
                 :indent indent :first-line first-line)))

(defun handle-input-reply (stdin identities msg buffers)
  (format t "[stdin] handling 'input_reply'~%")

  ;; AT THIS POINT NEED TO HAND OFF VALUE TO ASKSIGN OR WHATEVER
  ;; CAUSED INPUT_REQUEST TO BE SENT !!
)

(defun send-input-request (stdin parent-msg prompt)
  (let ((message (make-message parent-msg "input_request" nil `(("prompt" . ,prompt)))))
    (message-send (stdin-socket stdin) message :identities '("input_request"))))

