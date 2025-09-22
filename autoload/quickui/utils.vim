"======================================================================
"
" utils.vim - 
"
" Created by skywind on 2019/12/19
" Last Modified: 2023/07/23 18:44
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :


"----------------------------------------------------------------------
" parse description into item object
"----------------------------------------------------------------------
function! quickui#utils#item_parse(description)
	let obj = {'text':'', 'key_pos':-1, 'key_char':'', 'is_sep':0, 'help':''}
	let text = ''
	let child = 0
	if type(a:description) == v:t_string
		let text = a:description
		let obj.help = ''
		let obj.cmd = ''
	elseif type(a:description) == v:t_list
		let size = len(a:description)
		let text = (size >= 1)? a:description[0] : ''
		let obj.help = (size >= 3)? a:description[2] : ''
		let obj.cmd = ''
		if size >= 2
			if type(a:description[1]) == v:t_string
				let obj.cmd = a:description[1]
			elseif type(a:description[1]) == v:t_list
				let obj.cmd = ''
				let obj.child = a:description[1]
				let child = 1
			endif
		endif
	endif
	if text =~ '^-\+$'
		let obj.is_sep = 1
		let obj.text = ""
		let obj.desc = ""
		let obj.text_width = 0
		let obj.desc_width = 0
		let obj.enable = 0
	else
		let text = quickui#core#expand_text(text)
		let obj.enable = 1
		if strpart(text, 0, 1) == '~'
			let text = strpart(text, 1)
			let obj.enable = 0
		endif
		let pos = stridx(text, "\t")
		let sep = ">"
		if pos < 0 
			let obj.text = text
			let obj.desc = ""
		else
			let obj.text = strpart(text, 0, pos)
			let obj.desc = strpart(text, pos + 1)
			let obj.desc = substitute(obj.desc, "\t", " ", "g")
		endif
		let obj.desc = (child == 0)? obj.desc : sep
		let text = obj.text
		let rest = ''
		let start = 0
		while 1
			let pos = stridx(text, "&", start)
			if pos < 0 
				let rest .= strpart(text, start)
				break
			end
			let rest .= strpart(text, start, pos - start)
			let key = strpart(text, pos + 1, 1)
			let start = pos + 2
			if key == '&'
				let rest .= '&'
			elseif key == '~'
				let rest .= '~'
			else
				let obj.key_char = key
				let obj.key_pos = strwidth(rest)
				let rest .= key
			endif
		endwhile
		let obj.text = rest
		let obj.text_width = strwidth(obj.text)
		let obj.desc_width = strwidth(obj.desc)
	end
	return obj
endfunc


"----------------------------------------------------------------------
" alignment
"----------------------------------------------------------------------
function! quickui#utils#context_align(item, left_size, right_size)
	let obj = a:item
	let middle = (a:right_size > 0)? 2 : 0
	let size = a:left_size + a:right_size + middle
	if obj.is_sep
		let obj.content = repeat('-', size)
	else
		if obj.text_width < a:left_size
			let delta = a:left_size - obj.text_width
			let obj.text_left = obj.text . repeat(' ', delta)
		else
			let obj.text_left = obj.text
		endif
		if obj.desc_width < a:right_size
			let delta = a:right_size - obj.desc_width
			let obj.text_right = repeat(' ', delta) . obj.desc
		else
			let obj.text_right = obj.desc
		endif
		if a:right_size > 0
			let obj.content = obj.text_left . '  ' . obj.text_right
		else
			let obj.content = obj.text_left
		endif
	endif
	return obj
endfunc


"----------------------------------------------------------------------
" style: default
"----------------------------------------------------------------------
function! quickui#utils#highlight(style)
	let style = (type(a:style) == v:t_number)? (''. a:style) : a:style
	let style = tolower(style)
	if style == '' || style == '0' || style == 'default' || style == 'Pmenu'
		hi! link TVisionBG Pmenu
		hi! link TVisionKey Keyword
		hi! link TVisionOff Comment
		hi! link TVisionSel PmenuSel
		hi! link TVisionHelp Title
	elseif style == 'borland'
	endif
endfunc



