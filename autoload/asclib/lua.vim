"======================================================================
"
" lua.vim - lua interface
"
" Created by skywind on 2022/11/29
" Last Modified: 2022/11/29 06:13:13
"
"======================================================================


"----------------------------------------------------------------------
" const variables
"----------------------------------------------------------------------
let s:has_lua = has('lua') || has('nvim')
let s:has_nvim = has('nvim')


"----------------------------------------------------------------------
" export variables
"----------------------------------------------------------------------
let g:asclib#lua#has_lua = s:has_lua
let g:asclib#lua#has_nvim = s:has_nvim


"----------------------------------------------------------------------
" call lua function
"----------------------------------------------------------------------
function! asclib#lua#call(funcname, args) abort
	lua vim.__temp_args = vim.fn.eval('a:args')
	return luaeval(a:funcname .. '(table.unpack(vim.__temp_args))')
endfunc


"----------------------------------------------------------------------
" force import
"----------------------------------------------------------------------
function! asclib#lua#require(name)
	lua package.loaded[vim.fn.eval('a:name')] = nil
	lua require(vim.fn.eval('a:name'))
endfunc


"----------------------------------------------------------------------
" import path
"----------------------------------------------------------------------
function! asclib#lua#get_imp_info(luafile)
	let luafile = a:luafile
	if luafile == '' || luafile == '%'
		let luafile = expand('%')
	endif
	let luaname = asclib#path#abspath(luafile)
	let package = []
	for path in split(&rtp, ',')
		let test = asclib#path#join(path, 'lua')
		if isdirectory(test)
			call add(package, test)
		endif
	endfor
	let pp = luaeval('package.path')
	for path in split(pp, ';')
		if path =~ '[\\\/]\?\.lua$'
			let path = substitute(path, '[\\\/]\?\.lua$', '', 'g')
			let path = substitute(path, '?$', '', 'g')
			if stridx(path, '?') < 0
				if isdirectory(path)
					call add(package, path)
				endif
			endif
		endif
	endfor
	for path in package
		let test = path
		if asclib#path#contains(test, luaname)
			let relpath = asclib#path#relpath(luaname, test)
			if relpath =~ '\.lua$'
				let relpath = substitute(relpath, '\.lua$', '', 'g')
				let relpath = tr(relpath, '\', '/')
				let relpath = tr(relpath, '/', '.')
				let test = asclib#path#normalize(test)
				return [test, relpath]
			endif
		endif
	endfor
	return ['', '']
endfunc


"----------------------------------------------------------------------
" get import name
"----------------------------------------------------------------------
function! asclib#lua#get_imp_name(luafile)
	let res = asclib#lua#get_imp_info(a:luafile)
	return res[1]
endfunc


"----------------------------------------------------------------------
" refresh file
"----------------------------------------------------------------------
function! asclib#lua#refresh(luafile)
	let impname = asclib#lua#get_imp_name(a:luafile)
	if impname != ''
		call asclib#lua#require(impname)
	else
		exec 'luafile ' . fnameescape(a:luafile)
	endif
endfunc


"----------------------------------------------------------------------
" timing
"----------------------------------------------------------------------
function! asclib#lua#timing()
	let ts = reltime()
	" call s:collect_rtp_config()
	call asclib#lua#get_imp_name('c:/share/vim/lua/core/ascmini.lua')
	let tt = reltimestr(reltime(ts))
	return tt
endfunc



