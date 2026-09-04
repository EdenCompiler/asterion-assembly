;;;; Antigonus 1.0.0 — engine 2D para jogos de automação.
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
   #:+engine-version+ #:+save-version+ #:game-config #:world #:entity-id
   #:item-definition #:recipe-definition #:building-definition
   #:technology-definition #:mod-manifest #:building #:entity #:train
   #:define-game #:defgame #:run-game #:stop-game #:replace-world #:make-world #:with-world
   #:world-seed #:world-tick
   #:world-building-count
   #:world-pollution #:world-research #:world-campaign #:world-difficulty
   #:world-game-data #:reset-engine #:define-system #:defsystem #:remove-system
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
   #:recipe-definition-id #:recipe-definition-inputs #:recipe-definition-outputs
   #:recipe-definition-duration #:recipe-definition-category #:building-definition-id
   #:building-definition-name #:building-definition-category
   #:building-definition-cost #:building-definition-power
   #:building-definition-color #:building-definition-size
   #:technology-definition-id #:technology-definition-cost
   #:technology-definition-name #:technology-definition-unlocks
   #:technology-definition-prerequisites #:simulate-tick #:on-event #:emit-event
   #:save-game #:load-game #:autosave-game #:discover-mods #:load-mods
   #:mod-fingerprint #:mod-manifest-id #:mod-manifest-version
   #:mod-manifest-name #:mod-manifest-dependencies #:mod-manifest-enabled
   #:set-language #:translate #:register-translations #:deftranslations #:current-language
   #:draw-rect #:draw-line #:draw-text #:draw-circle #:screen-width
   #:sprite-sheet #:animation-definition #:register-sprite-sheet #:draw-sprite
   #:register-animation #:defanimation #:find-animation #:animation-frame
   #:draw-animation #:engine-time #:unload-sprites
   #:screen-height #:set-clear-color #:set-camera #:camera-position
   #:register-sound #:play-sound #:set-audio-volume
   #:screen-to-world #:world-to-screen #:mouse-position #:input-down-p
   #:set-time-scale #:time-scale #:paused-p #:toggle-pause #:engine-log
   #:profile-snapshot #:resource-noise #:find-path #:rail-route
   #:game-config-title #:game-config-width #:game-config-height
   #:game-config-start #:game-config-update #:game-config-render
   #:game-config-input #:game-config-shutdown))