"----------------------------------------------------------------------
" build map
"----------------------------------------------------------------------
let s:maps = {}
let s:maps["\<ESC>"] = 'ESC'
let s:maps["\<CR>"] = 'ENTER'
let s:maps["\<SPACE>"] = 'ENTER'
let s:maps["\<UP>"] = 'UP'
let s:maps["\<DOWN>"] = 'DOWN'
let s:maps["\<LEFT>"] = 'LEFT'
let s:maps["\<RIGHT>"] = 'RIGHT'
let s:maps["\<HOME>"] = 'HOME'
let s:maps["\<END>"] = 'END'
let s:maps["\<c-j>"] = 'DOWN'
let s:maps["\<c-k>"] = 'UP'
let s:maps["\<c-h>"] = 'LEFT'
let s:maps["\<c-l>"] = 'RIGHT'
let s:maps["\<c-n>"] = 'NEXT'
let s:maps["\<c-p>"] = 'PREV'
let s:maps["\<c-b>"] = 'PAGEUP'
let s:maps["\<c-f>"] = 'PAGEDOWN'
let s:maps["\<c-u>"] = 'HALFUP'
let s:maps["\<c-d>"] = 'HALFDOWN'
let s:maps["\<PageUp>"] = 'PAGEUP'
let s:maps["\<PageDown>"] = 'PAGEDOWN'
let s:maps["\<c-g>"] = 'NOHL'
let s:maps['j'] = 'DOWN'
let s:maps['k'] = 'UP'
let s:maps['h'] = 'LEFT'
let s:maps['l'] = 'RIGHT'
let s:maps['J'] = 'HALFDOWN'
let s:maps['K'] = 'HALFUP'
let s:maps['H'] = 'PAGEUP'
let s:maps['L'] = 'PAGEDOWN'
let s:maps["g"] = 'TOP'
let s:maps["G"] = 'BOTTOM'
let s:maps['q'] = 'ESC'
let s:maps['n'] = 'NEXT'
let s:maps['N'] = 'PREV'


function! quickui#utils#keymap()
	return deepcopy(s:maps)
endfunc


"----------------------------------------------------------------------
" python simulate system() on window to prevent temporary window
"----------------------------------------------------------------------
function! s:python_system(cmd, version)
	if has('nvim')
		let hr = system(a:cmd)
	elseif has('win32') || has('win64') || has('win95') || has('win16')
		if a:version < 0 || (has('python3') == 0 && has('python2') == 0)
			let hr = system(a:cmd)
			let s:shell_error = v:shell_error
			return hr
		elseif a:version == 3
			let pyx = 'py3 '
			let python_eval = 'py3eval'
		elseif a:version == 2
			let pyx = 'py2 '
			let python_eval = 'pyeval'
		else
			let pyx = 'pyx '
			let python_eval = 'pyxeval'
		endif
		exec pyx . 'import subprocess, vim'
		exec pyx . '__argv = {"args":vim.eval("a:cmd"), "shell":True}'
		exec pyx . '__argv["stdout"] = subprocess.PIPE'
		exec pyx . '__argv["stderr"] = subprocess.STDOUT'
		exec pyx . '__pp = subprocess.Popen(**__argv)'
		exec pyx . '__return_text = __pp.stdout.read()'
		exec pyx . '__pp.stdout.close()'
		exec pyx . '__return_code = __pp.wait()'
		exec 'let l:hr = '. python_eval .'("__return_text")'
		exec 'let l:pc = '. python_eval .'("__return_code")'
		let s:shell_error = l:pc
		return l:hr
	else
		let hr = system(a:cmd)
	endif
	let s:shell_error = v:shell_error
	return hr
endfunc


"----------------------------------------------------------------------
" execute external program and return its output
"----------------------------------------------------------------------
function! quickui#utils#system(cmd)
	let hr = s:python_system(a:cmd, get(g:, 'quickui_python', 0))
	let g:quickui#utils#shell_error = s:shell_error
	return hr
endfunc


"----------------------------------------------------------------------
" display a error msg
"----------------------------------------------------------------------
function! quickui#utils#errmsg(what)
	redraw
	echohl ErrorMsg
	echom a:what
	echohl None
endfunc


