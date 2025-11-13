"======================================================================
"
" git.vim - 
"
" Created by skywind on 2023/08/09
" Last Modified: 2023/08/09 16:04:27
"
"======================================================================


"----------------------------------------------------------------------
" get branch info
"----------------------------------------------------------------------
function! asclib#git#get_branch(where)
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
function! asclib#git#get_remote(where, name)
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
function! asclib#git#diff_tree(where, commit, parent)
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
function! asclib#git#commit_parents(where, commit)
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
function! asclib#git#commit_info(where, commit)
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


