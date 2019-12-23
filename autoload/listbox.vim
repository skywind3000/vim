"======================================================================
"
" listbox.vim - 
"
" Created by skywind on 2019/12/20
" Last Modified: 2019/12/20 15:31:14
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :


"----------------------------------------------------------------------
" replace string
"----------------------------------------------------------------------
function! s:string_replace(text, old, new)
	let l:data = split(a:text, a:old, 1)
	return join(l:data, a:new)
endfunc


"----------------------------------------------------------------------
" eval & expand: '%{script}' in string
"----------------------------------------------------------------------
function! s:expand_text(string) abort
	let partial = []
	let index = 0
	while 1
		let pos = stridx(a:string, '%{', index)
		if pos < 0
			let partial += [strpart(a:string, index)]
			break
		endif
		let head = ''
		if pos > index
			let partial += [strpart(a:string, index, pos - index)]
		endif
		let endup = stridx(a:string, '}', pos + 2)
		if endup < 0
			let partial += [strpart(a:stirng, index)]
			break
		endif
		let index = endup + 1
		if endup > pos + 2
			let script = strpart(a:string, pos + 2, endup - (pos + 2))
			let script = substitute(script, '^\s*\(.\{-}\)\s*$', '\1', '')
			let result = eval(script)
			let partial += [result]
		endif
	endwhile
	return join(partial, '')
endfunc


"----------------------------------------------------------------------
" escape key character (starts by &) from string
"----------------------------------------------------------------------
function! s:escape(text)
	let text = a:text
	let rest = ''
	let start = 0
	let obj = ['', '', -1, -1, -1]
	while 1
		let pos = stridx(text, '&', start)
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
			let obj[1] = key
			let obj[2] = strlen(rest)
			let obj[3] = strchars(rest)
			let obj[4] = strdisplaywidth(rest)
			let rest .= key
		endif
	endwhile
	let obj[0] = rest
	return obj
endfunc


"----------------------------------------------------------------------
" list parse
"----------------------------------------------------------------------
function! s:single_parse(description)
	let item = { 'part': [], 'size': 0 }
	let item.key_char = ''
	let item.key_pos = -1
	let item.key_idx = -1
	for text in split(a:description, "\t")
		let obj = s:escape(text)
		let item.part += [obj[0]]
		if obj[2] >= 0 && item.key_idx < 0
			let item.key_char = obj[1]
			let item.key_pos = obj[3]
			let item.key_idx = item.size
		endif
		let item.size += 1
	endfor
	return item
endfunc


"----------------------------------------------------------------------
" parse
"----------------------------------------------------------------------
function! listbox#parse(lines)
	let items = {'image': [], 'column':0, 'nrows':0, 'keys':[]}
	let items.keymap = {}
	let items.displaywidth = 0
	let sizes = []
	let objects = []
	let spliter = '  '
	for line in a:lines
		let line = s:expand_text(line)
		let obj = s:single_parse(line)
		let objects += [obj]
		if obj.key_pos > 0
			let items.keymap[tolower(obj.key_char)] = items.nrows
		endif
		let items.nrows += 1
		while len(sizes) < obj.size
			let sizes += [0]
		endwhile
		let items.column = len(sizes)
		let index = 0
		for part in obj.part
			let size = strdisplaywidth(obj.part[index])
			if size > sizes[index]
				let sizes[index] = size
			endif
			let index += 1
		endfor
	endfor
	for obj in objects
		let start = 1
		let index = 0
		let output = ' '
		let ni = ['', -1]
		for part in obj.part
			let size = strdisplaywidth(part)
			let need = sizes[index]
			if size >= need
				let element = part
			else
				let element = part . repeat(' ', need - size)
			endif
			if obj.key_idx == index
				let ni[0] = obj.key_char
				let ni[1] = start + obj.key_pos
			endif
			let output .= element
			if index + 1 < len(obj.part)
				let output .= spliter
			endif
			let start += strchars(element) + strchars(spliter)
			let index += 1
		endfor
		let items.image += [output . ' ']
		let items.keys += [ni]
		let size = strdisplaywidth(output) + 1
		if size > items.displaywidth
			let items.displaywidth = size
		endif
	endfor
	return items
endfunc