"----------------------------------------------------------------------
" safe print
"----------------------------------------------------------------------
function! quickui#utils#print(content, highlight, ...)
	let saveshow = &showmode
	set noshowmode
    let wincols = &columns
    let statusline = (&laststatus==1 && winnr('$')>1) || (&laststatus==2)
    let reqspaces_lastline = (statusline || !&ruler) ? 12 : 29
    let width = len(a:content)
    let limit = wincols - reqspaces_lastline
	let l:content = a:content
	if width + 1 > limit
		let l:content = strpart(l:content, 0, limit - 1)
		let width = len(l:content)
	endif
	" prevent scrolling caused by multiple echo
	let needredraw = (a:0 >= 1)? a:1 : 1
	if needredraw != 0
		redraw 
	endif
	if a:highlight != 0
		echohl Type
		echo l:content
		echohl NONE
	else
		echo l:content
	endif
	if saveshow != 0
		set showmode
	endif
endfunc


"----------------------------------------------------------------------
" max height
"----------------------------------------------------------------------
function! quickui#utils#max_height(percentage)
	return (&lines) * a:percentage / 100
endfunc


"----------------------------------------------------------------------
" cursor movement
"----------------------------------------------------------------------
function! quickui#utils#movement(offset)
	let height = winheight(0)
	let winline = winline()
	let curline = line('.')
	let topline = curline - winline + 1
	let topline = (topline < 1)? 1 : topline
	let botline = topline + height - 1
	let offset = 0
	if type(a:offset) == v:t_number
		let offset = a:offset
	elseif type(a:offset) == v:t_string
		if a:offset == 'PAGEUP'
			let offset = -height
		elseif a:offset == 'PAGEDOWN'
			let offset = height
		elseif a:offset == 'HALFUP' || a:offset == 'LEFT'
			let offset = -(height / 2)
		elseif a:offset == 'HALFDOWN' || a:offset == 'RIGHT'
			let offset = height / 2
		elseif a:offset == 'UP'
			let offset = -1
		elseif a:offset == 'DOWN'
			let offset = 1
		elseif a:offset == 'TOP'
			exec "noautocmd normal gg"
			return
		elseif a:offset == 'BOTTOM'
			exec "noautocmd normal G"
			return
		endif
	endif
	" echom "offset: ". offset
	if offset > 0
		exec "noautocmd normal ". offset . "\<C-E>"
	elseif offset < 0
		exec "noautocmd normal ". (-offset) . "\<C-Y>"
	endif
endfunc


"----------------------------------------------------------------------
" cursor scroll
"----------------------------------------------------------------------
function! quickui#utils#scroll(winid, offset)
	if type(a:offset) == v:t_number
		let cmd = 'call quickui#utils#movement(' . a:offset . ')'
		call quickui#core#win_execute(a:winid, cmd)
	else
		let cmd = 'call quickui#utils#movement("' . a:offset . '")'
		call quickui#core#win_execute(a:winid, cmd)
	endif
endfunc



"----------------------------------------------------------------------
" centerize
"----------------------------------------------------------------------
function! quickui#utils#center(winid, ...)
	if g:quickui#core#has_nvim == 0
		let pos = popup_getpos(a:winid)
	else
		let pos = {}
		let pos.width = nvim_win_get_width(a:winid)
		let pos.height = nvim_win_get_height(a:winid)
	endif
	let h = pos.height
	let w = pos.width
	let mode = (a:0 < 1)? 0 : (a:1)
	let scale = (mode == 0)? 80 : 68
	let limit1 = (&lines - 2) * scale / 100
	let limit2 = (&lines - 2)
	let opts = {}
	if h + 4 < limit1
		let opts.line = (limit1 - h) / 2
	else
		let opts.line = (limit2 - h) / 2
	endif
	let opts.col = (&columns - w) / 2
	let opts.col = (opts.col < 1)? 1 : (opts.col)
	let hr = quickui#core#screen_fit(opts.line, opts.col, w, h)
	let opts.col = hr[1]
	let opts.line = hr[0]
	if g:quickui#core#has_nvim == 0
		call popup_move(a:winid, opts)
	else
		let no = {'col': opts.col - 1, 'row': opts.line - 1}
		let no.relative = 'editor'
		call nvim_win_set_config(a:winid, no)
	endif
