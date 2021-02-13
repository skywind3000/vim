"======================================================================
"
" rtformat.vim - Format current line on Enter
"
" Created by skywind on 2021/02/13
" Last Modified: 2021/02/13 22:57:28
"
"======================================================================

" vim: set ts=4 sw=4 tw=78 noet :

"----------------------------------------------------------------------
" settings
"----------------------------------------------------------------------
let g:rtf_python = get(g:, 'rtf_python', 0)


"----------------------------------------------------------------------
" python
"----------------------------------------------------------------------
let s:py_cmd = ''
let s:py_eval = ''
let s:py_version = 0

if g:rtf_python == 0
	if has('python3')
		let s:py_cmd = 'py3'
		let s:py_eval = 'py3eval'
		let s:py_version = 3
	elseif has('python')
		let s:py_cmd = 'py'
		let s:py_eval = 'pyeval'
		let s:py_version = 2
	endif
elseif g:rtf_python == 2
	if has('python')
		let s:py_cmd = 'py'
		let s:py_eval = 'pyeval'
		let s:py_version = 2
	endif
else
	if has('python3')
		let s:py_cmd = 'py3'
		let s:py_eval = 'py3eval'
		let s:py_version = 3
	endif
endif



"----------------------------------------------------------------------
" internal
"----------------------------------------------------------------------
function! s:errmsg(text)
	redraw
	echohl ErrorMsg
	echom "ERROR: " . a:text
	echohl None
endfunc

function! s:check_python()
	if s:py_version == 0
		call s:errmsg('require +python or +python3 feature')
		return -1
	endif
	let code = ['__i = 100']
	let code += ['try:']
	let code += ['    import autopep8']
	" let code += ['    import yapf']
	let code += ['    __i = 1']
	let code += ['except ImportError:']
	let code += ['    __i = 0']
	exec s:py_cmd join(code, "\n")
	exec 'let hr = ' . s:py_eval . '("__i")'
	if hr == 0
		call s:errmsg('require python module autopep8')
		return -2
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" rules to apply
"----------------------------------------------------------------------
let s:pep8_rules = ['E101', 'E11', 'E121', 'E122', 'E123', 'E124', 'E125']
let s:pep8_rules += ['E126', 'E127', 'E128', 'E129',  'E131', 'E133', ]
let s:pep8_rules += ['E20', 'E211', 'E22', 'E224', 'E225', 'E226', 'E227']
let s:pep8_rules += ['E228', 'E231', 'E241', 'E242', 'E251', 'E252']
let s:pep8_rules += ['E27']


"----------------------------------------------------------------------
" format line
"----------------------------------------------------------------------
function! s:format_line(text)
	if &ft == 'python' || &ft == 'c' || &ft == 'cpp' || &ft == 'lua'
		let head = matchstr(a:text, '^\s*')
		let body = matchstr(a:text, '^\s*\zs.*$')
		let rules = deepcopy(s:pep8_rules)
		if &ft == 'python'
			let rules += ['E26', 'E265', 'E266']
		endif
		exec s:py_cmd "import vim"
		exec s:py_cmd "__t = vim.eval('body')"
		if 1
			exec s:py_cmd "import autopep8"
			exec s:py_cmd "__o = {'select':vim.eval('rules')}"
			exec s:py_cmd "__t = autopep8.fix_code(__t, options = __o)"
		else
			exec s:py_cmd "import yapf.yapflib.yapf_api"
			exec s:py_cmd "__t = yapf.yapflib.yapf_api.FormatCode(__t)"
			exec s:py_cmd "if type(__t) == type([]): __t = __t[0]"
			exec s:py_cmd "if type(__t) == type((0,)): __t = __t[0]"
		endif
		exec s:py_cmd '__t = __t.strip("\r\n\t ")'
		" exec s:py_cmd "print(repr(__t))"
		exec 'let newbody = ' . s:py_eval . '("__t")'
		return head . newbody
	endif
	return a:text
endfunc

function! FormatLine(text)
	return s:format_line(a:text)
endfunc


"----------------------------------------------------------------------
" Main Function
"----------------------------------------------------------------------
function! RealTimeFormatCode()
	let text = getline('.')
	let pos = col('.') - 1
	let tail = strpart(text, pos)
	if tail =~ '^\s*$'
		let text = s:format_line(text)
		call setline(line('.'), text)
		if pumvisible()
			call feedkeys("\<c-y>\<end>", 'n')
		else
			call feedkeys("\<end>", 'n')
		endif
	endif
	if pumvisible()
		call feedkeys("\<c-y>\<cr>", 'n')
	else
		call feedkeys("\<cr>", 'n')
	endif
endfunc


"----------------------------------------------------------------------
" can we use this
"----------------------------------------------------------------------
function! s:check_enable()
	if s:check_python() != 0
		return 0
	endif
	if &ft == 'vim'
		call s:errmsg('unsupported filetype: ' . &ft)
		return 0
	elseif &ft == 'python' || &ft == 'c' || &ft == 'cpp' || &ft == 'lua'
		return 1
	endif
	call s:errmsg('unsupported filetype: ' . &ft)
	return 0
endfunc


"----------------------------------------------------------------------
" commands
"----------------------------------------------------------------------
function! s:RTFormatEnable()
	if s:check_enable() == 0
		return 0
	endif
	silent! iunmap <buffer> <cr>
	inoremap <buffer><cr> <c-\><c-o>:call RealTimeFormatCode()<cr>
	let b:rtf_enable = 1
	redraw
	echohl TODO
	echo "RTFormat is enabled in current buffer, exit with :RTFormatDisable"
	echohl None
	return 0
endfunc

function! s:RTFormatDisable()
	if s:check_enable() == 0
		return 0
	endif
	if get(b:, 'rtf_enable', 0) != 0
		silent! iunmap <buffer> <cr>
	endif
	redraw
	echohl TODO
	echo "RTFormat is disabled in current buffer"
	echohl None
	let b:rtf_enable = 0
endfunc

command! -nargs=0 RTFormatEnable call s:RTFormatEnable()
command! -nargs=0 RTFormatDisable call s:RTFormatDisable()