"----------------------------------------------------------------------
" reposition text offset
"----------------------------------------------------------------------
function! listbox#reposition()
	exec 'normal! zz'
	let height = winheight(0)	
	let size = line('$')
	let curline = line('.')
	let winline = winline()
	let topline = curline - winline + 1
	let botline = topline + height - 1
	let disline = botline - size
	if disline > 0
		exec 'normal ggG'
		exec ':' . curline
		exec 'normal G'
		exec ':' . curline
	endif
endfunc


"----------------------------------------------------------------------
" highlight region
"----------------------------------------------------------------------
function! s:highlight_region(name, srow, scol, erow, ecol, virtual)
	let sep = (a:virtual == 0)? 'c' : 'v'
	let cmd = 'syn region ' . a:name . ' '
	let cmd .= ' start=/\%' . a:srow . 'l\%' . a:scol . sep . '/'
	let cmd .= ' end=/\%' . a:erow . 'l\%' . a:ecol . sep . '/'
	return cmd
endfunc


"----------------------------------------------------------------------
" highlight keys
"----------------------------------------------------------------------
function! s:highlight_keys(winid, items)
	let items = a:items
	let index = 0
	while index < items.nrows
		let key = items.keys[index]
		if key[1] >= 0
			let px = key[1] + 1
			let py = index + 1
			let cmd = s:highlight_region('KeyWord', py, px, py, px + 1, 1)
			call win_execute(a:winid, cmd)
		endif
		let index += 1
	endwhile
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
let s:maps["\<c-n>"] = 'DOWN'
let s:maps["\<c-p>"] = 'UP'
let s:maps["\<c-b>"] = 'PAGEUP'
let s:maps["\<c-f>"] = 'PAGEDOWN'
let s:maps["\<c-u>"] = 'HALFUP'
let s:maps["\<c-d>"] = 'HALFDOWN'
let s:maps["\<PageUp>"] = 'PAGEUP'
let s:maps["\<PageDown>"] = 'PAGEDOWN'
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


"----------------------------------------------------------------------
" local object
"----------------------------------------------------------------------
let s:local_obj = {}

function! s:popup_local(winid)
	if !has_key(s:local_obj, a:winid)
		let s:local_obj[a:winid] = {}
	endif
	return s:local_obj[a:winid]
endfunc

function! s:popup_clear(winid)
	if has_key(s:local_obj, a:winid)
		call remove(s:local_obj, a:winid)
	endif
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------

" border extract
function! s:border_extract(pattern)
	let parts = ['', '', '', '', '', '', '', '', '', '', '']
	for idx in range(11)
		let parts[idx] = strcharpart(a:pattern, idx, 1)
	endfor
	return parts
endfunc


function! s:border_convert(pattern)
	if type(a:pattern) == v:t_string
		let p = s:border_extract(a:pattern)
	else
		let p = a:pattern
	endif
	let pattern = [ p[1], p[5], p[7], p[3], p[0], p[2], p[8], p[6] ]
	return pattern
endfunc

let s:border_style = {}
let s:border_style[1] = s:border_extract('+-+|-|+-+++')
let s:border_style[2] = s:border_extract('┌─┐│─│└─┘├┤')
let s:border_style[3] = s:border_extract('╔═╗║─║╚═╝╟╢')

function! s:border_vim(name)
	let border = get(s:border_style, a:name, s:border_style[1])
	return s:border_convert(border)
endfunc


