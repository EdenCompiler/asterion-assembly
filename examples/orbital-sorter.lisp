;;;; Orbital Sorter — minijogo que usa exclusivamente a API pública Antigonus.

(defpackage #:orbital-sorter
  (:use #:cl #:antigonus)
  (:export #:register-content #:new-world #:headless-demo #:start))
(in-package #:orbital-sorter)

(defun register-content ()
  (reset-engine)
  (defitem :blue-cargo :name "Blue cargo" :stack-size 100
    :color '(75 170 240) :material-kind :cargo)
  (defitem :orange-cargo :name "Orange cargo" :stack-size 100
    :color '(240 145 61) :material-kind :cargo)
  (defbuilding :source :name "Orbital intake" :category :logistics
    :cost nil :power -4 :ports '(:item-out) :footprint '(1 . 1))
  (defbuilding :sorter :name "Cargo sorter" :category :logistics
    :cost '((:blue-cargo . 1)) :power 1 :ports '(:item-in :item-out-a :item-out-b)
    :circuit-connectors '(:red :green))
  (defbuilding :sink :name "Launch bay" :category :logistics
    :cost nil :power 0 :ports '(:item-in))
  (defsystem :orbital-sorting
      (:priority 10 :phase :simulation :reads (:inventories)
       :writes (:inventories))
      (world)
    (let ((source (building-at world 0 0))
          (sorter (building-at world 1 0))
          (sink (building-at world 2 0)))
      (when (zerop (mod (world-tick world) 15))
        (inventory-add (building-inventory source)
                       (if (evenp (world-tick world)) :blue-cargo :orange-cargo) 1))
      (dolist (item '(:blue-cargo :orange-cargo))
        (when (and (plusp (inventory-count (building-inventory source) item))
                   (inventory-remove (building-inventory source) item 1))
          (inventory-add (building-inventory sorter) item 1))
        (when (and (plusp (inventory-count (building-inventory sorter) item))
                   (inventory-remove (building-inventory sorter) item 1))
          (inventory-add (building-inventory sink) item 1)))))
  t)

(defun new-world (&key (seed 7))
  (register-content)
  (let ((world (make-world :seed seed)))
    (place-building world :source 0 0)
    (place-building world :sorter 1 0)
    (place-building world :sink 2 0)
    world))

(defun headless-demo (&optional (ticks 300))
  (let ((world (new-world)))
    (dotimes (i ticks) (simulate-tick world))
    (let ((sink (building-at world 2 0)))
      (list :blue (inventory-count (building-inventory sink) :blue-cargo)
            :orange (inventory-count (building-inventory sink) :orange-cargo)
            :hash (simulation-state-hash world)))))

(defgame *orbital-sorter*
  :title "Orbital Sorter — Antigonus 2.0"
  :width 960 :height 540)

(defun start () (run-game *orbital-sorter* :world (new-world)))
