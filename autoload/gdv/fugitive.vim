"======================================================================
"
" fugitive.vim - 
"
" Created by skywind on 2025/11/16
" Last Modified: 2025/11/16 12:24:53
"
"======================================================================


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win16') || has('win64') || has('win95')
let s:quickfix = {}


"----------------------------------------------------------------------
" get git root for fugitive buffer
"----------------------------------------------------------------------
function! gdv#fugitive#root(bid) abort
	let name = bufname(a:bid)
	if name !~ '^fugitive:[\\/][\\/]'
		return ''
	endif
	let path = getbufvar(a:bid, 'git_dir', '')
	if path != '' && path =~ '[\\/]\.git$'
		let path = substitute(path, '[\\/]\.git$', '', '')
		if isdirectory(path)
			if s:windows
				let path = quickui#core#string_replace(path, '/', '\')
			endif
			return path
		endif
	endif
	let path = substitute(name, '^fugitive:[\\/][\\/]', '', '')
	let path = substitute(path, '[\\/]\.git[\\/].*$', '', '')
	if s:windows
		if path =~ '^[\\/]\a\:[\\/]'
			let path = strpart(path, 1)
		endif
	endif
	if isdirectory(path)
		if s:windows
			let path = quickui#core#string_replace(path, '/', '\')
		endif
		return path
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get fugitive quickfix entry buffer id
"----------------------------------------------------------------------
function! gdv#fugitive#qf_entry(index) abort
	let items = getqflist({'title':1, 'id':0})
	let title = quickui#core#string_strip(items.title)
	if title !~ ':Gclog'
		return -1
	endif
	if !has_key(s:quickfix, items.id)
		let s:quickfix[items.id] = getqflist()
	endif
	let content = s:quickfix[items.id]
	let index = a:index
	if index < 0 || index >= len(content)
		return -1
	endif
	let item = content[index]
	if !item.valid
		return -1
	endif
	let bid = item.bufnr
	if strlen(item.module) != 7
		return -1
	endif
	return bid
endfunc


"----------------------------------------------------------------------
" get git root for nofile buffer
"----------------------------------------------------------------------
function! gdv#fugitive#nofile_root() abort
	if &bt == ''
		return ''
	elseif &bt == 'nofile'
		if &ft == 'floggraph'
			if exists('b:flog_state')
				return get(b:flog_state, 'workdir', '')
			endif
		elseif &ft == 'agit_stat' || &ft == 'agit_diff'
			if exists('t:git')
				if has_key(t:git, 'git_root')
					return t:git['git_root']
				endif
			endif
		elseif &ft == 'magit'
			if exists('b:magit_top_dir')
				return b:magit_top_dir
			endif
		elseif &ft == 'NeogitStatus' && has('nvim')
			try
				let t = luaeval('require("neogit.lib.git").repo.git_root')
				return t
			catch
			endtry
		endif
		if exists('b:git_dir')
			let r = b:git_dir
			if r =~ '[\\/]\.git$'
				let r = substitute(r, '[\\/]\.git$', '', '')
			endif
			return r
		endif
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get current git root from variaous fugitive contexts
"----------------------------------------------------------------------
function! gdv#fugitive#current_root() abort
	if &bt == 'nofile'
		let root = gdv#fugitive#nofile_root()
		if root != '' && isdirectory(root)
			return root
		endif
	elseif &bt == 'quickfix'
		let bid = gdv#fugitive#qf_entry(line('.') - 1)
		if bid >= 0
			let root = gdv#fugitive#root(bid)
			if root != '' && isdirectory(root)
				return root
			endif
		endif
	endif
	let git = gdv#git#current_object()
	if has_key(git, 'root')
		return git.root
	endif
	let root = gdv#fugitive#root('%')
	if root != '' && isdirectory(root)
		let git.root = root
		return root
	endif
	let root = gdv#git#root('')
	if root != '' && isdirectory(root)
		let git.root = root
		return root
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get commit hash for fugitive buffer
"----------------------------------------------------------------------
function! gdv#fugitive#commit_hash(bid)
	let name = bufname(a:bid)
	if name !~ '^fugitive:[\\/][\\/]'
		return ''
	endif
	let ft = getbufvar(a:bid, '&filetype', '')
	let part = matchstr(name, '[\\/]\.git[\\/][\\/]\zs.*$')
	let commit = substitute(part, '[\\/].*$', '', '')
	return commit
endfunc


"----------------------------------------------------------------------
" build fugitive file name
"----------------------------------------------------------------------
function! gdv#fugitive#make(root, commit, fn) abort
	let name = 'fugitive://'
	if s:windows
		let name .= '/'
	endif
	let root = a:root
	if root =~ '^\~'
		let root = expand(root)
	endif
	let name .= root . '/.git//' . a:commit
	if a:fn != ''
		let name .= '/' . a:fn
	endif
	if s:windows
		let name = quickui#core#string_replace(name, '/', "\\")
	endif
	return name
endfunc


