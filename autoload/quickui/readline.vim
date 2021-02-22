"======================================================================
"
" readline.vim - 
"
" Created by skywind on 2021/02/20
" Last Modified: 2021/02/20 12:58:24
"
"======================================================================


"----------------------------------------------------------------------
" readline class
"----------------------------------------------------------------------
let s:readline = {}
let s:readline.cursor = 0       " cursur position in character
let s:readline.code = []        " buffer character in int list
let s:readline.wide = []        " char display width
let s:readline.size = 0         " buffer size in character
let s:readline.text = ''        " text buffer
let s:readline.dirty = 0        " dirty
let s:readline.select = -1      " visual selection start pos
let s:readline.history = []     " history text
let s:readline.index = 0        " history pointer, 0 for current


"----------------------------------------------------------------------
" move pos
"----------------------------------------------------------------------
function! s:readline.move(pos) abort
	let pos = a:pos
	let pos = (pos < 0)? 0 : pos
	let pos = (pos > self.size)? self.size : pos
	let self.cursor = pos
	return pos
endfunc


"----------------------------------------------------------------------
" change position, mode: 0/start, 1/current, 2/eol
"----------------------------------------------------------------------
function! s:readline.seek(pos, mode) abort
	if a:mode == 0
		call self.move(a:pos)
	elseif a:mode == 1
		call self.move(self.cursor + a:pos)
	else
		call self.move(self.size + a:pos)
	endif
endfunc


"----------------------------------------------------------------------
" set text
"----------------------------------------------------------------------
function! s:readline.set(text)
	let code = str2list(a:text)
	let wide = []
	for cc in code
		let ch = nr2char(cc)
		let wide += [strdisplaywidth(cc)]
	endfor
	let self.code = code
	let self.wide = wide
	let self.size = len(code)
	let self.dirty = 1
	call self.move(self.cursor)
endfunc


"----------------------------------------------------------------------
" internal: update text parts
"----------------------------------------------------------------------
function! s:readline.update() abort
	let self.text = list2str(self.code)
	let self.dirty = 0
	return self.text
endfunc


"----------------------------------------------------------------------
" extract text: -1/0/1 for text before/on/after cursor
"----------------------------------------------------------------------
function! s:readline.extract(locate)
	let cc = self.cursor
	if a:locate < 0
		let p = slice(self.code, 0, cc)
	elseif a:locate == 0
		let p = slice(self.code, cc, cc + 1)
	else
		let p = slice(self.code, cc + 1)
	endif
	return list2str(p)
endfunc


"----------------------------------------------------------------------
" insert text in current cursor position
"----------------------------------------------------------------------
function! s:readline.insert(text) abort
	let code = str2list(a:text)
	let wide = []
	let cursor = self.cursor
	for cc in code
		let ch = nr2char(cc)
		let wide += [strdisplaywidth(cc)]
	endfor
	call extend(self.code, code, cursor)
	call extend(self.wide, wide, cursor)
	let self.size = len(self.code)
	let self.cursor += len(code)
	let self.dirty = 1
endfunc


"----------------------------------------------------------------------
" internal function: delete n characters on and after cursor
"----------------------------------------------------------------------
function! s:readline.delete(size) abort
	let cursor = self.cursor
	let avail = self.size - cursor
	if avail > 0
		let size = a:size
		let size = (size > avail)? avail : size
		let cursor = self.cursor
		call remove(self.code, cursor, cursor + size - 1)
		call remove(self.wide, cursor, cursor + size - 1)
		let self.size = len(self.code)
		let self.dirty = 1
	endif
endfunc


"----------------------------------------------------------------------
" backspace
"----------------------------------------------------------------------
function! s:readline.backspace(size) abort
	let avail = self.cursor
	let size = a:size
	let size = (size > avail)? avail : size
	if size > 0
		let self.cursor -= size
		call self.delete(size)
		let self.dirty = 1
	endif
endfunc


"----------------------------------------------------------------------
" replace
"----------------------------------------------------------------------
function! s:readline.replace(text) abort
	let length = strchars(a:text)
	if length > 0
		call self.delete(length)
		call self.insert(a:text)
		let self.dirty = 1
	endif
endfunc


