# Antigonus + Asterion Assembly

> `upgrade/3.0`: demo de circuitos em desenvolvimento, ainda sem aceite comercial.
> API `3.0.0`, save schema `3`. Saves/mods 1/2 são recusados sem alteração.
> Veja [estado, comandos e pendências](docs/UPGRADE-3.md).

Antigonus é uma engine Common Lisp macro-dirigida para jogos 2D de automação.
Toda a engine está em [`antigonus.lisp`](antigonus.lisp); a API pública é em
inglês e o código interno é em pt-BR. Asterion Assembly é o jogo completo de
exemplo, com campanha, sandbox, logística, produção, pesquisa, fauna e trens.
O mundo usa atlas raster originais em `assets/sprites`, incluindo um atlas
estático com um sprite exclusivo para cada uma das 54 construções, biomas e
fauna, além de spritesheets animadas de 8 frames para máquinas, esteiras,
unidades e efeitos. O engenheiro humanoide possui um atlas sem armas para
repouso, caminhada, construção e manutenção; ações ofensivas ficam isoladas em
`weapons-animated.png`.
O catálogo e a barra rápida sempre usam os sprites estáticos; animações aparecem
somente nas instâncias do mundo. Os atlas de inventário contêm 70 itens exclusivos;
os itens dos inventários reais são interpolados sobre esteiras, braços e portas
de máquinas.
Uma árvore de 36 tecnologias, dividida em tronco e especializações, acessível
por `T`, usa páginas responsivas e aplica dependências, progresso e bloqueios
reais. Objetivos de campanha permanecem visíveis, antecipam recompensas e
confirmam cada avanço de capítulo. O ambiente combina terreno por bioma com
vegetação, cristais, ruínas, detritos e sinais visuais de poluição ou restauração.
`WASD` movimenta o engenheiro; botão central ou `X` dispara na
direção do cursor, com VFX determinísticos de disparo e impacto.
Construções lineares aceitam arrasto com orientação automática, `Z` desfaz a
construção recente e divisores alternam itens de forma determinística entre
duas pistas com posições exatas. O catálogo pagina os 54 edifícios sem animar
ícones. O inspetor contextual mostra energia, conteúdo, receita e taxa sem
interromper a simulação.
Primitivas geométricas ficam restritas à interface, sombras, depuração e
fallback da engine.

## Executar

Requisitos de desenvolvimento: SBCL, Quicklisp e SDL2.

```sh
make test
make playtest
make run
make package-linux
```

Use `sbcl --script run.lisp pt 1701` para jogar em português com uma seed
específica. No executável, `--pt` seleciona português e `--safe-mode` desativa
todos os mods.

## Macro DSL

```lisp
(antigonus:defitem :ore :name "Ore" :stack-size 200)
(antigonus:defrecipe :plate :inputs '((:ore . 1))
  :outputs '((:plate . 1)) :duration 30)
(antigonus:defsystem :weather (:priority 20) (world)
  (incf (antigonus:world-pollution world) 0.01))
(antigonus:defanimation :factory-active :sheet :factory
  :start 0 :frames 8 :fps 10)
(antigonus:defgame *game* :title "My Factory" :update #'update)
```

Documentação: [manual](docs/MANUAL.md), [API](docs/API.md) e
[mods](docs/MODDING.md).

## English

Antigonus is a macro-driven Common Lisp engine for 2D automation games. Its
entire engine source is `antigonus.lisp`; public API names are English while
the implementation is Brazilian Portuguese. Run `make test` before packaging.

Code and data are MIT licensed. The product name/logo are excluded as marks;
see `TRADEMARK.md`.
