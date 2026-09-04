((:type :item :id :luminous-bearing :name "Luminous bearing" :stack-size 200
  :color (98 255 222) :description "An example item supplied by a declarative mod.")
 (:type :recipe :id :luminous-bearing-recipe
  :inputs ((:gear . 1) (:asterion-crystal . 1))
  :outputs ((:luminous-bearing . 2)) :duration 45 :category :crafting)
 (:type :building :id :luminous-belt :name "Luminous belt" :category :logistics
  :cost ((:belt-part . 2) (:luminous-bearing . 1)) :power 1 :color (77 244 214)))
