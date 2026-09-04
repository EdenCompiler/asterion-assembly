;;;; Cena determinística usada pelo playtest gráfico em X virtual.
(load (merge-pathnames "quicklisp/setup.lisp" (user-homedir-pathname)))
(pushnew (uiop:getcwd) asdf:*central-registry* :test #'equal)
(ql:quickload :asterion-assembly :silent t)

(asterion-assembly::preparar :safe-mode t)
(antigonus:set-language :en)
(setf asterion-assembly::*categoria-ui* :all
      asterion-assembly::*mostrar-catalogo* t
      asterion-assembly::*indice-selecao* 0
      asterion-assembly::*pular-menu-principal* t)

(let* ((mundo (asterion-assembly:new-game :seed 1701 :difficulty :peaceful))
       (minerador (antigonus:place-building mundo :miner -4 -4))
       (braco (antigonus:place-building mundo :inserter -3 -4 :rotation 0))
       (esteira (antigonus:place-building mundo :belt -2 -4 :rotation 0))
       (forno (antigonus:place-building mundo :stone-furnace -1 -4
                                        :recipe :smelt-iron)))
  (declare (ignore braco esteira forno))
  ;; Três mineradores e suas esteiras reproduzem a primeira fábrica real do
  ;; jogador e mantêm o playtest acima do antigo limiar incorreto de 20 MW.
  (dolist (y '(-2 0))
    (antigonus:place-building mundo :miner -4 y)
    (loop for x from -3 to -1 do
      (antigonus:place-building mundo :belt x y :rotation 0)))
  (let ((divisor (antigonus:place-building mundo :splitter 2 -2 :rotation 0)))
    (antigonus:place-building mundo :belt 3 -2 :rotation 0)
    (antigonus:place-building mundo :belt 2 -1 :rotation 1)
    (antigonus:inventory-add (antigonus:building-inventory divisor) :copper-ore 6))
  ;; Galeria 2.0: garante que cada célula do novo atlas seja renderizada no
  ;; backend real, incluindo transparência, culling e ícones sem animação.
  (loop for kind in '(:underground-belt :filter-splitter :stack-inserter :loader
                      :boiler :directional-pump :circuit-sensor
                      :arithmetic-combinator :decider-combinator :chain-signal
                      :curved-rail :diagonal-crossing :construction-roboport
                      :logistics-roboport :scrubber :supply-depot)
        for indice from 0 do
          (antigonus:place-building mundo kind (+ 4 (mod indice 4))
                                    (+ -4 (floor indice 4))))
  (antigonus:inventory-add (antigonus:building-inventory minerador) :iron-ore 20)
  (antigonus:spawn-entity mundo :crawler 5.5 1.5 :hp 90 :data '(:playtest t))
  (antigonus:run-game (asterion-assembly::configurar) :world mundo))