endfunc


"----------------------------------------------------------------------
" show cursorline in textbox
"----------------------------------------------------------------------
function! quickui#utils#show_cursor(winid, row)
	let height = winheight(0)
	let winline = winline()
	let curline = line('.')
	let topline = curline - winline + 1
	let topline = (topline < 1)? 1 : topline
	let botline = topline + height - 1
	let w:__quickui_line__ = get(w:, '__quickui_line__', -1)
	if a:row >= topline && a:row <= botline
		exec ":" . a:row
		if w:__quickui_line__ != 1
			if g:quickui#core#has_nvim == 0
				call popup_setoptions(a:winid, {'cursorline': 1})
			else
				call quickui#core#win_execute(a:winid, 'setl cursorline')
				if exists('+cursorlineopt')
					call quickui#core#win_execute(a:winid, 'setl cursorlineopt=both')
				endif
			endif
		endif
		let w:__quickui_line__ = 1
	else
		if w:__quickui_line__ != 0
			if g:quickui#core#has_nvim == 0
				call popup_setoptions(a:winid, {'cursorline': 0})
			else
				call quickui#core#win_execute(a:winid, 'setl nocursorline')
			endif
		endif
		let w:__quickui_line__ = 0
	endif
endfunc


"----------------------------------------------------------------------
" update cursor line
"----------------------------------------------------------------------
function! quickui#utils#update_cursor(winid)
	let bid = winbufnr(a:winid)
	let row = getbufvar(bid, '__quickui_cursor__', -1)
	let cmd = 'call quickui#utils#show_cursor('. a:winid .', '.row.')'
	call quickui#core#win_execute(a:winid, cmd)
endfunc


"----------------------------------------------------------------------
" get window line
"----------------------------------------------------------------------
function! quickui#utils#get_cursor(winid)
	let g:quickui#utils#__cursor_index__ = -1
	let cmd = 'let g:quickui#utils#__cursor_index__ = line(".")'
	noautocmd call quickui#core#win_execute(a:winid, cmd)
	return g:quickui#utils#__cursor_index__
endfunc


"----------------------------------------------------------------------
" get topline in current window
"----------------------------------------------------------------------
function! quickui#utils#current_topline()
	let height = winheight(0)
	let winline = winline()
	let curline = line('.')
	let topline = curline - winline + 1
	return topline
endfunc


"----------------------------------------------------------------------
" get first cursorline
"----------------------------------------------------------------------
function! quickui#utils#get_topline(winid)
	let g:quickui#utils#__cursor_topline__ = -1
	let cmd = 'let g:quickui#utils#__cursor_topline__ = '
	let cmd = cmd . 'quickui#utils#current_topline()'
	call quickui#core#win_execute(a:winid, cmd)
	return g:quickui#utils#__cursor_topline__
endfunc


"----------------------------------------------------------------------
" make border
"----------------------------------------------------------------------
function! quickui#utils#make_border(width, height, border, title, ...)
	let pattern = quickui#core#border_get(a:border)
	let image = []
	let w = a:width
	let h = a:height
	let text = pattern[0] . repeat(pattern[1], w) . pattern[2]
	let image += [text]
	let index = 0
	while index < h
		let text = pattern[3] . repeat(' ', w) . pattern[5]
		let image += [text]
		let index += 1
	endwhile
	let text = pattern[6] . repeat(pattern[7], w) . pattern[8]
	let image += [text]
	let button = (a:0 > 0)? (a:1) : 0
	let align = (a:0 > 1)? (a:2) : ''
	let text = image[0]
	let title = quickui#core#string_fit(a:title, w)
	if align == '' || align == 'l'
		let text = quickui#core#string_compose(text, 1, title)
	elseif align == 'm'
		let left = (w + 2 - len(title)) / 2
		let text = quickui#core#string_compose(text, left, title)
	elseif align == 'r'
		let left = w + 2 - len(title) - 1
		let text = quickui#core#string_compose(text, left, title)
	endif
	if button != 0
		let text = quickui#core#string_compose(text, w + 1, 'X')
	endif
	let image[0] = text
	return image
