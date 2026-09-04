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
