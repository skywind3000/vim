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
noremap <silent>\1 1gt
noremap <silent>\2 2gt
noremap <silent>\3 3gt
noremap <silent>\4 4gt
noremap <silent>\5 5gt
noremap <silent>\6 6gt
noremap <silent>\7 7gt
noremap <silent>\8 8gt
noremap <silent>\9 9gt
noremap <silent>\0 10gt
noremap <silent><s-tab> :tabnext<CR>
inoremap <silent><s-tab> <ESC>:tabnext<CR>


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


"----------------------------------------------------------------------
" unimpaired
"----------------------------------------------------------------------
nnoremap <silent>[a :previous<cr>
nnoremap <silent>]a :next<cr>
nnoremap <silent>[A :first<cr>
nnoremap <silent>]A :last<cr>
nnoremap <silent>[b :bprevious<cr>
nnoremap <silent>]b :bnext<cr>
nnoremap <silent>[B :bfirst<cr>
nnoremap <silent>]B :blast<cr>
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


