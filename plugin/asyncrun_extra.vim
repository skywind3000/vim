"======================================================================
"
" asyncrun_extra.vim - extra runners for asyncrun
"
" Created by skywind on 2021/01/11
" Last Modified: 2021/01/11 17:51:21
"
"======================================================================


"----------------------------------------------------------------------
" initialize
"----------------------------------------------------------------------
let g:asyncrun_runner = get(g:, 'asyncrun_runner', {})

let s:windows = has('win32') || has('win64') || has('win16') || has('win95')


"----------------------------------------------------------------------
" utils
"----------------------------------------------------------------------
function! s:errmsg(msg)
	redraw
	echohl ErrorMsg
	echom 'ERROR: ' . a:msg
	echohl NONE
	return 0
endfunction


"----------------------------------------------------------------------
" gnome-terminal
"----------------------------------------------------------------------
function! s:gnome_run(opts)
	if !executable('gnome-terminal')
		return s:errmsg('gnome-terminal executable not find !')
	endif
	let cmds = []
	let cmds += ['cd ' . shellescape(getcwd()) ]
	let cmds += [a:opts.cmd]
	let cmds += ['echo ""']
	let cmds += ['read -n1 -rsp "press any key to continue ..."']
	let text = shellescape(join(cmds, ";"))
	let command = 'gnome-terminal -- bash -c ' . text
	call system(command . ' &')
endfunction

function! s:gnome_tab(opts)
	if !executable('gnome-terminal')
		return s:errmsg('gnome-terminal executable not find !')
	endif
	let cmds = []
	let cmds += ['cd ' . shellescape(getcwd()) ]
	let cmds += [a:opts.cmd]
	let cmds += ['echo ""']
	let cmds += ['read -n1 -rsp "press any key to continue ..."']
	let text = shellescape(join(cmds, ";"))
	let command = 'gnome-terminal --tab --active -- bash -c ' . text
	call system(command . ' &')
endfunction

let g:asyncrun_runner.gnome = function('s:gnome_run')
let g:asyncrun_runner.gnome_tab = function('s:gnome_tab')


"----------------------------------------------------------------------
" run in xterm
"----------------------------------------------------------------------
function! s:xterm_run(opts)
	if !executable('xterm')
		return s:errmsg('xterm executable not find !')
	endif
	let cmds = []
	let cmds += ['cd ' . shellescape(getcwd()) ]
	let cmds += [a:opts.cmd]
	let cmds += ['echo ""']
	let cmds += ['read -n1 -rsp "press any key to continue ..."']
	let text = shellescape(join(cmds, ";"))
	let command = 'xterm '
	let command .= ' -T ' . shellescape(':AsyncRun ' . a:opts.cmd)
	let command .= ' -e bash -c ' . text
	call system(command . ' &')
endfunc

let g:asyncrun_runner.xterm = function('s:xterm_run')


"----------------------------------------------------------------------
" external runner
"----------------------------------------------------------------------
function! s:external_run(opts)
	if s:windows != 0
		return 0
	endif
	let d = ['gnome', 'xterm']
	let p = get(g:, 'asyncrun_extra_priority', d)
	for n in p
		if n == 'gnome' && executable('gnome-terminal')
			return s:gnome_run(a:opts)
		elseif n == 'xterm' && executable('xterm')
			return s:xterm_run(a:opts)
		endif
	endfor
endfunction

if s:windows == 0
	let g:asyncrun_runner.external = function('s:external_run')
endif


"----------------------------------------------------------------------
" floaterm
"----------------------------------------------------------------------
function! s:floaterm_run(opts)
	if exists(':FloatermNew') != 2
		return s:errmsg('require voldikss/vim-floaterm')
	endif
	if exists('*asyncrun#script_write') == 0
		return s:errmsg('require asyncrun 2.7.8 or above')
	endif
	let cmd = 'FloatermNew '
	let cmd .= ' --wintype=float'
	if has_key(a:opts, 'position') 
		let cmd .= ' --position=' . fnameescape(a:opts.position)
	endif
	if has_key(a:opts, 'width')
		let cmd .= ' --width=' . fnameescape(a:opts.width)
	endif
	if has_key(a:opts, 'height')
		let cmd .= ' --height=' . fnameescape(a:opts.height)
	endif
	if has_key(a:opts, 'title')
		let cmd .= ' --title=' . fnameescape(a:opts.title)
	endif
	let cmd .= ' --autoclose=0'
	let cmd .= ' --silent=' . get(a:opts, 'silent', 0)
	let cwd = (a:opts.cwd == '')? getcwd() : (a:opts.cwd)
	let cmd .= ' --cwd=' . fnameescape(cwd)
	" for precisely arguments passing and shell builtin commands
	" a temporary file is introduced
	let cmd .= ' ' . fnameescape(asyncrun#script_write(a:opts.cmd, 0))
	exec cmd
	if get(a:opts, 'focus', 1) == 0
		stopinsert | noa wincmd p
		augroup close-floaterm-runner
			autocmd!
			autocmd CursorMoved,InsertEnter * ++nested
						\ call timer_start(100, { -> s:floaterm_close() })
		augroup END
	endif
endfunction

function! s:floaterm_close() abort
	if &ft == 'floaterm' | return | endif
	for b in tabpagebuflist()
		if getbufvar(b, '&ft') == 'floaterm' &&
					\ getbufvar(b, 'floaterm_jobexists') == v:false
			execute b 'bwipeout!'
			break
		endif
	endfor
	autocmd! close-floaterm-runner
endfunction

function! s:floaterm_run_2(opts)
	let curr_bufnr = floaterm#curr()
	if has_key(a:opts, 'silent') && a:opts.silent == 1
		FloatermHide!
	endif
	let cmd = 'cd ' . shellescape(getcwd())
	call floaterm#terminal#send(curr_bufnr, [cmd])
	call floaterm#terminal#send(curr_bufnr, [a:opts.cmd])
	stopinsert
	if &filetype == 'floaterm' && g:floaterm_autoinsert
		call floaterm#util#startinsert()
	endif
	return 0
endfunction


let g:asyncrun_runner.floaterm = function('s:floaterm_run')
let g:asyncrun_runner.floaterm_reuse = function('s:floaterm_run_2')


"----------------------------------------------------------------------
" tmux
"----------------------------------------------------------------------
function! s:tmux_run(opts)
	if exists('*VimuxRunCommand') == 0
		return s:errmsg('require benmills/vimux')
	endif
	let cwd = getcwd()
	call VimuxRunCommand('cd ' . shellescape(cwd) . '; ' . a:opts.cmd)
endfunction

let g:asyncrun_runner.tmux = function('s:tmux_run')


"----------------------------------------------------------------------
" terminal_help
"----------------------------------------------------------------------
function! s:termhelp_run(opts)
	let cwd = getcwd()
	call TerminalSend('cd ' . shellescape(cwd) . "\r")
	call TerminalSend(a:opts.cmd . "\r")
endfunction

let g:asyncrun_runner.termhelp = function('s:termhelp_run')


