(asdf:defsystem "asterion-assembly"
  :description "Jogo de automação Asterion Assembly"
  :version "3.0.0"
  :license "MIT"
  :depends-on ("antigonus")
  :serial t
  :components ((:file "asterion-assembly")))

(asdf:defsystem "asterion-assembly/tests"
  :depends-on ("asterion-assembly")
  :serial t
  :components ((:file "tests/tests") (:file "tests/circuits") (:file "tests/tutorial-circuits")
               (:file "tests/controls-settings")))
