"======================================================================
"
" gitlib.vim - 
"
" Created by skywind on 2025/11/13
" Last Modified: 2025/11/13 17:23:48
"
"======================================================================



"----------------------------------------------------------------------
" interal
"----------------------------------------------------------------------
let s:object = {}


"----------------------------------------------------------------------
" get object
"----------------------------------------------------------------------
function! module#gitlib#object(name) abort
	if !has_key(s:object, a:name)
		let s:object[a:name] = {}
	endif
	return s:object[a:name]
endfunc


"----------------------------------------------------------------------
" diff view side-by-side
"----------------------------------------------------------------------
function! module#gitlib#diffview(where, commit) abort
	let root = asclib#vcs#croot(a:where, 'git')
	if root == ''
		return -1
	endif
	let commit = a:commit
	if commit == ''
		return -1
	endif
	let key = root . '::' . commit
	let obj = module#gitlib#object(key)
	if !has_key(obj, 'info')
		let info = asclib#git#commit_info(root, commit)
		let obj.info = info
	endif
	let info = obj.info
	if !has_key(obj, 'diffview')
		" unsilent echom printf('root(%s), commit(%s)', root, commit)
		let diff = asclib#git#commit_diff(root, commit, info.parents)
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
	let name = asclib#git#fugitive_make(root, hash, item[3])
	exec printf('tabe %s', fnameescape(name))
	exec printf('Gvdiffsplit! %s:%s', item[1], item[3])
	return 0
endfunc


"----------------------------------------------------------------------
" fugitive quickfix commit extractor
"----------------------------------------------------------------------
function! module#gitlib#fugitive_qf_commit() abort
	if &bt != 'quickfix'
		return ''
	endif
	let bid = asclib#git#fugitive_qf_entry(line('.') - 1)
	if bid < 0
		return ''
	endif
	let hash = asclib#git#fugitive_commit(bid)
	return hash
endfunc


"----------------------------------------------------------------------
" floggraph commit reader
"----------------------------------------------------------------------
function! module#gitlib#flog_commit_line(lnum) abort
	if &bt != 'nofile'
		return ''
	elseif &ft != 'floggraph' && &ft != 'GV'
		return ''
	endif
	let text = getline(a:lnum)
	let pos = stridx(text, '*')
	if pos < 0
		return ''
	endif
	let rest = strpart(text, pos + 1)
	let hash = ''
	if &ft == 'floggraph'
		let p1 = stridx(rest, '[')
		if p1 < 0
			return ''
		endif
		let p2 = stridx(rest, ']')
		if p2 < 0 || p2 <= p1
			return ''
		endif
		let hash = strpart(rest, p1 + 1, p2 - p1 - 1)
	else
		let begin = '^[^0-9]*[0-9]\{4}-[0-9]\{2}-[0-9]\{2}\s\+'
		let hash = matchstr(rest, begin . '\zs[0-9a-f]\{5,40}\ze\s')
	endif
	return hash
endfunc


"----------------------------------------------------------------------
" floggraph commit extractor
"----------------------------------------------------------------------
function! module#gitlib#flog_commit_extract() abort
	if &bt != 'nofile'
		return ''
	elseif &ft != 'floggraph' && &ft != 'GV'
		return ''
	endif
	let lnum = line('.')
	while lnum > 0
		let hash = module#gitlib#flog_commit_line(lnum)
		if hash != ''
			return hash
		endif
		let lnum -= 1
	endwhile
	return ''
endfunc


"----------------------------------------------------------------------
" clever diff view
"----------------------------------------------------------------------
function! module#gitlib#clever_diffview(commit) abort
	let root = asclib#git#current_root()
	let commit = a:commit
	if commit == ''
		let commit = asclib#git#fugitive_commit('%')
	endif
	if commit == ''
		if &bt == 'quickfix'
			let commit = module#gitlib#fugitive_qf_commit()
		elseif &bt == 'nofile'
			let commit = module#gitlib#flog_commit_extract()
		endif
	endif
	if commit == ''
		call asclib#core#errmsg('No commit specified for diff view.')
		return 0
	endif
	call module#gitlib#diffview(root, commit)
	return 0
endfunc


"----------------------------------------------------------------------
" stage diff file
"----------------------------------------------------------------------
function! module#gitlib#stage_diffview(where, fname, staged) abort
	let root = asclib#git#current_root()
	if a:where != '' && a:where != '%'
		let root = asclib#vcs#croot(a:where, 'git')
	endif
	if root == ''
		return -1
	endif
	if a:staged == 0
		let srcname = asclib#path#join(root, a:fname)
	else
		let srcname = asclib#git#fugitive_make(root, '0', a:fname)
	endif
	exec printf('tabe %s', fnameescape(srcname))
	exec printf('Gvdiffsplit! %s:%s', 'HEAD', a:fname)
endfunc


"----------------------------------------------------------------------
" clever stage diff on a fugitive status buffer
"----------------------------------------------------------------------
function! module#gitlib#clever_stage_diff() abort
	if &bt != 'nowrite'
		call asclib#core#errmsg('Not a fugitive status buffer.')
		return -1
	elseif &ft != 'fugitive'
		call asclib#core#errmsg('Not a fugitive status buffer.')
		return -1
	endif
	let lnum = line('.')
	let text = getline(lnum)
	if text !~ '^\S\s\+\S\+'
		call asclib#core#errmsg('Not on a valid file line.')
		return -1
	endif
	let status = strpart(text, 0, 1)
	let fname = asclib#string#strip(strpart(text, 2))
	if fname == ''
		call asclib#core#errmsg('Cannot extract filename.')
		return -1
	endif
	if status =~ '[\+\- ]'
		call asclib#core#errmsg('Cannot extract filename.')
		return -1
	endif
	if status !~ '\a'
		call asclib#core#errmsg('File is untracked or ignored')
		return -1
	endif
	let mode = ''
	while lnum > 0
		let curline = getline(lnum)
		if curline =~ '^\a\a\+\s\+('
			let mode = tolower(matchstr(curline, '^\a\S\+'))
			break
		endif
		let lnum -= 1
	endwhile
	if mode == ''
		call asclib#core#errmsg('Cannot determine staging mode.')
		return -1
	endif
	if mode == 'untracked'
		call asclib#core#errmsg('File is untracked, no diff available.')
		return -1
	endif
	call module#gitlib#stage_diffview('', fname, mode == 'staged')
endfunc


