---
name: skhd-clients
description: Adicionar, remover ou modificar clientes no modo leader "clients" do skhd. Mantém `skhd/.config/skhd/skhdrc`, a cheatsheet em `README.md` e os cards em `anki/dotfiles-toolbox.txt` em sincronia; no fim faz commit, push e abre um PR. Use quando o utilizador disser "adicionar cliente", "alterar cliente", "remover cliente", "novo URL de Mello/Winestone/Lidl/...", ou correr `/skhd-clients` explicitamente.
allowed-tools: Read, Edit, Grep, Glob, Bash, AskUserQuestion, mcp__github__create_pull_request
---

# skhd-clients

Skill interactiva para gerir o modo `clients` do skhd. O modo
organiza-se em dois níveis: clientes (bindings directos em `clients <
k>` ou transições `clients < k ; <sub>`) e, para clientes com mais de
um ambiente, sub-modos com as variantes (prod/qual, external/internal,
etc.).

## Ficheiros-fonte

- **`skhd/.config/skhd/skhdrc`** — verdade sobre o que existe.
  - Linha `:: clients @ : echo "clients|…" > /tmp/skhd-mode` — cheatsheet do HUD.
  - Linhas `:: <sub> @ : echo "clients › <sub>|…" > /tmp/skhd-mode` — cheatsheet de cada sub-modo.
  - Bloco `# --- Modo clients …` contém `clients < <k> …` e, por baixo, os grupos `<sub> < <k> …` + `<sub> < escape ; default`.
- **`README.md`** — bloco `# Leader "clients"` com linhas `K → …`.
- **`anki/dotfiles-toolbox.txt`** — cards `sk*` com tag `skhd shortcuts` que referenciam cada cliente.

## Fluxo obrigatório

1. **Ler e parsear o estado actual** de `skhd/.config/skhd/skhdrc`:
   - Extrair cada `clients < <k> …`:
     - Se termina em `; <sub>` → cliente com sub-modo `<sub>`.
     - Se termina em `: open "<url>"; skhd -k "escape"` → cliente directo.
   - Para cada sub-modo, ler a declaração `:: <sub> @ : echo "…"` e
     todas as linhas `<sub> < <k> …` (menos o `<sub> < escape ; default`).
   - Do `:: clients @ : echo "clients|<Nome> (<k>) | … | sair (esc)"` extrair o nome de display de cada cliente.

2. **Apresentar uma tabela compacta** ao utilizador:
   ```
   key  cliente      tipo       URL(s)
   m    Mello        sub-modo   p Produção  → https://mdados.cultofbits.com
                                q Qualidade → https://mdados-qual.cultofbits.com
   r    Rentelecom   directo    https://rentelecom.cultofbits.com
   …
   ```

3. **Perguntar a acção** com `AskUserQuestion`:
   - "Adicionar cliente" / "Alterar cliente" / "Remover cliente".

4. **Recolher dados** conforme a acção (usa `AskUserQuestion` sempre que tenha opções discretas; pede texto livre apenas para nomes/URLs):
   - **Adicionar**:
     - Nome de display (ex.: "Acme").
     - Letra-chave (letra minúscula, validar que não colide com as
       existentes). Sugerir a 1ª letra do nome; se estiver tomada,
       propor alternativas.
     - Número de URLs: 1 → directo; 2+ → sub-modo.
     - Se directo: 1 URL.
     - Se sub-modo: nome interno do modo (lowercase, ex.: `acme`;
       não pode colidir com `default`/`cob`/`personal`/`clients` nem
       com sub-modos existentes); para cada variante, pedir
       `(Label, key, URL)` (ex.: `Produção, p, https://…`).
   - **Alterar**: listar clientes, perguntar qual; depois perguntar o
     que mudar (renomear, re-tecla, editar URL/label, adicionar URL,
     remover URL). Regras:
     - 1→2 URLs promove directo → sub-modo. Perguntar o nome do
       sub-modo (default: cliente lowercased).
     - 2→1 URL demove sub-modo → directo. Confirmar antes de apagar a
       declaração `:: <sub> @`.
   - **Remover**: listar clientes, perguntar qual, confirmar.

5. **Validar**:
   - Letra-chave em `clients`: 1 letra minúscula (`[a-z]`), única entre
     as `clients < …` existentes.
   - Letra-chave em sub-modo: 1 letra minúscula, única no sub-modo,
     não pode ser `escape`.
   - Nome do sub-modo: `[a-z][a-z0-9]*`, não colide com modos
     existentes.
   - URL: string não vazia, sem whitespace interno nos extremos.

