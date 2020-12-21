"======================================================================
"
" vimmake.vim - 
"
" Created by skywind on 2020/02/13
" Last Modified: 2020/02/13 04:17:51
"
" Implements:
"   - GrepCode command
"   - keymaps for AsyncTask
"
"======================================================================

" vim: set et fenc=utf-8 ff=unix sts=8 sw=4 ts=4 :


"----------------------------------------------------------------------
"- Global Variables
"----------------------------------------------------------------------

"----------------------------------------------------------------------
" Internal Definition
"----------------------------------------------------------------------

" path where vimmake.vim locates
let s:vimmake_windows = 0	" internal usage, won't be modified by user

" check running in windows
if has('win32') || has('win64') || has('win95') || has('win16')
	let s:vimmake_windows = 1
endif

" join two path
function! s:PathJoin(home, name)
	return asclib#path#join(a:home, a:name)
endfunc


"----------------------------------------------------------------------
" grep code
"----------------------------------------------------------------------
if !exists('g:vimmake_grep_exts')
	let g:vimmake_grep_exts = ['c', 'cpp', 'cc', 'h', 'hpp', 'hh', 'as']
	let g:vimmake_grep_exts += ['m', 'mm', 'py', 'js', 'php', 'java', 'vim']
	let g:vimmake_grep_exts += ['asm', 's', 'pyw', 'lua', 'go', 'rs']
endif

