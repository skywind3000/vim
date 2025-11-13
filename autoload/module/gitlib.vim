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
let s:cursor_pos = {}


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#gitlib#hello() abort
	return 'Hello from gitlib module!'
endfunc



"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#gitlib#sidebyside(commit) abort
	let root = asclib#git#current_root()
	if root == ''
		return -1
	endif
	let diff = asclib#git#commit_diff(root, a:commit)
	if len(diff) == 0
		return 0
	endif
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
	let opts = {'title': 'Select to Compare (ParentId/Parent/Status/Filename)'}
	let key = root . '::' . a:commit
	let index = quickui#tools#clever_inputlist(key, content, opts)
	if index < 0
		return 0
	endif
	let item = diff[index]
	exec 'Gtabedit ' . a:commit . ':' . item[3]
	exec 'Gvdiffsplit! ' . item[1] . ':' . item[3]
	return 0
endfunc



