let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'https://github.com/preservim/nerdtree'
nnoremap <leader>on :NERDTreeFocus<CR>
nnoremap <leader>cn :NERDTreeClose<CR>

Plug 'https://github.com/dense-analysis/ale'
let g:ale_linters_explicit = 1
let g:ale_linters = {
            \ 'sh': ['shellcheck'],
            \ 'zsh': ['shell'],
            \ 'bash': ['shell'],
            \ 'csh': ['shell'],
            \ 'help': [],
            \ 'python': ['flake8', 'mypy', 'pylint'],
            \ 'vim': ['vint'],
            \}
let g:ale_completion_enabled = 1
nnoremap <Leader>tl :ALEToggle<cr> " linter toggle

Plug 'https://github.com/sheerun/vim-polyglot'

call plug#end()


set nocompatible
filetype on
filetype plugin on
filetype indent on
syntax on
set number
set shiftwidth=4
set tabstop=4
set expandtab
set wrap
set incsearch
set ignorecase
set smartcase
set showcmd
set showmode
set showmatch
set hlsearch
set history=1000
set wildmenu
set wildmode=list:longest,full
set encoding=utf-8
colorscheme industry
set background=dark
set clipboard=unnamedplus
set modifiable
set cursorline
set cursorcolumn