"----------------------------------------------------------------------
" get selection range [start, end)
"----------------------------------------------------------------------
function! s:readline.visual_range() abort
	if self.select < 0
		return [-1, -1]
	elseif self.select <= self.cursor
		return [self.select, self.cursor]
	else
		return [self.cursor, self.select]
	endif
endfunc


"----------------------------------------------------------------------
" get selection text
"----------------------------------------------------------------------
function! s:readline.visual_text() abort
	if self.select < 0
		return ''
	else
		let [start, end] = self.visual_range()
		let code = slice(self.code, start, end)
		return list2str(code)
	endif
endfunc


"----------------------------------------------------------------------
" delete selection
"----------------------------------------------------------------------
function! s:readline.visual_delete() abort
	if self.select >= 0
		let cursor = self.cursor
		let length = self.cursor - self.select
		if length > 0
			call self.backspace(length)
			let self.select = -1
		elseif length < 0
			call self.delete(-length)
			let self.select = -1
		endif
	endif
endfunc


"----------------------------------------------------------------------
" replace selection
"----------------------------------------------------------------------
function! s:readline.visual_replace(text) abort
	if self.select >= 0
		call self.visual_delete()
		call self.insert(a:text)
	endif
endfunc


"----------------------------------------------------------------------
" check is eol
"----------------------------------------------------------------------
function! s:readline.is_eol()
	return self.cursor >= self.size
endfunc


"----------------------------------------------------------------------
" read code (what == 0) or wide (what != 0)
"----------------------------------------------------------------------
function! s:readline.read_data(pos, width, what)
	let x = a:pos
	let w = a:width
	let size = self.size
	if x < 0
		let w += x
		let x = 0
	endif
	if x + w > size
		let w = size - x
	endif
	if x >= size || w <= 0
		return []
	endif
	let data = (a:what == 0)? self.code : self.wide
	return slice(data, x, x + w)
endfunc


"----------------------------------------------------------------------
" calculate available view port size, give length in display-width,
" returns how many characters can fit in length.
"----------------------------------------------------------------------
function! s:readline.avail(pos, length)
	let length = a:length
	let size = self.size
	let wide = self.wide
	let pos = a:pos
	let sum = 0
	if length == 0
		return 0
	elseif length > 0
		while 1
			let char_width = (pos >= 0 && pos < size)? wide[pos] : 1
			let sum += char_width
			if sum > length
				break
			endif
			let pos += 1
		endwhile
		return pos - a:pos
	else
		while 1
			let char_width = (pos >= 0 && pos < size)? wide[pos] : 1
			let sum += char_width
			if sum > length
				break
			endif
			let pos -= 1
		endwhile
		return a:pos - pos
	endif
endfunc


"----------------------------------------------------------------------
" display: returns a list of text string with attributes
" eg. the readline buffer is "Hello, World !!" and cursor is on "W"
" the returns value should be:
" [(0, "Hello, "), (1, "W"), (0, "orld !!")]
" avail attributes: 0/normal-text, 1/cursor, 2/visual, 3/visual+cursor
"----------------------------------------------------------------------
function! s:readline.display()
	let size = self.size
	let cursor = self.cursor
	let codes = self.code
	let display = []
	if (self.select < 0) || (self.select == cursor)
		" content before cursor
		if cursor > 0
			let code = slice(codes, 0, cursor)
			let display += [[0, list2str(code)]]
		endif
		" content on cursor
		let code = (cursor < size)? codes[cursor] : char2nr(' ')
		let display += [[1, list2str([code])]]
		" content after cursor
		if cursor + 1 < size
			let code = slice(codes, cursor + 1, size)
			let display += [[0, list2str(code)]]
		endif
	else
		let vis_start = (cursor < self.select)? cursor : self.select
		let vis_endup = (cursor > self.select)? cursor : self.select
		" content befor visual selection
		if vis_start > 0
			let code = slice(codes, 0, vis_start)
			let display += [[0, list2str(code)]]
		endif
		" content in visual selection
		if cursor < self.select
			let code = [codes[cursor]]
			let display += [[3, list2str(code)]]
			let code = slice(codes, cursor + 1, vis_endup)
			let display += [[2, list2str(code)]]
			if vis_endup < size
				let code = slice(codes, vis_endup, size)
				let display += [[0, list2str(code)]]
			endif
		else
			" visual selection
			let code = slice(codes, vis_start, vis_endup)
			let display += [[2, list2str(code)]]
			" content on cursor
			let code = (cursor < size)? codes[cursor] : char2nr(' ')
			let display += [[1, list2str([code])]]
			" content after cursor
			if cursor + 1 < size
				let code = slice(codes, cursor + 1, size)
				let display += [[0, list2str(code)]]
			endif
		endif
	endif
	return display
