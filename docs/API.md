# Antigonus macro API / API de macros

The preferred authoring interface is declarative. Runtime registration
functions remain available for mods that generate content dynamically.

- `defgame NAME &rest OPTIONS` declares a `game-config`.
- `defitem`, `defrecipe`, `defbuilding`, `deftechnology` declare content.
- `defsystem NAME OPTIONS (WORLD) BODY...` declares a deterministic tick system.
- `deftranslations LANGUAGE (KEY TEXT)...` declares localized strings.
- `defanimation ID :sheet SHEET :start N :frames N :fps N` declares a
  contiguous spritesheet animation. `draw-animation` supports phase offsets,
  opacity, tint, rotation, flipping and world/camera coordinates.
- `with-world` creates a lexically scoped world.
- `with-inventory-transaction` commits only when its body returns true and
  rolls back on `nil` or an error.

Systems run by ascending `:priority`, once per 30 Hz tick. They must not use
wall-clock time or the global random generator. Use `resource-noise` with the
world seed for deterministic procedural decisions.

Visual animation uses `engine-time`, which is deliberately independent of the
30 UPS simulation clock. This keeps presentation fluid while the deterministic
world is paused or running at 2x/4x.

## Exemplo

```lisp
(register-sprite-sheet :factory "factory.png" 8 1)
(defanimation :factory-active :sheet :factory :start 0 :frames 8 :fps 10)

(defsystem :corrosion (:priority 40) (world)
  (map-buildings
    (lambda (building)
      (when (> (world-pollution world) 1000)
        (decf (building-hp building))))
    world))
```

Saves contain simple S-expressions read with `*read-eval*` disabled. Public
schemas and exported symbols use English names; source internals and comments
remain in pt-BR.
