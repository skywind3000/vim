"======================================================================
"
" viminit.vim - Vim initialize script
"
" Maintainer: skywind3000 (at) gmail.com
" Last Modified: 2021/03/08 13:40
"
" Tiny script which makes vim become neat and handy, supports vim.tiny
"
"======================================================================

" vim: set et fenc=utf-8 ff=unix sts=8 sw=4 ts=4 :


"----------------------------------------------------------------------
" core initialize
"----------------------------------------------------------------------
set nocompatible

set backspace=eol,start,indent
set autoindent
set cindent
set winaltkeys=no
set nowrap
set wildignore=*.swp,*.bak,*.pyc,*.obj,*.o,*.class
set ttimeout
set ttimeoutlen=50
set cmdheight=1
set ruler
set nopaste
set display=lastline

set shiftwidth=4
set softtabstop=4
set noexpandtab
set tabstop=4

if has('multi_byte')
	set encoding=utf-8
	set fileencoding=utf-8
	set fileencodings=ucs-bom,utf-8,gbk,gb18030,big5,euc-jp,latin1
endif

set formatoptions+=m
set formatoptions+=B
set showcmd


"----------------------------------------------------------------------
" map CTRL_HJKL to move cursor in all mode
" config terminal bind <backspace> to ASCII code 127
"----------------------------------------------------------------------
noremap <C-h> <left>
noremap <C-j> <down>
noremap <C-k> <up>
noremap <C-l> <right>
inoremap <C-h> <left>
inoremap <C-j> <down>
inoremap <C-k> <up>
inoremap <C-l> <right>


"----------------------------------------------------------------------
" buffer keymap
"----------------------------------------------------------------------
noremap <silent>\bn :bn<cr>
noremap <silent>\bp :bp<cr>
noremap <silent>\bm :bm<cr>
noremap <silent>\bv :vs<cr>
noremap <silent>\bs :sp<cr>
noremap <silent>\bd :bdelete<cr>
noremap <silent>\bl :ls<cr>
noremap <silent>\bb :ls<cr>:b


"----------------------------------------------------------------------
" window keymaps
"----------------------------------------------------------------------
noremap <silent>\ww <c-w>w
noremap <silent>\wv <c-w>v
noremap <silent>\ws <c-w>s
noremap <silent>\wh <c-w>h
noremap <silent>\wj <c-w>j
noremap <silent>\wk <c-w>k
noremap <silent>\wl <c-w>l
noremap <silent>\wc <c-w>c
noremap <silent>\wo <c-w>o
noremap <silent>\wp <c-w>p
noremap <silent>\w1 :1wincmd w<cr>
noremap <silent>\w2 :2wincmd w<cr>
noremap <silent>\w3 :3wincmd w<cr>
noremap <silent>\w4 :4wincmd w<cr>
noremap <silent>\w5 :5wincmd w<cr>
noremap <silent>\w6 :6wincmd w<cr>
noremap <silent>\w7 :7wincmd w<cr>
noremap <silent>\w8 :8wincmd w<cr>
noremap <silent>\w9 :9wincmd w<cr>


"----------------------------------------------------------------------
" tab keymap
"----------------------------------------------------------------------
noremap <silent>\tc :tabnew<cr>
noremap <silent>\tq :tabclose<cr>
noremap <silent>\tn :tabnext<cr>
noremap <silent>\tp :tabprev<cr>
noremap <silent>\to :tabonly<cr>
noremap <silent>\th :-tabmove<cr>
noremap <silent>\tl :+tabmove<cr>
noremap <silent>\ta g<tab>
noremap <silent>\1 :tabn 1<cr>
noremap <silent>\2 :tabn 2<cr>
noremap <silent>\3 :tabn 3<cr>
noremap <silent>\4 :tabn 4<cr>
noremap <silent>\5 :tabn 5<cr>
noremap <silent>\6 :tabn 6<cr>
noremap <silent>\7 :tabn 7<cr>
noremap <silent>\8 :tabn 8<cr>
noremap <silent>\9 :tabn 9<cr>
noremap <silent>\0 :tabn 10<cr>
noremap <silent><s-tab> :tabnext<CR>
inoremap <silent><s-tab> <ESC>:tabnext<CR>


