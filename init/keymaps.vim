"======================================================================
"
" keymaps.vim - keymaps starting with <space>
"
" Created by skywind on 2016/10/12
" Last Modified: 2023/09/18 02:35
"
"======================================================================


"----------------------------------------------------------------------
" tab switching
"----------------------------------------------------------------------
let s:array = [')', '!', '@', '#', '$', '%', '^', '&', '*', '(']
for i in range(10)
	let x = (i == 0)? 10 : i
	let c = s:array[i]
	exec "noremap <silent><M-".i."> ".x."gt"
	exec "inoremap <silent><M-".i."> <ESC>".x."gt"
	if get(g:, 'vim_no_meta_shift_num', 0) == 0
		exec "noremap <silent><M-".c."> ".x."gt"
		exec "inoremap <silent><M-".c."> <ESC>".x."gt"
	endif
endfor

noremap <silent><m-t> :tabnew<cr>
inoremap <silent><m-t> <ESC>:tabnew<cr>
noremap <silent><m-w> :tabclose<cr>
inoremap <silent><m-w> <ESC>:tabclose<cr>
noremap <m-s> :w<cr>
inoremap <m-s> <esc>:w<cr>


"----------------------------------------------------------------------
" VimTools
"----------------------------------------------------------------------
for s:index in range(10)
	let s:button = (s:index > 0)? 'F'.s:index : 'F10'
	if has('gui_running')
		exec "noremap <C-".s:button."> :AsyncTask task-c-f".s:index . '<cr>'
		exec "inoremap <C-".s:button."> <ESC>:AsyncTask task-c-f".s:index . '<cr>'
	endif
endfor



"----------------------------------------------------------------------
" window
"----------------------------------------------------------------------
nnoremap <silent><space>= :resize +3<cr>
nnoremap <silent><space>- :resize -3<cr>
nnoremap <silent><space>, :vertical resize -3<cr>
nnoremap <silent><space>. :vertical resize +3<cr>

