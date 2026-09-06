# Antigonus 3.0 — estado do marco / milestone status

Desenvolvido em `upgrade/3.0`, integrado em `main` nesta etapa a pedido do usuário.
API `3.0.0`, save schema `3`.
Versão de desenvolvimento; não é uma declaração de aceite da demo pública.

## Entregue nesta etapa

- Grafos vermelhos/verdes independentes, portas físicas, nove tiles de alcance,
  custo e reembolso pelo jogo, componentes determinísticos e índice de portas.
- Combinadores aritméticos/decisores, sinais tipados, memória de um tick salva
  por emissor, buffers privados em workers e aplicação em ordem estável.
- Modo `C`, seleção magnética, clique/arrasto para ligar, corte sob o cursor,
  painel sem digitação, sinais ao vivo, fios sólidos/tracejados e paleta âmbar/azul.
- Novo atlas original `assets/sprites/circuits-v3.png`, 4×4, 1280×1280 RGBA.
  Sensor, dois combinadores, lâmpada, alarme e terminais têm sprites próprios.
  Estados luminosos são exclusivos do mundo; catálogo/barra continuam estáticos.
- Seis desafios com seis segundos de evidência sustentada: extração/transporte,
  energia/produção, estoque/braço, filtragem, tanque/bomba e contador/alarme.
  Kits e desbloqueios ensinam a próxima etapa, com diagramas e instruções PT/EN.
- Bombas separam redes, transferem volume e respondem à habilitação por circuito.
  Fluido local persistente conserva volume na reconstrução e no save.
- Filtros de braços/divisores; habilitação de máquinas; estado de lâmpada/alarme.
- Aba de controles com direção da bomba, prioridade de saída do divisor,
  quatro cores e brilho 0–100% para lâmpadas, som/mensagem do alarme,
  cópia de contagem do decisor e comparação entre dois sinais.
  Prioridade permite overflow quando não existe filtro; filtro nunca vaza para
  uma saída incompatível. Todos os campos são validados, copiados e persistidos.
- Configurações de idioma, resolução, fullscreen desktop, UI 75/90/100%,
  volume mestre, efeitos e alertas separados, redução de flashes e daltonismo.
  Perfis S-expression com leitura sem avaliação e gravação temporária/rename.
  Perfil inválido é preservado e não pode ser sobrescrito silenciosamente.
- API/save 3 recusa versões anteriores. Saves novos: `saves/v3/`.
  `ASTERION_SAVE_DIR` seleciona outra pasta. Testes têm saves isolados.
- Executável: `--headless-smoke` e `--render-smoke`, este último produzindo
  `circuit-smoke.ppm` por readback real. CI configurada para testar ZIPs Linux/Windows.

## Controles de circuitos

Mouse/teclado: `C` abre/fecha; `X` troca cor; clique em origem/destino ou arraste;
botão direito corta o fio próximo. No combinador, entrada é a porta esquerda e
saída a direita. Saída ligada à própria entrada cria realimentação.
Clique nos cartões do painel para ciclar os valores. Constante: faixas
esquerda/direita correspondem a −10, −1, +1, +10. Cabeçalho alterna a paleta.
`Tab` ou clique na faixa LOGICA/CONTROLES alterna a aba. O catálogo de sinais
inclui itens registrados por mods. Alarmes oferecem mensagens predefinidas PT/EN
(circuito, estoque baixo, tanque cheio, energia baixa), sem digitação.

Gamepad: `Y` abre/fecha; analógico direito move o cursor; `A` seleciona porta
ou edita o campo quando o cursor está no painel; `X` troca cor; `B` cancela.
Ombros alternam abas; direcional cima/baixo edita; esquerda seleciona o próximo
campo quando o cursor está no painel e corta fio quando está no mundo;
direita alterna paleta. Analógico esquerdo move o personagem.

## Evidências locais

- `make test`: 322 verificações, incluindo os seis desafios nas quatro
  dificuldades, casos negativos, conservação da bomba e eventos de gamepad.
- Playtests: oito telas de menu, 27 capturas gerais, cinco de circuitos,
  três de configurações e um readback de gamepad SDL (44 imagens).
  Resolução 1600×900, fullscreen 1920×1080, UI 90%, volumes e perfil foram
  exercitados por mouse real em X virtual com Openbox.
- Gamepad virtual conectado pela SDL: botões, fio, abas, cor/brilho da lâmpada,
  eixo do cursor e desconexão com eixos zerados. Não apenas chamadas à API de entrada.
