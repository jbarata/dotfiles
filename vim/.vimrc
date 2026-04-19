" ~/.vimrc — Configuração Vim
" Gerido por: https://github.com/mimes70/dotfiles
" Editor secundário (VS Code é primário) — minimalista mas confortável

" =========================================================
" 1. Sintaxe e cores
" =========================================================
syntax on
set termguicolors
set background=dark

" Catppuccin Mocha (mesmo tema do Ghostty)
silent! colorscheme catppuccin_mocha

" =========================================================
" 2. Editor — defaults sensatos
" =========================================================
set number              " line numbers
set ruler               " posição cursor (linha,coluna)
set showcmd             " mostra comando em construção
set scrolloff=8         " margem ao scrollar
set sidescrolloff=8     " margem lateral
set wrap                " wrap longo
set linebreak           " wrap em palavras inteiras

" Indentação
set autoindent
set expandtab           " tab → spaces
set tabstop=4           " width visual
set shiftwidth=4        " indent automático
set softtabstop=4       " backspace remove 4 spaces

" Mouse e clipboard
set mouse=a
set clipboard=unnamed   " yank → clipboard sistema

" =========================================================
" 3. Pesquisa
" =========================================================
set ignorecase
set smartcase           " case-sensitive se houver maiúsculas
set hlsearch            " highlight matches (use :noh para limpar)
set incsearch           " pesquisa incremental

" =========================================================
" 4. Persistent undo
" =========================================================
set undofile
set undodir=~/.vim/undo
silent! call mkdir(expand('~/.vim/undo'), 'p')

" =========================================================
" 5. Backups e swap
" =========================================================
set nobackup
set nowritebackup
set noswapfile          " ficheiros .swp incomodam mais do que ajudam

" =========================================================
" 6. Performance
" =========================================================
set lazyredraw          " não redraw durante macros
set updatetime=300      " responsividade de plugins

" =========================================================
" 7. UI
" =========================================================
set laststatus=2        " sempre mostrar status line
set noshowmode          " esconder -- INSERT -- (airline já mostra)
set signcolumn=yes      " coluna de sinais sempre visível

" Cursor shape por modo (DECSCUSR). O Ghostty tem `cursor-style = bar`
" como default global; estas sequências sobrepõem-no dentro do vim para
" ter bloco sobre o caracter em normal mode.
let &t_SI = "\e[6 q"    " insert  → bar
let &t_SR = "\e[4 q"    " replace → underline
let &t_EI = "\e[2 q"    " normal  → block

" =========================================================
" 8. Leader e mappings
" =========================================================
let mapleader = ","

" Limpar highlight de pesquisa
nnoremap <silent> <leader>n :noh<CR>

" Save com leader+w
nnoremap <leader>w :w<CR>

" Quit com leader+q
nnoremap <leader>q :q<CR>

" Toggle line numbers
nnoremap <leader>l :set number!<CR>

" =========================================================
" 9. Plugins (instalados em ~/.vim/pack/dotfiles/start/)
" =========================================================

" --- vim-airline ---
let g:airline_theme = 'catppuccin_mocha'
let g:airline_powerline_fonts = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#tabline#enabled = 1
