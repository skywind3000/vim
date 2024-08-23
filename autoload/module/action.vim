"======================================================================
"
" action.vim - menu / navigator actions
"
" Created by skywind on 2024/02/22
" Last Modified: 2024/02/22 22:28:20
"
"======================================================================


"----------------------------------------------------------------------
" ask input for grep
"----------------------------------------------------------------------
function! module#action#grep() abort
	let p = asyncrun#get_root('%')
	let d = p
	if len(p) > (&columns * 2) / 3 || len(p) > 60
		let d = asclib#path#shorten(p, 60)
	endif
	let t = 'Find word in (' . d . '): '
	let t = asclib#ui#input(t, expand('<cword>'), 'grep')
	let t = asclib#string#strip(t)
	redraw
	if strlen(t) > 0
		silent exec "GrepCode! ".fnameescape(t)
		call asclib#compat#quickfix_title('- searching "'. t. '"')
	endif
endfunc


"----------------------------------------------------------------------
" run shell commands on current project root
"----------------------------------------------------------------------
function! module#action#shell() abort
	let p = asclib#path#current_root()
	if len(p) > (&columns * 2) / 3 || len(p) > 60
		let p = asclib#path#shorten(p)
	endif
	let prev = get(s:, 'previous_cmd', '')
	let t = 'Shell cmd in current project (' . p . '): '
	let t = asclib#ui#input(t, prev, 'pshell')
	let t = asclib#string#strip(t)
	if t != ''
		let opts = {}
		let opts.mode = 'quickfix'
		let opts.raw = 1
		let opts.cwd = '<root>'
		let s:previous_cmd = t
		call asyncrun#run('', opts, t)
	endif
endfunc


"----------------------------------------------------------------------
" toggle: tagbar/vista/aerial/outline
"----------------------------------------------------------------------
function! module#action#tagbar() abort
	if exists(':Vista') == 2
		exec ':Vista'
	elseif exists(':AerialToggle') == 2
		exec ':AerialToggle'
	elseif exists(':Outline') == 2
		exec ':Outline'
	elseif exists(':Tagbar') == 2
		exec ':Tagbar'
	endif
endfunc


"----------------------------------------------------------------------
" easymotion
"----------------------------------------------------------------------
function! module#action#easymotion(what) abort
	if a:what != ''
		stopinsert
		call feedkeys("\<Plug>(easymotion-" . a:what . ")", '')
	endif
endfunc



"----------------------------------------------------------------------
" ask input for cppman
"----------------------------------------------------------------------
function! module#action#cppman() abort
	let t = 'Find word in Cppman:'
	let t = asclib#ui#input(t, module#cpp#fetch_cword(), 'cppman')
	let t = asclib#string#strip(t)
	redraw
	if t != ''
		exec 'Cppman ' . t
	endif
endfunc


"----------------------------------------------------------------------
" apply template
"----------------------------------------------------------------------
function! module#action#template_select(ft) abort
	let items = template#list_names(a:ft)
	let names = keys(items)
	call sort(names)
	let items = []
	for name in names
		call add(items, printf("%s/%s", a:ft, name))
	endfor
	let msg = printf('Apply Template (for %s): ', a:ft)
	let index = asclib#ui#select(msg, items)
	if index > 0
		let name = names[index - 1]
		exec printf("Template %s/%s", a:ft, name)
		call asclib#common#message('Template applied:', name)
	endif
endfunc



"----------------------------------------------------------------------
" select escript
"----------------------------------------------------------------------
function! module#action#escript_select() abort
	let items = escript#list()
	let names = keys(items)
	call sort(names)
	let msg = 'Select Script: '
	let index = asclib#ui#select(msg, names)
	if index > 0
		let name = names[index - 1]
		let script = items[name]
		exec printf('EScript %s', name)
	endif
endfunc