- Benchmark isolado: 5.000 dispositivos, 10.000 fios, 1.000 combinadores;
  16,53 ms/tick (60,5 UPS) neste computador na verificação final local. Não equivale ao desempenho do
  jogo inteiro nem ao teste de megabase com renderização.
- Smoke do ZIP Linux executado localmente e na CI.
- [CI nativa aprovada em 06/09/2026](https://github.com/EdenCompiler/asterion-assembly/actions/runs/34022245281):
  Linux, Windows Server 2022 e comparação de hashes. Windows executou o ZIP,
  produziu readback 1280×720 em OpenGL 4.6/Mesa e encerrou normalmente.
  Mesa é driver de teste do runner, não faz parte do ZIP distribuído.
- O mesmo ZIP Windows (`62d9ce5`) passou no Wine 10, com extração e prefixo
  novos, display virtual, simulação, persistência e readback OpenGL 4.5.
- Linux/Windows nativos produziram o hash `72846DB4265264D3` após 120 ticks
  na execução CI `34022245281`. Coordenadas da fauna usam grade de 1/65536 tile
  para eliminar resíduos diferentes das funções trigonométricas nativas.
- Falha deliberada na thread SDL chega ao chamador; texturas/áudio são liberados
  durante o unwind e uma segunda janela consegue recriar os recursos.
- Backend OpenGL confirmado pela SDL e pela versão real do contexto, não apenas
  por um hint. Um contexto 2.1 forçado foi recusado com diagnóstico e saída 1.
  No Windows, drivers WGL externos ficam carregados até o fim do processo;
  janelas, contextos e recursos gráficos continuam sendo liberados normalmente.
- CI Windows passou 134 verificações, incluindo os seis desafios nas quatro
  dificuldades e controles/perfis; preserva logs/readback e rejeita captura
  vazia além de conferir assinatura e dimensões.

Reproduzir:

```sh
make test
make playtest
sbcl --script tests/circuit-benchmark.lisp
make smoke-package
xvfb-run -a bash tests/package-smoke-wine.sh /caminho/asterion-assembly-windows-x64.zip
```

O teste de fullscreen requer Openbox em `PATH` (ou caminho absoluto em
`ASTERION_TEST_WM`) dentro do X virtual. Não usa o display do jogador.
Preferências: `saves/v3/profiles/default.sexp`; `ASTERION_PROFILE` seleciona
outro perfil (letras ASCII, números, hífen e sublinhado). Não há seletor de
perfis na interface nesta etapa. Fullscreen usa a resolução do desktop;
a resolução escolhida é usada ao voltar ao modo janela.

## Ainda necessário antes de fechar 3.0

- Playtest completo da primeira hora por teclado/mouse e apenas gamepad;
  calibrar duração, economia e instruções. Os testes automatizados montam
  cenários via API e não comprovam uma campanha humana de uma hora.
- Melhorar a seleção de sinais com busca visual/paginação; o ciclo atual inclui
  todo o catálogo, mas ainda é trabalhoso para grandes conjuntos de mods.
- Completar remapeamento de teclado/gamepad, seletor de perfis, seleção de saves
  e confirmação explícita de sobrescrita. UI acima de 100% exige reflow dos
  painéis antigos. Música/ambiente e opções adicionais de acessibilidade seguem pendentes.
- Ampliar sensores/testes, erros de mods, combinações incompatíveis e recuperação
  automática de gravação interrompida; `.bak` atualmente oferece cópia anterior.
- Validar gamepads físicos, mais resoluções e ausência de flicker em sessões longas.
- Testar instalações de jogador Windows 10/11 e drivers de GPU físicos: o runner
  Server 2022 com Mesa e o Wine não substituem essa matriz. Atualizar texto de
  loja e apresentação final sem prometer itens ainda não validados.

## English summary

This is a development milestone, not a release acceptance. Physical circuits,
delayed combinators, wire UI, circuit sprites, six sustained tutorial gates and
packaged smoke commands are implemented. Old saves/mods are intentionally
rejected, never migrated or overwritten. New saves use `saves/v3/`.
Local automated checks are not a substitute for the full first-hour mouse and
controller playthroughs. Actuator controls, persisted display/audio profiles and
real SDL virtual-controller tests are now implemented. Linux and native Windows
Server 2022 CI passed, including packaged OpenGL readback and matching simulation
hashes. Consumer Windows/GPU coverage, remapping, save/profile pickers and
commercial polish still require completion.
