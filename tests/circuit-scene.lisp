;;;; Cena para entrada real via X virtual; não grava saves do jogador.
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(pushnew (uiop:getcwd) asdf:*central-registry* :test #'equal)
(ql:quickload :asterion-assembly :silent t)
(asterion-assembly::preparar :safe-mode t)
(setf asterion-assembly::*pular-menu-principal* t)
(let* ((w (asterion-assembly:new-game :difficulty :peaceful))
       (sensor (antigonus:place-building w :circuit-sensor -6 -1))
       (c (antigonus:place-building w :arithmetic-combinator -3 -1))
       (lampada (antigonus:place-building w :signal-lamp 0 -1)))
  (antigonus:inventory-add (antigonus:building-inventory sensor) :iron-plate 100)
  (antigonus:configure-circuit-device c
    (antigonus:make-circuit-device-config :behavior :arithmetic
      :input-signal '(:item :iron-plate) :operator :/ :constant 10
      :output-signal '(:virtual :signal-check)))
  (antigonus:run-game
    (antigonus:define-game :title "Asterion Assembly - circuit playtest"
      :start #'asterion-assembly::iniciar-mundo :update #'asterion-assembly::atualizar
      :render #'asterion-assembly::renderizar :input #'asterion-assembly::entrada
      :shutdown (lambda (m)
                  (assert (= 2 (length (antigonus:circuit-connections m))))
                  (assert (getf (antigonus:building-state lampada) :lamp-active))
                  (assert (eq :blue (getf (antigonus:building-state lampada) :lamp-color)))
                  (assert (= 25 (getf (antigonus:building-state lampada) :lamp-intensity)))
                  (format t "~&CIRCUIT INPUT OK~%"))) :world w))