endfunc


"----------------------------------------------------------------------
" search or jump
"----------------------------------------------------------------------
function! quickui#utils#search_or_jump(winid, cmd)
	if a:cmd == '/' || a:cmd == '?'
		let prompt = (a:cmd == '/')? '/' : '?'
		" let prompt = (a:cmd == '/')? '(search): ' : '(search backwards): '
		let t = quickui#core#input(prompt, '')
		if t != '' && t != "\<c-c>"
			try
				silent call quickui#core#win_execute(a:winid, a:cmd . t)
			catch /^Vim\%((\a\+)\)\=:E486:/
				call quickui#utils#errmsg('E486: Pattern not find: '. t)
			endtry
			silent! call quickui#core#win_execute(a:winid, 'nohl')
			call setwinvar(a:winid, '__quickui_search_cmd', a:cmd)
			call setwinvar(a:winid, '__quickui_search_key', t)
		endif
	elseif a:cmd == ':'
		let prompt = ':'
		" let prompt = '(goto): '
		let t = quickui#core#input(prompt, '')
		if t != ''
			call quickui#core#win_execute(a:winid, ':' . t)	
		endif
	endif
endfunc


"----------------------------------------------------------------------
" search next
"----------------------------------------------------------------------
function! quickui#utils#search_next(winid, cmd)
	let prev_cmd = getwinvar(a:winid, '__quickui_search_cmd', '')
	let prev_key = getwinvar(a:winid, '__quickui_search_key', '')
	if prev_key != ''
		if a:cmd ==# 'n' || a:cmd == 'NEXT'
			let cmd = (prev_cmd == '/')? '/' : '?'
		else
			let cmd = (prev_cmd == '/')? '?' : '/'
		endif
		try
			silent call quickui#core#win_execute(a:winid, cmd . prev_key)
		catch /^Vim\%((\a\+)\)\=:E486:/
		endtry
		noautocmd call quickui#core#win_execute(a:winid, 'nohl')
	endif
	let cmds = ['exec line(".")']
	let cmds += ['normal! 0']
	silent call quickui#core#win_execute(a:winid, cmds)
endfunc


"----------------------------------------------------------------------
" size can be in '24' or '24%' or '0.25'
"----------------------------------------------------------------------
function! quickui#utils#read_size(text, maxsize)
	if type(a:text) == v:t_number
		return a:text
	elseif type(a:text) == v:t_string
		let text = trim(a:text)
		if text =~ '%$'
			let text = strpart(text, 0, len(text) - 1)
			let ratio = str2nr(text)
			let num = (a:maxsize) * ratio / 100
			return (num < a:maxsize)? num : a:maxsize
		else
			let fsize = str2float(a:text)
			if fsize <= 1.0
				return float2nr(fsize * a:maxsize)
			endif
			let size = float2nr(fsize)
			return (size > a:maxsize)? a:maxsize : size
		endif
	elseif type(a:text) == v:t_float
		let fsize = a:text
		if fsize <= 1.0
			return float2nr(fsize * a:maxsize)
		endif
		let size = float2nr(fsize)
		return (size > a:maxsize)? a:maxsize : size
	endif
endfunc



"----------------------------------------------------------------------
" get default tools width
"----------------------------------------------------------------------
function! quickui#utils#tools_width()
	let width = get(g:, 'quickui_tools_width', '60%')
	let size = quickui#utils#read_size(width, &columns)
	let minimal = (60 < &columns)? 60 : &columns
	let size = (size < minimal)? minimal : size
	return (size > &columns)? &columns : size
endfunc


