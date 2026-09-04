;;;; Gera um executável SBCL autocontido. A biblioteca SDL2 continua sendo nativa.
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(pushnew (uiop:getcwd) asdf:*central-registry* :test #'equal)
(ql:quickload :asterion-assembly :silent t)

(defun asterion-entrypoint ()
  (handler-case
      (let* ((args (uiop:command-line-arguments))
             (pt (member "--pt" args :test #'string=))
             (seguro (member "--safe-mode" args :test #'string=)))
        (asterion-assembly:start :language (if pt :pt :en) :safe-mode seguro)
        0)
    (error (e)
      (format *error-output* "Asterion Assembly encerrou com erro: ~A~%" e)
      1)))

(let ((saida (or (uiop:getenv "ASTERION_OUTPUT") "dist/asterion-assembly")))
  (ensure-directories-exist saida)
  (sb-ext:save-lisp-and-die saida :toplevel #'asterion-entrypoint
                                  :executable t :compression t
                                  :save-runtime-options t))
