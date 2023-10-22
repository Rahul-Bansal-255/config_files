" Reference https://github.com/junegunn/vim-plug/wiki/tips#automatic-installation

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

Plug 'https://github.com/tpope/vim-fugitive'

Plug 'https://github.com/preservim/nerdtree'
nnoremap <leader>n :NERDTreeFocus<CR>

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'https://github.com/dense-analysis/ale'
Plug 'https://github.com/sheerun/vim-polyglot'
Plug 'https://github.com/mg979/vim-visual-multi'

call plug#end()

" Reference https://www.freecodecamp.org/news/vimrc-configuration-guide-customize-your-vim-editor/
" Reference Sandeep Kapse's .vimrc

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


" Notes

" To enable paste mode in vim
" :set paste
" :set nopaste
" In insert mode CTRL+[ works as <ESC>
