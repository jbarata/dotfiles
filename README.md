# Dotfiles

Configurações de trabalho centralizadas para macOS, geridas com [GNU Stow](https://www.gnu.org/software/stow/) e sincronizadas via git.

## Máquinas

| Máquina | Arquitetura | Homebrew |
|---------|-------------|----------|
| iMac (Retina 5K, 27", 2020) | Intel (x86_64) | `/usr/local` |
| MacBook (M3) | Apple Silicon (arm64) | `/opt/homebrew` |

## Aplicações geridas

- **Git** — `.gitconfig`, commit signing via 1Password SSH
- **Shell (Zsh)** — `.zshrc`, `.zprofile`, `.aliases`, `.exports` (vi mode, fzf, autosuggestions, syntax-highlighting)
- **SSH** — config com 1Password SSH agent + hosts de trabalho
- **Ghostty** — terminal GPU-accelerated (JetBrains Mono, Catppuccin Mocha)
- **VS Code** — settings, keybindings, extensões, dicionário PT
- **Claude Code** — settings globais e CLAUDE.md
- **Übersicht** — clone automático do [repo de widgets](https://github.com/mimes70/Ubersicht-Widgets)
- **NVM** — Node version manager (lazy loading)

## Setup rápido (nova máquina)

```bash
git clone https://github.com/mimes70/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

O bootstrap deteta automaticamente se é Intel ou Apple Silicon. Para pré-visualizar sem executar:

```bash
./bootstrap.sh --dry-run
```

## Estrutura

```
git/            → stow → ~/.gitconfig
shell/          → stow → ~/.zshrc, ~/.zprofile, ~/.aliases, ~/.exports
ssh/            → stow → ~/.ssh/config
ghostty/        → stow → ~/.config/ghostty/config
claude/         → symlink manual → ~/.claude/settings.json, ~/.claude/CLAUDE.md
vscode/         → symlink manual → ~/Library/.../Code/User/
machine/        → overrides por máquina (imac.sh, macbook.sh)
setup/          → scripts de instalação (symlinks, extensões, defaults)
ubersicht/      → clone/update do repo de widgets
```

## Sync diário

```bash
ds              # dotfiles status
da              # dotfiles add -p (stage interativo)
dc -m "msg"     # dotfiles commit
dp              # dotfiles push
dl              # dotfiles pull (na outra máquina)
```

### VS Code extensions

```bash
vscode-export   # exportar lista de extensões para o repo
vscode-import   # instalar extensões a partir da lista
```

### fzf

```bash
Ctrl+R          # pesquisa fuzzy no histórico
Ctrl+T          # pesquisa fuzzy de ficheiros
Alt+C           # pesquisa fuzzy de directórias (cache 24h)
fzf-refresh     # forçar actualização da cache Alt+C
```

## Segredos

Segredos são geridos pelo **1Password CLI** (`op`). Nunca são guardados em ficheiros — são obtidos a pedido via `op read`. O SSH agent do 1Password elimina a necessidade de chaves privadas no disco.

O SOPS AGE key é carregado on-demand: o wrapper `sops()` no `.zshrc` chama `op read` apenas na primeira invocação.