(defpackage #:antigonus-interno
  (:use #:cl #:antigonus))

(in-package #:antigonus)

(defparameter +engine-version+ "1.0.0")
(defconstant +save-version+ 1)
(deftype entity-id () '(integer 1 *))

(defstruct item-definition id name (stack-size 100) color description)
(defstruct recipe-definition id (inputs nil) (outputs nil) (duration 30) category)
(defstruct building-definition id name category (cost nil) (power 0) color
           (size 1) recipe-category description)
(defstruct technology-definition id name (cost nil) (unlocks nil) prerequisites description)
(defstruct mod-manifest id name version engine-version dependencies conflicts
           path (enabled t) scripts content)
(defstruct (entity (:constructor %make-entity)) id kind x y (vx 0.0) (vy 0.0)
           (hp 100) data)
(defstruct (building (:constructor %make-building)) id kind x y (rotation 0)
           (inventory (make-hash-table :test #'equal)) recipe (progress 0)
           (enabled t) (hp 100) state)
(defstruct (train (:constructor %make-train)) id route (route-index 0)
           (progress 0.0) (speed 0.08) (cargo (make-hash-table :test #'equal))
           (status :moving))
(defstruct (world (:constructor %make-world)) (seed 1) (tick 0)
           (buildings (make-hash-table)) (positions (make-hash-table :test #'equal))
           (entities (make-hash-table)) (trains nil) (next-id 1)
           (pollution 0.0) (research nil) (campaign nil) (difficulty :standard)
           (game-data (make-hash-table :test #'equal)) (events nil))
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
  (let ((prioridade (or (getf options :priority) 0)))
    `(define-system ,name (lambda ,lambda-list ,@body) :priority ,prioridade)))

(defmacro deftranslations (language &body pairs)
  "Declara traduções; cada entrada tem a forma (KEY \"TEXT\")."
  `(register-translations ,language
     (list ,@(mapcar (lambda (par) `(cons ,(first par) ,(second par))) pairs))))

(defmacro defanimation (id &rest options)
  "Declara uma animação visual sobre uma faixa contígua de uma atlas."
  `(register-animation ,id ,@options))

(defun make-world (&key (seed 1) (difficulty :standard))
  (%make-world :seed (max 1 (abs seed)) :difficulty difficulty))

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

(defun register-sound (id path)
  "Registra o caminho de um WAV. O carregamento é preguiçoso após abrir o áudio."
  (setf (gethash id *sons*) (list :path (namestring path) :chunk nil)) id)
(defun set-audio-volume (volume)
  (setf *volume-audio* (max 0 (min 128 volume)))
  (when *audio-pronto* (sdl2-mixer:volume -1 *volume-audio*)) *volume-audio*)
(defun play-sound (id &key (loops 0))
  (when *audio-pronto*
    (let ((som (gethash id *sons*)))
      (when som
        (handler-case
            (progn
              (unless (getf som :chunk)
                (setf (getf som :chunk) (sdl2-mixer:load-wav (getf som :path))))
              (sdl2-mixer:play-channel -1 (getf som :chunk) loops))
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

(defun register-item (id &key name (stack-size 100) color description)
  (setf (gethash id *itens*)
        (make-item-definition :id id :name (or name (string id))
                              :stack-size stack-size :color color :description description)))
(defun find-item (id) (gethash id *itens*))
(defun map-items (funcao) (maphash (lambda (k v) (declare (ignore k)) (funcall funcao v)) *itens*))

(defun register-recipe (id &key inputs outputs (duration 30) category)
  (setf (gethash id *receitas*)
        (make-recipe-definition :id id :inputs inputs :outputs outputs
                                :duration duration :category category)))
(defun find-recipe (id) (gethash id *receitas*))
(defun map-recipes (funcao) (maphash (lambda (k v) (declare (ignore k)) (funcall funcao v)) *receitas*))

(defun register-building (id &key name category cost (power 0) color (size 1)
                                  recipe-category description)
  (setf (gethash id *construcoes*)
        (make-building-definition :id id :name (or name (string id)) :category category
                                  :cost cost :power power :color color :size size
                                  :recipe-category recipe-category :description description)))
(defun find-building (id) (gethash id *construcoes*))
(defun map-building-definitions (funcao)
  (maphash (lambda (k v) (declare (ignore k)) (funcall funcao v)) *construcoes*))

(defun register-technology (id &key name cost unlocks prerequisites description)
  (setf (gethash id *tecnologias*)
        (make-technology-definition :id id :name (or name (string id)) :cost cost
                                    :unlocks unlocks :prerequisites prerequisites
                                    :description description)))
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

(defun place-building (mundo kind x y &key (rotation 0) recipe state)
  (when (and (find-building kind) (null (gethash (cons x y) (world-positions mundo))))
    (let* ((id (prog1 (world-next-id mundo) (incf (world-next-id mundo))))
           (predio (%make-building :id id :kind kind :x x :y y :rotation rotation
                                   :recipe recipe :state state
                                   :hp (or (getf state :hp) 100))))
      (setf (gethash id (world-buildings mundo)) predio
            (gethash (cons x y) (world-positions mundo)) id)
      (emit-event :building-placed mundo predio)
      predio)))

(defun building-at (mundo x y)
  (let ((id (gethash (cons x y) (world-positions mundo))))
    (and id (gethash id (world-buildings mundo)))))

(defun remove-building (mundo predio-ou-id)
  (let ((predio (if (building-p predio-ou-id) predio-ou-id
                    (gethash predio-ou-id (world-buildings mundo)))))
    (when predio
      (remhash (cons (building-x predio) (building-y predio)) (world-positions mundo))
      (remhash (building-id predio) (world-buildings mundo))
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

(defun define-system (name function &key (priority 0))
  (setf *sistemas* (remove name *sistemas* :key #'first :test #'equal))
  (push (list name priority function) *sistemas*)
  (setf *sistemas* (sort *sistemas* #'< :key #'second))
  name)
(defun remove-system (name) (setf *sistemas* (remove name *sistemas* :key #'first :test #'equal)))
(defun on-event (event function) (push function (gethash event *eventos*)) function)
(defun emit-event (event &rest args)
  (dolist (funcao (reverse (gethash event *eventos*))) (apply funcao args)))

(defun registrar-tempo (nome inicio)
  (setf (gethash nome *perfil*)
        (/ (- (get-internal-real-time) inicio) internal-time-units-per-second)))
(defun profile-snapshot ()
  (let (resultado) (maphash (lambda (k v) (push (cons k v) resultado)) *perfil*) resultado))

(defun simulate-tick (mundo)
  "Avança exatamente um tick determinístico."
  (let ((inicio (get-internal-real-time)))
    (incf (world-tick mundo))
    (dolist (sistema *sistemas*) (funcall (third sistema) mundo))
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
    ((hash-table-p valor)
     (list :antigonus-hash-table (tabela-para-lista valor)))
    ((consp valor)
     (cons (valor-para-dados (car valor)) (valor-para-dados (cdr valor))))
    (t valor)))

(defun dados-para-valor (dados)
  (cond
    ((and (consp dados) (eq (car dados) :antigonus-hash-table))
     (lista-para-tabela (second dados)))
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
        :enabled (building-enabled b) :hp (building-hp b) :state (building-state b)))
(defun entidade-para-dados (e)
  (list :id (entity-id e) :kind (entity-kind e) :x (entity-x e) :y (entity-y e)
        :vx (entity-vx e) :vy (entity-vy e) :hp (entity-hp e) :data (entity-data e)))
(defun mundo-para-dados (mundo)
  (let (predios entidades)
    (map-buildings (lambda (b) (push (predio-para-dados b) predios)) mundo)
    (map-entities (lambda (e) (push (entidade-para-dados e) entidades)) mundo)
    (list :seed (world-seed mundo) :tick (world-tick mundo) :next-id (world-next-id mundo)
          :pollution (world-pollution mundo) :research (world-research mundo)
          :campaign (world-campaign mundo) :difficulty (world-difficulty mundo)
          :game-data (tabela-para-lista (world-game-data mundo))
          :buildings predios :entities entidades :mods (mod-fingerprint))))
(defun dados-para-mundo (d)
  (let ((m (%make-world :seed (getf d :seed) :tick (getf d :tick)
                        :next-id (getf d :next-id) :pollution (getf d :pollution)
                        :research (getf d :research) :campaign (getf d :campaign)
                        :difficulty (getf d :difficulty)
                        :game-data (lista-para-tabela (getf d :game-data)))))
    (dolist (p (getf d :buildings))
      (let ((b (%make-building :id (getf p :id) :kind (getf p :kind)
                               :x (getf p :x) :y (getf p :y)
                               :rotation (getf p :rotation)
                               :inventory (lista-para-tabela (getf p :inventory))
                               :recipe (getf p :recipe) :progress (getf p :progress)
                               :enabled (getf p :enabled) :hp (getf p :hp)
                               :state (getf p :state))))
        (setf (gethash (building-id b) (world-buildings m)) b
              (gethash (cons (building-x b) (building-y b)) (world-positions m))
              (building-id b))))
    (dolist (p (getf d :entities))
      (let ((e (%make-entity :id (getf p :id) :kind (getf p :kind)
                             :x (getf p :x) :y (getf p :y) :vx (getf p :vx)
                             :vy (getf p :vy) :hp (getf p :hp) :data (getf p :data))))
        (setf (gethash (entity-id e) (world-entities m)) e)))
    m))
(defun save-game (mundo caminho)
  (ensure-directories-exist caminho)
  (let ((temporario (format nil "~A.tmp" caminho)))
    (with-open-file (s temporario :direction :output :if-exists :supersede
                                  :if-does-not-exist :create)
      (let ((*print-pretty* nil) (*print-readably* t))
        (print (list :antigonus-save +save-version+ :engine +engine-version+
                     :payload (mundo-para-dados mundo)) s)))
    (when (probe-file caminho) (delete-file caminho))
    (rename-file temporario caminho))
  caminho)
(defun load-game (caminho)
  (with-open-file (s caminho :direction :input)
    (let ((*read-eval* nil))
      (let ((dados (read s nil nil)))
        (unless (and (listp dados) (eql (getf dados :antigonus-save) +save-version+))
          (error "Save incompatível ou corrompido: ~A" caminho))
        (dados-para-mundo (getf dados :payload))))))
(defun autosave-game (mundo diretorio &key (slots 3))
  (let* ((indice (mod (world-tick mundo) slots))
         (caminho (merge-pathnames (format nil "autosave-~D.save" indice)
                                   (pathname diretorio))))
    (save-game mundo caminho)))

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
  (setf *mods-carregados* nil)
  (unless safe-mode
    (dolist (mod (ordenar-mods mods))
      (handler-case
          (progn (carregar-conteudo-mod mod)
                 (dolist (script (mod-manifest-scripts mod))
                   (load (merge-pathnames script (mod-manifest-path mod))))
                 (push mod *mods-carregados*)
                 (engine-log :info "Mod carregado: ~A ~A" (mod-manifest-name mod)
                             (mod-manifest-version mod)))
        (error (e) (engine-log :error "Falha no mod ~A: ~A" (mod-manifest-id mod) e)))))
  (nreverse *mods-carregados*))
(defun mod-fingerprint ()
  (format nil "~36R" (abs (sxhash (mapcar (lambda (m) (list (mod-manifest-id m)
                                                              (mod-manifest-version m)))
                                          *mods-carregados*)))))

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
    (#\! 4 4 4 4 4 0 4) (#\? 14 17 1 2 4 0 4)))
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
(defun executar-sdl ()
  (sdl2:with-init (:video :audio :gamecontroller)
    (sdl2:with-window (janela :title (game-config-title antigonus::*configuracao-atual*)
                              :w antigonus::*largura-tela* :h antigonus::*altura-tela*
                              :flags '(:shown :resizable))
      (sdl2:with-renderer (renderer janela :flags '(:accelerated :presentvsync))
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
              (ultimo (get-internal-real-time)) (acumulador 0.0)
              (passo (/ 1.0 30.0)))
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
            (:controlleraxismotion (:axis axis :value value)
              (enviar-entrada :controller-axis axis value))
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
            (:quit () t)))
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
