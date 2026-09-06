;;;; Falhas na thread gráfica devem voltar ao chamador e permitir nova janela.
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(pushnew (uiop:getcwd) asdf:*central-registry* :test #'equal)
(ql:quickload :antigonus :silent t)
(define-condition falha-grafica-de-teste (error) ())
(antigonus:register-sprite-sheet :recovery "assets/sprites/circuits-v3.png" 4 4)
(antigonus:register-sound :recovery "assets/audio/alarm-warning.wav")
(let ((capturada nil) (encerrada nil) (reaberta nil))
  (handler-case
      (antigonus:run-game
       (antigonus:define-game :title "Antigonus error propagation test"
         :render (lambda (w alpha) (declare (ignore w alpha))
                   (antigonus:draw-sprite :recovery 0 0 0 64 64)
                   (antigonus:play-sound :recovery)
                   (error 'falha-grafica-de-teste))
         :shutdown (lambda (w) (declare (ignore w)) (setf encerrada t))))
    (falha-grafica-de-teste () (setf capturada t)))
  (assert capturada)
  (assert encerrada)
  (assert (not antigonus::*executando*))
  (assert (null (antigonus::sprite-sheet-texture (gethash :recovery antigonus::*folhas-sprites*))))
  (assert (null (getf (gethash :recovery antigonus::*sons*) :chunk)))
  (antigonus:run-game
   (antigonus:define-game :title "Antigonus recovery test"
     :render (lambda (w alpha) (declare (ignore w alpha))
               (antigonus:draw-sprite :recovery 0 0 0 64 64)
               (antigonus:play-sound :recovery)
               (setf reaberta t) (antigonus:stop-game))))
  (assert reaberta)
  (format t "~&SDL FAILURE PROPAGATION AND RECOVERY OK~%"))
