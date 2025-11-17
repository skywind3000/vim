"======================================================================
"
" git.vim - 
"
" Created by skywind on 2025/11/16
" Last Modified: 2025/11/16 09:47:03
"
"======================================================================


"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win16') || has('win64') || has('win95')
let g:has_popup = exists('*popup_create') && v:version >= 800


"----------------------------------------------------------------------
" error message
"----------------------------------------------------------------------
function! gdv#git#errmsg(what)
	redraw
	echohl ErrorMsg
	echom 'ERROR: ' . a:what
	echohl None
endfunc


"----------------------------------------------------------------------
" detect quickui dependency
"----------------------------------------------------------------------
function! gdv#git#detect() abort
	if exists(':QuickUI') != 0
		return 1
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" system
"----------------------------------------------------------------------
function! gdv#git#system(cmd, cwd) abort
	let pwd = getcwd()
	if a:cwd != ''
		call quickui#core#chdir(a:cwd)
	endif
	let hr = quickui#utils#system(a:cmd)
	if a:cwd != ''
		call quickui#core#chdir(pwd)
	endif
	return hr
endfunc


"----------------------------------------------------------------------
" get current buffer git object
"----------------------------------------------------------------------
function! gdv#git#current_object() abort
	let name = '__gdv__'
	let bid = bufnr('%')
	let obj = getbufvar(bid, name)
	if type(obj) != 4
		call setbufvar(bid, name, {})
		let obj = getbufvar(bid, name)
	endif
	return obj
endfunc


"----------------------------------------------------------------------
" run git command and return output lines
"----------------------------------------------------------------------
function! gdv#git#run(args, cwd) abort
	return gdv#git#system('git ' . a:args, a:cwd)
endfunc