"----------------------------------------------------------------------
" tab keymap in gvim
"----------------------------------------------------------------------
if has('gui_running')
	noremap <silent><c-tab> :tabprev<CR>
	inoremap <silent><c-tab> <ESC>:tabprev<CR>
	noremap <silent><m-1> :tabn 1<cr>
	noremap <silent><m-2> :tabn 2<cr>
	noremap <silent><m-3> :tabn 3<cr>
	noremap <silent><m-4> :tabn 4<cr>
	noremap <silent><m-5> :tabn 5<cr>
	noremap <silent><m-6> :tabn 6<cr>
	noremap <silent><m-7> :tabn 7<cr>
	noremap <silent><m-8> :tabn 8<cr>
	noremap <silent><m-9> :tabn 9<cr>
	noremap <silent><m-0> :tabn 10<cr>
	inoremap <silent><m-1> <ESC>:tabn 1<cr>
	inoremap <silent><m-2> <ESC>:tabn 2<cr>
	inoremap <silent><m-3> <ESC>:tabn 3<cr>
	inoremap <silent><m-4> <ESC>:tabn 4<cr>
	inoremap <silent><m-5> <ESC>:tabn 5<cr>
	inoremap <silent><m-6> <ESC>:tabn 6<cr>
	inoremap <silent><m-7> <ESC>:tabn 7<cr>
	inoremap <silent><m-8> <ESC>:tabn 8<cr>
	inoremap <silent><m-9> <ESC>:tabn 9<cr>
	inoremap <silent><m-0> <ESC>:tabn 10<cr>
	noremap <silent><m-up> :tabprev<cr>
	noremap <silent><m-down> :tabnext<cr>
	inoremap <silent><m-up> <ESC>:tabprev<cr>
	inoremap <silent><m-down> <ESC>:tabnext<cr>
endif


"----------------------------------------------------------------------
" tab keymap in macvim
"----------------------------------------------------------------------
if has("gui_macvim")
	set macmeta
	noremap <silent><c-tab> :tabprev<CR>
	inoremap <silent><c-tab> <ESC>:tabprev<CR>
	noremap <silent><d-1> :tabn 1<cr>
	noremap <silent><d-2> :tabn 2<cr>
	noremap <silent><d-3> :tabn 3<cr>
	noremap <silent><d-4> :tabn 4<cr>
	noremap <silent><d-5> :tabn 5<cr>
	noremap <silent><d-6> :tabn 6<cr>
	noremap <silent><d-7> :tabn 7<cr>
	noremap <silent><d-8> :tabn 8<cr>
	noremap <silent><d-9> :tabn 9<cr>
	noremap <silent><d-0> :tabn 10<cr>
	inoremap <silent><d-1> <ESC>:tabn 1<cr>
	inoremap <silent><d-2> <ESC>:tabn 2<cr>
	inoremap <silent><d-3> <ESC>:tabn 3<cr>
	inoremap <silent><d-4> <ESC>:tabn 4<cr>
	inoremap <silent><d-5> <ESC>:tabn 5<cr>
	inoremap <silent><d-6> <ESC>:tabn 6<cr>
	inoremap <silent><d-7> <ESC>:tabn 7<cr>
	inoremap <silent><d-8> <ESC>:tabn 8<cr>
	inoremap <silent><d-9> <ESC>:tabn 9<cr>
	inoremap <silent><d-0> <ESC>:tabn 10<cr>
	noremap <silent><d-o> :browse tabnew<cr>
	inoremap <silent><d-o> <ESC>:browse tabnew<cr>
endif


