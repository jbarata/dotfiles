# Dotfiles

Configurações centralizadas para macOS (iMac Intel + MacBook M3), geridas com [GNU Stow](https://www.gnu.org/software/stow/) e sincronizadas via git.

---

## Índice

- [Uso](#uso)
- [Instalação](#instalação)
- [Manutenção](#manutenção)
- [Estrutura](#estrutura)
- [Decisões](#decisões)

---

## Uso

### Sync diário

```bash
ds              # dotfiles status
da              # dotfiles add -p (stage interativo)
dc -m "msg"     # dotfiles commit
dp              # dotfiles push
dl              # dotfiles pull (na outra máquina)
```

### fzf — Fuzzy finder

```bash
Ctrl+R          # pesquisa fuzzy no histórico
Ctrl+T          # pesquisa fuzzy de ficheiros (insere path)
Alt+C           # pesquisa fuzzy de directórias (cd) — usa cache 24h
fzf-refresh     # forçar actualização da cache Alt+C
```

### Vim — Leader = `,`

```bash
,n      # limpar highlight de pesquisa
,w      # save
,q      # quit
,l      # toggle line numbers
gcc     # comentar linha (vim-commentary)
cs"'    # mudar "x" para 'x' (vim-surround)
:Git    # git integration (vim-fugitive)
```

### Ghostty — Terminal

```bash
Cmd+T               # novo tab
Cmd+Shift+Left/Right # tab anterior/seguinte
Cmd+1, Cmd+2, ...   # tab específico
Cmd+D / Cmd+Shift+D # split horizontal/vertical
Cmd+Alt+setas       # navegar entre splits
Cmd+Shift+Alt+setas # redimensionar split
Cmd+W               # fechar tab/split
Cmd+Shift+I         # renomear tab
Cmd+Shift+,         # reload da configuração
```

### skhd — Atalhos globais (abrir apps/URLs)

Editar `skhd/.config/skhd/skhdrc` e correr `skhd --restart-service`.

```bash
# Tecla única (herdado dos Atalhos Mac):
Ctrl+Alt+Cmd+Z          # Zoom (sala pessoal)
Ctrl+Alt+Cmd+S          # Slack
Ctrl+Alt+Cmd+C          # Claude (activate)
Shift+Ctrl+Alt+Cmd+C    # ChatGPT
Ctrl+Alt+Cmd+V          # VS Code
Ctrl+Alt+Cmd+G          # Ghostty (abre ou activa a janela)
Ctrl+Alt+Cmd+T          # Calendário (open_calendar.scpt do focus.widget)
Ctrl+Alt+Cmd+R          # Toggle review mode no focus.widget

# Leader "cob" (Ctrl+Alt+Cmd+D seguido de...):
D → P                   # Plan (Dogfooding)
D → O                   # Do
D → R                   # Review
D → D                   # Dogfooding (home)

# Leader "personal" (Ctrl+Alt+Cmd+P seguido de...):
P → M                   # Mimes (Dia a Dia)
P → B                   # BudgetBakers
P → L                   # AnyList (via Atalho iOS)

# Leader "clients" — aninhado (Ctrl+Alt+Cmd+K seguido de...):
K → M → P               # Mello Produção
K → M → Q               # Mello Qualidade
K → W → P               # Winestone Produção
K → W → Q               # Winestone Qualidade
K → L → E               # Lidl External
K → L → I               # Lidl Internal
K → R                   # Rentelecom (directo)

# Esc cancela qualquer modo (mesmo aninhado sai directo para default).
```

Ao entrar num leader, o widget `skhd-hud.widget` mostra um overlay no topo
do ecrã com o nome do modo e a cheatsheet de teclas disponíveis. O skhd
escreve o estado em `/tmp/skhd-mode` e o widget fica invisível quando
voltamos a `default`.

### Working Info — Desktop como workspace temporário

O Desktop é o "rascunho visual" da sessão. No fim, `Ctrl+Alt+Cmd+W`
dispara o modo arrumação: para cada ficheiro seleccionado no Finder (ou
todos os do Desktop se nada estiver seleccionado) um diálogo pergunta o
destino em `~/Documents/Working Info` — projecto existente, novo projecto,
raiz, saltar ou cancelar tudo. Colisões resolvidas caso a caso
(renomear `(2)`, substituir, saltar).

`Cmd+Alt+W` abre a pasta no Finder e aciona o atalho global do Rectangle
(`Ctrl+Alt+Enter`) para aplicar o tamanho/posição predefinidos.

Scripts em `bin/open-working-info.sh` e `bin/desktop-tidy.sh`.

### VS Code — Multi-cursor

```bash
Cmd+D           # seleccionar próxima ocorrência
Cmd+Shift+L     # seleccionar TODAS as ocorrências
Cmd+U           # desfazer última selecção
```

### Git — Aliases

```bash
git st          # status
git co          # checkout
git br          # branch
git ci          # commit
git pr          # pull --rebase
git lg          # log oneline graph
git dlog        # log denso (uma linha)
git vlog        # log visual (multi-linha)
```

### VS Code extensions sync

```bash
vscode-export   # exportar lista para o repo
vscode-import   # instalar todas a partir do repo
```

### Funções custom

```bash
rtmux <server>      # autossh + tmux attach/new "mimes"
listening           # portas TCP em LISTEN
listening 8080      # filtrar por porta
zsh_startup_time    # medir tempo de arranque (5x)
```

### Segredos via 1Password

```bash
op read "op://Vault/Item/field"   # ler segredo
sops <args>                        # wrapper que carrega SOPS_AGE_KEY lazy
```

---

## Instalação

### Nova máquina

```bash
git clone git@github.com:mimes70/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh --dry-run    # pré-visualizar
./bootstrap.sh              # executar
```

O bootstrap:
1. Instala Homebrew (se não existir)
2. `brew bundle` (Brewfile + Brewfile.<machine>)
3. Instala NVM (se não existir)
4. Detecta ficheiros existentes, mostra **diff vs repo**, pede confirmação
5. Faz backup centralizado em `~/dotfiles-backup/pre-bootstrap-<timestamp>/`
6. Cria symlinks (stow + manuais)
7. Clona/actualiza plugins vim para `~/.vim/pack/dotfiles/start/`
8. Migra remote git para SSH
9. Instala extensões VS Code
10. Symlinka widgets Übersicht (geridos no repo, em `ubersicht/widgets/`)
11. Aplica macOS defaults
12. Cria `~/.cache` para fzf

O bootstrap é **idempotente** — pode correr várias vezes.

### Testar shell sem activar

```bash
ZDOTDIR=~/.dotfiles/shell zsh -l
```

### Activação manual (sem bootstrap)

```bash
cd ~/.dotfiles
bash setup/symlinks.sh           # criar symlinks
bash setup/vim-plugins.sh        # instalar plugins vim
bash setup/vscode-extensions.sh  # instalar extensões VS Code
```

---

## Manutenção

### Adicionar pacote ao Brewfile

```bash
# CLI tool
echo 'brew "nome"          # descrição' >> Brewfile

# GUI app
echo 'cask "nome"          # descrição' >> Brewfile

# Específico de máquina
echo 'brew "nome"' >> Brewfile.imac     # ou Brewfile.macbook
```

### Adicionar alias

Editar `shell/.aliases` e organizar por secção (Dotfiles, Git, Navegação, etc.).

### Adicionar variável de ambiente

Editar `shell/.exports`.

### Adicionar plugin vim

```bash
echo 'https://github.com/owner/plugin-name' >> setup/vim-plugins.txt
bash setup/vim-plugins.sh   # clona e gera helptags
```

### Adicionar extensão VS Code

```bash
# Após instalar manualmente:
vscode-export   # exporta lista actualizada para o repo
```

### Adicionar atalho skhd

Editar `skhd/.config/skhd/skhdrc` e acrescentar uma linha no formato
`<modificadores> - <tecla> : <comando>`:

```
ctrl + alt + cmd - n : open "https://example.com"
```

Para um modo (leader) novo:

```
:: mymode @
ctrl + alt + cmd - x ; mymode
mymode < a : open "https://..." ; default
mymode < escape ; default
```

Aplicar sem reboot:

```bash
skhd --restart-service
```

Primeira instalação: autorizar o binário em **Definições → Privacidade e
Segurança → Acessibilidade**.

### Adicionar tema Ghostty

```bash
curl -o ghostty/.config/ghostty/themes/<nome> <url>
# Activar em ghostty/.config/ghostty/config:
# theme = <nome>
```

### Atualizar Anki deck

Ficheiro: `anki-dotfiles-toolbox.txt`
Formato: TSV com cabeçalho:
```
#separator:tab
#html:false
#deck:Dotfiles Toolbox
#tags column:3
#Front	Back	Tags
```

Cada card é uma linha: `pergunta\tresposta\ttags-separadas-por-espaço`

Comentários `# ...` são ignorados pelo Anki, usar para organizar secções.

Importar: Anki → File → Import → seleccionar ficheiro.

### Debug SSH agent (Fork e outras apps GUI)

Se o Fork (ou outra app GUI) der `Permission denied (publickey)` apesar de o terminal funcionar:

```bash
# Valor no launchd (deve ser o do 1Password)
launchctl getenv SSH_AUTH_SOCK

# Valor dentro do processo Fork (deve coincidir)
ps eww -p "$(pgrep -f 'Fork.app/Contents/MacOS/Fork' | head -1)" | tr ' ' '\n' | grep SSH_AUTH_SOCK

# Recarregar o LaunchAgent e redefinir para a sessão actual
bash setup/ssh-auth-sock.sh
```

Se divergirem, quit completo da app (`Cmd+Q`) e reabrir — na maioria dos casos isso basta. Se não bastar, logout e login.

### Reverter alterações

Backups em:
- `~/dotfiles-backup/pre-bootstrap-<timestamp>/` — feitos pelo bootstrap
- `~/dotfiles-backup/<timestamp>/` — feitos pelo `setup/symlinks.sh`

Os ficheiros têm `__` no nome em vez de `/` (ex: `Library__Application Support__Code__User__settings.json`).

### Verificar Homebrew

```bash
brew doctor
brew bundle check          # verificar consistência com Brewfile
brew bundle cleanup        # remover pacotes não no Brewfile (cuidado!)
```

---

## Estrutura

```
.dotfiles/
├── README.md                       # Este ficheiro
├── bootstrap.sh                    # Setup script (--dry-run disponível)
├── Brewfile                        # Pacotes Homebrew partilhados
├── Brewfile.imac                   # Específico iMac
├── Brewfile.macbook                # Específico MacBook
├── anki-dotfiles-toolbox.txt       # Cards Anki (importável)
│
├── shell/                          # → stow → ~/
│   ├── .zshrc                      # Config principal Zsh
│   ├── .zprofile                   # Login shell (Homebrew init)
│   ├── .aliases                    # Aliases partilhados
│   ├── .exports                    # Variáveis de ambiente
│   └── .stow-local-ignore          # Ignora .zsh_history, .zcompdump
│
├── git/                            # → stow → ~/.gitconfig
│   └── .gitconfig                  # Inclui SSH signing, aliases
│
├── ssh/                            # → link_config → ~/.ssh/config
│   └── .ssh/config                 # 1Password agent + work hosts
│
├── vim/                            # → stow → ~/.vimrc
│   └── .vimrc                      # Config (Catppuccin, leader=,)
│
├── ghostty/                        # → link_config → ~/.config/ghostty/
│   └── .config/ghostty/
│       ├── config                  # JetBrains Mono + Catppuccin
│       └── themes/catppuccin-mocha # Tema embutido
│
├── skhd/                           # → link_config → ~/.config/skhd/
│   └── .config/skhd/skhdrc         # Atalhos globais (Ctrl+Alt+Cmd+... + modos cob/personal)
│
├── vscode/                         # → link_config → ~/Library/.../Code/User/
│   ├── settings.json               # Settings completas
│   ├── keybindings.json
│   ├── extensions.txt              # Lista de extensões
│   └── portugues_pre_acordo.txt    # Dicionário cSpell PT
│
├── claude/                         # → link_config → ~/.claude/
│   ├── settings.json               # Configurações Claude Code
│   └── CLAUDE.md                   # Instruções globais
│
├── machine/                        # Overrides por máquina (sourced no .zshrc)
│   ├── imac.sh
│   └── macbook.sh
│
├── ubersicht/                      # Übersicht widgets
│   └── widgets/                    # Widgets (git subtree de Ubersicht-Widgets)
│
├── launchd/                        # → setup/ssh-auth-sock.sh → ~/Library/LaunchAgents/
│   └── com.mimes.ssh-auth-sock.plist # SSH_AUTH_SOCK → 1Password para apps GUI
│
├── bin/                            # Scripts helper (chamados pelo skhd)
│   ├── open-working-info.sh        # Cmd+Alt+W: abrir + preset Rectangle
│   └── desktop-tidy.sh             # Ctrl+Alt+Cmd+W: arrumação interactiva
│
└── setup/                          # Scripts de instalação
    ├── symlinks.sh                 # Stow + link_config
    ├── vim-plugins.sh              # Clonar plugins vim
    ├── vim-plugins.txt             # URLs dos plugins vim
    ├── vscode-extensions.sh        # Instalar extensões
    ├── ubersicht.sh                # Symlink pasta de widgets Übersicht
    ├── skhd.sh                     # Arranca/reinicia serviço skhd
    ├── ssh-auth-sock.sh            # Instala LaunchAgent SSH_AUTH_SOCK (1Password)
    └── macos-defaults.sh           # defaults write
```

---

## Decisões

Histórico das decisões tomadas e seu racional, para contexto futuro.

### Shell — 2026-04-17

| Decisão | Racional |
|---|---|
| Estrutura modular (`.zshrc` + `.aliases` + `.exports`) | Separa concerns; mais fácil de navegar |
| `EDITOR=vim`, `VISUAL=code --wait` | vim para CLI rápido (git commit), VS Code para edição visual |
| Vi mode (`bindkey -v`) | Consistência com vim |
| Histórico 50K com `HIST_IGNORE_ALL_DUPS` | Mais memória útil, sem duplicados |
| `compinit` cacheado (regenera 24h) | Arranque ~200ms mais rápido |
| Prompt: hostname (yellow) + dir (cyan) + git (magenta) | Distingue iMac vs MacBook visualmente |
| `setopt AUTO_CD` | Escrever path muda directamente |
| `setopt HIST_IGNORE_SPACE` | Comandos com espaço inicial não ficam no histórico (segurança) |
| Homebrew init **só** em `.zprofile` | Evita duplicação (era em ambos) |
| `SSH_AUTH_SOCK` no `~/.ssh/config` (não no `.zshrc`) | Acessível a processos não-interactivos |
| Path `${DOTFILES:-$HOME/.dotfiles}` | Permite override de localização |

### NVM (Node) — 2026-04-17

| Decisão | Racional |
|---|---|
| Lazy loading com stubs | Arranque shell ~500ms mais rápido |
| Stubs para `nvm`, `node`, `npm`, `npx` | Cobre todos os entry points comuns |
| `chpwd` hook só carrega se `.nvmrc` existe | Sem penalty no primeiro `cd` |
| Removido `brew node` do Brewfile | NVM gere versões |

### fzf — 2026-04-17

| Decisão | Racional |
|---|---|
| `fd` em vez de `find` | Mais rápido, ignora `.git/` por defeito |
| Cache Alt+C em `~/.cache/fzf-dirs-cache` | 250K dirs demoram 8s a listar — cache é instantâneo |
| Cache regenera em background a cada 24h | Always-fresh sem bloquear shell |
| `FZF_ALT_C_COMMAND="cat $cache"` | Override no nível da var, não do widget (widget é redefinido pelo fzf) |
| `macos-option-as-alt = true` no Ghostty | Sem isto, Alt+C não funciona em macOS |

### Git — 2026-04-17

| Decisão | Racional |
|---|---|
| SSH signing via 1Password | Chave privada nunca sai do 1Password |
| `init.defaultBranch = main` | Padrão moderno |
| `push.autoSetupRemote = true` | Evita `git push -u origin <branch>` |
| `pull.rebase = true` | Histórico linear |
| Aliases híbridos (`st`, `dlog`, `vlog`) | Mantém shortcuts simples + visualizações ricas |
| Remote SSH (`git@github.com:`) | Usa 1Password agent, sem credenciais Keychain |

### Terminal — 2026-04-17

| Decisão | Racional |
|---|---|
| **Ghostty** sobre iTerm2 | GPU-accelerated, config text-based versionável |
| **JetBrains Mono** | Ligatures, gratuita, legível |
| **Catppuccin Mocha** | Mesmo tema em Ghostty + VS Code + vim |
| Cursor `bar` sem blink | Coerente com vi mode |
| Tab navigation `Cmd+Shift+Left/Right` | Teclado PT não tem `[]` acessíveis |

### Vim — 2026-04-17

| Decisão | Racional |
|---|---|
| Editor secundário (não primário) | VS Code é primário |
| Plugin manager nativo (`~/.vim/pack/dotfiles/start/`) | Sem dependências externas |
| Plugins clonados via `setup/vim-plugins.sh` | Mais simples que submodules |
| Nível 3: vim-sensible/commentary/surround/fugitive + airline + catppuccin | Mínimo polido |
| Leader = `,` | Mais acessível que `\` em PT |
| Persistent undo em `~/.vim/undo/` | Não perder histórico entre sessões |

### VS Code — 2026-04-17

| Decisão | Racional |
|---|---|
| `formatOnSave: false`, `formatOnPaste/Type: true` | Manter controlo, formatar só ao colar |
| `git.path: "git"` | Usa o git do PATH (Homebrew em ambas as máquinas) |
| Dicionário PT pré-acordo no repo | Sincronização entre máquinas |
| Markdown editor com CSS custom | Branding |

### SSH — 2026-04-17

| Decisão | Racional |
|---|---|
| 1Password agent | Sem chaves no disco |
| Hosts de trabalho no repo (privado) | Sincronização entre máquinas |
| `ServerAliveInterval 30` | Evita disconnect em sessões longas |

### 1Password / SOPS — 2026-04-17

| Decisão | Racional |
|---|---|
| `sops()` wrapper com lazy auth | Evita prompt 1Password a cada shell nova |
| `op read` on-demand | Segredos nunca em ficheiros |

### SSH_AUTH_SOCK para apps GUI — 2026-04-18

| Decisão | Racional |
|---|---|
| LaunchAgent `com.mimes.ssh-auth-sock.plist` vs `launchctl setenv` ad-hoc | `setenv` no terminal não propaga para apps GUI lançadas via LaunchServices (Fork, etc.); LaunchAgent corre no login e define para toda a sessão |
| `ProgramArguments` com `/bin/sh -c` | Permite expansão `$HOME` em runtime — plists não expandem env vars directamente |
| Gerido por `setup/ssh-auth-sock.sh` | Symlinka o plist + `launchctl load` + `launchctl setenv` imediato (evita logout/login) |
| Problema específico: Fork força `-i ~/.ssh/id_rsa -F /dev/null` | Ignora `~/.ssh/config` (e a directiva `IdentityAgent`); só o env var é respeitado |

### Bootstrap — 2026-04-17

| Decisão | Racional |
|---|---|
| `--dry-run` flag | Pré-visualizar sem executar |
| Diff antes de substituir | Ver o que muda + decidir |
| Confirmação interactiva | Evitar substituições não intencionais |
| Backups centralizados em `~/dotfiles-backup/<timestamp>/` | Não espalhar `.backup` files |
| Detecta symlinks "stale" e remove-os | Stow recusa overwrite de symlinks externos |
| `bash` em vez de `source` para sub-scripts | Evita `set -e` matar shell pai |
| Compatível com Bash 3.2 (macOS default) | Sem `declare -A` |

### Stow — 2026-04-17

| Decisão | Racional |
|---|---|
| `--no-folding` | Nunca substitui directórios por symlinks |
| Stow para ficheiros directos em `~` | Idempotente, simples |
| `link_config` (não stow) para SSH/Ghostty | Stow recusa criar links em dirs com ficheiros não-geridos |
| `.stow-local-ignore` em `shell/` | Ignora `.zsh_history`, `.zcompdump` |

### Anki — 2026-04-17

| Decisão | Racional |
|---|---|
| Formato TSV plano | Importável directamente, fácil de editar |
| Tags hierárquicas (`vim mappings`, `git-config`) | Filtragem fina no Anki |
| Comentários `#` para organização | Ignorados pelo Anki, ajudam navegação |

### skhd (shortcuts) — 2026-04-18

| Decisão | Racional |
|---|---|
| skhd em vez de Atalhos Mac + `/tmp/uber-listener.log` | Config em texto, versionável e sincronizada entre máquinas via git |
| `ctrl + alt + cmd` como hyper único | Preserva a convenção herdada dos Atalhos Mac (muscle memory) |
| Modos (leaders) `d`, `p`, `k` para dashboards/pessoais/clientes | Colapsa muitas combinações em 3 leaders; mais mnemónico e liberta keymap |
| Modos aninhados para clientes (k → m/w → p/q) | Espelha a hierarquia real (solução × ambiente); esc sai directo para default em qualquer nível |
| Dogfooding (home) passa a `d → d` dentro do modo cob | Home é menos usado que os dashboards Plan/Do/Review; consistência no leader |
| `@` nos modos (capture) | Teclas não ligadas ficam bloqueadas enquanto em modo — evita surpresas |
| HUD dos modos via `skhd-hud.widget` (Übersicht) em vez de `display notification` | Latência ~100ms vs segundos da Notification Center; CSS customizável; sem novas deps (Übersicht já corre) |
| `open "<url>"` directo (em vez de simular clique no widget) | Elimina polling a 500ms do `links.widget` e o ficheiro temporário |
| Toggle do `focus.widget` via `/tmp/focus-review-toggle` | `open` não consegue mexer no DOM; ficheiro dedicado (não partilhado) torna a intenção explícita |
| Tap `koekeishiya/formulae` | Fórmula oficial do autor (mesmo autor do yabai) |
| Gerido por `skhd --install-service` + `--start-service` | A fórmula não define plist para `brew services`; o skhd tem CLI próprio para launchd |
| Hammerspoon considerado e rejeitado | Overkill para URL→hotkey; skhd é declarativo em 1 ficheiro |

### Übersicht widgets — 2026-04-18

| Decisão | Racional |
|---|---|
| Widgets migrados para `ubersicht/widgets/` via `git subtree` | Um só repo, histórico preservado |
| `setup/ubersicht.sh` symlinka a pasta inteira | Consistente com os outros scripts em `setup/` |
| Symlink directo em `~/Library/Application Support/Übersicht/widgets` | Sem namespace `Ubersicht-Widgets/` extra |
| Upstream `mimes70/Ubersicht-Widgets` mantido como fonte opcional | Pode-se `git subtree pull/push --prefix=ubersicht/widgets ubersicht-widgets main` |

### Repositório — 2026-04-17

| Decisão | Racional |
|---|---|
| Repo privado | Permite incluir signing key, hosts SSH de trabalho |
| Branch convention `claude/<feature>-<id>` | Trabalho em branches descritivas |
| Commit messages descritivos com "why" | Histórico útil para futura referência |
| README como memória para Claude Code | Contexto persistente entre sessões |