endfunc


"----------------------------------------------------------------------
" save history in current position
"----------------------------------------------------------------------
function! s:readline.history_save() abort
	let size = len(self.history)
	if size > 0
		let self.index = (self.index < 0)? 0 : self.index
		let self.index = (self.index >= size)? (size - 1) : self.index
		if self.dirty
			call self.update()
		endif
		let self.history[self.index] = self.text
	endif
endfunc


"----------------------------------------------------------------------
" previous history
"----------------------------------------------------------------------
function! s:readline.history_prev() abort
	let size = len(self.history)
	if size > 0
		call self.history_save()
		let self.index = (self.index < size - 1)? (self.index + 1) : 0
		call self.set(self.history[self.index])
	endif
endfunc


"----------------------------------------------------------------------
" next history
"----------------------------------------------------------------------
function! s:readline.history_next() abort
	let size = len(self.history)
	if size > 0
		call self.history_save()
		let self.index = (self.index <= 0)? (size - 1) : (self.index - 1)
		call self.set(self.history[self.index])
	endif
endfunc


"----------------------------------------------------------------------
" init history
"----------------------------------------------------------------------
function! s:readline.history_init(history) abort
	if len(a:history) == 0
		let self.history = []
		let self.index = 0
	else
		let history = deepcopy(a:history) + ['']
		call reverse(history)
		let self.history = history
		let self.index = 0
	endif
endfunc


"----------------------------------------------------------------------
" feed character
"----------------------------------------------------------------------
function! s:readline.feed(char) abort
	let char = a:char
	let code = str2list(char)
	let head = len(code)? code[0] : 0
	if head < 0x20 || head == 0x80
		if char == "\<BS>"
			if self.select >= 0
				call self.visual_delete()
			else
				call self.backspace(1)
			endif
		elseif char == "\<DELETE>"
			if self.select >= 0
				call self.visual_delete()
			else
				call self.delete(1)
			endif
		elseif char == "\<LEFT>" || char == "\<c-b>"
			if self.select >= 0
				call self.move(min([self.select, self.cursor]))
				let self.select = -1
			else
				call self.seek(-1, 1)
			endif
		elseif char == "\<RIGHT>" || char == "\<c-f>"
			if self.select >= 0
				call self.move(max([self.select, self.cursor]))
				let self.select = -1
			else
				call self.seek(1, 1)
			endif
		elseif char == "\<UP>"
			call self.history_prev()
			let self.select = -1
		elseif char == "\<DOWN>"
			call self.history_next()
			let self.select = -1
		elseif char == "\<S-Left>"
			if self.select < 0
				let self.select = self.cursor
			endif
			call self.seek(-1, 1)
		elseif char == "\<S-Right>"
			if self.select < 0
				let self.select = self.cursor
			endif
			call self.seek(1, 1)
		elseif char == "\<S-Home>"
			if self.select < 0
				let self.select = self.cursor
			endif
			call self.seek(0, 0)
		elseif char == "\<S-End>"
			if self.select < 0
				let self.select = self.cursor
			endif
			call self.seek(0, 2)
		elseif char == "\<c-d>"
			if self.select >= 0
				call self.visual_delete()
			else
				call self.delete(1)
			endif
		elseif char == "\<c-k>"
			if self.select >= 0
				call self.visual_delete()
			else
				if self.size > self.cursor
					call self.delete(self.size - self.cursor)
				endif
			endif
		elseif char == "\<home>" || char == "\<c-a>"
			call self.move(0)
			let self.select = -1
		elseif char == "\<end>" || char == "\<c-e>"
			call self.move(self.size)
			let self.select = -1
		elseif char == "\<C-Insert>"
		elseif char == "\<S-Insert>"
		elseif char == "\<c-w>"
			if self.select < 0
				let head = self.extract(-1)
				let word = matchstr(head, '\S\+\s*$')
				if word != ''
					call self.backspace(strchars(word))
				endif
			else
				call self.visual_delete()
			endif
		elseif char == "\<c-c>"
			if self.select >= 0
				let text = self.visual_text()
				if text != ''
					let @0 = text
				endif
			endif
		elseif char == "\<c-x>"
			if self.select >= 0
				let text = self.visual_text()
				if text != ''
					let @0 = text
					call self.visual_delete()
				endif
			endif
		elseif char == "\<c-v>"
			let text = split(@0, "\n", 1)[0]
			if text != ''
				if self.select >= 0
					call self.visual_delete()
				endif
				call self.insert(text)
			endif
		else
			return -1
		endif
		return 0
	else
		if self.select >= 0
			call self.visual_delete()
		endif
		call self.insert(char)
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" display parts
"----------------------------------------------------------------------
function! s:readline.echo(blink)
	let display = self.display()
	for [attr, text] in display
		if attr == 0
			echohl Normal
		elseif attr == 1
			if a:blink == 0
				echohl Cursor
			else
				echohl Normal
			endif
		elseif attr == 2
			echohl Visual
		elseif attr == 3
			if a:blink == 0
				echohl Cursor
			else
				echohl Visual
			endif
		endif
		echon text
	endfor
