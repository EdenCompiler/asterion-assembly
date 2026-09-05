;;;; Gamepad virtual na SDL real, incluindo hotplug, botões, eixos e remoção.
;;;; A cena prepara os dispositivos; não representa uma primeira hora humana.
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(pushnew (uiop:getcwd) asdf:*central-registry* :test #'equal)
(ql:quickload :asterion-assembly :silent t)
(asterion-assembly::preparar :safe-mode t)
(setf asterion-assembly::*pular-menu-principal* t)
(ensure-directories-exist "build/controller-playtest/frame.ppm")
(let* ((w (asterion-assembly:new-game :difficulty :peaceful))
       (sensor (antigonus:place-building w :circuit-sensor -2 -1))
       (lampada (antigonus:place-building w :signal-lamp 1 -1))
       (quadro 0) (indice nil) (joystick nil) (cursor-anterior 0) (removido nil))
  (antigonus:configure-circuit-device lampada (antigonus:make-circuit-device-config :behavior :lamp))
  (labels ((botao (id valor)
             (assert (zerop (cffi:foreign-funcall "SDL_JoystickSetVirtualButton"
                             :pointer joystick :int id :uint8 valor :int))))
           (cursor (predio)
             (multiple-value-setq (asterion-assembly::*cursor-gamepad-x*
                                  asterion-assembly::*cursor-gamepad-y*)
               (antigonus:world-to-screen
                (asterion-assembly::posicao-porta-x predio :main)
                (asterion-assembly::posicao-porta-y predio)))))
    (unwind-protect
         (antigonus:run-game
          (antigonus:define-game
           :title "Asterion SDL controller playtest" :start #'asterion-assembly::iniciar-mundo
           :update #'asterion-assembly::atualizar
           :input (lambda (m tipo &rest dados)
                    (when (eq tipo :controller-disconnected) (setf removido t))
                    (apply #'asterion-assembly::entrada m tipo dados))
           :render
           (lambda (m alpha)
             (incf quadro)
             (case quadro
               (1 (setf indice (cffi:foreign-funcall "SDL_JoystickAttachVirtual"
                                :int 1 :int 4 :int 15 :int 0 :int))
                  (assert (>= indice 0))
                  (assert (sdl2:game-controller-p indice))
                  (setf joystick (cffi:foreign-funcall "SDL_JoystickOpen" :int indice :pointer))
                  (assert (not (cffi:null-pointer-p joystick))))
               (8 (botao 3 1)) (10 (botao 3 0))
               (15 (assert asterion-assembly::*modo-circuito*) (cursor sensor))
               (20 (botao 0 1)) (22 (botao 0 0))
               (30 (cursor lampada)) (32 (botao 0 1)) (34 (botao 0 0))
               (38 (assert (= 1 (length (antigonus:circuit-connections m)))))
               (40 (botao 9 1)) (42 (botao 9 0))
               (50 (assert (= 1 asterion-assembly::*pagina-dispositivo-circuito*))
                   (setf asterion-assembly::*cursor-gamepad-x* (- (antigonus:screen-width) 50)))
               (52 (botao 0 1)) (54 (botao 0 0))
               (60 (botao 13 1)) (62 (botao 13 0))
               (64 (botao 0 1)) (66 (botao 0 0))
               (70 (assert (eq :blue (getf (antigonus:building-state lampada) :lamp-color)))
                   (assert (zerop (getf (antigonus:building-state lampada) :lamp-intensity))))
               (75 (setf cursor-anterior asterion-assembly::*cursor-gamepad-x*)
                   (assert (zerop (cffi:foreign-funcall "SDL_JoystickSetVirtualAxis"
                                   :pointer joystick :int 2 :int16 -20000 :int))))
               (85 (assert (< asterion-assembly::*cursor-gamepad-x* cursor-anterior))
                   (cffi:foreign-funcall "SDL_JoystickClose" :pointer joystick :void)
                   (setf joystick nil)
                   (assert (zerop (cffi:foreign-funcall "SDL_JoystickDetachVirtual" :int indice :int)))
                   (setf indice nil))
               (95 (assert removido)
                   (assert (every #'zerop asterion-assembly::*eixos-gamepad*))
                   (assert (not asterion-assembly::*gamepad-ativo*))))
             (asterion-assembly::renderizar m alpha)
             (when (= quadro 100)
               (antigonus:capture-renderer "build/controller-playtest/frame.ppm")
               (format t "~&SDL CONTROLLER INPUT OK~%") (antigonus:stop-game))))
          :world w)
      ;; A SDL já encerrou na saída de RUN-GAME; os handles são fechados no
      ;; quadro 85. Falhas anteriores deixam a SDL liberar os dispositivos.
      )))