"----------------------------------------------------------------------
" read from register or evaluation
"----------------------------------------------------------------------
function! quickui#utils#read_eval(...)
	let opts = (a:0 == 0)? {} : (a:1)
	try
		let code = getchar()
	catch /^Vim:Interrupt$/
		let code = "\<C-C>"
	endtry
	let ch = (type(code) == v:t_number)? nr2char(code) : code
	if ch == "\<c-c>"
		return ''
	elseif ch == "\<esc>" || ch == "\<cr>"
		return ''
	elseif ch == "="
		let e = input('=')
		if e == ''
			return ''
		endif
		return eval(e)
	elseif ch == "\<c-w>"
		let x = expand('<cword>')
		return x
	elseif len(ch) == 1
		let x = eval('@' . ch)
		return x
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" normalize textlist
"----------------------------------------------------------------------
function! quickui#utils#text_list_normalize(textlist)
	if type(a:textlist) == v:t_list
		let textlist = a:textlist
	else
		let textlist = split('' . a:textlist, '\n', 1)
	endif
	let out = []
	for text in textlist
		let text = substitute(text, '[\r\n\t]', ' ', 'g')
		let out += [text]
	endfor
	return out
endfunc



"----------------------------------------------------------------------
" getchar
"----------------------------------------------------------------------
function! quickui#utils#getchar(wait)
	try
		if a:wait != 0
			let code = getchar()
		else
			let code = getchar(0)
		endif
	catch /^Vim:Interrupt$/
		let code = "\<C-C>"
	endtry
	if type(code) == v:t_number && code == 0
		try
			exec 'sleep 15m'
			continue
		catch /^Vim:Interrupt$/
			let code = "\<c-c>"
		endtry
	endif
	let ch = (type(code) == v:t_number)? nr2char(code) : code
	return ch
endfunc



"----------------------------------------------------------------------
" switch buffer
"----------------------------------------------------------------------
function! quickui#utils#switch(filename, opts)
	let switch = get(g:, 'quickui_switch_mode', &switchbuf)
	let switch = get(a:opts, 'switch', switch)
	let method = split(switch, ',')
	let goto = get(a:opts, 'goto', -1)
	let ft = get(a:opts, 'ft', '')
	let cmds = get(a:opts, 'command', [])
	if type(a:filename) == type('')
		let filename = expand(a:filename)
		if filereadable(filename) == 0
			if get(a:opts, 'exist', 0) != 0
				echohl ErrorMsg
				echom "E484: Can't open file " . (a:filename)
				echohl None
				return 0
			endif
		endif
		let bid = bufnr(filename)
	else
		let bid = a:filename
		if bid < 0
			return 0
		endif
	endif
	if index(method, 'useopen') >= 0
		for wid in range(winnr('$'))
			let b = winbufnr(wid + 1)
			if b == bid
				silent exec ''. (wid + 1) . 'wincmd w'
				if goto > 0
					silent exec ':' . goto
				endif
				for cmd in cmds
					exec cmd
				endfor
				return 1
			endif
		endfor
	endif
	if index(method, 'usetab') >= 0
		for tid in range(tabpagenr('$'))
			let buflist = tabpagebuflist(tid + 1)
			for wid in range(len(buflist))
				if bid == buflist[wid]
					silent exec 'tabn ' . (tid + 1)
					silent exec '' . (wid + 1) . 'wincmd w'
					if goto > 0
						silent exec ':' . goto
					endif
					for cmd in cmds
						exec cmd
					endfor
					return 1
				endif
			endfor
		endfor
	endif
	if index(method, 'newtab') >= 0
		silent exec 'tab split'
	elseif index(method, 'uselast') >= 0
		silent exec 'wincmd p'
	elseif index(method, 'edit') >= 0
		silent exec ''
	elseif index(method, 'drop') >= 0
	else
		if &buftype != ''
			silent exec 'wincmd p'
		endif
		for i in range(winnr('$'))
			if &buftype == ''
				break
			endif
			silent exec 'wincmd w'
		endfor
		let mods = get(a:opts, 'mods', '')
		if index(method, 'auto') >= 0
			if winwidth(0) >= 160
				exec mods . ' vsplit'
			else
				exec mods . ' split'
			endif
		elseif index(method, 'split') >= 0
			exec mods . ' split'
		elseif index(method, 'vsplit') >= 0
			exec mods . ' vsplit'
		endif
	endif
	try
		let force = ((get(a:opts, 'force', 0) != 0)? '!' : '')
		if bid >= 0
			exec 'b' . force . ' ' . bid
		else
			exec 'edit' . force . ' ' . fnameescape(expand(a:filename))
		endif
	catch /^Vim\%((\a\+)\)\=:E37:/ 
		echohl ErrorMsg
		echo 'E37: No write since last change (set force=1 to override)'
		echohl None
		return 0
	endtry
	if goto > 0
		exec ':' . goto
	endif
	if ft != ''
		exec 'setlocal ft=' . fnameescape(ft)
	endif
	for cmd in cmds
		exec cmd
	endfor
	return 1
