"======================================================================
"
" extension.vim - 
"
" Created by skywind on 2023/06/28
" Last Modified: 2023/06/28 16:02:42
"
"======================================================================


"----------------------------------------------------------------------
" display help
"----------------------------------------------------------------------
function! module#extension#help(name, ...)
	let path = asclib#path#runtime('site/doc/' . a:name . '.txt')
	if !filereadable(path)
		call asclib#common#errmsg('E149: Sorry, no help for ' . a:name)
	else
		if asclib#utils#display(path, 'auto') == 0
			call asclib#utils#make_info_buf()
			if a:0 > 0
				if a:1 > 0
					exec printf(':%d', a:1)
				endif
			endif
			if a:0 > 1
				let ft = a:2
				exec printf('setlocal ft=%s', ft)
			endif
			noremap <buffer>c :close<cr>
			noremap <buffer>q :close<cr>
			noremap <buffer><bs> :close<cr>
		endif
	endif
endfunc


"----------------------------------------------------------------------
" list keys
"----------------------------------------------------------------------
function! module#extension#help_list()
	let pattern = asclib#path#runtime('site/doc/*.txt')
	let keys = []
	for name in split(asclib#path#glob(pattern), "\n")
		let nm = fnamemodify(name, ':t:r')
		let keys += [nm]
	endfor
	return keys
endfunc


"----------------------------------------------------------------------
" help complete
"----------------------------------------------------------------------
function! module#extension#help_complete(ArgLead, CmdLine, CursorPos)
	let keys = module#extension#help_list()
	return asclib#common#complete(a:ArgLead, a:CmdLine, a:CursorPos, keys)
endfunc


"----------------------------------------------------------------------
" read txt mode
"----------------------------------------------------------------------
function! module#extension#toggle_reading_mode()
	if &l:wrap == 0
		setlocal wrap
		noremap <buffer>j gj
		noremap <buffer>k gk
		echo "reading mode enabled" 
	else
		setlocal nowrap
		unmap <buffer>j
		unmap <buffer>k
		echo "reading mode disabled" 
	endif
endfunc