"----------------------------------------------------------------------
" gvim keymaps
"----------------------------------------------------------------------
if has('gui_running')
	noremap <silent><m-t> :tabnew<cr>
	inoremap <silent><m-t> <ESC>:tabnew<cr>
	noremap <silent><m-w> :tabclose<cr>
	inoremap <silent><m-w> <ESC>:tabclose<cr>
	noremap <silent><m-v> :close<cr>
	inoremap <silent><m-v> <ESC>:close<cr>
	noremap <m-s> :w<cr>
	inoremap <m-s> <esc>:w<cr>
endif


"----------------------------------------------------------------------
" miscs
"----------------------------------------------------------------------
set scrolloff=2
set showmatch
set matchtime=3
set listchars=tab:\|\ ,trail:.,extends:>,precedes:<

" window management
noremap <tab>h <c-w>h
noremap <tab>j <c-w>j
noremap <tab>k <c-w>k
noremap <tab>l <c-w>l
noremap <tab>w <c-w>w
noremap <tab>c <c-w>c
noremap <tab>+ <c-w>+
noremap <tab>- <c-w>-
noremap <tab>, <c-w>< 
noremap <tab>. <c-w>>
noremap <tab>= <c-w>=
noremap <tab>s <c-w>s
noremap <tab>v <c-w>v
noremap <tab>o <c-w>o
noremap <tab>p <c-w>p

" tab enhancement
noremap <silent><tab> <nop>
noremap <silent><tab>f <c-i>
noremap <silent><tab>b <c-o>

" insert mode as emacs
inoremap <c-a> <home>
inoremap <c-e> <end>
inoremap <c-d> <del>
inoremap <c-_> <c-k>
inoremap <c-x><c-a> <c-a>
inoremap <c-x><c-b> <c-e>

" faster command mode
cnoremap <c-h> <left>
cnoremap <c-j> <down>
cnoremap <c-k> <up>
cnoremap <c-l> <right>
cnoremap <c-a> <home>
cnoremap <c-e> <end>
cnoremap <c-f> <right>
cnoremap <c-b> <left>
cnoremap <c-d> <del>
cnoremap <c-_> <c-k>
cnoremap <c-o> <c-d>
cnoremap <c-x><c-f> <c-f>
cnoremap <c-x><c-a> <c-a>
cnoremap <c-x><c-e> <c-e>
cnoremap <c-x><c-d> <c-d>

" quit all
noremap <silent>Q :confirm qall<cr>


"----------------------------------------------------------------------
" unimpaired
"----------------------------------------------------------------------
nnoremap <silent>[a :previous<cr>
nnoremap <silent>]a :next<cr>
nnoremap <silent>[A :first<cr>
nnoremap <silent>]A :last<cr>
nnoremap <silent>[b :bprevious<cr>
nnoremap <silent>]b :bnext<cr>
nnoremap <silent>[w :tabprevious<cr>
nnoremap <silent>]w :tabnext<cr>
nnoremap <silent>[W :tabfirst<cr>
nnoremap <silent>]W :tablast<cr>
nnoremap <silent>[q :cprevious<cr>
nnoremap <silent>]q :cnext<cr>
nnoremap <silent>[Q :cfirst<cr>
nnoremap <silent>]Q :clast<cr>
nnoremap <silent>[l :lprevious<cr>
nnoremap <silent>]l :lnext<cr>
nnoremap <silent>[L :lfirst<cr>
nnoremap <silent>]L :llast<cr>
nnoremap <silent>[t :tprevious<cr>
nnoremap <silent>]t :tnext<cr>
nnoremap <silent>[T :tfirst<cr>
nnoremap <silent>]T :tlast<cr>

" unimpaired options
nnoremap <silent>[oc :setl cursorline<cr>
nnoremap <silent>]oc :setl nocursorline<cr>
nnoremap <silent>[os :setl spell<cr>
nnoremap <silent>]os :setl nospell<cr>
nnoremap <silent>[op :setl paste<cr>
nnoremap <silent>]op :setl nopaste<cr>
nnoremap <silent>[ow :setl wrap<cr>
nnoremap <silent>]ow :setl nowrap<cr>



