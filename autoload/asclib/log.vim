"======================================================================
"
" log.vim - 
"
" Created by skywind on 2024/03/13
" Last Modified: 2024/03/13 23:17
"
"======================================================================


"----------------------------------------------------------------------
" config
"----------------------------------------------------------------------
let s:enabled = {'debug':1, 'info':1, 'warn':1, 'error':1, 'fatal':1, '': 1}
let s:option = {'path': '~/.vim/logs', 'echo': 0, 'file': 1}


"----------------------------------------------------------------------
" enable channel
"----------------------------------------------------------------------
function! asclib#log#enable(channel, enabled) abort
	if has_key(s:enabled, a:channel)
		let s:enabled[a:channel] = a:enabled
	endif
endfunc


"----------------------------------------------------------------------
" set option
"----------------------------------------------------------------------
function! asclib#log#option(key, value) abort
	if has_key(s:option, a:key)
		let s:option[a:key] = a:value
	endif
endfunc


"----------------------------------------------------------------------
" get current log file name
"----------------------------------------------------------------------
function! asclib#log#name() abort
	let time = strftime('%Y-%m-%d')
	let name = 'm'. strpart(time, 0, 10) . '.log'
	let name = substitute(name, '-', '', 'g')
	let path = expand(s:option.path)
	let t = path .'/'. name
	if has('win32') || has('win64') || has('win16') || has('win95')
		return tr(t, '/', '\')
	endif
	return t
endfunc


"----------------------------------------------------------------------
" log output
"----------------------------------------------------------------------
function! s:writelog(text, ...) abort
	let text = (a:0 == 0)? a:text : a:text . ' '. join(a:000, ' ')
	let time = strftime('%Y-%m-%d %H:%M:%S')
	let name = 'm'. strpart(time, 0, 10) . '.log'
	let name = substitute(name, '-', '', 'g')
	let path = expand(s:option.path)
	let text = '['.time.'] ' . text
	let name = path .'/'. name
	if exists('*writefile') && s:option.file != 0
		if !isdirectory(path)
			silent! call mkdir(path, 'p')
		endif
		silent! call writefile([text . "\n"], name, 'a')
	endif
	if s:option.echo != 0
		echom text
	endif
	return 1
endfunc


"----------------------------------------------------------------------
" log to channel
"----------------------------------------------------------------------
function! asclib#log#out(channel, text, ...) abort
	if get(s:enabled, a:channel, 0)
		let text = (a:0 == 0)? a:text : a:text . ' '. join(a:000, ' ')
		if a:channel == ''
			call s:writelog(text)
		else
			call s:writelog('['.a:channel.'] '. text)
		endif
	endif
endfunc


"----------------------------------------------------------------------
" log format
"----------------------------------------------------------------------
function! asclib#log#format(fmt, args) abort
	return (len(a:args) == 0)? a:fmt : call('printf', [a:fmt] + a:args)
endfunc


"----------------------------------------------------------------------
" log printf 
"----------------------------------------------------------------------
function! asclib#log#printf(channel, fmt, ...) abort
	let t = asclib#log#format(a:fmt, a:000)
	call asclib#log#out(a:channel, t)
endfunc


"----------------------------------------------------------------------
" headless log
"----------------------------------------------------------------------
function! asclib#log#clear(fmt, ...) abort
	call asclib#log#out('', asclib#log#format(a:fmt, a:000))
endfunc


"----------------------------------------------------------------------
" log info
"----------------------------------------------------------------------
function! asclib#log#info(fmt, ...) abort
	call asclib#log#out('info', asclib#log#format(a:fmt, a:000))
endfunc


"----------------------------------------------------------------------
" log debug
"----------------------------------------------------------------------
function! asclib#log#debug(fmt, ...) abort
	call asclib#log#out('debug', asclib#log#format(a:fmt, a:000))
endfunc


"----------------------------------------------------------------------
" log warn
"----------------------------------------------------------------------
function! asclib#log#warn(fmt, ...) abort
	call asclib#log#out('warn', asclib#log#format(a:fmt, a:000))
endfunc


"----------------------------------------------------------------------
" log error
"----------------------------------------------------------------------
function! asclib#log#error(fmt, ...) abort
	call asclib#log#out('error', asclib#log#format(a:fmt, a:000))
endfunc


"----------------------------------------------------------------------
" log fatal
"----------------------------------------------------------------------
function! asclib#log#fatal(fmt, ...) abort
	call asclib#log#out('fatal', asclib#log#format(a:fmt, a:000))
endfunc


"----------------------------------------------------------------------
" dont't log anything
"----------------------------------------------------------------------
function! asclib#log#null(fmt, ...) abort
endfunc


"----------------------------------------------------------------------
" get log function 
"----------------------------------------------------------------------
function! asclib#log#get(name) abort
	if has_key(s:enabled, a:name) && a:name != ''
		return function('asclib#log#'.a:name)
	endif
	return function('asclib#log#clear')
endfunc



