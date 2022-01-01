"======================================================================
"
" keymaps.vim - keymaps start with using <space>
"
" Created by skywind on 2016/10/12
" Last Modified: 2018/05/02 13:05
"
"======================================================================

"----------------------------------------------------------------------
" VimTools
"----------------------------------------------------------------------
for s:index in range(10)
	let s:button = (s:index > 0)? 'F'.s:index : 'F10'
	exec 'noremap <space>'.s:index.' :VimTool ' . s:index . '<cr>'
	if has('gui_running')
		exec "noremap <C-".s:button."> :AsyncTask task-c-f".s:index . '<cr>'
		exec "inoremap <C-".s:button."> <ESC>:AsyncTask task-c-f".s:index . '<cr>'
	endif
endfor


" keymap for VimTool
if (has('gui_running') || has('nvim')) && (has('win32') || has('win64'))
	let s:keys = [')', '!', '@', '#', '$', '%', '^', '&', '*', '(']
	for s:index in range(10)
		let s:name = ''.s:index
		if s:index == 0 | let s:name = '10' | endif
		exec 'noremap <silent><M-'.s:keys[s:index].'> :AsyncTask task-f'.s:index.'<cr>'
		exec 'inoremap <silent><M-'.s:keys[s:index].'> <ESC>:AsyncTask task-f'.s:index.'<cr>'
	endfor
else
	" require to config terminal to remap key alt-shift+? to '\033[{0}?~'
	for s:index in range(10)
		let s:name = ''.s:index
		if s:index == 0 | let s:name = '10' | endif
	endfor
endif


"----------------------------------------------------------------------
" window control
"----------------------------------------------------------------------
noremap <silent><space>= :resize +3<cr>
noremap <silent><space>- :resize -3<cr>
noremap <silent><space>, :vertical resize -3<cr>
noremap <silent><space>. :vertical resize +3<cr>