6. **Aplicar edições** — editar os 3 ficheiros com Edit.

   **`skhd/.config/skhd/skhdrc`**:
   - Regenerar a linha `:: clients @ : echo "clients|<N1> (<k1>) | <N2> (<k2>) | … | sair (esc)"` com todos os clientes (ordem: preservar ordem actual; novos vão para o fim).
   - Para cada sub-modo adicionado, inserir uma linha
     `:: <sub> @ : echo "clients › <sub>|<L1> (<k1>) | … | sair (esc)"`
     imediatamente a seguir às `::` existentes dos outros sub-modos.
   - Para cada sub-modo removido, apagar a linha `::` correspondente.
   - No bloco `# --- Modo clients`, actualizar as linhas `clients < <k> …`:
     - Directo: `clients < <k> : open "<url>"; skhd -k "escape"`.
     - Sub-modo: `clients < <k> ; <sub>`.
   - Adicionar/remover o grupo do sub-modo:
     ```
     <sub> < <k1> : open "<url1>"; skhd -k "escape"
     <sub> < <k2> : open "<url2>"; skhd -k "escape"
     <sub> < escape ; default
     ```
   - Se o cliente tocado aparece no comentário-cabeçalho (linhas 13–16,
     "leader do modo clients"), actualizar a descrição para reflectir
     a nova composição (apenas a frase das variantes, sem refazer todo
     o cabeçalho).

   **`README.md`**, bloco `# Leader "clients"`:
   - Regenerar as linhas `K → <LETRA>` (directo) ou
     `K → <LETRA> → <LETRA>` (sub-modo), uma por URL final, com
     comentário `# <Cliente> <Variante>`.

   **`anki/dotfiles-toolbox.txt`**:
   - Cards existentes: editar a resposta em-local (preservar GUID).
   - Clientes removidos: apagar a linha do card.
   - Clientes adicionados: acrescentar 1 card com GUID novo no padrão
     `sk` + 8 caracteres alfanuméricos (mix `[a-zA-Z0-9]`). Garantir
     unicidade em todo o ficheiro (Grep pelo prefixo antes de escolher).
     Formato de pergunta/resposta do card espelha os existentes, e.g.:
     ```
     <GUID>\tskhd clients: como abrir <Cliente> <V1> vs <V2>?\tK → <K> → <k1> (<V1>) ou K → <K> → <k2> (<V2>)\tskhd shortcuts
     ```
     ou (directo):
     ```
     <GUID>\tskhd clients: como abrir <Cliente>?\tK → <K> (directo; <url>)\tskhd shortcuts
     ```

7. **Commit + push + PR**:
   - Staging selectivo: só os 3 ficheiros editados, com
     `git add <paths>` (nunca `-A`).
   - Mensagem de commit descritiva, ex.:
     - `skhd clients: add <Nome>`
     - `skhd clients: rename <Velho> → <Novo>`
     - `skhd clients: add URL <Variante> to <Nome>`
     - `skhd clients: remove <Nome>`
   - Push: `git push -u origin $(git branch --show-current)`. Retry
     até 4× em falhas de rede (2s, 4s, 8s, 16s).
   - PR: usar `mcp__github__create_pull_request` (gh CLI não está
     disponível). Título curto igual ao summary do commit; corpo com
     1–3 bullets de Summary e uma checklist mínima de Test plan (ex.:
     `skhd --restart-service`, premir `Ctrl+Alt+Cmd+K`, verificar HUD).
     Devolver o URL do PR ao utilizador.

8. **Lembrete final** ao utilizador:
   ```
   Para aplicar localmente:
     skhd --restart-service
     (e refresh do Übersicht se a cheatsheet do HUD mudou)
   ```

## Regras invioláveis (padrões já presentes no skhdrc)

- **NÃO** usar `: cmd ; default` — o parser do skhd trata tudo a seguir
  a `:` como shell. Sair de modo faz-se por `; skhd -k "escape"` no
  fim da shell, que dispara o binding `<sub> < escape ; default`.
- **TODO** sub-modo tem obrigatoriamente uma linha
  `<sub> < escape ; default`.
- O HUD é escrito na declaração do modo via
  `:: <mode> @ : echo "<mode>|…" > /tmp/skhd-mode`; não mexer no
  widget `skhd-hud.widget`.

## Robustez

- Se o skhdrc tiver um estado inesperado (ex.: sub-modo órfão, binding
  duplicado), **parar e reportar** ao utilizador em vez de corrigir
  silenciosamente.
- Se o utilizador cancelar a meio (AskUserQuestion sem resposta), não
  aplicar parciais — abortar sem tocar nos ficheiros.
- Se `git push` falhar persistentemente (após 4 retries), **não**
  tentar forçar; reportar o erro e deixar o commit local.
