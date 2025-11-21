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

