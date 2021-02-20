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
			call self.backspace(1)
		elseif char == "\<DELETE>"
			call self.delete(1)
		elseif char == "\<LEFT>"
			call self.move(self.cursor - 1)
		elseif char == "\<RIGHT>"
			call self.move(self.cursor + 1)
		elseif char == "\<UP>"
			call self.history_prev()
		elseif char == "\<DOWN>"
			call self.history_next()
		elseif char == "\<c-d>"
			call self.delete(1)
		elseif char == "\<c-k>"
			if self.size > self.cursor
				call self.delete(self.size - self.cursor)
			endif
		elseif char == "\<home>"
			call self.move(0)
		elseif char == "\<end>"
			call self.move(self.size)
		elseif char == "\<C-Insert>"
		elseif char == "\<S-Insert>"
		elseif char == "\<c-w>"
		else
			return -1
		endif
		return 0
	else
		call self.insert(char)
	endif
	return 0
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
	call assert_equal('78', obj.visual_text(), 'test visual selection')
	call obj.visual_delete()
	call assert_equal('012ab9', obj.update(), 'test visual delete2')
	if len(v:errors) 
		for error in v:errors
			echoerr error
		endfor
	endif
	return obj.update()
endfunc

" echo quickui#readline#test()


"----------------------------------------------------------------------
" test
"----------------------------------------------------------------------
function! quickui#readline#cli(prompt)
	let rl = quickui#readline#new()
endfunc