"----------------------------------------------------------------------
" init window
"----------------------------------------------------------------------
function! listbox#create(textlist, opts)
	let hwnd = {}
	let opts = {}
	let items = listbox#parse(a:textlist)
	let winid = popup_create(items.image, {'hidden':1, 'wrap':0})
	let bufnr = winbufnr(winid)
	let hwnd.winid = winid
	let hwnd.items = items
	let hwnd.bufnr = bufnr
	let hwnd.keymap = deepcopy(s:maps)
	let hwnd.hotkey = items.keymap
	let hwnd.opts = deepcopy(a:opts)
	let hwnd.context = has_key(a:opts, 'context')? a:opts.context : {}
	let w = has_key(a:opts, 'w')? a:opts.w + 2 : items.displaywidth
	let h = has_key(a:opts, 'h')? a:opts.h : items.nrows
	if h + 6 > &lines
		let h = &lines - 6
		let h = (h < 1)? 1 : h
	endif
	if w + 4 > &columns
		let w = &columns - 4
		let w = (w < 1)? 1 : w
	endif
	let opts = {"minwidth":w, "minheight":h, "maxwidth":w, "maxheight":h}
	if has_key(a:opts, 'line')
		let opts.line = a:opts.line
	else
		let limit1 = (&lines - 2) * 80 / 100
		let limit2 = (&lines - 2)
		if h + 4 < limit1
			let opts.line = (limit1 - h) / 2
		else
			let opts.line = (limit2 - h) / 2
		endif
		let opts.line = (opts.line < 1)? 1 : opts.line
	endif
	if has_key(a:opts, 'col')
		let opts.col = a:opts.col
	else
		let opts.col = (&columns - w) / 2
	endif
	call popup_move(winid, opts)
	" call setwinvar(winid, '&wincolor', get(a:opts, 'color', 'TVisionBG'))
	if get(a:opts, 'index', 0) >= 0
		let moveto = get(a:opts, 'index', 0) + 1
		call popup_show(winid)
		call win_execute(winid, 'normal! G')
		call win_execute(winid, ':' . moveto)
		call win_execute(winid, 'normal! G')
		call win_execute(winid, ':' . moveto)
		call win_execute(winid, 'call listbox#reposition()')
	endif
	call s:highlight_keys(winid, items)
	let border = get(a:opts, 'border', 1)
	let opts = {}
	if get(a:opts, 'manual', 0) == 0
		let opts.filter = 'listbox#filter'
		let opts.callback = 'listbox#callback'
	endif
	let opts.cursorline = 1
	let opts.drag = 1
	let opts.border = [0,0,0,0,0,0,0,0,0]
	if border > 0
		let opts.borderchars = s:border_vim(border)
		let opts.border = [1,1,1,1,1,1,1,1,1]
	endif
	let opts.title = has_key(a:opts, 'title')? ' ' . a:opts.title . ' ' : ''
	let opts.padding = [0,1,0,1]
	let opts.cursorline = 1
	let opts.mapping = 0
	let opts.drag = 1
	if has_key(a:opts, 'close')
		let opts.close = a:opts.close
	endif
	call popup_setoptions(winid, opts)
	let local = s:popup_local(winid)
	let local.hwnd = hwnd
	let local.winid = winid
	let keymap = hwnd.keymap
	if !has_key(a:opts, 'horizon')
		let keymap["\<LEFT>"] = 'HALFUP'
		let keymap["\<RIGHT>"] = 'HALFDOWN'
		let keymap["h"] = 'HALFUP'
		let keymap["l"] = 'HALFDOWN'
	endif
	let hwnd.state = 1
	let hwnd.code = 0
	return hwnd
endfunc


"----------------------------------------------------------------------
" close list box
"----------------------------------------------------------------------
function! listbox#close(hwnd)
	if a:hwnd.winid > 0
		call popup_close(a:hwnd.winid)
		call s:popup_clear(a:hwnd.winid)
		let a:hwnd.winid = -1
	endif
endfunc


"----------------------------------------------------------------------
" exit
"----------------------------------------------------------------------
function! listbox#callback(winid, code)
	let local = s:popup_local(a:winid)
	let hwnd = local.hwnd
	let code = a:code
	if a:code > 0
		call win_execute(a:winid, ':' . a:code)
		redraw
		let code = a:code - 1
	endif
	let hwnd.state = 0
	let hwnd.code = code
	call s:popup_clear(a:winid)
	if has_key(hwnd.opts, 'callback')
		let F = function(hwnd.opts.callback)
		call F(hwnd.context, code)
	endif
endfunc


"----------------------------------------------------------------------
" key processing
"----------------------------------------------------------------------
function! listbox#filter(winid, key)
	let local = s:popup_local(a:winid)
	let hwnd = local.hwnd
	let keymap = hwnd.keymap
	if a:key == "\<ESC>" || a:key == "\<c-c>"
		call popup_close(a:winid, -1)
		return 1
	elseif a:key == "\<CR>" || a:key == "\<SPACE>"
		return popup_filter_menu(a:winid, "\<CR>")
	elseif has_key(hwnd.hotkey, a:key)
		let index = hwnd.hotkey[a:key]
		call popup_close(a:winid, index + 1)
		return 1
	elseif has_key(keymap, a:key)
		let key = keymap[a:key]
		let cmd = 'listbox#cursor_movement("' . key . '")'
		call win_execute(a:winid, 'call ' . cmd)
		return 1
	endif
	return popup_filter_menu(a:winid, a:key)
endfunc


