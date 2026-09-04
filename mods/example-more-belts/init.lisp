;;;; Scripts de mods são código Lisp confiável e usam apenas a API em inglês.
(in-package #:cl-user)
(antigonus:on-event :building-placed
  (lambda (world building)
    (declare (ignore world))
    (when (eq (antigonus:building-kind building) :luminous-belt)
      (antigonus:engine-log :info "Uma esteira luminosa foi construída."))))
