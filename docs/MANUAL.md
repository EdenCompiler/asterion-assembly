# Asterion Assembly — Manual / Manual do jogador

## Objective / Objetivo

Build a self-sufficient factory, research military logistics, locate the hive
at the end of the nine chapters and destroy it. The world remains playable as
a sandbox after victory.

Construa uma fábrica autossuficiente, pesquise logística militar, localize a
colmeia ao final dos nove capítulos e destrua-a. O mundo continua como sandbox.

## Controls / Controles

- WASD: move the humanoid engineer / move o engenheiro humanoide
- Left click or drag: build; belts, pipes, rails, walls and poles fill every
  crossed cell and orient automatically / clique ou arraste para construir;
  esteiras, tubos, trilhos, muros e postes preenchem todas as células e giram
  automaticamente
- Right click: remove and refund 75% / remover e recuperar 75%
- Z: undo the most recent construction made in the last 10 seconds, with full
  refund / desfazer a construção mais recente dos últimos 10 segundos, com
  reembolso integral
- Middle click or X: fire toward the cursor / disparar na direção do cursor
- Q/E or controller shoulders: cycle buildings / trocar construção
- R: rotate / girar
- F: cycle machine recipe / trocar receita da máquina
- Mouse wheel: zoom
- Space or controller Start: pause
- F1/F2/F3: 1×, 2× and 4× simulation
- I or controller R3: building inventory; insert/take up to 10 items per action /
  inventário da construção sob o cursor; inserir/retirar até 10 itens por ação
- H: help overlay / ajuda
- B: toggle build catalog and sector minimap / catálogo e minimapa
- T: technology tree / árvore tecnológica
- Tab: production network panel / painel da rede de produção
- Hover a building: inspect status, power, contents, recipe and throughput /
  passe o cursor sobre uma construção para inspecionar estado, energia,
  conteúdo, receita e taxa

Miners extract the resource under them and output directly into the building
in front; without a receiver, they buffer the result. Inserters take from the
opposite side and place in their facing direction. Belts follow their arrow.
Splitters alternate items between their forward output and clockwise branch,
falling back to either available output when one side is disconnected.
Hovering logistics highlights visible flow directions. Configure a machine
recipe with F before placing it. Items delivered to the core enter the
construction inventory.

Every transported item is visible on belts, in the inserter arc and at active
machine ports. These icons reflect the real simulated inventories rather than
decorative particles.

Mineradoras extraem o recurso sob elas e descarregam diretamente na construção
à frente; sem receptor, guardam o resultado. Braços retiram do lado oposto e
colocam na direção da seta. Passar o cursor sobre a logística destaca as
direções do fluxo visível. Divisores alternam itens entre a saída frontal e o
ramal horário, usando a saída disponível quando a outra estiver desconectada.
Selecione a receita com F antes de posicionar uma máquina. Itens entregues ao
núcleo entram no inventário de construção.

Cada item transportado aparece nas esteiras, no arco dos braços e nas portas
das máquinas; os ícones representam os inventários reais da simulação.

The top power bar shows demand, capacity and satisfaction. High-contrast alert
rows identify power deficits, dry miners and blocked belt outputs. The Tab
panel tracks mined, crafted and moved items. Under overload, power allocation
remains deterministic and unpowered buildings stay visibly offline.

A barra superior mostra demanda, capacidade e satisfação energética. Alertas
de alto contraste identificam déficit de energia, mineradoras sem recurso e
saídas de esteira bloqueadas. O painel Tab registra itens minerados, produzidos
e movidos. Em sobrecarga, a distribuição permanece determinística e prédios
sem energia ficam visivelmente desligados.

Four difficulties are recognized: `peaceful`, `explorer`, `standard` and
`hostile`. Losing the engineer is recoverable; losing the core warns the
player to load the latest rotating autosave.
# Demo de circuitos 3.0 / Circuit demo

A primeira sequência possui seis desafios funcionais; manter o sistema correto
por seis segundos preenche a barra. Sensor olha a construção à sua frente (seta).
Use `C` para fios e o painel de configurações. Combinadores têm portas de entrada
e saída separadas. `X` troca cor; botão direito corta uma conexão.
Os guias contextuais explicam cada montagem. Ataques começam apenas depois do
desafio de contador; dificuldade pacífica continua sem combate.

The six initial challenges check sustained operation, not building counts.
Sensors read the building in front of their arrow. Press `C` for wiring, `X` for
wire color; right-click cuts a connection. Combinators separate input/output
ports. Context guides explain each setup. Combat is deferred until the counter
challenge; peaceful mode remains combat-free.

