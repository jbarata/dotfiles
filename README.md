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

### Rectangle — Window manager

Instalado via Brewfile (`cask "rectangle"`). Os defaults cobrem
Halfs/Thirds/Cantos/Center/Maximize/Display tal como na cheat sheet
(`Ctrl+Alt` como base; `Ctrl+Alt+Cmd+seta` para mover entre displays).

Para versionar overrides locais: Rectangle → Settings → Import/Export →
Export to file → guardar em `rectangle/RectangleConfig.json`. O
`setup/rectangle.sh` (chamado pelo bootstrap) converte o JSON para plist
e aplica via `defaults import com.knollsoft.Rectangle`.

Permissão "Acessibilidade" tem de ser dada manualmente na primeira
execução (Definições → Privacidade e Segurança).

### skhd — Atalhos globais (abrir apps/URLs)

Editar `skhd/.config/skhd/skhdrc` e correr `skhd --restart-service`.

```bash
# Tecla única (herdado dos Atalhos Mac):
Ctrl+Alt+Cmd+Z          # Zoom (sala pessoal)
Ctrl+Alt+Cmd+S          # Slack
Ctrl+Alt+Cmd+M          # Mail
Shift+Ctrl+Alt+Cmd+M    # Music
Ctrl+Alt+Cmd+C          # Claude (activate)
Shift+Ctrl+Alt+Cmd+C    # ChatGPT
Ctrl+Alt+Cmd+V          # VS Code
Ctrl+Alt+Cmd+G          # Ghostty (abre ou activa a janela)
Ctrl+Alt+Cmd+B          # Safari (abre ou activa a janela)
Shift+Ctrl+Alt+Cmd+B    # Google Chrome (abre ou activa a janela)
Ctrl+Alt+Cmd+T          # Calendário (open_calendar.scpt do focus.widget)
Shift+Ctrl+Alt+Cmd+N    # Safari → Notes (guarda a página actual em versão reader)
Ctrl+Alt+Cmd+F          # Dictate: toggle whisper-stream → paste no app activo

# Leader "cob" (Ctrl+Alt+Cmd+D seguido de...):
D → P                   # Plan (Dogfooding)
D → O                   # Do
D → R                   # Review
D → D                   # Dogfooding (home)
D → V                   # Vendas (Visão Geral)
D → T                   # Tempo (definição 427, q=username:mimes)

# Leader "personal" (Ctrl+Alt+Cmd+P seguido de...):
P → M                   # Mimes (Dia a Dia)
P → B                   # BudgetBakers
P → L                   # AnyList (via Atalho iOS)

# Leader "review" (Ctrl+Alt+Cmd+R seguido de...):
R → T                   # Today plan
R → D                   # Daily review
R → W                   # Weekly review
R → M                   # Monthly review
R → Q                   # Quarterly review
R → Y                   # Yearly review
R → O                   # Toggle painel (open/close)

# Leader "clients" — aninhado (Ctrl+Alt+Cmd+K seguido de...):
K → M → P               # Mello Produção
K → M → Q               # Mello Qualidade
K → W → P               # Winestone Produção
K → W → Q               # Winestone Qualidade
K → L → E               # Lidl External
K → L → I               # Lidl Internal
K → R                   # Rentelecom (directo)

# Painel de ajuda (toggle):
Ctrl+Alt+Cmd+'          # Alterna skhd-help.widget com a cheatsheet completa (apóstrofo: directo no teclado PT)

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

### Safari → Notes — Guardar página em modo reader

`Shift+Ctrl+Alt+Cmd+N` dispara `bin/safari-to-note.sh`: lê a página activa
do Safari, extrai uma versão "reader-friendly" (título, parágrafos,
filtrando nav/aside/footer/ads) e cria uma nota no Notes.app com o
título, o link para a página original, a tag `#site` e o conteúdo.

Imagens: ficam como marcadores `[imagem]` clicáveis que apontam para o
URL real — o Notes.app não renderiza `<img>` inline quando o body é
fixado via AppleScript (confirmado com HTML minimal, tanto remotos
como `data:` URIs aparecem como "File" placeholders). A posição no
fluxo do artigo fica preservada; abrir e arrastar é o path manual.
No caso do Substack, os proxies de imagem (que devolvem 404 fora do
browser) são "unproxied" via regex para o URL directo no S3.

Pré-requisitos (uma vez):
- Em Safari → Preferences → Advanced, activar **Show Develop menu**.
- Safari → Develop → **Allow JavaScript from Apple Events**.

Feedback visual via `skhd-hud.widget` (polling `/tmp/skhd-mode` a 100ms).
Logs de debug em `/tmp/safari-to-note.log` (inclui `v=<sha>` por execução).

### Whisper / Ditado por voz

`Ctrl+Alt+Cmd+F` (ou alias `dictate`) é um toggle. 1ª pressão arranca o
`whisper-stream` em background a capturar do microfone default; 2ª pressão
pára, transcreve e cola no app activo (preserva o clipboard anterior).

