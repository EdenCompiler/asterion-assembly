# Circuitos 3.0 / Circuit sprite atlas

Arquivo: `circuits-v3.png`, RGBA, 1280×1280, grade 4×4 (320 px/célula).
Gerado com a ferramenta integrada de geração de imagens; alfa preservado.
Saída original 1254×1254 normalizada para dimensão divisível por quatro.

Índices, em ordem de leitura:

0 sensor; 1 combinador aritmético; 2 decisor; 3 lâmpada apagada;
4 lâmpada âmbar; 5 lâmpada ciano; 6 alarme apagado; 7 alarme aceso;
8 terminal vermelho; 9 terminal verde; 10 terminal âmbar; 11 terminal azul;
12 fio vermelho; 13 fio verde; 14 faísca azul; 15 faísca âmbar.

Nem todo estado é configurável na UI desta etapa. Catálogos usam somente
quadros estáticos 0/1/2/3/6; estados luminosos usam 4/7 no mundo.

## Prompt final (built-in image generation)

Use case: stylized-concept. Asset type: production game sprite atlas for Asterion
Assembly circuit devices. Create an original 1024x1024 transparent PNG atlas,
EXACT 4 columns x 4 rows equal square cells, no visible grid. Each sprite entirely
inside its own cell with generous transparent margins, consistent orthographic
elevated top-down view, square bases aligned horizontally to game tiles (NOT
diamond isometric grid). Industrial sober gunmetal steel, small brass accents,
clean large silhouettes readable at 40 pixels, understated wear. TRUE TRANSPARENT
background, no text or labels, no scenery, no watermark. Row-major order: row1:
compact inventory sensor with scanning lens; arithmetic combinator box with twin
terminals and small blue display; decider combinator box with comparator display
and twin terminals; small signal lamp on steel base OFF. row2: SAME signal lamp
ON amber, SAME signal lamp ON cyan, programmable alarm siren on base OFF, SAME
alarm siren ON red. row3: red electrical socket terminal; green electrical socket
terminal; amber accessible socket terminal; blue accessible socket terminal.
row4: coiled red connecting wire; coiled green connecting wire; small blue
electrical connection spark; small amber electrical connection spark. Match scale
and view between on/off variants precisely. Only machinery/sockets/wires/sparks,
no weapons or characters.
