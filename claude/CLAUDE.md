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

## Propagação de alterações (IMPORTANTE)

Sempre que alterares funcionalidade no repo dotfiles — adicionar/remover/modificar
um atalho, script em `bin/`, variável de ambiente, alias, config de app, etc. —
tens de **repercutir a alteração em todos os artefactos de documentação**,
no mesmo commit:

1. **`README.md`** (obrigatório sempre que há mudança de funcionalidade)
   - Secção de uso relevante (ex.: "skhd", "Safari → Notes", "fzf", etc.)
   - Entrada na árvore "Estrutura" se ficheiros/pastas mudaram
   - Entrada em "Decisões" com tabela `| Decisão | Racional |` datada,
     explicando **o porquê** (não só o quê)

2. **`skhd-help.widget`** (`ubersicht/widgets/skhd-help.widget/index.coffee`)
   — obrigatório para atalhos skhd novos ou modificados. Adiciona/actualiza
   um `<div class="item"><kbd>…</kbd><span>…</span></div>` na secção
   apropriada (Apps / Leader cob / Leader personal / Leader clients /
   Leader review / Ajuda).

3. **`anki/cards.txt`** — quando a mudança introduz conhecimento
   não-trivial que vale a pena memorizar (atalhos, comandos, decisões
   arquitecturais, gotchas). Formato TSV: `guid\tFront\tBack\tTags`.
   Gerar GUID único (ex.: `skXX1aB2cD`) seguindo a convenção da secção.
   Não é obrigatório para mudanças triviais (typos, refactor sem impacto
   no uso).

4. **`skhdrc`** (`skhd/.config/skhd/skhdrc`) — se o atalho envolve skhd,
   actualiza o bloco de convenções no topo do ficheiro (secção `#
   Convenções de teclas`).

Checklist mental antes de commitar funcionalidade nova:
- [ ] Código funciona
- [ ] README.md: uso + estrutura + decisões
- [ ] skhd-help.widget (se atalho)
- [ ] skhdrc convenções (se atalho)
- [ ] anki/cards.txt (se há knowledge útil)
- [ ] Tudo no mesmo commit (não commits separados de "docs follow-up")

Razão: o README é a memória persistente entre sessões do Claude Code; o
widget é a cheatsheet acessível por `⌃⌥⌘ '`; o Anki é revisão activa.
Desalinhamento entre estes três e o código = divergência silenciosa que
custa tempo a detectar depois.
