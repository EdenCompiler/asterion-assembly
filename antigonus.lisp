;;;; Antigonus 3.0.0 — engine 2D para jogos de automação.
;;;; O núcleo inteiro da engine vive neste arquivo. A API pública é em inglês;
;;;; implementação, comentários e diagnósticos são mantidos em português.

(eval-when (:compile-toplevel :load-toplevel :execute)
  ;; Durante desenvolvimento aceitamos Quicklisp. O executável de distribuição
  ;; carrega as dependências antes de salvar a imagem e não precisa de Quicklisp.
  (unless (find-package :sdl2)
    (let ((carregador (and (find-package :ql)
                           (find-symbol "QUICKLOAD" :ql))))
      (when carregador (funcall carregador '(:sdl2 :sdl2-image :sdl2-mixer) :silent t)))))

(defpackage #:antigonus
  (:use #:cl)
  (:export
   #:+engine-version+ #:+save-version+ #:+chunk-size+ #:game-config #:world #:entity-id
   #:item-definition #:recipe-definition #:building-definition
   #:technology-definition #:mod-manifest #:building #:entity #:train
   #:chunk #:belt-lane #:belt-network #:fluid-network #:power-network
   #:circuit-port #:circuit-wire #:circuit-condition #:circuit-device-config
   #:circuit-network #:rail-node #:rail-edge #:rail-graph #:train-schedule
   #:train-schedule-stop #:blueprint-definition #:blueprint-entry
   #:simulation-command
   #:define-game #:defgame #:run-game #:stop-game #:replace-world #:make-world #:with-world
   #:world-seed #:world-tick
   #:world-building-count
   #:world-pollution #:world-research #:world-campaign #:world-difficulty
   #:world-game-data #:world-chunks #:world-belt-networks #:world-fluid-networks
   #:world-power-networks #:world-circuit-networks #:world-circuit-wires
   #:world-circuit-graph-dirty #:world-rail-graph #:world-worker-count
   #:world-blueprints #:world-ghosts #:reset-engine #:define-system #:defsystem
   #:remove-system #:run-deterministic-jobs #:enqueue-simulation-command
   #:simulation-state-hash
   #:spawn-entity #:remove-entity #:map-entities #:entity-kind #:entity-x
   #:entity-y #:entity-hp #:entity-data #:place-building #:remove-building
   #:building-at #:map-buildings #:building-id #:building-kind #:building-x
   #:building-y #:building-rotation #:building-inventory #:building-state
   #:building-recipe #:building-progress #:building-enabled #:building-hp
   #:inventory-count #:inventory-add #:inventory-remove #:inventory-has-p
   #:with-inventory-transaction #:register-item #:defitem #:find-item #:map-items
   #:register-recipe #:defrecipe #:find-recipe #:map-recipes
   #:register-building #:defbuilding #:find-building #:map-building-definitions
   #:register-technology #:deftechnology #:find-technology #:map-technologies
   #:item-definition-id #:item-definition-name #:item-definition-stack-size
   #:item-definition-color #:item-definition-description
   #:item-definition-material-kind #:item-definition-density
   #:recipe-definition-id #:recipe-definition-inputs #:recipe-definition-outputs
   #:recipe-definition-duration #:recipe-definition-category
   #:recipe-definition-fluid-inputs #:recipe-definition-fluid-outputs
   #:recipe-definition-catalysts #:recipe-definition-byproducts
   #:building-definition-id
   #:building-definition-name #:building-definition-category
   #:building-definition-cost #:building-definition-power
   #:building-definition-color #:building-definition-size
   #:building-definition-footprint #:building-definition-ports
   #:building-definition-render-layers #:building-definition-circuit-connectors
   #:building-definition-circuit-ports #:building-definition-circuit-behavior
   #:building-definition-tags
   #:technology-definition-id #:technology-definition-cost
   #:technology-definition-name #:technology-definition-unlocks
   #:technology-definition-prerequisites #:technology-definition-branch
   #:simulate-tick #:on-event #:emit-event
   #:save-game #:load-game #:autosave-game #:discover-mods #:load-mods
   #:mod-fingerprint #:mod-errors #:loaded-mods #:mod-manifest-id #:mod-manifest-version
   #:mod-manifest-name #:mod-manifest-dependencies #:mod-manifest-enabled
   #:set-language #:translate #:register-translations #:deftranslations #:current-language
   #:draw-rect #:draw-line #:draw-text #:draw-circle #:screen-width
   #:sprite-sheet #:animation-definition #:register-sprite-sheet #:draw-sprite
   #:register-animation #:defanimation #:find-animation #:animation-frame
   #:draw-animation #:engine-time #:unload-sprites
   #:screen-height #:set-clear-color #:set-camera #:camera-position
   #:register-sound #:play-sound #:set-audio-volume #:set-audio-bus-volume #:audio-bus-volume
   #:set-display-mode
   #:screen-to-world #:world-to-screen #:mouse-position #:input-down-p
   #:set-time-scale #:time-scale #:paused-p #:toggle-pause #:engine-log
   #:profile-snapshot #:resource-noise #:find-path #:rail-route
   #:chunk-x #:chunk-y #:chunk-tiles #:chunk-resources #:chunk-building-ids
   #:ensure-chunk #:find-chunk #:map-chunks #:world-tile #:set-world-tile
   #:chunk-resource-count #:set-chunk-resource-count #:deplete-resource
   #:belt-lane-count #:belt-lane-capacity #:belt-lane-items
   #:belt-lane-positions #:belt-lane-stacks #:make-belt-lane
   #:belt-lane-insert #:belt-lane-remove-front #:advance-belt-lane
   #:make-fluid-network #:make-power-network #:make-circuit-network
   #:make-circuit-port #:make-circuit-wire #:make-circuit-condition
   #:make-circuit-device-config
   #:ensure-fluid-network #:ensure-power-network #:ensure-circuit-network
   #:simulate-fluid-network #:allocate-power-network
   #:fluid-network-id #:fluid-network-fluid #:fluid-network-volume
   #:fluid-network-capacity #:fluid-network-pressure #:fluid-network-nodes
   #:power-network-id #:power-network-generation #:power-network-demand
   #:power-network-stored #:power-network-capacity #:power-network-nodes
   #:power-network-satisfaction #:circuit-network-id #:circuit-network-signals
   #:circuit-network-next-signals #:circuit-network-color
   #:circuit-network-nodes #:circuit-network-wires #:circuit-network-revision
   #:circuit-write #:circuit-read #:clear-circuit-network
   #:circuit-port-building-id #:circuit-port-id #:circuit-port-directions
   #:circuit-wire-id #:circuit-wire-color #:circuit-wire-a-building
   #:circuit-wire-a-port #:circuit-wire-b-building #:circuit-wire-b-port
   #:circuit-condition-left #:circuit-condition-comparator
   #:circuit-condition-right #:circuit-condition-constant
   #:circuit-device-config-behavior #:circuit-device-config-input-signal
   #:circuit-device-config-output-signal #:circuit-device-config-operator
   #:circuit-device-config-constant #:circuit-device-config-condition
   #:circuit-device-config-copy-count
   #:circuit-device-config-pump-direction #:circuit-device-config-output-priority
   #:circuit-device-config-lamp-color #:circuit-device-config-lamp-intensity
   #:circuit-device-config-alarm-sound #:circuit-device-config-alarm-message
   #:connect-circuit #:disconnect-circuit #:circuit-connections
   #:configure-circuit-device #:read-circuit-signal
   #:rebuild-circuit-networks #:circuit-network-for-port
   #:rail-node-id #:rail-node-x #:rail-node-y #:rail-edge-id
   #:rail-edge-from #:rail-edge-to #:rail-edge-length #:rail-edge-block
   #:rail-edge-one-way #:rail-graph-nodes #:rail-graph-edges
   #:rail-graph-block-reservations #:add-rail-node #:add-rail-edge
   #:reserve-rail-block #:release-rail-blocks #:rail-deadlocks
   #:train-schedule-stops #:train-schedule-index #:train-schedule-mode
   #:train-schedule-stop-station #:train-schedule-stop-condition
   #:train-schedule-stop-value #:set-train-schedule
   #:blueprint-definition-id #:blueprint-definition-name
   #:blueprint-definition-entries #:blueprint-entry-kind #:blueprint-entry-x
   #:blueprint-entry-y #:blueprint-entry-rotation #:blueprint-entry-settings
   #:capture-blueprint #:apply-blueprint #:capture-renderer
   #:game-config-title #:game-config-width #:game-config-height
   #:game-config-start #:game-config-update #:game-config-render
   #:game-config-input #:game-config-shutdown))

(defpackage #:antigonus-interno
  (:use #:cl #:antigonus))

(in-package #:antigonus)

(defparameter +engine-version+ "3.0.0")
(defconstant +save-version+ 3)
(defconstant +chunk-size+ 32)
(deftype entity-id () '(integer 1 *))

(defstruct item-definition id name (stack-size 100) color description
           (material-kind :solid) (density 1.0))
(defstruct recipe-definition id (inputs nil) (outputs nil) (duration 30) category
           (fluid-inputs nil) (fluid-outputs nil) (catalysts nil) (byproducts nil))
(defstruct building-definition id name category (cost nil) (power 0) color
           (size 1) recipe-category description (footprint '(1 . 1)) (ports nil)
           (render-layers nil) (circuit-connectors nil) (circuit-ports nil)
           circuit-behavior (tags nil))
(defstruct technology-definition id name (cost nil) (unlocks nil) prerequisites
           description (branch :main))
(defstruct mod-manifest id name version engine-version dependencies conflicts
           path (enabled t) scripts content)
(defstruct (entity (:constructor %make-entity)) id kind x y (vx 0.0) (vy 0.0)
           (hp 100) data)
(defstruct (building (:constructor %make-building)) id kind x y (rotation 0)
           (inventory (make-hash-table :test #'equal)) recipe (progress 0)
           (enabled t) (hp 100) state)
(defstruct (train (:constructor %make-train)) id route (route-index 0)
           (progress 0.0) (speed 0.08) (cargo (make-hash-table :test #'equal))
           (status :moving) schedule (reserved-blocks nil) (manual-p nil)
           (fluid-cargo (make-hash-table :test #'equal)))
(defstruct (chunk (:constructor %make-chunk)) x y
           (tiles (make-array (* +chunk-size+ +chunk-size+)
                              :element-type '(unsigned-byte 16) :initial-element 0))
           (resources (make-hash-table :test #'equal))
           (building-ids (make-array 0 :element-type 'fixnum
                                       :adjustable t :fill-pointer 0))
           (revision 0) (active-p t))
(defstruct (belt-lane (:constructor make-belt-lane
                           (&key (capacity 8)
                                 &aux
                                 (items (make-array capacity :initial-element nil))
                                 (positions (make-array capacity
                                                        :element-type '(unsigned-byte 16)
                                                        :initial-element 0))
                                 (stacks (make-array capacity
                                                     :element-type '(unsigned-byte 16)
                                                     :initial-element 0)))))
  (capacity 8 :type fixnum) (count 0 :type fixnum) items positions stacks)
(defstruct belt-network id (cells nil) (throughput 0) (blocked 0))
(defstruct fluid-network id fluid (volume 0.0) (capacity 0.0) (pressure 0.0)
           (nodes nil) (revision 0))
(defstruct power-network id (generation 0.0) (demand 0.0) (stored 0.0)
           (capacity 0.0) (nodes nil) (satisfaction 1.0) (revision 0))
(defstruct circuit-port building-id (id :main) (directions '(:input :output)))
(defstruct circuit-wire id (color :red) a-building (a-port :main)
           b-building (b-port :main))
(defstruct circuit-condition (left '(:virtual :signal-a)) (comparator :>)
           right (constant 0))
(defstruct circuit-device-config (behavior :sensor)
           (input-signal '(:virtual :signal-a))
           (output-signal '(:virtual :signal-a)) (operator :+) (constant 0)
           condition (copy-count nil) (pump-direction :forward)
           (output-priority :balanced) (lamp-color :amber) (lamp-intensity 100)
           (alarm-sound :warning) (alarm-message :circuit-alert))
(defstruct circuit-network id (color :red)
           (signals (make-hash-table :test #'equal))
           (next-signals (make-hash-table :test #'equal))
           (nodes nil) (wires nil) (revision 0))
(defstruct rail-node id x y (connections nil) station)
(defstruct rail-edge id from to (length 1.0) (block 0) (one-way nil)
           (geometry :straight) (speed-limit 1.0))
(defstruct (rail-graph (:constructor make-rail-graph
                           (&aux (nodes (make-hash-table))
                                 (edges (make-hash-table))
                                 (block-reservations (make-hash-table)))))
  nodes edges block-reservations (next-node-id 1) (next-edge-id 1))
(defstruct train-schedule-stop station (condition :full) value (wait-ticks 0))
(defstruct train-schedule (stops nil) (index 0) (mode :automatic))
(defstruct blueprint-entry kind x y (rotation 0) settings)
(defstruct blueprint-definition id name (entries nil))
(defstruct simulation-command key function)
(defstruct system-definition name (priority 0) (phase :simulation) reads writes
           (parallel nil) function)
(defstruct (world (:constructor %make-world)) (seed 1) (tick 0)
           (buildings (make-hash-table)) (positions (make-hash-table :test #'equal))
           (entities (make-hash-table)) (trains nil) (next-id 1)
           (pollution 0.0) (research nil) (campaign nil) (difficulty :standard)
           (game-data (make-hash-table :test #'equal)) (events nil)
           (chunks (make-hash-table :test #'equal))
           (belt-networks (make-hash-table)) (fluid-networks (make-hash-table))
           (power-networks (make-hash-table)) (circuit-networks (make-hash-table))
           (circuit-wires (make-hash-table)) (next-circuit-wire-id 1)
           (circuit-graph-dirty t) (indice-portas-circuito (make-hash-table :test #'equal))
           (rail-graph (make-rail-graph))
           (blueprints (make-hash-table :test #'equal)) (ghosts nil)
           (worker-count 1))
(defstruct (game-config (:constructor %make-game-config)) title (width 1280)
           (height 720) start update render input shutdown)
(defstruct (sprite-sheet (:constructor %make-sprite-sheet)) id path columns rows
           pixel-width pixel-height texture)
(defstruct animation-definition id sheet (start 0) (frames 1) (fps 8.0)
           (loop t))

(defvar *itens* (make-hash-table :test #'equal))
(defvar *receitas* (make-hash-table :test #'equal))
(defvar *construcoes* (make-hash-table :test #'equal))
(defvar *tecnologias* (make-hash-table :test #'equal))
(defvar *sistemas* nil)
(defvar *eventos* (make-hash-table :test #'equal))
(defvar *traducoes* (make-hash-table :test #'equal))
(defvar *idioma* :en)
(defvar *mods-carregados* nil)
(defvar *erros-mods* nil)
(defun mod-errors () (copy-tree *erros-mods*))
(defun loaded-mods () (copy-list *mods-carregados*))
(defvar *mundo-atual* nil)
(defvar *configuracao-atual* nil)
(defvar *executando* nil)
(defvar *pausado* nil)
(defvar *escala-tempo* 1)
(defvar *entradas-ativas* (make-hash-table :test #'equal))
(defvar *mouse-x* 0)
(defvar *mouse-y* 0)
(defvar *camera-x* 0.0)
(defvar *camera-y* 0.0)
(defvar *camera-zoom* 1.0)
(defvar *largura-tela* 1280)
(defvar *altura-tela* 720)
(defvar *cor-limpeza* '(7 10 18 255))
(defvar *perfil* (make-hash-table :test #'equal))
(defvar *sons* (make-hash-table :test #'equal))
(defvar *audio-pronto* nil)
(defvar *volume-audio* 96)
(defvar *volumes-grupos-audio* (make-hash-table :test #'eq))
(defvar *grupos-canais-audio* (make-array 16 :initial-element :effects))
(defvar *janela-atual* nil)
(defvar *modo-video* nil)
(defvar *folhas-sprites* (make-hash-table :test #'equal))
(defvar *animacoes* (make-hash-table :test #'equal))
(defvar *tempo-visual* 0.0)

(defun define-game (&key (title "Antigonus Game") (width 1280) (height 720)
                         start update render input shutdown)
  "Cria a configuração executável de um jogo Antigonus."
  (%make-game-config :title title :width width :height height :start start
                     :update update :render render :input input :shutdown shutdown))

;;; DSL macro-dirigida. As funções REGISTER-*/DEFINE-* continuam disponíveis
;;; para conteúdo carregado dinamicamente por mods.
(defmacro defgame (name &rest options)
  "Declara uma configuração de jogo como dado global."
  `(defparameter ,name (define-game ,@options)))

(defmacro with-world ((name &rest options) &body body)
  "Cria um mundo léxico e executa BODY sobre ele."
  `(let ((,name (make-world ,@options))) ,@body))

(defmacro defitem (id &rest options)
  "Declara ou substitui um item no registro atual."
  `(register-item ,id ,@options))

(defmacro defrecipe (id &rest options)
  "Declara uma receita pela DSL da Antigonus."
  `(register-recipe ,id ,@options))

(defmacro defbuilding (id &rest options)
  "Declara uma construção pela DSL da Antigonus."
  `(register-building ,id ,@options))

(defmacro deftechnology (id &rest options)
  "Declara uma tecnologia pela DSL da Antigonus."
  `(register-technology ,id ,@options))

(defmacro defsystem (name options lambda-list &body body)
  "Declara e registra um sistema. Ex.: (DEFSYSTEM :MOVE (:PRIORITY 10) (WORLD) ...)."
  (let ((prioridade (or (getf options :priority) 0))
        (fase (or (getf options :phase) :simulation))
        (leituras (getf options :reads))
        (escritas (getf options :writes))
        (paralelo (getf options :parallel)))
    `(define-system ,name (lambda ,lambda-list ,@body)
       :priority ,prioridade :phase ,fase :reads ',leituras :writes ',escritas
       :parallel ,paralelo)))

(defmacro deftranslations (language &body pairs)
  "Declara traduções; cada entrada tem a forma (KEY \"TEXT\")."
  `(register-translations ,language
     (list ,@(mapcar (lambda (par) `(cons ,(first par) ,(second par))) pairs))))

(defmacro defanimation (id &rest options)
  "Declara uma animação visual sobre uma faixa contígua de uma atlas."
  `(register-animation ,id ,@options))

(defun make-world (&key (seed 1) (difficulty :standard)
                         (worker-count 1))
  (%make-world :seed (max 1 (abs seed)) :difficulty difficulty
               :worker-count (max 1 worker-count)))

;;; Mundo dividido em chunks. As tabelas 1.x continuam sendo índices globais
;;; compatíveis; o chunk é a fonte de localidade para geração, render e jobs.
(defun coordenada-chunk (valor) (floor valor +chunk-size+))
(defun coordenada-local (valor) (mod valor +chunk-size+))

(defun find-chunk (mundo x y)
  "Encontra o chunk que contém a coordenada mundial X,Y sem criá-lo."
  (gethash (cons (coordenada-chunk x) (coordenada-chunk y))
           (world-chunks mundo)))

(defun ensure-chunk (mundo x y)
  "Encontra ou cria deterministicamente o chunk que contém X,Y."
  (let* ((cx (coordenada-chunk x)) (cy (coordenada-chunk y))
         (chave (cons cx cy)))
    (or (gethash chave (world-chunks mundo))
        (setf (gethash chave (world-chunks mundo)) (%make-chunk :x cx :y cy)))))

(defun map-chunks (funcao mundo &key active-only)
  "Percorre chunks em ordem estável, independentemente da hash-table."
  (let (chunks)
    (maphash (lambda (chave chunk) (declare (ignore chave)) (push chunk chunks))
             (world-chunks mundo))
    (dolist (chunk (sort chunks (lambda (a b)
                                  (or (< (chunk-y a) (chunk-y b))
                                      (and (= (chunk-y a) (chunk-y b))
                                           (< (chunk-x a) (chunk-x b)))))))
      (when (or (not active-only) (chunk-active-p chunk))
        (funcall funcao chunk)))))

(defun indice-tile-local (x y)
  (+ (coordenada-local x) (* (coordenada-local y) +chunk-size+)))

(defun world-tile (mundo x y)
  (let ((chunk (find-chunk mundo x y)))
    (if chunk (aref (chunk-tiles chunk) (indice-tile-local x y)) 0)))

(defun set-world-tile (mundo x y tile)
  (let ((chunk (ensure-chunk mundo x y)))
    (setf (aref (chunk-tiles chunk) (indice-tile-local x y)) tile)
    (incf (chunk-revision chunk)) tile))

(defun chunk-resource-count (mundo x y recurso)
  (let ((chunk (find-chunk mundo x y)))
    (if chunk
        (gethash (list (coordenada-local x) (coordenada-local y) recurso)
                 (chunk-resources chunk) 0)
        0)))

(defun set-chunk-resource-count (mundo x y recurso quantidade)
  (let* ((chunk (ensure-chunk mundo x y))
         (chave (list (coordenada-local x) (coordenada-local y) recurso)))
    (if (plusp quantidade)
        (setf (gethash chave (chunk-resources chunk)) quantidade)
        (remhash chave (chunk-resources chunk)))
    (incf (chunk-revision chunk)) (max 0 quantidade)))

(defun deplete-resource (mundo x y recurso &optional (quantidade 1))
  "Remove até QUANTIDADE da jazida e retorna o total realmente removido."
  (let* ((atual (chunk-resource-count mundo x y recurso))
         (removido (min atual (max 0 quantidade))))
    (when (plusp removido)
      (set-chunk-resource-count mundo x y recurso (- atual removido)))
    removido))

(defun world-building-count (world)
  "Retorna a quantidade de construções ativas do mundo."
  (hash-table-count (world-buildings world)))

(defun reset-engine ()
  "Limpa registros globais; útil para testes e recarga do jogo."
  (dolist (tabela (list *itens* *receitas* *construcoes* *tecnologias*
                        *eventos* *traducoes* *entradas-ativas* *perfil*
                        *animacoes*))
    (clrhash tabela))
  (setf *sistemas* nil *mods-carregados* nil *pausado* nil *escala-tempo* 1)
  t)

(defun register-sound (id path &key (bus :effects))
  "Registra o caminho de um WAV. O carregamento é preguiçoso após abrir o áudio."
  (unless (member bus '(:effects :alerts :ambient :music)) (error "Grupo de áudio inválido."))
  (setf (gethash id *sons*) (list :path (namestring path) :chunk nil :bus bus)) id)
(defun audio-bus-volume (bus)
  (gethash bus *volumes-grupos-audio* 128))
(defun volume-efetivo-canal (bus)
  (round (* *volume-audio* (audio-bus-volume bus)) 128))
(defun atualizar-volumes-canais ()
  (when *audio-pronto*
    (loop for bus across *grupos-canais-audio* for canal from 0
          do (sdl2-mixer:volume canal (volume-efetivo-canal bus)))))
(defun set-audio-bus-volume (bus volume)
  "Ajusta um grupo entre 0 e 128, multiplicado pelo volume mestre."
  (unless (and (member bus '(:effects :alerts :ambient :music)) (typep volume '(integer 0 128)))
    (error "Grupo ou volume de áudio inválido."))
  (setf (gethash bus *volumes-grupos-audio*) volume)
  (atualizar-volumes-canais) volume)
(defun set-audio-volume (volume)
  (setf *volume-audio* (max 0 (min 128 volume)))
  (atualizar-volumes-canais) *volume-audio*)
(defun play-sound (id &key (loops 0))
  (when *audio-pronto*
    (let ((som (gethash id *sons*)))
      (when som
        (handler-case
            (progn
              (unless (getf som :chunk)
                (setf (getf som :chunk) (sdl2-mixer:load-wav (getf som :path))))
              (let ((canal (loop for i below 16 when (zerop (sdl2-mixer:playing i)) return i)))
                (when canal
                  (setf (aref *grupos-canais-audio* canal) (getf som :bus :effects))
                  (sdl2-mixer:volume canal (volume-efetivo-canal (aref *grupos-canais-audio* canal)))
                  (sdl2-mixer:play-channel canal (getf som :chunk) loops))))
          (error (e) (engine-log :warning "Som ~A indisponível: ~A" id e)))))))

(defun register-sprite-sheet (id path columns rows)
  "Declara uma atlas. A textura é criada no primeiro DRAW-SPRITE."
  (setf (gethash id *folhas-sprites*)
        (%make-sprite-sheet :id id :path (namestring path) :columns columns :rows rows))
  id)

(defun register-animation (id &key sheet (start 0) (frames 1) (fps 8.0) (loop t))
  "Registra uma animação. Os frames devem ocupar células contíguas da atlas."
  (check-type frames (integer 1 *))
  (setf (gethash id *animacoes*)
        (make-animation-definition :id id :sheet sheet :start start :frames frames
                                   :fps (max 0.01 fps) :loop loop))
  id)

(defun find-animation (id) (gethash id *animacoes*))

(defun engine-time () *tempo-visual*)

(defun animation-frame (animation &optional (time *tempo-visual*))
  "Retorna o índice absoluto da atlas no instante TIME, em segundos."
  (let* ((def (etypecase animation
                (animation-definition animation)
                (symbol (or (find-animation animation)
                            (error "Animação desconhecida: ~A" animation)))))
         (passo (max 0 (floor (* (max 0.0 time) (animation-definition-fps def)))))
         (local (if (animation-definition-loop def)
                    (mod passo (animation-definition-frames def))
                    (min passo (1- (animation-definition-frames def))))))
    (+ (animation-definition-start def) local)))

(defun unload-sprites ()
  (maphash (lambda (id folha) (declare (ignore id))
             (when (sprite-sheet-texture folha)
               (sdl2:destroy-texture (sprite-sheet-texture folha))
               (setf (sprite-sheet-texture folha) nil)))
           *folhas-sprites*) t)

(defun register-item (id &key name (stack-size 100) color description
                               (material-kind :solid) (density 1.0))
  (setf (gethash id *itens*)
        (make-item-definition :id id :name (or name (string id))
                              :stack-size stack-size :color color :description description
                              :material-kind material-kind :density density)))
(defun find-item (id) (gethash id *itens*))
(defun map-items (funcao) (maphash (lambda (k v) (declare (ignore k)) (funcall funcao v)) *itens*))

(defun register-recipe (id &key inputs outputs (duration 30) category
                                 fluid-inputs fluid-outputs catalysts byproducts)
  (setf (gethash id *receitas*)
        (make-recipe-definition :id id :inputs inputs :outputs outputs
                                :duration duration :category category
                                :fluid-inputs fluid-inputs :fluid-outputs fluid-outputs
                                :catalysts catalysts :byproducts byproducts)))
(defun find-recipe (id) (gethash id *receitas*))
(defun map-recipes (funcao) (maphash (lambda (k v) (declare (ignore k)) (funcall funcao v)) *receitas*))

(defun register-building (id &key name category cost (power 0) color (size 1)
                                  recipe-category description footprint ports
                                  render-layers circuit-connectors circuit-ports
                                  circuit-behavior tags)
  (setf (gethash id *construcoes*)
        (make-building-definition :id id :name (or name (string id)) :category category
                                  :cost cost :power power :color color :size size
                                  :recipe-category recipe-category :description description
                                  :footprint (or footprint (cons size size)) :ports ports
                                  :render-layers render-layers
                                  :circuit-connectors circuit-connectors
                                  :circuit-ports circuit-ports
                                  :circuit-behavior circuit-behavior :tags tags)))
(defun find-building (id) (gethash id *construcoes*))
(defun map-building-definitions (funcao)
  (maphash (lambda (k v) (declare (ignore k)) (funcall funcao v)) *construcoes*))

(defun register-technology (id &key name cost unlocks prerequisites description
                                     (branch :main))
  (setf (gethash id *tecnologias*)
        (make-technology-definition :id id :name (or name (string id)) :cost cost
                                    :unlocks unlocks :prerequisites prerequisites
                                    :description description :branch branch)))
(defun find-technology (id) (gethash id *tecnologias*))
(defun map-technologies (funcao)
  (maphash (lambda (k v) (declare (ignore k)) (funcall funcao v)) *tecnologias*))

(defun inventory-count (inventario item) (gethash item inventario 0))
(defun inventory-add (inventario item quantidade)
  (setf (gethash item inventario) (+ (inventory-count inventario item) quantidade)))
(defun inventory-has-p (inventario custos)
  (every (lambda (par) (>= (inventory-count inventario (car par)) (cdr par))) custos))
(defun inventory-remove (inventario item quantidade)
  (when (>= (inventory-count inventario item) quantidade)
    (decf (gethash item inventario) quantidade)
    (when (zerop (gethash item inventario)) (remhash item inventario))
    t))

(defmacro with-inventory-transaction ((inventory) &body body)
  "Executa BODY atomicamente no inventário; NIL ou erro restaura o estado anterior."
  (let ((inv (gensym "INVENTARIO-")) (copia (gensym "COPIA-"))
        (ok (gensym "SUCESSO-")))
    `(let* ((,inv ,inventory) (,copia (tabela-para-lista ,inv)) (,ok nil))
       (unwind-protect (setf ,ok (progn ,@body))
         (unless ,ok
           (clrhash ,inv)
           (dolist (par ,copia) (setf (gethash (car par) ,inv) (cdr par)))))
       ,ok)))

;;; Logística compacta: cada pista guarda símbolos e posições fixas 0..65535
;;; em vetores paralelos. Não há consing por tick durante o avanço.
(defun belt-lane-insert (pista item &key (position 0) (stack 1) (min-gap 4096))
  "Insere ITEM se houver capacidade e espaço físico no início da pista."
  (let ((quantidade (belt-lane-count pista)))
    (when (and (< quantidade (belt-lane-capacity pista))
               (loop for i below quantidade
                     always (>= (abs (- (aref (belt-lane-positions pista) i)
                                        position))
                                min-gap)))
      (setf (aref (belt-lane-items pista) quantidade) item
            (aref (belt-lane-positions pista) quantidade)
            (max 0 (min 65535 position))
            (aref (belt-lane-stacks pista) quantidade)
            (max 1 (min 65535 stack)))
      (incf (belt-lane-count pista))
      ;; Mantém a frente (maior posição) no final, facilitando a remoção.
      (loop for i downfrom quantidade above 0
            while (< (aref (belt-lane-positions pista) i)
                     (aref (belt-lane-positions pista) (1- i))) do
        (rotatef (aref (belt-lane-items pista) i)
                 (aref (belt-lane-items pista) (1- i)))
        (rotatef (aref (belt-lane-positions pista) i)
                 (aref (belt-lane-positions pista) (1- i)))
        (rotatef (aref (belt-lane-stacks pista) i)
                 (aref (belt-lane-stacks pista) (1- i))))
      t)))

(defun belt-lane-remove-front (pista &key (threshold 65535))
  "Remove e retorna ITEM,STACK da frente quando ele atingiu THRESHOLD."
  (let ((indice (1- (belt-lane-count pista))))
    (when (and (>= indice 0)
               (>= (aref (belt-lane-positions pista) indice) threshold))
      (let ((item (aref (belt-lane-items pista) indice))
            (pilha (aref (belt-lane-stacks pista) indice)))
        (setf (aref (belt-lane-items pista) indice) nil
              (belt-lane-count pista) indice)
        (values item pilha t)))))

(defun advance-belt-lane (pista velocidade &key (min-gap 4096))
  "Avança posições sem ultrapassar o item à frente e retorna a pista."
  (loop for i downfrom (1- (belt-lane-count pista)) to 0
        for limite = (if (= i (1- (belt-lane-count pista)))
                         65535
                         (max 0 (- (aref (belt-lane-positions pista) (1+ i)) min-gap)))
        do (setf (aref (belt-lane-positions pista) i)
                 (min limite (+ (aref (belt-lane-positions pista) i)
                                (max 0 velocidade)))))
  pista)

;;; Redes de fluidos e energia deliberadamente usam modelos estáveis e
;;; discretos: profundidade operacional sem integrar dinâmica contínua cara.
(defun equilibrar-fluidos (redes)
  (dolist (rede redes)
    (setf (fluid-network-volume rede)
          (max 0.0 (min (fluid-network-capacity rede) (fluid-network-volume rede)))
          (fluid-network-pressure rede)
          (if (plusp (fluid-network-capacity rede))
              (/ (fluid-network-volume rede) (fluid-network-capacity rede)) 0.0))
    (incf (fluid-network-revision rede)))
  redes)

(defun ensure-fluid-network (mundo id &key fluid (capacity 0.0) nodes)
  (or (gethash id (world-fluid-networks mundo))
      (setf (gethash id (world-fluid-networks mundo))
            (make-fluid-network :id id :fluid fluid :capacity capacity :nodes nodes))))

(defun ensure-power-network (mundo id &key (capacity 0.0) nodes)
  (or (gethash id (world-power-networks mundo))
      (setf (gethash id (world-power-networks mundo))
            (make-power-network :id id :capacity capacity :nodes nodes))))

(defun ensure-circuit-network (mundo id &key nodes)
  (or (gethash id (world-circuit-networks mundo))
      (setf (gethash id (world-circuit-networks mundo))
            (make-circuit-network :id id :nodes nodes))))

(defun simulate-fluid-network (rede &key (inflow 0.0) (outflow 0.0))
  "Atualiza volume e pressão de uma única rede, conservando o fluido."
  (incf (fluid-network-volume rede) (- inflow outflow))
  (first (equilibrar-fluidos (list rede))))

(defun distribuir-energia (rede cargas)
  "Distribui energia por prioridade e ID. CARGAS: (ID PRIORIDADE DEMANDA CALLBACK)."
  (let* ((ordenadas (stable-sort (copy-list cargas)
                                 (lambda (a b)
                                   (or (> (second a) (second b))
                                       (and (= (second a) (second b))
                                            (< (first a) (first b)))))))
         (disponivel (+ (power-network-generation rede)
                        (power-network-stored rede)))
         (total (reduce #'+ ordenadas :key #'third :initial-value 0.0)))
    (setf (power-network-demand rede) total)
    (dolist (carga ordenadas)
      (let ((ligada (>= disponivel (third carga))))
        (when ligada (decf disponivel (third carga)))
        (funcall (fourth carga) ligada)))
    (setf (power-network-stored rede)
          (min (power-network-capacity rede) (max 0.0 disponivel))
          (power-network-satisfaction rede)
          (if (zerop total) 1.0 (min 1.0 (/ (+ (power-network-generation rede)
                                                (power-network-stored rede))
                                             total))))
    (incf (power-network-revision rede)) rede))

(defun allocate-power-network (rede loads)
  "API pública para distribuição determinística de energia."
  (distribuir-energia rede loads))

(defun sinal-circuito-valido-p (sinal)
  (and (consp sinal) (member (first sinal) '(:item :fluid :virtual))
       (consp (cdr sinal)) (null (cddr sinal))
       (or (keywordp (second sinal)) (stringp (second sinal)))))

(defun circuit-write (rede signal value &key (mode :set))
  (unless (and (sinal-circuito-valido-p signal) (integerp value))
    (error "Circuito requer sinal tipado e valor inteiro: ~S = ~S" signal value))
  (ecase mode
    (:set (setf (gethash signal (circuit-network-signals rede)) value))
    (:add (incf (gethash signal (circuit-network-signals rede) 0) value))
    (:max (setf (gethash signal (circuit-network-signals rede))
                (max value (gethash signal (circuit-network-signals rede)
                                    most-negative-fixnum)))))
  (incf (circuit-network-revision rede)) value)

(defun circuit-read (rede signal &optional (default 0))
  (gethash signal (circuit-network-signals rede) default))

(defun clear-circuit-network (rede)
  (clrhash (circuit-network-signals rede))
  (incf (circuit-network-revision rede)) rede)

;;; Grafos de circuitos 3.0. Redes vermelhas e verdes jamais se fundem.
(defun id-predio-circuito (predio-ou-id)
  (if (building-p predio-ou-id) (building-id predio-ou-id) predio-ou-id))

(defun chave-porta-circuito (predio porta)
  (list predio porta))

(defun texto-porta-circuito (porta)
  (format nil "~10,'0D/~A" (first porta) (second porta)))

(defun porta-circuito< (a b)
  (string< (texto-porta-circuito a) (texto-porta-circuito b)))

(defun hash-circuito-estavel (cor portas)
  "Produz ID FNV-1a estável entre plataformas a partir do componente ordenado."
  (let ((hash #xcbf29ce484222325)
        (texto (format nil "~A|~{~A~^|~}" cor
                       (mapcar #'texto-porta-circuito portas))))
    (loop for caractere across texto do
      (setf hash (logand #xffffffffffffffff
                         (* (logxor hash (char-code caractere)) #x100000001b3))))
    hash))

(defun portas-definidas-circuito (predio)
  (let* ((definicao (find-building (building-kind predio)))
         (portas (and definicao (building-definition-circuit-ports definicao))))
    (or portas (when (and definicao
                          (building-definition-circuit-connectors definicao))
                 '(:main)))))

(defun porta-circuito-valida-p (predio porta)
  (member porta (portas-definidas-circuito predio) :test #'equal))

(defun fio-equivalente-p (fio cor a porta-a b porta-b)
  (and (eq cor (circuit-wire-color fio))
       (or (and (= a (circuit-wire-a-building fio))
                (= b (circuit-wire-b-building fio))
                (equal porta-a (circuit-wire-a-port fio))
                (equal porta-b (circuit-wire-b-port fio)))
           (and (= b (circuit-wire-a-building fio))
                (= a (circuit-wire-b-building fio))
                (equal porta-b (circuit-wire-a-port fio))
                (equal porta-a (circuit-wire-b-port fio))))))

(defun connect-circuit (mundo predio-a predio-b
                        &key (port-a :main) (port-b :main) (color :red))
  "Conecta duas portas a até nove tiles; retorna fio e se a conexão foi criada."
  (unless (member color '(:red :green))
    (error "Cor de circuito inválida: ~A" color))
  (let* ((a-id (id-predio-circuito predio-a)) (b-id (id-predio-circuito predio-b))
         (a (gethash a-id (world-buildings mundo)))
         (b (gethash b-id (world-buildings mundo))))
    (unless (and a b) (error "Conexão referencia construção ausente."))
    (unless (and (porta-circuito-valida-p a port-a)
                 (porta-circuito-valida-p b port-b))
      (error "Porta de circuito inválida em ~A ou ~A." a-id b-id))
    (when (and (= a-id b-id) (equal port-a port-b))
      (error "Uma porta não pode conectar a si mesma."))
    (let ((distancia (sqrt (+ (expt (- (building-x a) (building-x b)) 2)
                              (expt (- (building-y a) (building-y b)) 2)))))
      (when (> distancia 9.0) (error "Conexão excede o alcance de nove tiles.")))
    (let ((existente nil))
      (maphash (lambda (id fio) (declare (ignore id))
                 (when (fio-equivalente-p fio color a-id port-a b-id port-b)
                   (setf existente fio)))
               (world-circuit-wires mundo))
      (if existente (values existente nil)
          (let* ((id (prog1 (world-next-circuit-wire-id mundo)
                       (incf (world-next-circuit-wire-id mundo))))
                 (fio (make-circuit-wire :id id :color color
                                         :a-building a-id :a-port port-a
                                         :b-building b-id :b-port port-b)))
            (setf (gethash id (world-circuit-wires mundo)) fio
                  (world-circuit-graph-dirty mundo) t)
            (values fio t))))))

(defun disconnect-circuit (mundo fio-ou-id)
  "Remove uma conexão e retorna o fio removido para o chamador reembolsar."
  (let* ((id (if (circuit-wire-p fio-ou-id) (circuit-wire-id fio-ou-id) fio-ou-id))
         (fio (gethash id (world-circuit-wires mundo))))
    (when fio
      (remhash id (world-circuit-wires mundo))
      (setf (world-circuit-graph-dirty mundo) t)
      fio)))

(defun circuit-connections (mundo &optional predio-ou-id color)
  "Lista conexões em ordem de ID, opcionalmente filtradas por prédio e cor."
  (let ((predio (and predio-ou-id (id-predio-circuito predio-ou-id))) resultado)
    (maphash (lambda (id fio) (declare (ignore id))
               (when (and (or (null predio)
                              (= predio (circuit-wire-a-building fio))
                              (= predio (circuit-wire-b-building fio)))
                          (or (null color) (eq color (circuit-wire-color fio))))
                 (push fio resultado)))
             (world-circuit-wires mundo))
    (sort resultado #'< :key #'circuit-wire-id)))

(defun configure-circuit-device (predio configuracao)
  "Associa uma configuração pública a uma construção compatível."
  (unless (circuit-device-config-p configuracao)
    (error "Configuração de circuito inválida: ~A" configuracao))
  (unless (and (portas-definidas-circuito predio)
               (integerp (circuit-device-config-constant configuracao))
               (member (circuit-device-config-operator configuracao) '(:+ :- :* :/ :mod :min :max)))
    (error "Dispositivo, operador ou constante de circuito inválidos."))
  (unless (and (member (circuit-device-config-pump-direction configuracao) '(:forward :reverse))
               (member (circuit-device-config-output-priority configuracao) '(:balanced :first :second))
               (member (circuit-device-config-lamp-color configuracao) '(:amber :blue :red :green))
               (typep (circuit-device-config-lamp-intensity configuracao) '(integer 0 100))
               (member (circuit-device-config-alarm-sound configuracao) '(:silent :warning :critical))
               (member (circuit-device-config-alarm-message configuracao)
                       '(:circuit-alert :low-stock :tank-full :power-low))
               (member (circuit-device-config-copy-count configuracao) '(nil t)))
    (error "Parâmetros de atuador inválidos."))
  (dolist (sinal (list (circuit-device-config-input-signal configuracao)
                       (circuit-device-config-output-signal configuracao)))
    (unless (or (null sinal) (sinal-circuito-valido-p sinal)
                (member sinal '(:each :anything :everything)))
      (error "Sinal de circuito inválido: ~S" sinal)))
  (let ((condicao (circuit-device-config-condition configuracao)))
    (when condicao
      (unless (and (circuit-condition-p condicao)
                   (integerp (circuit-condition-constant condicao))
                   (member (circuit-condition-comparator condicao) '(:< :<= := :!= :>= :>))
                   (or (sinal-circuito-valido-p (circuit-condition-left condicao))
                       (member (circuit-condition-left condicao) '(:each :anything :everything)))
                   (or (null (circuit-condition-right condicao))
                       (sinal-circuito-valido-p (circuit-condition-right condicao))))
        (error "Condição de circuito inválida."))))
  ;; Configurações copiadas por plantas/UI não compartilham estruturas mutáveis.
  (dolist (chave '(:circuit-true-tick :circuit-false-tick :filtered-output-0 :filtered-output-1))
    (remf (building-state predio) chave))
  (setf (getf (building-state predio) :circuit-config)
        (dados-para-valor (valor-para-dados configuracao))))

(defun read-circuit-signal (rede sinal &optional (padrao 0))
  (circuit-read rede sinal padrao))

(defun rebuild-circuit-networks (mundo)
  "Reconstrói componentes por cor somente quando o grafo foi alterado."
  (when (world-circuit-graph-dirty mundo)
    (let ((antigas (world-circuit-networks mundo))
          (novas (make-hash-table))
          (indice (make-hash-table :test #'equal))
          (fios (circuit-connections mundo)))
      (dolist (cor '(:red :green))
        (let ((adjacencias (make-hash-table :test #'equal))
              (fios-cor (remove-if-not (lambda (fio) (eq cor (circuit-wire-color fio))) fios)))
          (dolist (fio fios-cor)
            (let ((a (chave-porta-circuito (circuit-wire-a-building fio)
                                           (circuit-wire-a-port fio)))
                  (b (chave-porta-circuito (circuit-wire-b-building fio)
                                           (circuit-wire-b-port fio))))
              (pushnew b (gethash a adjacencias) :test #'equal)
              (pushnew a (gethash b adjacencias) :test #'equal)))
          (let (todas (visitadas (make-hash-table :test #'equal)))
            (maphash (lambda (porta vizinhos) (declare (ignore vizinhos)) (push porta todas))
                     adjacencias)
            (dolist (inicio (sort todas #'porta-circuito<))
              (unless (gethash inicio visitadas)
                (let ((fila (list inicio)) componente)
                  (loop while fila do
                    (let ((porta (pop fila)))
                      (unless (gethash porta visitadas)
                        (setf (gethash porta visitadas) t) (push porta componente)
                        (dolist (vizinho (gethash porta adjacencias))
                          (unless (gethash vizinho visitadas)
                            (push vizinho fila))))))
                  (setf componente (sort componente #'porta-circuito<))
                  (let* ((id (hash-circuito-estavel cor componente))
                         (anterior (gethash id antigas))
                         (rede (or anterior (make-circuit-network :id id :color cor))))
                    (setf (circuit-network-color rede) cor
                          (circuit-network-nodes rede) componente
                          (circuit-network-wires rede) nil)
                    (when (gethash id novas)
                      (error "Colisão de identificador de circuito: ~A" id))
                    (dolist (porta componente)
                      (setf (gethash (cons cor porta) indice) rede))
                    (setf (gethash id novas) rede))))))
          (dolist (fio fios-cor)
            (let ((rede (gethash (list cor (circuit-wire-a-building fio)
                                       (circuit-wire-a-port fio)) indice)))
              (push (circuit-wire-id fio) (circuit-network-wires rede))))))
      (setf (world-circuit-networks mundo) novas
            (world-indice-portas-circuito mundo) indice
            (world-circuit-graph-dirty mundo) nil)))
  (world-circuit-networks mundo))

(defun circuit-network-for-port (mundo predio-ou-id &optional (porta :main) color)
  (rebuild-circuit-networks mundo)
  (loop for cor in (if color (list color) '(:red :green))
        for rede = (gethash (list cor (id-predio-circuito predio-ou-id) porta)
                           (world-indice-portas-circuito mundo))
        when rede collect rede))

;;; Grafo ferroviário e reservas de blocos.
(defun add-rail-node (grafo x y &key station)
  (let ((id (prog1 (rail-graph-next-node-id grafo)
              (incf (rail-graph-next-node-id grafo)))))
    (setf (gethash id (rail-graph-nodes grafo))
          (make-rail-node :id id :x x :y y :station station))
    id))

(defun add-rail-edge (grafo from to &key (length 1.0) block one-way
                                           (geometry :straight) (speed-limit 1.0))
  (unless (and (gethash from (rail-graph-nodes grafo))
               (gethash to (rail-graph-nodes grafo)))
    (error "Nós ferroviários inexistentes: ~A -> ~A" from to))
  (let* ((id (prog1 (rail-graph-next-edge-id grafo)
               (incf (rail-graph-next-edge-id grafo))))
         (aresta (make-rail-edge :id id :from from :to to :length length
                                 :block (or block id) :one-way one-way
                                 :geometry geometry :speed-limit speed-limit)))
    (setf (gethash id (rail-graph-edges grafo)) aresta)
    (pushnew id (rail-node-connections (gethash from (rail-graph-nodes grafo))))
    (unless one-way
      (pushnew id (rail-node-connections (gethash to (rail-graph-nodes grafo)))))
    id))

(defun reserve-rail-block (grafo block train-id)
  "Reserva BLOCK para TRAIN-ID; a mesma composição pode renovar a reserva."
  (let ((dono (gethash block (rail-graph-block-reservations grafo))))
    (when (or (null dono) (eql dono train-id))
      (setf (gethash block (rail-graph-block-reservations grafo)) train-id)
      t)))

(defun release-rail-blocks (grafo train-id)
  (let (remover)
    (maphash (lambda (bloco dono) (when (eql dono train-id) (push bloco remover)))
             (rail-graph-block-reservations grafo))
    (dolist (bloco remover) (remhash bloco (rail-graph-block-reservations grafo)))
    (length remover)))

(defun rail-deadlocks (esperas)
  "Detecta ciclos num grafo TRAIN-ID -> TRAIN-ID e retorna os ciclos canônicos."
  (let ((visitados (make-hash-table)) (pilha nil) ciclos)
    (labels ((visitar (id)
               (case (gethash id visitados)
                 (:visiting
                  (let ((inicio (position id pilha)))
                    (when inicio (push (reverse (subseq pilha 0 (1+ inicio))) ciclos))))
                 (:done nil)
                 (otherwise
                  (setf (gethash id visitados) :visiting)
                  (push id pilha)
                  (let ((alvo (cdr (assoc id esperas))))
                    (when alvo (visitar alvo)))
                  (pop pilha)
                  (setf (gethash id visitados) :done)))))
      (dolist (par (sort (copy-list esperas) #'< :key #'car)) (visitar (car par))))
    (nreverse ciclos)))

(defun set-train-schedule (trem stops &key (mode :automatic))
  (setf (train-schedule trem)
        (make-train-schedule :stops stops :index 0 :mode mode)
        (train-manual-p trem) (eq mode :manual))
  trem)

;;; Plantas preservam apenas dados declarativos públicos.
(defun capture-blueprint (mundo x0 y0 x1 y1 &key id (name "Blueprint"))
  (let (entradas)
    (map-buildings
     (lambda (b)
       (when (and (<= (min x0 x1) (building-x b) (max x0 x1))
                  (<= (min y0 y1) (building-y b) (max y0 y1)))
         (push (make-blueprint-entry
                :kind (building-kind b) :x (- (building-x b) (min x0 x1))
                :y (- (building-y b) (min y0 y1)) :rotation (building-rotation b)
                :settings (list :recipe (building-recipe b))) entradas)))
     mundo)
    (let ((planta (make-blueprint-definition
                   :id (or id (intern (format nil "BLUEPRINT-~D" (1+ (hash-table-count
                                                                      (world-blueprints mundo))))
                                      :keyword))
                   :name name
                   :entries (sort entradas (lambda (a b)
                                             (or (< (blueprint-entry-y a)
                                                    (blueprint-entry-y b))
                                                 (and (= (blueprint-entry-y a)
                                                         (blueprint-entry-y b))
                                                      (< (blueprint-entry-x a)
                                                         (blueprint-entry-x b)))))))))
      (setf (gethash (blueprint-definition-id planta) (world-blueprints mundo)) planta)
      planta)))

(defun apply-blueprint (mundo planta origem-x origem-y &key (ghosts t))
  "Aplica PLANTA como fantasmas por padrão; NIL constrói imediatamente."
  (let (criados)
    (dolist (entrada (blueprint-definition-entries planta) (nreverse criados))
      (let ((x (+ origem-x (blueprint-entry-x entrada)))
            (y (+ origem-y (blueprint-entry-y entrada))))
        (if ghosts
            (let ((fantasma (list :kind (blueprint-entry-kind entrada) :x x :y y
                                  :rotation (blueprint-entry-rotation entrada)
                                  :settings (blueprint-entry-settings entrada))))
              (push fantasma (world-ghosts mundo)) (push fantasma criados))
            (let ((b (place-building mundo (blueprint-entry-kind entrada) x y
                                     :rotation (blueprint-entry-rotation entrada)
                                     :recipe (getf (blueprint-entry-settings entrada) :recipe))))
              (when b (push b criados))))))))

(defun place-building (mundo kind x y &key (rotation 0) recipe state)
  (when (and (find-building kind) (null (gethash (cons x y) (world-positions mundo))))
    (let* ((id (prog1 (world-next-id mundo) (incf (world-next-id mundo))))
           (predio (%make-building :id id :kind kind :x x :y y :rotation rotation
                                   :recipe recipe :state state
                                   :hp (or (getf state :hp) 100))))
      (setf (gethash id (world-buildings mundo)) predio
            (gethash (cons x y) (world-positions mundo)) id)
      (let ((chunk (ensure-chunk mundo x y)))
        (vector-push-extend id (chunk-building-ids chunk))
        (incf (chunk-revision chunk)))
      (emit-event :building-placed mundo predio)
      predio)))

(defun building-at (mundo x y)
  (let ((id (gethash (cons x y) (world-positions mundo))))
    (and id (gethash id (world-buildings mundo)))))

(defun remove-building (mundo predio-ou-id)
  (let ((predio (if (building-p predio-ou-id) predio-ou-id
                    (gethash predio-ou-id (world-buildings mundo)))))
    (when predio
      (dolist (fio (circuit-connections mundo predio))
        (disconnect-circuit mundo fio))
      (remhash (cons (building-x predio) (building-y predio)) (world-positions mundo))
      (remhash (building-id predio) (world-buildings mundo))
      (let ((chunk (find-chunk mundo (building-x predio) (building-y predio))))
        (when chunk
          (let ((indice (position (building-id predio) (chunk-building-ids chunk))))
            (when indice
              (replace (chunk-building-ids chunk) (chunk-building-ids chunk)
                       :start1 indice :start2 (1+ indice))
              (decf (fill-pointer (chunk-building-ids chunk)))))
          (incf (chunk-revision chunk))))
      (emit-event :building-removed mundo predio)
      predio)))

(defun map-buildings (funcao mundo)
  (maphash (lambda (k v) (declare (ignore k)) (funcall funcao v))
           (world-buildings mundo)))

(defun spawn-entity (mundo kind x y &key (hp 100) data)
  (let* ((id (prog1 (world-next-id mundo) (incf (world-next-id mundo))))
         (entidade (%make-entity :id id :kind kind :x x :y y :hp hp :data data)))
    (setf (gethash id (world-entities mundo)) entidade)
    (emit-event :entity-spawned mundo entidade)
    entidade))
(defun remove-entity (mundo entidade-ou-id)
  (let ((id (if (entity-p entidade-ou-id) (entity-id entidade-ou-id) entidade-ou-id)))
    (prog1 (gethash id (world-entities mundo)) (remhash id (world-entities mundo)))))
(defun map-entities (funcao mundo)
  (maphash (lambda (k v) (declare (ignore k)) (funcall funcao v))
           (world-entities mundo)))

(defun ordem-fase (fase)
  (or (position fase '(:input :pre-simulation :simulation :post-simulation
                        :presentation)) 2))

(defun ordenar-sistemas (a b)
  (let ((fa (ordem-fase (system-definition-phase a)))
        (fb (ordem-fase (system-definition-phase b))))
    (if (= fa fb)
        (if (= (system-definition-priority a) (system-definition-priority b))
            (string< (string (system-definition-name a))
                     (string (system-definition-name b)))
            (< (system-definition-priority a) (system-definition-priority b)))
        (< fa fb))))

(defun define-system (name function &key (priority 0) (phase :simulation)
                                      reads writes parallel)
  "Registra um sistema 2.0. Sistemas paralelos devem emitir comandos, não mutar o mundo."
  (setf *sistemas* (remove name *sistemas* :key #'system-definition-name :test #'equal))
  (push (make-system-definition :name name :priority priority :phase phase
                                :reads reads :writes writes :parallel parallel
                                :function function)
        *sistemas*)
  (setf *sistemas* (sort *sistemas* #'ordenar-sistemas))
  name)
(defun remove-system (name)
  (setf *sistemas* (remove name *sistemas* :key #'system-definition-name :test #'equal)))
(defun on-event (event function) (push function (gethash event *eventos*)) function)
(defun emit-event (event &rest args)
  (dolist (funcao (reverse (gethash event *eventos*))) (apply funcao args)))

(defun registrar-tempo (nome inicio)
  (setf (gethash nome *perfil*)
        (/ (- (get-internal-real-time) inicio) internal-time-units-per-second)))
(defun profile-snapshot ()
  (let (resultado) (maphash (lambda (k v) (push (cons k v) resultado)) *perfil*) resultado))

(defvar *buffer-comandos* nil)

(defun enqueue-simulation-command (key function)
  "Emite uma mutação ordenável a partir de um job paralelo."
  (push (make-simulation-command :key key :function function) *buffer-comandos*))

(defun run-deterministic-jobs (tarefas funcao &key (workers 1))
  "Executa tarefas possivelmente em paralelo e retorna resultados na ordem de entrada."
  (let* ((vetor (coerce tarefas 'vector))
         (quantidade (length vetor))
         (resultados (make-array quantidade))
         (proximo 0)
         (erro nil)
         #+sb-thread (trava (sb-thread:make-mutex :name "antigonus-jobs")))
    (labels ((obter-indice ()
               #+sb-thread
               (sb-thread:with-mutex (trava)
                 (when (< proximo quantidade) (prog1 proximo (incf proximo))))
               #-sb-thread
               (when (< proximo quantidade) (prog1 proximo (incf proximo))))
             (trabalhar ()
               (loop for indice = (obter-indice) while indice do
                 (handler-case
                     (setf (aref resultados indice)
                           (funcall funcao (aref vetor indice) indice))
                   (error (e)
                     #+sb-thread (sb-thread:with-mutex (trava) (unless erro (setf erro e)))
                     #-sb-thread (unless erro (setf erro e)))))))
      #+sb-thread
      (if (> workers 1)
          (let ((threads (loop repeat (min workers (max 1 quantidade))
                               collect (sb-thread:make-thread #'trabalhar
                                                              :name "antigonus-worker"))))
            (dolist (thread threads) (sb-thread:join-thread thread)))
          (trabalhar))
      #-sb-thread (trabalhar))
    (when erro (error erro))
    (coerce resultados 'list)))

(defun executar-sistemas-paralelos (sistemas mundo)
  (let ((buffers
          (run-deterministic-jobs
           sistemas
           (lambda (sistema indice)
             (declare (ignore indice))
             (let ((*buffer-comandos* nil))
               (funcall (system-definition-function sistema) mundo)
               (nreverse *buffer-comandos*)))
           :workers (world-worker-count mundo))))
    (let ((comandos (loop for buffer in buffers append buffer)))
      (dolist (comando (stable-sort comandos #'string<
                                    :key (lambda (c)
                                           (prin1-to-string (simulation-command-key c)))))
        (funcall (simulation-command-function comando))))))

(defun simulate-tick (mundo)
  "Avança exatamente um tick determinístico, aplicando jobs em ordem estável."
  (let ((inicio (get-internal-real-time)))
    (incf (world-tick mundo))
    (loop with restantes = *sistemas* while restantes do
      (let* ((fase (system-definition-phase (first restantes)))
             (grupo (loop while (and restantes
                                      (eq fase (system-definition-phase (first restantes))))
                          collect (pop restantes)))
             (paralelos (remove-if-not #'system-definition-parallel grupo)))
        (dolist (sistema (remove-if #'system-definition-parallel grupo))
          (funcall (system-definition-function sistema) mundo))
        (when paralelos (executar-sistemas-paralelos paralelos mundo))))
    (emit-event :tick mundo)
    (registrar-tempo :simulation inicio)
    mundo))

(defun set-language (language) (setf *idioma* language))
(defun current-language () *idioma*)
(defun register-translations (language pairs)
  (dolist (par pairs) (setf (gethash (cons language (car par)) *traducoes*) (cdr par))))
(defun translate (key &rest arguments)
  (let ((texto (or (gethash (cons *idioma* key) *traducoes*)
                   (gethash (cons :en key) *traducoes*) (string key))))
    (if arguments (apply #'format nil texto arguments) texto)))

(defun hash-coordenada (semente x y)
  (let ((n (logand #xffffffff (+ (* x 374761393) (* y 668265263) (* semente 1442695041)))))
    (setf n (logxor n (ash n -13)))
    (setf n (logand #xffffffff (* n 1274126177)))
    (logxor n (ash n -16))))
(defun resource-noise (mundo x y &optional (channel 0))
  (/ (logand #xffff (hash-coordenada (+ (world-seed mundo) channel) x y)) 65535.0))

(defun vizinhos-grade (ponto bloqueado-p)
  (destructuring-bind (x . y) ponto
    (remove-if bloqueado-p (list (cons (1+ x) y) (cons (1- x) y)
                                  (cons x (1+ y)) (cons x (1- y))))))
(defun find-path (start goal blocked-p &key (limit 20000))
  "A* em grade inteira. Retorna uma lista do início ao destino."
  (let ((abertos (list start)) (origem (make-hash-table :test #'equal))
        (g (make-hash-table :test #'equal)) (passos 0))
    (setf (gethash start g) 0)
    (labels ((h (p) (+ (abs (- (car p) (car goal))) (abs (- (cdr p) (cdr goal)))))
             (caminho (p) (let ((r (list p)))
                            (loop while (gethash p origem) do
                              (setf p (gethash p origem)) (push p r)) r)))
      (loop while (and abertos (< passos limit)) do
        (incf passos)
        (setf abertos (sort abertos #'< :key (lambda (p) (+ (gethash p g) (h p)))))
        (let ((atual (pop abertos)))
          (when (equal atual goal) (return-from find-path (caminho atual)))
          (dolist (proximo (vizinhos-grade atual blocked-p))
            (let ((tentativa (1+ (gethash atual g))))
              (when (< tentativa (gethash proximo g most-positive-fixnum))
                (setf (gethash proximo origem) atual (gethash proximo g) tentativa)
                (pushnew proximo abertos :test #'equal)))))))
    nil))

(defun rail-route (mundo start goal)
  (find-path start goal (lambda (p)
                          (unless (or (equal p start) (equal p goal))
                            (let ((b (building-at mundo (car p) (cdr p))))
                              (not (and b (member (building-kind b)
                                                  '(:rail :rail-signal :station)))))))))

;;; Persistência: somente dados simples entram no arquivo; nenhuma forma é avaliada.
(defun valor-para-dados (valor)
  (cond
    ((circuit-condition-p valor)
     (list :antigonus-circuit-condition
           :left (circuit-condition-left valor)
           :comparator (circuit-condition-comparator valor)
           :right (circuit-condition-right valor)
           :constant (circuit-condition-constant valor)))
    ((circuit-device-config-p valor)
     (list :antigonus-circuit-device-config
           :behavior (circuit-device-config-behavior valor)
           :input-signal (circuit-device-config-input-signal valor)
           :output-signal (circuit-device-config-output-signal valor)
           :operator (circuit-device-config-operator valor)
           :constant (circuit-device-config-constant valor)
           :condition (valor-para-dados (circuit-device-config-condition valor))
           :copy-count (circuit-device-config-copy-count valor)
           :pump-direction (circuit-device-config-pump-direction valor)
           :output-priority (circuit-device-config-output-priority valor)
           :lamp-color (circuit-device-config-lamp-color valor)
           :lamp-intensity (circuit-device-config-lamp-intensity valor)
           :alarm-sound (circuit-device-config-alarm-sound valor)
           :alarm-message (circuit-device-config-alarm-message valor)))
    ((belt-lane-p valor)
     (list :antigonus-belt-lane
           :capacity (belt-lane-capacity valor) :count (belt-lane-count valor)
           :items (loop for i below (belt-lane-count valor)
                        collect (aref (belt-lane-items valor) i))
           :positions (loop for i below (belt-lane-count valor)
                            collect (aref (belt-lane-positions valor) i))
           :stacks (loop for i below (belt-lane-count valor)
                         collect (aref (belt-lane-stacks valor) i))))
    ((hash-table-p valor)
     (list :antigonus-hash-table (tabela-para-lista valor)))
    ((stringp valor) valor)
    ((vectorp valor)
     (list :antigonus-vector
           (loop for elemento across valor collect (valor-para-dados elemento))))
    ((consp valor)
     (cons (valor-para-dados (car valor)) (valor-para-dados (cdr valor))))
    (t valor)))

(defun dados-para-valor (dados)
  (cond
    ((and (consp dados) (eq (car dados) :antigonus-circuit-condition))
     (make-circuit-condition :left (getf (cdr dados) :left)
                             :comparator (getf (cdr dados) :comparator)
                             :right (getf (cdr dados) :right)
                             :constant (getf (cdr dados) :constant 0)))
    ((and (consp dados) (eq (car dados) :antigonus-circuit-device-config))
     (make-circuit-device-config
      :behavior (getf (cdr dados) :behavior)
      :input-signal (getf (cdr dados) :input-signal)
      :output-signal (getf (cdr dados) :output-signal)
      :operator (getf (cdr dados) :operator)
      :constant (getf (cdr dados) :constant 0)
      :condition (dados-para-valor (getf (cdr dados) :condition))
      :copy-count (getf (cdr dados) :copy-count)
      :pump-direction (getf (cdr dados) :pump-direction :forward)
      :output-priority (getf (cdr dados) :output-priority :balanced)
      :lamp-color (getf (cdr dados) :lamp-color :amber)
      :lamp-intensity (getf (cdr dados) :lamp-intensity 100)
      :alarm-sound (getf (cdr dados) :alarm-sound :warning)
      :alarm-message (getf (cdr dados) :alarm-message :circuit-alert)))
    ((and (consp dados) (eq (car dados) :antigonus-belt-lane))
     (let* ((capacidade (getf (cdr dados) :capacity))
            (pista (make-belt-lane :capacity capacidade)))
       (loop for item in (getf (cdr dados) :items)
             for posicao in (getf (cdr dados) :positions)
             for pilha in (getf (cdr dados) :stacks)
             do (belt-lane-insert pista item :position posicao :stack pilha :min-gap 0))
       pista))
    ((and (consp dados) (eq (car dados) :antigonus-hash-table))
     (lista-para-tabela (second dados)))
    ((and (consp dados) (eq (car dados) :antigonus-vector))
     (coerce (mapcar #'dados-para-valor (second dados)) 'vector))
    ((consp dados)
     (cons (dados-para-valor (car dados)) (dados-para-valor (cdr dados))))
    (t dados)))

(defun tabela-para-lista (tabela)
  (let (r) (maphash (lambda (k v) (push (cons (valor-para-dados k)
                                               (valor-para-dados v)) r)) tabela)
    (sort r #'string< :key (lambda (p) (princ-to-string (car p))))))
(defun lista-para-tabela (lista &key (test #'equal))
  (let ((h (make-hash-table :test test)))
    (dolist (p lista h)
      (setf (gethash (dados-para-valor (car p)) h) (dados-para-valor (cdr p))))))
(defun predio-para-dados (b)
  (list :id (building-id b) :kind (building-kind b) :x (building-x b) :y (building-y b)
        :rotation (building-rotation b) :inventory (tabela-para-lista (building-inventory b))
        :recipe (building-recipe b) :progress (building-progress b)
        :enabled (building-enabled b) :hp (building-hp b)
        :state (valor-para-dados (building-state b))))
(defun entidade-para-dados (e)
  (list :id (entity-id e) :kind (entity-kind e) :x (entity-x e) :y (entity-y e)
        :vx (entity-vx e) :vy (entity-vy e) :hp (entity-hp e) :data (entity-data e)))
(defun chunk-para-dados (chunk)
  (list :x (chunk-x chunk) :y (chunk-y chunk)
        :tiles (coerce (chunk-tiles chunk) 'list)
        :resources (tabela-para-lista (chunk-resources chunk))
        :revision (chunk-revision chunk)))

(defun blueprint-para-dados (planta)
  (list :id (blueprint-definition-id planta) :name (blueprint-definition-name planta)
        :entries
        (mapcar (lambda (e)
                  (list :kind (blueprint-entry-kind e) :x (blueprint-entry-x e)
                        :y (blueprint-entry-y e) :rotation (blueprint-entry-rotation e)
                        :settings (valor-para-dados (blueprint-entry-settings e))))
                (blueprint-definition-entries planta))))

(defun mundo-para-dados (mundo)
  (rebuild-circuit-networks mundo)
  (let (predios entidades chunks plantas fios memoria-circuitos)
    (map-buildings (lambda (b) (push (predio-para-dados b) predios)) mundo)
    (map-entities (lambda (e) (push (entidade-para-dados e) entidades)) mundo)
    (map-chunks (lambda (chunk) (push (chunk-para-dados chunk) chunks)) mundo)
    (maphash (lambda (id planta) (declare (ignore id))
               (push (blueprint-para-dados planta) plantas))
             (world-blueprints mundo))
    (maphash (lambda (id fio) (declare (ignore id))
               (push (list :id (circuit-wire-id fio) :color (circuit-wire-color fio)
                           :a-building (circuit-wire-a-building fio)
                           :a-port (circuit-wire-a-port fio)
                           :b-building (circuit-wire-b-building fio)
                           :b-port (circuit-wire-b-port fio)) fios))
             (world-circuit-wires mundo))
    (maphash (lambda (id rede)
               (push (list :id id
                           :signals (tabela-para-lista (circuit-network-signals rede))
                           :next-signals (tabela-para-lista
                                          (circuit-network-next-signals rede)))
                     memoria-circuitos))
             (world-circuit-networks mundo))
    (list :seed (world-seed mundo) :tick (world-tick mundo) :next-id (world-next-id mundo)
          :pollution (world-pollution mundo) :research (world-research mundo)
          :campaign (world-campaign mundo) :difficulty (world-difficulty mundo)
          :game-data (tabela-para-lista (world-game-data mundo))
          :buildings (sort predios #'< :key (lambda (p) (getf p :id)))
          :entities (sort entidades #'< :key (lambda (p) (getf p :id)))
          :chunks (sort chunks #'string< :key (lambda (p)
                                               (format nil "~D/~D" (getf p :x) (getf p :y))))
          :blueprints (sort plantas #'string< :key (lambda (p) (princ-to-string (getf p :id))))
          :ghosts (valor-para-dados (world-ghosts mundo))
          :circuit-wires (sort fios #'< :key (lambda (fio) (getf fio :id)))
          :next-circuit-wire-id (world-next-circuit-wire-id mundo)
          :circuit-memory (sort memoria-circuitos #'< :key (lambda (rede) (getf rede :id)))
          :mods (mod-fingerprint))))

(defun restaurar-chunk (mundo dados)
  (let* ((x (* (getf dados :x) +chunk-size+))
         (y (* (getf dados :y) +chunk-size+))
         (chunk (ensure-chunk mundo x y))
         (tiles (getf dados :tiles)))
    (when tiles
      (replace (chunk-tiles chunk) tiles))
    (setf (chunk-resources chunk) (lista-para-tabela (getf dados :resources))
          (chunk-revision chunk) (getf dados :revision 0))
    chunk))

(defun restaurar-blueprint (dados)
  (make-blueprint-definition
   :id (getf dados :id) :name (getf dados :name)
   :entries (mapcar (lambda (e)
                      (make-blueprint-entry
                       :kind (getf e :kind) :x (getf e :x) :y (getf e :y)
                       :rotation (getf e :rotation)
                       :settings (dados-para-valor (getf e :settings))))
                    (getf dados :entries))))

(defun dados-para-mundo (d)
  (let ((m (%make-world :seed (getf d :seed) :tick (getf d :tick)
                        :next-id (getf d :next-id) :pollution (getf d :pollution)
                        :research (getf d :research) :campaign (getf d :campaign)
                        :difficulty (getf d :difficulty)
                        :game-data (lista-para-tabela (getf d :game-data)))))
    (dolist (chunk (getf d :chunks)) (restaurar-chunk m chunk))
    (dolist (p (getf d :buildings))
      (let ((b (%make-building :id (getf p :id) :kind (getf p :kind)
                               :x (getf p :x) :y (getf p :y)
                               :rotation (getf p :rotation)
                               :inventory (lista-para-tabela (getf p :inventory))
                               :recipe (getf p :recipe) :progress (getf p :progress)
                               :enabled (getf p :enabled) :hp (getf p :hp)
                               :state (dados-para-valor (getf p :state)))))
        (setf (gethash (building-id b) (world-buildings m)) b
              (gethash (cons (building-x b) (building-y b)) (world-positions m))
              (building-id b))
        (let ((chunk (ensure-chunk m (building-x b) (building-y b))))
          (vector-push-extend (building-id b) (chunk-building-ids chunk)))))
    (dolist (p (getf d :entities))
      (let ((e (%make-entity :id (getf p :id) :kind (getf p :kind)
                             :x (getf p :x) :y (getf p :y) :vx (getf p :vx)
                             :vy (getf p :vy) :hp (getf p :hp) :data (getf p :data))))
        (setf (gethash (entity-id e) (world-entities m)) e)))
    (dolist (dados-planta (getf d :blueprints))
      (let ((planta (restaurar-blueprint dados-planta)))
        (setf (gethash (blueprint-definition-id planta) (world-blueprints m)) planta)))
    (dolist (fio (getf d :circuit-wires))
      (let ((objeto (make-circuit-wire
                     :id (getf fio :id) :color (getf fio :color)
                     :a-building (getf fio :a-building) :a-port (getf fio :a-port)
                     :b-building (getf fio :b-building) :b-port (getf fio :b-port))))
        (setf (gethash (circuit-wire-id objeto) (world-circuit-wires m)) objeto)))
    (setf (world-next-circuit-wire-id m) (getf d :next-circuit-wire-id 1)
          (world-circuit-graph-dirty m) t)
    (rebuild-circuit-networks m)
    (dolist (memoria (getf d :circuit-memory))
      (let ((rede (gethash (getf memoria :id) (world-circuit-networks m))))
        (when rede
          (setf (circuit-network-signals rede)
                (lista-para-tabela (getf memoria :signals))
                (circuit-network-next-signals rede)
                (lista-para-tabela (getf memoria :next-signals))))))
    (setf (world-ghosts m) (dados-para-valor (getf d :ghosts)))
    m))

(defun migrar-logistica-v1 (mundo)
  "Converte buffers agregados antigos em duas pistas sem criar itens."
  (map-buildings
   (lambda (b)
     (when (member (building-kind b) '(:belt :fast-belt :splitter))
       (let ((pistas (vector (make-belt-lane :capacity 8)
                             (make-belt-lane :capacity 8)))
             (lado 0) pares)
         (maphash (lambda (item quantidade) (push (cons item quantidade) pares))
                  (building-inventory b))
         (dolist (par (sort pares #'string< :key (lambda (p) (string (car p)))))
           (dotimes (i (cdr par))
             (declare (ignore i))
             (let* ((pista (aref pistas lado))
                    (posicao (* 4096 (belt-lane-count pista))))
               (when (belt-lane-insert pista (car par) :position posicao :min-gap 0)
                 (inventory-remove (building-inventory b) (car par) 1)
                 (setf lado (mod (1+ lado) 2))))))
         (setf (getf (building-state b) :belt-lanes) pistas))))
   mundo)
  mundo)

(defun migrar-save-v1 (dados)
  (let ((mundo (dados-para-mundo dados)))
    (migrar-logistica-v1 mundo)
    ;; A rota antiga era um shuttle; a marca permite ao jogo gerar o horário
    ;; equivalente assim que as estações forem indexadas no novo grafo.
    (setf (gethash :migrated-from-save (world-game-data mundo)) 1
          (gethash :needs-rail-schedule-migration (world-game-data mundo)) t)
    mundo))
(defun save-game (mundo caminho)
  (ensure-directories-exist caminho)
  ;; Nem mesmo uma gravação explícita pode destruir um save de outra geração.
  (when (probe-file caminho)
    (with-open-file (s caminho)
      (let* ((*read-eval* nil) (dados (read s nil nil)))
        (unless (and (listp dados) (eql (getf dados :antigonus-save) +save-version+))
          (error (if (eq (current-language) :pt)
                     "SAVE INCOMPATIVEL: escolha outro arquivo. O original foi preservado."
                     "INCOMPATIBLE SAVE: choose another file. The original was preserved."))))))
  (let ((temporario (format nil "~A.tmp" caminho)))
    (with-open-file (s temporario :direction :output :if-exists :supersede
                                  :if-does-not-exist :create)
      (let ((*print-pretty* nil) (*print-readably* t))
        (print (list :antigonus-save +save-version+ :engine +engine-version+
                     :payload (mundo-para-dados mundo)) s)))
    (when (probe-file caminho)
      (uiop:copy-file caminho (format nil "~A.bak" caminho)))
    (uiop:rename-file-overwriting-target temporario caminho))
  caminho)
(defun load-game (caminho)
  (with-open-file (s caminho :direction :input)
    (let ((*read-eval* nil))
      (let ((dados (read s nil nil)))
        (unless (listp dados)
          (error "Save corrompido: ~A" caminho))
        (let ((versao (getf dados :antigonus-save)))
          (unless (eql versao +save-version+)
            (error (if (eq (current-language) :pt)
                       "SAVE INCOMPATIVEL: esperado schema ~D, encontrado ~A. O arquivo nao foi alterado."
                       "INCOMPATIBLE SAVE: expected schema ~D, found ~A. The file was not changed.")
                   +save-version+ versao))
          (dados-para-mundo (getf dados :payload)))))))
(defun autosave-game (mundo diretorio &key (slots 3))
  (check-type slots (integer 1 *))
  (let* ((anterior (gethash :autosave-sequence (world-game-data mundo) 0))
         (indice (mod anterior slots))
         (caminho (merge-pathnames (format nil "autosave-~D.save" indice)
                                   (pathname diretorio))))
    (setf (gethash :autosave-sequence (world-game-data mundo)) (1+ anterior))
    (handler-case (save-game mundo caminho)
      (error (e)
        (setf (gethash :autosave-sequence (world-game-data mundo)) anterior)
        (error e)))))

(defun simulation-state-hash (mundo)
  "Hash FNV-1a de 64 bits sobre a representação canônica do mundo."
  (let* ((dados (mundo-para-dados mundo))
         (fios
           (loop for fio in (getf dados :circuit-wires)
                 for a = (list (getf fio :a-building) (getf fio :a-port))
                 for b = (list (getf fio :b-building) (getf fio :b-port))
                 collect (list (getf fio :color)
                               (sort (list a b) #'porta-circuito<))))
         (hash #xcbf29ce484222325)
        (texto (with-output-to-string (s)
                 (let ((*print-pretty* nil) (*print-readably* t))
                   ;; IDs de edição dos fios não são estado elétrico da malha.
                   (setf (getf dados :circuit-wires) (sort fios #'string< :key #'prin1-to-string))
                   ;; A pasta de gravação é metadado local: mover uma instalação
                   ;; entre Linux/Windows não altera o estado da fábrica.
                   (setf (getf dados :game-data)
                         (remove :save-dir (getf dados :game-data) :key #'car))
                   (prin1 dados s)))))
    (loop for c across texto do
      (setf hash (logand #xffffffffffffffff
                         (* (logxor hash (char-code c)) #x100000001b3))))
    hash))

;;; Mods declarativos e scripts confiáveis.
(defun ler-sexp-seguro (arquivo)
  (with-open-file (s arquivo :direction :input) (let ((*read-eval* nil)) (read s nil nil))))
(defun manifesto-de-dados (dados pasta)
  (make-mod-manifest :id (getf dados :id) :name (getf dados :name)
                     :version (getf dados :version) :engine-version (getf dados :engine-version)
                     :dependencies (getf dados :dependencies) :conflicts (getf dados :conflicts)
                     :enabled (not (eq (getf dados :enabled t) nil)) :path pasta
                     :content (getf dados :content) :scripts (getf dados :scripts)))
(defun discover-mods (diretorio)
  (let (mods)
    (when (probe-file diretorio)
      (dolist (pasta (uiop:subdirectories diretorio))
        (let ((manifesto (merge-pathnames "manifest.sexp" pasta)))
          (when (probe-file manifesto)
            (handler-case (push (manifesto-de-dados (ler-sexp-seguro manifesto) pasta) mods)
              (error (e) (engine-log :error "Manifesto inválido ~A: ~A" manifesto e)))))))
    (sort mods #'string< :key (lambda (m) (string (mod-manifest-id m))))))
(defun ordenar-mods (mods)
  (let ((resultado nil) (temporarios nil) (permanentes nil))
    (labels ((visitar (m)
               (when (member (mod-manifest-id m) temporarios :test #'equal)
                 (error "Ciclo de dependências envolvendo ~A" (mod-manifest-id m)))
               (unless (member (mod-manifest-id m) permanentes :test #'equal)
                 (push (mod-manifest-id m) temporarios)
                 (dolist (dep (mod-manifest-dependencies m))
                   (let ((alvo (find (if (consp dep) (car dep) dep) mods
                                     :key #'mod-manifest-id :test #'equal)))
                     (unless alvo (error "Dependência ausente ~A em ~A" dep (mod-manifest-id m)))
                     (visitar alvo)))
                 (setf temporarios (remove (mod-manifest-id m) temporarios :test #'equal))
                 (push (mod-manifest-id m) permanentes) (push m resultado))))
      (dolist (m mods) (when (mod-manifest-enabled m) (visitar m))))
    (nreverse resultado)))
(defun carregar-conteudo-mod (mod)
  (dolist (nome (mod-manifest-content mod))
    (let ((dados (ler-sexp-seguro (merge-pathnames nome (mod-manifest-path mod)))))
      (dolist (entrada dados)
        (case (getf entrada :type)
          (:item (apply #'register-item (getf entrada :id) (remf-copia entrada :type :id)))
          (:recipe (apply #'register-recipe (getf entrada :id) (remf-copia entrada :type :id)))
          (:building (apply #'register-building (getf entrada :id) (remf-copia entrada :type :id)))
          (:technology (apply #'register-technology (getf entrada :id) (remf-copia entrada :type :id))))))))
(defun remf-copia (lista &rest chaves)
  (loop for (k v) on lista by #'cddr unless (member k chaves) append (list k v)))
(defun load-mods (mods &key safe-mode)
  (setf *mods-carregados* nil *erros-mods* nil)
  (unless safe-mode
    (dolist (mod (handler-case (ordenar-mods mods)
                   (error (e)
                     (push (list :id :dependencies :message (princ-to-string e)) *erros-mods*)
                     (dolist (m mods) (setf (mod-manifest-enabled m) nil))
                     nil)))
      (handler-case
          (progn
                 (unless (and (stringp (mod-manifest-engine-version mod))
                              (let ((partes (uiop:split-string
                                             (mod-manifest-engine-version mod) :separator ".")))
                                (and (= (length partes) 3) (string= (first partes) "3")
                                     (every (lambda (p) (and (plusp (length p))
                                                            (every #'digit-char-p p))) partes))))
                   (error (if (eq (current-language) :pt)
                              "Mod requer API ~A; Antigonus 3 aceita somente API 3.x. Arquivos preservados."
                              "Mod requires API ~A; Antigonus 3 only accepts API 3.x. Files preserved.")
                          (mod-manifest-engine-version mod)))
                 (dolist (dep (mod-manifest-dependencies mod))
                   (unless (find (if (consp dep) (car dep) dep) *mods-carregados*
                                 :key #'mod-manifest-id :test #'equal)
                     (error "Dependência desativada: ~A" dep)))
                 (carregar-conteudo-mod mod)
                 (dolist (script (mod-manifest-scripts mod))
                   (load (merge-pathnames script (mod-manifest-path mod))))
                 (push mod *mods-carregados*)
                 (engine-log :info "Mod carregado: ~A ~A" (mod-manifest-name mod)
                             (mod-manifest-version mod)))
        (error (e)
          (setf (mod-manifest-enabled mod) nil)
          (push (list :id (mod-manifest-id mod) :message (princ-to-string e)) *erros-mods*)
          (engine-log :error "Falha no mod ~A: ~A" (mod-manifest-id mod) e)))))
  (setf *mods-carregados* (nreverse *mods-carregados*)
        *erros-mods* (nreverse *erros-mods*))
  *mods-carregados*)
(defun mod-fingerprint ()
  "Fingerprint portátil, independente do SXHASH específico da implementação."
  (let ((hash #xcbf29ce484222325)
        (texto (format nil "~{~A~^|~}"
                        (sort (mapcar (lambda (m) (format nil "~A@~A" (mod-manifest-id m)
                                                         (mod-manifest-version m)))
                                      *mods-carregados*) #'string<))))
    (loop for c across texto do
      (setf hash (logand #xffffffffffffffff (* (logxor hash (char-code c)) #x100000001b3))))
    (format nil "~16,'0X" hash)))

(defun engine-log (level format-control &rest args)
  (format *error-output* "~&[ANTIGONUS ~A] ~?~%" (string-upcase (string level))
          format-control args) (finish-output *error-output*))

;;; Estado de apresentação e wrappers públicos SDL.
(defun screen-width () *largura-tela*)
(defun screen-height () *altura-tela*)
(defun set-clear-color (r g b &optional (a 255)) (setf *cor-limpeza* (list r g b a)))
(defun set-camera (x y &optional (zoom 1.0))
  (setf *camera-x* x *camera-y* y *camera-zoom* (max 0.2 (min 4.0 zoom))))
(defun camera-position () (values *camera-x* *camera-y* *camera-zoom*))
(defun world-to-screen (x y)
  (values (round (+ (/ *largura-tela* 2) (* (- x *camera-x*) *camera-zoom*)))
          (round (+ (/ *altura-tela* 2) (* (- y *camera-y*) *camera-zoom*)))))
(defun screen-to-world (x y)
  (values (+ *camera-x* (/ (- x (/ *largura-tela* 2)) *camera-zoom*))
          (+ *camera-y* (/ (- y (/ *altura-tela* 2)) *camera-zoom*))))
(defun mouse-position () (values *mouse-x* *mouse-y*))
(defun input-down-p (action)
  (gethash (if (keywordp action) (sdl2:scancode-key-to-value action) action)
           *entradas-ativas*))
(defun set-time-scale (scale) (setf *escala-tempo* (max 1 (min 4 scale)) *pausado* nil))
(defun time-scale () *escala-tempo*)
(defun paused-p () *pausado*)
(defun toggle-pause () (setf *pausado* (not *pausado*)))
(defun stop-game () (setf *executando* nil))
(defun replace-world (world)
  "Substitui o mundo ativo entre telas, por exemplo ao continuar um save."
  (check-type world world)
  (setf *mundo-atual* world))

(in-package #:antigonus-interno)
(defvar *renderizador* nil)

(defun cor (lista) (values (or (first lista) 255) (or (second lista) 255)
                               (or (third lista) 255) (or (fourth lista) 255)))
(defun aplicar-cor (lista)
  (multiple-value-call #'sdl2:set-render-draw-color *renderizador* (cor lista)))

(in-package #:antigonus)
(defun set-display-mode (width height &key fullscreen (ui-scale 1))
  "Aplica resolução de janela e escala lógica; fullscreen usa a área do desktop.
Escalas de 75 a 100% preservam a área útil mínima de 1280×720 da interface."
  (unless (and (typep width '(integer 1024 7680)) (typep height '(integer 576 4320))
               (realp ui-scale) (<= 3/4 ui-scale 1))
    (error "Resolução ou escala de interface inválida."))
  (when *janela-atual*
    (sdl2:set-window-fullscreen *janela-atual* (and fullscreen :desktop))
    (unless fullscreen (sdl2:set-window-size *janela-atual* width height)))
  (let ((largura (round 1280 ui-scale)) (altura (round 720 ui-scale)))
    (when antigonus-interno::*renderizador*
      (unless (zerop (sdl2-ffi.functions:sdl-render-set-logical-size
                      antigonus-interno::*renderizador* largura altura))
        (error "Não foi possível aplicar a escala de interface.")))
    (setf *largura-tela* largura *altura-tela* altura))
  (setf *modo-video* (list width height :fullscreen (not (null fullscreen)) :ui-scale ui-scale)))

(defun draw-rect (x y width height color &key outline world)
  (when antigonus-interno::*renderizador*
    (when world (multiple-value-setq (x y) (world-to-screen x y))
          (setf width (round (* width *camera-zoom*)) height (round (* height *camera-zoom*))))
    (antigonus-interno::aplicar-cor color)
    (funcall (if outline #'sdl2:render-draw-rect #'sdl2:render-fill-rect)
             antigonus-interno::*renderizador* (sdl2:make-rect (round x) (round y)
                                                               (max 1 (round width))
                                                               (max 1 (round height))))))
(defun draw-line (x1 y1 x2 y2 color &key world)
  (when antigonus-interno::*renderizador*
    (when world (multiple-value-setq (x1 y1) (world-to-screen x1 y1))
          (multiple-value-setq (x2 y2) (world-to-screen x2 y2)))
    (antigonus-interno::aplicar-cor color)
    (sdl2:render-draw-line antigonus-interno::*renderizador*
                           (round x1) (round y1) (round x2) (round y2))))
(defun draw-circle (x y radius color &key world (segments 20))
  (loop for i below segments for a = (* 2 pi (/ i segments))
        for b = (* 2 pi (/ (1+ i) segments))
        do (draw-line (+ x (* radius (cos a))) (+ y (* radius (sin a)))
                      (+ x (* radius (cos b))) (+ y (* radius (sin b))) color :world world)))

(defun capture-renderer (caminho)
  "Grava o framebuffer real em PPM RGB8, antes de apresentar o quadro."
  (unless antigonus-interno::*renderizador* (error "Renderizador indisponível."))
  (multiple-value-bind (largura altura)
      (sdl2:get-renderer-output-size antigonus-interno::*renderizador*)
    (let* ((tamanho (* largura altura 3))
           (pixels (make-array tamanho :element-type '(unsigned-byte 8))))
      (cffi:with-foreign-object (buffer :uint8 tamanho)
        (unless (zerop (sdl2-ffi.functions:sdl-render-read-pixels
                        antigonus-interno::*renderizador* (cffi:null-pointer)
                        386930691 buffer (* largura 3))) ; SDL_PIXELFORMAT_RGB24
          (error "Falha no readback do renderizador."))
        (dotimes (i tamanho) (setf (aref pixels i) (cffi:mem-aref buffer :uint8 i))))
      (ensure-directories-exist caminho)
      (with-open-file (s caminho :direction :output :if-exists :supersede
                                :element-type '(unsigned-byte 8))
        (loop for c across (format nil "P6~%~D ~D~%255~%" largura altura)
              do (write-byte (char-code c) s))
        (write-sequence pixels s))
      caminho)))

(defun carregar-folha (folha)
  (unless (sprite-sheet-texture folha)
    (let ((superficie (sdl2-image:load-image (sprite-sheet-path folha))))
      (unwind-protect
           (let ((w (sdl2:surface-width superficie))
                 (h (sdl2:surface-height superficie)))
             (setf (sprite-sheet-pixel-width folha) w
                   (sprite-sheet-pixel-height folha) h
                   (sprite-sheet-texture folha)
                   (sdl2:create-texture-from-surface antigonus-interno::*renderizador* superficie))
             (sdl2:set-texture-blend-mode (sprite-sheet-texture folha) :blend))
        (sdl2:free-surface superficie))))
  folha)

(defun draw-sprite (sheet index x y width height
                    &key world (angle 0.0) (opacity 255) flip (tint '(255 255 255)))
  "Desenha a célula INDEX de uma atlas registrada."
  (when antigonus-interno::*renderizador*
    (let ((folha (gethash sheet *folhas-sprites*)))
      (when folha
        (handler-case
            (progn
              (carregar-folha folha)
              (when world
                ;; Calcula ambos os cantos no mesmo espaço arredondado. Assim,
                ;; sprites adjacentes compartilham a borda mesmo em zoom
                ;; fracionário, sem frestas escuras de um pixel entre tiles.
                (multiple-value-bind (x0 y0) (world-to-screen x y)
                  (multiple-value-bind (x1 y1)
                      (world-to-screen (+ x width) (+ y height))
                    (setf x x0 y y0 width (- x1 x0) height (- y1 y0)))))
              (let* ((cw (floor (sprite-sheet-pixel-width folha) (sprite-sheet-columns folha)))
                     (ch (floor (sprite-sheet-pixel-height folha) (sprite-sheet-rows folha)))
                     (col (mod index (sprite-sheet-columns folha)))
                     (row (floor index (sprite-sheet-columns folha)))
                     (src (sdl2:make-rect (* col cw) (* row ch) cw ch))
                     (dst (sdl2:make-rect (round x) (round y) (max 1 (round width))
                                          (max 1 (round height)))))
                (destructuring-bind (r g b) tint
                  (sdl2:set-texture-color-mod (sprite-sheet-texture folha) r g b))
                (sdl2:set-texture-alpha-mod (sprite-sheet-texture folha)
                                            (max 0 (min 255 opacity)))
                (unwind-protect
                     (sdl2:render-copy-ex antigonus-interno::*renderizador*
                                          (sprite-sheet-texture folha) :source-rect src
                                          :dest-rect dst :angle angle :flip flip)
                  (sdl2:set-texture-alpha-mod (sprite-sheet-texture folha) 255)
                  (sdl2:set-texture-color-mod (sprite-sheet-texture folha) 255 255 255))))
          (error (e) (engine-log :warning "Sprite ~A não pôde ser desenhado: ~A" sheet e)))))))

(defun draw-animation (animation x y width height
                       &key world (angle 0.0) (opacity 255) flip
                         (tint '(255 255 255)) time (phase 0.0))
  "Desenha uma animação registrada. PHASE permite defasar instâncias."
  (let ((def (etypecase animation
               (animation-definition animation)
               (symbol (find-animation animation)))))
    (when def
      (draw-sprite (animation-definition-sheet def)
                   (animation-frame def (+ (or time *tempo-visual*) phase))
                   x y width height :world world :angle angle :opacity opacity
                   :flip flip :tint tint))))

;; Fonte bitmap 5x7, suficiente para UI sem arquivos ou licenças adicionais.
(defparameter *fonte-bitmap*
  '((#\A 14 17 17 31 17 17 17) (#\B 30 17 17 30 17 17 30)
    (#\C 14 17 16 16 16 17 14) (#\D 30 17 17 17 17 17 30)
    (#\E 31 16 16 30 16 16 31) (#\F 31 16 16 30 16 16 16)
    (#\G 14 17 16 23 17 17 15) (#\H 17 17 17 31 17 17 17)
    (#\I 14 4 4 4 4 4 14) (#\J 7 2 2 2 18 18 12)
    (#\K 17 18 20 24 20 18 17) (#\L 16 16 16 16 16 16 31)
    (#\M 17 27 21 21 17 17 17) (#\N 17 25 21 19 17 17 17)
    (#\O 14 17 17 17 17 17 14) (#\P 30 17 17 30 16 16 16)
    (#\Q 14 17 17 17 21 18 13) (#\R 30 17 17 30 20 18 17)
    (#\S 15 16 16 14 1 1 30) (#\T 31 4 4 4 4 4 4)
    (#\U 17 17 17 17 17 17 14) (#\V 17 17 17 17 17 10 4)
    (#\W 17 17 17 21 21 21 10) (#\X 17 17 10 4 10 17 17)
    (#\Y 17 17 10 4 4 4 4) (#\Z 31 1 2 4 8 16 31)
    (#\0 14 17 19 21 25 17 14) (#\1 4 12 4 4 4 4 14)
    (#\2 14 17 1 2 4 8 31) (#\3 30 1 1 14 1 1 30)
    (#\4 2 6 10 18 31 2 2) (#\5 31 16 16 30 1 1 30)
    (#\6 14 16 16 30 17 17 14) (#\7 31 1 2 4 8 8 8)
    (#\8 14 17 17 14 17 17 14) (#\9 14 17 17 15 1 1 14)
    (#\- 0 0 0 31 0 0 0) (#\_ 0 0 0 0 0 0 31)
    (#\. 0 0 0 0 0 12 12) (#\: 0 12 12 0 12 12 0)
    (#\/ 1 2 2 4 8 8 16) (#\+ 0 4 4 31 4 4 0)
    (#\! 4 4 4 4 4 0 4) (#\? 14 17 1 2 4 0 4)
    (#\< 1 2 4 8 4 2 1) (#\> 16 8 4 2 4 8 16)
    (#\= 0 0 31 0 31 0 0) (#\* 0 21 14 31 14 21 0)
    (#\# 10 31 10 10 31 10 0) (#\| 4 4 4 4 4 4 4)
    (#\% 17 2 4 8 17 0 0)
    (#\( 2 4 8 8 8 4 2) (#\) 8 4 2 2 2 4 8)))
(defun normalizar-caractere (c)
  (let ((pos (position c "ÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇáàâãäéèêëíìîïóòôõöúùûüç")))
    (if pos (char "AAAAAEEEEIIIIOOOOOUUUUCaaaaaeeeeiiiiooooouuuuc" pos)
        (char-upcase c))))
(defun draw-text (text x y color &key (scale 2))
  (loop for c across (princ-to-string text) for coluna from 0
        for glyph = (cdr (assoc (normalizar-caractere c) *fonte-bitmap*))
        do (when glyph
             (loop for bits in glyph for linha from 0 do
               (loop for bit from 0 below 5 when (logbitp (- 4 bit) bits) do
                 (draw-rect (+ x (* coluna 6 scale) (* bit scale))
                            (+ y (* linha scale)) scale scale color))))))

(in-package #:antigonus-interno)
(defun enviar-entrada (tipo &rest dados)
  (let ((f (and antigonus::*configuracao-atual*
                (game-config-input antigonus::*configuracao-atual*))))
    (when f (apply f antigonus::*mundo-atual* tipo dados))))
(defun atualizar-tecla (keysym pressionada)
  (let ((codigo (sdl2:scancode-value keysym)))
    (setf (gethash codigo antigonus::*entradas-ativas*) pressionada)
    (if pressionada
        (let ((consumida (enviar-entrada :key-down codigo)))
          (unless consumida
            (cond
              ((sdl2:scancode= codigo :scancode-escape) (stop-game))
              ((sdl2:scancode= codigo :scancode-space) (toggle-pause))
              ((sdl2:scancode= codigo :scancode-f1) (set-time-scale 1))
              ((sdl2:scancode= codigo :scancode-f2) (set-time-scale 2))
              ((sdl2:scancode= codigo :scancode-f3) (set-time-scale 4)))))
        (enviar-entrada :key-up codigo))))
(defun nome-driver-renderizacao (info)
  ;; SDL_RendererInfo começa com const char *name em todas as ABIs SDL2.
  (cffi:foreign-string-to-lisp (cffi:mem-ref (autowrap:ptr info) :pointer)))
(defun indice-driver-opengl ()
  "Seleciona um índice explícito: hints permitem fallback silencioso da SDL."
  (engine-log :info "Consultando drivers SDL")
  (or (loop for i below (sdl2:get-num-render-drivers)
            for info = (sdl2:get-render-driver-info i)
            when (unwind-protect (string= "opengl" (nome-driver-renderizacao info))
                   (sdl2::free-render-info info))
              return (progn (engine-log :info "Driver OpenGL selecionado: ~D" i) i))
      (error "OpenGL 3.3 é obrigatório / OpenGL 3.3 is required.")))
(defun verificar-renderizador-opengl (renderer)
  (let ((info (sdl2:get-renderer-info renderer)))
    (unwind-protect
         (unless (string= "opengl" (nome-driver-renderizacao info))
           (error "Backend gráfico incompatível / Incompatible rendering backend."))
      (sdl2::free-render-info info)))
  (let* ((funcao (sdl2:gl-get-proc-address "glGetString"))
         (versao (unless (cffi:null-pointer-p funcao)
                   (cffi:foreign-funcall-pointer funcao () :uint #x1f02 :string))))
    (unless versao (error "Contexto OpenGL indisponível / OpenGL context unavailable."))
    (let* ((ponto (position #\. versao))
           (maior (and ponto (parse-integer versao :end ponto :junk-allowed t)))
           (menor (and ponto (parse-integer versao :start (1+ ponto) :junk-allowed t))))
      (unless (and maior menor (or (> maior 3) (and (= maior 3) (>= menor 3))))
        (error "OpenGL 3.3 é obrigatório / required; encontrado / found: ~A" versao)))
    (engine-log :info "Renderer: opengl; OpenGL: ~A; batching SDL ativo" versao)))
(defun executar-sdl ()
  (sdl2:with-init (:video :audio :gamecontroller)
    (engine-log :info "SDL inicializada; criando janela OpenGL")
    ;; A versão 2.0 fixa o backend SDL no driver OpenGL e habilita o lote
    ;; interno de comandos. Não há seleção automática de Direct3D/software.
    (sdl2:set-hint :render-driver "opengl")
    (sdl2:set-hint :render-batching "1")
    (sdl2:set-hint :render-scale-quality "0")
    (sdl2:gl-set-attrs :context-major-version 3 :context-minor-version 3
                       :context-profile-mask 2 :doublebuffer 1)
    (sdl2:with-window (janela :title (game-config-title antigonus::*configuracao-atual*)
                              :w antigonus::*largura-tela* :h antigonus::*altura-tela*
                              :flags '(:shown :resizable :opengl))
      (engine-log :info "Janela criada; inicializando renderizador OpenGL explícito")
      (sdl2:with-renderer (renderer janela :index (indice-driver-opengl)
                                         :flags '(:accelerated :presentvsync))
        (verificar-renderizador-opengl renderer)
        ;; Mantém uma área lógica estável ao redimensionar. A SDL escala e
        ;; letterboxa o quadro completo, evitando HUD recortado e coordenadas
        ;; de mouse divergentes em janelas com outra proporção.
        (sdl2-ffi.functions:sdl-render-set-logical-size
         renderer antigonus::*largura-tela* antigonus::*altura-tela*)
        (sdl2:set-render-draw-blend-mode renderer :blend)
        (handler-case
            (progn (sdl2-mixer:init)
                   (sdl2-mixer:open-audio 44100 :s16sys 2 1024)
                   (sdl2-mixer:allocate-channels 16)
                   (setf antigonus::*audio-pronto* t)
                   (set-audio-volume antigonus::*volume-audio*))
          (error (e) (engine-log :warning "Áudio indisponível: ~A" e)))
        (handler-case (sdl2-image:init '(:png))
          (error (e) (engine-log :warning "SDL2_image indisponível: ~A" e)))
        (let ((*renderizador* renderer)
              (antigonus::*janela-atual* janela)
              (controles (loop for i below (sdl2:joystick-count)
                              when (sdl2:game-controller-p i) collect (sdl2:game-controller-open i)))
              (ultimo (get-internal-real-time)) (acumulador 0.0)
              (passo (/ 1.0 30.0)))
          (when antigonus::*modo-video* (apply #'set-display-mode antigonus::*modo-video*))
          (sdl2:with-event-loop (:method :poll)
            (:keydown (:keysym keysym) (atualizar-tecla keysym t))
            (:keyup (:keysym keysym) (atualizar-tecla keysym nil))
            (:mousemotion (:x x :y y)
              (setf antigonus::*mouse-x* x antigonus::*mouse-y* y)
              (enviar-entrada :mouse-move x y))
            (:mousebuttondown (:button button :x x :y y)
              (enviar-entrada :mouse-down button x y))
            (:mousebuttonup (:button button :x x :y y)
              (enviar-entrada :mouse-up button x y))
            (:mousewheel (:x x :y y) (enviar-entrada :mouse-wheel x y))
            (:controllerdeviceadded (:which which)
              (when (sdl2:game-controller-p which)
                (let ((novo (sdl2:game-controller-open which)))
                  (if (some (lambda (controle)
                              (= (sdl2:game-controller-instance-id controle)
                                 (sdl2:game-controller-instance-id novo))) controles)
                      (sdl2:game-controller-close novo)
                      (push novo controles)))))
            (:controlleraxismotion (:axis axis :value value)
              (enviar-entrada :controller-axis axis value))
            (:controllerdeviceremoved (:which which)
              (let ((controle (find which controles :key #'sdl2:game-controller-instance-id)))
                (when controle
                  (setf controles (remove controle controles))
                  (sdl2:game-controller-close controle)))
              (enviar-entrada :controller-disconnected))
            (:controllerbuttondown (:button button)
              (enviar-entrada :controller-down button))
            (:controllerbuttonup (:button button)
              (enviar-entrada :controller-up button))
            (:idle ()
              (unless antigonus::*executando* (sdl2:push-event :quit))
              (let* ((agora (get-internal-real-time))
                     (delta (min 0.25 (/ (- agora ultimo) internal-time-units-per-second))))
                (setf ultimo agora)
                (incf antigonus::*tempo-visual* delta)
                (unless antigonus::*pausado*
                  (incf acumulador (* delta antigonus::*escala-tempo*)))
                (loop while (>= acumulador passo) do
                  (simulate-tick antigonus::*mundo-atual*)
                  (when (game-config-update antigonus::*configuracao-atual*)
                    (funcall (game-config-update antigonus::*configuracao-atual*)
                             antigonus::*mundo-atual* passo))
                  (decf acumulador passo)))
              (multiple-value-call #'sdl2:set-render-draw-color renderer
                (cor antigonus::*cor-limpeza*))
              (sdl2:render-clear renderer)
              (when (game-config-render antigonus::*configuracao-atual*)
                (funcall (game-config-render antigonus::*configuracao-atual*)
                         antigonus::*mundo-atual*
                         (/ acumulador passo)))
              (sdl2:render-present renderer))
            (:quit () t))
          (dolist (controle controles) (sdl2:game-controller-close controle)))
        (when antigonus::*audio-pronto*
          (maphash (lambda (id som) (declare (ignore id))
                     (when (getf som :chunk) (sdl2-mixer:free-chunk (getf som :chunk))))
                   antigonus::*sons*)
          (sdl2-mixer:close-audio) (sdl2-mixer:quit)
          (setf antigonus::*audio-pronto* nil))
        (unload-sprites)
        (sdl2-image:quit)))))

(in-package #:antigonus)
(defun run-game (config &key world headless (ticks 0))
  "Executa CONFIG. Em modo headless, avança TICKS sem abrir uma janela."
  (setf *configuracao-atual* config *mundo-atual* (or world (make-world))
        *largura-tela* (game-config-width config) *altura-tela* (game-config-height config)
        *executando* t)
  (when (game-config-start config) (funcall (game-config-start config) *mundo-atual*))
  (unwind-protect
       (if headless
           (dotimes (i ticks)
             (declare (ignorable i)) (simulate-tick *mundo-atual*)
             (when (game-config-update config)
               (funcall (game-config-update config) *mundo-atual* (/ 1.0 30.0))))
           (antigonus-interno::executar-sdl))
    (when (game-config-shutdown config) (funcall (game-config-shutdown config) *mundo-atual*))
    (setf *executando* nil))
  *mundo-atual*)