endfunc


"----------------------------------------------------------------------
" constructor
"----------------------------------------------------------------------
function! quickui#readline#new()
	let obj = deepcopy(s:readline)
	return obj
endfunc


"----------------------------------------------------------------------
" test suit
"----------------------------------------------------------------------
function! quickui#readline#test()
	let v:errors = []
	let obj = quickui#readline#new()
	call obj.set('0123456789')
	call assert_equal('0123456789', obj.update(), 'test set')
	call obj.insert('ABC')
	call assert_equal('ABC0123456789', obj.update(), 'test insert')
	call obj.delete(3)
	call assert_equal('ABC3456789', obj.update(), 'test delete')
	call obj.backspace(2)
	call assert_equal('A3456789', obj.update(), 'test backspace')
	call obj.delete(1000)
	call assert_equal('A', obj.update(), 'test kill right')
	call obj.insert('BCD')
	call assert_equal('ABCD', obj.update(), 'test append')
	call obj.delete(1000)
	call assert_equal('ABCD', obj.update(), 'test append')
	call obj.backspace(1000)
	call assert_equal('', obj.update(), 'test append')
	call obj.insert('0123456789')
	call assert_equal('0123456789', obj.update(), 'test reinit')
	call obj.move(3)
	call obj.replace('abcd')
	call assert_equal('012abcd789', obj.update(), 'test replace')
	let obj.select = obj.cursor
	call obj.seek(-2, 1)
	call obj.visual_delete()
	call assert_equal('012ab789', obj.update(), 'test visual delete')
	let obj.select = obj.cursor
	call obj.seek(2, 1)
	echo obj.display()
	call assert_equal('78', obj.visual_text(), 'test visual selection')
	call obj.visual_delete()
	call assert_equal('012ab9', obj.update(), 'test visual delete2')
	call obj.seek(-2, 1)
	if len(v:errors) 
		for error in v:errors
			echoerr error
		endfor
	endif
	call obj.move(1)
	let obj.select = 4
	echo obj.display()
	return obj.update()
endfunc

" echo quickui#readline#test()


"----------------------------------------------------------------------
" cli test
"----------------------------------------------------------------------
function! quickui#readline#cli(prompt)
	let rl = quickui#readline#new()
	let index = 0
	let start = localtime()
	let accept = ''
	while 1
		noautocmd redraw
		echohl Question
		echon a:prompt
		let ts = float2nr(reltimefloat(reltime()) * 10)
		call rl.echo((ts % 8) < 3)
		" echon rl.display()
		try
			let code = getchar(0)
		catch /^Vim:Interrupt$/
			let code = "\<c-c>"
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
		if ch == ""
			continue
		elseif ch == "\<ESC>"
			break
		elseif ch == "\<cr>"
			let accept = rl.update()
			break
		else
			call rl.feed(ch)
		endif
	endwhile
	echohl None
	noautocmd redraw
	echo ""
	return accept
endfunc

echo quickui#readline#cli(">>> ")


