# Modding Asterion Assembly

Create a folder below `mods/` with `manifest.sexp`. Metadata and declarative
content are safely read without evaluation. Optional Lisp scripts are trusted
native code and can access the same machine and files as the game.

Crie uma pasta sob `mods/` com `manifest.sexp`. Metadados e conteúdo declarativo
são lidos sem avaliação. Scripts Lisp opcionais são código nativo confiável.

```lisp
(:id :my-mod :name "My mod" :version "1.0.0"
 :engine-version "3.0.0" :dependencies nil :conflicts nil
 :enabled t :content ("content.sexp") :scripts ("init.lisp"))
```

Content entries use the English `:type`, `:id`, `:inputs`, `:outputs`,
`:duration`, `:category`, `:cost`, `:power` and `:color` schema. Dependencies
are topologically ordered; missing dependencies and cycles abort the affected
load. Enabled mod IDs and versions form the save fingerprint. Use `--safe-mode`
to skip every mod. Changes require restarting the game.

See `mods/example-more-belts` for a working data-and-script mod.

## Ruptura 3.0 / Breaking change

Somente versões de API 3.x com três componentes são aceitas. Manifestos 1/2
são desativados e relatados por `mod-errors`, sem editar os arquivos.
Dependentes de mods recusados também não carregam. Falhas de resolução
desativam o conjunto de mods nessa execução. `--safe-mode` ignora todos.
Scripts são código confiável, **sem sandbox**; mudanças exigem reinício.

Only three-part API 3.x versions are accepted. Old manifests are disabled for
the run, not rewritten. Rejected dependencies do not load. Resolution failures
disable the mod set for the run. There are no 1/2 compatibility adapters.
