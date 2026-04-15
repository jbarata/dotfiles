# Dotfiles

Configurações de trabalho centralizadas para macOS, geridas com [GNU Stow](https://www.gnu.org/software/stow/) e sincronizadas via git.

## Máquinas

| Máquina | Arquitetura | Homebrew |
|---------|-------------|----------|
| iMac (Retina 5K, 27", 2020) | Intel (x86_64) | `/usr/local` |
| MacBook (M3) | Apple Silicon (arm64) | `/opt/homebrew` |

## Aplicações geridas

- **Git** — `.gitconfig`, `.gitignore_global`, commit signing via 1Password
- **Shell (Zsh)** — `.zshrc`, `.zprofile`, `.aliases`, `.exports`
- **SSH** — config com 1Password SSH agent
- **iTerm2** — preferências carregadas de diretoria custom
- **VS Code** — settings, keybindings, snippets, lista de extensões
- **Claude Code** — settings globais e CLAUDE.md
- **Übersicht** — clone automático do [repo de widgets](https://github.com/mimes70/Ubersicht-Widgets)

## Setup rápido (nova máquina)

```bash
git clone https://github.com/mimes70/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x bootstrap.sh
./bootstrap.sh
```

O bootstrap deteta automaticamente se é Intel ou Apple Silicon.

## Estrutura

```
git/            → stow → ~/.gitconfig, ~/.gitignore_global
shell/          → stow → ~/.zshrc, ~/.zprofile, ~/.aliases, ~/.exports
ssh/            → stow → ~/.ssh/config
iterm2/         → iTerm2 carrega diretamente desta diretoria
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

## Segredos

Segredos são geridos pelo **1Password CLI** (`op`). Nunca são guardados em ficheiros — são obtidos a pedido via `op item get` ou `op read`. O SSH agent do 1Password elimina a necessidade de chaves privadas no disco.