```bash
Ctrl+Alt+Cmd+F      # toggle: arrancar / parar+colar
dictate             # mesmo toggle a partir do terminal
```

Feedback visual no `skhd-hud.widget`:
- `● REC (medium/pt) — ⌃⌥⌘F para parar` enquanto grava
- `⏹ a transcrever…` durante a paragem
- `✓ colado` no fim (ou `∅ sem áudio` / `∅ sem texto` se vazio)

Modelo default: `medium` (multilingue, ~1.5 GB) — accuracy notável em PT
em microfone integrado, ainda fluido no M2 Max em Metal puro (latência
maior nas pausas vs `small` mas resultado mais usável). Override por
sessão:

```bash
WHISPER_MODEL=small WHISPER_LANG=auto dictate    # mais rápido, menos preciso
WHISPER_MODEL=large-v3 dictate                    # melhor qualidade, sem real-time
```

Logs em `/tmp/dictate.log`.

### Whisper / Transcribe — Áudio gravado (iPhone, etc.)

`transcribe` aceita qualquer formato suportado pelo `ffmpeg` (m4a do
iPhone, qta do Dictafone macOS, mp3, mp4, wav, opus...) e usa o modelo
`large-v3` para qualidade máxima — não tempo real, mas só corre quando
se chama.

```bash
transcribe ~/Downloads/memo.m4a            # ficheiro concreto
transcribe *.m4a                            # múltiplos
```

Output sempre em **`~/Desktop/`** por defeito (visível, fácil de mover
para arquivo depois — independente de onde está o input):
```
memo.m4a  →  ~/Desktop/memo.txt   (texto plano)
          →  ~/Desktop/memo.srt   (com timestamps; útil para procurar momentos)
```

**Dictafone do macOS:** os ficheiros não estão num path estável (estão
num container CloudKit opaco). Arrasta a gravação da app Dictafone
directamente para a janela do Ghostty — o terminal cola o path do `.qta`
materializado temporariamente — e prime Enter. O `ffmpeg` lida com a
extensão `.qta` (é M4A) sem alterações.

Override por sessão:
```bash
WHISPER_OFFLINE_MODEL=medium WHISPER_LANG=pt transcribe ficheiro.m4a
WHISPER_OUT_DIR=~/Documents/Transcriptions transcribe ficheiro.m4a
```

### Whisper / Transcribe-diarize — Reuniões e diálogos

