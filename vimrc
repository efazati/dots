colorscheme desert
set t_Co=256
set nowritebackup

syntax on
set number
set ma
set tabstop=4
set softtabstop=4
set expandtab

set showcmd
set cursorline
filetype indent on
set clipboard=unnamedplus
set wildmenu
set lazyredraw
set showmatch
set incsearch 
set hlsearch 
hi Search ctermfg=white 
nnoremap <esc> :noh<return><esc>

nnoremap <esc>^[ <esc>^[

set ruler

" let g:ycm_path_to_python_interpreter="/usr/bin/python"
" set directory^=$HOME/.vim/tmp//

" m<F2><F2><F2>ap <F2> :!ls<CR>:e

set backspace=indent,eol,start  "Allow backspace in insert mode
set history=1000                "Store lots of :cmdline history
set autoread                    "Reload files changed outside vim
set hidden


" ================ Turn Off Swap Files ==============

set noswapfile
set nobackup
set nowb

" ================ Persistent Undo ==================
" Keep undo history across sessions, by storing in file.
" Only works all the time.
if has('persistent_undo') && isdirectory(expand('~').'/.vim/backups')
  silent !mkdir ~/.vim/backups > /dev/null 2>&1
  set undodir=~/.vim/backups
  set undofile
endif

" ================ Indentation ======================

set autoindent
set smartindent
set smarttab


" ================ Scrolling ========================

set scrolloff=8         "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=1

nnoremap <S-Up> :m-2<CR>
nnoremap <S-Down> :m+<CR>
inoremap <S-Up> <Esc>:m-2<CR>
inoremap <S-Down> <Esc>:m+<CR>
