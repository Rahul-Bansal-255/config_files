" Disable compatibility with vi which can cause unexpected issues.
set nocompatible

" Enable type file detection. Vim will be able to try to detect the type of file is use.
filetype on

" Enable plugins and load plugin for the detected file type.
filetype plugin on

" Load an indent file for the detected file type.
filetype indent on

" Enable syntax highlighting
syntax on

" Add line numbers to the file:
set number

" Wrap the text to next line
set wrap

" While searching though a file incrementally highlight matching characters as you type.
set incsearch
set hlsearch

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Show partial command you type in the last line of the screen.
set showcmd

" Show the mode you are on the last line.
set showmode

" Show matching brackets when text indicator is over them
set showmatch

" Sets how many lines of history VIM has to remember
set history=1000

" Enable auto completion menu after pressing TAB.
set wildmenu
set wildmode=list:longest,full

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf-8

" Set color schemes
colorscheme industry
set background=dark

" Q. What is difference between Vim's clipboard "unnamed" and
" "unnamedplus" settings?
"
" On Mac OS X and Windows, the [*] and [+] registers both point to the
" system clipboard so [unnamed] and [unnamedplus] have the same effect:
" the unnamed register is synchronized with the system clipboard.
"
" On Linux, you have essentially two clipboards: one is pretty much
" the same as in the other OSes ([Ctrl C] and [Ctrl V] in other programs,
" mapped to register [+] in Vim), the other is the "selection"
" clipboard (mapped to register [*] in Vim).
"
" Using only [unnamedplus] on Linux, Windows and Mac OS X allows you to:
"
" - [Ctrl C] in other programs and put in Vim with [p] on all three platforms,
" - yank in Vim with [y] and [Ctrl V] in other programs on all three platforms.
"
" If you also want to use Linux's "selection" clipboard, you will also
" need [unnamed].
"
" Here is a cross-platform value:
set clipboard^=unnamed,unnamedplus

" Q. What is the difference here vs [^=] & [+=]?
"
" Vim as three types of options: "string", "number", and "boolean".
" [^=] multiplies only in the context of "number" options but ['clipboard']
" is a "string" option where [^=] prepends the value and [+=] appends the value.

" Make a buffer modifiable
set modifiable

" Highlight cursor line underneath the cursor horizontally.
set cursorline

" Highlight cursor line underneath the cursor vertically.
set cursorcolumn
