"======================================================================
"
" git.vim - 
"
" Created by skywind on 2023/08/09
" Last Modified: 2023/08/09 16:04:27
"
"======================================================================


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')
let s:quickfix = {}


"----------------------------------------------------------------------
" get git object for current buffer
"----------------------------------------------------------------------
function! asclib#git#current_object() abort
	return asclib#buffer#variable('%', 'git', {})
endfunc


"----------------------------------------------------------------------
" get git root for fugitive buffer
"----------------------------------------------------------------------
function! asclib#git#fugitive_root(bid) abort
	let name = bufname(a:bid)
	if name !~ '^fugitive:[\\/][\\/]'
		return ''
	endif
	let path = getbufvar(a:bid, 'git_dir', '')
	if path != '' && path =~ '[\\/]\.git$'
		let path = substitute(path, '[\\/]\.git$', '', '')
		if isdirectory(path)
			return asclib#path#normalize(path)
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
		return asclib#path#normalize(path)
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get fugitive quickfix entry buffer id
"----------------------------------------------------------------------
function! asclib#git#fugitive_qf_entry(index) abort
	let items = getqflist({'title':1, 'id':0})
	let title = asclib#string#strip(items.title)
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
function! asclib#git#nonfile_root() abort
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
			return b:git_dir
		endif
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get git root for current buffer
"----------------------------------------------------------------------
function! asclib#git#current_root() abort
	if &bt == 'nofile'
		let root = asclib#git#nonfile_root()
		if root != '' && isdirectory(root)
			return root
		endif
	elseif &bt == 'quickfix'
		let bid = asclib#git#fugitive_qf_entry(line('.') - 1)
		if bid >= 0
			let root = asclib#git#fugitive_root(bid)
			if root != '' && isdirectory(root)
				return root
			endif
		endif
	endif
	let git = asclib#git#current_object()
	if has_key(git, 'root')
		return git.root
	endif
	let root = asclib#git#fugitive_root('%')
	if root != '' && isdirectory(root)
		let git.root = root
		return root
	endif
	let root = asclib#vcs#croot('', 'git')
	if root != '' && isdirectory(root)
		let git.root = root
		return root
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get branch info
"----------------------------------------------------------------------
function! asclib#git#get_branch(where) abort
	let root = asclib#vcs#croot(a:where, 'git')
	if root == ''
		return ''
	endif
	let hr = asclib#vcs#git('branch', root)
	for text in split(hr, '\n')
		let text = asclib#string#strip(text)
		let name = matchstr(text, '^\*\s*\zs\S\+\ze\s*$')
		let name = asclib#string#strip(name)
		if name != ''
			return name
		endif
	endfor
	return ''
endfunc


"----------------------------------------------------------------------
" get remote url
"----------------------------------------------------------------------
function! asclib#git#get_remote(where, name) abort
	let root = asclib#vcs#croot(a:where, 'git')
	if root == ''
		return ''
	endif
	let hr = asclib#vcs#git('remote get-url ' . a:name, root)
	return (g:asclib#core#shell_error == 0)? asclib#string#strip(hr) : ''
endfunc


"----------------------------------------------------------------------
" git diff-tree --no-commit-id --name-status -r <commit-hash>
"----------------------------------------------------------------------
function! asclib#git#diff_tree(where, commit, parent) abort
	let root = asclib#vcs#croot(a:where, 'git')
	if root == ''
		return []
	endif
	let cmd = 'diff-tree --no-commit-id --name-status -r '
	if a:parent == ''
		let cmd .= a:commit
	else
		let cmd .= a:parent . ' ' . a:commit
	endif
	let hr = asclib#vcs#git(cmd, root)
	let result = []
	for line in split(hr, '\n')
		let line = asclib#string#strip(line)
		if line == ''
			continue
		endif
		let status = matchstr(line, '^\S\+')
		let filename = matchstr(line, '^\S\+\s\+\zs.*$')
		call add(result, [status, filename])
	endfor
	return result
endfunc


"----------------------------------------------------------------------
" git show -s --pretty=%P <commit-hash>
"----------------------------------------------------------------------
function! asclib#git#commit_parents(where, commit) abort
	let root = asclib#vcs#croot(a:where, 'git')
	if root == ''
		return []
	endif
	let cmd = 'show -s --pretty=%P ' . a:commit
	let hr = asclib#vcs#git(cmd, root)
	let result = []
	for line in split(hr, '\n')
		let line = asclib#string#strip(line)
		if line == ''
			continue
		endif
		for parent in split(line, '\s\+')
			let parent = asclib#string#strip(parent)
			if parent == ''
				continue
			endif
			call add(result, parent)
		endfor
	endfor
	return result
endfunc


"----------------------------------------------------------------------
" git log --pretty=format:"%H %ad %s" --date=short -1 <commit-hash>
"----------------------------------------------------------------------
function! asclib#git#commit_info(where, commit) abort
	let root = asclib#vcs#croot(a:where, 'git')
	if root == ''
		return {}
	endif
	let cmd = 'log --pretty=format:"%H %ad %s" --date=short -1 ' . a:commit
	let hr = asclib#vcs#git(cmd, root)
	let result = {}
	for line in split(hr, '\n')
		let line = asclib#string#strip(line)
		if line == ''
			continue
		endif
		let hash = matchstr(line, '^\S\+')
		let rest = matchstr(line, '^\S\+\s\+\zs.*$')
		let date = matchstr(rest, '^\S\+')
		let message = matchstr(rest, '^\S\+\s\+\zs.*$')
		if date == '' || hash == ''
			continue
		endif
		let result = {'hash': hash, 'date': date, 'message': message}
	endfor
	return result
endfunc


"----------------------------------------------------------------------
" git rev-parse <commit-hash> 
"----------------------------------------------------------------------
function! asclib#git#commit_hash(where, commit) abort
	let root = asclib#vcs#croot(a:where, 'git')
	if root == ''
		return ''
	endif
	let cmd = 'rev-parse ' . a:commit
	let hr = asclib#vcs#git(cmd, root)
	let hash = asclib#string#strip(hr)
	if hash == '' || g:asclib#core#shell_error != 0
		return ''
	endif
	return hash
endfunc


"----------------------------------------------------------------------
" get commit diff info 
"----------------------------------------------------------------------
function! asclib#git#commit_diff(where, commit) abort
	let root = asclib#vcs#croot(a:where, 'git')
	if root == ''
		return []
	endif
	let parents = asclib#git#commit_parents(a:where, a:commit)
	let result = []
	let index = 1
	for parent in parents
		for item in asclib#git#diff_tree(a:where, a:commit, parent)
			call add(result, [index, parent, item[0], item[1]])
		endfor
		let index += 1
	endfor
	return result
endfunc


"----------------------------------------------------------------------
" get commit hash for fugitive buffer
"----------------------------------------------------------------------
function! asclib#git#fugitive_commit(bid)
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
function! asclib#git#fugitive_make(root, commit, fn) abort
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
		let name = asclib#string#replace(name, '/', "\\")
	endif
	return name
endfunc


