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
" Extract git root from fugitive buffer name
" fugitive:///home/user/.vim/vim/.git//HASH
" fugitive:///home/user/.vim/vim/.git//HASH/autoload/gdv/git.vim
" fugitive:///home/user/.vim/vim/.git/module/NAME//HASH
" fugitive:///home/user/.vim/vim/.git/module/NAME//HASH/path/file
"----------------------------------------------------------------------
function! gdv#fugitive#name2root(name) abort
	let name = a:name
	if name !~ '^fugitive:[\\/][\\/]'
		return ''
	endif
	let path = substitute(name, '^fugitive:[\\/][\\/]', '', '')
	if s:windows && path =~ '^[\\/]\a\:'
		let path = strpart(path, 1)
	endif
	let path = substitute(path, '[\\/][\\/].*$', '', '')
	return gdv#git#git2root(path)
endfunc


"----------------------------------------------------------------------
" Extract commit hash from fugitive buffer name
" Format: fugitive://path/.git//commit
" For submodules: fugitive://path/.git/modules/submodule//commit
" The commit hash is always after the last "//"
"----------------------------------------------------------------------
function! gdv#fugitive#name2hash(name) abort
	let name = a:name
	if name !~ '^fugitive:[\\/][\\/]'
		return ''
	endif
	let name = substitute(name, '^fugitive:[\\/][\\/]', '', '')
	let part = matchstr(name, '[\\/][\\/]\zs[0-9a-f]\{4,40}\ze')
	if part != ''
		return part
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get git root for fugitive buffer
"----------------------------------------------------------------------
function! gdv#fugitive#root(bid) abort
	let name = bufname(a:bid)
	if name !~ '^fugitive:[\\/][\\/]'
		return ''
	endif
	let path = getbufvar(a:bid, 'git_dir', '')
	if path != ''
		let path = gdv#git#git2root(path)
		if path != ''
			return path
		endif
	endif
	let path = gdv#fugitive#name2root(name)
	if path != ''
		if isdirectory(path)
			return path
		endif
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
	if strlen(item.module) < 4
		return -1
	endif
	return bid
endfunc


"----------------------------------------------------------------------
" get git root from quickfix list item (works even if buffer is not open)
"----------------------------------------------------------------------
function! gdv#fugitive#qf_root(index) abort
	let items = getqflist({'title':1, 'id':0})
	if !has_key(s:quickfix, items.id)
		let s:quickfix[items.id] = getqflist()
	endif
	let content = s:quickfix[items.id]
	if a:index < 0 || a:index >= len(content)
		return ''
	endif
	let item = content[a:index]
	if item.bufnr > 0
		let bufname_str = ''
		if exists('*getbufinfo')
			try
				let buf_info = getbufinfo(item.bufnr)
				if len(buf_info) > 0 && has_key(buf_info[0], 'name')
					let bufname_str = buf_info[0].name
				endif
			catch
			endtry
		endif
		if bufname_str == ''
			let bufname_str = bufname(item.bufnr)
		endif
		if bufname_str != '' && bufname_str =~ '^fugitive:[\\/][\\/]'
			let root = gdv#fugitive#root(item.bufnr)
			if root != ''
				return root
			endif
		endif
	endif
	" Try to extract root from quickfix title
	" For :Gclog, title might contain the git directory path
	let title = items.title
	if title != ''
		" Title format might be: "git -C <path> log ..." or similar
		" Try to extract path from title
		let path = matchstr(title, '-C\s\+\zs[^\s]\+')
		if path != ''
			let root = gdv#git#root(path)
			if root != ''
				return root
			endif
		endif
	endif
	" Fallback: try to find root from current context
	let root = gdv#git#root('')
	if root != ''
		return root
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" fugitive quickfix commit extractor 
"----------------------------------------------------------------------
function! gdv#fugitive#qf_commit() abort
	if &bt != 'quickfix'
		return ''
	endif
	" Get quickfix list item for current line
	let items = getqflist({'title':1, 'id':0})
	if !has_key(s:quickfix, items.id)
		let s:quickfix[items.id] = getqflist()
	endif
	let content = s:quickfix[items.id]
	let index = line('.') - 1
	if index < 0 || index >= len(content)
		return ''
	endif
	let item = content[index]
	if has_key(item, 'module') && strlen(item.module) >= 4
		let bid = gdv#fugitive#qf_entry(index)
		if bid >= 0
			let name = bufname(bid)
			let hash = gdv#fugitive#name2hash(name)
			if hash != ''
				return hash
			endif
		endif
		let root = gdv#fugitive#qf_root(index)
		if root != ''
			let full_hash = gdv#git#commit_hash(root, item.module)
			if full_hash != ''
				return full_hash
			endif
		endif
		" Fallback: use short hash directly
		return item.module
	endif
	return ''
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
		elseif &ft == 'GV'
			let git_dir = get(b:, 'git_dir', '')
			if get(b:, 'git_dir', '') == ''
				return gdv#git#root(getcwd())
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
		if exists('b:git_dir') && get(b:, 'git_dir', '') != ''
			let root = gdv#git#git2root(b:git_dir)
			if root != ''
				return root
			endif
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
			" Verify this is a valid git repository
			let git_path = root . '/.git'
			if isdirectory(git_path) || filereadable(git_path)
				return root
			endif
		endif
	elseif &bt == 'quickfix'
		" Try to get root from quickfix list item first (works even if buffer not open)
		let root = gdv#fugitive#qf_root(line('.') - 1)
		if root != ''
			return root
		endif
		" Fallback: try buffer-based method
		let bid = gdv#fugitive#qf_entry(line('.') - 1)
		if bid >= 0
			let root = gdv#fugitive#root(bid)
			if root != '' && isdirectory(root)
				return root
			endif
		endif
	elseif &bt == 'nowrite' && &ft == 'git'
		" For git log output windows, try to find git root from current context
		" This handles both normal repos and submodules
		let root = gdv#git#root('')
		if root != ''
			return root
		endif
		" Fallback: try to use b:git_dir if available
		if exists('b:git_dir') && get(b:, 'git_dir', '') != ''
			let root = gdv#git#git2root(b:git_dir)
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
		" Verify this is a valid git repository
		let git_path = root . '/.git'
		if isdirectory(git_path) || filereadable(git_path)
			let git.root = root
			return root
		endif
	endif
	" Final fallback: use gdv#git#root() which handles submodules
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
	let hash = gdv#fugitive#name2hash(name)
	return hash
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
	let git_dir = gdv#git#root2git(root)
	let git_dir = gdv#git#abspath(git_dir)
	let name .= git_dir . '//' . a:commit
	if a:fn != ''
		let name .= '/' . a:fn
	endif
	if s:windows
		let name = quickui#core#string_replace(name, '/', "\\")
	endif
	return name
endfunc