endfunc



"----------------------------------------------------------------------
" returns 1 if filetype matches pattern, otherwise returns 0
"----------------------------------------------------------------------
function! quickui#utils#match_ft(filetype, pattern)
	let pattern = quickui#core#string_strip(a:pattern)
	let ft = a:filetype
	if pattern == ''
		return 0
	elseif pattern =~ '^/'
		let pattern = strpart(pattern, 1)
		if match(ft, pattern) >= 0
			return 1
		endif
	elseif pattern =~ '^!'
		let pattern = strpart(pattern, 1)
		if match(ft, pattern) < 0
			return 1
		endif
	endif
	let blacklist = []
	let whitelist = []
	for check in split(pattern, ',')
		if pattern[0] == '-'
			let blacklist += [check]
		else
			let whitelist += [check]
		endif
	endfor
	if index(blacklist, '-' . ft) >= 0
		return 0
	endif
	if empty(whitelist) || index(whitelist, ft) >= 0
		return 1
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" format table
"----------------------------------------------------------------------
function! quickui#utils#tabulify(rows)
	let content = []
	let rows = []
	let nrows = len(a:rows)
	let ncols = 0
	for row in a:rows
		if len(row) > ncols
			let ncols = len(row)
		endif
	endfor
	if nrows == 0 || ncols == 0
		return content
	endif
	let sizes = repeat([0], ncols)
	let index = range(ncols)
	for row in a:rows
		let newrow = deepcopy(row)
		if len(newrow) < ncols
			let newrow += repeat([''], ncols - len(newrow))
		endif
		for i in index
			let size = strwidth(newrow[i])
			let sizes[i] = (sizes[i] < size)? size : sizes[i]
		endfor
		let rows += [newrow]
	endfor
	for row in rows
		let ni = []
		for i in index
			let x = row[i]
			let size = strwidth(x)
			if size < sizes[i]
				let x = x . repeat(' ', sizes[i] - size)
			endif
			let ni += [x]
		endfor
		let content += [ni]
	endfor
	return content
endfunc


"----------------------------------------------------------------------
" print table
"----------------------------------------------------------------------
function! quickui#utils#print_table(rows, highmap)
	let content = quickui#utils#tabulify(a:rows)
	let index = 0
	for line in content
		let col = 0
		echon (index == 0)? " " : "\n "
		for cell in line
			let key = index . ',' . col
			if !has_key(a:highmap, key)
				echohl None
			else
				exec 'echohl ' . a:highmap[key]
			endif
			echon cell . '  '
			let col += 1
		endfor
		let index += 1
	endfor
	echohl None
endfunc


"----------------------------------------------------------------------
" hide/show cursor
"----------------------------------------------------------------------
function! quickui#utils#hide_system_cursor(hide) abort
	if !exists('s:cursor_highlight')
		let s:cursor_highlight = hlget('Cursor')
	endif
	if !exists('s:cursor_guicursor')
		let s:cursor_guicursor = &guicursor
	endif
	if !exists('s:cursor_tve')
		let s:cursor_tve = &t_ve
	endif
	if !exists('s:cursor_current')
		let s:cursor_current = 0
	endif
	if a:hide == 0
		call hlset(s:cursor_highlight)
		let &guicursor = s:cursor_guicursor
		let &t_ve = s:cursor_tve
		let s:cursor_current = 0
	else
		if s:cursor_current == 0
			let s:cursor_current = 1
			let s:cursor_highlight = hlget('Cursor')
			let s:cursor_guicursor = &guicursor
			let s:cursor_tve = &t_ve
		endif
		exec 'hi! clear Cursor'
		exec 'hi! link Cursor Normal'
		exec 'set t_ve='
		exec 'set guicursor=a:ver25-Cursor/lCursor'
	endif
endfunc




