;;;; Asterion Assembly — jogo completo de demonstração comercial da Antigonus.
;;;; O código do jogo é pt-BR; chamadas públicas da engine permanecem em inglês.

(defpackage #:asterion-assembly
  (:use #:cl #:antigonus)
  (:export #:start #:new-game #:headless-demo #:register-content))
(in-package #:asterion-assembly)

(defconstant +tamanho-celula+ 32)
(defconstant +ticks-autosave+ 9000)
(defparameter *raiz* (uiop:ensure-directory-pathname
                      (or (uiop:getenv-pathname "ASTERION_ROOT") (uiop:getcwd))))
(defparameter *selecionados*
  #(:belt :fast-belt :splitter :inserter :long-inserter :miner :stone-furnace
    :electric-furnace :assembler :chemical-plant :refinery :pipe :pump :tank
    :power-pole :solar-panel :accumulator :steam-generator :laboratory :roboport
    :logistic-chest :rail :rail-signal :station :wall :gun-turret :laser-turret
    :rocket-turret :plasma-turret :radar :repair-bay :hive-launcher
    :underground-belt :filter-splitter :stack-inserter :loader :boiler
    :directional-pump :circuit-sensor :arithmetic-combinator :decider-combinator
    :chain-signal :curved-rail :diagonal-crossing :construction-roboport
    :logistics-roboport :scrubber :supply-depot))
(defvar *indice-selecao* 0)
(defvar *zoom* 1.0)
(defvar *rotacao-construcao* 0)
(defvar *indice-receita* 0)
(defparameter *receitas-selecionaveis*
  #(:smelt-iron :smelt-copper :smelt-stone :smelt-steel :make-glass :wire :gear
    :pipe-item :circuit :advanced-circuit :processor :battery :plastic :sulfur
    :fuel :lubricant :engine :electric-engine :rail-part :signal-part
    :drone-frame :logistic-drone :repair-pack :magazine :piercing-magazine
    :rocket :plasma-cell :hive-charge :wall-part :solar-cell :accumulator-cell
    :science-red :science-green :science-blue :science-purple))
(defvar *mostrar-ajuda* t)
(defvar *mostrar-estatisticas* nil)
(defvar *mostrar-catalogo* t)
(defvar *categoria-ui* :all)
(defvar *pagina-catalogo* 0)
(defvar *cursor-gamepad-x* 640.0)
(defvar *cursor-gamepad-y* 360.0)
(defvar *eixos-gamepad* (make-array 4 :initial-element 0.0))
(defvar *tela-ui* :main-menu)
(defvar *retorno-configuracoes* :main-menu)
(defvar *indice-menu* 0)
(defvar *sessao-iniciada* nil)
(defvar *pular-menu-principal* nil)
(defvar *semente-atual* 1701)
(defvar *dificuldade-atual* :standard)
(defvar *reduzir-flashes* t)
(defvar *volume-configurado* 96)
(defvar *mensagem-menu* "")
(defvar *indice-tecnologia* 0)
(defvar *arrasto-construcao* nil)
(defvar *ultima-celula-arrasto* nil)
(defparameter *construcoes-arrastaveis*
  '(:belt :fast-belt :pipe :rail :wall :power-pole))
(defparameter *ordem-tecnologias*
  #(:automation :logistics :steel :electricity :defense :fluids :oil :solar
    :advanced-circuits :railway :rail-signals :systems-science :laser-defense
    :drones :logistic-network :advanced-smelting :rocketry :crystal-science
    :plasma :rail-capacity :factory-speed-1 :factory-speed-2
    :military-logistics :hive-assault :bulk-logistics :fluid-pressure
    :power-storage :circuit-networks :automated-trains :chain-signals
    :remote-construction :ecological-industry :restoration :artillery-support
    :megabase-logistics :planetary-stewardship))

(defun dado (mundo chave &optional padrao)
  (gethash chave (world-game-data mundo) padrao))
(defun (setf dado) (valor mundo chave &optional padrao)
  (declare (ignore padrao)) (setf (gethash chave (world-game-data mundo)) valor))

(defun registrar-itens ()
  (dolist (i '((:iron-ore "Iron ore" 200 (138 160 177))
               (:copper-ore "Copper ore" 200 (218 124 83))
               (:stone "Stone" 200 (151 139 130)) (:coal "Carbon" 200 (65 69 82))
               (:silica "Silica" 200 (196 221 226)) (:oil "Crude oil" 500 (36 29 49))
               (:water "Water" 500 (54 151 212)) (:asterion-crystal "Asterion crystal" 100 (128 255 218))
               (:iron-plate "Iron plate" 200 (180 198 209)) (:copper-plate "Copper plate" 200 (237 146 91))
               (:steel-plate "Steel plate" 100 (111 133 148)) (:glass "Glass" 100 (154 235 237))
               (:stone-brick "Stone brick" 200 (148 99 90)) (:copper-wire "Copper wire" 300 (244 167 90))
               (:gear "Gear" 200 (165 183 194)) (:pipe "Pipe" 200 (148 177 176))
               (:circuit "Circuit" 200 (85 218 142)) (:advanced-circuit "Advanced circuit" 100 (255 91 123))
               (:processor "Processor" 100 (106 208 255)) (:battery "Battery" 100 (89 222 187))
               (:plastic "Bioplastic" 200 (224 229 238)) (:sulfur "Sulfur" 200 (241 213 79))
               (:lubricant "Lubricant" 500 (101 204 96)) (:fuel "Refined fuel" 100 (238 102 73))
               (:science-red "Analysis pack" 100 (244 82 92)) (:science-green "Logistics pack" 100 (90 226 143))
               (:science-blue "Systems pack" 100 (75 181 245)) (:science-purple "Quantum pack" 100 (189 110 255))
               (:belt-part "Belt assembly" 200 (229 181 69)) (:inserter-part "Servo" 200 (100 207 224))
               (:engine "Engine" 100 (151 177 181)) (:electric-engine "Electric engine" 100 (91 211 187))
               (:rail-part "Rail section" 200 (151 132 119)) (:signal-part "Signal controller" 100 (255 100 108))
               (:drone-frame "Drone frame" 50 (125 218 231)) (:logistic-drone "Logistic drone" 50 (93 224 178))
               (:repair-pack "Repair pack" 100 (118 231 156)) (:magazine "Magazine" 200 (225 180 73))
               (:piercing-magazine "Piercing magazine" 200 (255 104 85)) (:rocket "Rocket" 100 (235 92 94))
               (:plasma-cell "Plasma cell" 100 (174 108 255)) (:hive-charge "Hive charge" 20 (255 78 158))
               (:wall-part "Composite wall" 200 (139 162 177)) (:solar-cell "Solar cell" 100 (75 169 229))
               (:accumulator-cell "Accumulator cell" 100 (127 229 205))))
    (destructuring-bind (id nome pilha cor) i
      (defitem id :name nome :stack-size pilha :color cor)))
  (defitem :crystal-analysis :name "Crystal analysis" :stack-size 100
           :color '(186 112 255))
  ;; Expansão 2.0: materiais tipados alimentam as novas especializações.
  (dolist (i '((:tungsten-ore "Tungsten ore" 100 (105 120 137) :ore)
               (:cobalt-ore "Cobalt ore" 100 (65 118 191) :ore)
               (:biomass "Biomass" 200 (92 151 89) :organic)
               (:tungsten-plate "Tungsten plate" 100 (142 153 165) :metal)
               (:cobalt-plate "Cobalt plate" 100 (80 139 212) :metal)
               (:concrete "Concrete" 200 (139 143 145) :construction)
               (:reinforced-concrete "Reinforced concrete" 100 (95 105 115) :construction)
               (:motor "Electric motor" 100 (210 145 67) :component)
               (:precision-gear "Precision gear" 100 (181 192 201) :component)
               (:pump-unit "Pump unit" 50 (73 177 200) :component)
               (:sensor "Network sensor" 100 (89 224 191) :electronics)
               (:wire-red "Red circuit wire" 200 (237 75 83) :wire)
               (:wire-green "Green circuit wire" 200 (65 207 116) :wire)
               (:robot-brain "Robot brain" 50 (110 188 237) :electronics)
               (:construction-drone "Construction drone" 50 (238 181 63) :vehicle)
               (:fluid-canister "Fluid canister" 100 (136 177 190) :container)
               (:coolant "Coolant" 500 (78 203 220) :fluid)
               (:explosives "Industrial explosives" 100 (224 103 75) :chemical)
               (:rail-chain-controller "Chain controller" 100 (225 91 98) :electronics)
               (:pollution-filter "Pollution filter" 100 (104 188 130) :ecology)
               (:restoration-seed "Restoration seed" 100 (118 211 104) :ecology)
               (:artillery-shell "Artillery shell" 20 (219 113 73) :ammunition)
               (:locomotive-frame "Locomotive frame" 20 (150 119 96) :vehicle)
               (:wagon-frame "Wagon frame" 20 (130 143 151) :vehicle)))
    (destructuring-bind (id nome pilha cor tipo) i
      (defitem id :name nome :stack-size pilha :color cor :material-kind tipo))))

(defun registrar-receitas ()
  (dolist (r '((:smelt-iron ((:iron-ore . 1)) ((:iron-plate . 1)) 45 :smelting)
               (:smelt-copper ((:copper-ore . 1)) ((:copper-plate . 1)) 45 :smelting)
               (:smelt-stone ((:stone . 2)) ((:stone-brick . 1)) 50 :smelting)
               (:smelt-steel ((:iron-plate . 5)) ((:steel-plate . 1)) 110 :smelting)
               (:make-glass ((:silica . 2) (:coal . 1)) ((:glass . 1)) 60 :smelting)
               (:wire ((:copper-plate . 1)) ((:copper-wire . 2)) 20 :crafting)
               (:gear ((:iron-plate . 2)) ((:gear . 1)) 30 :crafting)
               (:pipe-item ((:iron-plate . 1)) ((:pipe . 1)) 20 :crafting)
               (:circuit ((:iron-plate . 1) (:copper-wire . 3)) ((:circuit . 1)) 45 :crafting)
               (:advanced-circuit ((:circuit . 2) (:copper-wire . 4) (:plastic . 2)) ((:advanced-circuit . 1)) 90 :crafting)
               (:processor ((:advanced-circuit . 2) (:circuit . 8) (:silica . 4)) ((:processor . 1)) 150 :crafting)
               (:battery ((:copper-plate . 1) (:iron-plate . 1) (:sulfur . 1)) ((:battery . 1)) 75 :chemistry)
               (:plastic ((:oil . 3) (:coal . 1)) ((:plastic . 2)) 70 :chemistry)
               (:sulfur ((:oil . 2) (:water . 2)) ((:sulfur . 2)) 60 :chemistry)
               (:fuel ((:oil . 5)) ((:fuel . 2)) 90 :chemistry)
               (:lubricant ((:oil . 4)) ((:lubricant . 3)) 80 :chemistry)
               (:belt-part ((:iron-plate . 1) (:gear . 1)) ((:belt-part . 2)) 30 :crafting)
               (:inserter-part ((:iron-plate . 1) (:gear . 1) (:circuit . 1)) ((:inserter-part . 1)) 45 :crafting)
               (:engine ((:steel-plate . 1) (:gear . 2) (:pipe . 2)) ((:engine . 1)) 90 :crafting)
               (:electric-engine ((:engine . 1) (:circuit . 2) (:lubricant . 2)) ((:electric-engine . 1)) 120 :crafting)
               (:rail-part ((:steel-plate . 1) (:stone . 2)) ((:rail-part . 2)) 45 :crafting)
               (:signal-part ((:circuit . 3) (:iron-plate . 1)) ((:signal-part . 1)) 50 :crafting)
               (:drone-frame ((:steel-plate . 2) (:electric-engine . 1) (:battery . 2)) ((:drone-frame . 1)) 120 :crafting)
               (:logistic-drone ((:drone-frame . 1) (:processor . 1)) ((:logistic-drone . 1)) 150 :crafting)
               (:repair-pack ((:gear . 2) (:circuit . 1)) ((:repair-pack . 1)) 45 :crafting)
               (:magazine ((:iron-plate . 2)) ((:magazine . 2)) 35 :crafting)
               (:piercing-magazine ((:magazine . 1) (:steel-plate . 1)) ((:piercing-magazine . 1)) 55 :crafting)
               (:rocket ((:steel-plate . 1) (:fuel . 2) (:circuit . 1)) ((:rocket . 1)) 90 :crafting)
               (:plasma-cell ((:battery . 2) (:asterion-crystal . 1) (:processor . 1)) ((:plasma-cell . 1)) 160 :crafting)
               (:hive-charge ((:plasma-cell . 5) (:rocket . 5) (:processor . 3)) ((:hive-charge . 1)) 300 :crafting)
               (:wall-part ((:stone-brick . 2) (:steel-plate . 1)) ((:wall-part . 2)) 60 :crafting)
               (:solar-cell ((:silica . 2) (:copper-plate . 1) (:circuit . 1)) ((:solar-cell . 1)) 70 :crafting)
               (:accumulator-cell ((:battery . 2) (:steel-plate . 1)) ((:accumulator-cell . 1)) 80 :crafting)
               (:science-red ((:gear . 1) (:copper-plate . 1)) ((:science-red . 1)) 60 :science)
               (:science-green ((:belt-part . 1) (:inserter-part . 1)) ((:science-green . 1)) 90 :science)
               (:science-blue ((:engine . 1) (:advanced-circuit . 1) (:sulfur . 1)) ((:science-blue . 1)) 120 :science)
               (:science-purple ((:processor . 1) (:crystal-analysis . 1) (:rail-part . 2)) ((:science-purple . 1)) 180 :science)))
    (destructuring-bind (id entradas saidas duracao categoria) r
      (defrecipe id :inputs entradas :outputs saidas :duration duracao :category categoria)))
  ;; Receitas de construção completam o catálogo de 60 receitas úteis aos mods/UI.
  (let ((indice 0))
    (dolist (id '(:belt :fast-belt :splitter :inserter :long-inserter :miner
                  :stone-furnace :electric-furnace :assembler :chemical-plant
                  :refinery :pump :tank :pipe :power-pole :solar-panel
                  :accumulator :steam-generator :laboratory :roboport
                  :logistic-chest :wall :gun-turret))
      (incf indice)
      (defrecipe (intern (format nil "BUILD-~A" id) :keyword)
        :inputs (if (< indice 10) '((:iron-plate . 3) (:gear . 1))
                    '((:steel-plate . 2) (:circuit . 2)))
        :outputs (list (cons id 1)) :duration (+ 30 indice) :category :construction)))
  (dolist (r '((:smelt-tungsten ((:tungsten-ore . 2) (:coal . 1)) ((:tungsten-plate . 1)) 130 :smelting)
               (:smelt-cobalt ((:cobalt-ore . 2)) ((:cobalt-plate . 1)) 95 :smelting)
               (:make-concrete ((:stone . 3) (:water . 1)) ((:concrete . 2)) 55 :crafting)
               (:reinforce-concrete ((:concrete . 2) (:steel-plate . 1)) ((:reinforced-concrete . 1)) 70 :crafting)
               (:make-motor ((:copper-wire . 4) (:gear . 2) (:steel-plate . 1)) ((:motor . 1)) 65 :crafting)
               (:precision-gear ((:gear . 2) (:cobalt-plate . 1)) ((:precision-gear . 1)) 70 :crafting)
               (:pump-unit ((:motor . 1) (:pipe . 2) (:steel-plate . 1)) ((:pump-unit . 1)) 75 :crafting)
               (:network-sensor ((:circuit . 2) (:copper-wire . 2)) ((:sensor . 1)) 55 :crafting)
               (:red-wire ((:copper-wire . 1) (:plastic . 1)) ((:wire-red . 2)) 25 :crafting)
               (:green-wire ((:copper-wire . 1) (:plastic . 1)) ((:wire-green . 2)) 25 :crafting)
               (:robot-brain ((:processor . 1) (:sensor . 2)) ((:robot-brain . 1)) 100 :crafting)
               (:construction-drone ((:drone-frame . 1) (:robot-brain . 1)) ((:construction-drone . 1)) 140 :crafting)
               (:fluid-canister ((:steel-plate . 1) (:plastic . 1)) ((:fluid-canister . 2)) 35 :crafting)
               (:coolant ((:water . 3) (:sulfur . 1)) ((:coolant . 3)) 65 :chemistry)
               (:explosives ((:sulfur . 2) (:coal . 2)) ((:explosives . 2)) 80 :chemistry)
               (:chain-controller ((:signal-part . 1) (:processor . 1)) ((:rail-chain-controller . 1)) 70 :crafting)
               (:pollution-filter ((:plastic . 2) (:biomass . 3)) ((:pollution-filter . 1)) 90 :chemistry)
               (:restoration-seed ((:biomass . 4) (:water . 2)) ((:restoration-seed . 2)) 100 :chemistry)
               (:artillery-shell ((:explosives . 4) (:tungsten-plate . 2)) ((:artillery-shell . 1)) 150 :crafting)
               (:locomotive-frame ((:tungsten-plate . 4) (:motor . 4)) ((:locomotive-frame . 1)) 180 :crafting)
               (:wagon-frame ((:reinforced-concrete . 2) (:steel-plate . 6)) ((:wagon-frame . 1)) 130 :crafting)
               (:build-underground-belt ((:belt-part . 6)) ((:underground-belt . 2)) 65 :construction)
               (:build-filter-splitter ((:belt-part . 5) (:sensor . 1)) ((:filter-splitter . 1)) 80 :construction)
               (:build-stack-inserter ((:inserter-part . 3) (:motor . 1)) ((:stack-inserter . 1)) 75 :construction)
               (:build-loader ((:belt-part . 8) (:motor . 2)) ((:loader . 1)) 100 :construction)
               (:build-boiler ((:steel-plate . 5) (:pipe . 4)) ((:boiler . 1)) 90 :construction)
               (:build-circuit-sensor ((:sensor . 2) (:steel-plate . 1)) ((:circuit-sensor . 1)) 60 :construction)
               (:build-arithmetic-combinator ((:circuit . 4) (:processor . 1)) ((:arithmetic-combinator . 1)) 75 :construction)
               (:build-decider-combinator ((:circuit . 4) (:sensor . 2)) ((:decider-combinator . 1)) 75 :construction)
               (:build-chain-signal ((:rail-chain-controller . 1) (:steel-plate . 1)) ((:chain-signal . 1)) 60 :construction)))
    (destructuring-bind (id entradas saidas duracao categoria) r
      (defrecipe id :inputs entradas :outputs saidas :duration duracao
                 :category categoria))))

