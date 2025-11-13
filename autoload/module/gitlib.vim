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
function! module#gitlib#diffview(commit) abort
	let root = asclib#git#current_root()
	if root == ''
		return -1
	endif
	let key = root . '::' . a:commit
	let obj = module#gitlib#object(key)
	if !has_key(obj, 'diffview')
		let diff = asclib#git#commit_diff(root, a:commit)
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
		let hash = asclib#git#commit_hash(root, a:commit)
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
	exec 'Gtabedit ' . a:commit . ':' . item[3]
	exec 'Gvdiffsplit! ' . item[1] . ':' . item[3]
	return 0
endfunc



