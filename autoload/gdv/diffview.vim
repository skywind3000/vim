"======================================================================
"
" diffview.vim - 
"
" Created by skywind on 2025/11/16
" Last Modified: 2025/11/16 12:58:32
"
"======================================================================


"----------------------------------------------------------------------
" interal
"----------------------------------------------------------------------
let s:object = {}


"----------------------------------------------------------------------
" get object
"----------------------------------------------------------------------
function! gdv#diffview#object(name) abort
	if !has_key(s:object, a:name)
		let s:object[a:name] = {}
	endif
	return s:object[a:name]
endfunc


"----------------------------------------------------------------------
" diff view side-by-side
"----------------------------------------------------------------------
function! gdv#diffview#open(where, commit, side) abort
	let root = gdv#git#root(a:where)
	if root == ''
		return -1
	endif
	let commit = a:commit
	if commit == ''
		return -1
	endif
	let key = root . '::' . commit
	let obj = gdv#diffview#object(key)
	if !has_key(obj, 'info')
		let info = gdv#git#commit_info(root, commit)
		let obj.info = info
	endif
	let info = obj.info
	if !has_key(obj, 'diffview')
		" unsilent echom printf('root(%s), commit(%s)', root, commit)
		let diff = gdv#git#commit_diff(root, commit, info.parents)
		let obj.diffview = diff
	endif
	let diff = obj.diffview
	if len(diff) == 0
		return 0
	endif
	if !has_key(obj, 'content')
		let content = []
		for item in diff
			let pid = item[0]
			let hash = item[1]
			let status = item[2]
			let filename = item[3]
			let short = strpart(hash, 0, 7)
			let text = printf("%s\t%s\t%s\t%s", pid, short, status, filename)
			call add(content, text)
		endfor
		let obj.content = content
	endif
	let content = obj.content
	let hash = info.hash
	let short = strpart(hash, 0, 7)
	let opts = {}
	let opts.title = 'Commit Diff View ('. short . ') ' . info.date
	let opts.hide_system_cursor = 1
	let index = quickui#tools#clever_inputlist(key, content, opts)
	if index < 0
		return 0
	endif
	let item = diff[index]
	let name = gdv#fugitive#make(root, hash, item[3])
	if a:side == 0
		exec printf('tabe %s', fnameescape(name))
	else
		exec printf('-1tabe %s', fnameescape(name))
	endif
	exec printf('Gvdiffsplit! %s:%s', item[1], item[3])
	return 0
endfunc


"----------------------------------------------------------------------
" extract commit hash from git log output line
"----------------------------------------------------------------------
function! gdv#diffview#extract_git_log_hash() abort
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
" start diff view
"----------------------------------------------------------------------
function! gdv#diffview#start(commit) abort
	let root = ''
	let commit = a:commit
	" For quickfix windows, get both root and commit from the same quickfix item
	" This ensures they match (important for submodules)
	if &bt == 'quickfix'
		if commit == ''
			let commit = gdv#fugitive#qf_commit()
		endif
		if commit != ''
			" Get root from the same quickfix item to ensure they match
			let root = gdv#fugitive#qf_root(line('.') - 1)
		endif
		if root == ''
			" Fallback to current_root() if qf_root() fails
			let root = gdv#fugitive#current_root()
		endif
	else
		" For other window types, use the normal flow
		let root = gdv#fugitive#current_root()
		if commit == ''
			if &bt == 'nowrite' && &ft == 'fugitive'
				return gdv#stage#open_diff()
			endif
			let commit = gdv#fugitive#commit_hash('%')
		endif
		if commit == ''
			if &bt == 'nofile'
				let commit = gdv#flog#commit_extract()
			elseif &bt == 'nowrite' && &ft == 'git'
				" Support for fugitive git log output windows
				let commit = gdv#diffview#extract_git_log_hash()
			endif
		endif
	endif
	if commit == ''
		call gdv#git#errmsg('No commit specified for diff view.')
		return 0
	endif
	if root == ''
		call gdv#git#errmsg('No git repository found.')
		return 0
	endif
	let right = get(g:, 'gdv_tab_right', 0)
	call gdv#diffview#open(root, commit, right? 0 : 1)
	return 0
endfunc



