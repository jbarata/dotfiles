# Claude Code — Instruções Globais

## Contexto
- Dois Macs: iMac (Intel, 2020) e MacBook (M3, Apple Silicon)
- Homebrew: `/usr/local` no iMac, `/opt/homebrew` no MacBook
- 1Password CLI configurado para SSH agent e git commit signing
- Dotfiles geridos em: https://github.com/mimes70/dotfiles

## Preferências
- Língua: Português (PT)
- Editor CLI: vim
- Editor gráfico: VS Code (VISUAL)
- Terminal: Ghostty (JetBrains Mono, Catppuccin Mocha)
- Shell: Zsh (vi mode, fzf, autosuggestions, syntax-highlighting)
- Node: NVM (lazy loading, sem brew node)
- Segredos: 1Password CLI (`op read`), nunca em ficheiros

## Estrutura dotfiles
- `shell/` → stow → ~/.zshrc, .zprofile, .aliases, .exports
- `git/` → stow → ~/.gitconfig
- `ssh/` → stow → ~/.ssh/config
- `ghostty/` → stow → ~/.config/ghostty/config
- `vscode/` → symlink manual (setup/symlinks.sh)
- `claude/` → symlink manual (setup/symlinks.sh)
- `machine/` → overrides por máquina (imac.sh, macbook.sh)

## Git
- Commits assinados via SSH (1Password)
- Remotes via SSH (git@github.com)
- `pull.rebase = true`
- `push.autoSetupRemote = true`
- `init.defaultBranch = main`