(defun registrar-construcoes ()
  (dolist (b '((:core :core (48 220 205) nil 0) (:belt :logistics (214 166 55) ((:iron-plate . 1)) 1)
               (:fast-belt :logistics (238 100 67) ((:belt-part . 2)) 2)
               (:splitter :logistics (231 184 75) ((:belt-part . 4) (:circuit . 1)) 2)
               (:inserter :logistics (74 197 211) ((:inserter-part . 1)) 2)
               (:long-inserter :logistics (241 105 79) ((:inserter-part . 2)) 2)
               (:miner :production (89 183 226) ((:iron-plate . 6) (:gear . 3)) 6)
               (:stone-furnace :production (180 114 83) ((:stone . 6)) 0)
               (:electric-furnace :production (196 109 255) ((:steel-plate . 6) (:advanced-circuit . 3)) 8)
               (:assembler :production (71 179 202) ((:iron-plate . 8) (:gear . 4) (:circuit . 3)) 7)
               (:chemical-plant :production (87 204 132) ((:steel-plate . 6) (:pipe . 5)) 10)
               (:refinery :production (124 97 160) ((:steel-plate . 10) (:pipe . 8) (:circuit . 5)) 15)
               (:pipe :fluid (102 165 174) ((:iron-plate . 1)) 0) (:pump :fluid (70 180 211) ((:engine . 1) (:pipe . 2)) 3)
               (:tank :fluid (80 137 151) ((:steel-plate . 8) (:pipe . 4)) 0)
               (:power-pole :power (238 199 96) ((:copper-wire . 3) (:iron-plate . 2)) 0)
               (:solar-panel :power (48 127 196) ((:solar-cell . 4) (:steel-plate . 2)) -20)
               (:accumulator :power (74 191 162) ((:accumulator-cell . 4)) 0)
               (:steam-generator :power (191 109 75) ((:steel-plate . 6) (:pipe . 4)) -30)
               (:laboratory :science (178 92 246) ((:circuit . 8) (:gear . 6)) 12)
               (:roboport :logistics (71 210 174) ((:steel-plate . 12) (:processor . 3)) 20)
               (:logistic-chest :logistics (202 95 213) ((:steel-plate . 3) (:circuit . 3)) 1)
               (:rail :rail (120 111 105) ((:rail-part . 1)) 0) (:rail-signal :rail (245 91 95) ((:signal-part . 1)) 1)
               (:station :rail (75 176 207) ((:steel-plate . 8) (:signal-part . 3)) 4)
               (:locomotive :rail (217 103 72) ((:engine . 8) (:steel-plate . 15)) 12)
               (:cargo-wagon :rail (137 151 159) ((:steel-plate . 12) (:gear . 8)) 0)
               (:fluid-wagon :rail (82 157 172) ((:steel-plate . 12) (:tank . 1)) 0)
               (:wall :defense (111 133 149) ((:wall-part . 1)) 0)
               (:gun-turret :defense (236 181 64) ((:iron-plate . 8) (:gear . 4)) 4)
               (:laser-turret :defense (91 222 211) ((:steel-plate . 8) (:battery . 4)) 15)
               (:rocket-turret :defense (244 92 100) ((:steel-plate . 12) (:processor . 3)) 18)
               (:plasma-turret :defense (190 96 255) ((:processor . 6) (:asterion-crystal . 5)) 30)
               (:radar :utility (103 193 231) ((:circuit . 5) (:steel-plate . 3)) 5)
               (:repair-bay :utility (81 214 143) ((:logistic-drone . 2) (:repair-pack . 5)) 12)
               (:hive-launcher :weapon (255 73 149) ((:steel-plate . 30) (:processor . 10)) 40)))
    (destructuring-bind (id categoria cor custo energia) b
      (defbuilding id :name (string-capitalize (substitute #\Space #\- (string id)))
        :category categoria :color cor :cost custo :power energia)))
  (dolist (b '((:underground-belt :logistics ((:belt-part . 6)) 2 (1 . 1) (:item-in :item-out) (:belt :underground))
               (:filter-splitter :logistics ((:belt-part . 5) (:sensor . 1)) 3 (2 . 1) (:item-in :item-out-a :item-out-b) (:belt :filter))
               (:stack-inserter :logistics ((:inserter-part . 3) (:motor . 1)) 4 (1 . 1) (:item-in :item-out) (:inserter :stacking))
               (:loader :logistics ((:belt-part . 8) (:motor . 2)) 5 (2 . 1) (:item-in-a :item-in-b :item-out) (:belt :loader))
               (:boiler :power ((:steel-plate . 5) (:pipe . 4)) -22 (2 . 2) (:fluid-in :steam-out) (:generator :fluid))
               (:directional-pump :fluid ((:pump-unit . 1) (:pipe . 2)) 5 (1 . 1) (:fluid-in :fluid-out) (:pump :directional))
               (:circuit-sensor :circuit ((:sensor . 2) (:steel-plate . 1)) 2 (1 . 1) (:signal-out) (:sensor))
               (:arithmetic-combinator :circuit ((:circuit . 4) (:processor . 1)) 2 (1 . 1) (:signal-in :signal-out) (:combinator :arithmetic))
               (:decider-combinator :circuit ((:circuit . 4) (:sensor . 2)) 2 (1 . 1) (:signal-in :signal-out) (:combinator :decider))
               (:chain-signal :rail ((:rail-chain-controller . 1)) 1 (1 . 1) (:rail-block :signal-in) (:rail :chain-signal))
               (:curved-rail :rail ((:rail-part . 4)) 0 (2 . 2) (:rail-a :rail-b) (:rail :curve))
               (:diagonal-crossing :rail ((:rail-part . 8)) 0 (2 . 2) (:rail-a :rail-b :rail-c :rail-d) (:rail :crossing))
               (:construction-roboport :logistics ((:steel-plate . 10) (:robot-brain . 2)) 18 (2 . 2) (:power :logistic) (:drone :construction))
               (:logistics-roboport :logistics ((:steel-plate . 12) (:robot-brain . 3)) 22 (2 . 2) (:power :logistic) (:drone :logistics))
               (:scrubber :ecology ((:pollution-filter . 4) (:motor . 2)) 16 (2 . 2) (:power :filter) (:ecology :pollution-sink))
               (:supply-depot :rail ((:reinforced-concrete . 8) (:motor . 3)) 8 (3 . 2) (:rail :item-in :fluid-in :signal-in) (:rail :station :supply))))
    (destructuring-bind (id categoria custo energia footprint portas tags) b
      (defbuilding id :name (string-capitalize (substitute #\Space #\- (string id)))
        :category categoria :color '(132 151 160) :cost custo :power energia
        :footprint footprint :ports portas :render-layers '(:base :machine :status)
        :circuit-connectors (when (member :signal-in portas) '(:red :green))
        :tags tags))))

(defun registrar-tecnologias ()
  (loop for (id nome custo desbloqueios prereq) in
    '((:automation "Automation" 20 (:assembler :inserter) nil)
      (:logistics "Logistics" 25 (:belt :splitter) (:automation))
      (:steel "Steel processing" 30 (:steel-plate) (:automation))
      (:electricity "Electricity" 35 (:power-pole :steam-generator) (:steel))
      (:defense "Perimeter defense" 30 (:wall :gun-turret) (:automation))
      (:fluids "Fluid handling" 40 (:pipe :pump :tank) (:electricity))
      (:oil "Oil processing" 55 (:refinery :chemical-plant) (:fluids))
      (:solar "Solar energy" 50 (:solar-panel :accumulator) (:electricity))
      (:advanced-circuits "Advanced circuits" 60 (:advanced-circuit) (:oil))
      (:railway "Railway" 70 (:rail :station :locomotive :cargo-wagon) (:steel :electricity))
      (:rail-signals "Rail signals" 60 (:rail-signal) (:railway :advanced-circuits))
      (:systems-science "Systems science" 70 (:science-blue) (:advanced-circuits))
      (:laser-defense "Laser defense" 80 (:laser-turret) (:systems-science :advanced-circuits))
      (:drones "Construction drones" 90 (:roboport :repair-bay) (:systems-science))
      (:logistic-network "Logistic network" 100 (:logistic-drone :logistic-chest) (:drones))
      (:advanced-smelting "Electric smelting" 80 (:electric-furnace) (:systems-science))
      (:rocketry "Rocketry" 110 (:rocket :rocket-turret) (:oil :systems-science))
      (:crystal-science "Crystal science" 120 (:asterion-crystal :science-purple) (:systems-science))
      (:plasma "Plasma containment" 140 (:plasma-cell :plasma-turret) (:crystal-science))
      (:rail-capacity "Rail capacity" 120 (:fluid-wagon) (:rail-signals))
      (:factory-speed-1 "Factory speed I" 80 (:speed-1) (:automation))
      (:factory-speed-2 "Factory speed II" 140 (:speed-2) (:factory-speed-1 :systems-science))
      (:military-logistics "Military logistics" 130 (:piercing-magazine) (:railway :defense))
      (:hive-assault "Hive assault" 250 (:hive-charge :hive-launcher) (:plasma :rocketry :military-logistics)))
    do (deftechnology id :name nome :cost `((:science-red . ,custo))
         :unlocks desbloqueios :prerequisites prereq))
  (loop for (id nome custo desbloqueios prereq ramo) in
    '((:bulk-logistics "Bulk logistics" 110 (:underground-belt :filter-splitter :stack-inserter :loader) (:logistics :advanced-circuits) :logistics)
      (:fluid-pressure "Fluid pressure control" 90 (:directional-pump :coolant) (:fluids) :energy)
      (:power-storage "Grid storage" 105 (:boiler :accumulator-cell) (:electricity :fluids) :energy)
      (:circuit-networks "Circuit networks" 115 (:circuit-sensor :arithmetic-combinator :decider-combinator :wire-red :wire-green) (:systems-science) :logistics)
      (:automated-trains "Automated trains" 135 (:locomotive-frame :wagon-frame :supply-depot) (:railway :systems-science) :logistics)
      (:chain-signals "Chain signalling" 145 (:chain-signal :curved-rail :diagonal-crossing) (:rail-signals :automated-trains) :logistics)
      (:remote-construction "Remote construction" 150 (:construction-roboport :construction-drone) (:drones :circuit-networks) :logistics)
      (:ecological-industry "Ecological industry" 100 (:pollution-filter :scrubber) (:oil :solar) :ecology)
      (:restoration "Biome restoration" 160 (:restoration-seed) (:ecological-industry :drones) :ecology)
      (:artillery-support "Rail artillery support" 180 (:artillery-shell) (:rocketry :automated-trains) :defense)
      (:megabase-logistics "Megabase logistics" 220 (:logistics-roboport :precision-gear) (:bulk-logistics :chain-signals :remote-construction) :logistics)
      (:planetary-stewardship "Planetary stewardship" 260 (:sandbox-restoration-goal) (:restoration :megabase-logistics :hive-assault) :ecology))
    do (deftechnology id :name nome :cost `((:science-purple . ,custo))
         :unlocks desbloqueios :prerequisites prereq :branch ramo)))

(defun registrar-traducoes ()
  (deftranslations :en
    (:title "ASTERION ASSEMBLY") (:chapter "CHAPTER ~D/9: ~A")
    (:help "WASD MOVE  DRAG LMB BUILD  RMB REMOVE  Z UNDO  T TECHNOLOGY")
    (:victory "HIVE NEUTRALIZED - SANDBOX UNLOCKED") (:pollution "POLLUTION ~D")
    (:selected "SELECTED: ~A") (:inventory "CORE IRON ~D  COPPER ~D  STONE ~D")
    (:no-material "INSUFFICIENT MATERIAL") (:mods-warning "SCRIPT MODS ARE TRUSTED CODE")
    (:build-menu "BUILD") (:all "ALL") (:logistics "LOG") (:production "PROD")
    (:power "POWER") (:defense "DEF") (:objective "OBJECTIVE")
    (:map "SECTOR MAP") (:cost "COST") (:new-game "NEW GAME")
    (:continue "CONTINUE") (:settings "SETTINGS") (:mods "MODS")
    (:credits "CREDITS") (:quit "QUIT") (:resume "RESUME")
    (:save "SAVE GAME") (:main-menu "MAIN MENU") (:back "BACK")
    (:language "LANGUAGE") (:audio "AUDIO") (:flashes "REDUCED FLASHES")
    (:menu-tagline "BUILD THE MACHINE. BREAK THE HIVE.")
    (:technology "TECHNOLOGY") (:research "RESEARCH") (:locked "LOCKED")
    (:available "AVAILABLE") (:completed "COMPLETED") (:active "ACTIVE")
    (:status "STATUS") (:working "WORKING") (:idle "IDLE")
    (:no-power "NO POWER") (:no-resource "NO RESOURCE") (:blocked "OUTPUT BLOCKED")
    (:disabled "DISABLED") (:contents "CONTENTS") (:empty "EMPTY")
    (:rate "RATE") (:flow "FLOW") (:power-deficit "POWER DEFICIT")
    (:miners-dry "MINERS WITHOUT RESOURCE") (:belts-blocked "BLOCKED OUTPUTS")
    (:power-satisfaction "SATISFACTION") (:mined "MINED") (:crafted "CRAFTED")
    (:moved "MOVED") (:active-machines "ACTIVE MACHINES")
    (:undo-complete "CONSTRUCTION UNDONE") (:nothing-to-undo "NOTHING TO UNDO"))
  (deftranslations :pt
    (:title "ASTERION ASSEMBLY") (:chapter "CAPITULO ~D/9: ~A")
    (:help "WASD MOVE  ARRASTE LMB CONSTROI  RMB REMOVE  Z DESFAZ  T TECNOLOGIA")
    (:victory "COLMEIA NEUTRALIZADA - SANDBOX LIBERADO") (:pollution "POLUICAO ~D")
    (:selected "SELECIONADO: ~A") (:inventory "NUCLEO FERRO ~D  COBRE ~D  PEDRA ~D")
    (:no-material "MATERIAL INSUFICIENT") (:mods-warning "MODS COM SCRIPT SAO CODIGO CONFIAVEL")
    (:build-menu "CONSTRUIR") (:all "TODOS") (:logistics "LOG") (:production "PROD")
    (:power "ENERGIA") (:defense "DEF") (:objective "OBJETIVO")
    (:map "MAPA DO SETOR") (:cost "CUSTO") (:new-game "NOVO JOGO")
    (:continue "CONTINUAR") (:settings "CONFIGURACOES") (:mods "MODS")
    (:credits "CREDITOS") (:quit "SAIR") (:resume "RETOMAR")
    (:save "SALVAR JOGO") (:main-menu "MENU PRINCIPAL") (:back "VOLTAR")
    (:language "IDIOMA") (:audio "AUDIO") (:flashes "REDUZIR FLASHES")
    (:menu-tagline "CONSTRUA A MAQUINA. DESTRUA A COLMEIA.")
    (:technology "TECNOLOGIA") (:research "PESQUISAR") (:locked "BLOQUEADA")
    (:available "DISPONIVEL") (:completed "CONCLUIDA") (:active "ATIVA")
    (:status "ESTADO") (:working "OPERANDO") (:idle "OCIOSO")
    (:no-power "SEM ENERGIA") (:no-resource "SEM RECURSO") (:blocked "SAIDA BLOQUEADA")
    (:disabled "DESATIVADO") (:contents "CONTEUDO") (:empty "VAZIO")
    (:rate "TAXA") (:flow "FLUXO") (:power-deficit "DEFICIT DE ENERGIA")
    (:miners-dry "MINERADORES SEM RECURSO") (:belts-blocked "SAIDAS BLOQUEADAS")
    (:power-satisfaction "SATISFACAO") (:mined "MINERADO") (:crafted "PRODUZIDO")
    (:moved "MOVIDO") (:active-machines "MAQUINAS ATIVAS")
    (:undo-complete "CONSTRUCAO DESFEITA") (:nothing-to-undo "NADA PARA DESFAZER")))

(defun register-content ()
  (registrar-itens) (registrar-receitas) (registrar-construcoes)
  (registrar-tecnologias) (registrar-traducoes) t)

(defun interpolar-suave (a b t0)
  (let ((s (* t0 t0 (- 3 (* 2 t0))))) (+ a (* (- b a) s))))

(defun ruido-suave (mundo x y sal &optional (escala 12.0))
  "Ruído bilinear por seed para formar biomas e manchas, não pixels aleatórios."
  (let* ((fx (/ x escala)) (fy (/ y escala))
         (x0 (floor fx)) (y0 (floor fy)) (tx (- fx x0)) (ty (- fy y0))
         (a (resource-noise mundo x0 y0 sal))
         (b (resource-noise mundo (1+ x0) y0 sal))
         (c (resource-noise mundo x0 (1+ y0) sal))
         (d (resource-noise mundo (1+ x0) (1+ y0) sal)))
    (interpolar-suave (interpolar-suave a b tx) (interpolar-suave c d tx) ty)))

(defun bioma-em (mundo x y)
  (let ((umidade (ruido-suave mundo x y 301 18.0))
        (calor (ruido-suave mundo x y 707 25.0)))
    (cond ((> calor .72) :ashlands)
          ((> umidade .62) :luminous-marsh)
          ((< umidade .34) :basalt-wastes)
          (t :crystal-grove))))

(defun dentro-mancha-p (mundo x y cx cy raio sal)
  (< (+ (/ (expt (- x cx) 2) (* raio raio))
        (/ (expt (- y cy) 2) (* raio raio))
        (* .32 (- (ruido-suave mundo x y sal 3.5) .5))) 1.0))

(defun recurso-potencial-em (mundo x y)
  "Calcula o tipo geológico sem consultar ou alterar o estoque da jazida."
  (cond
    ((dentro-mancha-p mundo x y -5 -4 3.2 11) :iron-ore)
    ((dentro-mancha-p mundo x y 5 -4 3.0 13) :copper-ore)
    ((dentro-mancha-p mundo x y -5 5 3.1 17) :stone)
    ((dentro-mancha-p mundo x y 5 5 2.8 19) :coal)
    ((> (ruido-suave mundo x y 41 7.0) .79)
     (nth (min 7 (floor (* 8 (ruido-suave mundo x y 97 19.0))))
          '(:iron-ore :copper-ore :stone :coal :silica :oil :water :asterion-crystal)))))

(defun quantidade-inicial-recurso (mundo x y recurso)
  "Depósitos próximos ensinam; depósitos distantes sustentam megabases."
  (let* ((distancia (sqrt (+ (* x x) (* y y))))
         (variacao (floor (* 500 (resource-noise mundo x y 2111))))
         (especial (if (member recurso '(:oil :asterion-crystal)) 650 0)))
    (+ 420 variacao especial (floor (* 24 distancia)))))

(defun recurso-em (mundo x y)
  "Materializa deterministicamente a geologia no chunk e respeita esgotamento."
  (let ((marcador (world-tile mundo x y)))
    (when (zerop marcador)
      (let ((recurso (recurso-potencial-em mundo x y)))
        (set-world-tile mundo x y (if recurso (1+ (indice-recurso-sprite recurso)) 65535))
        (when recurso
          (set-chunk-resource-count mundo x y recurso
                                    (quantidade-inicial-recurso mundo x y recurso)))))
    (let ((recurso (and (/= (world-tile mundo x y) 65535)
                        (nth (1- (world-tile mundo x y))
                             '(:iron-ore :copper-ore :stone :coal :silica :oil
                               :water :asterion-crystal)))))
      (and recurso (plusp (chunk-resource-count mundo x y recurso)) recurso))))

(defun povoar-fauna-passiva (mundo &optional (quantidade 24))
  (dotimes (i quantidade)
    (let* ((angulo (* 2 pi (resource-noise mundo i 1 811)))
           (raio (+ 10 (* 22 (resource-noise mundo i 2 823))))
           (tipo (nth (mod i 4) '(:glow-mite :crystal-grazer :sky-jelly :shellback))))
      (spawn-entity mundo tipo (* raio (cos angulo)) (* raio (sin angulo))
                    :hp 60 :data (list :heading angulo :age 0)))))

(defun inventario-jogador (mundo) (dado mundo :player-inventory))
(defun adicionar-inicial (inventario)
  (dolist (p '((:iron-plate . 120) (:copper-plate . 80) (:stone . 100)
               (:gear . 40) (:circuit . 30) (:rail-part . 80)))
    (inventory-add inventario (car p) (cdr p))))

(defun new-game (&key (seed 1701) (difficulty :standard))
  (let ((mundo (make-world :seed seed :difficulty difficulty))
        (inventario (make-hash-table :test #'equal)))
    (adicionar-inicial inventario)
    (setf (dado mundo :player-inventory) inventario
          (dado mundo :chapter) 1 (dado mundo :chapter-progress) 0
          (dado mundo :unlocked) '(:core :belt :inserter :miner :stone-furnace :power-pole)
          (dado mundo :message) "ESTABLISH THE FIRST EXTRACTION LINE"
          (dado mundo :message-until) 300 (dado mundo :kills) 0
          (dado mundo :power-produced) 50 (dado mundo :power-used) 0
          (dado mundo :sandbox) nil (dado mundo :hive-spawned) nil
          (dado mundo :active-research) :automation (dado mundo :research-progress) 0
          (dado mundo :save-dir) (merge-pathnames "saves/" *raiz*))
    (place-building mundo :core 0 0 :state '(:hp 2000))
    (spawn-entity mundo :engineer 0.5 1.5 :hp 300
                  :data '(:moving nil :heading 0.0 :action :idle :action-until 0))
    (povoar-fauna-passiva mundo)
    mundo))

(defun consumir-custo (mundo definicao)
  (let ((inv (inventario-jogador mundo)) (custo (building-definition-cost definicao)))
    (when (inventory-has-p inv custo)
      (dolist (p custo) (inventory-remove inv (car p) (cdr p))) t)))
(defun devolver-custo (mundo definicao)
  (dolist (p (building-definition-cost definicao))
    (inventory-add (inventario-jogador mundo) (car p) (max 1 (floor (* (cdr p) 0.75))))))

(defun direcao (rotacao)
  (nth (mod rotacao 4) '((1 . 0) (0 . 1) (-1 . 0) (0 . -1))))

(defun saidas-divisor (predio)
  "Retorna as duas saídas cardeais do divisor: frente e ramal horário."
  (let* ((d (direcao (building-rotation predio)))
         (lateral (cons (- (cdr d)) (car d)))
         (x (building-x predio)) (y (building-y predio)))
    (list (cons (+ x (car d)) (+ y (cdr d)))
          (cons (+ x (car lateral)) (+ y (cdr lateral))))))

(defun predio-operacional-p (predio)
  "Distingue a habilitação do jogador da energia distribuída pela rede."
  (and (building-enabled predio)
       (or (not (plusp (building-definition-power
                        (find-building (building-kind predio)))))
           (getf (building-state predio) :powered t))))

(defun transportador-p (predio)
  (and predio (member (building-kind predio) '(:belt :fast-belt :splitter))))

(defun pistas-predio (predio)
  "Retorna as duas pistas persistentes de um transportador."
  (or (getf (building-state predio) :belt-lanes)
      (setf (getf (building-state predio) :belt-lanes)
            (vector (make-belt-lane :capacity 8)
                    (make-belt-lane :capacity 8)))))

(defun transportador-com-item-p (predio)
  (or (item-inventario-deterministico (building-inventory predio))
      (let ((pistas (getf (building-state predio) :belt-lanes)))
        (and pistas (loop for pista across pistas
                          thereis (plusp (belt-lane-count pista)))))))

(defun item-inventario-deterministico (inventario)
  (let (itens)
    (maphash (lambda (item quantidade)
               (when (plusp quantidade) (push item itens))) inventario)
    (first (sort itens #'string< :key #'string))))

(defun inserir-em-destino (destino item &key (pista 0) (pilha 1))
  "Insere no estado físico da esteira ou no inventário de uma máquina."
  (when destino
    (if (transportador-p destino)
        (belt-lane-insert (aref (pistas-predio destino) (mod pista 2)) item
                          :position 0 :stack pilha :min-gap 7168)
        (progn (inventory-add (building-inventory destino) item pilha) t))))

(defun registrar-vazao (predio quantidade)
  (incf (getf (building-state predio) :flow-window 0) quantidade))

(defun atualizar-energia (mundo)
  "Distribui energia uma vez por tick sem piscar construções em brownout.
Consumidores antigos têm prioridade determinística; os demais permanecem
visivelmente desligados até existir capacidade, em vez de alternarem a 30 Hz."
  (let ((producao 50) (consumo 0) (capacidade 0) consumidores nos)
    (map-buildings
     (lambda (b)
       (let ((potencia (building-definition-power (find-building (building-kind b)))))
         (push (building-id b) nos)
         (cond ((minusp potencia) (incf producao (- potencia)))
               ((plusp potencia)
                (incf consumo potencia)
                (push b consumidores)))
         (when (eq (building-kind b) :accumulator) (incf capacidade 100))))
     mundo)
    (let ((rede (ensure-power-network mundo 0 :capacity capacidade :nodes nos)))
      (setf (power-network-generation rede) (float producao)
            (power-network-capacity rede) (float capacidade)
            (power-network-nodes rede) (sort nos #'<))
      (allocate-power-network
       rede
       (mapcar (lambda (b)
                 (let ((potencia (building-definition-power
                                  (find-building (building-kind b)))))
                   (list (building-id b)
                         (getf (building-state b) :power-priority 0)
                         (float potencia)
                         (lambda (alimentado)
                           (setf (getf (building-state b) :powered)
                                 (and (building-enabled b) alimentado)
                                 (getf (building-state b) :power-network) 0)))))
               consumidores))
      (setf (dado mundo :power-satisfaction) (power-network-satisfaction rede)))
    (setf (dado mundo :power-produced) producao
          (dado mundo :power-used) consumo
          (dado mundo :power-stored)
          (power-network-stored (gethash 0 (world-power-networks mundo))))))

(defparameter *tipos-fluido*
  '(:pipe :pump :directional-pump :tank :boiler :chemical-plant :refinery))

(defun componentes-cardinais (mundo tipos)
  "Agrupa construções adjacentes em componentes de ordem estável."
  (let (pendentes componentes)
    (map-buildings (lambda (b) (when (member (building-kind b) tipos) (push b pendentes)))
                   mundo)
    (setf pendentes (sort pendentes #'< :key #'building-id))
    (loop while pendentes do
      (let ((fila (list (pop pendentes))) componente)
        (loop while fila do
          (let ((atual (pop fila)))
            (push atual componente)
            (dolist (d '((1 . 0) (-1 . 0) (0 . 1) (0 . -1)))
              (let ((vizinho (building-at mundo (+ (building-x atual) (car d))
                                           (+ (building-y atual) (cdr d)))))
                (when (and vizinho (member vizinho pendentes :test #'eq)
                           (member (building-kind vizinho) tipos))
                  (setf pendentes (delete vizinho pendentes :test #'eq))
                  (setf fila (nconc fila (list vizinho))))))))
        (push (sort componente #'< :key #'building-id) componentes)))
    (nreverse componentes)))

(defun fluidos-no-predio (predio)
  (remove-duplicates
   (remove nil
           (cons (getf (building-state predio) :fluid)
                 (remove-if-not
                  (lambda (item) (plusp (inventory-count (building-inventory predio) item)))
                  '(:water :oil :lubricant :fuel :coolant))))))

(defun fluido-no-predio (predio) (first (fluidos-no-predio predio)))

(defun capacidade-fluido (predio)
  (case (building-kind predio) (:tank 1000.0) ((:refinery :chemical-plant) 300.0)
        (:boiler 250.0) (otherwise 100.0)))

(defun sistema-fluidos (mundo)
  "Monta redes de volume/pressão e bloqueia componentes com mistura."
  (let (ativos)
    (dolist (componente (componentes-cardinais mundo *tipos-fluido*))
      (let* ((id (building-id (first componente)))
             (fluidos (remove-duplicates (mapcan #'fluidos-no-predio componente)))
             (capacidade (reduce #'+ componente :key #'capacidade-fluido)))
        (push id ativos)
        (if (> (length fluidos) 1)
            (dolist (b componente) (setf (getf (building-state b) :fluid-conflict) t))
            (let* ((fluido (first fluidos))
                   (rede (ensure-fluid-network mundo id :fluid fluido
                                               :capacity capacidade
                                               :nodes (mapcar #'building-id componente))))
              (when (and (fluid-network-fluid rede) fluido
                         (not (eq (fluid-network-fluid rede) fluido))
                         (plusp (fluid-network-volume rede)))
                (dolist (b componente) (setf (getf (building-state b) :fluid-conflict) t))
                (return))
              (setf (fluid-network-fluid rede) fluido
                    (fluid-network-capacity rede) capacidade
                    (fluid-network-nodes rede) (mapcar #'building-id componente))
              (let ((entrada 0.0))
                (when fluido
                  (dolist (b componente)
                    (setf (getf (building-state b) :fluid-conflict) nil
                          (getf (building-state b) :fluid-network) id
                          (getf (building-state b) :fluid) fluido)
                    (let ((qtd (inventory-count (building-inventory b) fluido)))
                      (when (plusp qtd)
                        (incf entrada qtd)
                        (inventory-remove (building-inventory b) fluido qtd)))))
                (simulate-fluid-network rede :inflow entrada)))))
    (let (obsoletos)
      (maphash (lambda (id rede) (declare (ignore rede))
                 (unless (member id ativos) (push id obsoletos)))
               (world-fluid-networks mundo))
      (dolist (id obsoletos) (remhash id (world-fluid-networks mundo)))))))

(defun sistema-circuitos (mundo)
  "Publica sinais tipados e executa combinadores em ordem de construção."
  (let (nos combinadores)
    (map-buildings
     (lambda (b)
       (when (member (building-kind b)
                     '(:circuit-sensor :arithmetic-combinator :decider-combinator
                       :rail-signal :chain-signal :station :supply-depot))
         (push (building-id b) nos)
         (when (member (building-kind b) '(:arithmetic-combinator :decider-combinator))
           (push b combinadores)))) mundo)
    (let ((rede (ensure-circuit-network mundo 0 :nodes (sort nos #'<))))
      (setf (circuit-network-nodes rede) (sort nos #'<))
      (clear-circuit-network rede)
      (circuit-write rede :pollution (round (world-pollution mundo)))
      (circuit-write rede :power (round (* 100 (dado mundo :power-satisfaction 1.0))))
      (circuit-write rede :items-moved (dado mundo :items-moved 0))
      (dolist (b (sort combinadores #'< :key #'building-id))
        (let* ((estado (building-state b))
               (entrada (getf estado :input-signal :items-moved))
               (saida (getf estado :output-signal :signal-a))
               (valor (circuit-read rede entrada)))
          (if (eq (building-kind b) :arithmetic-combinator)
              (circuit-write rede saida
                             (truncate valor (max 1 (getf estado :operand 2))))
              (circuit-write rede saida
                             (if (> valor (getf estado :threshold 0)) 1 0)))
          (setf (getf estado :circuit-network) 0))))))

(defun sistema-drones-construcao (mundo)
  "Converte fantasmas cobertos por roboports em construções conservando custos."
  (when (and (world-ghosts mundo) (zerop (mod (world-tick mundo) 30)))
    (let ((fantasma (first (sort (copy-list (world-ghosts mundo))
                                 (lambda (a b) (or (< (getf a :y) (getf b :y))
                                                   (and (= (getf a :y) (getf b :y))
                                                        (< (getf a :x) (getf b :x))))))))
          (porto nil))
      (map-buildings
       (lambda (b)
         (when (and (null porto)
                    (member (building-kind b) '(:roboport :construction-roboport))
                    (<= (distancia (building-x b) (building-y b)
                                   (getf fantasma :x) (getf fantasma :y)) 14))
           (setf porto b))) mundo)
      (when porto
        (let ((def (find-building (getf fantasma :kind))))
          (when (and def (inventory-has-p (inventario-jogador mundo)
                                          (building-definition-cost def)))
            (dolist (custo (building-definition-cost def))
              (inventory-remove (inventario-jogador mundo) (car custo) (cdr custo)))
            (place-building mundo (getf fantasma :kind) (getf fantasma :x)
                            (getf fantasma :y) :rotation (getf fantasma :rotation 0)
                            :recipe (getf (getf fantasma :settings) :recipe))
            (setf (world-ghosts mundo) (delete fantasma (world-ghosts mundo) :test #'eq))
            (criar-efeito mundo :vfx-spark (+ .5 (getf fantasma :x))
                          (+ .5 (getf fantasma :y)) :duracao 20)))))))

(defun sistema-mineracao (mundo)
  (when (zerop (mod (world-tick mundo) 45))
    (map-buildings
     (lambda (b)
       (when (and (eq (building-kind b) :miner) (predio-operacional-p b))
         (let ((recurso (recurso-em mundo (building-x b) (building-y b))))
           (when (and recurso
                      (plusp (deplete-resource mundo (building-x b)
                                                (building-y b) recurso 1)))
             ;; Como em uma linha de automação legível, o minerador entrega
             ;; diretamente à porta frontal. Sem destino, conserva no buffer.
             (let* ((d (direcao (building-rotation b)))
                    (destino (building-at mundo (+ (building-x b) (car d))
                                               (+ (building-y b) (cdr d)))))
               (unless (inserir-em-destino destino recurso
                                           :pista (mod (building-id b) 2))
                 (inventory-add (building-inventory b) recurso 1)))
             (incf (dado mundo :items-mined 0))
             (incf (world-pollution mundo) 0.8))))) mundo)))

(defun transferir-um (origem destino &optional mundo)
  (let ((movido (item-inventario-deterministico origem)))
    (when movido
      (inventory-remove origem movido 1)
      (inventory-add destino movido 1)
      (when mundo (incf (dado mundo :items-moved 0))))
    movido))

(defun alimentar-pistas-do-buffer (predio)
  "Adapta máquinas e saves antigos sem duplicar itens agregados."
  (let ((item (item-inventario-deterministico (building-inventory predio))))
    (when item
      (let* ((pistas (pistas-predio predio))
             (preferida (mod (getf (building-state predio) :input-lane 0) 2)))
        (loop for pista in (list preferida (mod (1+ preferida) 2))
              when (belt-lane-insert (aref pistas pista) item :position 0
                                     :min-gap 7168)
                do (inventory-remove (building-inventory predio) item 1)
                   (setf (getf (building-state predio) :input-lane)
                         (mod (1+ pista) 2))
                   (return t))))))

(defun destino-transportador (mundo predio indice-pista)
  (if (eq (building-kind predio) :splitter)
      (let* ((saidas (saidas-divisor predio))
             (preferida (mod (+ (getf (building-state predio) :next-output 0)
                                indice-pista) 2))
             (posicao (nth preferida saidas)))
        (values (building-at mundo (car posicao) (cdr posicao)) preferida))
      (let ((d (direcao (building-rotation predio))))
        (values (building-at mundo (+ (building-x predio) (car d))
                             (+ (building-y predio) (cdr d))) indice-pista))))

(defun transferir-frente-pista (mundo predio indice-pista)
  "Transfere quando a posição real chegou à borda e o destino aceitou."
  (let* ((pista (aref (pistas-predio predio) indice-pista))
         (indice (1- (belt-lane-count pista))))
    (when (and (>= indice 0)
               (= (aref (belt-lane-positions pista) indice) 65535))
      (let ((item (aref (belt-lane-items pista) indice))
            (pilha (aref (belt-lane-stacks pista) indice)))
        (multiple-value-bind (destino saida)
            (destino-transportador mundo predio indice-pista)
          (when (inserir-em-destino destino item :pista indice-pista :pilha pilha)
            (belt-lane-remove-front pista)
            (registrar-vazao predio pilha)
            (incf (dado mundo :items-moved 0) pilha)
            (when (eq (building-kind predio) :splitter)
              (setf (getf (building-state predio) :next-output)
                    (mod (1+ saida) 2)))
            t))))))

(defun sistema-logistica (mundo)
  (let (predios)
    (map-buildings (lambda (b) (push b predios)) mundo)
    ;; Processar jusante antes de montante impede pulsos visuais e preserva
    ;; a mesma ordem em qualquer implementação de hash-table.
    (dolist (b (sort predios #'> :key #'building-id))
      (case (building-kind b)
        ((:belt :fast-belt :splitter)
         (when (predio-operacional-p b)
           (alimentar-pistas-do-buffer b)
           (dotimes (pista 2)
             (advance-belt-lane
              (aref (pistas-predio b) pista)
              (if (eq (building-kind b) :fast-belt) 16384 8192)))
           (dotimes (pista 2) (transferir-frente-pista mundo b pista))))
        ((:inserter :long-inserter)
         (when (predio-operacional-p b)
           (let* ((d (direcao (building-rotation b)))
                  (dist (if (eq (building-kind b) :long-inserter) 2 1))
                  (origem (building-at mundo (- (building-x b) (* (car d) dist))
                                       (- (building-y b) (* (cdr d) dist))))
                  (alvo (building-at mundo (+ (building-x b) (* (car d) dist))
                                     (+ (building-y b) (* (cdr d) dist)))))
             (when (and origem alvo (zerop (mod (world-tick mundo) 8)))
               (let ((item (if (transportador-p origem)
                               (multiple-value-bind (i pilha presente)
                                   (belt-lane-remove-front
                                    (aref (pistas-predio origem)
                                          (mod (building-id b) 2)) :threshold 0)
                                 (declare (ignore pilha)) (and presente i))
                               (item-inventario-deterministico
                                (building-inventory origem)))))
                 (when item
                   (unless (transportador-p origem)
                     (inventory-remove (building-inventory origem) item 1))
                   (if (inserir-em-destino alvo item
                                           :pista (mod (building-id b) 2))
                       (progn
                         (incf (dado mundo :items-moved 0))
                         (setf (getf (building-state b) :carried-item) item
                               (getf (building-state b) :carry-start)
                               (world-tick mundo)))
                       (inventory-add (building-inventory origem) item 1))))))))
      (when (and (transportador-p b) (zerop (mod (world-tick mundo) 30)))
        (setf (getf (building-state b) :flow-rate)
              (getf (building-state b) :flow-window 0)
              (getf (building-state b) :flow-window) 0)))
    ;; Tudo que chega ao núcleo torna-se material de construção do jogador.
    (let ((core (nucleo mundo)))
      (when core
        (loop while (transferir-um (building-inventory core)
                                   (inventario-jogador mundo) mundo)))))))

(defun receita-padrao (kind)
  (case kind (:stone-furnace :smelt-iron) (:electric-furnace :smelt-steel)
        (:assembler :gear) (:chemical-plant :plastic) (:refinery :fuel)
        (:laboratory :science-red)))
(defun sistema-producao (mundo)
  (map-buildings
   (lambda (b)
     (let* ((id (or (building-recipe b) (receita-padrao (building-kind b))))
            (receita (and id (find-recipe id))))
       (when (and receita (predio-operacional-p b)
                  (inventory-has-p (building-inventory b) (recipe-definition-inputs receita)))
         (incf (building-progress b))
         (when (>= (building-progress b) (recipe-definition-duration receita))
           (dolist (p (recipe-definition-inputs receita))
             (inventory-remove (building-inventory b) (car p) (cdr p)))
           (dolist (p (recipe-definition-outputs receita))
             (inventory-add (building-inventory b) (car p) (cdr p))
             (incf (dado mundo :items-crafted 0) (cdr p)))
           (setf (building-progress b) 0)
           (incf (world-pollution mundo) 0.3)))))
   mundo))

(defun atualizar-alertas-fabrica (mundo)
  "Resume falhas acionáveis sem obrigar o jogador a abrir outro painel."
  (when (zerop (mod (world-tick mundo) 15))
    (let ((sem-energia 0) (mineradores-secos 0) (saidas-bloqueadas 0)
          (ativas 0))
      (map-buildings
       (lambda (b)
         (when (and (plusp (building-definition-power (find-building (building-kind b))))
                    (building-enabled b) (not (getf (building-state b) :powered t)))
           (incf sem-energia))
         (when (predio-operacional-p b) (incf ativas))
         (when (and (eq (building-kind b) :miner)
                    (null (recurso-em mundo (building-x b) (building-y b))))
           (incf mineradores-secos))
         (when (and (transportador-p b) (transportador-com-item-p b))
           (let ((saidas (if (eq (building-kind b) :splitter)
                             (saidas-divisor b)
                             (let ((d (direcao (building-rotation b))))
                               (list (cons (+ (building-x b) (car d))
                                           (+ (building-y b) (cdr d))))))))
             (unless (some (lambda (posicao)
                             (building-at mundo (car posicao) (cdr posicao)))
                           saidas)
               (incf saidas-bloqueadas)))))
       mundo)
      (setf (dado mundo :unpowered-count) sem-energia
            (dado mundo :dry-miner-count) mineradores-secos
            (dado mundo :blocked-output-count) saidas-bloqueadas
            (dado mundo :active-building-count) ativas))))

(defun distancia (x1 y1 x2 y2) (sqrt (+ (expt (- x1 x2) 2) (expt (- y1 y2) 2))))
(defun nucleo (mundo) (building-at mundo 0 0))
(defun gerar-inimigo (mundo)
  (let* ((angulo (* 2 pi (resource-noise mundo (world-tick mundo) 9 91)))
         (raio (+ 24 (mod (world-tick mundo) 20)))
         (tipos '(:crawler :spitter :brute :stalker :swarmer :guardian))
         (tipo (nth (mod (floor (world-pollution mundo) 100) 6) tipos)))
    (spawn-entity mundo tipo (* raio (cos angulo)) (* raio (sin angulo))
                  :hp (+ 40 (* 30 (position tipo tipos))))))
(defun sistema-fauna (mundo)
  (let ((multiplicador (case (world-difficulty mundo) (:peaceful 0) (:explorer 0.4)
                             (:hostile 2.0) (t 1.0))))
    (when (and (> multiplicador 0) (> (world-pollution mundo) 30)
               (zerop (mod (world-tick mundo)
                           (max 45 (round (/ 600 multiplicador))))))
      (gerar-inimigo mundo)))
  (let (mortos)
    (map-entities
     (lambda (e)
       (when (member (entity-kind e) '(:crawler :spitter :brute :stalker :swarmer :guardian))
         (let ((d (max 0.001 (distancia (entity-x e) (entity-y e) 0 0))))
           (decf (entity-x e) (/ (entity-x e) (* d 15.0)))
           (decf (entity-y e) (/ (entity-y e) (* d 15.0)))
           (when (< d 1.2)
             (let ((core (nucleo mundo)))
               (when core (decf (building-hp core) 1)
                 (when (<= (building-hp core) 0)
                   (setf (dado mundo :message) "CORE LOST - LOAD THE LAST AUTOSAVE"
                         (dado mundo :message-until) (+ (world-tick mundo) 300))))))))
       (when (<= (entity-hp e) 0) (push (entity-id e) mortos))) mundo)
    (dolist (id mortos) (remove-entity mundo id) (incf (dado mundo :kills 0)))))

(defparameter *fauna-passiva* '(:glow-mite :crystal-grazer :sky-jelly :shellback))

(defun sistema-ecossistema (mundo)
  (when (zerop (mod (world-tick mundo) 2))
    (let ((quantidade 0) mortos)
      (map-entities
       (lambda (e)
         (when (member (entity-kind e) *fauna-passiva*)
           (incf quantidade)
           (let* ((dados (entity-data e)) (idade (1+ (getf dados :age 0)))
                  (mudar (zerop (mod (+ idade (entity-id e)) 180)))
                  (angulo (if mudar
                              (* 2 pi (resource-noise mundo (entity-id e)
                                                      (floor idade 180) 919))
                              (getf dados :heading 0.0)))
                  (dist (max .01 (distancia (entity-x e) (entity-y e) 0 0)))
                  (fuga (and (> (world-pollution mundo) 120) (< dist 18)))
                  (direcao (if fuga (atan (entity-y e) (entity-x e)) angulo))
                  (velocidade (case (entity-kind e) (:sky-jelly .018) (:glow-mite .026)
                                   (t .014))))
             (setf (getf dados :age) idade (getf dados :heading) angulo)
             (incf (entity-x e) (* velocidade (cos direcao)))
             (incf (entity-y e) (* velocidade (sin direcao)))
             (when (and (> (world-pollution mundo) 300) (< dist 10)
                        (zerop (mod idade 30)))
               (decf (entity-hp e) 2))
             (when (<= (entity-hp e) 0) (push (entity-id e) mortos))))) mundo)
      (dolist (id mortos) (remove-entity mundo id))
      (when (and (< quantidade 18) (zerop (mod (world-tick mundo) 900)))
        (povoar-fauna-passiva mundo 4)))))

(defparameter *tipos-hostis* '(:crawler :spitter :brute :stalker :swarmer :guardian :hive))

(defun criar-efeito (mundo tipo x y &key (duracao 18) (tamanho 34))
  (spawn-entity mundo tipo x y :hp 1
                :data (list :age 0 :lifetime duracao :size tamanho)))

(defun sistema-efeitos (mundo)
  "Move projéteis e descarta VFX temporários sem afetar o determinismo."
  (let (remover impactos)
    (map-entities
     (lambda (e)
       (let ((tipo (entity-kind e)) (dados (entity-data e)))
         (cond
           ((eq tipo :pulse-projectile)
            (incf (entity-x e) (getf dados :vx 0.0))
            (incf (entity-y e) (getf dados :vy 0.0))
            (incf (getf dados :age))
            (let ((alvo nil))
              (map-entities
               (lambda (possivel)
                 (when (and (null alvo) (member (entity-kind possivel) *tipos-hostis*)
                            (< (distancia (entity-x e) (entity-y e)
                                          (entity-x possivel) (entity-y possivel)) .62))
                   (setf alvo possivel))) mundo)
              (when alvo
                (decf (entity-hp alvo) 28)
                (push (list (entity-x e) (entity-y e)) impactos)
                (push (entity-id e) remover)
                (play-sound :impact)
                (when (<= (entity-hp alvo) 0)
                  (push (entity-id alvo) remover)
                  (incf (dado mundo :kills 0)))))
            (when (>= (getf dados :age) (getf dados :lifetime 45))
              (push (entity-id e) remover)))
           ((member tipo '(:vfx-spark :vfx-smoke :vfx-impact :vfx-muzzle))
            (incf (getf dados :age))
            (when (>= (getf dados :age) (getf dados :lifetime 18))
              (push (entity-id e) remover)))))) mundo)
    (dolist (id (remove-duplicates remover)) (remove-entity mundo id))
    (dolist (pos impactos)
      (criar-efeito mundo :vfx-impact (first pos) (second pos)
                    :duracao 16 :tamanho 46))))

(defun sistema-defesa (mundo)
  (when (zerop (mod (world-tick mundo) 12))
    (map-buildings
     (lambda (b)
       (when (member (building-kind b) '(:gun-turret :laser-turret :rocket-turret :plasma-turret))
         (let ((alvo nil) (melhor 12.0))
           (map-entities (lambda (e)
             (when (member (entity-kind e) '(:crawler :spitter :brute :stalker :swarmer :guardian :hive))
               (let ((d (distancia (building-x b) (building-y b) (entity-x e) (entity-y e))))
                 (when (< d melhor) (setf melhor d alvo e))))) mundo)
           (when alvo (decf (entity-hp alvo)
                            (case (building-kind b) (:gun-turret 12) (:laser-turret 20)
                                  (:rocket-turret 40) (:plasma-turret 70))))))) mundo)))

(defparameter *capitulos*
  #("LANDFALL" "METALS" "AUTOMATION" "FLUIDS" "RESEARCH" "RAILWAYS"
    "SIGNALS AND DRONES" "WAR INDUSTRY" "HIVE ASSAULT"))
(defun quantidade-tipo (mundo tipo)
  (let ((n 0)) (map-buildings (lambda (b) (when (eq (building-kind b) tipo) (incf n))) mundo) n))
(defun avancar-capitulo (mundo)
  (let ((c (dado mundo :chapter 1)))
    (when (and (< c 9)
      (case c (1 (>= (quantidade-tipo mundo :miner) 2))
              (2 (>= (quantidade-tipo mundo :stone-furnace) 2))
              (3 (>= (quantidade-tipo mundo :assembler) 1))
              (4 (>= (+ (quantidade-tipo mundo :pipe) (quantidade-tipo mundo :pump)) 6))
              (5 (>= (quantidade-tipo mundo :laboratory) 1))
              (6 (>= (quantidade-tipo mundo :rail) 20))
              (7 (>= (+ (quantidade-tipo mundo :rail-signal) (quantidade-tipo mundo :roboport)) 2))
              (8 (>= (+ (quantidade-tipo mundo :rocket-turret) (quantidade-tipo mundo :plasma-turret)) 2))))
      (incf (dado mundo :chapter))
      (setf (dado mundo :message) (format nil "NEW CHAPTER: ~A" (aref *capitulos* c))
            (dado mundo :message-until) (+ (world-tick mundo) 240)))
    (when (and (= (dado mundo :chapter 1) 9) (not (dado mundo :hive-spawned)))
      (spawn-entity mundo :hive 42 37 :hp 5000 :data '(:objective t))
      (setf (dado mundo :hive-spawned) t (dado mundo :message) "HIVE LOCATED AT 42,37"
            (dado mundo :message-until) (+ (world-tick mundo) 600)))
    (when (and (dado mundo :hive-spawned) (not (dado mundo :sandbox)))
      (let ((viva nil)) (map-entities (lambda (e) (when (eq (entity-kind e) :hive) (setf viva t))) mundo)
        (unless viva (setf (dado mundo :sandbox) t (dado mundo :message) (translate :victory)
                           (dado mundo :message-until) most-positive-fixnum))))))

(defun sistema-campanha (mundo)
  (when (zerop (mod (world-tick mundo) 30)) (avancar-capitulo mundo))
  (when (and (> (world-tick mundo) 0) (zerop (mod (world-tick mundo) +ticks-autosave+)))
    (handler-case (autosave-game mundo (dado mundo :save-dir) :slots 3)
      (error (e) (engine-log :error "Autosave falhou: ~A" e)))))

(defun tecnologia-concluida-p (mundo id)
  (member id (world-research mundo)))

(defun tecnologia-disponivel-p (mundo id)
  (let ((tecnologia (find-technology id)))
    (and tecnologia
         (not (tecnologia-concluida-p mundo id))
         (every (lambda (requisito) (tecnologia-concluida-p mundo requisito))
                (technology-definition-prerequisites tecnologia)))))

(defun custo-tecnologia (tecnologia)
  (or (cdr (assoc :science-red (technology-definition-cost tecnologia))) 1))

(defun selecionar-pesquisa (mundo id)
  (when (tecnologia-disponivel-p mundo id)
    (setf (dado mundo :active-research) id
          (dado mundo :research-progress) 0
          (dado mundo :message) (format nil "RESEARCH SELECTED: ~A"
                                        (technology-definition-name (find-technology id)))
          (dado mundo :message-until) (+ (world-tick mundo) 180))
    t))

(defun construcao-desbloqueada-p (mundo kind)
  "Libera conteúdo inicial, pesquisado ou não associado a tecnologia alguma."
  (or (member kind (dado mundo :unlocked))
      (let ((possui-tecnologia nil))
        (map-technologies
         (lambda (tecnologia)
           (when (member kind (technology-definition-unlocks tecnologia))
             (setf possui-tecnologia t))))
        (not possui-tecnologia))))

(defun sistema-pesquisa (mundo)
  (when (and (plusp (quantidade-tipo mundo :laboratory))
             (zerop (mod (world-tick mundo) 60)))
    (let* ((proxima (dado mundo :active-research))
           (tecnologia (and proxima (find-technology proxima)))
           (inv (inventario-jogador mundo)))
      (when (and tecnologia (tecnologia-disponivel-p mundo proxima)
                 (inventory-remove inv :science-red 1))
        (incf (dado mundo :research-progress 0))
        (when (>= (dado mundo :research-progress) (custo-tecnologia tecnologia))
          (push proxima (world-research mundo))
          (setf (dado mundo :research-progress) 0
                (dado mundo :active-research) nil
                (dado mundo :unlocked)
                (union (technology-definition-unlocks tecnologia) (dado mundo :unlocked))
                (dado mundo :message) (format nil "RESEARCH COMPLETE: ~A"
                                              (technology-definition-name tecnologia))
                (dado mundo :message-until) (+ (world-tick mundo) 240)))))))

(defun sistema-trens (mundo)
  ;; Uma rota automática demonstra reservas e movimento entre as duas primeiras estações.
  (let ((trens (dado mundo :trains)) (estacoes nil))
    (map-buildings (lambda (b) (when (eq (building-kind b) :station) (push b estacoes))) mundo)
    (when (and (null trens) (>= (length estacoes) 2))
      (let* ((a (first estacoes)) (b (second estacoes))
             (rota (rail-route mundo (cons (building-x a) (building-y a))
                               (cons (building-x b) (building-y b)))))
        (when rota
          (let ((e (spawn-entity mundo :train (+ .5 (caar rota)) (+ .5 (cdar rota))
                                 :hp 1200 :data (list :route rota :index 0 :phase 0))))
            (setf (dado mundo :trains) (list (entity-id e)))))))
    (dolist (id (dado mundo :trains))
      (let ((e nil)) (map-entities (lambda (x) (when (= (entity-id x) id) (setf e x))) mundo)
        (when e
          (let* ((dados (entity-data e)) (rota (getf dados :route))
                 (indice (getf dados :index)) (alvo (nth indice rota)))
            (when alvo
              (let* ((tx (+ .5 (car alvo))) (ty (+ .5 (cdr alvo)))
                     (dx (- tx (entity-x e))) (dy (- ty (entity-y e)))
                     (d (max .001 (sqrt (+ (* dx dx) (* dy dy))))))
                (incf (entity-x e) (* .09 (/ dx d))) (incf (entity-y e) (* .09 (/ dy d)))
                (when (< d .12)
                  (setf (getf dados :index)
                        (if (zerop (getf dados :phase))
                            (min (1- (length rota)) (1+ indice))
                            (max 0 (1- indice))))
                  (when (= (getf dados :index) (1- (length rota))) (setf (getf dados :phase) 1))
                  (when (zerop (getf dados :index)) (setf (getf dados :phase) 0)))))))))))

(defun registrar-sistemas ()
  (defsystem :efeitos (:priority 5 :phase :pre-simulation
                       :reads (:entities) :writes (:entities))
    (mundo) (sistema-efeitos mundo))
  (defsystem :energia (:priority 7 :reads (:buildings) :writes (:power-networks))
    (mundo) (atualizar-energia mundo))
  (defsystem :fluidos (:priority 8 :reads (:buildings) :writes (:fluid-networks))
    (mundo) (sistema-fluidos mundo))
  (defsystem :circuitos (:priority 9 :reads (:power-networks :buildings)
                         :writes (:circuit-networks))
    (mundo) (sistema-circuitos mundo))
  (defsystem :mineracao (:priority 10 :reads (:chunks) :writes (:chunks :belts))
    (mundo) (sistema-mineracao mundo))
  (defsystem :logistica (:priority 20 :reads (:buildings) :writes (:belts :inventories))
    (mundo) (sistema-logistica mundo))
  (defsystem :producao (:priority 30 :reads (:recipes) :writes (:inventories))
    (mundo) (sistema-producao mundo))
  (defsystem :drones (:priority 32 :reads (:ghosts) :writes (:buildings :ghosts))
    (mundo) (sistema-drones-construcao mundo))
  (defsystem :alertas-fabrica (:priority 35) (mundo) (atualizar-alertas-fabrica mundo))
  (defsystem :fauna (:priority 40) (mundo) (sistema-fauna mundo))
  (defsystem :ecossistema (:priority 45) (mundo) (sistema-ecossistema mundo))
  (defsystem :defesa (:priority 50) (mundo) (sistema-defesa mundo))
  (defsystem :pesquisa (:priority 55) (mundo) (sistema-pesquisa mundo))
  (defsystem :trens (:priority 58) (mundo) (sistema-trens mundo))
  (defsystem :campanha (:priority 60) (mundo) (sistema-campanha mundo)))

(defun indice-recurso-sprite (recurso)
  (position recurso '(:iron-ore :copper-ore :stone :coal :silica :oil :water
                      :asterion-crystal)))

(defparameter *sprites-itens*
  '((:iron-ore . 0) (:copper-ore . 1) (:stone . 2) (:coal . 3)
    (:silica . 4) (:oil . 5) (:water . 6) (:asterion-crystal . 7)
    (:iron-plate . 8) (:copper-plate . 9) (:steel-plate . 10) (:glass . 11)
    (:stone-brick . 12) (:copper-wire . 13) (:gear . 14) (:pipe . 15)
    (:circuit . 16) (:advanced-circuit . 17) (:processor . 18) (:battery . 19)
    (:plastic . 20) (:sulfur . 21) (:lubricant . 22) (:fuel . 23)
    (:science-red . 24) (:science-green . 25) (:science-blue . 26)
    (:science-purple . 27) (:belt-part . 28) (:inserter-part . 29)
    (:engine . 30) (:electric-engine . 31) (:rail-part . 32)
    (:signal-part . 33) (:drone-frame . 34) (:logistic-drone . 35)
    (:repair-pack . 36) (:magazine . 37) (:piercing-magazine . 38)
    (:rocket . 39) (:plasma-cell . 40) (:hive-charge . 41)
    (:wall-part . 42) (:solar-cell . 43) (:accumulator-cell . 44)
    (:crystal-analysis . 45)))

(defparameter *sprites-itens-v2*
  '((:tungsten-ore . 0) (:cobalt-ore . 1) (:biomass . 2)
    (:tungsten-plate . 3) (:cobalt-plate . 4) (:concrete . 5)
    (:reinforced-concrete . 6) (:motor . 7) (:precision-gear . 8)
    (:pump-unit . 9) (:sensor . 10) (:wire-red . 11) (:wire-green . 12)
    (:robot-brain . 13) (:construction-drone . 14) (:fluid-canister . 15)
    (:coolant . 16) (:explosives . 17) (:rail-chain-controller . 18)
    (:pollution-filter . 19) (:restoration-seed . 20) (:artillery-shell . 21)
    (:locomotive-frame . 22) (:wagon-frame . 23)))

(defun sprite-item (item)
  (or (cdr (assoc item *sprites-itens*))
      (cdr (assoc item *sprites-itens-v2*))))

(defun folha-item (item)
  (if (assoc item *sprites-itens-v2*) :items-v2 :items))

(defun primeiro-item-visivel (inventario)
  "Escolhe deterministicamente um item presente apenas para apresentação."
  (let (presentes)
    (maphash (lambda (item quantidade)
               (when (and (> quantidade 0) (sprite-item item)) (push item presentes)))
             inventario)
    (first (sort presentes #'string< :key #'string))))

(defparameter *sprites-construcoes*
  '((:core . 0) (:belt . 1) (:fast-belt . 2) (:splitter . 3)
    (:inserter . 4) (:long-inserter . 5)
    (:miner . 6) (:stone-furnace . 7) (:electric-furnace . 8)
    (:assembler . 9) (:chemical-plant . 10) (:refinery . 11)
    (:pipe . 12) (:pump . 13) (:tank . 14) (:power-pole . 15)
    (:solar-panel . 16) (:accumulator . 17)
    (:steam-generator . 18) (:laboratory . 19) (:roboport . 20)
    (:logistic-chest . 21) (:rail . 22) (:rail-signal . 23)
    (:station . 24) (:locomotive . 25) (:cargo-wagon . 26)
    (:fluid-wagon . 27) (:wall . 28) (:gun-turret . 29)
    (:laser-turret . 30) (:rocket-turret . 31) (:plasma-turret . 32)
    (:radar . 33) (:repair-bay . 34) (:hive-launcher . 35)))

(defparameter *sprites-construcoes-v2*
  '((:underground-belt . 0) (:filter-splitter . 1) (:stack-inserter . 2)
    (:loader . 3) (:boiler . 4) (:directional-pump . 5)
    (:circuit-sensor . 6) (:arithmetic-combinator . 7)
    (:decider-combinator . 8) (:chain-signal . 9) (:curved-rail . 10)
    (:diagonal-crossing . 11) (:construction-roboport . 12)
    (:logistics-roboport . 13) (:scrubber . 14) (:supply-depot . 15)))

(defun sprite-construcao (kind)
  (or (cdr (assoc kind *sprites-construcoes*))
      (cdr (assoc kind *sprites-construcoes-v2*)) 3))

(defun folha-construcao (kind)
  (if (assoc kind *sprites-construcoes-v2*) :buildings-v2 :buildings))

(defun sprite-unidade (kind)
  (case kind (:commander-drone 0) (:logistic-drone 1) (:repair-drone 2)
        (:train 3) (:cargo-wagon 4) (:fluid-wagon 5) (:crawler 6) (:spitter 7)
        (:brute 8) (:stalker 9) (:swarmer 10) (:guardian 8) (:hive 11) (t 6)))

(defun animacao-maquina (kind)
  (case kind
    (:miner :miner-active)
    ((:stone-furnace :electric-furnace) :furnace-active)
    (:assembler :assembler-active)
    ((:chemical-plant :refinery) :chemical-active)))

(defun animacao-logistica (kind)
  (case kind
    (:belt :belt-moving)
    (:fast-belt :fast-belt-moving)
    ((:inserter :long-inserter) :inserter-working)
    (:rail-signal :rail-signal-active)))

(defun animacao-unidade (kind)
  (case kind
    ((:commander-drone :logistic-drone :repair-drone) :commander-hover)
    ((:crawler :stalker :swarmer) :crawler-walk)
    (:spitter :spitter-walk)
    ((:brute :guardian) :brute-walk)
    (:glow-mite :glow-mites)
    (:crystal-grazer :crystal-grazer)
    (:sky-jelly :sky-jelly)
    (:shellback :shellback)))

(defun animacao-engenheiro (mundo entidade)
  "Ações básicas usam sua atlas; ataques apontam para a atlas ofensiva separada."
  (let* ((dados (entity-data entidade))
         (acao (getf dados :action :idle))
         (ativa (< (world-tick mundo) (getf dados :action-until 0))))
    (cond ((and ativa (eq acao :shoot)) :engineer-shoot-pulse)
          ((and ativa (eq acao :building)) :engineer-build)
          ((and ativa (eq acao :interact)) :engineer-interact)
          ((getf dados :moving) :engineer-walk)
          (t :engineer-idle))))

(defun indice-direcional-engenheiro (entidade)
  "Converte o ângulo do mundo para as oito vistas já desenhadas na atlas.
A ordem visual é sul, sudoeste, oeste, noroeste, norte, nordeste, leste, sudeste."
  (mod (round (+ 6 (/ (getf (entity-data entidade) :heading 0.0)
                         (/ pi 4.0)))) 8))

(defun quadro-engenheiro (mundo entidade)
  "Seleciona uma vista sem girar fisicamente o corpo 3/4."
  (let* ((dados (entity-data entidade))
         (direcao (indice-direcional-engenheiro entidade))
         (acao (getf dados :action :idle))
         (ativa (< (world-tick mundo) (getf dados :action-until 0))))
    (cond
      ((and ativa (eq acao :building)) (+ 16 direcao))
      ((and ativa (eq acao :interact)) (+ 24 direcao))
      ;; Alterna a pose neutra e o passo da mesma direção.
      ((and (getf dados :moving) (oddp (floor (* 7 (engine-time)))))
       (+ 8 direcao))
      (t direcao))))

(defun indice-chao (mundo x y)
  (+ (case (bioma-em mundo x y)
       (:basalt-wastes 0) (:crystal-grove 2) (:luminous-marsh 4) (:ashlands 6))
     (if (> (resource-noise mundo x y 1009) .5) 1 0)))

(defun indice-prop-ambiental (mundo x y)
  (when (and (> (resource-noise mundo x y 1031) .935)
             (> (+ (abs x) (abs y)) 4))
    (let ((n (resource-noise mundo x y 1063)))
      (case (bioma-em mundo x y)
        (:crystal-grove (+ 8 (floor (* 16 n))))
        (:luminous-marsh (+ 8 (floor (* 24 n))))
        (:basalt-wastes (+ 24 (floor (* 8 n))))
        (:ashlands (+ 32 (floor (* 16 n))))))))

(defun visivel-no-mundo-p (x y &optional (margem 96))
  (multiple-value-bind (sx sy) (world-to-screen x y)
    (and (> sx (- margem)) (< sx (+ (screen-width) margem))
         (> sy (- margem)) (< sy (+ (screen-height) margem)))))

(defun desenhar-item (item x y &optional (tamanho 15))
  (let ((indice (sprite-item item)))
    (when indice (draw-sprite (folha-item item) indice x y tamanho tamanho :world t))))

(defun desenhar-item-em-transito (b mundo x y)
  "Projeta itens reais dos inventários nas portas e transportadores."
  (let* ((kind (building-kind b)) (tick (world-tick mundo))
         (d (direcao (building-rotation b))))
    (cond
      ((member kind '(:belt :fast-belt :splitter))
       ;; A posição desenhada é a posição inteira da simulação. Não há relógio
       ;; visual independente, portanto congestionamento e brownout não piscam.
       (let ((pistas (pistas-predio b))
             (px (- (cdr d))) (py (car d)))
         (dotimes (lado 2)
           (let ((pista (aref pistas lado))
                 (lateral (if (zerop lado) -5 5)))
             (dotimes (indice (belt-lane-count pista))
               (let* ((item (aref (belt-lane-items pista) indice))
                      (frac (/ (aref (belt-lane-positions pista) indice) 65535.0))
                      (deslocamento (+ -13 (* 26 frac))))
                 (desenhar-item item
                                (+ x 9 (* (car d) deslocamento) (* px lateral))
                                (+ y 9 (* (cdr d) deslocamento) (* py lateral)) 12)))))))
      ((member kind '(:inserter :long-inserter))
       (let* ((item (getf (building-state b) :carried-item))
              (inicio (getf (building-state b) :carry-start -100))
              (idade (- tick inicio)))
         (when (and item (<= 0 idade 8))
           (let* ((frac (/ idade 8.0))
                  (dist (if (eq kind :long-inserter) 2 1))
                  (alcance (* dist 24))
                  (linha (* alcance (- (* 2 frac) 1)))
                  (arco (* -12 (sin (* pi frac))))
                  (px (+ x 9 (* (car d) linha) (* (- (cdr d)) arco)))
                  (py (+ y 9 (* (cdr d) linha) (* (car d) arco))))
             (desenhar-item item px py 14)))))
      ((member kind '(:stone-furnace :electric-furnace :assembler
                      :chemical-plant :refinery :laboratory))
       (when (> (building-progress b) 0)
         (let* ((id (or (building-recipe b) (receita-padrao kind)))
                (receita (and id (find-recipe id)))
                (item (and receita (caar (recipe-definition-outputs receita)))))
           (when item
             (desenhar-item item (+ x 25) (+ y 2 (* 2 (sin (* 5 (engine-time))))) 14)))))
      ((eq kind :miner)
       (let ((item (or (primeiro-item-visivel (building-inventory b))
                       (recurso-em mundo (building-x b) (building-y b)))))
         (when item (desenhar-item item (+ x 25) (+ y 8) 14))))
      ((member kind '(:pipe :pump :tank))
       (let ((item (primeiro-item-visivel (building-inventory b))))
         (when (member item '(:water :oil :lubricant :fuel))
           (desenhar-item item (+ x 9) (+ y 9) 14)))))))

(defun desenhar-construcao (b &key (opacity 255) (world t) game-world)
  (let* ((kind (building-kind b))
         (x (* (building-x b) +tamanho-celula+))
         (y (* (building-y b) +tamanho-celula+))
         (angulo (* 90 (building-rotation b)))
         (fase (* .073 (mod (building-id b) 19)))
         (logistica (animacao-logistica kind))
         (operacional (if game-world (predio-operacional-p b) (building-enabled b)))
         (tint (if operacional '(255 255 255) '(110 125 135))))
    (when (or (not world) (visivel-no-mundo-p x y))
      (when world
        (draw-rect (+ x 5) (+ y 23) 23 7 '(0 0 0 75) :world t))
      (cond
        (logistica
         (draw-animation logistica x y 32 32 :world world :angle angulo
                         :phase fase :opacity opacity :tint tint))
        ((eq kind :rail)
         (draw-sprite :terrain 15 x y 32 32 :world world :angle angulo
                      :opacity opacity :tint tint))
        (t
         (draw-sprite (folha-construcao kind) (sprite-construcao kind) (- x 7) (- y 10)
                      46 46 :world world :angle angulo :opacity opacity :tint tint)))
      (when (and world game-world)
        (desenhar-item-em-transito b game-world x y))
      (when (and world operacional
                 (or (eq kind :miner) (> (building-progress b) 0))
                 (member kind '(:miner :stone-furnace :electric-furnace :assembler
                                :chemical-plant :refinery)))
        (draw-animation (if (member kind '(:stone-furnace :electric-furnace))
                            :factory-smoke :electric-spark)
                        (+ x 2) (- y 18) 30 30 :world t :phase fase
                        :opacity (if *reduzir-flashes* 125 190))))))

(defun predio-sob-cursor (mundo)
  "Obtém a construção apontada somente dentro da área útil do mapa."
  (multiple-value-bind (mx my) (mouse-position)
    (when (and (> my 72) (< my (- (screen-height) 96))
               (or (not *mostrar-catalogo*) (< mx (- (screen-width) 250))))
      (multiple-value-bind (wx wy) (screen-to-world mx my)
        (building-at mundo (floor wx +tamanho-celula+)
                     (floor wy +tamanho-celula+))))))

(defun estado-predio (mundo predio)
  "Produz um estado curto, legível e acionável para inspeção contextual."
  (let ((kind (building-kind predio)))
    (cond
      ((not (building-enabled predio)) :disabled)
      ((not (predio-operacional-p predio)) :no-power)
      ((and (eq kind :miner)
            (null (recurso-em mundo (building-x predio) (building-y predio))))
       :no-resource)
      ((and (transportador-p predio) (transportador-com-item-p predio))
       (let ((saidas (if (eq kind :splitter)
                         (saidas-divisor predio)
                         (let ((d (direcao (building-rotation predio))))
                           (list (cons (+ (building-x predio) (car d))
                                       (+ (building-y predio) (cdr d))))))))
         (if (some (lambda (posicao)
                     (building-at mundo (car posicao) (cdr posicao)))
                   saidas)
             :working :blocked)))
      ((or (> (building-progress predio) 0)
           (and (eq kind :miner)
                (recurso-em mundo (building-x predio) (building-y predio))))
       :working)
      (t :idle))))

(defun cor-estado-predio (estado)
  (case estado
    (:working '(91 236 185 255))
    (:idle '(159 184 197 255))
    ((:no-power :blocked) '(255 190 72 255))
    ((:no-resource :disabled) '(255 105 125 255))
    (t '(205 222 230 255))))

(defun itens-inventario-visiveis (inventario &optional (limite 3))
  (let (itens)
    (maphash (lambda (item quantidade)
               (when (plusp quantidade) (push (cons item quantidade) itens)))
             inventario)
    (subseq (sort itens #'string< :key (lambda (p) (string (car p))))
            0 (min limite (length itens)))))

(defun nome-direcao (rotacao)
  (nth (mod rotacao 4) '("E" "S" "W" "N")))

(defun desenhar-seta-fluxo-em (gx gy rotacao cor)
  "Sobrepõe direção sem depender apenas da animação ou da cor da esteira."
  (let* ((d (direcao rotacao))
         (dx (car d)) (dy (cdr d))
         (cx (+ 16 (* gx +tamanho-celula+)))
         (cy (+ 16 (* gy +tamanho-celula+)))
         (x0 (- cx (* dx 9))) (y0 (- cy (* dy 9)))
         (x1 (+ cx (* dx 9))) (y1 (+ cy (* dy 9)))
         (px (- dy)) (py dx))
    (draw-line x0 y0 x1 y1 cor :world t)
    (draw-line x1 y1 (+ (- x1 (* dx 5)) (* px 4))
               (+ (- y1 (* dy 5)) (* py 4)) cor :world t)
    (draw-line x1 y1 (- (- x1 (* dx 5)) (* px 4))
               (- (- y1 (* dy 5)) (* py 4)) cor :world t)))

(defun desenhar-seta-fluxo (predio cor)
  (if (eq (building-kind predio) :splitter)
      (let* ((rotacao (building-rotation predio))
             (ramal (mod (1+ rotacao) 4)))
        (desenhar-seta-fluxo-em (building-x predio) (building-y predio) rotacao cor)
        (desenhar-seta-fluxo-em (building-x predio) (building-y predio) ramal cor))
      (desenhar-seta-fluxo-em (building-x predio) (building-y predio)
                               (building-rotation predio) cor)))

(defun desenhar-overlay-fabrica (mundo)
  "Destaca a entidade inspecionada e revela o fluxo da rede logística visível."
  (let ((foco (predio-sob-cursor mundo)))
    (when foco
      (let ((x (* (building-x foco) +tamanho-celula+))
            (y (* (building-y foco) +tamanho-celula+)))
        (draw-rect x y 32 32 '(245 211 91 255) :world t :outline t))
      (when (member (building-kind foco) '(:belt :fast-belt :splitter
                                           :inserter :long-inserter))
        (map-buildings
         (lambda (b)
           (when (and (member (building-kind b) '(:belt :fast-belt :splitter
                                                  :inserter :long-inserter))
                      (visivel-no-mundo-p (* (building-x b) +tamanho-celula+)
                                          (* (building-y b) +tamanho-celula+)))
             (desenhar-seta-fluxo b (if (predio-operacional-p b)
                                        '(108 255 215 235) '(255 111 126 235)))))
         mundo)))))

(defun desenhar-inspetor-predio (mundo)
  "Painel estático de hover com estado, taxa, energia e conteúdo real."
  (let ((b (predio-sob-cursor mundo)))
    (when b
      (let* ((x 12) (y (- (screen-height) 292)) (largura 344) (altura 170)
             (def (find-building (building-kind b)))
             (estado (estado-predio mundo b))
             (cor (cor-estado-predio estado))
             (potencia (building-definition-power def))
             (receita (and (building-recipe b) (find-recipe (building-recipe b))))
             (itens (itens-inventario-visiveis (building-inventory b))))
        (draw-rect x y largura altura '(4 10 17 248))
        (draw-rect x y largura altura cor :outline t)
        (draw-sprite (folha-construcao (building-kind b))
                     (sprite-construcao (building-kind b))
                     (+ x 12) (+ y 12) 48 48)
        (draw-text (subseq (string-upcase (building-definition-name def)) 0
                           (min 30 (length (building-definition-name def))))
                   (+ x 72) (+ y 14) '(231 241 245 255) :scale 2)
        (draw-text (format nil "~A: ~A" (translate :status) (translate estado))
                   (+ x 72) (+ y 39) cor :scale 1)
        (draw-text (cond ((minusp potencia) (format nil "POWER OUTPUT ~D MW" (- potencia)))
                         ((plusp potencia) (format nil "POWER USE ~D MW" potencia))
                         (t "POWER PASSIVE"))
                   (+ x 72) (+ y 54) '(158 205 220 255) :scale 1)
        (when (member (building-kind b) '(:belt :fast-belt :splitter
                                          :inserter :long-inserter))
          (draw-text (format nil "~A: ~A~A" (translate :flow)
                             (nome-direcao (building-rotation b))
                             (if (eq (building-kind b) :splitter)
                                 (format nil "/~A" (nome-direcao
                                                    (1+ (building-rotation b)))) ""))
                     (+ x 250) (+ y 54) '(108 255 215 255) :scale 1))
        (if receita
            (let* ((duracao (recipe-definition-duration receita))
                   (progresso (building-progress b))
                   (saida (first (recipe-definition-outputs receita)))
                   (taxa (if saida (/ (* 30.0 (cdr saida)) duracao) 0.0)))
              (draw-text (format nil "RECIPE ~A   ~A ~,1F/S"
                                 (building-recipe b) (translate :rate) taxa)
                         (+ x 14) (+ y 78) '(205 190 242 255) :scale 1)
              (draw-rect (+ x 14) (+ y 96) 316 8 '(19 34 43 255))
              (draw-rect (+ x 14) (+ y 96)
                         (* 316 (/ (min progresso duracao) (float duracao))) 8 cor))
            (draw-text (format nil "~A" (translate :contents))
                       (+ x 14) (+ y 82) '(165 188 200 255) :scale 1))
        (if itens
            (loop for (item . quantidade) in itens for coluna from 0
                  for ix = (+ x 14 (* coluna 108)) do
              (draw-rect ix (+ y 116) 100 38 '(10 23 32 255))
              (draw-sprite (folha-item item) (sprite-item item)
                           (+ ix 4) (+ y 120) 30 30)
              (draw-text (format nil "~A ~D" item quantidade)
                         (+ ix 38) (+ y 130) '(214 228 234 255) :scale 1))
            (draw-text (translate :empty) (+ x 14) (+ y 128)
                       '(113 137 150 255) :scale 1))))))

(defun desenhar-icone (kind x y tamanho &key (opacity 255))
  "Desenha o ícone estático e exclusivo de uma construção na interface."
  (draw-sprite (folha-construcao kind) (sprite-construcao kind) x y tamanho tamanho
               :opacity opacity))

(defparameter *categorias-ui* #(:all :logistics :production :power :defense))

(defun pertence-categoria-p (kind categoria)
  (let ((real (building-definition-category (find-building kind))))
    (case categoria
      (:all t)
      (:logistics (member real '(:logistics :fluid :rail)))
      (:production (member real '(:production :science)))
      (:power (eq real :power))
      (:defense (member real '(:defense :weapon :utility))))))

(defun indices-catalogo ()
  (loop for i below (length *selecionados*)
        when (pertence-categoria-p (aref *selecionados* i) *categoria-ui*) collect i))

(defconstant +itens-por-pagina-catalogo+ 32)

(defun paginas-catalogo (&optional (indices (indices-catalogo)))
  (max 1 (ceiling (length indices) +itens-por-pagina-catalogo+)))

(defun indices-pagina-catalogo ()
  (let* ((indices (indices-catalogo))
         (paginas (paginas-catalogo indices)))
    (setf *pagina-catalogo* (mod *pagina-catalogo* paginas))
    (let ((inicio (* *pagina-catalogo* +itens-por-pagina-catalogo+)))
      (subseq indices inicio (min (length indices)
                                  (+ inicio +itens-por-pagina-catalogo+))))))

(defun custo-resumido (kind)
  (let ((custo (building-definition-cost (find-building kind))))
    (if custo
        (format nil "~{~A ~D~^  ~}"
                (loop for (item . qtd) in (subseq custo 0 (min 2 (length custo)))
                      append (list (string-upcase (subseq (string item) 1
                                                         (min 5 (length (string item))))) qtd)))
        "FREE")))

(defun desenhar-chip-recurso (sprite quantidade x y cor)
  (draw-rect x y 92 34 '(8 16 25 242))
  (draw-rect x y 92 34 '(45 71 84 255) :outline t)
  (draw-sprite :terrain sprite (+ x 4) (+ y 3) 28 28)
  (draw-text quantidade (+ x 39) (+ y 11) cor :scale 1))

(defun desenhar-minimapa (mundo)
  (let* ((tamanho 218) (x0 (- (screen-width) tamanho 12)) (y0 88)
         (celula 9) (raio 10))
    (draw-rect x0 y0 tamanho (+ tamanho 24) '(4 9 15 244))
    (draw-rect x0 y0 tamanho (+ tamanho 24) '(63 102 118 255) :outline t)
    (draw-text (translate :map) (+ x0 10) (+ y0 8) '(112 245 220 255) :scale 1)
    (multiple-value-bind (cx cy zoom) (camera-position)
      (declare (ignore zoom))
      (let ((gx (floor cx +tamanho-celula+)) (gy (floor cy +tamanho-celula+)))
        (loop for dy from (- raio) to raio do
          (loop for dx from (- raio) to raio do
            (let* ((wx (+ gx dx)) (wy (+ gy dy)) (recurso (recurso-em mundo wx wy))
                   (x (+ x0 14 (* (+ dx raio) celula)))
                   (y (+ y0 31 (* (+ dy raio) celula))))
              (draw-rect x y 8 8
                         (case recurso
                           (:iron-ore '(126 151 169 255)) (:copper-ore '(211 104 61 255))
                           (:stone '(155 139 119 255)) (:coal '(43 48 59 255))
                           (:oil '(104 61 129 255)) (:water '(48 136 199 255))
                           (:asterion-crystal '(98 245 211 255))
                           (t (if (> (resource-noise mundo wx wy 31) .5)
                                  '(18 51 60 255) '(16 35 48 255))))))))
        (map-buildings
         (lambda (b)
           (let ((dx (- (building-x b) gx)) (dy (- (building-y b) gy)))
             (when (and (<= (- raio) dx raio) (<= (- raio) dy raio))
               (draw-rect (+ x0 16 (* (+ dx raio) celula))
                          (+ y0 33 (* (+ dy raio) celula)) 4 4
                          (if (eq (building-kind b) :core)
                              '(255 194 76 255) '(104 239 217 255)))))) mundo)
        (draw-rect (+ x0 9 (* raio celula)) (+ y0 26 (* raio celula)) 18 18
                   '(255 255 255 255) :outline t)))))

(defun desenhar-catalogo (mundo)
  (let* ((x0 (- (screen-width) 242)) (y0 88) (largura 230)
         (todos (indices-catalogo)) (indices (indices-pagina-catalogo)))
    (draw-rect x0 y0 largura (- (screen-height) y0 100) '(4 9 15 246))
    (draw-rect x0 y0 largura (- (screen-height) y0 100) '(63 102 118 255) :outline t)
    (draw-text (translate :build-menu) (+ x0 10) (+ y0 10) '(112 245 220 255) :scale 1)
    (draw-text (format nil "~D/~D" (1+ *pagina-catalogo*) (paginas-catalogo todos))
               (+ x0 190) (+ y0 10) '(151 181 194 255) :scale 1)
    (loop for categoria across *categorias-ui* for i from 0
          for bx = (+ x0 8 (* i 44)) do
      (draw-rect bx (+ y0 29) 40 24
                 (if (eq categoria *categoria-ui*) '(31 76 82 255) '(10 24 34 255)))
      (draw-rect bx (+ y0 29) 40 24
                 (if (eq categoria *categoria-ui*) '(104 245 211 255) '(47 76 91 255))
                 :outline t)
      (draw-text (subseq (translate categoria) 0 (min 4 (length (translate categoria))))
                 (+ bx 5) (+ y0 37) '(205 222 230 255) :scale 1))
    (loop for indice in indices for ordem from 0
          for coluna = (mod ordem 4) for linha = (floor ordem 4)
          for bx = (+ x0 8 (* coluna 54)) for by = (+ y0 61 (* linha 52))
          for kind = (aref *selecionados* indice)
          for liberada = (construcao-desbloqueada-p mundo kind) do
      (draw-rect bx by 48 46
                 (if (= indice *indice-selecao*) '(29 66 75 255) '(9 19 29 255)))
      (draw-rect bx by 48 46
                 (if (= indice *indice-selecao*) '(103 245 213 255) '(45 70 84 255))
                 :outline t)
      (desenhar-icone kind (+ bx 5) (+ by 3) 38
                      :opacity (cond ((not liberada) 58)
                                     ((= indice *indice-selecao*) 255) (t 195)))
      (unless liberada
        (draw-text "LOCK" (+ bx 7) (+ by 35) '(255 113 129 255) :scale 1)))
    (let ((kind (aref *selecionados* *indice-selecao*)))
      (draw-rect (+ x0 8) (- (screen-height) 155) 214 47 '(8 18 27 250))
      (draw-text (string-upcase (substitute #\Space #\- (string kind)))
                 (+ x0 16) (- (screen-height) 145) '(244 190 79 255) :scale 1)
      (draw-text (format nil "~A: ~A" (translate :cost) (custo-resumido kind))
                 (+ x0 16) (- (screen-height) 126) '(181 199 210 255) :scale 1))))

(defun desenhar-mundo (mundo)
  (multiple-value-bind (cx cy zoom) (camera-position)
    (declare (ignore zoom))
    (let* ((meia-x (ceiling (/ (screen-width) (* 2 +tamanho-celula+ *zoom*))))
           (meia-y (ceiling (/ (screen-height) (* 2 +tamanho-celula+ *zoom*))))
           (gx (floor (/ cx +tamanho-celula+))) (gy (floor (/ cy +tamanho-celula+))))
      (loop for y from (- gy meia-y 1) to (+ gy meia-y 1) do
        (loop for x from (- gx meia-x 1) to (+ gx meia-x 1) do
          (let ((px (* x +tamanho-celula+)) (py (* y +tamanho-celula+))
                (recurso (recurso-em mundo x y)))
            (draw-sprite :environment (indice-chao mundo x y)
                         px py +tamanho-celula+ +tamanho-celula+ :world t)
            (when recurso
              (let ((indice (indice-recurso-sprite recurso)))
                (when indice
                  (draw-sprite :terrain (+ 4 indice) px py +tamanho-celula+
                               +tamanho-celula+ :world t))))
            (unless recurso
              (let ((prop (indice-prop-ambiental mundo x y)))
                (when prop
                  (let ((tam (if (<= 16 prop 23) 54 42)))
                    (draw-sprite :environment prop
                                 (- px (/ (- tam 32) 2)) (- py (- tam 32))
                                 tam tam :world t)))))))))
    (map-buildings (lambda (b) (desenhar-construcao b :game-world mundo)) mundo)
    (map-entities
     (lambda (e)
       (let* ((x (* (entity-x e) +tamanho-celula+))
              (y (* (entity-y e) +tamanho-celula+))
              (kind (entity-kind e))
              (tam (cond ((eq kind :hive) 92) ((eq kind :engineer) 68) (t 50)))
              (animacao (animacao-unidade kind))
              (fase (* .11 (mod (entity-id e) 13))))
         (when (visivel-no-mundo-p x y)
           (unless (member kind '(:pulse-projectile :vfx-spark :vfx-smoke
                                  :vfx-impact :vfx-muzzle))
             (draw-rect (- x 13) (+ y 12) 26 8 '(0 0 0 80) :world t))
           (cond
             ((eq kind :pulse-projectile)
              (draw-animation :plasma-impact (- x 10) (- y 10) 20 20
                              :world t :time (* .035 (getf (entity-data e) :age 0))))
             ((member kind '(:vfx-spark :vfx-smoke :vfx-impact :vfx-muzzle))
              (let* ((dados (entity-data e)) (tam (getf dados :size 34))
                     (anim (case kind (:vfx-smoke :factory-smoke)
                                      (:vfx-impact :plasma-impact)
                                      (t :electric-spark))))
                (draw-animation anim (- x (/ tam 2)) (- y (/ tam 2)) tam tam
                                :world t :time (/ (getf dados :age 0) 30.0)
                                :opacity (max 20 (- 255 (* 10 (getf dados :age 0)))))))
             ((eq kind :engineer)
              ;; O corpo usa vistas direcionais; rotação geométrica deixava a
              ;; arte 3/4 de cabeça para baixo ao caminhar para norte.
              (draw-sprite :protagonist-animated (quadro-engenheiro mundo e)
                           (- x (/ tam 2)) (- y (* tam .72)) tam tam :world t))
             (animacao
               (draw-animation animacao (- x (/ tam 2)) (- y (/ tam 2)) tam tam
                               :world t :phase fase))
             (t
              (draw-sprite :units (sprite-unidade kind)
                           (- x (/ tam 2)) (- y (/ tam 2)) tam tam :world t)))))) mundo)))

(defun desenhar-previa-construcao (mundo)
  (multiple-value-bind (mx my) (mouse-position)
    (when (and (> my 76) (< my (- (screen-height) 104))
               (or (not *mostrar-catalogo*) (< mx (- (screen-width) 250))))
      (multiple-value-bind (wx wy) (screen-to-world mx my)
        (let* ((gx (floor wx +tamanho-celula+)) (gy (floor wy +tamanho-celula+))
               (x (* gx +tamanho-celula+)) (y (* gy +tamanho-celula+))
               (kind (aref *selecionados* *indice-selecao*))
               (livre (and (construcao-desbloqueada-p mundo kind)
                           (alcance-personagem-p mundo gx gy)
                           (null (building-at mundo gx gy)))))
          (draw-animation :placement-ring (- x 8) (- y 8) 48 48 :world t
                          :tint (if livre '(110 255 194) '(255 92 116)))
          (let ((opacidade (if livre 150 75))
                (angulo (* 90 *rotacao-construcao*)))
            (draw-sprite (folha-construcao kind) (sprite-construcao kind) (- x 7) (- y 10)
                         46 46 :world t :angle angulo :opacity opacidade)
            (when (member kind '(:belt :fast-belt :inserter :long-inserter
                                 :pump :rail-signal :station))
              (desenhar-seta-fluxo-em gx gy *rotacao-construcao*
                                      (if livre '(115 255 216 255)
                                          '(255 104 124 255))))))))))

(defun desenhar-hotbar (mundo)
  (let* ((largura 594) (x0 (floor (- (screen-width) largura) 2))
         (y (- (screen-height) 88)))
    (draw-rect (- x0 8) (- y 7) (+ largura 16) 78 '(4 8 15 238))
    (draw-rect (- x0 8) (- y 7) (+ largura 16) 78 '(64 91 112 255) :outline t)
    (loop for slot from -4 to 4
          for indice = (mod (+ *indice-selecao* slot) (length *selecionados*))
          for x = (+ x0 (* (+ slot 4) 66))
          for kind = (aref *selecionados* indice)
          for liberada = (construcao-desbloqueada-p mundo kind) do
      (draw-rect x y 58 58 (if (zerop slot) '(31 68 78 255) '(12 22 32 245)))
      (draw-rect x y 58 58 (if (zerop slot) '(93 245 211 255) '(53 79 95 255)) :outline t)
      (desenhar-icone kind (+ x 7) (+ y 5) 44
                      :opacity (cond ((not liberada) 48) ((zerop slot) 255) (t 185)))
      (draw-text (1+ (+ slot 4)) (+ x 4) (+ y 4) '(205 222 230 255) :scale 1)
      (when (zerop slot)
        (draw-rect (+ x 2) (+ y 54) 54 3 '(244 190 79 255))))))

(defun desenhar-alertas-fabrica (mundo)
  "Alertas compactos usam símbolo, texto e cor para não depender só da paleta."
  (let ((alertas (remove nil
                         (list
                          (when (plusp (dado mundo :unpowered-count 0))
                            (list (format nil "! ~A: ~D" (translate :power-deficit)
                                          (dado mundo :unpowered-count 0))
                                  '(255 190 72 255)))
                          (when (plusp (dado mundo :dry-miner-count 0))
                            (list (format nil "! ~A: ~D" (translate :miners-dry)
                                          (dado mundo :dry-miner-count 0))
                                  '(255 107 126 255)))
                          (when (plusp (dado mundo :blocked-output-count 0))
                            (list (format nil "> ~A: ~D" (translate :belts-blocked)
                                          (dado mundo :blocked-output-count 0))
                                  '(112 220 238 255)))))))
    (loop for (texto cor) in alertas for linha from 0
          for y = (+ 82 (* linha 27)) do
      (draw-rect 12 y 236 23 '(4 10 17 238))
      (draw-rect 12 y 4 23 cor)
      (draw-text (subseq texto 0 (min 36 (length texto))) 22 (+ y 8) cor :scale 1))))

(defun desenhar-ui (mundo)
  (draw-rect 0 0 (screen-width) 72 '(4 8 15 246))
  (draw-rect 0 71 (screen-width) 1 '(62 105 119 255))
  (draw-text (translate :title) 14 10 '(112 245 220 255) :scale 2)
  (let* ((c (dado mundo :chapter 1)) (nome (aref *capitulos* (1- c)))
         (inv (inventario-jogador mundo)) (sel (aref *selecionados* *indice-selecao*)))
    (draw-text (translate :chapter c nome) 14 40 '(205 222 230 255) :scale 1)
    (desenhar-chip-recurso 4 (inventory-count inv :iron-plate) 290 10 '(202 219 229 255))
    (desenhar-chip-recurso 5 (inventory-count inv :copper-plate) 388 10 '(245 156 98 255))
    (desenhar-chip-recurso 6 (inventory-count inv :stone) 486 10 '(207 190 174 255))
    (draw-text (translate :selected (string-upcase (string sel))) 290 52 '(244 190 79 255) :scale 1)
    (draw-text (format nil "ROT ~D  RECIPE ~A" *rotacao-construcao*
                       (aref *receitas-selecionaveis* *indice-receita*))
               605 52 '(196 176 239 255) :scale 1)
    (draw-text (translate :pollution (floor (world-pollution mundo))) 901 52 '(255 104 124 255) :scale 1)
    (let* ((satisfacao (dado mundo :power-satisfaction 1.0))
           (cor-energia (if (< satisfacao 1.0) '(255 184 68 255) '(86 225 196 255))))
      (draw-text (format nil "POWER ~D/~D  SAT ~D/100  KILLS ~D"
                         (dado mundo :power-used 0) (dado mundo :power-produced 0)
                         (round (* 100 satisfacao)) (dado mundo :kills 0))
                 605 18 '(190 222 232 255) :scale 1)
    (draw-rect 605 36 290 5 '(18 35 43 255))
      (draw-rect 605 36 (* 290 satisfacao) 5 cor-energia))
    (desenhar-hotbar mundo)
    (if *mostrar-catalogo* (desenhar-catalogo mundo) (desenhar-minimapa mundo))
    (desenhar-alertas-fabrica mundo)
    (when *mostrar-ajuda*
      (draw-rect 12 (- (screen-height) 117) 470 23 '(7 12 20 235))
      (draw-text (translate :help) 22 (- (screen-height) 110) '(175 197 207 255) :scale 1))
    (when *mostrar-estatisticas*
      (let ((painel-x (if *mostrar-catalogo* (- (screen-width) 572)
                          (- (screen-width) 330))))
      (draw-rect painel-x 88 312 238 '(6 13 22 246))
      (draw-rect painel-x 88 312 238 '(69 117 132 255) :outline t)
      (draw-text "PRODUCTION NETWORK" (+ painel-x 20) 104 '(112 245 220 255))
      (draw-text (format nil "BUILDINGS ~D" (world-building-count mundo))
                 (+ painel-x 20) 136 '(198 216 226 255))
      (draw-text (format nil "~A ~D / ~D" (translate :active-machines)
                         (dado mundo :active-building-count 0)
                         (world-building-count mundo))
                 (+ painel-x 20) 160 '(91 226 184 255))
      (draw-text (format nil "~A ~D" (translate :mined) (dado mundo :items-mined 0))
                 (+ painel-x 20) 184 '(168 210 226 255))
      (draw-text (format nil "~A ~D" (translate :crafted) (dado mundo :items-crafted 0))
                 (+ painel-x 20) 208 '(196 176 239 255))
      (draw-text (format nil "~A ~D" (translate :moved) (dado mundo :items-moved 0))
                 (+ painel-x 20) 232 '(112 245 220 255))
      (draw-text (format nil "POLLUTION ~D" (floor (world-pollution mundo)))
                 (+ painel-x 20) 256 '(255 130 143 255))
      (draw-text (format nil "SPEED ~DX" (time-scale))
                 (+ painel-x 204) 256 '(255 130 143 255))
      (draw-text (format nil "RESEARCH ~D" (length (world-research mundo)))
                 (+ painel-x 20) 280 '(244 190 79 255))
      (draw-text (format nil "POWER SAT ~D/100"
                         (round (* 100 (dado mundo :power-satisfaction 1.0))))
                 (+ painel-x 20) 304 '(244 190 79 255))))
    (when (< (world-tick mundo) (dado mundo :message-until 0))
      (let ((msg (dado mundo :message "")))
        (draw-rect 260 92 (- (screen-width) 520) 38 '(38 16 50 225))
        (draw-text msg 280 105 '(235 131 255 255) :scale 2)))
    (desenhar-inspetor-predio mundo)
    ))

(defun garantir-pausa () (unless (paused-p) (toggle-pause)))
(defun garantir-execucao () (when (paused-p) (toggle-pause)))
(defun caminho-quicksave () (merge-pathnames "saves/quicksave.save" *raiz*))

(defun desenhar-fundo-menu ()
  (draw-sprite :cover 0 0 0 (screen-width) (screen-height))
  (draw-rect 0 0 (screen-width) (screen-height) '(2 6 13 105))
  (draw-rect 0 0 520 (screen-height) '(3 8 16 222))
  (draw-sprite :logo 0 38 58 430 108)
  (draw-text (translate :menu-tagline) 76 184 '(241 185 76 255) :scale 1))

(defun desenhar-botao-menu (texto x y largura selecionado &key desabilitado)
  (multiple-value-bind (mx my) (mouse-position)
    (let ((hover (and (<= x mx (+ x largura)) (<= y my (+ y 46)))))
      (draw-rect x y largura 46
                 (cond (desabilitado '(9 14 22 220))
                       ((or selecionado hover) '(23 63 72 246))
                       (t '(8 20 31 240))))
      (draw-rect x y largura 46
                 (cond (desabilitado '(40 52 62 255))
                       ((or selecionado hover) '(105 244 214 255))
                       (t '(48 79 95 255))) :outline t)
      (when (or selecionado hover)
        (draw-rect x y 5 46 '(241 185 76 255)))
      (draw-text texto (+ x 22) (+ y 17)
                 (if desabilitado '(84 96 105 255) '(213 231 237 255)) :scale 1))))

(defparameter *opcoes-menu-principal* #(:new-game :continue :settings :mods :credits :quit))
(defparameter *opcoes-menu-pausa* #(:resume :save :settings :main-menu :quit))

(defun desenhar-menu-principal ()
  (desenhar-fundo-menu)
  (loop for chave across *opcoes-menu-principal* for i from 0
        for y = (+ 260 (* i 58)) do
    (desenhar-botao-menu (translate chave) 92 y 330 (= i *indice-menu*)
                         :desabilitado (and (eq chave :continue)
                                            (not (probe-file (caminho-quicksave))))))
  (draw-text +engine-version+ 92 (- (screen-height) 30) '(103 128 141 255) :scale 1)
  (when (> (length *mensagem-menu*) 0)
    (draw-text *mensagem-menu* 92 620 '(255 111 130 255) :scale 1)))

(defun desenhar-menu-pausa ()
  (draw-rect 0 0 (screen-width) (screen-height) '(2 5 10 175))
  (let ((x (- (/ (screen-width) 2) 205)))
    (draw-rect x 154 410 412 '(4 11 20 246))
    (draw-rect x 154 410 412 '(70 112 128 255) :outline t)
    (draw-text "PAUSED" (+ x 138) 180 '(112 245 220 255) :scale 3)
    (loop for chave across *opcoes-menu-pausa* for i from 0
          for y = (+ 238 (* i 58)) do
      (desenhar-botao-menu (translate chave) (+ x 40) y 330 (= i *indice-menu*)))))

(defun desenhar-configuracoes ()
  (desenhar-fundo-menu)
  (draw-text (translate :settings) 92 238 '(112 245 220 255) :scale 2)
  (let ((idioma (if (eq (current-language) :pt) "PORTUGUES" "ENGLISH")))
    (loop for texto in (list (format nil "~A: ~A" (translate :language) idioma)
                             (format nil "~A: ~D%" (translate :audio)
                                     (round (* 100 (/ *volume-configurado* 128.0))))
                             (format nil "~A: ~A" (translate :flashes)
                                     (if *reduzir-flashes* "ON" "OFF"))
                             (translate :back))
          for i from 0 for y = (+ 292 (* i 58)) do
      (desenhar-botao-menu texto 92 y 380 (= i *indice-menu*)))))

(defun desenhar-mods ()
  (desenhar-fundo-menu)
  (draw-text (translate :mods) 92 238 '(112 245 220 255) :scale 2)
  (draw-rect 92 290 380 184 '(7 17 27 242))
  (draw-text "LUMINOUS BELTS  1.0.0" 112 316 '(211 229 235 255) :scale 1)
  (draw-text "STATUS: ENABLED" 112 346 '(104 241 196 255) :scale 1)
  (draw-text "SCRIPT MODS ARE TRUSTED CODE" 112 394 '(245 182 76 255) :scale 1)
  (draw-text (format nil "FINGERPRINT ~A" (mod-fingerprint)) 112 424 '(154 174 185 255) :scale 1)
  (desenhar-botao-menu (translate :back) 92 500 330 t))

(defun desenhar-creditos ()
  (desenhar-fundo-menu)
  (draw-text (translate :credits) 92 238 '(112 245 220 255) :scale 2)
  (draw-text "ENGINE AND GAME: ANTIGONUS PROJECT" 92 302 '(213 231 237 255) :scale 1)
  (draw-text "ART: ORIGINAL PROCEDURAL AND GENERATED ASSETS" 92 334 '(181 199 210 255) :scale 1)
  (draw-text "SDL2 / SBCL / COMMON LISP" 92 366 '(181 199 210 255) :scale 1)
  (draw-text "NO TELEMETRY. MIT LICENSE." 92 414 '(104 241 196 255) :scale 1)
  (desenhar-botao-menu (translate :back) 92 478 330 t))

(defun posicao-tecnologia (indice)
  (values (+ 44 (* (mod indice 6) 200))
          (+ 118 (* (floor indice 6) 112))))

(defun estado-tecnologia (mundo id)
  (cond ((tecnologia-concluida-p mundo id) :completed)
        ((eq id (dado mundo :active-research)) :active)
        ((tecnologia-disponivel-p mundo id) :available)
        (t :locked)))

(defun cor-estado-tecnologia (estado)
  (case estado
    (:completed '(73 211 160 255)) (:active '(243 184 72 255))
    (:available '(85 211 230 255)) (t '(67 77 90 255))))

(defun desenhar-arvore-tecnologica (mundo)
  (draw-rect 0 0 (screen-width) (screen-height) '(3 8 15 247))
  (draw-text (translate :technology) 42 28 '(112 245 220 255) :scale 3)
  (draw-text "ARROWS SELECT  ENTER RESEARCH  T/ESC CLOSE" 44 72 '(159 182 194 255))
  ;; Dependências aparecem atrás dos nós e tornam os ramos legíveis.
  (loop for id across *ordem-tecnologias* for indice from 0
        for tech = (find-technology id) do
    (multiple-value-bind (x y) (posicao-tecnologia indice)
      (dolist (requisito (technology-definition-prerequisites tech))
        (let ((origem (position requisito *ordem-tecnologias*)))
          (when origem
            (multiple-value-bind (ox oy) (posicao-tecnologia origem)
              (draw-line (+ ox 90) (+ oy 36) (+ x 90) (+ y 36)
                         (if (tecnologia-concluida-p mundo requisito)
                             '(66 188 151 255) '(48 65 76 255)))))))))
  (loop for id across *ordem-tecnologias* for indice from 0
        for tech = (find-technology id) for estado = (estado-tecnologia mundo id) do
    (multiple-value-bind (x y) (posicao-tecnologia indice)
      (draw-rect x y 180 72 (if (= indice *indice-tecnologia*)
                                '(24 46 58 255) '(8 19 29 255)))
      (draw-rect x y 180 72 (if (= indice *indice-tecnologia*)
                                '(241 188 76 255) (cor-estado-tecnologia estado)) :outline t)
      (draw-text (subseq (string-upcase (technology-definition-name tech)) 0
                         (min 22 (length (technology-definition-name tech))))
                 (+ x 9) (+ y 12) '(214 231 238 255))
      (draw-text (translate estado) (+ x 9) (+ y 39)
                 (cor-estado-tecnologia estado))
      (draw-text (format nil "~D" (custo-tecnologia tech)) (+ x 148) (+ y 39)
                 '(192 174 238 255))))
  (let* ((id (aref *ordem-tecnologias* *indice-tecnologia*))
         (tech (find-technology id)) (estado (estado-tecnologia mundo id))
         (ativo (eq id (dado mundo :active-research)))
         (progresso (if ativo (dado mundo :research-progress 0) 0))
         (custo (custo-tecnologia tech)))
    (draw-rect 42 582 (- (screen-width) 84) 104 '(6 15 24 252))
    (draw-rect 42 582 (- (screen-width) 84) 104 (cor-estado-tecnologia estado) :outline t)
    (draw-text (technology-definition-name tech) 62 601 '(235 242 245 255) :scale 2)
    (draw-text (format nil "UNLOCKS: ~{~A~^, ~}" (technology-definition-unlocks tech))
               62 632 '(170 191 202 255))
    (draw-rect 62 657 520 10 '(17 30 39 255))
    (draw-rect 62 657 (* 520 (/ (min progresso custo) (float custo))) 10
               (cor-estado-tecnologia estado))
    (draw-text (format nil "~D / ~D" progresso custo) 598 657 '(218 229 234 255))))

(defun clicar-arvore-tecnologica (mundo x y)
  (loop for indice below (length *ordem-tecnologias*) do
    (multiple-value-bind (nx ny) (posicao-tecnologia indice)
      (when (and (<= nx x (+ nx 180)) (<= ny y (+ ny 72)))
        (setf *indice-tecnologia* indice)
        (selecionar-pesquisa mundo (aref *ordem-tecnologias* indice))
        (return t)))))

(defun renderizar (mundo alpha)
  (declare (ignore alpha))
  (case *tela-ui*
    (:main-menu (desenhar-menu-principal))
    (:settings (desenhar-configuracoes))
    (:mods (desenhar-mods))
    (:credits (desenhar-creditos))
    (:technology (desenhar-mundo mundo) (desenhar-arvore-tecnologica mundo))
    (otherwise
     (desenhar-mundo mundo)
     (when (eq *tela-ui* :playing) (desenhar-overlay-fabrica mundo))
     (when (eq *tela-ui* :playing) (desenhar-previa-construcao mundo))
     (desenhar-ui mundo)
     (when (eq *tela-ui* :pause) (desenhar-menu-pausa)))))

(defun personagem (mundo)
  (let (resultado)
    (map-entities (lambda (e) (when (eq (entity-kind e) :engineer)
                                (setf resultado e))) mundo)
    resultado))

(defun alcance-personagem-p (mundo gx gy &optional (alcance 9.0))
  (let ((p (personagem mundo)))
    (and p (<= (distancia (entity-x p) (entity-y p) (+ gx .5) (+ gy .5)) alcance))))

(defun mover-personagem (mundo)
  (let ((p (personagem mundo)))
    (when p
      (let ((dx (+ (if (input-down-p :scancode-d) 1.0 0.0)
                   (if (input-down-p :scancode-a) -1.0 0.0)
                   (aref *eixos-gamepad* 0)))
            (dy (+ (if (input-down-p :scancode-s) 1.0 0.0)
                   (if (input-down-p :scancode-w) -1.0 0.0)
                   (aref *eixos-gamepad* 1))))
        (let ((mag (sqrt (+ (* dx dx) (* dy dy)))))
          (setf (getf (entity-data p) :moving) (> mag .05))
          (if (> mag .05)
              (let ((nx (+ (entity-x p) (* .16 (/ dx mag))))
                    (ny (+ (entity-y p) (* .16 (/ dy mag)))))
                (setf (getf (entity-data p) :heading) (atan dy dx))
                (unless (building-at mundo (floor nx) (floor (entity-y p)))
                  (setf (entity-x p) nx))
                (unless (building-at mundo (floor (entity-x p)) (floor ny))
                  (setf (entity-y p) ny)))
              ;; Parado, o engenheiro acompanha o cursor sem trocar de quadro.
              (multiple-value-bind (mx my) (mouse-position)
                (multiple-value-bind (wx wy) (screen-to-world mx my)
                  (let ((alvo-x (/ wx +tamanho-celula+))
                        (alvo-y (/ wy +tamanho-celula+)))
                    (unless (and (< (abs (- alvo-x (entity-x p))) .05)
                                 (< (abs (- alvo-y (entity-y p))) .05))
                      (setf (getf (entity-data p) :heading)
                            (atan (- alvo-y (entity-y p))
                                  (- alvo-x (entity-x p))))))))))
        (multiple-value-bind (cx cy z) (camera-position)
          (declare (ignore z))
          (let ((alvo-x (* (entity-x p) +tamanho-celula+))
                (alvo-y (* (entity-y p) +tamanho-celula+)))
            (set-camera (+ cx (* .18 (- alvo-x cx)))
                        (+ cy (* .18 (- alvo-y cy))) *zoom*)))))))

(defun iniciar-acao-personagem (mundo acao &optional (duracao 14))
  (let ((p (personagem mundo)))
    (when p
      (setf (getf (entity-data p) :action) acao
            (getf (entity-data p) :action-until) (+ (world-tick mundo) duracao)))))

(defun disparar-em-tela (mundo sx sy)
  "Dispara na direção do cursor usando a animação ofensiva, nunca a atlas básica."
  (let ((p (personagem mundo)))
    (when p
      (multiple-value-bind (wx wy) (screen-to-world sx sy)
        (let* ((tx (/ wx +tamanho-celula+)) (ty (/ wy +tamanho-celula+))
               (dx (- tx (entity-x p))) (dy (- ty (entity-y p)))
               (mag (max .001 (sqrt (+ (* dx dx) (* dy dy)))))
               (nx (/ dx mag)) (ny (/ dy mag)))
          (setf (getf (entity-data p) :heading) (atan dy dx))
          (spawn-entity mundo :pulse-projectile
                        (+ (entity-x p) (* nx .8)) (+ (entity-y p) (* ny .8))
                        :data (list :vx (* nx .72) :vy (* ny .72)
                                    :age 0 :lifetime 45))
          (criar-efeito mundo :vfx-muzzle
                        (+ (entity-x p) (* nx .85)) (+ (entity-y p) (* ny .85))
                        :duracao 8 :tamanho 30)
          (iniciar-acao-personagem mundo :shoot 12)
          (play-sound :shoot) t)))))

(defun atualizar (mundo delta)
  (declare (ignore delta))
  (when (eq *tela-ui* :playing) (mover-personagem mundo)))

(defun celula-em-tela (sx sy)
  (multiple-value-bind (wx wy) (screen-to-world sx sy)
    (cons (floor wx +tamanho-celula+) (floor wy +tamanho-celula+))))

(defun registrar-construcao-recente (mundo predio)
  (let ((historico (cons (list :id (building-id predio) :tick (world-tick mundo))
                         (dado mundo :recent-builds nil))))
    (setf (dado mundo :recent-builds) (subseq historico 0 (min 32 (length historico))))))

(defun construir-na-celula (mundo x y)
  "Constrói uma célula e registra uma operação reversível de curta duração."
  (let* ((kind (aref *selecionados* *indice-selecao*)) (def (find-building kind)))
    (when (and (construcao-desbloqueada-p mundo kind)
               (alcance-personagem-p mundo x y)
               (null (building-at mundo x y)) (consumir-custo mundo def))
      (let ((predio
              (place-building mundo kind x y :rotation *rotacao-construcao*
                              :recipe (when (member kind
                                                    '(:stone-furnace :electric-furnace
                                                      :assembler :chemical-plant :refinery
                                                      :laboratory))
                                        (aref *receitas-selecionaveis*
                                              *indice-receita*)))))
        (when predio
          (registrar-construcao-recente mundo predio)
          (iniciar-acao-personagem mundo :building)
          (criar-efeito mundo :vfx-spark (+ x .5) (+ y .5) :duracao 18 :tamanho 42)
          (play-sound :build))
        predio))))

(defun construir-em-tela (mundo sx sy)
  (let ((celula (celula-em-tela sx sy)))
    (construir-na-celula mundo (car celula) (cdr celula))))

(defun rotacao-entre-celulas (origem destino)
  (let ((dx (- (car destino) (car origem)))
        (dy (- (cdr destino) (cdr origem))))
    (cond ((plusp dx) 0) ((plusp dy) 1) ((minusp dx) 2) ((minusp dy) 3))))

(defun iniciar-arrasto-construcao (mundo sx sy)
  (let* ((celula (celula-em-tela sx sy))
         (kind (aref *selecionados* *indice-selecao*)))
    (setf *ultima-celula-arrasto* celula
          *arrasto-construcao* (member kind *construcoes-arrastaveis*))
    (construir-na-celula mundo (car celula) (cdr celula))))

(defun continuar-arrasto-construcao (mundo sx sy)
  "Preenche uma linha Manhattan contínua, mesmo com eventos de mouse espaçados."
  (when (and *arrasto-construcao* *ultima-celula-arrasto*)
    (let ((destino (celula-em-tela sx sy))
          (atual *ultima-celula-arrasto*)
          (passos 0))
      (loop until (or (equal atual destino) (>= passos 64)) do
        (let* ((dx (- (car destino) (car atual)))
               (dy (- (cdr destino) (cdr atual)))
               (proximo (if (>= (abs dx) (abs dy))
                            (cons (+ (car atual) (signum dx)) (cdr atual))
                            (cons (car atual) (+ (cdr atual) (signum dy))))))
          (setf *rotacao-construcao* (rotacao-entre-celulas atual proximo))
          (construir-na-celula mundo (car proximo) (cdr proximo))
          (setf atual proximo)
          (incf passos)))
      (setf *ultima-celula-arrasto* destino))))

(defun predio-por-id (mundo id)
  (let (resultado)
    (map-buildings (lambda (b) (when (= id (building-id b)) (setf resultado b))) mundo)
    resultado))

(defun desfazer-ultima-construcao (mundo)
  "Remove a construção válida mais recente por até dez segundos e devolve 100%."
  (loop while (dado mundo :recent-builds nil) do
    (let* ((registro (pop (dado mundo :recent-builds)))
           (predio (predio-por-id mundo (getf registro :id))))
      (when (and predio (<= (- (world-tick mundo) (getf registro :tick)) 300)
                 (not (eq (building-kind predio) :core)))
        (dolist (custo (building-definition-cost (find-building (building-kind predio))))
          (inventory-add (inventario-jogador mundo) (car custo) (cdr custo)))
        (remove-building mundo predio)
        (criar-efeito mundo :vfx-smoke (+ (building-x predio) .5)
                      (+ (building-y predio) .5) :duracao 16 :tamanho 40)
        (setf (dado mundo :message) (translate :undo-complete)
              (dado mundo :message-until) (+ (world-tick mundo) 75))
        (play-sound :remove)
        (return-from desfazer-ultima-construcao predio))))
  (setf (dado mundo :message) (translate :nothing-to-undo)
        (dado mundo :message-until) (+ (world-tick mundo) 75))
  nil)
(defun remover-em-tela (mundo sx sy)
  (multiple-value-bind (wx wy) (screen-to-world sx sy)
    (let ((b (building-at mundo (floor wx +tamanho-celula+) (floor wy +tamanho-celula+))))
      (when (and b (alcance-personagem-p mundo (building-x b) (building-y b))
                 (not (eq (building-kind b) :core)))
        (devolver-custo mundo (find-building (building-kind b))) (remove-building mundo b)
        (iniciar-acao-personagem mundo :interact)
        (criar-efeito mundo :vfx-smoke (+ (building-x b) .5) (+ (building-y b) .5)
                      :duracao 24 :tamanho 48)
        (play-sound :remove)))))

(defun selecionar (delta)
  (setf *indice-selecao* (mod (+ *indice-selecao* delta) (length *selecionados*))))

(defun clique-interface (mundo x y)
  "Processa cliques na quickbar e no catálogo; retorna verdadeiro se consumido."
  (let* ((largura 594) (hx (floor (- (screen-width) largura) 2))
         (hy (- (screen-height) 88)))
    (cond
      ((and (<= hx x (+ hx largura)) (<= hy y (+ hy 58)))
       (let ((slot (floor (- x hx) 66)))
         (when (< slot 9)
           (let* ((indice (mod (+ *indice-selecao* (- slot 4))
                               (length *selecionados*)))
                  (kind (aref *selecionados* indice)))
             (when (construcao-desbloqueada-p mundo kind)
               (setf *indice-selecao* indice))))) t)
      ((and *mostrar-catalogo* (>= x (- (screen-width) 242))
            (>= y 88) (< y (- (screen-height) 100)))
       (let ((x0 (- (screen-width) 242)))
         (cond
           ((and (<= 117 y 141) (<= (+ x0 8) x (+ x0 228)))
            (let ((i (floor (- x (+ x0 8)) 44)))
              (when (< i (length *categorias-ui*))
                (setf *categoria-ui* (aref *categorias-ui* i)
                      *pagina-catalogo* 0))))
           ((>= y 149)
            (let* ((coluna (floor (- x (+ x0 8)) 54))
                   (linha (floor (- y 149) 52))
                   (ordem (+ coluna (* linha 4)))
                   (indices (indices-pagina-catalogo)))
              (when (and (<= 0 coluna 3) (<= 0 ordem) (< ordem (length indices)))
                (let ((indice (nth ordem indices)))
                  (when (construcao-desbloqueada-p mundo (aref *selecionados* indice))
                    (setf *indice-selecao* indice)))))))) t)
      (t nil))))

(defun abrir-sessao (mundo)
  (replace-world mundo)
  (setf *sessao-iniciada* t *tela-ui* :playing *indice-menu* 0 *mensagem-menu* ""
        *arrasto-construcao* nil *ultima-celula-arrasto* nil)
  (garantir-execucao))

(defun salvar-sessao (mundo)
  (handler-case
      (progn (save-game mundo (caminho-quicksave))
             (setf *mensagem-menu* "GAME SAVED") t)
    (error (e)
      (setf *mensagem-menu* (format nil "SAVE FAILED: ~A" e)) nil)))

(defun ativar-opcao-menu (mundo chave)
  (case chave
    (:new-game
     (abrir-sessao (new-game :seed *semente-atual* :difficulty *dificuldade-atual*)))
    (:continue
     (when (probe-file (caminho-quicksave))
       (handler-case (abrir-sessao (load-game (caminho-quicksave)))
         (error (e) (setf *mensagem-menu* (format nil "SAVE INVALID: ~A" e))))))
    (:settings
     (setf *retorno-configuracoes* *tela-ui* *tela-ui* :settings *indice-menu* 0))
    (:mods (setf *tela-ui* :mods *indice-menu* 0))
    (:credits (setf *tela-ui* :credits *indice-menu* 0))
    (:quit (stop-game))
    (:resume (setf *tela-ui* :playing *indice-menu* 0) (garantir-execucao))
    (:save (salvar-sessao mundo))
    (:main-menu
     (salvar-sessao mundo)
     (setf *tela-ui* :main-menu *indice-menu* 0)
     (garantir-pausa))
    (:back (setf *tela-ui* *retorno-configuracoes* *indice-menu* 0))))

(defun ativar-configuracao (indice)
  (case indice
    (0 (set-language (if (eq (current-language) :pt) :en :pt)))
    (1 (setf *volume-configurado*
             (cond ((< *volume-configurado* 32) 64)
                   ((< *volume-configurado* 80) 96)
                   ((< *volume-configurado* 112) 128)
                   (t 0)))
       (set-audio-volume *volume-configurado*))
    (2 (setf *reduzir-flashes* (not *reduzir-flashes*)))
    (3 (setf *tela-ui* *retorno-configuracoes* *indice-menu* 0))))

(defun quantidade-opcoes-menu ()
  (case *tela-ui* (:main-menu 6) (:pause 5) (:settings 4) (otherwise 1)))

(defun acionar-indice-menu (mundo)
  (case *tela-ui*
    (:main-menu (ativar-opcao-menu mundo (aref *opcoes-menu-principal* *indice-menu*)))
    (:pause (ativar-opcao-menu mundo (aref *opcoes-menu-pausa* *indice-menu*)))
    (:settings (ativar-configuracao *indice-menu*))
    ((:mods :credits) (setf *tela-ui* :main-menu *indice-menu* 0))))

(defun voltar-menu (mundo)
  (case *tela-ui*
    (:main-menu (stop-game))
    (:pause (ativar-opcao-menu mundo :resume))
    (:settings (setf *tela-ui* *retorno-configuracoes* *indice-menu* 0))
    ((:mods :credits) (setf *tela-ui* :main-menu *indice-menu* 0))))

(defun entrada-menu-teclado (mundo k)
  (cond
    ((sdl2:scancode= k :scancode-up)
     (setf *indice-menu* (mod (1- *indice-menu*) (quantidade-opcoes-menu))))
    ((sdl2:scancode= k :scancode-down)
     (setf *indice-menu* (mod (1+ *indice-menu*) (quantidade-opcoes-menu))))
    ((or (sdl2:scancode= k :scancode-return)
         (sdl2:scancode= k :scancode-kp-enter))
     (acionar-indice-menu mundo))
    ((sdl2:scancode= k :scancode-escape) (voltar-menu mundo))
    ((and (eq *tela-ui* :pause) (sdl2:scancode= k :scancode-space))
     (ativar-opcao-menu mundo :resume))
    ((and (eq *tela-ui* :settings)
          (or (sdl2:scancode= k :scancode-left) (sdl2:scancode= k :scancode-right)))
     (ativar-configuracao *indice-menu*)))
  t)

(defun indice-clique-menu (x y x0 y0 largura quantidade)
  (when (and (<= x0 x (+ x0 largura)) (>= y y0))
    (let ((indice (floor (- y y0) 58)))
      (when (and (< indice quantidade) (< (mod (- y y0) 58) 46)) indice))))

(defun entrada-menu-mouse (mundo botao x y)
  (when (= botao 1)
    (case *tela-ui*
      (:main-menu
       (let ((i (indice-clique-menu x y 92 260 330 6)))
         (when i (setf *indice-menu* i) (acionar-indice-menu mundo))))
      (:pause
       (let ((i (indice-clique-menu x y (- (/ (screen-width) 2) 165) 238 330 5)))
         (when i (setf *indice-menu* i) (acionar-indice-menu mundo))))
      (:settings
       (let ((i (indice-clique-menu x y 92 292 380 4)))
         (when i (setf *indice-menu* i) (ativar-configuracao i))))
      ((:mods :credits)
       (when (and (<= 92 x 422) (<= 478 y 546))
         (setf *tela-ui* :main-menu *indice-menu* 0)))))
  t)

(defun fechar-arvore-tecnologica ()
  (setf *tela-ui* :playing)
  (garantir-execucao)
  t)

(defun entrada-arvore-tecnologica (mundo tipo dados)
  (case tipo
    (:key-down
     (let ((k (first dados)))
       (cond ((or (sdl2:scancode= k :scancode-escape)
                  (sdl2:scancode= k :scancode-t))
              (fechar-arvore-tecnologica))
             ((sdl2:scancode= k :scancode-left)
              (setf *indice-tecnologia* (mod (1- *indice-tecnologia*) 24)))
             ((sdl2:scancode= k :scancode-right)
              (setf *indice-tecnologia* (mod (1+ *indice-tecnologia*) 24)))
             ((sdl2:scancode= k :scancode-up)
              (setf *indice-tecnologia* (mod (- *indice-tecnologia* 6) 24)))
             ((sdl2:scancode= k :scancode-down)
              (setf *indice-tecnologia* (mod (+ *indice-tecnologia* 6) 24)))
             ((or (sdl2:scancode= k :scancode-return)
                  (sdl2:scancode= k :scancode-kp-enter))
              (selecionar-pesquisa mundo
                                   (aref *ordem-tecnologias* *indice-tecnologia*)))))
     t)
    (:mouse-down
     (destructuring-bind (botao x y) dados
       (when (= botao 1) (clicar-arvore-tecnologica mundo x y))) t)
    (:controller-down
     (case (first dados)
       (0 (selecionar-pesquisa mundo (aref *ordem-tecnologias* *indice-tecnologia*)))
       (1 (fechar-arvore-tecnologica))) t)
    (otherwise t)))

(defun entrada (mundo tipo &rest dados)
  (if (eq *tela-ui* :technology)
      (entrada-arvore-tecnologica mundo tipo dados)
      (if (not (eq *tela-ui* :playing))
      (case tipo
        (:key-down (entrada-menu-teclado mundo (first dados)))
        (:mouse-down (apply #'entrada-menu-mouse mundo dados))
        (:controller-down
         (case (first dados) (0 (acionar-indice-menu mundo)) (1 (voltar-menu mundo))) t)
        (otherwise t))
      (case tipo
    (:key-down
     (let ((k (first dados)))
       (cond ((sdl2:scancode= k :scancode-escape)
              (setf *arrasto-construcao* nil *ultima-celula-arrasto* nil)
              (setf *tela-ui* :pause *indice-menu* 0) (garantir-pausa) t)
             ((sdl2:scancode= k :scancode-space)
              (setf *tela-ui* :pause *indice-menu* 0) (garantir-pausa) t)
             ((sdl2:scancode= k :scancode-q) (selecionar -1) t)
             ((sdl2:scancode= k :scancode-e) (selecionar 1))
             ((sdl2:scancode= k :scancode-h) (setf *mostrar-ajuda* (not *mostrar-ajuda*)))
             ((sdl2:scancode= k :scancode-b)
              (setf *mostrar-catalogo* (not *mostrar-catalogo*)))
             ((sdl2:scancode= k :scancode-t)
              (setf *tela-ui* :technology)
              (garantir-pausa) t)
             ((sdl2:scancode= k :scancode-tab)
              (setf *mostrar-estatisticas* (not *mostrar-estatisticas*)))
             ((sdl2:scancode= k :scancode-r)
              (setf *rotacao-construcao* (mod (1+ *rotacao-construcao*) 4)))
             ((sdl2:scancode= k :scancode-f)
              (setf *indice-receita* (mod (1+ *indice-receita*)
                                          (length *receitas-selecionaveis*))))
             ((sdl2:scancode= k :scancode-z)
              (desfazer-ultima-construcao mundo) t)
             ((sdl2:scancode= k :scancode-x)
              (multiple-value-bind (mx my) (mouse-position)
                (disparar-em-tela mundo mx my))))))
    (:mouse-down
     (destructuring-bind (botao x y) dados
       (case botao
         (1 (if (clique-interface mundo x y)
                (setf *arrasto-construcao* nil *ultima-celula-arrasto* nil)
                (iniciar-arrasto-construcao mundo x y)))
         (2 (disparar-em-tela mundo x y))
         (3 (unless (clique-interface mundo x y) (remover-em-tela mundo x y))))))
    (:mouse-move
     (destructuring-bind (x y) dados
       (continuar-arrasto-construcao mundo x y)))
    (:mouse-up
     (when (= (first dados) 1)
       (setf *arrasto-construcao* nil *ultima-celula-arrasto* nil)))
    (:mouse-wheel
     (let ((dy (second dados)))
       (multiple-value-bind (mx my) (mouse-position)
         (declare (ignore my))
         (if (and *mostrar-catalogo* (>= mx (- (screen-width) 242)))
             (setf *pagina-catalogo*
                   (mod (+ *pagina-catalogo* (if (minusp dy) 1 -1))
                        (paginas-catalogo)))
             (progn
               (setf *zoom* (max .5 (min 2.5 (+ *zoom* (* dy .1)))))
               (multiple-value-bind (x y z) (camera-position)
                 (declare (ignore z)) (set-camera x y *zoom*)))))))
    (:controller-axis
     (let ((eixo (first dados)) (valor (/ (second dados) 32767.0)))
       (when (< eixo 4) (setf (aref *eixos-gamepad* eixo) (if (< (abs valor) .18) 0.0 valor)))))
    (:controller-down
     (case (first dados) (0 (construir-em-tela mundo *cursor-gamepad-x* *cursor-gamepad-y*))
           (1 (remover-em-tela mundo *cursor-gamepad-x* *cursor-gamepad-y*))
           (2 (disparar-em-tela mundo *cursor-gamepad-x* *cursor-gamepad-y*))
           (4 (selecionar -1)) (5 (selecionar 1))
           (6 (setf *tela-ui* :pause *indice-menu* 0) (garantir-pausa))))))))

(defun iniciar-mundo (mundo)
  (declare (ignore mundo))
  (set-clear-color 5 8 15) (set-camera 0 0 1.0)
  (register-sprite-sheet :cover
                         (merge-pathnames "assets/store/png/cover.png" *raiz*) 1 1)
  (register-sprite-sheet :logo
                         (merge-pathnames "assets/store/png/logo.png" *raiz*) 1 1)
  (register-sprite-sheet :machines (merge-pathnames "assets/sprites/machines-atlas.png" *raiz*) 6 4)
  (register-sprite-sheet :buildings
                         (merge-pathnames "assets/sprites/buildings-static.png" *raiz*) 6 6)
  (register-sprite-sheet :buildings-v2
                         (merge-pathnames "assets/sprites/buildings-expansion-v2.png" *raiz*) 4 4)
  (register-sprite-sheet :items
                         (merge-pathnames "assets/sprites/items-static.png" *raiz*) 8 6)
  (register-sprite-sheet :items-v2
                         (merge-pathnames "assets/sprites/items-expansion-v2.png" *raiz*) 5 5)
  (register-sprite-sheet :environment
                         (merge-pathnames "assets/sprites/environment-static.png" *raiz*) 8 6)
  (register-sprite-sheet :terrain (merge-pathnames "assets/sprites/terrain-atlas.png" *raiz*) 4 4)
  (register-sprite-sheet :units (merge-pathnames "assets/sprites/units-atlas.png" *raiz*) 4 3)
  (register-sprite-sheet :machines-animated
                         (merge-pathnames "assets/sprites/machines-animated.png" *raiz*) 8 4)
  (register-sprite-sheet :logistics-animated
                         (merge-pathnames "assets/sprites/logistics-animated.png" *raiz*) 8 4)
  (register-sprite-sheet :units-animated
                         (merge-pathnames "assets/sprites/units-animated.png" *raiz*) 8 4)
  (register-sprite-sheet :wildlife-animated
                         (merge-pathnames "assets/sprites/wildlife-animated.png" *raiz*) 8 4)
  (register-sprite-sheet :effects-animated
                         (merge-pathnames "assets/sprites/effects-animated.png" *raiz*) 8 4)
  (register-sprite-sheet :protagonist-animated
                         (merge-pathnames "assets/sprites/protagonist-animated.png" *raiz*) 8 4)
  (register-sprite-sheet :weapons-animated
                         (merge-pathnames "assets/sprites/weapons-animated.png" *raiz*) 8 4)
  (defanimation :miner-active :sheet :machines-animated :start 0 :frames 8 :fps 9)
  (defanimation :furnace-active :sheet :machines-animated :start 8 :frames 8 :fps 7)
  (defanimation :assembler-active :sheet :machines-animated :start 16 :frames 8 :fps 10)
  (defanimation :chemical-active :sheet :machines-animated :start 24 :frames 8 :fps 6)
  (defanimation :belt-moving :sheet :logistics-animated :start 0 :frames 8 :fps 10)
  (defanimation :fast-belt-moving :sheet :logistics-animated :start 8 :frames 8 :fps 16)
  (defanimation :inserter-working :sheet :logistics-animated :start 16 :frames 8 :fps 9)
  (defanimation :rail-signal-active :sheet :logistics-animated :start 24 :frames 8 :fps 5)
  (defanimation :commander-hover :sheet :units-animated :start 0 :frames 8 :fps 8)
  (defanimation :crawler-walk :sheet :units-animated :start 8 :frames 8 :fps 9)
  (defanimation :spitter-walk :sheet :units-animated :start 16 :frames 8 :fps 7)
  (defanimation :brute-walk :sheet :units-animated :start 24 :frames 8 :fps 6)
  (defanimation :glow-mites :sheet :wildlife-animated :start 0 :frames 8 :fps 9)
  (defanimation :crystal-grazer :sheet :wildlife-animated :start 8 :frames 8 :fps 6)
  (defanimation :sky-jelly :sheet :wildlife-animated :start 16 :frames 8 :fps 7)
  (defanimation :shellback :sheet :wildlife-animated :start 24 :frames 8 :fps 5)
  (defanimation :electric-spark :sheet :effects-animated :start 0 :frames 8 :fps 12)
  (defanimation :factory-smoke :sheet :effects-animated :start 8 :frames 8 :fps 7)
  (defanimation :plasma-impact :sheet :effects-animated :start 16 :frames 8 :fps 11)
  (defanimation :placement-ring :sheet :effects-animated :start 24 :frames 8 :fps 8)
  ;; Os quadros escolhidos compartilham a orientação leste; o renderer aplica
  ;; o ângulo do personagem, evitando rotação acidental dentro do próprio ciclo.
  (defanimation :engineer-idle :sheet :protagonist-animated :start 1 :frames 1 :fps 1)
  (defanimation :engineer-walk :sheet :protagonist-animated :start 9 :frames 2 :fps 7)
  (defanimation :engineer-build :sheet :protagonist-animated :start 18 :frames 2 :fps 7)
  (defanimation :engineer-interact :sheet :protagonist-animated :start 24 :frames 2 :fps 5)
  ;; A atlas ofensiva é intencionalmente independente das ações do corpo básico.
  (defanimation :engineer-aim-pulse :sheet :weapons-animated :start 0 :frames 8 :fps 8)
  (defanimation :engineer-shoot-pulse :sheet :weapons-animated :start 8 :frames 8 :fps 12)
  (defanimation :engineer-mining-laser :sheet :weapons-animated :start 16 :frames 8 :fps 9)
  (defanimation :engineer-shock-baton :sheet :weapons-animated :start 24 :frames 8 :fps 11)
  (register-sound :build (merge-pathnames "assets/audio/build.wav" *raiz*))
  (register-sound :remove (merge-pathnames "assets/audio/remove.wav" *raiz*))
  (register-sound :shoot (merge-pathnames "assets/audio/shoot.wav" *raiz*))
  (register-sound :impact (merge-pathnames "assets/audio/impact.wav" *raiz*))
  (set-audio-volume *volume-configurado*)
  (setf *indice-menu* 0 *mensagem-menu* ""
        *pagina-catalogo* 0
        *tela-ui* (if *pular-menu-principal* :playing :main-menu)
        *sessao-iniciada* *pular-menu-principal*
        *arrasto-construcao* nil *ultima-celula-arrasto* nil)
  (if *pular-menu-principal* (garantir-execucao) (garantir-pausa))
  (engine-log :info "Asterion Assembly iniciado; scripts de mods são código confiável."))
(defun encerrar-mundo (mundo)
  (when *sessao-iniciada*
    (handler-case (save-game mundo (merge-pathnames "quicksave.save" (dado mundo :save-dir)))
      (error (e) (engine-log :error "Quicksave falhou: ~A" e)))))

(defgame *jogo-asterion*
  :title "Asterion Assembly" :width 1280 :height 720
  :start #'iniciar-mundo :update #'atualizar :render #'renderizar
  :input #'entrada :shutdown #'encerrar-mundo)

(defun configurar (&optional (mundo nil))
  (declare (ignore mundo)) *jogo-asterion*)

(defun preparar (&key safe-mode)
  (reset-engine) (register-content) (registrar-sistemas)
  (load-mods (discover-mods (merge-pathnames "mods/" *raiz*)) :safe-mode safe-mode))

(defun start (&key (language :en) (seed 1701) (difficulty :standard) safe-mode)
  (setf *semente-atual* seed *dificuldade-atual* difficulty *pular-menu-principal* nil)
  (preparar :safe-mode safe-mode) (set-language language)
  (run-game (configurar) :world (new-game :seed seed :difficulty difficulty)))

(defun headless-demo (&key (ticks 1800) (seed 1701))
  (preparar :safe-mode t)
  (let ((mundo (new-game :seed seed)))
    (place-building mundo :miner -4 -4)
    (place-building mundo :miner 4 -4)
    (place-building mundo :stone-furnace -3 -4 :recipe :smelt-iron)
    (run-game (configurar) :world mundo :headless t :ticks ticks)))