nnoremap <silent><space>hh :nohl<cr>
nnoremap <silent><bs> :nohl<cr>:redraw!<cr>
nnoremap <silent><tab>, :call Tab_MoveLeft()<cr>
nnoremap <silent><tab>. :call Tab_MoveRight()<cr>
nnoremap <silent><tab>6 :VinegarOpen leftabove vs<cr>
nnoremap <silent><tab>7 :VinegarOpen vs<cr>
nnoremap <silent><tab>8 :VinegarOpen belowright sp<cr>
nnoremap <silent><tab>9 :VinegarOpen tabedit<cr>
nnoremap <silent><tab>0 :exe "NERDTree ".fnameescape(expand("%:p:h"))<cr>
nnoremap <silent><tab>y :exe "NERDTree ".fnameescape(asclib#path#get_root("%"))<cr>
nnoremap <silent><tab>g <c-w>p

" nnoremap <silent><space>ha :GuiSignRemove
" 			\ errormarker_error errormarker_warning<cr>

" replace
nnoremap <space>p viw"0p
nnoremap <space>y yiw

" fast save
nnoremap <C-S> :w<cr>
inoremap <C-S> <ESC>:w<cr>

nnoremap <silent><m-t> :tabnew<cr>
vnoremap <silent><m-t> <ESC>:tabnew<cr>
inoremap <silent><m-t> <ESC>:tabnew<cr>
nnoremap <silent><m-w> :tabclose<cr>
inoremap <silent><m-w> <ESC>:tabclose<cr>
nnoremap <silent><m-v> :close<cr>
inoremap <silent><m-v> <esc>:close<cr>
nnoremap <m-s> :w<cr>
inoremap <m-s> <esc>:w<cr>


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
" GUI hotkeys
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
	if v:version >= 802
		tnoremap <M-Left> <c-\><c-N>:call Tab_MoveLeft()<cr>
		tnoremap <M-Right> <c-\><c-N>:call Tab_MoveRight()<cr>
	endif
	if has('gui_macvim')
		noremap <m-\|> :call Toggle_Transparency(9)<cr>
	else
		noremap <m-\|> :call Toggle_Transparency(15)<cr>
	endif
endif

if has('gui_running') || has('gui_macvim') || has('gui_mac')
	" new digraph
	inoremap <c--> <c-k>
	inoremap <c-_> <c-k>
endif

nnoremap <m-z> za
nnoremap <m-Z> zA


"----------------------------------------------------------------------
" terminal
"----------------------------------------------------------------------
if has('terminal')
	" tnoremap <m-=> <c-w>N
endif


" editing commands
nnoremap <space>aa ggVG

"----------------------------------------------------------------------
" text-objects
"----------------------------------------------------------------------
onoremap az :<c-u>normal! ggVG<cr>
vnoremap az ogg0oG$
" onoremap il :<c-u>normal! v$o^oh<cr>
" vnoremap il $o^oh

vnoremap ik 0o$h
onoremap ik :normal vik<cr>
vnoremap ak 0o$
onoremap ak :normal vak<cr>


"----------------------------------------------------------------------
" tasks
"----------------------------------------------------------------------
noremap <silent><s-f12> :AsyncTaskEdit<cr>
inoremap <silent><s-f12> <ESC>:AsyncTaskEdit<cr>
noremap <silent><f12> :TaskFinder<cr>
inoremap <silent><f12> <ESC>:TaskFinder<cr>
noremap <silent><c-f12> :AsyncTaskEnviron profile debug release static<cr>
inoremap <silent><c-f12> <ESC>:AsyncTaskEnviron profile debug release static<cr>

noremap <silent><F5> :AsyncTask file-run<cr>
noremap <silent><F6> :AsyncTask make<cr>
noremap <silent><F7> :AsyncTask emake<cr>
noremap <silent><F8> :AsyncTask emake-exe<cr>
noremap <silent><F9> :AsyncTask file-build<cr>
noremap <silent><F10> :call asyncrun#quickfix_toggle(6)<cr>
noremap <silent><F11> :AsyncTask file-debug<cr>
noremap <silent><s-f5> :AsyncTask project-run<cr>
noremap <silent><s-f6> :AsyncTask project-test<cr>
noremap <silent><s-f7> :AsyncTask project-init<cr>
noremap <silent><s-f8> :AsyncTask project-install<cr>
noremap <silent><s-f9> :AsyncTask project-build<cr>
noremap <silent><s-f11> :AsyncTask project-debug<cr>

inoremap <silent><F5> <ESC>:AsyncTask file-run<cr>
inoremap <silent><F6> <ESC>:AsyncTask make<cr>
inoremap <silent><F7> <ESC>:AsyncTask emake<cr>
inoremap <silent><F8> <ESC>:AsyncTask emake-exe<cr>
inoremap <silent><F9> <ESC>:AsyncTask file-build<cr>
inoremap <silent><F10> <ESC>:call asyncrun#quickfix_toggle(6)<cr>
inoremap <silent><s-f5> <ESC>:AsyncTask project-run<cr>
inoremap <silent><s-f6> <ESC>:AsyncTask project-test<cr>
inoremap <silent><s-f7> <ESC>:AsyncTask project-init<cr>
inoremap <silent><s-f8> <ESC>:AsyncTask project-install<cr>
inoremap <silent><s-f9> <ESC>:AsyncTask project-build<cr>

noremap <silent><f1> :AsyncTask task-f1<cr>
noremap <silent><f2> :AsyncTask task-f2<cr>
noremap <silent><f3> :AsyncTask task-f3<cr>
noremap <silent><f4> :AsyncTask task-f4<cr>
noremap <silent><s-f1> :AsyncTask task-s-f1<cr>
noremap <silent><s-f2> :AsyncTask task-s-f2<cr>
noremap <silent><s-f3> :AsyncTask task-s-f3<cr>
noremap <silent><s-f4> :AsyncTask task-s-f4<cr>
inoremap <silent><f1> <ESC>:AsyncTask task-f1<cr>
inoremap <silent><f2> <ESC>:AsyncTask task-f2<cr>
inoremap <silent><f3> <ESC>:AsyncTask task-f3<cr>
inoremap <silent><f4> <ESC>:AsyncTask task-f4<cr>
inoremap <silent><s-f1> <ESC>:AsyncTask task-s-f1<cr>
inoremap <silent><s-f2> <ESC>:AsyncTask task-s-f2<cr>
inoremap <silent><s-f3> <ESC>:AsyncTask task-s-f3<cr>
inoremap <silent><s-f4> <ESC>:AsyncTask task-s-f4<cr>


"----------------------------------------------------------------------
"- quickui buffer switch / bufferhint
"----------------------------------------------------------------------
if has('patch-8.2.1') || has('nvim-0.4')
	nnoremap <silent>+ :call quickui#tools#list_buffer('FileSwitch tabe')<cr>
else
	nnoremap + :call bufferhint#Popup()<CR>
endif


"----------------------------------------------------------------------
" space + j : make
"----------------------------------------------------------------------
nnoremap <silent><space>jj  :AsyncRun -cwd=<root> make<cr>
nnoremap <silent><space>jc  :AsyncRun -cwd=<root> make clean<cr>
nnoremap <silent><space>jk  :AsyncRun -mode=4 -cwd=<root> make run<cr>
nnoremap <silent><space>jl  :AsyncRun -mode=4 -cwd=<root> make test<cr>
nnoremap <silent><space>j1  :AsyncRun -mode=4 -cwd=<root> make t1<cr>
nnoremap <silent><space>j2  :AsyncRun -mode=4 -cwd=<root> make t2<cr>
nnoremap <silent><space>j3  :AsyncRun -mode=4 -cwd=<root> make t3<cr>
nnoremap <silent><space>j4  :AsyncRun -mode=4 -cwd=<root> make t4<cr>
nnoremap <silent><space>j5  :AsyncRun -mode=4 -cwd=<root> make t5<cr>
nnoremap <silent><space>k1  :AsyncRun -cwd=<root> make t1<cr>
nnoremap <silent><space>k2  :AsyncRun -cwd=<root> make t2<cr>
nnoremap <silent><space>k3  :AsyncRun -cwd=<root> make t3<cr>
nnoremap <silent><space>k4  :AsyncRun -cwd=<root> make t4<cr>
nnoremap <silent><space>k5  :AsyncRun -cwd=<root> make t5<cr>

nnoremap <silent><space>jm :call Tools_SwitchMakeFile()<cr>

"----------------------------------------------------------------------
" set keymap to GrepCode
"----------------------------------------------------------------------
nnoremap <silent><leader>cq :VimStop<cr>
nnoremap <silent><leader>cQ :VimStop!<cr>
nnoremap <silent><leader>cv :GrepCode <C-R>=expand("<cword>")<cr><cr>
nnoremap <silent><leader>cx :GrepCode! <C-R>=expand("<cword>")<cr><cr>


"----------------------------------------------------------------------
" cscope
"----------------------------------------------------------------------
if has("cscope")
	noremap <silent> <leader>cs :VimScope s <C-R><C-W><CR>
	noremap <silent> <leader>cg :VimScope g <C-R><C-W><CR>
	noremap <silent> <leader>cc :VimScope c <C-R><C-W><CR>
	noremap <silent> <leader>ct :VimScope t <C-R><C-W><CR>
	noremap <silent> <leader>ce :VimScope e <C-R><C-W><CR>
	noremap <silent> <leader>cd :VimScope d <C-R><C-W><CR>
	noremap <silent> <leader>ca :VimScope a <C-R><C-W><CR>
	noremap <silent> <leader>cf :VimScope f <C-R><C-W><CR>
	noremap <silent> <leader>ci :VimScope i <C-R><C-W><CR>
	if v:version >= 800 || has('patch-7.4.2038')
		set cscopequickfix=s+,c+,d+,i+,t+,e+,g+,f+,a+
	else
		set cscopequickfix=s+,c+,d+,i+,t+,e+,g+,f+
	endif
endif

nnoremap <leader>cb1 :call vimmake#update_tags('', 'ctags', '.tags')<cr>
nnoremap <leader>cb2 :call vimmake#update_tags('', 'cs', '.cscope')<cr>
nnoremap <leader>cb3 :call vimmake#update_tags('!', 'ctags', '.tags')<cr>
nnoremap <leader>cb4 :call vimmake#update_tags('!', 'cs', '.cscope')<cr>
nnoremap <leader>cb5 :call vimmake#update_tags('', 'py', '.cscopy')<cr>
nnoremap <leader>cb6 :call vimmake#update_tags('!', 'py', '.cscopy')<cr>


"----------------------------------------------------------------------
" space + t : toggle plugins
"----------------------------------------------------------------------
"noremap <silent><C-F10> :call Toggle_Taglist()<cr>
"inoremap <silent><C-F10> <c-\><c-o>:call Toggle_Taglist()<cr>
noremap <silent><S-F10> :call quickmenu#toggle(0)<cr>
inoremap <silent><S-F10> <ESC>:call quickmenu#toggle(0)<cr>
noremap <silent><M-;> :call quickui#tools#preview_tag('')<cr>
noremap <silent><M-:> :PreviewClose<cr>
nnoremap <silent><tab>; :PreviewGoto edit<cr>
nnoremap <silent><tab>: :PreviewGoto tabe<cr>

if has('autocmd')
	function! s:insert_enter()
		if get(g:, 'echodoc#enable_at_startup', 0) != 0
			set noshowmode
		elseif exists(':CocInstall')
			set noshowmode
		endif
	endfunc
	function! s:insert_leave()
		if get(g:, 'echodoc#enable_at_startup', 0) != 0
			set showmode
		elseif exists(':CocInstall')
			set showmode
		endif
	endfunc
	augroup AscKeymapsAu
		autocmd!
		autocmd InsertLeave * call s:insert_leave()
		autocmd InsertEnter * call s:insert_enter()
		" autocmd InsertLeave * set showmode
		if exists('##TerminalOpen')
			autocmd TerminalOpen * setlocal ft=terminal
		elseif exists('##TermOpen')
			autocmd TermOpen * setlocal ft=terminal
		endif
	augroup END
endif

nnoremap <silent><m-a> :PreviewSignature<cr>
inoremap <silent><m-a> <c-\><c-o>:PreviewSignature<cr>


"----------------------------------------------------------------------
" GUI/Terminal
"----------------------------------------------------------------------
noremap <silent><M-[> :call asclib#quickfix#scroll(2)<cr>
noremap <silent><M-]> :call asclib#quickfix#scroll(3)<cr>
noremap <silent><M-{> :call asclib#quickfix#scroll(4)<cr>
noremap <silent><M-}> :call asclib#quickfix#scroll(5)<cr>
noremap <silent><M-u> :call asclib#window#scroll('#', 6)<cr>
noremap <silent><M-d> :call asclib#window#scroll('#', 7)<cr>
noremap <silent><M-U> :call quickui#preview#scroll(-1)<cr>
noremap <silent><M-D> :call quickui#preview#scroll(1)<cr>

inoremap <silent><M-[> <c-\><c-o>:call asclib#quickfix#scroll(2)<cr>
inoremap <silent><M-]> <c-\><c-o>:call asclib#quickfix#scroll(3)<cr>
inoremap <silent><M-{> <c-\><c-o>:call asclib#quickfix#scroll(4)<cr>
inoremap <silent><M-}> <c-\><c-o>:call asclib#quickfix#scroll(5)<cr>
inoremap <silent><M-u> <c-\><c-o>:call asclib#window#scroll('#', 6)<cr>
inoremap <silent><M-d> <c-\><c-o>:call asclib#window#scroll('#', 7)<cr>


"----------------------------------------------------------------------
" space + f + num: session management
"----------------------------------------------------------------------
set ssop-=options    " do not store global and local values in a session
" set ssop-=folds      " do not store folds

for s:index in range(5)
	exec 'nnoremap <silent><space>f'.s:index.'s :mksession! ~/.vim/session.'.s:index.'<cr>'
	exec 'nnoremap <silent><space>f'.s:index.'l :so ~/.vim/session.'.s:index.'<cr>'
endfor


"----------------------------------------------------------------------
" leader + b/c : buffer
"----------------------------------------------------------------------
nnoremap <silent><leader>bc :BufferClose<cr>
nnoremap <silent><leader>cw :CdToFileDir<cr>
nnoremap <silent><leader>cr :CdToProjectRoot<cr>


"----------------------------------------------------------------------
" space + h : fast open files
"----------------------------------------------------------------------
nnoremap <silent><space>hp :FileSwitch ~/.vim/project.txt<cr>
nnoremap <silent><space>hf <c-w>gf
nnoremap <silent><space>he :call Show_Explore()<cr>
nnoremap <silent><space>hb :FileSwitch ~/.vim/bundle.vim<cr>
nnoremap <silent><space>hq :FileSwitch ~/.vim/quicknote.txt<cr>
nnoremap <silent><space>hm :FileSwitch +setl\ ft=markdown ~/.vim/quicknote.md<cr>
nnoremap <silent><space>hg :FileSwitch ~/.vim/scratch.txt<cr>
nnoremap <silent><space>hd :FileSwitch ~/.vim/notes.md<cr>
nnoremap <silent><space>ho :FileSwitch ~/.vim/cloud/Documents/cloudnote.txt<cr>
nnoremap <silent><space>hi :FileSwitch ~/.vim/tasks.ini<cr>
nnoremap <silent><space>ha :
nnoremap <silent><space>h; :call asclib#nextcloud_sync()<cr>

if (!has('nvim')) && (has('win32') || has('win64'))
	nnoremap <silent><space>hr :FileSwitch ~/_vimrc<cr>
elseif !has('nvim')
	nnoremap <silent><space>hr :FileSwitch ~/.vimrc<cr>
else
	nnoremap <silent><space>hr :FileSwitch ~/.config/nvim/init.vim<cr>
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

if has('win32') || has('win16') || has('win95') || has('win64')
	let s:autohk = expand('~/AppData/Roaming/Microsoft/Windows/Start Menu')
	let s:autohk = s:autohk . '/Programs/Startup/quickkeys.ahk'
	exec 'nnoremap <space>ha :FileSwitch '. fnameescape(s:autohk). ' <cr>'
endif

let s:nvimrc = expand("~/.config/nvim/init.vim")
if has('win32') || has('win16') || has('win95') || has('win64')
	let s:nvimrc = expand("~/AppData/Local/nvim/init.vim")
endif
exec 'nnoremap <space>h. :FileSwitch '.fnameescape(s:nvimrc).'<cr>'

nnoremap <space>hn :FileSwitch $RTP/neovim.lua<cr>



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
nnoremap <silent><space>lp :call asclib#lint_pylint('')<cr>
nnoremap <silent><space>lf :call asclib#lint_flake8('')<cr>
nnoremap <silent><space>ls :call asclib#lint_splint('')<cr>
nnoremap <silent><space>lc :call asclib#lint_cppcheck('')<cr>
nnoremap <silent><space>lg :call asclib#open_gprof('', '')<cr>
nnoremap <silent><space>lt :call asclib#html_prettify()<cr>

" last command
nnoremap <space>ll :<c-p><cr>


"----------------------------------------------------------------------
" quickmenu
"----------------------------------------------------------------------
noremap <silent><c-f10> :call quickmenu#toggle(1)<cr>
inoremap <silent><c-f10> <ESC>:call quickmenu#toggle(1)<cr>
noremap <silent><c-f11> :call quickmenu#toggle(2)<cr>
inoremap <silent><c-f11> <ESC>:call quickmenu#toggle(2)<cr>
nnoremap <silent>g5 :PreviewTag<cr>
nnoremap <silent><space>ww :call asclib#touch_file('wsgi')<cr>

nnoremap <space>m0 :call quickmenu#toggle(0)<cr>
nnoremap <space>m1 :call quickmenu#toggle(1)<cr>
nnoremap <space>m2 :call quickmenu#toggle(2)<cr>
nnoremap <space>m3 :call quickmenu#toggle(3)<cr>


"----------------------------------------------------------------------
" others
"----------------------------------------------------------------------
nnoremap <silent><space>at :MyCheatSheetAlign<cr>
vnoremap <silent><space>at :MyCheatSheetAlign<cr>
nnoremap <silent><space>ab :CppBraceExpand<cr>
vnoremap <silent><space>ab :CppBraceExpand<cr>

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
if (has('win32') || has('win64')) && (has('nvim') || (!has('gui_running')))
	nnoremap <s-insert> "*P
	vnoremap <s-insert> "-d"*P
	inoremap <s-insert> <c-r><c-o>*
	vnoremap <c-insert> "*y
	cnoremap <s-insert> <c-r>*
endif


"----------------------------------------------------------------------
" space + s : svn
"----------------------------------------------------------------------
nnoremap <space>sc :AsyncRun svn co -m "update from vim"<cr>
nnoremap <space>su :AsyncRun svn up<cr>
nnoremap <space>st :AsyncRun svn st<cr>


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



