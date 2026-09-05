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

## API 3.0

Display/audio additions: `(set-display-mode width height :fullscreen t :ui-scale 9/10)`
uses desktop fullscreen (the selected resolution is retained for windowed mode).
UI scales are supported from 75% to 100%, preserving the game's minimum logical
viewport. `(register-sound id path :bus :alerts)` assigns one of `:effects`,
`:alerts`, `:ambient`, `:music`. `set-audio-bus-volume` / `audio-bus-volume`
use 0–128, multiplied by the master `set-audio-volume`.

Vídeo/áudio: fullscreen usa a resolução do desktop. A escala lógica mantém os
cliques SDL alinhados à UI. Grupos de áudio são multiplicados pelo mestre;
volume zero dos efeitos não silencia alertas de outro grupo.

Additional `make-circuit-device-config` fields (all have exported accessors):

| Field | Accepted values / valores |
| --- | --- |
| `:pump-direction` | `:forward`, `:reverse` |
| `:output-priority` | `:balanced`, `:first`, `:second` |
| `:lamp-color` | `:amber`, `:blue`, `:red`, `:green` |
| `:lamp-intensity` | Integer 0–100 |
| `:alarm-sound` | `:silent`, `:warning`, `:critical` |
| `:alarm-message` | `:circuit-alert`, `:low-stock`, `:tank-full`, `:power-low` |
| `:copy-count` | `nil`, `t` |

`configure-circuit-device` validates before storing an independent copy. The
game applies these fields while the device has a circuit connection. A splitter
prefers the selected output and overflows only when no item filter is set.
With a filter, matching items go exclusively to the preferred output (first
when balanced), and other items to the opposite output. Disconnecting restores
normal forward/balanced operation. Alarms trigger on a rising condition, with
a 90-tick cooldown; message IDs are localized by the game, not free-form text.

Os campos são copiados e salvos. Divisores com filtro não desviam itens para a
saída incompatível; bombas desconectadas voltam à direção normal. A lâmpada só
usa sprites luminosos no mundo, nunca no catálogo. Alarme emite som/mensagem na
borda de ativação, com intervalo mínimo de 90 ticks.

`+engine-version+` is `3.0.0`, the save schema is `3`, and chunks are fixed at
32×32 tiles. `ensure-chunk`, `world-tile`, `set-world-tile`,
`chunk-resource-count` and `deplete-resource` expose deterministic world data.

`defitem`, `defrecipe`, `defbuilding` and `deftechnology` accept the additive
2.0 material, fluid, footprint, port, render-layer, circuit connector and tech
branch fields. Mods must explicitly target API 3. `defsystem` additionally accepts
`:phase`, `:reads`, `:writes` and `:parallel`; parallel jobs return command
buffers that are applied in their stable input order.

Factory primitives include two-lane compact belts, volume/pressure fluid
networks, priority power networks and typed circuit signals. Rail graphs expose
geometry, blocks and stable reservations. `capture-blueprint` and
`apply-blueprint` create immediate structures or persistent construction ghosts.

Schema-1/2 saves are rejected without migration or overwrite. Schema-3 writes
use a temporary file and retain the previous generation in `.bak`.

Physical circuit APIs: `connect-circuit`, `disconnect-circuit`,
`circuit-connections`, `circuit-network-for-port`, `rebuild-circuit-networks`,
`configure-circuit-device`, `read-circuit-signal`. Public types:
`circuit-port`, `circuit-wire`, `circuit-condition`, `circuit-device-config`,
`circuit-network`; constructors and accessors use these English names.

Signals are `(:item ID)`, `(:fluid ID)`, `(:virtual ID)` with integer values.
`defbuilding` accepts `:circuit-ports` and `:circuit-behavior`. Combinators in
Asterion have `:input` and `:output`; other circuit devices use `:main`.

```lisp
(connect-circuit world sensor combinator :port-b :input :color :red)
(connect-circuit world combinator lamp :port-a :output :color :green)
(configure-circuit-device combinator
  (make-circuit-device-config
    :behavior :arithmetic :input-signal '(:item :iron-plate)
    :operator :/ :constant 10 :output-signal '(:virtual :signal-a)))
```

`connect-circuit` returns `(values wire created-p)`, validates ports and a
nine-tile range. Duplicates return the existing wire. `disconnect-circuit`
returns the removed wire or `nil`. The game, not the topology API, handles
wire material cost/refund. Separate ports of one device allow feedback.
`circuit-network-for-port WORLD BUILDING &optional PORT COLOR` returns a list
of independent components. Network IDs derive from color and sorted ports.

Asterion snapshots sensors and previous combinator outputs, evaluates private
worker buffers, and commits them in building-ID order. Combinator output is
visible next tick. Red/green can be summed at a device input but do not become
one physical network. Memory belongs to emitters and survives rewiring/saves.
Arithmetic: `+ - * / mod min max`; division/modulo by zero produce zero.
Comparators: `< <= = != >= >`; selectors: `each`, `anything`, `everything`.
Empty `everything` is false in this implementation. Asterion's sensor and
actuator behavior lives in the game; declaring a building alone does not simulate it.

`capture-renderer PATH` writes an RGB8 PPM framebuffer during rendering, before
present. `loaded-mods` and `mod-errors` expose runtime status/diagnostics.

PT-BR: saves/manifestos antigos não têm adaptadores. O chamador deve cobrar
fio somente quando `created-p` for verdadeiro e reembolsar somente quando
`disconnect-circuit` retornar um fio. A configuração é validada e copiada
independentemente, sem compartilhar estruturas mutáveis entre dispositivos.

The interactive runtime requests an OpenGL 3.3 compatibility context through
SDL2 and fixes `SDL_RENDER_DRIVER` to OpenGL with render batching enabled. A
missing OpenGL backend is a startup error; the runtime does not silently
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
