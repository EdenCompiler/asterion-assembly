;;;; Carregador de desenvolvimento. Uso: sbcl --script run.lisp [pt|en] [seed]
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(pushnew (uiop:getcwd) asdf:*central-registry* :test #'equal)
(ql:quickload :asterion-assembly :silent t)
(let* ((args (uiop:command-line-arguments))
       (idioma (if (string-equal (or (first args) "en") "pt") :pt :en))
       (semente (or (and (second args) (parse-integer (second args) :junk-allowed t)) 1701)))
  (asterion-assembly:start :language idioma :seed semente))