"----------------------------------------------------------------------
" get git root directory
"----------------------------------------------------------------------
function! gdv#git#root(where) abort
	let place = (a:where == '')? expand('%:p') : (a:where)
	let root = quickui#core#find_root(place, ['.git'], 1)
	if root == ''
		return ''
	endif
	let git_path = root . '/.git'
	" Check if .git is a directory (normal git repo)
	if isdirectory(git_path)
		return root
	endif
	" Check if .git is a file (git submodule)
	if filereadable(git_path)
		" Read the .git file to get the gitdir path
		try
			let lines = readfile(git_path)
			if len(lines) > 0
				let gitdir_line = quickui#core#string_strip(lines[0])
				" Check if it's a gitdir reference (format: "gitdir: <path>")
				if gitdir_line =~ '^gitdir:\s*'
					let gitdir_path = matchstr(gitdir_line, '^gitdir:\s*\zs.*$')
					let gitdir_path = quickui#core#string_strip(gitdir_path)
					" Convert relative path to absolute path
					" Git submodule .git files use relative paths like "../../../../.git/modules/..."
					if gitdir_path !~ '^[\\/]\|^\a:'
						" Relative path, resolve it relative to root
						" Use fnamemodify to properly resolve the path
						let gitdir_path = fnamemodify(root . '/' . gitdir_path, ':p')
						" Remove trailing path separator if present
						let gitdir_path = substitute(gitdir_path, '[\\/]$', '', '')
					endif
					" Normalize path separators for Windows
					if s:windows
						let gitdir_path = substitute(gitdir_path, '/', '\', 'g')
					endif
					" Verify the gitdir exists and is a directory
					if isdirectory(gitdir_path)
						" This is a valid git submodule, return the work tree root
						" Git commands should be run in the work tree (root), not in gitdir
						return root
					endif
				endif
			endif
		catch
			" If reading fails, it's not a valid git submodule
		endtry
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get branch info
"----------------------------------------------------------------------
function! gdv#git#get_branch(where) abort
	let root = gdv#git#root(a:where)
	if root == ''
		return ''
	endif
	let hr = gdv#git#run('branch', root)
	for text in split(hr, '\n')
		let text = quickui#core#string_strip(text)
		let name = matchstr(text, '^\*\s*\zs\S\+\ze\s*$')
		let name = quickui#core#string_strip(name)
		if name != ''
			return name
		endif
	endfor
	return ''
endfunc


"----------------------------------------------------------------------
" git diff-tree --no-commit-id --name-status -r <commit-hash>
"----------------------------------------------------------------------
function! gdv#git#diff_tree(where, commit, parent) abort
	let root = gdv#git#root(a:where)
	if root == ''
		return []
	endif
	let cmd = 'diff-tree --no-commit-id --name-status -r '
	if a:parent == ''
		let cmd .= a:commit
	else
		let cmd .= a:parent . ' ' . a:commit
	endif
	let hr = gdv#git#run(cmd, root)
	let result = []
	for line in split(hr, '\n')
		let line = quickui#core#string_strip(line)
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
function! gdv#git#commit_parents(where, commit) abort
	let root = gdv#git#root(a:where)
	if root == ''
		return []
	endif
	let cmd = 'show -s --pretty=%P ' . a:commit
	let hr = gdv#git#run(cmd, root)
	let result = []
	for line in split(hr, '\n')
		let line = quickui#core#string_strip(line)
		if line == ''
			continue
		endif
		for parent in split(line, '\s\+')
			let parent = quickui#core#string_strip(parent)
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
function! gdv#git#commit_info(where, commit) abort
	let root = gdv#git#root(a:where)
	if root == ''
		return {}
	endif
	let cmd = 'log --pretty=format:"%H %ad %s" --date=short -1 ' . a:commit
	let hr = gdv#git#run(cmd, root)
	let result = {}
	for line in split(hr, '\n')
		let line = quickui#core#string_strip(line)
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
function! gdv#git#commit_hash(where, commit) abort
	let root = gdv#git#root(a:where)
	if root == ''
		return ''
	endif
	let cmd = 'rev-parse ' . a:commit
	let hr = gdv#git#run(cmd, root)
	let hash = quickui#core#string_strip(hr)
	if hash == '' || g:quickui#utils#shell_error != 0
		return ''
	endif
	return hash
endfunc


"----------------------------------------------------------------------
" get commit diff info 
"----------------------------------------------------------------------
function! gdv#git#commit_diff(where, commit, ...) abort
	let root = gdv#git#root(a:where)
	if root == ''
		return []
	endif
	if a:0 > 0
		let parents = a:1
	else
		let parents = gdv#git#commit_parents(a:where, a:commit)
	endif
	let result = []
	let index = 1
	for parent in parents
		for item in gdv#git#diff_tree(a:where, a:commit, parent)
			call add(result, [index, parent, item[0], item[1]])
		endfor
		let index += 1
	endfor
	return result
endfunc


"----------------------------------------------------------------------
" git show -s --format="%H %ad %P" --date=short <commit-hash>
"----------------------------------------------------------------------
function! gdv#git#commit_info(where, commit) abort
	let root = gdv#git#root(a:where)
	if root == ''
		return {}
	endif
	let cmd = 'show -s --format="%H %ad %P" --date=short ' . a:commit
	let hr = gdv#git#run(cmd, root)
	let result = {}
	for line in split(hr, '\n')
		let line = quickui#core#string_strip(line)
		if line == ''
			continue
		endif
		let hash = matchstr(line, '^\S\+')
		let rest = matchstr(line, '^\S\+\s\+\zs.*$')
		let date = matchstr(rest, '^\S\+')
		let parents_str = matchstr(rest, '^\S\+\s\+\zs.*$')
		let parents = []
		for parent in split(parents_str, '\s\+')
			let parent = quickui#core#string_strip(parent)
			if parent != ''
				call add(parents, parent)
			endif
		endfor
		if date == '' || hash == ''
			continue
		endif
		let result = {'hash': hash, 'date': date, 'parents': parents}
	endfor
	return result
endfunc



