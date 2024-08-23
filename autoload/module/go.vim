"======================================================================
"
" go.vim - 
"
" Created by skywind on 2024/03/20
" Last Modified: 2024/03/20 23:37:53
"
"======================================================================


"----------------------------------------------------------------------
" internal 
"----------------------------------------------------------------------
let s:has_goimports = executable('goimports')? 1 : 0
let s:inited = 0


"----------------------------------------------------------------------
" init 
"----------------------------------------------------------------------
function! module#go#init()
	if &bt == '' && &ft == 'go'
		if s:inited == 0
			augroup ModuleGoEvents
				au!
				au BufWritePre *.go :call module#go#format()
			augroup END
			let s:inited = 1
		endif
	endif
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
function! module#go#update_header(textlist)
	return a:textlist
endfunc


"----------------------------------------------------------------------
" format  
"----------------------------------------------------------------------
function! module#go#format()
	if s:has_goimports
		let obj = asclib#core#object('b')
		if get(obj, 'post_format', 0)
			call asclib#text#format('goimports')
			if get(obj, 'update_time', 0)
				" call asclib#text#filter(1, 10, ':module#go#update_header')
				if exists(':UpdateLastModified') == 2
					" exec 'UpdateLastModified'
				endif
			endif
			" call asclib#text#format('gofmt')
		endif
	endif
endfunc


"----------------------------------------------------------------------
" mod_init
"----------------------------------------------------------------------
function! module#go#mod_init()
	let p = asyncrun#get_root('%')
	let d = p
	if len(p) > (&columns * 2) / 3 || len(p) > 60
		let d = asclib#path#shorten(p, 60)
	endif
endfunc


