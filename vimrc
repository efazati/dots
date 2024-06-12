colorscheme desert
set t_Co=256
set nowritebackup

syntax on
set number
set ma

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
nnoremap q: <nop>
nnoremap Q <nop>

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
set tabstop=4
set softtabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set smarttab


" ================ Scrolling ========================

set scrolloff=8         "Start scrolling when we're 8 lines away from margins
set sidescrolloff=15
set sidescroll=1

nnoremap <C-Up> :m-2<CR>
nnoremap <C-Down> :m+<CR>
inoremap <C-Up> <Esc>:m-2<CR>
inoremap <C-Down> <Esc>:m+<CR>

" ================ Multi select ========================
let g:VM_mouse_mappings = 1
let g:VM_maps = {}
let g:VM_maps['Find Under']         = '<C-d>'           " replace C-n
let g:VM_maps['Find Subword Under'] = '<C-d>'           " replace visual C-n
nmap   <C-LeftMouse>         <Plug>(VM-Mouse-Cursor)
nmap   <C-RightMouse>        <Plug>(VM-Mouse-Word)  
nmap   <M-C-RightMouse>      <Plug>(VM-Mouse-Column)
let g:VM_maps["Undo"] = 'u'
let g:VM_maps["Redo"] = '<C-r>'

let g:VM_maps["Select Cursor Down"] = '<C-j>'
let g:VM_maps["Select Cursor Up"] = '<C-k>'
let g:VM_maps["Select All"] = '<C-a>' 
let g:VM_maps["Visual All"] = '<M-a>' 

let g:VM_theme = 'codedark'
let g:VM_highlight_matches = 'red'

" ======== Move line up/Down =====================
" Move line up with Alt-Up
nnoremap <Esc><Up> :m .-2<CR>==
nnoremap <Esc>[1;3A :m .-2<CR>==
inoremap <Esc><Up> <Esc>:m .-2<CR>==gi
inoremap <Esc>[1;3A <Esc>:m .-2<CR>==gi
vnoremap <Esc><Up> :m '<-2<CR>gv=gv
vnoremap <Esc>[1;3A :m '<-2<CR>gv=gv

" Move line down with Alt-Down
nnoremap <Esc><Down> :m .+1<CR>==
nnoremap <Esc>[1;3B :m .+1<CR>==
inoremap <Esc><Down> <Esc>:m .+1<CR>==gi
inoremap <Esc>[1;3B <Esc>:m .+1<CR>==gi
vnoremap <Esc><Down> :m '>+1<CR>gv=gv
vnoremap <Esc>[1;3B :m '>+1<CR>gv=gv

" Map Shift+Tab to unindent in normal and visual modes
execute "set <S-Tab>=\e[Z"
nnoremap <S-Tab> <<
vnoremap <S-Tab> <gv

" For insert and command-line mode, map Shift+Tab to insert a literal Tab character
inoremap <S-Tab> <C-D>
cnoremap <S-Tab> <C-D>
