"======================================================================
"
" menu_help.vim - menu functions
"
" Created by skywind on 2019/12/30
" Last Modified: 2019/12/30 14:47:29
"
"======================================================================

let s:keymaps = '123456789abcdefimnopqrstuvwxyz'

function! MenuHelp_PlugEvent(event)
	exec "normal \<plug>(" . a:event . ")"
endfunc

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
	let keymaps = '123456789abcdefimopqrstuvwxyz'
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

function! MenuHelp_WinHelp(help)
	let t = expand('<cword>')
	echohl Type
	call inputsave()
	let t = input('Search help of ('. fnamemodify(a:help, ':t').'): ', t)
	call inputrestore()
	echohl None
	redraw | echo "" | redraw
	if t == ''
		return 0
	endif
	let extname = tolower(fnamemodify(a:help, ':e'))
	if extname == 'hlp'
		call asclib#open_win32_help(a:help, t)
	elseif extname == 'chm'
		call asclib#open_win32_chm(a:help, t)
	else
		echo "unknow filetype"
	endif
endfunc

function! MenuHelp_HelpList(name, content)
	let content = []
	let index = 0
	for item in a:content
		let key = (index < len(s:keymaps))? strpart(s:keymaps, index, 1) : ''
		let text = '[' . ((key == '')? ' ' : ('&' . key)) . "]\t"
		let text = text . item[0] . "\t" . item[1]
		let cmd = 'call MenuHelp_WinHelp("' . item[1] . '")'
		let content += [[text, cmd]]
		let index += 1
	endfor
	let opts = {'title': 'Help Content', 'index':0, 'close':'button'}
	call quickui#tools#clever_listbox(a:name, content, opts)
endfunc

function! MenuHelp_SplitLine()
	echohl Type
	call inputsave()
	let t = input('Enter maximum line width: ')
	call inputrestore()
	redraw | echo "" | redraw
	if t == ''
		return 0
	endif
	let width = str2nr(t)
	if width <= 0
		echohl ErrorMsg
		echo "Invalid number: " . t
		echohl None
		redraw
		return 0
	endif
	exec 'LineBreaker ' . width
endfunc

function! MenuHelp_EasyMotion(what)
	if a:what != ''
		stopinsert
		call feedkeys("\<Plug>(easymotion-" . a:what . ")", '')
	endif
endfunc