noremap <silent><space>hh :nohl<cr>
noremap <silent><bs> :nohl<cr>:redraw!<cr>
noremap <silent><tab>, :call Tab_MoveLeft()<cr>
noremap <silent><tab>. :call Tab_MoveRight()<cr>
noremap <silent><tab>6 :VinegarOpen leftabove vs<cr>
noremap <silent><tab>7 :VinegarOpen vs<cr>
noremap <silent><tab>8 :VinegarOpen belowright sp<cr>
noremap <silent><tab>9 :VinegarOpen tabedit<cr>
noremap <silent><tab>0 :exe "NERDTree ".fnameescape(expand("%:p:h"))<cr>
noremap <silent><tab>y :exe "NERDTree ".fnameescape(asclib#path#get_root("%"))<cr>
noremap <silent><tab>g <c-w>p

noremap <silent><space>ha :GuiSignRemove
			\ errormarker_error errormarker_warning<cr>

" replace
noremap <space>p viw"0p
noremap <space>y yiw

" fast save
noremap <C-S> :w<cr>
inoremap <C-S> <ESC>:w<cr>

noremap <silent><m-t> :tabnew<cr>
inoremap <silent><m-t> <ESC>:tabnew<cr>
noremap <silent><m-w> :tabclose<cr>
inoremap <silent><m-w> <ESC>:tabclose<cr>
noremap <silent><m-v> :close<cr>
inoremap <silent><m-v> <esc>:close<cr>
noremap <m-s> :w<cr>
inoremap <m-s> <esc>:w<cr>


"----------------------------------------------------------------------
" tasks
"----------------------------------------------------------------------
noremap <space>te :AsyncTaskEdit<cr>
noremap <space>tg :AsyncTaskEdit!<cr>
noremap <space>tfb :AsyncTask file-build<cr>
noremap <space>tfr :AsyncTask file-run<cr>
noremap <space>tfd :AsyncTask file-debug<cr>
noremap <space>tpi :AsyncTask project-init<cr>
noremap <space>tpb :AsyncTask project-build<cr>
noremap <space>tpr :AsyncTask project-run<cr>
noremap <space>tpd :AsyncTask project-debug<cr>


"----------------------------------------------------------------------
" Movement Enhancement
"----------------------------------------------------------------------
noremap <M-h> b
noremap <M-l> w
noremap <M-j> gj
noremap <M-k> gk
inoremap <M-h> <c-left>
inoremap <M-l> <c-right>
inoremap <M-j> <c-\><c-o>gj
inoremap <M-k> <c-\><c-o>gk
inoremap <M-y> <c-\><c-o>d$
cnoremap <M-h> <c-left>
cnoremap <M-l> <c-right>
cnoremap <M-b> <c-left>
cnoremap <M-f> <c-right>


"----------------------------------------------------------------------
" fast window switching: ALT+SHIFT+HJKL
"----------------------------------------------------------------------
noremap <m-H> <c-w>h
noremap <m-L> <c-w>l
noremap <m-J> <c-w>j
noremap <m-K> <c-w>k
inoremap <m-H> <esc><c-w>h
inoremap <m-L> <esc><c-w>l
inoremap <m-J> <esc><c-w>j
inoremap <m-K> <esc><c-w>k

if has('terminal') && exists(':terminal') == 2 && has('patch-8.1.1')
	set termwinkey=<c-_>
	tnoremap <m-H> <c-_>h
	tnoremap <m-L> <c-_>l
	tnoremap <m-J> <c-_>j
	tnoremap <m-K> <c-_>k
	tnoremap <m-q> <c-\><c-n>
	tnoremap <m-1> <c-_>1gt
	tnoremap <m-2> <c-_>2gt
	tnoremap <m-3> <c-_>3gt
	tnoremap <m-4> <c-_>4gt
	tnoremap <m-5> <c-_>5gt
	tnoremap <m-6> <c-_>6gt
	tnoremap <m-7> <c-_>7gt
	tnoremap <m-8> <c-_>8gt
	tnoremap <m-9> <c-_>9gt
	tnoremap <m-0> <c-_>10gt
elseif has('nvim')
	tnoremap <m-H> <c-\><c-n><c-w>h
	tnoremap <m-L> <c-\><c-n><c-w>l
	tnoremap <m-J> <c-\><c-n><c-w>j
	tnoremap <m-K> <c-\><c-n><c-w>k
	tnoremap <m-q> <c-\><c-n>
	tnoremap <m-1> <c-\><c-n>1gt
	tnoremap <m-2> <c-\><c-n>2gt
	tnoremap <m-3> <c-\><c-n>3gt
	tnoremap <m-4> <c-\><c-n>4gt
	tnoremap <m-5> <c-\><c-n>5gt
	tnoremap <m-6> <c-\><c-n>6gt
	tnoremap <m-7> <c-\><c-n>7gt
	tnoremap <m-8> <c-\><c-n>8gt
	tnoremap <m-9> <c-\><c-n>9gt
	tnoremap <m-0> <c-\><c-n>10gt
endif


"----------------------------------------------------------------------
" gui hotkeys - alt + ?
"----------------------------------------------------------------------
if has('gui_running') || (has('nvim') && (has('win32') || has('win64')))
	noremap <silent><A-o> :call Open_Browse(2)<cr>
	inoremap <silent><A-o> <ESC>:call Open_Browse(2)<cr>
	noremap <S-cr> o<ESC>
	noremap <c-cr> O<esc>
	noremap <M-Left> :call Tab_MoveLeft()<cr>
	noremap <M-Right> :call Tab_MoveRight()<cr>
	inoremap <M-Left> <ESC>:call Tab_MoveLeft()<cr>
	inoremap <M-Right> <ESC>:call Tab_MoveRight()<cr>
	tnoremap <M-Left> <c-\><c-N>:call Tab_MoveLeft()<cr>
	tnoremap <M-Right> <c-\><c-N>:call Tab_MoveRight()<cr>
	if has('gui_macvim')
		noremap <m-\|> :call Toggle_Transparency(9)<cr>
	else
		noremap <m-\|> :call Toggle_Transparency(15)<cr>
	endif
endif

nnoremap <m-z> za
nnoremap <m-Z> zA


"----------------------------------------------------------------------
" terminal
"----------------------------------------------------------------------
if has('terminal')
	" tnoremap <m-=> <c-w>N
endif


"----------------------------------------------------------------------
" space + s : svn
"----------------------------------------------------------------------
noremap <space>sc :AsyncRun svn co -m "update from vim"<cr>
noremap <space>su :AsyncRun svn up<cr>
noremap <space>st :AsyncRun svn st<cr>

" editing commands
noremap <space>aa ggVG

"----------------------------------------------------------------------
" text-objects
"----------------------------------------------------------------------
onoremap e :<c-u>normal! ggVG<cr>
vnoremap e ogg0oG$
onoremap il :<c-u>normal! v$o^oh<cr>
vnoremap il $o^oh


"----------------------------------------------------------------------
" space + j : make
"----------------------------------------------------------------------
noremap <silent><space>jj  :AsyncRun -cwd=<root> make<cr>
noremap <silent><space>jc  :AsyncRun -cwd=<root> make clean<cr>
noremap <silent><space>jk  :AsyncRun -mode=4 -cwd=<root> make run<cr>
noremap <silent><space>jl  :AsyncRun -mode=4 -cwd=<root> make test<cr>
noremap <silent><space>j1  :AsyncRun -mode=4 -cwd=<root> make t1<cr>
noremap <silent><space>j2  :AsyncRun -mode=4 -cwd=<root> make t2<cr>
noremap <silent><space>j3  :AsyncRun -mode=4 -cwd=<root> make t3<cr>
noremap <silent><space>j4  :AsyncRun -mode=4 -cwd=<root> make t4<cr>
noremap <silent><space>j5  :AsyncRun -mode=4 -cwd=<root> make t5<cr>
noremap <silent><space>k1  :AsyncRun -cwd=<root> make t1<cr>
noremap <silent><space>k2  :AsyncRun -cwd=<root> make t2<cr>
noremap <silent><space>k3  :AsyncRun -cwd=<root> make t3<cr>
noremap <silent><space>k4  :AsyncRun -cwd=<root> make t4<cr>
noremap <silent><space>k5  :AsyncRun -cwd=<root> make t5<cr>

noremap <silent><space>jm :call Tools_SwitchMakeFile()<cr>


"----------------------------------------------------------------------
" space + t : toggle plugins
"----------------------------------------------------------------------
"noremap <silent><C-F10> :call Toggle_Taglist()<cr>
"inoremap <silent><C-F10> <c-\><c-o>:call Toggle_Taglist()<cr>
noremap <silent><S-F10> :call quickmenu#toggle(0)<cr>
inoremap <silent><S-F10> <ESC>:call quickmenu#toggle(0)<cr>
noremap <silent><M-;> :call quickui#tools#preview_tag('')<cr>
noremap <silent><M-:> :PreviewClose<cr>
noremap <silent><tab>; :PreviewGoto edit<cr>
noremap <silent><tab>: :PreviewGoto tabe<cr>

if has('autocmd')
	function! s:quickfix_keymap()
		if &buftype != 'quickfix'
			return
		endif
		nnoremap <silent><buffer> p :call quickui#tools#preview_quickfix()<cr>
		nnoremap <silent><buffer> P :PreviewClose<cr>
		nnoremap <silent><buffer> q :close<cr>
		setlocal nonumber
	endfunc
	function! s:insert_leave()
		if get(g:, 'echodoc#enable_at_startup') == 0
			set showmode
		endif
	endfunc
	augroup AscKeymapsAu
		autocmd!
		autocmd FileType qf call s:quickfix_keymap()
		autocmd FileType vim noremap <buffer><F4> :<c-u>silent update<cr>:so %<cr>
		autocmd InsertLeave * call s:insert_leave()
		" autocmd InsertLeave * set showmode
	augroup END
endif

nnoremap <silent><m-a> :PreviewSignature<cr>
inoremap <silent><m-a> <c-\><c-o>:PreviewSignature<cr>


"----------------------------------------------------------------------
" GUI/Terminal
"----------------------------------------------------------------------
noremap <silent><M-[> :call Tools_QuickfixCursor(2)<cr>
noremap <silent><M-]> :call Tools_QuickfixCursor(3)<cr>
noremap <silent><M-{> :call Tools_QuickfixCursor(4)<cr>
noremap <silent><M-}> :call Tools_QuickfixCursor(5)<cr>
noremap <silent><M-u> :call Tools_PreviousCursor(6)<cr>
noremap <silent><M-d> :call Tools_PreviousCursor(7)<cr>
noremap <silent><M-U> :call quickui#preview#scroll(-1)<cr>
noremap <silent><M-D> :call quickui#preview#scroll(1)<cr>

inoremap <silent><M-[> <c-\><c-o>:call Tools_QuickfixCursor(2)<cr>
inoremap <silent><M-]> <c-\><c-o>:call Tools_QuickfixCursor(3)<cr>
inoremap <silent><M-{> <c-\><c-o>:call Tools_QuickfixCursor(4)<cr>
inoremap <silent><M-}> <c-\><c-o>:call Tools_QuickfixCursor(5)<cr>
inoremap <silent><M-u> <c-\><c-o>:call Tools_PreviousCursor(6)<cr>
inoremap <silent><M-d> <c-\><c-o>:call Tools_PreviousCursor(7)<cr>


"----------------------------------------------------------------------
" space + f + num: session management
"----------------------------------------------------------------------
set ssop-=options    " do not store global and local values in a session
" set ssop-=folds      " do not store folds

for s:index in range(5)
	exec 'noremap <silent><space>f'.s:index.'s :mksession! ~/.vim/session.'.s:index.'<cr>'
	exec 'noremap <silent><space>f'.s:index.'l :so ~/.vim/session.'.s:index.'<cr>'
endfor


"----------------------------------------------------------------------
" leader + b/c : buffer
"----------------------------------------------------------------------
noremap <silent><leader>bc :BufferClose<cr>
noremap <silent><leader>cw :CdToFileDir<cr>
noremap <silent><leader>cr :CdToProjectRoot<cr>


"----------------------------------------------------------------------
" space + h : fast open files
"----------------------------------------------------------------------
noremap <silent><space>hp :FileSwitch ~/.vim/project.txt<cr>
noremap <silent><space>hf <c-w>gf
noremap <silent><space>he :call Show_Explore()<cr>
noremap <silent><space>hb :FileSwitch ~/.vim/bundle.vim<cr>
noremap <silent><space>hq :FileSwitch ~/.vim/quicknote.txt<cr>
noremap <silent><space>hm :FileSwitch +setl\ ft=markdown ~/.vim/quicknote.md<cr>
noremap <silent><space>hg :FileSwitch ~/.vim/scratch.txt<cr>
noremap <silent><space>hd :FileSwitch ~/.vim/notes.md<cr>
noremap <silent><space>ho :FileSwitch ~/.vim/cloud/Documents/cloudnote.txt<cr>
noremap <silent><space>hi :FileSwitch ~/.vim/tasks.ini<cr>
noremap <silent><space>h; :call asclib#nextcloud_sync()<cr>

if (!has('nvim')) && (has('win32') || has('win64'))
	noremap <silent><space>hr :FileSwitch ~/_vimrc<cr>
elseif !has('nvim')
	noremap <silent><space>hr :FileSwitch ~/.vimrc<cr>
else
	noremap <silent><space>hr :FileSwitch ~/.config/nvim/init.vim<cr>
endif

if has('nvim') == 0
	nnoremap <silent><space>hl :FileSwitch ~/.vim/local.vim<cr>
else
	nnoremap <silent><space>hl :FileSwitch ~/.config/nvim/local.vim<cr>
endif

let $RTP = expand('<sfile>:p:h:h')
nnoremap <silent><space>hk :FileSwitch $RTP/init/keymaps.vim<cr>
nnoremap <silent><space>hs :FileSwitch $RTP/skywind.vim<cr>
nnoremap <silent><space>hv :FileSwitch $RTP/bundle.vim<cr>
nnoremap <silent><space>hc :FileSwitch $RTP/autoload/asclib.vim<cr>
nnoremap <silent><space>hu :FileSwitch $RTP/autoload/auxlib.vim<cr>
nnoremap <silent><space>ht :FileSwitch $RTP/tasks.ini<cr>

let s:nvimrc = expand("~/.config/nvim/init.vim")
if has('win32') || has('win16') || has('win95') || has('win64')
	let s:nvimrc = expand("~/AppData/Local/nvim/init.vim")
endif
exec 'nnoremap <space>hn :FileSwitch '.fnameescape(s:nvimrc).'<cr>'




"----------------------------------------------------------------------
" visual mode
"----------------------------------------------------------------------
vnoremap <space>gp :!python<cr>
" vmap <space>gs y/<c-r>"<cr>
vmap <space>gs y/<C-R>=escape(@", '\\/.*$^~[]')<CR>
vmap <space>gr y:%s/<C-R>=escape(@", '\\/.*$^~[]')<CR>//gc<Left><Left><Left>


"----------------------------------------------------------------------
" linting
"----------------------------------------------------------------------
noremap <silent><space>lp :call asclib#lint_pylint('')<cr>
noremap <silent><space>lf :call asclib#lint_flake8('')<cr>
noremap <silent><space>ls :call asclib#lint_splint('')<cr>
noremap <silent><space>lc :call asclib#lint_cppcheck('')<cr>
noremap <silent><space>lg :call asclib#open_gprof('', '')<cr>
noremap <silent><space>lt :call asclib#html_prettify()<cr>


"----------------------------------------------------------------------
" more personal in gvim
"----------------------------------------------------------------------
if has('gui_running') && (has('win32') || has('win64'))
	noremap <S-F11> :AsyncRun -mode=4 -cwd=$(VIM_FILEDIR) -save=1 d:\\software\\anaconda3\\python.exe "$(VIM_FILENAME)"<cr>
	inoremap <S-F11> <ESC>:AsyncRun -mode=4 -cwd=$(VIM_FILEDIR) d:\\software\\anaconda3\\python.exe "$(VIM_FILENAME)"<cr>
	noremap <S-F12> :AsyncRun -mode=4 -save=1 -cwd=$(VIM_FILEDIR) d:\\dev\\python64\\python.exe "$(VIM_FILENAME)"<cr>
endif

noremap <C-F10> :VimBuild gcc -pg<cr>


"----------------------------------------------------------------------
" vimmake faster
"----------------------------------------------------------------------
noremap <silent><F12> :call quickmenu#toggle(0)<cr>
inoremap <silent><F12> <ESC>:call quickmenu#toggle(0)<cr>
noremap <silent><F11> :call quickmenu#toggle(1)<cr>
inoremap <silent><F11> <ESC>:call quickmenu#toggle(1)<cr>

noremap <silent><c-f10> :call quickmenu#toggle(1)<cr>
inoremap <silent><c-f10> <ESC>:call quickmenu#toggle(1)<cr>
noremap <silent><c-f11> :call quickmenu#toggle(2)<cr>
inoremap <silent><c-f11> <ESC>:call quickmenu#toggle(2)<cr>
" noremap <silent><c-f12> :call asclib#utils#script_menu()<cr>
" inoremap <silent><c-f12> <ESC>:call asclib#utils#script_menu()<cr>
noremap <silent><c-f9> :AsyncTaskEdit<cr>
inoremap <silent><c-f9> <ESC>:AsyncTaskEdit<cr>

nnoremap <silent>g5 :PreviewTag<cr>
nnoremap <silent>g6 :call vimmake#update_tags('!', 'cs', '.cscope')<cr>
nnoremap <silent>g7 :call vimmake#update_tags('!', 'py', '.cscopy')<cr>
nnoremap <silent>g9 :call vimmake#update_tags('!', 'ctags', '.tags')<cr>

nnoremap <silent><space>ww :call asclib#touch_file('wsgi')<cr>

noremap <space>m0 :call quickmenu#toggle(0)<cr>
noremap <space>m1 :call quickmenu#toggle(1)<cr>
noremap <space>m2 :call quickmenu#toggle(2)<cr>
noremap <space>m3 :call quickmenu#toggle(3)<cr>


"----------------------------------------------------------------------
" others
"----------------------------------------------------------------------
nnoremap <silent><space>at :MyCheatSheetAlign<cr>
vnoremap <silent><space>at :MyCheatSheetAlign<cr>
nnoremap <silent><space>ab :BraceExpand<cr>
vnoremap <silent><space>ab :BraceExpand<cr>

noremap <m-i> :call quickui#tools#list_function()<cr>
noremap <m-I> :call quickui#tools#list_function()<cr>
noremap <m-y> :call quickui#tools#list_function()<cr>

if has('gui_macvim')
	noremap <d-i> :call quickui#tools#list_function()<cr>
	noremap <d-I> :call quickui#tools#list_function()<cr>
	noremap <d-y> :call quickui#tools#list_function()<cr>
endif


"----------------------------------------------------------------------
" neovim system clipboard
"----------------------------------------------------------------------
if has('nvim') && (has('win32') || has('win64'))
	nnoremap <s-insert> "*P
	vnoremap <s-insert> "-d"*P
	inoremap <s-insert> <c-r><c-o>*
	vnoremap <c-insert> "*y
	cnoremap <s-insert> <c-r>*
endif


"----------------------------------------------------------------------
" Transferring blocks of text between vim sessions
" http://www.drchip.org/astronaut/vim/index.html#Maps
"----------------------------------------------------------------------
nmap <Leader>xr   :r $HOME/.vim/xfer<CR>
nmap <Leader>xw   :'a,.w! $HOME/.vim/xfer<CR>
vmap <Leader>xw   :w! $HOME/.vim/xfer<CR>
nmap <Leader>xa   :'a,.w>> $HOME/.vim/xfer<CR>
vmap <Leader>xa   :w>> $HOME/.vim/xfer<CR>
nmap <Leader>xS   :so $HOME/.vim/xfer<CR>
nmap <Leader>xy   :'a,.y *<CR>
vmap <Leader>xy   :y *<CR>



