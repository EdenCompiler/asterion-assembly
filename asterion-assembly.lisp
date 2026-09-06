;;;; Asterion Assembly — jogo completo de demonstração comercial da Antigonus.
;;;; O código do jogo é pt-BR; chamadas públicas da engine permanecem em inglês.

(defpackage #:asterion-assembly
  (:use #:cl #:antigonus)
  (:export #:start #:new-game #:headless-demo #:register-content #:run-smoke))
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
    :signal-lamp :programmable-alarm
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
(defvar *gamepad-ativo* nil)
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
(defvar *resolucao-configurada* '(1280 720))
(defvar *tela-cheia-configurada* nil)
(defvar *escala-ui-configurada* 1)
(defvar *paleta-configurada* nil)
(defvar *perfil-gravavel* t)
(defvar *mensagem-menu* "")
(defvar *indice-tecnologia* 0)
(defvar *arrasto-construcao* nil)
(defvar *ultima-celula-arrasto* nil)
(defvar *modo-circuito* nil)
(defvar *cor-fio-circuito* :red)
(defvar *origem-fio-circuito* nil)
(defvar *porta-origem-circuito* :main)
(defvar *campo-circuito-gamepad* 0)
(defvar *pagina-dispositivo-circuito* 0)
(defvar *predio-circuito-selecionado* nil)
(defparameter *sinais-circuito-ui*
  #((:item :iron-plate) (:item :copper-plate) (:item :gear)
    (:item :iron-ore) (:item :copper-ore) (:item :coal)
    (:fluid :water) (:fluid :oil) (:virtual :signal-a)
    (:virtual :signal-b) (:virtual :signal-check) (:virtual :power)
    (:virtual :pollution)))
(defparameter *operadores-circuito-ui* #(:> :< := :!= :>= :<=))
(defparameter *modos-sensor-ui*
  #(:inventory :belt :flow :fluid :pressure :power :pollution :machine))
(defparameter *construcoes-arrastaveis*
  '(:belt :fast-belt :pipe :rail :wall :power-pole))
(defparameter *ordem-tecnologias*
  #(:automation :circuit-networks :logistics :steel :electricity :defense :fluids :oil :solar
    :advanced-circuits :railway :rail-signals :systems-science :laser-defense
    :drones :logistic-network :advanced-smelting :rocketry :crystal-science
    :plasma :rail-capacity :factory-speed-1 :factory-speed-2
    :military-logistics :hive-assault :bulk-logistics :fluid-pressure
    :power-storage :automated-trains :chain-signals
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
               (:build-circuit-sensor ((:circuit . 2) (:iron-plate . 1)) ((:circuit-sensor . 1)) 60 :construction)
               (:build-arithmetic-combinator ((:circuit . 4) (:sensor . 1)) ((:arithmetic-combinator . 1)) 75 :construction)
               (:build-decider-combinator ((:circuit . 4) (:sensor . 2)) ((:decider-combinator . 1)) 75 :construction)
               (:build-signal-lamp ((:circuit . 2) (:copper-wire . 2)) ((:signal-lamp . 1)) 40 :construction)
               (:build-programmable-alarm ((:circuit . 3) (:sensor . 1)) ((:programmable-alarm . 1)) 55 :construction)
               (:build-chain-signal ((:rail-chain-controller . 1) (:steel-plate . 1)) ((:chain-signal . 1)) 60 :construction)))
    (destructuring-bind (id entradas saidas duracao categoria) r
      (defrecipe id :inputs entradas :outputs saidas :duration duracao
                 :category categoria))))

(defun comportamento-circuito-predio (id)
  (case id
    (:circuit-sensor :sensor)
    (:arithmetic-combinator :arithmetic)
    (:decider-combinator :decider)
    (:signal-lamp :lamp)
    (:programmable-alarm :alarm)
    ((:inserter :long-inserter :stack-inserter :splitter :filter-splitter
      :pump :directional-pump :stone-furnace :electric-furnace :assembler
      :chemical-plant :refinery) :actuator)))

(defun portas-circuito-predio (id)
  (if (member id '(:arithmetic-combinator :decider-combinator))
      '(:input :output)
      (when (comportamento-circuito-predio id) '(:main))))

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
        :category categoria :color cor :cost custo :power energia
        :circuit-ports (portas-circuito-predio id)
        :circuit-connectors (when (portas-circuito-predio id) '(:red :green))
        :circuit-behavior (comportamento-circuito-predio id))))
  (dolist (b '((:underground-belt :logistics ((:belt-part . 6)) 2 (1 . 1) (:item-in :item-out) (:belt :underground))
               (:filter-splitter :logistics ((:belt-part . 5) (:sensor . 1)) 3 (2 . 1) (:item-in :item-out-a :item-out-b) (:belt :filter))
               (:stack-inserter :logistics ((:inserter-part . 3) (:motor . 1)) 4 (1 . 1) (:item-in :item-out) (:inserter :stacking))
               (:loader :logistics ((:belt-part . 8) (:motor . 2)) 5 (2 . 1) (:item-in-a :item-in-b :item-out) (:belt :loader))
               (:boiler :power ((:steel-plate . 5) (:pipe . 4)) -22 (2 . 2) (:fluid-in :steam-out) (:generator :fluid))
               (:directional-pump :fluid ((:pump-unit . 1) (:pipe . 2)) 5 (1 . 1) (:fluid-in :fluid-out) (:pump :directional))
               (:circuit-sensor :circuit ((:circuit . 2) (:iron-plate . 1)) 2 (1 . 1) (:signal-out) (:sensor))
               (:arithmetic-combinator :circuit ((:circuit . 4) (:sensor . 1)) 2 (1 . 1) (:signal-in :signal-out) (:combinator :arithmetic))
               (:decider-combinator :circuit ((:circuit . 4) (:sensor . 2)) 2 (1 . 1) (:signal-in :signal-out) (:combinator :decider))
               (:signal-lamp :circuit ((:circuit . 2) (:copper-wire . 2)) 1 (1 . 1) (:signal-in) (:display :lamp))
               (:programmable-alarm :circuit ((:circuit . 3) (:sensor . 1)) 1 (1 . 1) (:signal-in) (:display :alarm))
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
        :circuit-connectors (when (or (member :signal-in portas)
                                      (portas-circuito-predio id)) '(:red :green))
        :circuit-ports (portas-circuito-predio id)
        :circuit-behavior (comportamento-circuito-predio id)
        :tags tags))))

(defun registrar-tecnologias ()
  (loop for (id nome custo desbloqueios prereq) in
    '((:automation "Automation" 20 (:assembler :inserter) nil)
      (:circuit-networks "Circuit networks" 30
       (:circuit-sensor :arithmetic-combinator :decider-combinator
        :signal-lamp :programmable-alarm :wire-red :wire-green)
       (:automation))
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
    (:undo-complete "CONSTRUCTION UNDONE") (:nothing-to-undo "NOTHING TO UNDO")
    (:reward "CHAPTER REWARD") (:out-of-range "OUT OF BUILD RANGE")
    (:occupied "TILE OCCUPIED") (:locked-building "TECHNOLOGY REQUIRED")
    (:objective-progress "PROGRESS") (:next-reward "REWARD")
    (:circuit-mode "CIRCUIT NETWORK") (:wire-cost "WIRE")
    (:circuit-help "C CLOSE  X COLOR  LMB LINK  RMB CUT")
    (:select-device "SELECT A CIRCUIT DEVICE") (:sensor-mode "MODE")
    (:signal "SIGNAL") (:operator "OPERATOR") (:value "VALUE")
    (:live-signals "LIVE SIGNALS"))
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
    (:undo-complete "CONSTRUCAO DESFEITA") (:nothing-to-undo "NADA PARA DESFAZER")
    (:reward "RECOMPENSA DO CAPITULO") (:out-of-range "FORA DO ALCANCE")
    (:occupied "CELULA OCUPADA") (:locked-building "TECNOLOGIA NECESSARIA")
    (:objective-progress "PROGRESSO") (:next-reward "RECOMPENSA")
    (:circuit-mode "REDE DE CIRCUITOS") (:wire-cost "FIO")
    (:circuit-help "C FECHA  X COR  LMB LIGA  RMB CORTA")
    (:select-device "SELECIONE UM DISPOSITIVO") (:sensor-mode "MODO")
    (:signal "SINAL") (:operator "OPERADOR") (:value "VALOR")
    (:live-signals "SINAIS AO VIVO")))

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

(defun coordenada-fauna (valor)
  "Quantiza movimento a 1/65536 tile, removendo resíduos da libm entre sistemas."
  (/ (round (* valor 65536)) 65536d0))

(defun povoar-fauna-passiva (mundo &optional (quantidade 24))
  (dotimes (i quantidade)
    (let* ((angulo (* 2 pi (resource-noise mundo i 1 811)))
           (raio (+ 10 (* 22 (resource-noise mundo i 2 823))))
           (tipo (nth (mod i 4) '(:glow-mite :crystal-grazer :sky-jelly :shellback))))
      (spawn-entity mundo tipo (coordenada-fauna (* raio (cos angulo)))
                    (coordenada-fauna (* raio (sin angulo)))
                    :hp 60 :data (list :heading angulo :age 0)))))

(defun inventario-jogador (mundo) (dado mundo :player-inventory))
(defun adicionar-inicial (inventario)
  (dolist (p '((:iron-plate . 120) (:copper-plate . 80) (:stone . 100)
               (:gear . 40) (:circuit . 30) (:sensor . 8) (:inserter-part . 12)
               (:wire-red . 20) (:wire-green . 20) (:rail-part . 80)))
    (inventory-add inventario (car p) (cdr p))))

(defun new-game (&key (seed 1701) (difficulty :standard))
  (let ((mundo (make-world :seed seed :difficulty difficulty))
        (inventario (make-hash-table :test #'equal)))
    (adicionar-inicial inventario)
    (setf (dado mundo :player-inventory) inventario
          (dado mundo :chapter) 1 (dado mundo :chapter-progress) 0
          (dado mundo :chapter-start-tick) 0
          (dado mundo :unlocked) '(:core :belt :inserter :miner :stone-furnace :power-pole)
          (dado mundo :message) "ESTABLISH THE FIRST EXTRACTION LINE"
          (dado mundo :message-until) 300 (dado mundo :kills) 0
          (dado mundo :power-produced) 50 (dado mundo :power-used) 0
          (dado mundo :sandbox) nil (dado mundo :hive-spawned) nil
          (dado mundo :active-research) :automation (dado mundo :research-progress) 0
          (dado mundo :save-dir) (diretorio-saves))
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
       (getf (building-state predio) :circuit-enabled t)
       (or (not (plusp (building-definition-power
                        (find-building (building-kind predio)))))
           (getf (building-state predio) :powered t))))

(defun transportador-p (predio)
  (and predio (member (building-kind predio)
                      '(:belt :fast-belt :splitter :underground-belt
                        :filter-splitter :loader))))

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

(defun sistema-fluidos-legado (mundo)
  "Implementação anterior mantida temporariamente como referência de diagnóstico."
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

(defun distribuir-volume-fluido (mundo rede)
  "Distribui volume inteiro proporcionalmente, sem perder o resto da divisão."
  (let ((restante (round (fluid-network-volume rede)))
        (capacidade (round (fluid-network-capacity rede))))
    (dolist (id (fluid-network-nodes rede))
      (let* ((b (predio-por-id mundo id)) (limite (round (capacidade-fluido b)))
             (parte (if (plusp capacidade) (floor (* restante limite) capacidade) 0)))
        (setf (getf (building-state b) :fluid-volume) parte
              (getf (building-state b) :fluid) (fluid-network-fluid rede))
        (decf restante parte) (decf capacidade limite)))
    (setf (fluid-network-pressure rede)
          (/ (fluid-network-volume rede) (max 1.0 (fluid-network-capacity rede))))))

(defun rede-fluido-predio (mundo predio)
  (and predio (gethash (getf (building-state predio) :fluid-network)
                       (world-fluid-networks mundo))))

(defun sistema-fluidos (mundo)
  "Bombas separam redes; volumes locais persistentes conservam fluido ao reconstruir."
  (let ((redes (make-hash-table)))
    (dolist (componente (componentes-cardinais mundo
                           (set-difference *tipos-fluido* '(:pump :directional-pump))))
      (let* ((id (building-id (first componente)))
             (fluidos (remove-duplicates (mapcan #'fluidos-no-predio componente)))
             (capacidade (reduce #'+ componente :key #'capacidade-fluido))
             (conflito (> (length fluidos) 1))
             (fluido (first fluidos))
             (volume (loop for b in componente sum (getf (building-state b) :fluid-volume 0))))
        (dolist (b componente)
          (setf (getf (building-state b) :fluid-conflict) conflito
                (getf (building-state b) :fluid-network) id)
          (unless conflito
            (let ((quantidade (min (inventory-count (building-inventory b) fluido)
                                   (max 0 (- (round capacidade) volume)))))
              (incf volume quantidade)
              (when (plusp quantidade)
                (inventory-remove (building-inventory b) fluido quantidade)))))
        (unless conflito
          (setf (gethash id redes)
                (make-fluid-network :id id :fluid fluido :volume (float volume)
                  :capacity capacidade :nodes (mapcar #'building-id componente))))))
    (setf (world-fluid-networks mundo) redes)
    (let (bombas)
      (map-buildings (lambda (b) (when (member (building-kind b) '(:pump :directional-pump))
                                  (push b bombas))) mundo)
      (dolist (b (sort bombas #'< :key #'building-id))
        (when (predio-operacional-p b)
          (let* ((d (direcao (mod (+ (building-rotation b)
                                    (if (getf (building-state b) :circuit-reverse) 2 0)) 4)))
                 (x (building-x b)) (y (building-y b))
                 (origem (rede-fluido-predio mundo (building-at mundo (- x (car d)) (- y (cdr d)))))
                 (destino (rede-fluido-predio mundo (building-at mundo (+ x (car d)) (+ y (cdr d)))))
                 (agua (and (null origem) (or (eq (recurso-em mundo x y) :water)
                                             (eq (recurso-em mundo (- x (car d)) (- y (cdr d))) :water))))
                 (fluido (if agua :water (and origem (fluid-network-fluid origem)))))
            (when (and destino fluido (not (eq origem destino))
                       (or (null (fluid-network-fluid destino))
                           (eq fluido (fluid-network-fluid destino))))
              (let ((qtd (min 8 (if agua 8 (round (fluid-network-volume origem)))
                              (round (- (fluid-network-capacity destino)
                                        (fluid-network-volume destino))))))
                (when (plusp qtd)
                  (unless agua (decf (fluid-network-volume origem) qtd))
                  (incf (fluid-network-volume destino) qtd)
                  (setf (fluid-network-fluid destino) fluido
                        (getf (building-state b) :last-fluid-transfer) (world-tick mundo))
                  (incf (getf (building-state b) :fluid-transferred 0) qtd))))))))
    (maphash (lambda (id rede) (declare (ignore id)) (distribuir-volume-fluido mundo rede)) redes)))

(defun redes-circuito-predio (mundo predio &optional saida)
  (circuit-network-for-port
   mundo predio (if (member (building-kind predio)
                            '(:arithmetic-combinator :decider-combinator))
                   (if saida :output :input) :main)))

(defun sinais-redes-circuito (redes)
  "Soma as cores na entrada sem criar uma ponte entre seus grafos."
  (let ((resultado (make-hash-table :test #'equal)))
    (dolist (rede redes resultado)
      (maphash (lambda (sinal valor) (incf (gethash sinal resultado 0) valor))
               (circuit-network-signals rede)))))

(defun valor-circuito (sinais sinal)
  (gethash sinal sinais 0))

(defun comparar-circuito (a operador b)
  (case operador
    (:< (< a b)) (:<= (<= a b)) (:= (= a b)) (:!= (/= a b))
    (:>= (>= a b)) (:> (> a b)) (otherwise nil)))

(defun calcular-circuito (a operador b)
  (case operador
    (:+ (+ a b)) (:- (- a b)) (:* (* a b))
    (:/ (if (zerop b) 0 (truncate a b))) (:mod (if (zerop b) 0 (mod a b)))
    (:min (min a b)) (:max (max a b)) (otherwise 0)))

(defun escrever-em-redes (redes sinal valor &key proximo)
  (dolist (rede redes)
    (let ((tabela (if proximo (circuit-network-next-signals rede)
                      (circuit-network-signals rede))))
      (incf (gethash sinal tabela 0) valor)
      (when (zerop (gethash sinal tabela)) (remhash sinal tabela))
      (incf (circuit-network-revision rede)))))

(defun predio-frontal (mundo predio)
  (let ((d (direcao (building-rotation predio))))
    (building-at mundo (+ (building-x predio) (car d))
                 (+ (building-y predio) (cdr d)))))

(defun soma-pistas (predio item)
  (let ((pistas (getf (building-state predio) :belt-lanes)) (total 0))
    (when pistas
      (loop for pista across pistas do
        (dotimes (i (belt-lane-count pista))
          (when (or (null item) (eq item (aref (belt-lane-items pista) i)))
            (incf total (aref (belt-lane-stacks pista) i))))))
    total))

(defun valor-sensor-circuito (mundo sensor configuracao)
  (let* ((modo (getf (building-state sensor) :sensor-mode :inventory))
         (alvo (or (predio-frontal mundo sensor) sensor))
         (sinal (circuit-device-config-output-signal configuracao))
         (item (and (consp sinal) (eq (first sinal) :item) (second sinal))))
    (case modo
      (:inventory (inventory-count (building-inventory alvo) item))
      (:belt (soma-pistas alvo item))
      (:flow (getf (building-state alvo) :flow-rate 0))
      (:fluid (let ((rede (gethash (getf (building-state alvo) :fluid-network)
                                    (world-fluid-networks mundo))))
                (if rede (round (fluid-network-volume rede)) 0)))
      (:pressure (let ((rede (gethash (getf (building-state alvo) :fluid-network)
                                       (world-fluid-networks mundo))))
                   (if rede (round (* 100 (fluid-network-pressure rede))) 0)))
      (:power (round (* 100 (dado mundo :power-satisfaction 1.0))))
      (:pollution (round (world-pollution mundo)))
      (:machine (if (predio-operacional-p alvo) 1 0))
      (otherwise 0))))

(defun configuracao-circuito-padrao (predio)
  (or (getf (building-state predio) :circuit-config)
      (setf (getf (building-state predio) :circuit-config)
            (case (building-kind predio)
              (:circuit-sensor
               (make-circuit-device-config :behavior :sensor
                                           :output-signal '(:item :iron-plate)))
              (:arithmetic-combinator
               (make-circuit-device-config :behavior :arithmetic
                                           :input-signal '(:item :iron-plate)
                                           :operator :/ :constant 10
                                           :output-signal '(:virtual :signal-a)))
              (:decider-combinator
               (make-circuit-device-config
                :behavior :decider :output-signal '(:virtual :signal-check)
                :condition (make-circuit-condition :left '(:virtual :signal-a)
                                                   :comparator :> :constant 5)))
              (otherwise
               (make-circuit-device-config
                :behavior :actuator
                :condition (make-circuit-condition :left '(:virtual :signal-check)
                                                   :comparator :> :constant 0)))))))

(defun emitir-aritmetica (redes configuracao sinais)
  (let ((entrada (circuit-device-config-input-signal configuracao))
        (saida (circuit-device-config-output-signal configuracao))
        (operador (circuit-device-config-operator configuracao))
        (constante (circuit-device-config-constant configuracao)))
    (if (eq entrada :each)
        (let ((soma 0))
          (maphash
           (lambda (sinal valor)
             (let ((resultado (calcular-circuito valor operador constante)))
               (if (eq saida :each)
                   (escrever-em-redes redes sinal resultado :proximo t)
                   (incf soma resultado)))) sinais)
          (unless (eq saida :each)
            (escrever-em-redes redes saida soma :proximo t)))
        (escrever-em-redes redes saida
                           (calcular-circuito (valor-circuito sinais entrada)
                                             operador constante)
                           :proximo t))))

(defun sinais-que-passam (sinais condicao)
  (let ((esquerda (circuit-condition-left condicao))
        (operador (circuit-condition-comparator condicao))
        (direita (circuit-condition-right condicao))
        (constante (circuit-condition-constant condicao)) resultado)
    (labels ((passa (sinal valor)
               (declare (ignore sinal))
               (comparar-circuito valor operador
                                  (if direita (valor-circuito sinais direita) constante))))
      (cond
        ((eq esquerda :anything)
         (maphash (lambda (s v) (when (passa s v) (push (cons s v) resultado))) sinais)
         (when resultado (list (first (sort resultado #'string< :key
                                                  (lambda (p) (prin1-to-string (car p))))))))
        ((eq esquerda :everything)
         (let ((todos t) (algum nil))
           (maphash (lambda (s v) (setf algum t) (unless (passa s v) (setf todos nil))) sinais)
           (when (and algum todos)
             (maphash (lambda (s v) (push (cons s v) resultado)) sinais))
           resultado))
        ((eq esquerda :each)
         (maphash (lambda (s v) (when (passa s v) (push (cons s v) resultado))) sinais)
         resultado)
        ((passa esquerda (valor-circuito sinais esquerda))
         (list (cons esquerda (valor-circuito sinais esquerda))))))))

(defun emitir-decisao (redes configuracao sinais)
  (let* ((condicao (circuit-device-config-condition configuracao))
         (aprovados (and condicao (sinais-que-passam sinais condicao)))
         (saida (circuit-device-config-output-signal configuracao)))
    (when aprovados
      (cond
        ((eq saida :everything)
         (maphash (lambda (s v) (escrever-em-redes redes s v :proximo t)) sinais))
        ((eq saida :each)
         (dolist (par aprovados)
           (escrever-em-redes redes (car par)
                              (if (circuit-device-config-copy-count configuracao) (cdr par) 1)
                              :proximo t)))
        (t (escrever-em-redes redes saida
                              (if (circuit-device-config-copy-count configuracao)
                                  (cdar aprovados) 1) :proximo t))))))

(defun mensagem-alarme-circuito (chave)
  (let ((par (assoc chave '((:circuit-alert "ALARME DE CIRCUITO" "CIRCUIT ALERT")
                            (:low-stock "ESTOQUE BAIXO" "LOW STOCK")
                            (:tank-full "TANQUE CHEIO" "TANK FULL")
                            (:power-low "ENERGIA BAIXA" "LOW POWER")))))
    (if (eq (current-language) :pt) (second par) (third par))))

(defun aplicar-atuador-circuito (mundo predio configuracao sinais)
  (let* ((condicao (circuit-device-config-condition configuracao))
         (ativo (or (null condicao) (not (null (sinais-que-passam sinais condicao)))))
         (estado (building-state predio)))
    (setf (getf estado :circuit-enabled) ativo
          (getf estado :circuit-filter) (circuit-device-config-input-signal configuracao)
          (getf estado :circuit-reverse)
          (eq (circuit-device-config-pump-direction configuracao) :reverse)
          (getf estado :circuit-priority) (circuit-device-config-output-priority configuracao))
    (setf (getf estado (if ativo :circuit-true-tick :circuit-false-tick)) (world-tick mundo))
    (case (building-kind predio)
      (:signal-lamp (setf (getf estado :lamp-active) ativo
                          (getf estado :lamp-color) (circuit-device-config-lamp-color configuracao)
                          (getf estado :lamp-intensity) (circuit-device-config-lamp-intensity configuracao)
                          (getf estado :lamp-signal)
                          (circuit-device-config-input-signal configuracao)))
      (:programmable-alarm
       (when (and ativo (not (getf estado :alarm-active))
                  (> (world-tick mundo) (getf estado :alarm-cooldown -1)))
         (notificar mundo (mensagem-alarme-circuito
                           (circuit-device-config-alarm-message configuracao))
                    :duracao 90 :cor '(255 188 72 255))
         (case (circuit-device-config-alarm-sound configuracao)
           (:warning (play-sound :alarm-warning))
           (:critical (play-sound :alarm-critical)))
         (setf (getf estado :alarm-cooldown) (+ (world-tick mundo) 90)))
       (setf (getf estado :alarm-active) ativo)))
    (setf (building-state predio) estado)
    ativo))

(defun sistema-circuitos (mundo)
  "Avalia sensores, memória, combinadores e atuadores com latência determinística."
  (rebuild-circuit-networks mundo)
  (maphash
   (lambda (id rede) (declare (ignore id))
     (clrhash (circuit-network-signals rede))
     (clrhash (circuit-network-next-signals rede)))
   (world-circuit-networks mundo))
  (let (predios)
    (map-buildings (lambda (b) (push b predios)) mundo)
    (setf predios (sort predios #'< :key #'building-id))
    ;; A memória pertence ao emissor, não à topologia: reconectar não a perde.
    (dolist (b predios)
      (let ((memoria (getf (building-state b) :circuit-output)))
        (when memoria
          (let ((redes (redes-circuito-predio mundo b t)))
            (maphash (lambda (sinal valor) (escrever-em-redes redes sinal valor)) memoria)))))
    ;; Sensores são fontes instantâneas do snapshot deste tick.
    (dolist (b predios)
      (when (eq (building-kind b) :circuit-sensor)
        (let* ((config (configuracao-circuito-padrao b))
               (redes (redes-circuito-predio mundo b)))
          (escrever-em-redes redes (circuit-device-config-output-signal config)
                             (valor-sensor-circuito mundo b config)))))
    ;; Combinadores escrevem exclusivamente no buffer do próximo tick.
    (let* ((tarefas
             (loop for b in predios
                   when (member (building-kind b) '(:arithmetic-combinator :decider-combinator))
                     collect (list b (configuracao-circuito-padrao b)
                                   (sinais-redes-circuito (redes-circuito-predio mundo b)))))
           (resultados
             (run-deterministic-jobs
              tarefas
              (lambda (tarefa indice)
                (declare (ignore indice))
                (destructuring-bind (b config sinais) tarefa
                  (let ((memoria (make-circuit-network)))
                    (if (eq (building-kind b) :arithmetic-combinator)
                        (emitir-aritmetica (list memoria) config sinais)
                        (emitir-decisao (list memoria) config sinais))
                    (list b (circuit-network-next-signals memoria)))))
              :workers (world-worker-count mundo))))
      ;; Workers só produzem buffers privados. O commit segue IDs de construção.
      (dolist (resultado resultados)
        (destructuring-bind (b memoria) resultado
          (setf (getf (building-state b) :circuit-output) memoria)
          (let ((redes (redes-circuito-predio mundo b t)))
            (maphash (lambda (s v) (escrever-em-redes redes s v :proximo t)) memoria)))))
    ;; Atuadores observam um snapshot completo, independente da ordem de construção.
    (dolist (b predios)
      (when (member (building-definition-circuit-behavior (find-building (building-kind b)))
                    '(:actuator :lamp :alarm))
        (let ((redes (redes-circuito-predio mundo b)))
          (if redes
              (aplicar-atuador-circuito mundo b (configuracao-circuito-padrao b)
                                        (sinais-redes-circuito redes))
              (setf (getf (building-state b) :circuit-enabled) t
                    (getf (building-state b) :circuit-filter) nil
                    (getf (building-state b) :circuit-reverse) nil
                    (getf (building-state b) :circuit-priority) :balanced
                    (getf (building-state b) :lamp-active) nil
                    (getf (building-state b) :alarm-active) nil)))))))

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
             (setf (getf (building-state b) :last-work-tick) (world-tick mundo))
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
  (cond
    ((member (building-kind predio) '(:splitter :filter-splitter))
      (let* ((saidas (saidas-divisor predio))
             (item (let* ((pista (aref (pistas-predio predio) indice-pista))
                          (i (1- (belt-lane-count pista))))
                     (and (>= i 0) (aref (belt-lane-items pista) i))))
             (sinal-filtro (getf (building-state predio) :circuit-filter))
             (filtro (or (and (consp sinal-filtro) (eq (first sinal-filtro) :item)
                              (second sinal-filtro)) (getf (building-state predio) :filter)))
             (prioridade (getf (building-state predio) :circuit-priority :balanced))
             (principal (if (eq prioridade :second) 1 0))
             (preferida (cond (filtro (if (eq item filtro) principal (- 1 principal)))
                              ((not (eq prioridade :balanced)) principal)
                              (t (mod (+ (getf (building-state predio) :next-output 0)
                                         indice-pista) 2))))
             (posicao (nth preferida saidas)))
        (values (building-at mundo (car posicao) (cdr posicao)) preferida)))
    ((eq (building-kind predio) :underground-belt)
     (let* ((d (direcao (building-rotation predio)))
            (par (loop for distancia from 1 to 5
                       for candidato = (building-at
                                        mundo
                                        (+ (building-x predio) (* distancia (car d)))
                                        (+ (building-y predio) (* distancia (cdr d))))
                       when (and candidato (eq (building-kind candidato)
                                               :underground-belt)
                                 (= (building-rotation candidato)
                                    (building-rotation predio)))
                         return candidato)))
       (values (or par (building-at mundo (+ (building-x predio) (car d))
                                    (+ (building-y predio) (cdr d))))
               indice-pista)))
    (t
     (let ((d (direcao (building-rotation predio))))
       (values (building-at mundo (+ (building-x predio) (car d))
                            (+ (building-y predio) (cdr d))) indice-pista)))))

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
          (let ((aceito (inserir-em-destino destino item :pista indice-pista :pilha pilha)))
            ;; Prioridade prefere uma saída, mas não bloqueia a outra. Filtros
            ;; são exclusivos: nunca desviam um item para a saída incompatível.
            (when (and (not aceito)
                       (member (building-kind predio) '(:splitter :filter-splitter))
                       (not (getf (building-state predio) :filter))
                       (not (let ((s (getf (building-state predio) :circuit-filter)))
                              (and (consp s) (eq (first s) :item)))))
              (let* ((outra (- 1 saida)) (pos (nth outra (saidas-divisor predio))))
                (when (inserir-em-destino (building-at mundo (car pos) (cdr pos)) item
                                          :pista indice-pista :pilha pilha)
                  (setf aceito t saida outra))))
          (when aceito
            (belt-lane-remove-front pista)
            (registrar-vazao predio pilha)
            (setf (getf (building-state predio) :last-work-tick) (world-tick mundo))
            (incf (dado mundo :items-moved 0) pilha)
            (when (member (building-kind predio) '(:splitter :filter-splitter))
              (setf (getf (building-state predio) :next-output)
                    (mod (1+ saida) 2))
              (when (getf (building-state predio) :circuit-filter)
                (setf (getf (building-state predio)
                            (if (zerop saida) :filtered-output-0 :filtered-output-1))
                      (world-tick mundo))))
            t)))))))

(defun sistema-logistica (mundo)
  (let (predios)
    (map-buildings (lambda (b) (push b predios)) mundo)
    ;; Processar jusante antes de montante impede pulsos visuais e preserva
    ;; a mesma ordem em qualquer implementação de hash-table.
    (dolist (b (sort predios #'> :key #'building-id))
      (case (building-kind b)
        ((:belt :fast-belt :splitter :underground-belt :filter-splitter :loader)
         (when (predio-operacional-p b)
           (alimentar-pistas-do-buffer b)
           (dotimes (pista 2)
             (advance-belt-lane
              (aref (pistas-predio b) pista)
              (case (building-kind b)
                ((:fast-belt :underground-belt) 16384) (:loader 32768)
                (otherwise 8192))))
           (dotimes (pista 2) (transferir-frente-pista mundo b pista))))
        ((:inserter :long-inserter :stack-inserter)
         (when (predio-operacional-p b)
           (let* ((d (direcao (building-rotation b)))
                  (dist (if (eq (building-kind b) :long-inserter) 2 1))
                  (origem (building-at mundo (- (building-x b) (* (car d) dist))
                                       (- (building-y b) (* (cdr d) dist))))
                  (alvo (building-at mundo (+ (building-x b) (* (car d) dist))
                                     (+ (building-y b) (* (cdr d) dist)))))
             (when (and origem alvo (zerop (mod (world-tick mundo) 8)))
               (dotimes (transferencia (if (eq (building-kind b) :stack-inserter) 4 1))
                 (declare (ignore transferencia))
               (let* ((pista (and (transportador-p origem)
                                  (aref (pistas-predio origem) (mod (building-id b) 2))))
                      (indice (and pista (1- (belt-lane-count pista))))
                      (sinal (getf (building-state b) :circuit-filter))
                      (filtro (and (consp sinal) (eq (first sinal) :item) (second sinal)))
                      (item (if pista
                                (and (>= indice 0) (aref (belt-lane-items pista) indice))
                                (if filtro
                                    (and (plusp (inventory-count (building-inventory origem) filtro)) filtro)
                                    (item-inventario-deterministico (building-inventory origem))))))
                 (when (and item (or (null filtro) (eq item filtro)))
                   (when (inserir-em-destino alvo item :pista (mod (building-id b) 2))
                       (progn
                         ;; Só retirar após aceitar; pilhas nunca viram um único item.
                         (if pista
                             (if (> (aref (belt-lane-stacks pista) indice) 1)
                                 (decf (aref (belt-lane-stacks pista) indice))
                                 (belt-lane-remove-front pista :threshold 0))
                             (inventory-remove (building-inventory origem) item 1))
                         (incf (dado mundo :items-moved 0))
                         (setf (getf (building-state b) :carried-item) item
                               (getf (building-state b) :carry-start)
                               (world-tick mundo)))))))))))
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
           (setf (getf (building-state b) :last-work-tick) (world-tick mundo))
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
    (spawn-entity mundo tipo (coordenada-fauna (* raio (cos angulo)))
                  (coordenada-fauna (* raio (sin angulo)))
                  :hp (+ 40 (* 30 (position tipo tipos))))))
(defun sistema-fauna (mundo)
  (let ((multiplicador (case (world-difficulty mundo) (:peaceful 0) (:explorer 0.4)
                             (:hostile 2.0) (t 1.0))))
    (when (and (> multiplicador 0) (> (dado mundo :chapter 1) 6)
               (> (world-pollution mundo) 30)
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
           (setf (entity-x e) (coordenada-fauna (entity-x e))
                 (entity-y e) (coordenada-fauna (entity-y e)))
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
             (setf (entity-x e) (coordenada-fauna (entity-x e))
                   (entity-y e) (coordenada-fauna (entity-y e)))
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
  #("EXTRACTION" "POWER AND PRODUCTION" "INVENTORY CONTROL" "FILTERED SORTING"
    "TANK REGULATION" "COUNTER AND ALARM"
    "SIGNALS AND DRONES" "WAR INDUSTRY" "HIVE ASSAULT"))
(defparameter *capitulos-pt*
  #("EXTRACAO" "ENERGIA E PRODUCAO" "CONTROLE DE ESTOQUE" "DIVISAO FILTRADA"
    "REGULACAO DO TANQUE" "CONTADOR E ALARME"
    "SINAIS E DRONES" "INDUSTRIA BELICA" "ATAQUE A COLMEIA"))

(defun nome-capitulo (indice)
  (aref (if (eq (current-language) :pt) *capitulos-pt* *capitulos*) indice))

(defun notificar (mundo texto &key (duracao 150) (cor '(112 245 220 255)))
  "Enfileira feedback sem substituir outras mensagens importantes."
  (let ((entrada (list :text texto :until (+ (world-tick mundo) duracao) :color cor)))
    (setf (dado mundo :notifications)
          (subseq (cons entrada (dado mundo :notifications nil))
                  0 (min 4 (1+ (length (dado mundo :notifications nil))))))
    entrada))

(defparameter *recompensas-capitulos*
  '(((:iron-plate . 35) (:copper-plate . 25) (:solar-cell . 8) (:steel-plate . 12))
    ((:gear . 24) (:belt-part . 30) (:circuit . 30) (:wire-red . 20) (:wire-green . 20))
    ((:science-red . 25) (:circuit . 20) (:belt-part . 40))
    ((:pipe . 30) (:steel-plate . 20) (:engine . 4))
    ((:circuit . 24) (:wire-red . 12) (:wire-green . 12))
    ((:rail-part . 100) (:signal-part . 12) (:processor . 12) (:logistic-drone . 4))
    ((:rocket . 20) (:repair-pack . 20))
    ((:hive-charge . 2) (:plasma-cell . 20))))

(defun texto-itens (itens)
  (format nil "~{~A x~D~^  +  ~}"
          (loop for (item . qtd) in itens
                append (list (string-upcase (string item)) qtd))))

(defun conceder-recompensa-capitulo (mundo capitulo)
  (let ((itens (nth (1- capitulo) *recompensas-capitulos*)))
    (when itens
      (dolist (par itens) (inventory-add (inventario-jogador mundo) (car par) (cdr par)))
      (notificar mundo (format nil "~A: ~A" (translate :reward) (texto-itens itens))
                 :duracao 270 :cor '(244 190 79 255)))))

(defun objetivo-capitulo (mundo)
  "Retorna descrição, progresso, alvo e recompensa do capítulo corrente."
  (let ((c (dado mundo :chapter 1)))
    (when (<= c 6)
      (return-from objetivo-capitulo
        (values (nth (1- c)
                     (if (eq (current-language) :pt)
                         '("MINERE E TRANSPORTE" "GERE ENERGIA E PRODUZA" "CONTROLE UM BRACO POR ESTOQUE"
                           "SEPARE DOIS ITENS COM FILTRO" "REGULE UM TANQUE POR NIVEL" "CONTADOR + LAMPADA + ALARME")
                         '("MINE AND TRANSPORT" "GENERATE POWER AND PRODUCE" "CONTROL AN ARM BY STOCK"
                           "FILTER TWO DIFFERENT ITEMS" "REGULATE A TANK BY LEVEL" "COUNTER + LAMP + ALARM")))
                (min 180 (dado mundo :chapter-progress 0)) 180
                (nth (1- c) *recompensas-capitulos*))))
    (multiple-value-bind (texto atual alvo)
        (case c
          (1 (values (if (eq (current-language) :pt) "CONSTRUA 2 MINERADORES" "BUILD 2 MINERS")
                     (quantidade-tipo mundo :miner) 2))
          (2 (values (if (eq (current-language) :pt) "OPERE 2 FORNALHAS" "OPERATE 2 FURNACES")
                     (quantidade-tipo mundo :stone-furnace) 2))
          (3 (values (if (eq (current-language) :pt) "MONTE UMA MONTADORA" "BUILD AN ASSEMBLER")
                     (quantidade-tipo mundo :assembler) 1))
          (4 (values (if (eq (current-language) :pt) "CONECTE 6 PECAS DE FLUIDO" "CONNECT 6 FLUID PARTS")
                     (+ (quantidade-tipo mundo :pipe) (quantidade-tipo mundo :pump)) 6))
          (5 (values (if (eq (current-language) :pt) "ATIVE UM LABORATORIO" "ACTIVATE A LABORATORY")
                     (quantidade-tipo mundo :laboratory) 1))
          (6 (values (if (eq (current-language) :pt) "ASSENTE 20 TRILHOS" "LAY 20 RAIL SEGMENTS")
                     (quantidade-tipo mundo :rail) 20))
          (7 (values (if (eq (current-language) :pt) "LIGUE SINAIS E ROBOPORT" "CONNECT SIGNALS AND A ROBOPORT")
                     (+ (quantidade-tipo mundo :rail-signal) (quantidade-tipo mundo :roboport)) 2))
          (8 (values (if (eq (current-language) :pt) "FORTIFIQUE COM 2 TORRES" "DEPLOY 2 ADVANCED TURRETS")
                     (+ (quantidade-tipo mundo :rocket-turret)
                        (quantidade-tipo mundo :plasma-turret)) 2))
          (otherwise
           (values (if (eq (current-language) :pt) "LOCALIZE E DESTRUA A COLMEIA"
                       "LOCATE AND DESTROY THE CENTRAL HIVE")
                   (if (dado mundo :sandbox) 1 0) 1)))
      (values texto (min atual alvo) alvo
              (and (< c 9) (nth (1- c) *recompensas-capitulos*))))))
(defun quantidade-tipo (mundo tipo)
  (let ((n 0)) (map-buildings (lambda (b) (when (eq (building-kind b) tipo) (incf n))) mundo) n))
(defun avancar-capitulo (mundo)
  (let ((c (dado mundo :chapter 1)))
    (when (and (< c 9)
      (case c ((1 2 3 4 5 6) (>= (dado mundo :chapter-progress 0) 180))
              (7 (>= (+ (quantidade-tipo mundo :rail-signal) (quantidade-tipo mundo :roboport)) 2))
              (8 (>= (+ (quantidade-tipo mundo :rocket-turret) (quantidade-tipo mundo :plasma-turret)) 2))))
      (conceder-recompensa-capitulo mundo c)
      (incf (dado mundo :chapter))
      (setf (dado mundo :chapter-progress) 0 (dado mundo :tutorial-valid-since) nil
            (dado mundo :chapter-start-tick) (world-tick mundo))
      (dolist (id (case c
                    (1 '(:assembler :solar-panel :steam-generator))
                    (2 '(:circuit-sensor :arithmetic-combinator :decider-combinator
                         :signal-lamp :programmable-alarm :logistic-chest :laboratory))
                    (3 '(:splitter :filter-splitter))
                    (4 '(:pipe :pump :directional-pump :tank))))
        (pushnew id (dado mundo :unlocked)))
      (setf (dado mundo :message)
            (format nil "~A: ~A" (if (eq (current-language) :pt) "NOVO CAPITULO" "NEW CHAPTER")
                    (nome-capitulo c))
            (dado mundo :message-until) (+ (world-tick mundo) 240)))
    (when (and (= (dado mundo :chapter 1) 9) (not (dado mundo :hive-spawned)))
      (spawn-entity mundo :hive 42 37 :hp 5000 :data '(:objective t))
      (setf (dado mundo :hive-spawned) t (dado mundo :message) "HIVE LOCATED AT 42,37"
            (dado mundo :message-until) (+ (world-tick mundo) 600)))
    (when (and (dado mundo :hive-spawned) (not (dado mundo :sandbox)))
      (let ((viva nil)) (map-entities (lambda (e) (when (eq (entity-kind e) :hive) (setf viva t))) mundo)
        (unless viva (setf (dado mundo :sandbox) t (dado mundo :message) (translate :victory)
                           (dado mundo :message-until) most-positive-fixnum))))))

(defun sensor-controla-p (mundo predio modo)
  "Exige sensor físico lendo o mesmo sinal que a condição do atuador."
  (let* ((config (configuracao-circuito-padrao predio))
         (condicao (circuit-device-config-condition config))
         (redes (redes-circuito-predio mundo predio)) encontrado)
    (when condicao
      (dolist (rede redes)
        (dolist (porta (circuit-network-nodes rede))
          (let ((sensor (predio-por-id mundo (first porta))))
            (when (and sensor (eq (building-kind sensor) :circuit-sensor)
                       (eq (getf (building-state sensor) :sensor-mode :inventory) modo)
                       (predio-frontal mundo sensor)
                       (equal (circuit-condition-left condicao)
                              (circuit-device-config-output-signal
                               (configuracao-circuito-padrao sensor))))
              (setf encontrado sensor))))))
    encontrado))

(defun evidencia-recente-p (mundo predio chave &optional (janela 120))
  (let ((tick (getf (building-state predio) chave)))
    (and tick (<= 0 (- (world-tick mundo) tick) janela))))

(defun evidencia-no-capitulo-p (mundo predio chave)
  (let ((tick (getf (building-state predio) chave)))
    (and tick (>= tick (dado mundo :chapter-start-tick 0)))))

(defun tutorial-funcionando-p (mundo)
  "Retorna a construção que comprova o desafio; contagens de prédios não bastam."
  (let ((c (dado mundo :chapter 1)) predios)
    (map-buildings (lambda (b) (push b predios)) mundo)
    (setf predios (sort predios #'< :key #'building-id))
    (find-if
     (lambda (b)
       (case c
         (1 (let ((destino (predio-frontal mundo b)))
              (and (eq (building-kind b) :miner) (evidencia-recente-p mundo b :last-work-tick)
                   destino (transportador-p destino)
                   (evidencia-recente-p mundo destino :last-work-tick))))
         (2 (and (member (building-kind b) '(:assembler :stone-furnace :electric-furnace))
                 (predio-operacional-p b) (evidencia-recente-p mundo b :last-work-tick 180)
                 (some (lambda (g) (and (member (building-kind g) '(:solar-panel :steam-generator))
                                        (building-enabled g))) predios)))
         (3 (and (member (building-kind b) '(:inserter :long-inserter :stack-inserter))
                 (sensor-controla-p mundo b :inventory)
                 (evidencia-no-capitulo-p mundo b :carry-start)
                 (evidencia-no-capitulo-p mundo b :circuit-true-tick)
                 (evidencia-no-capitulo-p mundo b :circuit-false-tick)))
         (4 (let ((filtro (getf (building-state b) :circuit-filter)))
              (and (member (building-kind b) '(:splitter :filter-splitter))
                   (circuit-connections mundo b) (consp filtro) (eq (first filtro) :item)
                   (evidencia-no-capitulo-p mundo b :filtered-output-0)
                   (evidencia-no-capitulo-p mundo b :filtered-output-1))))
         (5 (let ((sensor (and (member (building-kind b) '(:pump :directional-pump))
                               (sensor-controla-p mundo b :fluid))))
              (and sensor (eq (building-kind (predio-frontal mundo sensor)) :tank)
                   (evidencia-no-capitulo-p mundo b :last-fluid-transfer)
                   (evidencia-no-capitulo-p mundo b :circuit-true-tick)
                   (evidencia-no-capitulo-p mundo b :circuit-false-tick))))
         (6 (when (eq (building-kind b) :arithmetic-combinator)
              (let* ((config (configuracao-circuito-padrao b))
                     (saida (circuit-device-config-output-signal config))
                     (redes (redes-circuito-predio mundo b t)) (lampada nil) (alarme nil))
                (when (and (eq (circuit-device-config-operator config) :+)
                           (plusp (circuit-device-config-constant config))
                           (equal saida (circuit-device-config-input-signal config))
                           (intersection redes (redes-circuito-predio mundo b)))
                  (dolist (rede redes)
                    (dolist (porta (circuit-network-nodes rede))
                      (let* ((alvo (predio-por-id mundo (first porta)))
                             (condicao (and alvo (circuit-device-config-condition
                                                 (configuracao-circuito-padrao alvo)))))
                        (when (and condicao (equal (circuit-condition-left condicao) saida)
                                   (getf (building-state alvo) :circuit-enabled))
                          (case (building-kind alvo)
                            (:signal-lamp (setf lampada t))
                            (:programmable-alarm (setf alarme t)))))))
                  (and lampada alarme))))))) predios)))

(defun avaliar-tutorial-circuitos (mundo)
  (when (<= (dado mundo :chapter 1) 6)
    (let* ((predio (tutorial-funcionando-p mundo))
           (id (and predio (building-id predio))))
      (unless (and id (eql id (dado mundo :tutorial-device)))
        (setf (dado mundo :tutorial-valid-since) nil (dado mundo :chapter-progress) 0))
      (setf (dado mundo :tutorial-device) id)
      (when predio
        (unless (dado mundo :tutorial-valid-since)
          (setf (dado mundo :tutorial-valid-since) (world-tick mundo)))
        (setf (dado mundo :chapter-progress)
              (- (world-tick mundo) (dado mundo :tutorial-valid-since)))))))

(defun sistema-campanha (mundo)
  (when (zerop (mod (world-tick mundo) 30))
    (avaliar-tutorial-circuitos mundo) (avancar-capitulo mundo))
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
  "Aceita qualquer pacote científico declarado pela tecnologia."
  (or (cdr (first (technology-definition-cost tecnologia))) 1))

(defun item-ciencia-tecnologia (tecnologia)
  (or (car (first (technology-definition-cost tecnologia))) :science-red))

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
                 (inventory-remove inv (item-ciencia-tecnologia tecnologia) 1))
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
    (:chain-signal . 9) (:curved-rail . 10)
    (:diagonal-crossing . 11) (:construction-roboport . 12)
    (:logistics-roboport . 13) (:scrubber . 14) (:supply-depot . 15)))

(defparameter *sprites-construcoes-v3*
  '((:circuit-sensor . 0) (:arithmetic-combinator . 1)
    (:decider-combinator . 2) (:signal-lamp . 3) (:programmable-alarm . 6)))

(defun sprite-construcao (kind)
  (or (cdr (assoc kind *sprites-construcoes-v3*))
      (cdr (assoc kind *sprites-construcoes*))
      (cdr (assoc kind *sprites-construcoes-v2*)) 3))

(defun folha-construcao (kind)
  (cond ((assoc kind *sprites-construcoes-v3*) :circuits-v3)
        ((assoc kind *sprites-construcoes-v2*) :buildings-v2)
        (t :buildings)))

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

(defun tinta-terreno (mundo x y)
  "Contém a saturação do piso para recursos e estados continuarem dominantes."
  (case (bioma-em mundo x y)
    (:crystal-grove '(154 174 174)) (:luminous-marsh '(135 169 166))
    (:basalt-wastes '(151 158 166)) (:ashlands '(174 151 139))))

(defun prop-ambiental (mundo x y)
  "Retorna índice e tamanho; ruínas são marcos raros, vegetação forma silhuetas."
  (when (> (+ (abs x) (abs y)) 5)
    (let ((densidade (resource-noise mundo x y 1031))
          (variante (resource-noise mundo x y 1063))
          (ruina (resource-noise mundo x y 1091)))
      (cond
        ((and (> (+ (abs x) (abs y)) 14) (> ruina .986))
         (values (+ 8 (min 5 (floor (* variante 6)))) 62))
        ((and (> (world-pollution mundo) 180) (> densidade .968))
         (values 15 54))
        ((and (< (world-pollution mundo) 80) (> densidade .984))
         (values 14 54))
        ((> densidade .952)
         (values
          (case (bioma-em mundo x y)
            (:crystal-grove (if (> variante .55) 5 3))
            (:luminous-marsh (if (> variante .5) 6 0))
            (:basalt-wastes (if (> variante .62) 2 4))
            (:ashlands (if (> variante .72) 7 2)))
          (if (> variante .55) 58 46)))))))

(defun visivel-no-mundo-p (x y &optional (margem 96))
  (multiple-value-bind (sx sy) (world-to-screen x y)
    (and (> sx (- margem)) (< sx (+ (screen-width) margem))
         (> sy (- margem)) (< sy (+ (screen-height) margem)))))

(defun desenhar-item (item x y &optional (tamanho 15))
  (let ((indice (sprite-item item)))
    (when indice (draw-sprite (folha-item item) indice x y tamanho tamanho :world t))))

(defun desenhar-icone-item (item x y tamanho)
  (let ((indice (sprite-item item)))
    (when indice (draw-sprite (folha-item item) indice x y tamanho tamanho))))

(defun desenhar-item-em-transito (b mundo x y)
  "Projeta itens reais dos inventários nas portas e transportadores."
  (let* ((kind (building-kind b)) (tick (world-tick mundo))
         (d (direcao (building-rotation b))))
    (cond
      ((member kind '(:belt :fast-belt :splitter :underground-belt
                      :filter-splitter :loader))
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
      ((member kind '(:inserter :long-inserter :stack-inserter))
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
         (draw-sprite (folha-construcao kind)
                      (cond ((and world (eq kind :programmable-alarm)
                                  (getf (building-state b) :alarm-active)) 7)
                            (t (sprite-construcao kind))) (- x 7) (- y 10)
                      46 46 :world world
                      :angle (if (assoc kind *sprites-construcoes-v3*) 0 angulo)
                      :opacity opacity :tint tint)))
      (when (and world (eq kind :signal-lamp) (getf (building-state b) :lamp-active))
        (let* ((cor (getf (building-state b) :lamp-color :amber))
               (brilho (getf (building-state b) :lamp-intensity 100))
               (acessivel (and game-world (dado game-world :colorblind-circuits)))
               (cor (if acessivel (if (member cor '(:amber :red)) :amber :blue) cor)))
          (draw-sprite :circuits-v3 (if (member cor '(:blue :green)) 5 4)
                       (- x 7) (- y 10) 46 46 :world t
                       :opacity (round (* opacity brilho) 100)
                       :tint (case cor (:red '(255 100 85)) (:green '(95 255 130))
                                   (otherwise '(255 255 255))))))
      (when (and world game-world)
        (desenhar-item-em-transito b game-world x y))
      (when (and world (eq kind :circuit-sensor))
        (desenhar-seta-fluxo-em (building-x b) (building-y b) (building-rotation b)
                                '(110 227 242 255)))
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
  (if (member (building-kind predio) '(:splitter :filter-splitter))
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
      (when (or (transportador-p foco)
                (member (building-kind foco) '(:inserter :long-inserter :stack-inserter)))
        (map-buildings
         (lambda (b)
           (when (and (or (transportador-p b)
                          (member (building-kind b)
                                  '(:inserter :long-inserter :stack-inserter)))
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
        (when (or (transportador-p b)
                  (member (building-kind b) '(:inserter :long-inserter :stack-inserter)))
          (draw-text (format nil "~A: ~A~A" (translate :flow)
                             (nome-direcao (building-rotation b))
                             (if (member (building-kind b) '(:splitter :filter-splitter))
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

(defvar *mundo-corrente-ui* nil)

(defun cor-circuito (cor)
  (if (and *mundo-corrente-ui* (dado *mundo-corrente-ui* :colorblind-circuits nil))
      (if (eq cor :red) '(255 184 58 255) '(80 176 255 255))
      (if (eq cor :red) '(255 72 88 255) '(73 230 137 255))))

(defun desenhar-fio-tracejado (x1 y1 x2 y2 cor)
  (let ((segmentos 18))
    (dotimes (i segmentos)
      (when (evenp i)
        (let ((a (/ i (float segmentos))) (b (/ (1+ i) (float segmentos))))
          (draw-line (+ x1 (* (- x2 x1) a)) (+ y1 (* (- y2 y1) a))
                     (+ x1 (* (- x2 x1) b)) (+ y1 (* (- y2 y1) b))
                     cor :world t))))))

(defun desenhar-redes-circuito (mundo)
  "Desenha o grafo físico e a prévia, com estilos distintos além das cores."
  (dolist (fio (circuit-connections mundo))
    (let ((a (predio-por-id mundo (circuit-wire-a-building fio)))
          (b (predio-por-id mundo (circuit-wire-b-building fio))))
      (when (and a b)
        (let ((x1 (posicao-porta-x a (circuit-wire-a-port fio)))
              (y1 (posicao-porta-y a))
              (x2 (posicao-porta-x b (circuit-wire-b-port fio)))
              (y2 (posicao-porta-y b))
              (cor (cor-circuito (circuit-wire-color fio))))
          (if (eq (circuit-wire-color fio) :green)
              (desenhar-fio-tracejado x1 y1 x2 y2 cor)
              (draw-line x1 y1 x2 y2 cor :world t))))))
  (when *origem-fio-circuito*
    (multiple-value-bind (mx my) (posicao-cursor-ui)
      (multiple-value-bind (wx wy) (screen-to-world mx my)
        (let* ((x (posicao-porta-x *origem-fio-circuito* *porta-origem-circuito*))
               (y (posicao-porta-y *origem-fio-circuito*))
               (valida (<= (+ (expt (- wx x) 2) (expt (- wy y) 2))
                            (expt (* 9 +tamanho-celula+) 2))))
          (draw-circle x y (* 9 +tamanho-celula+) '(83 110 128 75) :world t)
          (desenhar-fio-tracejado x y wx wy
                                  (if valida (cor-circuito *cor-fio-circuito*)
                                      '(130 130 130 255)))))))
  (map-buildings
   (lambda (b)
     (when (visivel-no-mundo-p (* (building-x b) 32) (* (building-y b) 32))
       (dolist (porta (portas-circuito-predio (building-kind b)))
         (let* ((x (posicao-porta-x b porta)) (y (posicao-porta-y b))
                (acessivel (dado mundo :colorblind-circuits nil))
                (indice (+ (if acessivel 10 8) (if (eq *cor-fio-circuito* :green) 1 0))))
           (draw-sprite :circuits-v3 indice (- x 6) (- y 6) 12 12 :world t)
           (when (eq b *origem-fio-circuito*)
             (draw-circle x y 8 (cor-circuito *cor-fio-circuito*) :world t)))))) mundo))

(defun posicao-porta-x (predio porta)
  (* (+ (building-x predio) (case porta (:input .18) (:output .82) (t .5)))
     +tamanho-celula+))

(defun posicao-porta-y (predio)
  (* (+ (building-y predio) .5) +tamanho-celula+))

(defun rotulo-sinal-circuito (sinal)
  (cond ((member sinal '(:each :anything :everything)) (string-upcase (string sinal)))
        ((and (consp sinal) (second sinal))
         (format nil "~A/~A" (string-upcase (string (first sinal)))
                 (string-upcase (string (second sinal)))))
        (t (princ-to-string sinal))))

(defun sinais-visiveis-predio (mundo predio)
  (let ((sinais (sinais-redes-circuito (redes-circuito-predio mundo predio))) pares)
    (maphash (lambda (s v) (push (cons s v) pares)) sinais)
    (subseq (sort pares (lambda (a b)
                          (or (> (abs (cdr a)) (abs (cdr b)))
                              (and (= (abs (cdr a)) (abs (cdr b)))
                                   (string< (prin1-to-string (car a))
                                            (prin1-to-string (car b)))))))
            0 (min 5 (hash-table-count sinais)))))

(defun sinais-disponiveis-circuito ()
  "Inclui também os itens registrados por mods, em ordem estável."
  (let (sinais)
    (map-items (lambda (item)
                 (push (list (if (eq (item-definition-material-kind item) :fluid) :fluid :item)
                             (item-definition-id item)) sinais)))
    (coerce (remove-duplicates
             (append (coerce *sinais-circuito-ui* 'list)
                     (sort sinais #'string< :key #'prin1-to-string)) :test #'equal)
            'vector)))

(defun campos-avancados-circuito (predio)
  "Descritores compartilhados pelo desenho e por mouse/gamepad."
  (append
   (case (building-kind predio)
     ((:pump :directional-pump)
      '((circuit-device-config-pump-direction "DIRECAO" "DIRECTION" #(:forward :reverse))))
     ((:splitter :filter-splitter)
      '((circuit-device-config-output-priority "PRIORIDADE" "PRIORITY" #(:balanced :first :second))))
     (:signal-lamp
      '((circuit-device-config-lamp-color "COR" "COLOR" #(:amber :blue :red :green))
        (circuit-device-config-lamp-intensity "BRILHO %" "BRIGHTNESS %" #(0 25 50 75 100))))
     (:programmable-alarm
      '((circuit-device-config-alarm-sound "SOM" "SOUND" #(:silent :warning :critical))
        (circuit-device-config-alarm-message "MENSAGEM" "MESSAGE"
         #(:circuit-alert :low-stock :tank-full :power-low))))
     (:decider-combinator
      '((circuit-device-config-copy-count "COPIAR VALOR" "COPY COUNT" #(nil t)))))
   (when (circuit-device-config-condition (configuracao-circuito-padrao predio))
     (list (list :right "COMPARAR COM" "COMPARE WITH"
                 (concatenate 'vector #(nil) (sinais-disponiveis-circuito)))))))

(defun valor-campo-avancado (config campo)
  (if (eq (first campo) :right)
      (circuit-condition-right (circuit-device-config-condition config))
      (funcall (first campo) config)))

(defun rotulo-valor-controle (valor)
  (let ((par (assoc valor '((:forward "NORMAL" "FORWARD") (:reverse "INVERSA" "REVERSE")
                            (:balanced "EQUILIBRADA" "BALANCED") (:first "SAIDA 1" "OUTPUT 1")
                            (:second "SAIDA 2" "OUTPUT 2") (:amber "AMBAR" "AMBER")
                            (:blue "AZUL" "BLUE") (:red "VERMELHO" "RED") (:green "VERDE" "GREEN")
                            (:silent "SILENCIOSO" "SILENT") (:warning "AVISO" "WARNING")
                            (:critical "CRITICO" "CRITICAL") (t "SIM" "YES")))))
    (cond (par (if (eq (current-language) :pt) (second par) (third par)))
          ((null valor) (if (eq (current-language) :pt) "NAO / CONSTANTE" "NO / CONSTANT"))
          ((consp valor) (rotulo-sinal-circuito valor))
          ((member valor '(:circuit-alert :low-stock :tank-full :power-low))
           (mensagem-alarme-circuito valor))
          (t valor))))

(defun desenhar-painel-circuito (mundo)
  (let* ((x (- (screen-width) 350)) (y 88) (w 338)
         (predio *predio-circuito-selecionado*))
    (draw-rect x y w (- (screen-height) y 18) '(4 10 17 248))
    (draw-rect x y w (- (screen-height) y 18) '(65 105 121 255) :outline t)
    (draw-text (translate :circuit-mode) (+ x 14) (+ y 14)
               (cor-circuito *cor-fio-circuito*) :scale 2)
    (draw-text (format nil "~A  |  ~A: 1" (string-upcase (string *cor-fio-circuito*))
                       (translate :wire-cost))
               (+ x 14) (+ y 45) '(205 220 228 255) :scale 1)
    (draw-text (translate :circuit-help) (+ x 14) (+ y 70) '(139 165 178 255) :scale 1)
    (if (null predio)
        (draw-text (translate :select-device) (+ x 14) (+ y 116) '(242 190 79 255) :scale 1)
        (let* ((config (configuracao-circuito-padrao predio))
               (condicao (circuit-device-config-condition config))
               (sinal (if (eq (building-kind predio) :circuit-sensor)
                          (circuit-device-config-output-signal config)
                          (or (and condicao (circuit-condition-left condicao))
                              (circuit-device-config-input-signal config))))
               (operador (if (eq (building-kind predio) :arithmetic-combinator)
                             (circuit-device-config-operator config)
                             (and condicao (circuit-condition-comparator condicao))))
               (constante (if condicao (circuit-condition-constant condicao)
                              (circuit-device-config-constant config))))
          (draw-text (format nil "#~D  ~A" (building-id predio)
                             (string-upcase (string (building-kind predio))))
                     (+ x 14) (+ y 100) '(235 241 244 255) :scale 1)
          (draw-text (if (zerop *pagina-dispositivo-circuito*)
                         (if (eq (current-language) :pt) "[LOGICA]  CONTROLES >  TAB/LB/RB"
                              "[LOGIC]  CONTROLS >  TAB/LB/RB")
                         (if (eq (current-language) :pt) "< LOGICA  [CONTROLES]  TAB/LB/RB"
                              "< LOGIC  [CONTROLS]  TAB/LB/RB"))
                     (+ x 14) (+ y 122) '(241 193 90 255) :scale 1)
          (loop for (titulo valor) in
                (if (plusp *pagina-dispositivo-circuito*)
                    (loop for campo in (campos-avancados-circuito predio)
                          collect (list (if (eq (current-language) :pt) (second campo) (third campo))
                                        (rotulo-valor-controle (valor-campo-avancado config campo))))
                (list (list (translate :sensor-mode)
                            (if (eq (building-kind predio) :circuit-sensor)
                                (getf (building-state predio) :sensor-mode :inventory)
                                (circuit-device-config-behavior config)))
                      (list (translate :signal) (rotulo-sinal-circuito sinal))
                      (list (translate :operator) operador)
                      (list (translate :value) constante)
                      (list (if (eq (current-language) :pt) "SAIDA/FILTRO" "OUTPUT/FILTER")
                            (rotulo-sinal-circuito
                             (if (member (building-kind predio)
                                         '(:arithmetic-combinator :decider-combinator))
                                 (circuit-device-config-output-signal config)
                                 (circuit-device-config-input-signal config))))))
                for i from 0 for linha-y = (+ y 143 (* i 42)) do
            (draw-rect (+ x 12) linha-y (- w 24) 34 '(10 25 35 255))
            (draw-rect (+ x 12) linha-y (- w 24) 34 '(44 75 90 255) :outline t)
            (when (= i *campo-circuito-gamepad*)
              (draw-rect (+ x 12) linha-y 3 34 '(241 193 90 255)))
            (when (and (zerop *pagina-dispositivo-circuito*) (= i 1)
                       (consp sinal) (eq (first sinal) :item))
              (desenhar-icone-item (second sinal) (+ x 16) (+ linha-y 7) 20))
            (let ((texto (format nil "~A  < ~A >" titulo valor)))
              (draw-text (subseq texto 0 (min 36 (length texto)))
                         (+ x 38) (+ linha-y 12) '(197 220 229 255) :scale 1)))
          (draw-text (translate :live-signals) (+ x 14) (+ y 367) '(112 245 220 255) :scale 1)
          (loop for (s . valor) in (sinais-visiveis-predio mundo predio)
                for i from 0 do
            (draw-text (format nil "~A = ~D" (rotulo-sinal-circuito s) valor)
                       (+ x 20) (+ y 393 (* i 23)) '(194 207 217 255) :scale 1))))))

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
                         px py +tamanho-celula+ +tamanho-celula+ :world t
                         :tint (tinta-terreno mundo x y))
            (when recurso
              (let ((indice (indice-recurso-sprite recurso)))
                (when indice
                  (draw-sprite :terrain (+ 4 indice) px py +tamanho-celula+
                               +tamanho-celula+ :world t))))
            (unless recurso
              (multiple-value-bind (prop tam) (prop-ambiental mundo x y)
                (when prop
                  (draw-sprite :environment-props-v2 prop
                               (- px (/ (- tam 32) 2)) (- py (- tam 32))
                               tam tam :world t))))))))
    (map-buildings (lambda (b) (desenhar-construcao b :game-world mundo)) mundo)
    (when *modo-circuito* (desenhar-redes-circuito mundo))
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
  (when *modo-circuito* (return-from desenhar-previa-construcao nil))
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

(defun desenhar-objetivo-atual (mundo)
  "Mantém a próxima ação e sua recompensa visíveis sem abrir menus."
  (multiple-value-bind (texto atual alvo recompensa) (objetivo-capitulo mundo)
    (let ((x 12) (y 168) (largura 270))
      (draw-rect x y largura 86 '(4 10 17 238))
      (draw-rect x y largura 86 '(53 91 108 255) :outline t)
      (draw-rect x y 4 86 '(112 245 220 255))
      (draw-text (translate :objective) (+ x 14) (+ y 10) '(112 245 220 255) :scale 1)
      (draw-text (subseq texto 0 (min 38 (length texto))) (+ x 14) (+ y 29)
                 '(222 234 239 255) :scale 1)
      (draw-rect (+ x 14) (+ y 48) 190 7 '(18 32 42 255))
      (draw-rect (+ x 14) (+ y 48) (* 190 (/ atual (float (max 1 alvo)))) 7
                 '(244 190 79 255))
      (draw-text (if (<= (dado mundo :chapter 1) 6)
                     (format nil "~D/~DS" (floor atual 30) (floor alvo 30))
                     (format nil "~D/~D" atual alvo)) (+ x 215) (+ y 47)
                 '(244 205 109 255) :scale 1)
      (when recompensa
        (let ((linha (format nil "~A: ~A" (translate :next-reward)
                             (texto-itens recompensa))))
          (draw-text (subseq linha 0 (min 40 (length linha))) (+ x 14) (+ y 67)
                     '(155 181 193 255) :scale 1))))))

(defun desenhar-guia-circuitos (mundo)
  (let ((c (dado mundo :chapter 1)))
    (when (and *mostrar-ajuda* (<= c 6))
      (let* ((pt (eq (current-language) :pt))
             (linhas
               (nth (1- c)
                 (if pt
                     '(("Minerador sobre ferro -> esteira -> nucleo." "R gira. Arraste para estender a linha." "Mantenha a producao por 6 segundos.")
                       ("Adicione um painel solar e uma fornalha." "Minerador -> esteira -> fornalha." "Produza metal com geracao adicional ativa.")
                       ("Aponte o sensor para o estoque da fornalha." "C: ligue sensor ao braco. Sinal: IRON-PLATE." "Condicao > 2: observe o braco ligar e parar.")
                       ("Alimente um divisor com ferro e cobre." "Ligue um fio. SAIDA/FILTRO: ITEM/IRON-ORE." "As duas saidas precisam transportar itens.")
                       ("Bomba na agua -> tanque; sensor olha tanque." "Sensor FLUID / FLUID/WATER. Ligue a bomba." "Condicao WATER < 100: encher e parar.")
                       ("Combinador: A + 1 -> A. Saida ligada a entrada." "Ligue saida a lampada e alarme: A > 5." "Mantenha o contador funcionando por 6s."))
                     '(("Miner on iron -> belt -> core." "R rotates. Drag to extend the line." "Keep the line working for 6 seconds.")
                       ("Add a solar panel and a furnace." "Miner -> belt -> furnace." "Produce metal with added generation online.")
                       ("Point a sensor at the furnace inventory." "C: wire sensor to arm. Signal: IRON-PLATE." "Condition > 2: see the arm run and stop.")
                       ("Feed iron and copper into a splitter." "Connect a wire. OUTPUT/FILTER: ITEM/IRON-ORE." "Both outputs must actually transport items.")
                       ("Pump on water -> tank; sensor faces tank." "Sensor FLUID / FLUID/WATER. Wire the pump." "Condition WATER < 100: fill, then stop.")
                       ("Combinator: A + 1 -> A. Wire output to input." "Wire output to lamp and alarm: A > 5." "Keep the counter working for 6 seconds.")))))
             (icones (nth (1- c) '((:miner :belt :core) (:solar-panel :stone-furnace)
                                   (:circuit-sensor :inserter) (:splitter :belt)
                                   (:pump :tank :circuit-sensor)
                                   (:arithmetic-combinator :signal-lamp :programmable-alarm)))))
        (draw-rect 12 266 328 128 '(4 10 17 238))
        (draw-rect 12 266 328 128 '(53 91 108 255) :outline t)
        (loop for kind in icones for i from 0 do
          (desenhar-icone kind (+ 27 (* i 56)) 276 32)
          (when (< i (1- (length icones)))
            (draw-text ">" (+ 65 (* i 56)) 288 '(244 190 79 255) :scale 1)))
        (loop for linha in linhas for i from 0 do
          (draw-text linha 23 (+ 320 (* i 19)) '(193 211 220 255) :scale 1))))))

(defun desenhar-notificacoes (mundo)
  (let ((ativas (remove-if (lambda (n) (<= (getf n :until) (world-tick mundo)))
                            (dado mundo :notifications nil))))
    (setf (dado mundo :notifications) ativas)
    (loop for notificacao in ativas for linha from 0
          for x = (if *modo-circuito* 12 (- (screen-width) 708))
          for y = (+ (if *modo-circuito* 480 140) (* linha 30))
          for cor = (getf notificacao :color '(112 245 220 255))
          for texto = (getf notificacao :text "") do
      (draw-rect x y 430 25 '(4 10 17 236))
      (draw-rect x y 4 25 cor)
      (draw-text (subseq texto 0 (min 62 (length texto))) (+ x 13) (+ y 8)
                 cor :scale 1))))

(defun desenhar-ui (mundo)
  (draw-rect 0 0 (screen-width) 72 '(4 8 15 246))
  (draw-rect 0 71 (screen-width) 1 '(62 105 119 255))
  (draw-text (translate :title) 14 10 '(112 245 220 255) :scale 2)
  (let* ((c (dado mundo :chapter 1)) (nome (nome-capitulo (1- c)))
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
    (cond (*modo-circuito* (desenhar-painel-circuito mundo))
          (*mostrar-catalogo* (desenhar-catalogo mundo))
          (t (desenhar-minimapa mundo)))
    (desenhar-alertas-fabrica mundo)
    (desenhar-objetivo-atual mundo)
    (desenhar-guia-circuitos mundo)
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
    (when (and (not *modo-circuito*) (< (world-tick mundo) (dado mundo :message-until 0)))
      (let ((msg (dado mundo :message "")))
        (draw-rect 260 92 (- (screen-width) 520) 38 '(38 16 50 225))
        (draw-text msg 280 105 '(235 131 255 255) :scale 2)))
    (desenhar-notificacoes mundo)
    (unless *modo-circuito* (desenhar-inspetor-predio mundo))
    (when *gamepad-ativo*
      (draw-circle *cursor-gamepad-x* *cursor-gamepad-y* 9 '(245 222 117 255))
      (draw-line (- *cursor-gamepad-x* 14) *cursor-gamepad-y*
                 (+ *cursor-gamepad-x* 14) *cursor-gamepad-y* '(245 222 117 255)))
    ))

(defun garantir-pausa () (unless (paused-p) (toggle-pause)))
(defun garantir-execucao () (when (paused-p) (toggle-pause)))
(defun diretorio-saves ()
  (uiop:ensure-directory-pathname
   (or (uiop:getenv-pathname "ASTERION_SAVE_DIR") (merge-pathnames "saves/v3/" *raiz*))))
(defun caminho-quicksave () (merge-pathnames "quicksave.save" (diretorio-saves)))

(defun caminho-perfil ()
  (let ((nome (or (uiop:getenv "ASTERION_PROFILE") "default")))
    (unless (and (<= 1 (length nome) 48)
                 (every (lambda (c) (or (find c "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
                                        nil)) nome))
      (error "Nome de perfil inválido / Invalid profile name."))
    (merge-pathnames (format nil "profiles/~A.sexp" nome) (diretorio-saves))))

(defun dados-configuracoes ()
  (list :format 1 :language (current-language) :master-volume *volume-configurado*
        :effects-volume (audio-bus-volume :effects) :alerts-volume (audio-bus-volume :alerts)
        :reduced-flashes *reduzir-flashes* :colorblind *paleta-configurada*
        :resolution *resolucao-configurada* :fullscreen *tela-cheia-configurada*
        :ui-scale *escala-ui-configurada*))

(defun validar-configuracoes (dados)
  "Valida o documento inteiro antes de mudar qualquer configuração ativa."
  (unless (and (listp dados) (evenp (length dados)) (= (getf dados :format 0) 1)
               (member (getf dados :language) '(:en :pt))
               (every (lambda (k) (typep (getf dados k) '(integer 0 128)))
                      '(:master-volume :effects-volume :alerts-volume))
               (every (lambda (k) (member (getf dados k) '(nil t)))
                      '(:reduced-flashes :colorblind :fullscreen))
               (member (getf dados :resolution) '((1280 720) (1600 900) (1920 1080)) :test #'equal)
               (member (getf dados :ui-scale) '(3/4 9/10 1)))
    (error "Perfil inválido; arquivo preservado / Invalid profile; file preserved."))
  dados)

(defun aplicar-configuracoes (dados)
  (validar-configuracoes dados)
  (apply #'set-display-mode (append (getf dados :resolution)
                                    (list :fullscreen (getf dados :fullscreen)
                                          :ui-scale (getf dados :ui-scale))))
  (set-language (getf dados :language))
  (setf *volume-configurado* (getf dados :master-volume)
        *reduzir-flashes* (getf dados :reduced-flashes)
        *paleta-configurada* (getf dados :colorblind)
        *resolucao-configurada* (copy-list (getf dados :resolution))
        *tela-cheia-configurada* (getf dados :fullscreen)
        *escala-ui-configurada* (getf dados :ui-scale))
  (set-audio-volume *volume-configurado*)
  (set-audio-bus-volume :effects (getf dados :effects-volume))
  (set-audio-bus-volume :alerts (getf dados :alerts-volume)))

(defun salvar-configuracoes (&optional (arquivo (caminho-perfil)))
  (handler-case
      (progn
        (unless *perfil-gravavel* (error "Perfil inválido preservado / Invalid profile preserved."))
        (let ((temporario (pathname (format nil "~A.tmp" arquivo))))
          (ensure-directories-exist arquivo)
          (with-open-file (s temporario :direction :output :if-exists :supersede :external-format :utf-8)
            (let ((*print-readably* t) (*print-pretty* nil)) (write (dados-configuracoes) :stream s)))
          (uiop:rename-file-overwriting-target temporario arquivo))
        t)
    (error (e) (setf *mensagem-menu* (princ-to-string e)) nil)))

(defun carregar-configuracoes (&optional (arquivo (caminho-perfil)))
  (setf *perfil-gravavel* t)
  (handler-case
      (when (probe-file arquivo)
          (let ((dados (with-open-file (s arquivo :external-format :utf-8)
                         (let ((*read-eval* nil)) (read s)))))
            (aplicar-configuracoes dados)))
    (error (e)
      (setf *perfil-gravavel* nil *mensagem-menu* (princ-to-string e))
      (engine-log :warning "~A" e))))

(defun desenhar-fundo-menu ()
  (draw-sprite :cover 0 0 0 (screen-width) (screen-height))
  (draw-rect 0 0 (screen-width) (screen-height) '(2 6 13 105))
  (draw-rect 0 0 520 (screen-height) '(3 8 16 222))
  (draw-sprite :logo 0 38 58 430 108)
  (draw-text (translate :menu-tagline) 76 184 '(241 185 76 255) :scale 1))

(defun desenhar-botao-menu (texto x y largura selecionado &key desabilitado (escala 1))
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
                 (if desabilitado '(84 96 105 255) '(213 231 237 255)) :scale escala))))

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
  (let ((idioma (if (eq (current-language) :pt) "PORTUGUES" "ENGLISH"))
        (pt (eq (current-language) :pt)))
    (loop for texto in (list (format nil "~A: ~A" (translate :language) idioma)
                             (format nil "~A: ~D%" (translate :audio)
                                     (round (* 100 (/ *volume-configurado* 128.0))))
                             (format nil "~A: ~A" (translate :flashes)
                                     (if *reduzir-flashes* "ON" "OFF"))
                             (format nil "~A: ~Dx~D" (if pt "RESOLUCAO" "RESOLUTION")
                                     (first *resolucao-configurada*) (second *resolucao-configurada*))
                             (format nil "~A: ~A" (if pt "TELA CHEIA" "FULLSCREEN")
                                     (if *tela-cheia-configurada* "ON" "OFF"))
                             (format nil "UI: ~D%" (round (* 100 *escala-ui-configurada*)))
                             (format nil "~A: ~D%" (if pt "EFEITOS" "EFFECTS")
                                     (round (* 100 (audio-bus-volume :effects)) 128))
                             (format nil "~A: ~D%" (if pt "ALERTAS" "ALERTS")
                                     (round (* 100 (audio-bus-volume :alerts)) 128))
                             (format nil "~A: ~A" (if pt "DALTONISMO" "COLORBLIND")
                                     (if *paleta-configurada* "ON" "OFF"))
                             (if pt "TESTAR ALERTA" "PREVIEW ALERT")
                             (if pt "RESTAURAR PADROES" "RESTORE DEFAULTS")
                             (translate :back))
          for i from 0 for y = (+ 292 (* (mod i 6) 58)) do
      (desenhar-botao-menu texto (+ 92 (* (floor i 6) 530)) y 490 (= i *indice-menu*) :escala 2))
  (when (plusp (length *mensagem-menu*))
    (draw-text (subseq *mensagem-menu* 0 (min 140 (length *mensagem-menu*)))
               92 665 '(255 137 130 255) :scale 1))))

(defun desenhar-mods ()
  (desenhar-fundo-menu)
  (draw-text (translate :mods) 92 238 '(112 245 220 255) :scale 2)
  (draw-rect 92 290 380 184 '(7 17 27 242))
  (loop for mod in (loaded-mods) for i from 0 below 3 do
    (draw-text (format nil "~A ~A" (mod-manifest-id mod) (mod-manifest-version mod))
               112 (+ 308 (* i 20)) '(104 241 196 255) :scale 1))
  (when (null (loaded-mods))
    (draw-text (if (eq (current-language) :pt) "NENHUM MOD CARREGADO" "NO MODS LOADED")
               112 310 '(211 229 235 255) :scale 1))
  (loop for erro in (mod-errors) for i from 0 below 2 do
    (let ((texto (format nil "~A: ~A" (getf erro :id) (getf erro :message))))
      (draw-text (subseq texto 0 (min 54 (length texto))) 112 (+ 365 (* i 18))
                 '(255 137 130 255) :scale 1)))
  (draw-text (translate :mods-warning) 112 404 '(245 182 76 255) :scale 1)
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

(defconstant +linhas-tecnologia+ 4)

(defun colunas-tecnologia ()
  "A árvore se adapta sem comprimir os cartões até ficarem ilegíveis."
  (max 3 (min 6 (floor (- (screen-width) 64) 190))))

(defun tecnologias-por-pagina ()
  (* +linhas-tecnologia+ (colunas-tecnologia)))

(defun pagina-tecnologia (indice)
  (floor indice (tecnologias-por-pagina)))

(defun intervalo-pagina-tecnologia ()
  (let* ((tamanho (tecnologias-por-pagina))
         (inicio (* (pagina-tecnologia *indice-tecnologia*) tamanho)))
    (values inicio (min (length *ordem-tecnologias*) (+ inicio tamanho)))))

(defun posicao-tecnologia (indice)
  (let* ((colunas (colunas-tecnologia))
         (local (mod indice (tecnologias-por-pagina)))
         (passo (if (= colunas 1) 0
                    (/ (- (screen-width) 88 180) (1- colunas)))))
    (values (+ 44 (round (* (mod local colunas) passo)))
            (+ 112 (* (floor local colunas) 90)))))

(defun estado-tecnologia (mundo id)
  (cond ((tecnologia-concluida-p mundo id) :completed)
        ((eq id (dado mundo :active-research)) :active)
        ((tecnologia-disponivel-p mundo id) :available)
        (t :locked)))

(defun cor-estado-tecnologia (estado)
  (case estado
    (:completed '(73 211 160 255)) (:active '(243 184 72 255))
    (:available '(85 211 230 255)) (t '(67 77 90 255))))

(defun nome-cartao-tecnologia (tecnologia)
  "Abrevia nomes no nó; o painel inferior mantém o nome completo."
  (let ((nome (string-upcase (technology-definition-name tecnologia))))
    (if (> (length nome) 16)
        (concatenate 'string (subseq nome 0 14) "..")
        nome)))

(defun desenhar-arvore-tecnologica (mundo)
  (draw-rect 0 0 (screen-width) (screen-height) '(3 8 15 247))
  (draw-text (translate :technology) 42 28 '(112 245 220 255) :scale 3)
  (let* ((pagina (pagina-tecnologia *indice-tecnologia*))
         (paginas (ceiling (length *ordem-tecnologias*) (tecnologias-por-pagina))))
    (draw-text "ARROWS SELECT  ENTER RESEARCH  PGUP/PGDN PAGE  T/ESC CLOSE"
               44 70 '(159 182 194 255))
    (draw-text (format nil "PAGE ~D / ~D" (1+ pagina) paginas)
               (- (screen-width) 150) 38 '(243 184 72 255))
    (multiple-value-bind (inicio fim) (intervalo-pagina-tecnologia)
      ;; Dependências da página aparecem atrás dos nós; conexões externas recebem
      ;; uma marca no cartão em vez de linhas atravessando páginas invisíveis.
      (loop for indice from inicio below fim
            for id = (aref *ordem-tecnologias* indice)
            for tech = (find-technology id) do
        (multiple-value-bind (x y) (posicao-tecnologia indice)
          (dolist (requisito (technology-definition-prerequisites tech))
            (let ((origem (position requisito *ordem-tecnologias*)))
              (when (and origem (= (pagina-tecnologia origem) pagina))
                (multiple-value-bind (ox oy) (posicao-tecnologia origem)
                  (draw-line (+ ox 90) (+ oy 36) (+ x 90) (+ y 36)
                             (if (tecnologia-concluida-p mundo requisito)
                                 '(66 188 151 255) '(48 65 76 255)))))))))
      (loop for indice from inicio below fim
            for id = (aref *ordem-tecnologias* indice)
            for tech = (find-technology id)
            for estado = (estado-tecnologia mundo id) do
        (multiple-value-bind (x y) (posicao-tecnologia indice)
          (draw-rect x y 180 72 (if (= indice *indice-tecnologia*)
                                    '(24 46 58 255) '(8 19 29 255)))
          (draw-rect x y 180 72 (if (= indice *indice-tecnologia*)
                                    '(241 188 76 255) (cor-estado-tecnologia estado)) :outline t)
          (draw-text (nome-cartao-tecnologia tech)
                     (+ x 9) (+ y 12) '(214 231 238 255))
          (draw-text (translate estado) (+ x 9) (+ y 39)
                     (cor-estado-tecnologia estado))
          (draw-text (format nil "~D" (custo-tecnologia tech)) (+ x 148) (+ y 39)
                     '(192 174 238 255)))))
  (let* ((id (aref *ordem-tecnologias* *indice-tecnologia*))
         (tech (find-technology id)) (estado (estado-tecnologia mundo id))
         (ativo (eq id (dado mundo :active-research)))
         (progresso (if ativo (dado mundo :research-progress 0) 0))
         (custo (custo-tecnologia tech))
         (painel-y 476)
         (painel-h (max 138 (min 190 (- (screen-height) painel-y 18))))
         (barra-y (+ painel-y painel-h -34)))
    (draw-rect 42 painel-y (- (screen-width) 84) painel-h '(6 15 24 252))
    (draw-rect 42 painel-y (- (screen-width) 84) painel-h
               (cor-estado-tecnologia estado) :outline t)
    (draw-text (technology-definition-name tech) 62 (+ painel-y 18)
               '(235 242 245 255) :scale 2)
    (draw-text (string-upcase (translate estado)) 62 (+ painel-y 49)
               (cor-estado-tecnologia estado))
    (draw-text (format nil "UNLOCKS: ~{~A~^, ~}" (technology-definition-unlocks tech))
               62 (+ painel-y 78) '(170 191 202 255))
    (draw-rect 62 barra-y 520 12 '(17 30 39 255))
    (draw-rect 62 barra-y (* 520 (/ (min progresso custo) (float custo))) 12
               (cor-estado-tecnologia estado))
    (draw-text (format nil "SCIENCE ~D / ~D" progresso custo) 598 (- barra-y 2)
               '(218 229 234 255)))))

(defun clicar-arvore-tecnologica (mundo x y)
  (multiple-value-bind (inicio fim) (intervalo-pagina-tecnologia)
    (loop for indice from inicio below fim do
      (multiple-value-bind (nx ny) (posicao-tecnologia indice)
        (when (and (<= nx x (+ nx 180)) (<= ny y (+ ny 72)))
          (setf *indice-tecnologia* indice)
          (selecionar-pesquisa mundo (aref *ordem-tecnologias* indice))
          (return t))))))

(defun renderizar (mundo alpha)
  (declare (ignore alpha))
  (setf *mundo-corrente-ui* mundo)
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

(defun posicao-cursor-ui ()
  (if *gamepad-ativo* (values *cursor-gamepad-x* *cursor-gamepad-y*) (mouse-position)))

(defun atualizar (mundo delta)
  (declare (ignore delta))
  (when (eq *tela-ui* :playing)
    (mover-personagem mundo)
    (when *gamepad-ativo*
      (setf *cursor-gamepad-x*
            (max 0 (min (1- (screen-width)) (+ *cursor-gamepad-x* (* 12 (aref *eixos-gamepad* 2)))))
            *cursor-gamepad-y*
            (max 0 (min (1- (screen-height)) (+ *cursor-gamepad-y* (* 12 (aref *eixos-gamepad* 3)))))))))

(defun celula-em-tela (sx sy)
  (multiple-value-bind (wx wy) (screen-to-world sx sy)
    (cons (floor wx +tamanho-celula+) (floor wy +tamanho-celula+))))

(defun registrar-construcao-recente (mundo predio)
  (let ((historico (cons (list :id (building-id predio) :tick (world-tick mundo))
                         (dado mundo :recent-builds nil))))
    (setf (dado mundo :recent-builds) (subseq historico 0 (min 32 (length historico))))))

(defun notificar-bloqueio-construcao (mundo texto)
  (unless (and (string= texto (dado mundo :last-build-error ""))
               (< (- (world-tick mundo) (dado mundo :last-build-error-tick -100)) 30))
    (setf (dado mundo :last-build-error) texto
          (dado mundo :last-build-error-tick) (world-tick mundo))
    (notificar mundo texto :duracao 75 :cor '(255 111 128 255))))

(defun construir-na-celula (mundo x y)
  "Constrói uma célula e registra uma operação reversível de curta duração."
  (let* ((kind (aref *selecionados* *indice-selecao*)) (def (find-building kind)))
    (cond
      ((not (construcao-desbloqueada-p mundo kind))
       (notificar-bloqueio-construcao mundo (translate :locked-building)) nil)
      ((not (alcance-personagem-p mundo x y))
       (notificar-bloqueio-construcao mundo (translate :out-of-range)) nil)
      ((building-at mundo x y)
       (notificar-bloqueio-construcao mundo (translate :occupied)) nil)
      ((not (consumir-custo mundo def))
       (notificar-bloqueio-construcao mundo (translate :no-material)) nil)
      (t
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
         predio)))))

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
  (gethash id (antigonus::world-buildings mundo)))

(defun reembolsar-fios-predio (mundo predio)
  (dolist (fio (circuit-connections mundo predio))
    (disconnect-circuit mundo fio)
    (inventory-add (inventario-jogador mundo)
                   (if (eq (circuit-wire-color fio) :red) :wire-red :wire-green) 1)))

(defun desfazer-ultima-construcao (mundo)
  "Remove a construção válida mais recente por até dez segundos e devolve 100%."
  (loop while (dado mundo :recent-builds nil) do
    (let* ((registro (pop (dado mundo :recent-builds)))
           (predio (predio-por-id mundo (getf registro :id))))
      (when (and predio (<= (- (world-tick mundo) (getf registro :tick)) 300)
                 (not (eq (building-kind predio) :core)))
        (dolist (custo (building-definition-cost (find-building (building-kind predio))))
          (inventory-add (inventario-jogador mundo) (car custo) (cdr custo)))
        (reembolsar-fios-predio mundo predio)
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
        (devolver-custo mundo (find-building (building-kind b)))
        (reembolsar-fios-predio mundo b) (remove-building mundo b)
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

(defun alternar-modo-circuito (&optional mundo)
  (setf *modo-circuito* (not *modo-circuito*)
        *origem-fio-circuito* nil)
  (unless *modo-circuito* (setf *predio-circuito-selecionado* nil))
  (when mundo
    (notificar mundo (if *modo-circuito* (translate :circuit-mode)
                         (if (eq (current-language) :pt) "MODO DE CIRCUITOS FECHADO"
                             "CIRCUIT MODE CLOSED")) :duracao 55))
  *modo-circuito*)

(defun predio-em-tela (mundo sx sy)
  (multiple-value-bind (wx wy) (screen-to-world sx sy)
    (building-at mundo (floor wx +tamanho-celula+) (floor wy +tamanho-celula+))))

(defun predio-conectavel-p (predio)
  (and predio (building-definition-circuit-ports (find-building (building-kind predio)))))

(defun conectar-predios-circuito (mundo origem destino &key (porta-a :main) (porta-b :main))
  (let* ((item (if (eq *cor-fio-circuito* :red) :wire-red :wire-green))
         (inventario (inventario-jogador mundo)))
    (cond
      ((not (inventory-remove inventario item 1))
       (notificar-bloqueio-construcao mundo (translate :no-material)) nil)
      (t
       (handler-case
           (multiple-value-bind (fio criado)
               (connect-circuit mundo origem destino :port-a porta-a :port-b porta-b
                                 :color *cor-fio-circuito*)
             (if (not criado)
                 (progn (inventory-add inventario item 1)
                        (notificar mundo (if (eq (current-language) :pt)
                                             "CONEXAO JA EXISTE" "CONNECTION ALREADY EXISTS")
                                   :duracao 60))
                 (progn
                   (criar-efeito mundo :vfx-spark (+ (building-x destino) .5)
                                 (+ (building-y destino) .5) :duracao 16 :tamanho 32)
                   (notificar mundo (format nil "~A #~D" (translate :circuit-mode)
                                            (circuit-wire-id fio)) :duracao 60)))
             fio)
         (error (e)
           (inventory-add inventario item 1)
           (notificar-bloqueio-construcao mundo (princ-to-string e)) nil))))))

(defun porta-magnetica-circuito (mundo sx sy)
  "Busca só os nove tiles próximos, escolhendo a porta mais próxima do cursor."
  (multiple-value-bind (wx wy) (screen-to-world sx sy)
    (let ((gx (floor wx 32)) (gy (floor wy 32))
          (menor (expt 19 2)) melhor melhor-porta)
      (loop for y from (1- gy) to (1+ gy) do
        (loop for x from (1- gx) to (1+ gx) for b = (building-at mundo x y) do
          (when b
            (dolist (porta (portas-circuito-predio (building-kind b)))
              (let ((d (+ (expt (- wx (posicao-porta-x b porta)) 2)
                          (expt (- wy (posicao-porta-y b)) 2))))
                (when (< d menor) (setf menor d melhor b melhor-porta porta)))))))
      (values melhor melhor-porta))))

(defun selecionar-porta-circuito (mundo sx sy &key somente-destino)
  (multiple-value-bind (predio porta) (porta-magnetica-circuito mundo sx sy)
    (when (and (predio-conectavel-p predio)
               (alcance-personagem-p mundo (building-x predio) (building-y predio)))
      (when (and somente-destino
                 (or (null *origem-fio-circuito*) (eq predio *origem-fio-circuito*)))
        (return-from selecionar-porta-circuito nil))
      (setf *predio-circuito-selecionado* predio)
      (cond
        ((null *origem-fio-circuito*)
         (setf *origem-fio-circuito* predio *porta-origem-circuito* porta)
         (notificar mundo (if (eq (current-language) :pt)
                              "ORIGEM SELECIONADA - ESCOLHA O DESTINO"
                              "SOURCE SELECTED - CHOOSE DESTINATION") :duracao 75))
        ((and (eq predio *origem-fio-circuito*) (eq porta *porta-origem-circuito*))
         (setf *origem-fio-circuito* nil))
        (t
         (conectar-predios-circuito mundo *origem-fio-circuito* predio
                                    :porta-a *porta-origem-circuito* :porta-b porta)
         (setf *origem-fio-circuito* nil)))
      t)))

(defun remover-fio-circuito-em (mundo sx sy)
  (let ((fio nil) (melhor 100.0))
    (dolist (candidato (circuit-connections mundo nil *cor-fio-circuito*))
      (let ((a (predio-por-id mundo (circuit-wire-a-building candidato)))
            (b (predio-por-id mundo (circuit-wire-b-building candidato))))
        (when (and a b (alcance-personagem-p mundo (building-x a) (building-y a)))
          (multiple-value-bind (ax ay) (world-to-screen (posicao-porta-x a (circuit-wire-a-port candidato))
                                                       (posicao-porta-y a))
            (multiple-value-bind (bx by) (world-to-screen (posicao-porta-x b (circuit-wire-b-port candidato))
                                                         (posicao-porta-y b))
              (let* ((dx (- bx ax)) (dy (- by ay))
                     (u (max 0 (min 1 (/ (+ (* (- sx ax) dx) (* (- sy ay) dy))
                                         (max .001 (+ (* dx dx) (* dy dy)))))))
                     (dist (+ (expt (- sx (+ ax (* u dx))) 2)
                              (expt (- sy (+ ay (* u dy))) 2))))
                (when (< dist melhor) (setf melhor dist fio candidato))))))))
    (when fio
      (disconnect-circuit mundo fio)
      (inventory-add (inventario-jogador mundo)
                     (if (eq (circuit-wire-color fio) :red) :wire-red :wire-green) 1)
      (notificar mundo (if (eq (current-language) :pt) "FIO REMOVIDO" "WIRE REMOVED")
                 :duracao 60)
      t)))

(defun proximo-em-vetor (atual vetor &key (teste #'equal))
  (aref vetor (mod (1+ (or (position atual vetor :test teste) -1)) (length vetor))))

(defun editar-configuracao-circuito (mundo x y)
  "Edita campos por cartões; retorna verdadeiro quando o painel consumiu o clique."
  (declare (ignore mundo))
  (let ((painel-x (- (screen-width) 350)) (predio *predio-circuito-selecionado*))
    (when (and *modo-circuito* (>= x painel-x) (<= 204 y 227))
      (setf *pagina-dispositivo-circuito* (- 1 *pagina-dispositivo-circuito*)
            *campo-circuito-gamepad* 0)
      (return-from editar-configuracao-circuito t))
    (when (and *modo-circuito* predio (>= x painel-x) (>= y 231))
      (let* ((config (configuracao-circuito-padrao predio))
             (linha (floor (- y 231) 42))
             (*sinais-circuito-ui* (sinais-disponiveis-circuito))
             (condicao (circuit-device-config-condition config)))
        (unless (and (< linha 5) (< (mod (- y 231) 42) 34))
          (return-from editar-configuracao-circuito t))
        (when (plusp *pagina-dispositivo-circuito*)
          (let ((campo (nth linha (campos-avancados-circuito predio))))
            (when campo
              (let ((novo (proximo-em-vetor (valor-campo-avancado config campo) (fourth campo))))
                (if (eq (first campo) :right)
                    (setf (circuit-condition-right condicao) novo)
                    (funcall (fdefinition (list 'setf (first campo))) novo config)))
              (configure-circuit-device predio config)))
          (return-from editar-configuracao-circuito t))
        (case linha
          (0 (when (eq (building-kind predio) :circuit-sensor)
               (setf (getf (building-state predio) :sensor-mode)
                     (proximo-em-vetor (getf (building-state predio) :sensor-mode :inventory)
                                       *modos-sensor-ui*))))
          (1 (let ((novo (proximo-em-vetor
                          (cond ((eq (building-kind predio) :circuit-sensor)
                                 (circuit-device-config-output-signal config))
                                (condicao (circuit-condition-left condicao))
                                (t (circuit-device-config-input-signal config)))
                          (if (eq (building-kind predio) :circuit-sensor) *sinais-circuito-ui*
                              (concatenate 'vector *sinais-circuito-ui*
                                           (if condicao #(:each :anything :everything) #(:each)))))))
               (cond ((eq (building-kind predio) :circuit-sensor)
                      (setf (circuit-device-config-output-signal config) novo))
                     (condicao (setf (circuit-condition-left condicao) novo))
                     (t (setf (circuit-device-config-input-signal config) novo)))))
          (2 (if (eq (building-kind predio) :arithmetic-combinator)
                 (setf (circuit-device-config-operator config)
                       (proximo-em-vetor (circuit-device-config-operator config)
                                         #(:+ :- :* :/ :mod :min :max)))
                 (when condicao (setf (circuit-condition-comparator condicao)
                       (proximo-em-vetor (circuit-condition-comparator condicao)
                                         *operadores-circuito-ui*)))))
          (3 (let ((delta (cond ((< x (+ painel-x 85)) -10)
                                ((< x (+ painel-x 175)) -1)
                                ((< x (+ painel-x 260)) 1) (t 10))))
               (if (eq (building-kind predio) :arithmetic-combinator)
                   (incf (circuit-device-config-constant config) delta)
                   (when condicao (incf (circuit-condition-constant condicao) delta)))))
          (4 (if (member (building-kind predio) '(:arithmetic-combinator :decider-combinator))
                 (setf (circuit-device-config-output-signal config)
                       (proximo-em-vetor (circuit-device-config-output-signal config)
                                         (concatenate 'vector *sinais-circuito-ui* #(:each))))
                 (setf (circuit-device-config-input-signal config)
                       (proximo-em-vetor (circuit-device-config-input-signal config)
                                         (concatenate 'vector #(nil) *sinais-circuito-ui*))))))
        (configure-circuit-device predio config)
        t))))

(defun abrir-sessao (mundo)
  (replace-world mundo)
  (setf (dado mundo :colorblind-circuits) *paleta-configurada*)
  (setf *sessao-iniciada* t *tela-ui* :playing *indice-menu* 0 *mensagem-menu* ""
        *arrasto-construcao* nil *ultima-celula-arrasto* nil
        *modo-circuito* nil *origem-fio-circuito* nil *predio-circuito-selecionado* nil)
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
  (handler-case
   (progn
    (case indice
    (0 (set-language (if (eq (current-language) :pt) :en :pt)))
    (1 (setf *volume-configurado*
             (cond ((< *volume-configurado* 32) 64)
                   ((< *volume-configurado* 80) 96)
                   ((< *volume-configurado* 112) 128)
                   (t 0)))
       (set-audio-volume *volume-configurado*))
    (2 (setf *reduzir-flashes* (not *reduzir-flashes*)))
    (3 (setf *resolucao-configurada*
             (proximo-em-vetor *resolucao-configurada* #((1280 720) (1600 900) (1920 1080)))))
    (4 (setf *tela-cheia-configurada* (not *tela-cheia-configurada*)))
    (5 (setf *escala-ui-configurada* (proximo-em-vetor *escala-ui-configurada* #(1 9/10 3/4))))
    (6 (set-audio-bus-volume :effects (mod (+ 32 (audio-bus-volume :effects)) 160)))
    (7 (set-audio-bus-volume :alerts (mod (+ 32 (audio-bus-volume :alerts)) 160)))
    (8 (setf *paleta-configurada* (not *paleta-configurada*)))
    (9 (play-sound :alarm-warning))
    (10 (aplicar-configuracoes '(:format 1 :language :en :master-volume 96
                                :effects-volume 128 :alerts-volume 128 :reduced-flashes t
                                :colorblind nil :resolution (1280 720) :fullscreen nil :ui-scale 1)))
    (11 (setf *tela-ui* *retorno-configuracoes* *indice-menu* 0)))
    (when (member indice '(3 4 5))
      (apply #'set-display-mode (append *resolucao-configurada*
             (list :fullscreen *tela-cheia-configurada* :ui-scale *escala-ui-configurada*))))
    (when *mundo-corrente-ui* (setf (dado *mundo-corrente-ui* :colorblind-circuits) *paleta-configurada*))
    (unless (member indice '(9 11)) (salvar-configuracoes)))
   (error (e) (setf *mensagem-menu* (princ-to-string e)))))

(defun quantidade-opcoes-menu ()
  (case *tela-ui* (:main-menu 6) (:pause 5) (:settings 12) (otherwise 1)))

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
       (loop for coluna below 2
             for i = (indice-clique-menu x y (+ 92 (* coluna 530)) 292 490 6)
             when i do (setf *indice-menu* (+ i (* coluna 6)))
                       (ativar-configuracao *indice-menu*)))
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
     (let ((k (first dados))
           (total (length *ordem-tecnologias*))
           (colunas (colunas-tecnologia))
           (pagina (tecnologias-por-pagina)))
       (cond ((or (sdl2:scancode= k :scancode-escape)
                  (sdl2:scancode= k :scancode-t))
              (fechar-arvore-tecnologica))
             ((sdl2:scancode= k :scancode-left)
              (setf *indice-tecnologia* (mod (1- *indice-tecnologia*) total)))
             ((sdl2:scancode= k :scancode-right)
              (setf *indice-tecnologia* (mod (1+ *indice-tecnologia*) total)))
             ((sdl2:scancode= k :scancode-up)
              (setf *indice-tecnologia* (mod (- *indice-tecnologia* colunas) total)))
             ((sdl2:scancode= k :scancode-down)
              (setf *indice-tecnologia* (mod (+ *indice-tecnologia* colunas) total)))
             ((sdl2:scancode= k :scancode-pageup)
              (setf *indice-tecnologia* (max 0 (- *indice-tecnologia* pagina))))
             ((sdl2:scancode= k :scancode-pagedown)
              (setf *indice-tecnologia* (min (1- total)
                                             (+ *indice-tecnologia* pagina))))
             ((or (sdl2:scancode= k :scancode-return)
                  (sdl2:scancode= k :scancode-kp-enter))
              (selecionar-pesquisa mundo
                                   (aref *ordem-tecnologias* *indice-tecnologia*)))))
     t)
    (:mouse-down
     (destructuring-bind (botao x y) dados
       (when (= botao 1) (clicar-arvore-tecnologica mundo x y))) t)
    (:controller-down
     (let ((botao (first dados))
           (total (length *ordem-tecnologias*))
           (colunas (colunas-tecnologia))
           (pagina (tecnologias-por-pagina)))
       (case botao
         (0 (selecionar-pesquisa mundo (aref *ordem-tecnologias* *indice-tecnologia*)))
         (1 (fechar-arvore-tecnologica))
         (9 (setf *indice-tecnologia* (max 0 (- *indice-tecnologia* pagina))))
         (10 (setf *indice-tecnologia* (min (1- total)
                                            (+ *indice-tecnologia* pagina))))
         (11 (setf *indice-tecnologia* (mod (- *indice-tecnologia* colunas) total)))
         (12 (setf *indice-tecnologia* (mod (+ *indice-tecnologia* colunas) total)))
         (13 (setf *indice-tecnologia* (mod (1- *indice-tecnologia*) total)))
         (14 (setf *indice-tecnologia* (mod (1+ *indice-tecnologia*) total)))))
     t)
    (otherwise t)))

(defun entrada (mundo tipo &rest dados)
  (when (eq tipo :controller-disconnected)
    (fill *eixos-gamepad* 0.0) (setf *gamepad-ativo* nil)
    (return-from entrada t))
  (when (member tipo '(:controller-axis :controller-down)) (setf *gamepad-ativo* t))
  (when (member tipo '(:mouse-move :mouse-down :key-down)) (setf *gamepad-ativo* nil))
  ;; O modo de fios captura eventos antes das ferramentas destrutivas normais.
  (when (and (eq *tela-ui* :playing)
             (or (and (eq tipo :key-down) (sdl2:scancode= (first dados) :scancode-c))
                 (and (eq tipo :controller-down) (= (first dados) 3))))
    (alternar-modo-circuito mundo)
    (return-from entrada t))
  (when (and (eq *tela-ui* :playing) *modo-circuito*)
    (when (entrada-circuito mundo tipo dados) (return-from entrada t)))
  (if (eq *tela-ui* :technology)
      (entrada-arvore-tecnologica mundo tipo dados)
      (if (not (eq *tela-ui* :playing))
      (case tipo
        (:key-down (entrada-menu-teclado mundo (first dados)))
        (:mouse-down (apply #'entrada-menu-mouse mundo dados))
        (:controller-down
         (case (first dados) (0 (acionar-indice-menu mundo)) (1 (voltar-menu mundo))
               (11 (setf *indice-menu* (mod (1- *indice-menu*) (quantidade-opcoes-menu))))
               (12 (setf *indice-menu* (mod (1+ *indice-menu*) (quantidade-opcoes-menu))))) t)
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

(defun entrada-circuito (mundo tipo dados)
  (flet ((trocar-cor () (setf *cor-fio-circuito* (if (eq *cor-fio-circuito* :red) :green :red)))
         (cancelar () (if *origem-fio-circuito* (setf *origem-fio-circuito* nil)
                          (alternar-modo-circuito mundo))))
    (case tipo
      (:key-down
       (cond ((sdl2:scancode= (first dados) :scancode-x) (trocar-cor) t)
             ((sdl2:scancode= (first dados) :scancode-tab)
              (setf *pagina-dispositivo-circuito* (- 1 *pagina-dispositivo-circuito*)
                    *campo-circuito-gamepad* 0) t)
             ((sdl2:scancode= (first dados) :scancode-escape) (cancelar) t)))
      (:mouse-down
       (destructuring-bind (botao x y) dados
         (if (>= x (- (screen-width) 350))
             (when (= botao 1)
               (if (< y 175)
                   (setf (dado mundo :colorblind-circuits)
                         (not (dado mundo :colorblind-circuits)))
                   (editar-configuracao-circuito mundo x y)))
             (when (and (> y 88) (< y (- (screen-height) 100)))
               (case botao
                 (1 (selecionar-porta-circuito mundo x y))
                 (3 (remover-fio-circuito-em mundo x y)))))) t)
      (:mouse-up
       (destructuring-bind (botao x y) dados
         (when (and (= botao 1) (< x (- (screen-width) 350))
                    (> y 88) (< y (- (screen-height) 100)))
           (selecionar-porta-circuito mundo x y :somente-destino t))) t)
      (:mouse-move t)
      (:controller-down
       (case (first dados)
         (0 (if (>= *cursor-gamepad-x* (- (screen-width) 350))
                (editar-configuracao-circuito mundo (- (screen-width) 50)
                                               (+ 240 (* 42 *campo-circuito-gamepad*)))
                (selecionar-porta-circuito mundo *cursor-gamepad-x* *cursor-gamepad-y*)))
         (1 (cancelar)) (2 (trocar-cor))
         ((9 10) (setf *pagina-dispositivo-circuito* (- 1 *pagina-dispositivo-circuito*)
                       *campo-circuito-gamepad* 0))
         (11 (editar-configuracao-circuito mundo (- (screen-width) 300)
                                            (+ 240 (* 42 *campo-circuito-gamepad*))))
         (12 (editar-configuracao-circuito mundo (- (screen-width) 50)
                                            (+ 240 (* 42 *campo-circuito-gamepad*))))
         (13 (if (>= *cursor-gamepad-x* (- (screen-width) 350))
                 (setf *campo-circuito-gamepad* (mod (1+ *campo-circuito-gamepad*) 5))
                 (remover-fio-circuito-em mundo *cursor-gamepad-x* *cursor-gamepad-y*)))
         (14 (setf (dado mundo :colorblind-circuits)
                   (not (dado mundo :colorblind-circuits))))) t))))

(defun iniciar-mundo (mundo)
  (declare (ignore mundo))
  (set-clear-color 5 8 15) (set-camera 0 0 1.0)
  (register-sprite-sheet :circuits-v3
                         (merge-pathnames "assets/sprites/circuits-v3.png" *raiz*) 4 4)
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
  (register-sprite-sheet :environment-props-v2
                         (merge-pathnames "assets/sprites/environment-props-v2.png" *raiz*) 4 4)
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
  (register-sound :alarm-warning (merge-pathnames "assets/audio/alarm-warning.wav" *raiz*) :bus :alerts)
  (register-sound :alarm-critical (merge-pathnames "assets/audio/alarm-critical.wav" *raiz*) :bus :alerts)
  (set-audio-volume *volume-configurado*)
  (setf *indice-menu* 0
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
  (set-language language) (preparar :safe-mode safe-mode)
  (carregar-configuracoes)
  (run-game (configurar) :world (new-game :seed seed :difficulty difficulty)))

(defun headless-demo (&key (ticks 1800) (seed 1701))
  (preparar :safe-mode t)
  (let ((mundo (new-game :seed seed)))
    (place-building mundo :miner -4 -4)
    (place-building mundo :miner 4 -4)
    (place-building mundo :stone-furnace -3 -4 :recipe :smelt-iron)
    (run-game (configurar) :world mundo :headless t :ticks ticks)))

(defun run-smoke (&key render (capture-path #P"circuit-smoke.ppm"))
  "Exercita uma conexão real sem carregar mods ou escrever nos saves do jogador."
  (preparar :safe-mode t)
  (let* ((mundo (new-game :difficulty :peaceful))
         (sensor (place-building mundo :circuit-sensor -6 -1))
         (combinador (place-building mundo :arithmetic-combinator -3 -1))
         (lampada (place-building mundo :signal-lamp 0 -1))
         (quadros 0))
    (inventory-add (building-inventory sensor) :iron-plate 100)
    (configure-circuit-device combinador
      (make-circuit-device-config :behavior :arithmetic
        :input-signal '(:item :iron-plate) :operator :/ :constant 10
        :output-signal '(:virtual :signal-check)))
    (connect-circuit mundo sensor combinador :port-b :input)
    (connect-circuit mundo combinador lampada :port-a :output)
    ;; Inclui fauna em movimento e os demais sistemas na comparação nativa.
    (dotimes (i 120) (simulate-tick mundo))
    (assert (getf (building-state lampada) :lamp-active))
    (when (uiop:getenv "ASTERION_SMOKE_SNAPSHOT")
      (save-game mundo "circuit-smoke.save"))
    (let ((arquivo (merge-pathnames (format nil "asterion-smoke-~A.save" (gensym))
                                    (uiop:temporary-directory))))
      (unwind-protect
           (progn (save-game mundo arquivo)
                  (assert (= (simulation-state-hash mundo)
                             (simulation-state-hash (load-game arquivo)))))
        (when (probe-file arquivo) (delete-file arquivo))))
    (when render
      (setf *pular-menu-principal* t *modo-circuito* t
            *predio-circuito-selecionado* combinador *origem-fio-circuito* nil)
      (run-game
       (define-game :title "Asterion Assembly - circuit smoke"
         :start #'iniciar-mundo :update #'atualizar :input #'entrada
         :render (lambda (w alpha)
                   (renderizar w alpha)
                   (when (= (incf quadros) 12)
                     (capture-renderer capture-path) (stop-game))))
       :world mundo))
    (format t "~&CIRCUIT SMOKE OK: ~D wires, state ~X~%"
            (length (circuit-connections mundo)) (simulation-state-hash mundo))
    t))