Saves novos / new saves: `saves/v3/`. Saves anteriores são incompatíveis e
permanecem intactos / older saves are incompatible and remain unchanged.
Controles completos e limitações atuais: [UPGRADE-3.md](UPGRADE-3.md).

## Configurações e atuadores / Settings and actuators

Menu Configurações: resolução da janela, fullscreen desktop, escala UI
75/90/100%, idioma, volume mestre/efeitos/alertas, redução de flashes e paleta
para daltonismo. “Testar alerta” permite conferir o volume sem iniciar combate.
As escolhas persistem em `saves/v3/profiles/default.sexp`. Um perfil inválido
fica preservado; a mensagem de erro não significa que ele foi substituído.
Não há tremor de câmera implementado nesta etapa.

No painel de circuitos, `Tab` ou os ombros do gamepad alternam Lógica/Controles.
A segunda aba regula bombas, prioridade de divisores, brilho/cor das lâmpadas,
alarmes e cópia de contagem. Comparar com outro sinal substitui a constante;
selecione “constante” novamente para voltar ao limite numérico.

Settings persist window resolution, desktop fullscreen, UI scale, language,
master/effects/alerts volume, reduced flashes and colorblind palette. Use Preview
Alert to check audio safely. `Tab` or controller shoulders switch Logic/Controls
in the circuit panel. Pump direction, splitter priority, lamps, alarms and
decider copy-count are configurable without text entry. Selecting a comparison
signal uses its current value instead of the constant threshold.

## Remapeamento, perfis e saves / Bindings, profiles and saves

Em **Configurações → Controles**, selecione uma ação e pressione a nova tecla,
botão de gamepad ou botão do mouse. Entradas em conflito são trocadas, nunca
duplicadas. Eixos podem trocar de função e ser invertidos. `Esc` permanece
reservado para cancelar/voltar e Enter do teclado numérico confirma, mesmo
após remapear a confirmação normal. Use PageUp/PageDown, roda ou ombros para
paginar as listas. A ajuda principal acompanha os controles escolhidos;
diagramas antigos ainda descrevem os atalhos padrão.

**Configurações → Perfis** cria uma cópia das preferências atuais e permite
selecionar perfis existentes. O último perfil escolhido é restaurado ao abrir
o jogo; `ASTERION_PROFILE` tem prioridade na inicialização. Nomes gerados são
`profile-001`, `profile-002`, etc. Perfis guardam preferências, não mundos
separados: os saves da pasta são compartilhados. Arquivos inválidos são
preservados, com erro na interface, sem aplicação parcial das preferências.

**Continuar** abre a lista de saves manuais, quicksave e três autosaves
rotativos. **Pausa → Salvar** cria `manual-001.save`, etc., ou oferece
sobrescrita de um arquivo existente, com **Cancelar selecionado por padrão**.
Uma sobrescrita guarda a versão anterior em `.bak`. Saves de schemas antigos
continuam bloqueados. Voltar ao menu principal também mantém o quicksave
automático; isso não substitui um save manual.

No inventário (`I` / R3), a primeira linha troca entre inserir e retirar.
As transferências pausam o jogo, respeitam o alcance do personagem e não criam
itens. O inventário mostra o buffer da construção, não retira diretamente
itens já presentes nas pistas de uma esteira. Há água perto da base em mundos
novos e o kit do desafio de contador inclui cobre para a lâmpada.

**Settings → Controls** captures keyboard, controller and mouse bindings, swaps
conflicts and supports axis swaps/inversion. Escape always cancels; keypad Enter
is an emergency confirm. PageUp/PageDown, wheel or shoulders change pages. Main
help reflects bindings; older diagrams still show defaults.

**Settings → Profiles** copies current preferences or activates an existing
profile. The last selection persists; `ASTERION_PROFILE` overrides it at startup.
Profiles share the save folder. **Continue** selects a manual/quick/rotating save;
**Pause → Save** creates a numbered manual save or asks before overwriting, with
Cancel focused by default. Previous files are kept as `.bak`; incompatible saves
are never overwritten. Returning to the main menu still writes the quicksave.

Point at a nearby building and press `I` / R3 to insert or take up to 10 items
per action while paused. The first row changes transfer direction. This accesses
the building buffer, not belt lanes. New worlds guarantee nearby water; the
counter reward kit supplies copper wire for the lamp.
