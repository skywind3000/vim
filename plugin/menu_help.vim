"======================================================================
"
" menu_help.vim - menu functions
"
" Created by skywind on 2019/12/30
" Last Modified: 2019/12/30 14:47:29
"
"======================================================================

function! MenuHelp_FormatJson()
	exec "%!python -m json.tool"
endfunc

function! MenuHelp_Fscope(scope)
	exec "GscopeFind ". a:scope . " " . fnameescape(expand('<cword>'))
endfunc

function! MenuHelp_Gscope(what)
	let p = asyncrun#get_root('%')
	let t = ''
	let m = {}
	let m["s"] = "string symbol"
	let m['g'] = 'definition'
	let m['d'] = 'functions called by this'
	let m['c'] = 'functions calling this'
	let m['t'] = 'string'
	let m['e'] = 'egrep pattern'
	let m['f'] = 'file'
	let m['i'] = 'files #including this file'
	let m['a'] = 'places where this symbol is assigned'
	let m['z'] = 'ctags database'
	if a:what == 'f' || a:what == 'i'
		" let t = expand('<cfile>')
	endif
	echohl Type
	call inputsave()
	let t = input('Find '.m[a:what].' in (' . p . '): ', t)
	call inputrestore()
	echohl None
	redraw | echo "" | redraw
	if t == ''
		return 0
	endif
	exec 'GscopeFind '. a:what. ' ' . fnameescape(t)
endfunc

function! MenuHelp_GrepCode()
	let p = asyncrun#get_root('%')
	echohl Type
	call inputsave()
	let t = input('Find word in ('. p.'): ', '')
	call inputrestore()
	echohl None
	redraw | echo "" | redraw
	if strlen(t) > 0
		silent exec "GrepCode! ".fnameescape(t)
		call asclib#quickfix_title('- searching "'. t. '"')
	endif
endfunc

function! MenuHelp_Proxy(enable)
	let $HTTP_PROXY = (a:enable)? 'socks5://localhost:1080' : ''
	let $HTTPS_PROXY = $HTTP_PROXY
	let $ALL_PROXY = $HTTP_PROXY
endfunc

function! MenuHelp_TaskList()
	let keymaps = '123456789abcdefimnopqrstuvwxyz'
	let items = asynctasks#list('')
	let rows = []
	let size = strlen(keymaps)
	let index = 0
	for item in items
		if item.name =~ '^\.'
			continue
		endif
		let cmd = strpart(item.command, 0, (&columns * 60) / 100)
		let key = (index >= size)? ' ' : strpart(keymaps, index, 1)
		let text = "[" . ((key != ' ')? ('&' . key) : ' ') . "]\t"
		let text .= item.name . "\t[" . item.scope . "]\t" . cmd
		let rows += [[text, 'AsyncTask ' . fnameescape(item.name)]]
		let index += 1
	endfor
	let opts = {}
	let opts.title = 'Task List'
	" let opts.bordercolor = 'QuickTitle'
	call quickui#tools#clever_listbox('tasks', rows, opts)
endfunc