"----------------------------------------------------------------------
" how to move cursor
"----------------------------------------------------------------------
function! listbox#cursor_movement(where)
	let curline = line('.')
	let endline = line('$')
	let height = winheight('.')
	if a:where == 'TOP'
		let curline = 0
	elseif a:where == 'BOTTOM'
		let curline = line('$')
	elseif a:where == 'UP'
		let curline = curline - 1
	elseif a:where == 'DOWN'
		let curline = curline + 1
	elseif a:where == 'PAGEUP'
		let curline = curline - height
	elseif a:where == 'PAGEDOWN'
		let curline = curline + height
	elseif a:where == 'HALFUP'
		let curline = curline - height / 2
	elseif a:where == 'HALFDOWN'
		let curline = curline + height / 2
	endif
	if curline < 1
		let curline = 1
	elseif curline > endline
		let curline = endline
	endif
	exec ":" . curline
endfunc


"----------------------------------------------------------------------
" block and return result
"----------------------------------------------------------------------
function! listbox#inputlist(textlist, opts)
	let opts = deepcopy(a:opts)
	let opts.manual = 1
	if has_key(opts, 'callback')
		call remove(opts, 'callback')
	endif
	let hwnd = listbox#create(a:textlist, opts)
	let winid = hwnd.winid
	let hr = -1
	" call win_execute(winid, 'normal zz')
	call popup_show(winid)
	while 1
		redraw
		try
			let code = getchar()
		catch /^Vim:Interrupt$/
			let code = "\<C-C>"
		endtry
		let ch = (type(code) == v:t_number)? nr2char(code) : code
		if ch == "\<ESC>" || ch == "\<c-c>"
			break
		elseif ch == " " || ch == "\<cr>"
			let cmd = 'let g:listbox#index = line(".")'
			call win_execute(winid, cmd)
			let hr = g:listbox#index - 1
			break
		elseif has_key(hwnd.hotkey, ch)
			let hr = hwnd.hotkey[ch]
			if hr >= 0
				break
			endif
		elseif has_key(hwnd.keymap, ch)
			let key = hwnd.keymap[ch]
			let cmd = 'listbox#cursor_movement("' . key . '")'
			call win_execute(winid, 'call ' . cmd)
			call popup_hide(winid)
			call popup_show(winid)
		endif
	endwhile
	call listbox#close(hwnd)
	return hr
endfunc


"----------------------------------------------------------------------
" any callback
"----------------------------------------------------------------------
function! listbox#execute(context, code)
	if a:code >= 0
		if a:code < len(a:context)
			exec a:context[a:code]
		endif
	endif
endfunc


"----------------------------------------------------------------------
" open popup and run command when select an item
"----------------------------------------------------------------------
function! listbox#any(content, opts)
	let opts = deepcopy(a:opts)
	let opts.callback = 'listbox#execute'
	let textlist = []
	let cmdlist = []
	for desc in a:content
		if type(desc) == v:t_string
			let textlist += [desc]
			let cmdlist += ['']
		elseif type(desc) == v:t_list
			let textlist += [(len(desc) > 0)? desc[0] : '']
			let cmdlist += [(len(desc) > 1)? desc[1] : '']
		endif
	endfor
	let opts.context = cmdlist
	call listbox#create(textlist, opts)
endfunc


"----------------------------------------------------------------------
" testing suit
"----------------------------------------------------------------------
if 0
	let lines = [
				\ "[1]\tOpen &File\t(F3)",
				\ "[2]\tChange &Directory\t(F2)",
				\ "[3]\tHelp",
				\ "",
				\ "[4]\tE&xit",
				\ ]
	for ix in range(1000)
		let lines += ['line: ' . ix]
	endfor
	function! MyCallback(context, code)
		echo "exit: ". a:code . ' context: '. a:context . ' bufid: '. bufnr()
	endfunc
	let opts = {'title':'Select', 'border':1, 'index':400, 'close':'button'}
	let opts.context = 'asdfasdf'
	let opts.callback = 'MyCallback'
	if 0
		let inst = listbox#create(lines, opts)
		call popup_show(inst.winid)
	else
		let code = listbox#inputlist(lines, opts)
		echo "code: " . code
	endif
endif


if 0
	let content = [
				\ [ 'echo 1', 'echo 100' ],
				\ [ 'echo 2', 'echo 200' ],
				\ [ 'echo 3', 'echo 300' ],
				\ [ 'echo 4' ],
				\ [],
				\ [ 'echo 5', 'echo bufnr()' ],
				\]
	let opts = {'title': 'select'}
	call listbox#any(content, opts)
endif


