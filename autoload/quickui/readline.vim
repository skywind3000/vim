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
let s:readline.size = 0	        " buffer size in character
let s:readline.text = ''        " text buffer
let s:readline.part = []        " 0/1/2: before/on/after cursor

let s:readline.on_move = ''     " on cursor move
let s:readline.on_change = ''   " on text change


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
" set text
"----------------------------------------------------------------------
function! s:readline.set(text)
	let code = list2str(text)
	let wide = []
	for cc in code
		let ch = nr2char(cc)
		let wide += [strdisplaywidth(cc)]
	endfor
	let self.code = code
	let self.wide = wide
	call self.move(self.cursor)
endfunc


"----------------------------------------------------------------------
" internal: update text parts
"----------------------------------------------------------------------
function! s:readline.update() abort
	let self.text = list2str(self.code)
	let self.size = len(self.code)
	let cc = self.cursor
	let p1 = slice(self.code, 0, cc)
	let p2 = slice(self.code, cc, cc + 1)
	let p3 = slice(self.code, cc + 1)
	let self.part = [list2str(p1), list2str(p2), list2str(p3)]
endfunc


"----------------------------------------------------------------------
" insert text in current cursor position
"----------------------------------------------------------------------
function! s:readline.insert(text) abort
	let code = str2list(text)
	let wide = []
	let cursor = self.cursor
	for cc in code
		let ch = nr2char(cc)
		let wide += [strdisplaywidth(cc)]
	endfor
	call insert(self.code, code, cursor)
	call insert(self.wide, wide, cursor)
	let self.cursor += len(code)
endfunc


"----------------------------------------------------------------------
" internal function: delete n characters on and after cursor
"----------------------------------------------------------------------
function! s:readline.delete(size) abort
	let avail = self.size - cursor
	if avail <= 0
		return 0
	endif
	let size = a:size
	let size = (size > avail)? avail : size
	let cursor = self.cursor
	call remove(self.code, cursor, cursor + size - 1)
	call remove(self.wide, cursor, cursor + size - 1)
	return 0
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
	endif
endfunc


"----------------------------------------------------------------------
" replace
"----------------------------------------------------------------------
function! s:readline.replace(text) abort
	let length = strchars(a:text)
	call self.delete(length)
	return self.insert(a:text)
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
		elseif char == "\<DELETE>"
		elseif char == "\<LEFT>"
		elseif char == "\<RIGHT>"
		elseif char == "\<UP>"
		elseif char == "\<DOWN>"
		else
			return -1
		endif
		return 0
	else
	endif
	return 0
endfunc