function! vimmake#grep(text, cwd)
	let mode = get(g:, 'vimmake_grep_mode', '')
	let fixed = get(g:, 'vimmake_grep_fixed', 0)
	if mode == ''
		let mode = (s:vimmake_windows == 0)? 'grep' : 'findstr'
	endif
	if mode == 'grep'
		let l:inc = ''
		for l:item in g:vimmake_grep_exts
			if s:vimmake_windows == 0
				let l:inc .= " --include='*." . l:item . "'"
			else
				let l:inc .= " --include=*." . l:item
			endif
		endfor
		if a:cwd == '.' || a:cwd == ''
			let l:inc .= ' *'
		else
			let l:full = asyncrun#fullname(a:cwd)
			let l:inc .= ' '.shellescape(l:full)
		endif
		let cmd = 'grep -n -s -R ' . (fixed? '-F ' : '')
		let cmd .= shellescape(a:text). l:inc .' /dev/null'
		call asyncrun#run('', {}, cmd)
	elseif mode == 'findstr'
		let l:inc = ''
		for l:item in g:vimmake_grep_exts
			if a:cwd == '.' || a:cwd == ''
				let l:inc .= '*.'.l:item.' '
			else
				let l:full = asyncrun#fullname(a:cwd)
				let l:inc .= '"%CD%/*.'.l:item.'" '
			endif
		endfor
		let options = { 'cwd':a:cwd }
		call asyncrun#run('', options, 'findstr /n /s /C:"'.a:text.'" '.l:inc)
	elseif mode == 'ag'
		let inc = []
		for item in g:vimmake_grep_exts
			let inc += ['\.'.item]
		endfor
		let cmd = 'ag ' . (fixed? '-F ' : '')
		if len(inc) > 0
			let cmd .= '-G '.shellescape('('.join(inc, '|').')$'). ' '
		endif
		let cmd .= '--nogroup --nocolor '.shellescape(a:text)
		if a:cwd != '.' && a:cwd != ''
			let cmd .= ' '. shellescape(asyncrun#fullname(a:cwd))
		endif
		call asyncrun#run('', {'mode':0}, cmd)
	elseif mode == 'rg'
		let cmd = 'rg -n --no-heading --color never '. (fixed? '-F ' : '')
		if len(g:vimmake_grep_exts) > 0
			let cmd .= ' --type-clear src '
			for item in g:vimmake_grep_exts
				if s:vimmake_windows == 0
					let cmd .= " --type-add 'src:*.". item . "'"
				else
					let cmd .= " --type-add \"src:*.". item . "\""
				endif
			endfor
			let cmd .= " -tsrc "
		endif
		let cmd .= ' '. shellescape(a:text)
		if a:cwd != '.' && a:cwd != ''
			let cmd .= ' '. shellescape(asyncrun#fullname(a:cwd))
		endif
		call asyncrun#run('', {'mode':0}, cmd)
	endif
endfunc

function! s:Cmd_GrepCode(bang, what, ...)
	let l:cwd = (a:0 == 0)? fnamemodify(expand('%'), ':h') : a:1
	if a:bang != ''
		let l:cwd = asyncrun#get_root(l:cwd)
	endif
	if l:cwd != ''
		let l:cwd = asyncrun#fullname(l:cwd)
	endif
	call vimmake#grep(a:what, l:cwd)
	let title = 'GrepCode' . a:bang . ' '. a:what
	if has('nvim') == 0 && (v:version >= 800 || has('patch-7.4.2210'))
		call setqflist([], 'a', {'title':title})
	elseif has('nvim') && has('nvim-0.2.2')
		call setqflist([], 'a', {'title':title})
	elseif has('nvim')
		call setqflist([], 'a', title)
	endif
endfunc

command! -bang -nargs=+ GrepCode call s:Cmd_GrepCode('<bang>', <f-args>)


"----------------------------------------------------------------------
" returns cmd
"----------------------------------------------------------------------
function! vimmake#hashtag(cwd)
	let mode = get(g:, 'vimmake_grep_mode', '')
	let mode = (mode == '' || mode == 'findstr')? 'grep' : mode
	if mode == 'grep'
		let text = '[\s:\-\.,\(\)\{\}]#\w*'
		let l:inc = ''
		for l:item in g:vimmake_grep_exts
			if s:vimmake_windows == 0
				let l:inc .= " --include='*." . l:item . "'"
			else
				let l:inc .= " --include=*." . l:item
			endif
		endfor
		if a:cwd == '.' || a:cwd == ''
			let l:inc .= ' *'
		else
			let l:full = asyncrun#fullname(a:cwd)
			let l:inc .= ' '.shellescape(l:full)
		endif
		let cmd = 'grep -s -h -R -P '
		let cmd .= shellescape(text). l:inc .' /dev/null'
		let cmd .= ' | grep -v -P ' . shellescape('^\s*#')
		let cmd .= ' | grep -s -h -o -P ' . shellescape(text)
		let cmd .= ' | grep -s -h -o ' . shellescape('#\w\+')
		return cmd
	elseif mode == 'rg'
		let cmd = 'rg --no-heading --no-filename --color never '
		let text = '[\s:\-\.,\(\)\{\}]#\w+'
		if len(g:vimmake_grep_exts) > 0
			let cmd .= ' --type-clear src '
			for item in g:vimmake_grep_exts
				if s:vimmake_windows == 0
					let cmd .= " --type-add 'src:*.". item . "'"
				else
					let cmd .= " --type-add \"src:*.". item . "\""
				endif
			endfor
			let cmd .= " -tsrc "
		endif
		let cmd .= ' '. shellescape(text)
		if a:cwd != '.' && a:cwd != ''
			let cmd .= ' '. shellescape(asyncrun#fullname(a:cwd))
		else
			let cmd .= ' .'
		endif
		let cmd .= ' | rg -v ' . shellescape('^\s*#')
		let cmd .= ' | rg -o ' . shellescape(text)
		let cmd .= ' | rg -o ' . shellescape('#\w+')
		return cmd
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" cscope easy
"----------------------------------------------------------------------
function! s:Cmd_VimScope(bang, what, name)
	let l:text = ''
	if a:what == '0' || a:what == 's'
		let l:text = 'symbol "'.a:name.'"'
	elseif a:what == '1' || a:what == 'g'
		let l:text = 'definition of "'.a:name.'"'
	elseif a:what == '2' || a:what == 'd'
		let l:text = 'functions called by "'.a:name.'"'
	elseif a:what == '3' || a:what == 'c'
		let l:text = 'functions calling "'.a:name.'"'
	elseif a:what == '4' || a:what == 't'
		let l:text = 'string "'.a:name.'"'
	elseif a:what == '6' || a:what == 'e'
		let l:text = 'egrep "'.a:name.'"'
	elseif a:what == '7' || a:what == 'f'
		let l:text = 'file "'.a:name.'"'
	elseif a:what == '8' || a:what == 'i'
		let l:text = 'files including "'.a:name.'"'
	elseif a:what == '9' || a:what == 'a'
		let l:text = 'assigned "'.a:name.'"'
	endif
	let ncol = col('.')
	let nrow = line('.')
	let nbuf = winbufnr('%')
	silent cexpr "[cscope ".a:what.": ".l:text."]"
	let success = 1
	try
		exec 'cs find '.a:what.' '.fnameescape(a:name)
	catch /^Vim\%((\a\+)\)\=:E259/
		echohl ErrorMsg
		echo "E259: not find '".a:name."'"
		echohl NONE
		let success = 0
	catch /^Vim\%((\a\+)\)\=:E567/
		echohl ErrorMsg
		echo "E567: no cscope connections"
		echohl NONE
		let success = 0
	catch /^Vim\%((\a\+)\)\=:E/
		echohl ErrorMsg
		echo "ERROR: cscope error"
		echohl NONE
		let success = 0
	endtry
	if winbufnr('%') == nbuf
		call cursor(nrow, ncol)
	endif
	if success != 0 && a:bang != '!'
		if has('autocmd')
			doautocmd User VimScope
		endif
	endif
	redrawstatus!
	redraw!
endfunc

command! -nargs=* -bang VimScope call s:Cmd_VimScope("<bang>", <f-args>)


"----------------------------------------------------------------------
" Keymap Setup
"----------------------------------------------------------------------
function! vimmake#keymap()
	noremap <silent><F5> :AsyncTask file-run<cr>
	noremap <silent><F6> :AsyncTask make<cr>
	noremap <silent><F7> :AsyncTask emake<cr>
	noremap <silent><F8> :AsyncTask emake-exe<cr>
	noremap <silent><F9> :AsyncTask file-build<cr>
	noremap <silent><F10> :call asyncrun#quickfix_toggle(6)<cr>
	noremap <silent><s-f5> :AsyncTask project-run<cr>
	noremap <silent><s-f6> :AsyncTask project-test<cr>
	noremap <silent><s-f7> :AsyncTask project-init<cr>
	noremap <silent><s-f8> :AsyncTask project-install<cr>
	noremap <silent><s-f9> :AsyncTask project-build<cr>

	inoremap <silent><F5> <ESC>:AsyncTask file-run<cr>
	inoremap <silent><F6> <ESC>:AsyncTask make<cr>
	inoremap <silent><F7> <ESC>:AsyncTask emake<cr>
	inoremap <silent><F8> <ESC>:AsyncTask emake-exe<cr>
	inoremap <silent><F9> <ESC>:AsyncTask file-build<cr>
	inoremap <silent><F10> <ESC>:call asyncrun#quickfix_toggle(6)<cr>
	inoremap <silent><s-f5> <ESC>:AsyncTask project-run<cr>
	inoremap <silent><s-f6> <ESC>:AsyncTask project-test<cr>
	inoremap <silent><s-f7> <ESC>:AsyncTask project-init<cr>
	inoremap <silent><s-f8> <ESC>:AsyncTask project-install<cr>
	inoremap <silent><s-f9> <ESC>:AsyncTask project-build<cr>

	noremap <silent><f1> :AsyncTask task-f1<cr>
	noremap <silent><f2> :AsyncTask task-f2<cr>
	noremap <silent><f3> :AsyncTask task-f3<cr>
	noremap <silent><f4> :AsyncTask task-f4<cr>
	inoremap <silent><f1> <ESC>:AsyncTask task-shift-f1<cr>
	inoremap <silent><f2> <ESC>:AsyncTask task-shift-f2<cr>
	inoremap <silent><f3> <ESC>:AsyncTask task-shift-f3<cr>
	inoremap <silent><f4> <ESC>:AsyncTask task-shift-f4<cr>

	" set keymap to GrepCode
	noremap <silent><leader>cq :VimStop<cr>
	noremap <silent><leader>cQ :VimStop!<cr>
	noremap <silent><leader>cv :GrepCode <C-R>=expand("<cword>")<cr><cr>
	noremap <silent><leader>cx :GrepCode! <C-R>=expand("<cword>")<cr><cr>

	" set keymap to cscope
	if has("cscope")
		noremap <silent> <leader>cs :VimScope s <C-R><C-W><CR>
		noremap <silent> <leader>cg :VimScope g <C-R><C-W><CR>
		noremap <silent> <leader>cc :VimScope c <C-R><C-W><CR>
		noremap <silent> <leader>ct :VimScope t <C-R><C-W><CR>
		noremap <silent> <leader>ce :VimScope e <C-R><C-W><CR>
		noremap <silent> <leader>cd :VimScope d <C-R><C-W><CR>
		noremap <silent> <leader>ca :VimScope a <C-R><C-W><CR>
		noremap <silent> <leader>cf :VimScope f <C-R><C-W><CR>
		noremap <silent> <leader>ci :VimScope i <C-R><C-W><CR>
		if v:version >= 800 || has('patch-7.4.2038')
			set cscopequickfix=s+,c+,d+,i+,t+,e+,g+,f+,a+
		else
			set cscopequickfix=s+,c+,d+,i+,t+,e+,g+,f+
		endif
	endif

	" cscope update
	noremap <leader>cb1 :call vimmake#update_tags('', 'ctags', '.tags')<cr>
	noremap <leader>cb2 :call vimmake#update_tags('', 'cs', '.cscope')<cr>
	noremap <leader>cb3 :call vimmake#update_tags('!', 'ctags', '.tags')<cr>
	noremap <leader>cb4 :call vimmake#update_tags('!', 'cs', '.cscope')<cr>
	noremap <leader>cb5 :call vimmake#update_tags('', 'py', '.cscopy')<cr>
	noremap <leader>cb6 :call vimmake#update_tags('!', 'py', '.cscopy')<cr>
endfunc

command! -nargs=0 VimmakeKeymap call vimmake#keymap()


"----------------------------------------------------------------------
" tag generation
"----------------------------------------------------------------------
if !exists('g:vimmake_ctags_flags')
	let g:vimmake_ctags_flags = '--fields=+niazS --extra=+q --c++-kinds=+px'
	let g:vimmake_ctags_flags.= ' --c-kinds=+p -n'
endif

function! vimmake#update_tags(cwd, mode, outname)
	if a:cwd == '!'
		let l:cwd = asyncrun#get_root('%')
	else
		let l:cwd = asyncrun#fullname(a:cwd)
		let l:cwd = fnamemodify(l:cwd, ':p:h')
	endif
	let l:cwd = substitute(l:cwd, '\\', '/', 'g')
	if a:mode == 'ctags' || a:mode == 'ct'
		let l:ctags = s:PathJoin(l:cwd, a:outname)
		if filereadable(l:ctags)
			try | call delete(l:ctags) | catch | endtry
		endif
		let l:options = {}
		let l:options['cwd'] = l:cwd
		let l:command = 'ctags -R -f '. shellescape(l:ctags)
		let l:parameters = ' '. g:vimmake_ctags_flags. ' '
		let l:parameters .= '--sort=yes '
		call asyncrun#run('', l:options, l:command . l:parameters . ' .')
	endif
	if index(['cscope', 'cs', 'pycscope', 'py'], a:mode) >= 0
		let l:fullname = s:PathJoin(l:cwd, a:outname)
		let l:fullname = asyncrun#fullname(l:fullname)
		let l:fullname = substitute(l:fullname, '\\', '/', 'g')
		let l:cscope = fnameescape(l:fullname)
		silent! exec "cs kill ".l:cscope
		let l:command = "silent! cs add ".l:cscope.' '.fnameescape(l:cwd)." "
		let l:options = {}
		let l:options['post'] = l:command
		let l:options['cwd'] = l:cwd
		if filereadable(l:fullname)
			try | call delete(l:fullname) | catch | endtry
		endif
		if a:mode == 'cscope' || a:mode == 'cs'
			let l:fullname = shellescape(l:fullname)
			call asyncrun#run('', l:options, 'cscope -b -R -f '.l:fullname)
		elseif a:mode == 'pycscope' || a:mode == 'py'
			let l:fullname = shellescape(l:fullname)
			call asyncrun#run('', l:options, 'pycscope -R -f '.l:fullname)
		endif
	endif
endfunc



