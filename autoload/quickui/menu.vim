"======================================================================
"
" menu.vim - main menu bar
"
" Created by skywind on 2019/12/24
" Last Modified: 2019/12/24 10:41:13
"
"======================================================================

" vim: set noet fenc=utf-8 ff=unix sts=4 sw=4 ts=4 :


"----------------------------------------------------------------------
" global
"----------------------------------------------------------------------
let s:menus = {}


"----------------------------------------------------------------------
" register entry: (section='File', entry='&Save', command='w')
"----------------------------------------------------------------------
function! quickui#menu#register(section, entry, command, help)
	if !has_key(s:menus, a:section)
		let index = 0
		let maximum = 0
		for name in keys(s:menus)
			let w = s:menus[name].weight
			let maximum = (index == 0)? w : ((maximum < w)? w : maximum)
			let index += 1
		endfor
		let s:menus[a:section] = {'name':a:section, 'weight':0, 'items':[]}
		let s:menus[a:section].weight = maximum + 100
	endif
	let menu = s:menus[a:section]
	let item = {'name':a:entry, 'command':a:command, 'help':a:help}
	let menu.items += [item]
endfunc


"----------------------------------------------------------------------
" remove entry:
"----------------------------------------------------------------------
function! quickui#menu#remove(section, index)
	if !has_key(s:menus, a:section)
		return -1
	endif
	let menu = s:menus[a:section]
	if type(a:index) == v:t_number
		let index = (a:index < 0)? (len(menu.items) + a:index) : a:index
		if index < 0 || index >= len(menu.items)
			return -1
		endif
		call remove(menu.items, index)
	elseif type(a:index) == v:t_string
		if a:index ==# '*'
			menu.items = []
		else
			let index = -1
			for ii in range(len(menu.items))
				if menu.items[ii].name ==# a:index
					let index = ii
					break
				endif
			endfor
			if index < 0 
				return -1
			endif
			call remove(menu.items, index)
		endif
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" return items key 
"----------------------------------------------------------------------
function! quickui#menu#section(section)
	return get(s:menus, a:section, v:null)
endfunc


"----------------------------------------------------------------------
" install a how section
"----------------------------------------------------------------------
function! quickui#menu#install(section, content)
	if type(a:content) == v:t_list
		for item in a:content
			if type(item) == v:t_dict
				call quickui#menu#register(a:section, item.name, item.command)
			elseif type(item) == v:t_list
				let help = (len(item) >= 3)? item[2] : ''
				call quickui#menu#register(a:section, item[0], item[1], help)
			endif
		endfor
	elseif type(a:content) == v:t_dict
		for name in keys(a:content)
			let cmd = a:content[name]
			call quickui#menu#register(a:section, name, cmd, '')
		endfor
	endif
endfunc


"----------------------------------------------------------------------
" change weight
"----------------------------------------------------------------------
function! quickui#menu#change_weight(section, weight)
	if has_key(s:menus, a:section)
		let s:menus[a:section].weight = a:weight
	endif
endfunc


"----------------------------------------------------------------------
" compare section
"----------------------------------------------------------------------
function! s:section_compare(s1, s2)
	if a:s1[0] == a:s2[0]
		return 0
	else
		return (a:s1[0] > a:s2[0])? 1 : -1
	endif
endfunc


"----------------------------------------------------------------------
" get section
"----------------------------------------------------------------------
function! quickui#menu#available()
	let menus = []
	for name in keys(s:menus)
		let menu = s:menus[name]
		if len(menu.items) > 0
			let menus += [[menu.weight, menu.name]]
		endif
	endfor
	call sort(menus, 's:section_compare')
	let result = []
	for obj in menus
		let result += [obj[1]]
	endfor
	return result
endfunc


"----------------------------------------------------------------------
" parse
"----------------------------------------------------------------------
function! quickui#menu#parse(size)
	let inst = {}
	let objs = []
	let inst.objs = objs
	for section in quickui#menu#availabe()
		let menu = s:menus[section]
		let items = {}
	endfor
endfunc


"----------------------------------------------------------------------
" testing suit
"----------------------------------------------------------------------
if 1
	let s:menus = {}
	call quickui#menu#install('&Help', [
				\ [ '&Content', 'echo 4' ],
				\ [ '&About', 'echo 5' ],
				\ ])
	call quickui#menu#install('&File', [
				\ [ '&Open', 'echo 1' ],
				\ [ '&Save', 'echo 2' ],
				\ [ '&Close', 'echo 3' ],
				\ ])
	call quickui#menu#install('&Edit', [
				\ [ '&Copy', 'echo 1', 'help1' ],
				\ [ '&Paste', 'echo 2', 'help2' ],
				\ [ '&Find', 'echo 3', 'help3' ],
				\ ])
	call quickui#menu#install('&Window', [])
	call quickui#menu#change_weight('&Help', 1000)
	echo quickui#menu#available()
endif



