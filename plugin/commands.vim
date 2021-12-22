"======================================================================
"
" commands.vim - 
"
" Created by skywind on 2021/12/22
" Last Modified: 2021/12/22 22:18:11
"
"======================================================================


"----------------------------------------------------------------------
" Follow switchbuf option to open a file
"----------------------------------------------------------------------
command! -nargs=+ FileSwitch call s:FileSwitch(<f-args>)
function! s:FileSwitch(...)
	call asclib#utils#file_switch(a:000)
endfunc


"----------------------------------------------------------------------
" Switch cpp/h file
"----------------------------------------------------------------------
command! -nargs=? SwitchHeader call module#cpp#switch_header(<f-args>) 


"----------------------------------------------------------------------
" paste mode line
"----------------------------------------------------------------------
command! -nargs=0 PasteVimModeLine call s:PasteVimModeLine()
function! s:PasteVimModeLine()
	let l:modeline = printf(" vim: set ts=%d sw=%d tw=%d %set :",
		\ &tabstop, &shiftwidth, &textwidth, &expandtab ? '' : 'no')
	if &commentstring != ""
		let l:modeline = substitute(&commentstring, "%s", l:modeline, "")
	else
		let l:modeline = substitute(l:modeline, '^ ', '', 'g')
	endif
	let l:save = @0
	let @0 = l:modeline
	exec 'normal! "0P'
	let @0 = l:save
endfunc


"----------------------------------------------------------------------
" remove trailing white-spaces
"----------------------------------------------------------------------
command! -nargs=0 StripTrailingWhitespace call s:StripTrailingWhitespace()
function! s:StripTrailingWhitespace()
	let _s=@/
	let l = line(".")
	let c = col(".")
	" do the business:
	exec '%s/\r$\|\s\+$//e'
	" clean up: restore previous search history, and cursor position
	let @/=_s
	call cursor(l, c)
endfunc


"----------------------------------------------------------------------
" update last modified time
"----------------------------------------------------------------------
command! -nargs=0 UpdateLastModified call s:UpdateLastModified()
function! s:UpdateLastModified()
	" preparation: save last search, and cursor position.
	let _s=@/
	let l = line(".")
	let c = col(".")

	let n = min([10, line('$')]) " check head
	let timestamp = strftime('%Y/%m/%d %H:%M') " time format
	let timestamp = substitute(timestamp, '%', '\%', 'g')
	let pat = substitute('Last Modified:\s*\zs.*\ze', '%', '\%', 'g')
	keepjumps silent execute '1,'.n.'s%^.*'.pat.'.*$%'.timestamp.'%e'

	" clean up: restore previous search history, and cursor position
	let @/=_s
	call cursor(l, c)
endfunc


"----------------------------------------------------------------------
" open terminal
"----------------------------------------------------------------------
command! -nargs=? OpenTerminal call s:OpenTerminal(<q-args>)
function! s:OpenTerminal(pos)
	let pos = asclib#string#strip(a:pos)
	let pos = (pos != '')? pos : 'TAB'
	let shell = get(g:, 'terminal_shell', split(&shell, ' ')[0])
	exec 'AsyncRun -mode=term -pos='. (pos) . ' -cwd=<root> ' . shell
endfunc


"----------------------------------------------------------------------
" break long lines to small lines of 76 characters.
"----------------------------------------------------------------------
command! -nargs=1 LineBreaker call s:LineBreaker(<q-args>)
function! s:LineBreaker(width)
	let width = &textwidth
	let p1 = &g:formatprg
	let p2 = &l:formatprg
	let &textwidth = str2nr(a:width)
	set formatprg=
	setlocal formatprg=
	exec 'normal ggVGgq'
	let &textwidth = width
	let &g:formatprg = p1
	let &l:formatprg = p2
endfunc


"----------------------------------------------------------------------
" OpenURL[!] [url]
" - open url in default browser (change this by g:browser_cmd)
" - when bang (!) is included, ignore g:browser_cmd
" - when url is omitted, use the current url under cursor
" - vim-plug format "Plug 'xxx'" can also be accepted.
"----------------------------------------------------------------------
command! -nargs=* -bang OpenURL call s:OpenURL(<q-args>, '<bang>')
function! s:OpenURL(url, bang)
	let url = a:url
	if url == ''
		let t = matchstr(getline('.'), '^\s*Plug\s*''\zs\(.\{-}\)*\ze''')
		if t != ''
			let github = 'https://github.com/'
			let url = (t =~ '^\(http\|https\):\/\/')? t : (github . t)
		else
			let url = expand('<cfile>')
		endif
	endif
	if url != ''
		call asclib#utils#open_url(url, a:bang)
	endif
endfunc


"----------------------------------------------------------------------
" browse code in github or gitlab
"----------------------------------------------------------------------
command! -nargs=* -bang BrowseGit call s:BrowseGit(<q-args>, '<bang>')
function! s:BrowseGit(name, bang, ...)
	let name = asclib#string#strip(a:name)
	let raw = (a:0 > 0)? (a:1) : 0
	let url = asclib#utils#git_browse(name, raw)
	if url != ''
		call s:open_url(url, a:bang)
	endif
endfunc


"----------------------------------------------------------------------
" Insert Class Name
"----------------------------------------------------------------------
command! -nargs=0 -range CppClassInsert 
			\ call module#cpp#class_insert(<line1>, <line2>)


"----------------------------------------------------------------------
" expand brace
"----------------------------------------------------------------------
command! -nargs=0 -range CppBraceExpand
			\ call module#cpp#brace_expand(<line1>, <line2>)


"----------------------------------------------------------------------
" cd to file directory
"----------------------------------------------------------------------
command! -nargs=0 CdToFileDir call s:CdToFileDir()
function! s:CdToFileDir()
	if &buftype == '' && expand('%') != ''
		silent exec 'cd ' . fnameescape(expand('%:p:h'))
		exec 'pwd'
	endif
endfunc


"----------------------------------------------------------------------
" cd to project root
"----------------------------------------------------------------------
command! -nargs=0 CdToProjectRoot call s:CdToProjectRoot()
function! s:CdToProjectRoot()
	if &buftype == '' && expand('%') != ''
		let root = asclib#path#get_root(expand('%:p'))
		silent exec 'cd ' . fnameescape(root)
		exec 'pwd'
	endif
endfunc

