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

## API 2.0

`+engine-version+` is `2.0.0`, the save schema is `2`, and chunks are fixed at
32×32 tiles. `ensure-chunk`, `world-tile`, `set-world-tile`,
`chunk-resource-count` and `deplete-resource` expose deterministic world data.

`defitem`, `defrecipe`, `defbuilding` and `deftechnology` accept the additive
2.0 material, fluid, footprint, port, render-layer, circuit connector and tech
branch fields. Existing 1.x forms remain valid. `defsystem` additionally accepts
`:phase`, `:reads`, `:writes` and `:parallel`; parallel jobs return command
buffers that are applied in their stable input order.

Factory primitives include two-lane compact belts, volume/pressure fluid
networks, priority power networks and typed circuit signals. Rail graphs expose
geometry, blocks and stable reservations. `capture-blueprint` and
`apply-blueprint` create immediate structures or persistent construction ghosts.

Schema-1 saves are backed up before migration. Aggregated belt inventory is
distributed deterministically over two lanes and legacy shuttle trains are
marked for equivalent schedule generation.

The interactive runtime requests an OpenGL 3.3 compatibility context through
SDL2 and fixes `SDL_RENDER_DRIVER` to OpenGL with render batching enabled. A
missing OpenGL backend is a startup error; the 2.0 runtime does not silently
switch to a software or Direct3D renderer.

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
