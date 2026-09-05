;;;; Configurações por eventos SDL reais; perfil e saves exclusivos do teste.
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(pushnew (uiop:getcwd) asdf:*central-registry* :test #'equal)
(ql:quickload :asterion-assembly :silent t)
(asterion-assembly::preparar :safe-mode t)
(let ((pronto nil))
(antigonus:run-game
 (antigonus:define-game
  :title "Asterion settings playtest"
  :start (lambda (w)
           (asterion-assembly::iniciar-mundo w)
           (setf asterion-assembly::*tela-ui* :settings))
  :update #'asterion-assembly::atualizar
  :render (lambda (w alpha)
            (asterion-assembly::renderizar w alpha)
            (unless pronto (setf pronto t) (format t "~&SETTINGS READY~%") (finish-output)))
  :input #'asterion-assembly::entrada
  :shutdown (lambda (w)
              (declare (ignore w))
              (assert (equal asterion-assembly::*resolucao-configurada* '(1600 900)))
              (assert asterion-assembly::*tela-cheia-configurada*)
              (assert (= 9/10 asterion-assembly::*escala-ui-configurada*))
              (assert asterion-assembly::*paleta-configurada*)
              (assert (zerop (antigonus:audio-bus-volume :effects)))
              (assert (= 128 (antigonus:audio-bus-volume :alerts)))
              (let ((dados (asterion-assembly::dados-configuracoes)))
                (asterion-assembly::carregar-configuracoes)
                (assert (equal dados (asterion-assembly::dados-configuracoes))))
              (format t "~&SETTINGS INPUT OK~%")))
 :world (asterion-assembly:new-game :difficulty :peaceful)))
