# Changelog

## 3.0.0-dev — 2026-09-05

- Corrigido resíduo de coordenadas da fauna entre Linux e Windows; smoke nativo
  compara 120 ticks completos, não apenas circuitos estáticos.
- Erros na thread SDL são propagados ao chamador, com liberação de texturas e áudio.
- ZIP Windows com caminhos portáveis; teste Wine usa extração e prefixo novos.
- Controles persistentes de bomba/divisor/lâmpada/alarme e decisor no painel.
- Perfis seguros, resolução/fullscreen, UI 75–100% e áudio por grupos.
- Alarmes sintetizados originais; catálogo de sinais inclui conteúdo de mods.
- Testes de mouse em fullscreen e gamepad virtual pela SDL com hotplug.
- Primeira hora humana, remapeamento e seletor de saves ainda pendentes.
- Added physical red/green circuits, typed signals, separate combinator ports,
  dirty-only graph rebuilds, a port index and delayed per-device memory.
- Added stable worker buffers, canonical topology hashes and safe schema-3 saves.
- Added wire mode, magnetic ports, mouse click/drag/cut, controller commands,
  static circuit sprites, lamp/alarm states and amber/blue accessibility colors.
- First six chapter gates now require sustained behavior, with hints, material
  kits and early unlocks. Tutorial attacks are deferred until the final challenge.
- Pumps separate networks and conserve persistent local volume. Circuit filters
  control splitters/inserters; inserters no longer discard stacked belt items.
- Old saves/mods are rejected without changing their files. New saves live in
  `saves/v3/`; autosave rotation no longer depends on tick divisibility.
- Added executable headless/render smoke modes and actual framebuffer PPM readback.
- This milestone is in progress, not a public-demo acceptance. See `docs/UPGRADE-3.md`.

## 2.0.0-dev — 2026-09-04

- Added deterministic 32×32 chunks, compact resource stores and schema-2 migration.
- Added stable parallel job command buffers and canonical simulation hashing.
- Added exact two-lane belt positions with save persistence and visible congestion.
- Added working underground belts, filter splitters, loaders and stack inserters.
- Added fluid pressure, power priority/storage, typed circuit networks and blueprints.
- Added rail graphs, block reservations, schedules and deadlock-cycle reporting.
- Expanded Asterion to 70 items, 90 recipes, 52 buildings and 36 technologies.
- Added original generated industrial atlases for 16 buildings and 24 item icons.
- Added finite deposits that scale with distance and construction-drone ghost handling.
- Added a paginated static build catalog and expanded virtual rendering coverage.
- Added a responsive two-page technology interface so every one of the 36 nodes
  is selectable at supported resolutions.
- Added persistent chapter objectives, visible progress, material rewards and
  explanatory build-error notifications.
- Added a 16-prop environmental atlas with biome-aware ruins, vegetation,
  pollution damage and restoration details, plus calmer biome color grading.
- Fixed the runtime to an OpenGL 3.3 SDL driver with command batching enabled.
- Validated the self-contained Linux x64 ZIP through an isolated package smoke test.

## 1.1.0 — 2026-09-04

- Added contextual building inspection with status, power, contents and throughput.
- Added visible logistics direction overlays, actionable alerts and production counters.
- Miners now discharge directly into the building in front of them.
- Splitters now alternate deterministically between forward and clockwise outputs.
- Added continuous drag construction with automatic orientation for linear structures.
- Added a ten-second, full-refund undo for the 32 most recent constructions.
- Reworked brownouts into stable deterministic allocation without visual flicker.
- Corrected all eight protagonist facing directions and resize-related render seams.

## 1.0.0 — 2026-08-28

- Macro-driven Antigonus engine in one Lisp source file.
- Deterministic automation simulation, SDL2 renderer and bilingual UI.
- Nine-chapter campaign, procedural world, fauna, defenses and rail routing.
- Versioned saves, three rotating autosaves and trusted-code mod support.
- Portable Linux/Windows build recipes and headless test suite.
- Static unique art for all 36 buildings and 46 item icons.
- Visible item flow on belts, inserters and machine ports.
- Factorio/Mindustry-inspired build catalog, quickbar, minimap and network panel.
- Repeatable graphical playtest on an isolated X virtual display.