`transcribe-diarize` faz transcrição **e identifica oradores**
(`[SPEAKER_00]`, `[SPEAKER_01]`, ...) via [whisperx](https://github.com/m-bain/whisperX)
(faster-whisper + pyannote.audio + alinhamento word-level).

```bash
transcribe-diarize ~/Desktop/reuniao.m4a    # ficheiro concreto
transcribe-diarize *.m4a                     # múltiplos
```

Output em `~/Desktop/` (igual ao `transcribe`):
```
reuniao.txt   # texto plano com prefixos [SPEAKER_NN]
reuniao.srt   # legendas com timestamps + speakers
```

Velocidade: ~0.5–1× tempo real no M2 Max (mais lento que `transcribe`
porque adiciona o passo de diarização do pyannote). Uma reunião de 60
min processa-se em ~1–2 horas.

Hint para o pyannote se souberes o número de oradores (melhora accuracy):
```bash
WHISPERX_MIN_SPEAKERS=2 WHISPERX_MAX_SPEAKERS=2 transcribe-diarize entrevista.m4a
```

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

---

## Instalação

### Nova máquina

```bash
git clone git@github.com:mimes70/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh --dry-run    # pré-visualizar
./bootstrap.sh              # executar
./bootstrap.sh --upgrade    # executar + actualizar pacotes Homebrew já instalados
```

O bootstrap:
1. Instala Homebrew (se não existir)
2. `brew bundle` (brew/Brewfile + brew/Brewfile.<machine>) — instala o que falta; só actualiza o que já lá está com `--upgrade`
3. Instala NVM (se não existir)
4. Detecta ficheiros existentes, mostra **diff vs repo**, pede confirmação
5. Faz backup centralizado em `~/dotfiles-backup/pre-bootstrap-<timestamp>/`
6. Cria symlinks (stow + manuais)
7. Clona/actualiza plugins vim para `~/.vim/pack/dotfiles/start/`
8. Migra remote git para SSH
9. Instala extensões VS Code
10. Symlinka widgets Übersicht (geridos no repo, em `ubersicht/widgets/`)
11. Compila `whisper.cpp` + descarrega modelo + gera Core ML (Apple Silicon)
12. Cria venv whisperx (diarização — modelos descarregam ao 1º uso)
13. Aplica macOS defaults
14. Cria `~/.cache` para fzf

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
echo 'brew "nome"          # descrição' >> brew/Brewfile

# GUI app
echo 'cask "nome"          # descrição' >> brew/Brewfile

# Específico de máquina
echo 'brew "nome"' >> brew/Brewfile.imac     # ou brew/Brewfile.macbook
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

Tudo o que diz respeito ao deck vive em `anki/`:
- `anki/cards.txt` — deck completo, `#html:true` (TSV importável; suporta
  `<img>` para anexar imagens). `#deck:Dotfiles Toolbox`.
- `anki/media/` — imagens referenciadas via `<img src="...">`.

Formato TSV: `guid\tFront\tBack\ttags-separadas-por-espaço`. Comentários
`# ...` são ignorados pelo Anki — usar para organizar secções. Como o
ficheiro está em `html:true`, qualquer `<` ou `>` em texto literal nos
campos tem de ficar escapado como `&lt;` / `&gt;`.

Antes do import é preciso copiar as imagens de `anki/media/` para a
pasta `collection.media` do Anki. O bootstrap já faz isso via
`setup/anki-media.sh`; manualmente: `bash ~/.dotfiles/setup/anki-media.sh`.

Importar: Anki → File → Import → seleccionar `anki/cards.txt`.

### Trocar modelo Whisper

O default do dictate é `medium` (descarregado pelo bootstrap). Para usar
outro:

```bash
WHISPER_MODEL=large-v3 bash ~/.dotfiles/setup/whisper.sh
```

O script é idempotente: descarrega o `.bin` se faltar e gera o
`.mlmodelc` (Apple Silicon) no venv `~/.local/share/whisper-coreml-venv/`.
Os modelos ficam em `~/.local/share/whisper-models/`.

Depois exporta `WHISPER_MODEL` no `shell/.exports` ou nas env vars do
launchd se quiseres mudar o default permanente; senão usa override por
sessão (`WHISPER_MODEL=small dictate`). Nota que `shell/.exports` só é
sourced em shells interactivas — não chega ao script lançado pelo skhd,
portanto para mudar o que o hotkey usa edita o default no próprio
`bin/dictate.sh`.

### Setup manual WhisperX (HuggingFace + 1Password)

Uma vez por máquina:

1. **Conta HuggingFace gratuita:** [huggingface.co/join](https://huggingface.co/join)
2. **Access Token** com `read` scope: [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)
   → "New token" → Type: Read → Copy
3. **Aceitar T&C** dos modelos pyannote (clicar "Agree and access repository" em ambos):
   - [pyannote/speaker-diarization-community-1](https://huggingface.co/pyannote/speaker-diarization-community-1) (modelo de diarização — default actual do whisperx)
   - [pyannote/segmentation-3.0](https://huggingface.co/pyannote/segmentation-3.0) (VAD interno)

   Nota: versões antigas de whisperx usavam `pyannote/speaker-diarization-3.1`. Se já tens esse aceite, fica como bonus mas não é necessário; o `community-1` é o que precisas hoje.
4. **Guardar no 1Password:**
   - Vault: `Private`
   - Title: `HuggingFace`
   - Field name: `token` (tipo: password)
   - Value: o token copiado
5. **Verificar:**
   ```bash
   op read "op://Private/HuggingFace/token"   # deve devolver o token
   transcribe-diarize ~/Desktop/teste.m4a     # corre o pipeline completo
   ```

A 1ª invocação do `transcribe-diarize` descarrega ~3.5 GB para
`~/.cache/huggingface/`: modelo `large-v3` em formato CTranslate2 (~3 GB)
+ modelos pyannote (~500 MB). Ficam cached para invocações seguintes.

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
brew bundle check --file=brew/Brewfile     # verificar consistência com Brewfile
brew bundle cleanup --file=brew/Brewfile   # remover pacotes não no Brewfile (cuidado!)
```

---

## Estrutura

```
.dotfiles/
├── README.md                       # Este ficheiro
├── bootstrap.sh                    # Setup script (--dry-run disponível)
├── brew/                           # Pacotes Homebrew
│   ├── Brewfile                    # Partilhados
│   ├── Brewfile.imac               # Específico iMac
│   └── Brewfile.macbook            # Específico MacBook
├── anki/                           # Deck Anki + media
│   ├── cards.txt                   # Deck completo (html:true, TSV)
│   └── media/
│       └── rectangle-cheatsheet.png  # cheat sheet anexa aos 6 cards re*
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
├── rectangle/                      # Config Rectangle versionada
│   └── RectangleConfig.json        # Export da UI; importado pelo bootstrap
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
│   ├── desktop-tidy.sh             # Ctrl+Alt+Cmd+W: arrumação interactiva
│   ├── safari-to-note.sh           # Shift+Ctrl+Alt+Cmd+N: Safari → Notes (texto + placeholders)
│   ├── dictate.sh                  # Ctrl+Alt+Cmd+F: toggle whisper-stream + paste
│   ├── transcribe.sh               # CLI: m4a/mp3/... → .txt + .srt via whisper-cli + ffmpeg
│   └── transcribe-diarize.sh       # CLI: como transcribe + diarização (whisperx + pyannote)
│
└── setup/                          # Scripts de instalação
    ├── symlinks.sh                 # Stow + link_config
    ├── vim-plugins.sh              # Clonar plugins vim
    ├── vim-plugins.txt             # URLs dos plugins vim
    ├── vscode-extensions.sh        # Instalar extensões
    ├── ubersicht.sh                # Symlink pasta de widgets Übersicht
    ├── skhd.sh                     # Arranca/reinicia serviço skhd
    ├── ssh-auth-sock.sh            # Instala LaunchAgent SSH_AUTH_SOCK (1Password)
    ├── cob-tools.sh                # clone/npm-link de cob-cli, cob-pdf, cob-aia e cob-press
    ├── whisper.sh                  # Build whisper.cpp + modelo + Core ML (Apple Silicon)
    ├── whisperx.sh                 # Venv whisperx (diarização) — pyannote + faster-whisper
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
| `setup/vscode-extensions.sh` mostra o stderr do `code` — 2026-09-08 | O `2>/dev/null` no `code --install-extension` engolia a razão da falha e sobrava só `AVISO: falhou <ext>`, impossível de diagnosticar. Agora o output vem indentado e no fim há um resumo das que falharam |

### SSH — 2026-04-17

| Decisão | Racional |
|---|---|
| 1Password agent | Sem chaves no disco |
| Hosts de trabalho no repo (privado) | Sincronização entre máquinas |
| `ServerAliveInterval 30` | Evita disconnect em sessões longas |

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
| `brew bundle --no-upgrade` por defeito, upgrades atrás de `--upgrade` — 2026-09-08 | O Homebrew deixou de publicar bottles para Mac Intel, por isso no iMac qualquer upgrade compila do source: um `brew bundle` normal arrastava `gcalcli` → `pydantic-core` (Rust), `ffmpeg`, `llvm@22`, `python@3.13/3.14` e ficava horas a compilar. Um bootstrap deve pôr a máquina a funcionar, não gastar a tarde a actualizar o que já funciona |
| `brew bundle --verbose` — 2026-09-08 | O `brew bundle` engole o output de cada install/upgrade e imprime o plano todo de uma vez: uma compilação de horas era indistinguível de um script pendurado |

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
| IPC do `focus.widget` (review) via `/tmp/focus-review-cmd` | `open` não consegue mexer no DOM; ficheiro dedicado + whitelist de tokens (toggle/open/close/today/daily/weekly/monthly/quarterly/year) serve o leader `review` sem acoplar o widget ao skhd |
| Homogenização `trimester → quarterly` (CSS, JS, `.scpt`, HUD, tag Things) | Termo "quarterly" é o padrão em inglês de negócio; remove ambiguidade e simplifica naming |
| `skhd-help.widget` (overlay) em vez de imprimir shortcuts no terminal | Self-documenting à distância de `⌃⌥⌘ '`; não depende de abrir o skhdrc/README |
| Tecla `'` (apóstrofo) para toggle da ajuda | Directa no teclado PT (sem shift), rápida e mnemónica ("abrir/fechar aspas" ≈ abrir/fechar ajuda) |
| Tap `koekeishiya/formulae` | Fórmula oficial do autor (mesmo autor do yabai) |
| Gerido por `skhd --install-service` + `--start-service` | A fórmula não define plist para `brew services`; o skhd tem CLI próprio para launchd |
| Hammerspoon considerado e rejeitado | Overkill para URL→hotkey; skhd é declarativo em 1 ficheiro |

### Safari → Notes — 2026-04-20

| Decisão | Racional |
|---|---|
| `Shift+Ctrl+Alt+Cmd+N` dispara `bin/safari-to-note.sh` | Mantém convenção do hyper; `n` = note, mnemónico |
| AppleScript + `do JavaScript` no tab Safari (não curl) | Usa o DOM renderizado — cookies, client-side JS e paywalls autenticados ficam automaticamente resolvidos |
| Heurística inline (article/main/[itemprop=articleBody] + score por texto/\<p\>) | Sem deps externas; 99% dos blog posts funcionam |
| Imagens: `<img>` → placeholder `<p><a>[imagem]</a></p>` com URL real | Notes.app **não** renderiza `<img>` inline via body AppleScript (remotos e `data:` URIs saem ambos como "File" — confirmado com HTML minimal). Preservar a posição + dar URL clicável é o degrau intermédio entre "imagens partidas" e "adicionar manualmente" |
| Substack: `unproxy()` regex decoda `/p/<transform>/<url-encoded-s3-url>` | Os proxies de `ruben.substack.com/p/…` devolvem 404 fora do browser; o S3 original está URL-encoded no último segmento do proxy e em claro no `data-attrs` JSON — o link do placeholder tem de apontar para um URL que o utilizador consiga abrir |
| Rejeitada a abordagem **Shortcuts.app** (pivot revertido) | A Shortcuts resolveria as imagens nativamente mas obriga a setup manual não-versionável por máquina, acopla a workflow à app Shortcuts, e o utilizador prefere o controlo do texto no repo em troca de inserir imagens manualmente |
| Rejeitada a abordagem **base64 inline** (4 iterações: sips WebP→PNG, data-attrs parsing, Substack unproxy, magic-byte detection) | Diagnóstico empírico com HTML minimal confirmou que o Notes trata qualquer `data:` URI no body como attachment genérico, independente do formato, tamanho ou correctness. Limitação está na API do Notes |
| Feedback visual via `skhd-hud.widget` + `/tmp/skhd-mode` | Widget já existente (poll 100ms); reaproveita o canal usado para leader modes; trap `EXIT` limpa |
| Tag `#site` escrita como texto no corpo HTML | Notes parseia hashtags em texto livre ao gravar, sem API dedicada |
| `v=<sha>` no log por invocação | Evita diagnosticar uma versão desactualizada quando o utilizador esquece `dl` (aconteceu durante o desenvolvimento) |
| Nota criada no folder default (sem especificar account/folder) | Evita depender de locale (`"Notes"` vs `"Notas"`); o Notes coloca na localização natural do utilizador |
| Requer "Allow JavaScript from Apple Events" em Safari | Restrição nativa do macOS desde Mojave — one-time setup |

### Whisper / Ditado por voz — 2026-04-25

| Decisão | Racional |
|---|---|
| `whisper.cpp` compilado em `~/.local/src/whisper.cpp` (não a fórmula `brew "whisper-cpp"`) | A fórmula não inclui `whisper-stream` (binário SDL2) nem activa Core ML. Compilar é o único caminho para ditado **streaming** real e para o speed-up do encoder no M2/M3 |
| `cmake -DWHISPER_SDL2=ON -DWHISPER_COREML=1` | SDL2 = captura de áudio nativa do `whisper-stream`; Core ML = encoder a correr na ANE (~3× mais rápido em `small`/`medium`) |
| Core ML só em `arm64` (auto-detect via `uname -m`) | No iMac Intel não há Neural Engine — gerar o `.mlmodelc` seria desperdício de tempo e disco |
| Geração do `.mlmodelc` num venv isolado em `~/.local/share/whisper-coreml-venv/` | `coremltools` + `torch` + `ane_transformers` pesam ~2 GB e fixam versões — não devem poluir o Python do sistema. Venv mantém o setup reproducível e descartável |
| Pin de `python@3.11` no Brewfile, `setup/whisper.sh` usa `python3.11` explicitamente | macOS recente trazia já `python3.14` como `python3`. Esse Python parte na criação do venv (ensurepip) e mesmo que passasse, `torch`/`coremltools` não têm wheels para cp313/cp314, e `ane_transformers` prende `torch 2.x` (Python ≤3.12). 3.11 é a versão com cobertura completa dos três pacotes |
| Geração Core ML como "best effort" (warn em vez de exit) | `set -e` no bootstrap matava todo o setup se o venv falhasse, deixando passos finais (macos-defaults, cache fzf) por correr. whisper-stream funciona perfeitamente em Metal puro com modelo `medium` no M2 Max; Core ML é optimização, não pré-requisito |
| Recriação automática do venv se o Python interno divergir | Se um run anterior criou o venv com outro Python (ex.: 3.14), reusar resulta em `pip install` partido. Detectar via `[[ ! -x $venv/bin/$expected_python ]]` e `rm -rf` é mais simples que migração in-place |
| Build com `-DWHISPER_COREML_ALLOW_FALLBACK=1` | Sem este flag, qualquer falha a carregar o `.mlmodelc` aborta o whisper context inteiro (mensagem `failed to initialize whisper context`) — mesmo com Metal disponível. Acontece quando o `coremltools` gera um `.mlmodelc` incompatível com o `coremlc` do Xcode (visto em macOS Sequoia + M2). Com fallback, perde-se só o speed-up; whisper-stream continua a funcionar |
| Pre-flight `xcrun --find coremlc` antes de instalar o venv | `coremlc` (compilador `.mlpackage` → `.mlmodelc`) só vem com o **Xcode completo**, não com as Command Line Tools (que o bootstrap já valida). Sem este check, o script instalava 2 GB de `torch+coremltools` e corria ~5 min de conversão PyTorch→MIL para falhar no último passo `xcrun coremlc compile`. Verificar à cabeça poupa tempo e disco; a mensagem orienta o user para `Xcode App Store + xcode-select -s` se quiser activar Core ML depois |
| Validação de tamanho mínimo no `download_model` | O `download-ggml-model.sh` upstream verifica só "ficheiro existe? skip" — não valida tamanho nem SHA. Se uma run anterior foi interrompida (Ctrl+C, rede cair) o `.bin` parcial fica em `models/` e a próxima execução salta o download e propaga silenciosamente o ficheiro corrupto. O whisper-cli só estoura no fim com `expected N tensors, got M`. Tabela `expected_size_mb` por modelo (calibrada a 90% do **real** — `large-v3` mede 2951 MB, não os 3.1 GB redondinhos da documentação) detecta o problema antes do `mv` para o local centralizado |
| `DOTFILES="${DOTFILES:-$HOME/.dotfiles}"` no topo do `setup/whisper.sh` | `set -u` faz o script crashar com `DOTFILES: unbound variable` se for invocado directamente (e não via `bootstrap.sh`, que define a var). O default permite o user correr `bash setup/whisper.sh` autonomamente — mais ainda quando uma mensagem de erro aponta para esse mesmo comando |
| Health-check pós-arranque no `dictate.sh` (sleep 0.8 + `kill -0`) | Sem isto, se o whisper-stream morrer no init (modelo corrupto, permissão de microfone negada, .mlmodelc partido com build sem fallback) o PID fica órfão, a HUD diz "● REC" e cada nova pressão lança outro processo condenado. O sleep de 0.8s cobre a janela típica do erro de inicialização sem atrasar o uso normal |
| `export LANG=en_US.UTF-8` no topo de `dictate.sh` e `transcribe.sh` | skhd herda um env minimalista do launchd — `LANG` fica unset. `pbcopy` sem `LANG=UTF-8` interpreta bytes UTF-8 como MacRoman ao guardar no clipboard, e cola `"N√£o"` em vez de `"Não"` em qualquer app. Os exports no `shell/.exports` só carregam em shells interactivas (.zshrc), portanto não chegam aos scripts spawned pelo skhd. Forçar a env no início garante encoding consistente independentemente do parent process |
| Modelo offline `large-v3` separado do streaming `medium` | Streaming precisa de tempo real → `medium` é o tecto sustentável no M2 Max em Metal puro; transcrição offline não tem essa restrição → `large-v3` dá qualidade muito superior em PT (especialmente nomes próprios, pontuação). Os dois coexistem em `~/.local/share/whisper-models/` |
| `transcribe.sh` faz resample via `ffmpeg` em vez de exigir wav | iPhone Voice Memos grava em `.m4a` (AAC); muitas outras fontes em `.mp3`, `.opus`, `.mp4`. whisper.cpp só aceita 16 kHz mono PCM — `ffmpeg -ar 16000 -ac 1 -c:a pcm_s16le` cobre tudo numa linha. Tmp wav é descartado depois |
| Output `.txt` + `.srt` por defeito (não opcional) | `.txt` para uso normal; `.srt` (com timestamps) permite procurar "onde é que eu disse X" e abrir directamente no QuickTime/VLC com legendas — o custo extra é zero (whisper-cli aceita `-otxt -osrt` na mesma run) |
| `transcribe` exige sempre path explícito (sem fzf-magic) | Tentei `fzf` sobre uma pasta canónica de Voice Memos mas o Dictafone do macOS guarda em CloudKit opaco — não há ficheiro estável para listar. Materialização para `.qta` só acontece durante o drag, num path tmp efémero. Em vez de inventar uma "inbox" sintética e treinar o utilizador a mexê-la, o caminho honesto é arrastar do Dictafone para o Ghostty (terminal cola o path) → Enter |
| Output sempre em `~/Desktop/` por defeito (não em `dirname($INPUT)`) | Auto-detect "se a pasta é gravável fica lá, senão fallback" parecia esperto, mas era inconsistente — outputs em `~/Downloads/` para uns ficheiros, em `~/Desktop/` para outros (Dictafone). Default fixo torna o comportamento previsível: o user sabe sempre onde procurar o `.txt`. Visível no Desktop facilita "ler agora, arrumar depois". `WHISPER_OUT_DIR` permite pin para utilizadores com pipeline diferente (`~/Documents/Transcriptions/`) |
| Post-flight existence check de `.txt`/`.srt` | Sem isto, o falhanço silencioso do `whisper-cli` (em sandbox ou disco cheio) deixa o script a imprimir "✓ x.txt / ✓ x.srt" para ficheiros que não existem, e o user só descobre o problema mais tarde. `[[ ! -f $OUT_PREFIX.txt || ! -f $OUT_PREFIX.srt ]]` no fim é a única garantia — exit code do whisper-cli não é confiável aqui |
| `WHISPER_LANG=auto` por defeito no `transcribe.sh` (vs `pt` no `dictate.sh`) | Streaming é uso interactivo, quase sempre PT — fixar evita o overhead de detecção. Batch processa material variado (memos PT, calls EN, mix) — `auto` é mais robusto sem perda perceptível |
| Modelo default `medium` (multilingue, ~1.5 GB) | `small` reconhecia mal a fala em PT em microfone integrado (visto na prática: "não tem a salvaver com pedem nada"). `medium` melhora drasticamente nomes próprios e pontuação à custa de ~3× mais lento — ainda fluido no M2 Max em Metal puro. EN-only `.en` cobre mal o caso `LANG=pt_PT`. `small` continua disponível via `WHISPER_MODEL=small` |
| Modelos centralizados em `~/.local/share/whisper-models/` | XDG-friendly; o `.mlmodelc` tem de viver ao lado do `.bin` para o whisper.cpp o detectar automaticamente |
| `bin/dictate.sh` toggle (em vez de push-to-talk) | Push-to-talk requer escutar key-up, que o skhd não suporta; toggle resolve com PID file e é igualmente confortável para ditado de 5–60s |
| `whisper-stream --step 0 --length 5000 --keep 200` | Modo VAD-like: só processa em silêncios, evitando que o stream emita transcrições parciais duplicadas que precisariam de dedup no shell. `--keep 200` ms de overlap evita cortes a meio de palavra |
| Paste via `pbcopy` + `osascript keystroke "v" cmd` em vez de `cliclick t:` | Funciona sem deps extra (cliclick não está no Brewfile); o save/restore do clipboard com `pbpaste` → backup → paste → `pbcopy` mitiga o efeito secundário de tocar no pasteboard |
| Restaurar clipboard 400 ms após paste (background) | Tempo suficiente para a app activa consumir o Cmd+V antes de o conteúdo voltar ao anterior; assíncrono não atrasa o feedback do HUD |
| Hotkey `ctrl + alt + cmd - f` (não leader) | Toggle só faz sentido como tecla única; `f` = "fala", livre e mnemónico em PT |
| HUD reaproveitando `/tmp/skhd-mode` (em vez de `display notification`) | Latência ~100 ms vs segundos; canal já existe e o widget já está a fazer poll. Estados `● REC` / `⏹ transcrevendo` / `✓ colado` são auto-explicativos |
| `nohup` + redirecção de stdout para `/tmp/dictate.out` | O whisper-stream emite tokens linha-a-linha; ler do ficheiro no momento do STOP é mais simples que pipes ou named pipes e sobrevive a uma shell que feche |
| Filtro de output via `sed -E '/^###/d; s/^\[[^]]*\][[:space:]]*//'` | O whisper-stream emite headers `### Transcription N START/END` e prefixos `[t1 --> t2]` por segmento — só queremos o texto puro |

### Whisper / WhisperX (diarização) — 2026-04-25

| Decisão | Racional |
|---|---|
| Stack separado para diarização (`whisperx`) em vez de tentar adaptar o `whisper.cpp` | whisper.cpp tem `--tinydiarize` mas só EN-only e detecta apenas transições, sem labels. Para PT com `[SPEAKER_NN]` real, o caminho realista é `pyannote.audio` que vive no ecossistema Python. whisperx encapsula faster-whisper (ASR) + pyannote (diarização) + alinhamento — preserva a invariante de "uma ferramenta, um output esperado" |
| Coexistir com `whisper.cpp` (não substituir) | `transcribe` simples (1 orador, blog post a transcrever) é 5× mais rápido em whisper.cpp do que em whisperx. Manter as duas ferramentas dá ao utilizador a escolha conforme o caso. Disco extra (~5 GB) é o custo da independência |
| Venv isolado em `~/.local/share/whisperx-venv/` (não reuso do `whisper-coreml-venv`) | Os requisitos de versões divergem (whisperx prende torch numa janela diferente da que `coremltools` exige). Misturar levaria a downgrades cruzados a cada `pip install`. Venvs separados isolam — disco é barato vs debugging de conflitos |
| HF token via 1Password (`op read` lazy) em vez de ficheiro `.env` ou `huggingface-cli login` | Padrão já estabelecido no repo (`sops`, `op://` no SSH config, etc.). `huggingface-cli login` escreve em `~/.cache/huggingface/token` em plaintext — viola o princípio de "secrets nunca em ficheiros". `op read` é instantâneo com biometric unlock activo |
| `WHISPERX_HF_TOKEN_OP_REF` configurável (default `op://Private/HuggingFace/token`) | Permite a outros utilizadores do dotfiles apontar para o seu vault sem editar o script. Default razoável para o caso "começo do zero, ainda não tenho o item" — mensagem de erro orienta exactamente o que criar |
| Modelos descarregam lazy ao 1º uso (não no `setup/whisperx.sh`) | Total ~3.5 GB e dependem de URLs HF que podem mudar; o whisperx tem a sua lógica de cache + retry. Forçar download no setup duplicaria responsabilidade e poderia falhar antes de o user ter o token configurado. Lazy é mais simples e idempotente |
| Output em `~/Desktop/` por defeito (mesma decisão do `transcribe`) | Consistência entre as duas ferramentas; reduz carga cognitiva ("onde está o `.txt`?") |
| Pos-flight existence check com mensagem de erro listando causas comuns | whisperx pode falhar silenciosamente quando T&C de um dos modelos pyannote não foi aceite (HTTP 403 do HF, capturado e logado mas com exit 0). Sem o check, o user vê "✓" sem ficheiros. Listar T&C/scope/network como hipóteses poupa um round-trip de debug |
| `WHISPER_LANG=pt` (não `auto`) por defeito no `transcribe-diarize` | A diarização do pyannote degrada quando whisperx escolhe a língua errada — em audios curtos com pausas, `auto` por vezes detecta EN. Em PT regular, fixar `pt` é mais robusto |
| `HF_HUB_DISABLE_TELEMETRY=1` exportado dentro do script | `huggingface_hub` envia telemetria anónima (versão lib + nome do modelo, **nunca o input áudio**). Áudio é processado 100% local mesmo sem este flag, mas defesa-em-profundidade é gratuita — uma linha. `HF_HUB_OFFLINE=1` continua opt-in para quem queira garantir zero rede após o 1º download |
| `${SPEAKER_FLAGS[@]+"${SPEAKER_FLAGS[@]}"}` em vez de `"${SPEAKER_FLAGS[@]}"` | `/bin/bash` no macOS é 3.2 e com `set -u` trata array vazio como variável unbound (`SPEAKER_FLAGS[@]: unbound variable`). O idiomático `${arr[@]+"${arr[@]}"}` expande só se o array tiver pelo menos um elemento — bash ≥4.4 não precisa, mas o repo prioriza compatibilidade com o bash do sistema |
| `--compute_type int8` por defeito (vs `float32`) | faster-whisper em CPU corre ~2× mais rápido em INT8 quantizado, com perda de qualidade imperceptível em PT para diarização (verificado empiricamente em batch). CTranslate2 não tem MPS no Apple Silicon, portanto a alternativa "GPU" não existe — o speedup tem de vir de quantização. `WHISPERX_COMPUTE_TYPE` permite override (`float16`, `float32`) para casos sensíveis |
| `PYTHONWARNINGS=ignore::UserWarning` exportado por defeito | `pyannote.audio` importa `torchcodec` para decode acelerado, que falha a carregar as dylibs `libavutil.X.dylib` do ffmpeg do brew (rpath mismatch) e cai em soundfile/librosa silenciosamente. Funciona à mesma mas o warning aparece a cada invocação a poluir output útil. Suprimir todos os UserWarning é mais simples que filtrar por módulo e raramente esconde algo accionável em uso CLI; `PYTHONWARNINGS=default` reverte para debug |
| Modelo de diarização default `pyannote/speaker-diarization-community-1` (não `speaker-diarization-3.1`) | whisperx mudou recentemente o default de diarização do `3.1` para o `community-1` — modelo novo, licença mais permissiva e activo no upstream. Aceitar T&C do `3.1` (instinto óbvio dada a versão na documentação antiga) não basta; o pipeline pede o `community-1` em runtime e dá `403 GatedRepoError`. Doc + mensagem de erro do script foram alinhadas com o default actual para evitar este round-trip |
| `--output_format all` + cleanup, em vez de `--output_format srt --output_format txt` | whisperx CLI aceita **apenas um** valor em `--output_format` (último ganha quando passados múltiplos — argparse com `choices`, não `action='append'`). Passar dois flags resultava em só o último (`txt`) ser gerado e o `.srt` desaparecer silenciosamente, falhando a post-flight check com mensagem enganadora. `all` gera todos os formatos (txt, srt, vtt, json, tsv, aud); apagamos os 4 extras para manter o output igual ao do `transcribe.sh` (txt + srt) |

### CLIs COB — 2026-08-24

| Decisão | Racional |
|---|---|
| `cob-press` instalado pelo mesmo `setup/cob-tools.sh` (clone → `~/.local/src/cob-press`, `npm install`, `npm run build`, `npm link`) | Mesmo padrão do `cob-aia`: repo privado da org `cob` via SSH, com passo de build e sem branch preferida. `npm link` deixa o comando `cob-press` sempre a apontar para o working copy, e o `git pull --ff-only` do setup actualiza-o em cada bootstrap |
| `check_engines` antes do `npm install` em cada repo COB | O `cob-press` declara `engines: {node: ">=24", npm: ">=11.16.0"}` com `engine-strict` — o npm sai com **EBADENGINE** (erro, não aviso) e o `set -e` do setup matava tudo o que vinha a seguir (Utils, cob-health, cmd-line-importer). O check lê o `engines` do `package.json` já clonado: npm aquém actualiza-se sozinho (`npm i -g npm@<mínimo>`, dentro da versão de node activa do nvm); node aquém dá aviso com o comando `nvm` a correr e salta **só** esse repo |
| `cob-cli` a seguir a branch `master` (era a branch `beta` mais recente) — 2026-09-08 | Queremos a versão estável instalada, não a pré-release. A resolução de branch no `link_cob_repo` passa a preferir a branch remota com o nome **exacto** e só depois cai no match por substring/mais recente (o `beta` → `beta-1.2.3` continua a funcionar). O `git pull` inicial passou para **depois** do checkout: clones antigos ficaram numa branch beta que pode já não existir no remoto e o pull rebentava com o `set -e` |
| `package-lock.json` descartado antes do checkout/pull dos repos COB — 2026-09-08 | O `npm install` do próprio setup reescreve o lock (npm/node diferentes de quem o gerou) e no bootstrap seguinte o `git checkout` recusava trocar de branch — e o `set -e` levava com o resto do bootstrap à frente. Descarta-se **só** o lock e **só** se o `package.json` estiver limpo: com o `package.json` alterado é mudança de dependências a sério. Qualquer outra alteração por commitar faz saltar o checkout/pull com aviso, em vez de ser deitada fora |
| `setup/cob-tools.sh` não fatal no `bootstrap.sh` — 2026-09-08 | Um repo COB inacessível ou com trabalho por commitar deixava de fora tudo o que vinha a seguir (whisper, whisperx, macOS defaults). Agora avisa e o bootstrap continua |

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
