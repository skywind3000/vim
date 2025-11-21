"======================================================================
"
" matcher.vim - 
"
" Created by skywind on 2025/11/22
" Last Modified: 2025/11/22 01:45:22
"
"======================================================================


"----------------------------------------------------------------------
" extract commit hash from git log output line
"----------------------------------------------------------------------
function! gdv#matcher#extract_git_log_hash() abort
	if &bt != 'nowrite' || &ft != 'git'
		return ''
	endif
	let line = getline('.')
	if line == ''
		return ''
	endif
	" Extract the first non-whitespace string (usually the commit hash)
	" This works for formats like:
	" - abc1234 commit message
	" - * abc1234 [branch] commit message
	" - |/ abc1234 commit message
	let hash = matchstr(line, '^\S\+')
	" Validate it looks like a commit hash (7-40 hex characters)
	if hash =~ '^[0-9a-f]\{7,40}$'
		return hash
	endif
	" Try to find hash in the line (for graph formats)
	" Look for 7-40 hex characters that might be a commit hash
	let hash = matchstr(line, '\<[0-9a-f]\{7,40}\>')
	if hash != ''
		return hash
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" extract [root, commit] from vim-plug buffer
"----------------------------------------------------------------------
function! gdv#matcher#extract_vimplug() abort
	if &bt != 'nofile' || &ft != 'vim-plug'
		return ['', '']
	endif
	let line = quickui#core#string_strip(getline('.'))
	if line == ''
		return ['', '']
	endif
	let lnum = line('.')
	let root = ''
	let name = ''
	while lnum >= 1
		let text = quickui#core#string_strip(getline(lnum))
		if text =~ '^-\s\+\S'
			let name = matchstr(text, '^-\s\+\zs\S\+\ze:')
			break
		endif
		let lnum = lnum - 1
	endwhile
	if name == ''
		return ['', '']
	elseif exists('g:plugs') == 0
		return ['', '']
	elseif !has_key(g:plugs, name)
		return ['', '']
	endif
	let item = g:plugs[name]
	let root = quickui#core#string_strip(get(item, 'dir', ''))
	if root == ''
		return ['', '']
	endif
	let root = gdv#git#abspath(root)
	if !isdirectory(root . '/.git')
		return ['', '']
	endif
	let line = quickui#core#string_strip(getline('.'))
	let hash = matchstr(line, '^\S\+')
	if hash =~ '^[0-9a-f]\{5,40}$'
		return hash
	endif
	let hash = matchstr(line, '\<[0-9a-f]\{5,40}\>')
	if hash != ''
		let hash = gdv#git#commit_hash(root, hash)
		if hash != ''
			return [root, hash]
		endif
	endif
	return ['', '']
endfunc


