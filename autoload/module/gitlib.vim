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
	if !has_key(obj, 'diffview')
		" unsilent echom printf('root(%s), commit(%s)', root, commit)
		let diff = asclib#git#commit_diff(root, commit)
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
	if !has_key(obj, 'hash')
		let hash = asclib#git#commit_hash(root, commit)
		let obj.hash = hash
	endif
	let hash = obj.hash
	let short = strpart(hash, 0, 7)
	let opts = {'title': 'Commit Diff View ('. short . ')'}
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
		endif
	endif
	if commit == ''
		call asclib#core#errmsg('No commit specified for diff view.')
		return 0
	endif
	call module#gitlib#diffview(root, commit)
	return 0
endfunc


