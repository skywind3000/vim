"======================================================================
"
" comp.vim - 
"
" Created by skywind on 2023/08/04
" Last Modified: 2023/08/04 14:22:42
"
"======================================================================

" key names
let s:text_keys = {
			\ 'command': 'shell command, or EX-command (starting with :)',
			\ 'cwd': "working directory, use `:pwd` when absent",
			\ 'output': '"quickfix" or "terminal"',
			\ 'pos': 'terminal position or the name of a runner', 
			\ 'errorformat': 'error matching rules in the quickfix window',
			\ 'save': 'whether to save modified buffers before task start',
			\ 'option': 'arbitrary string to pass to the runner',
			\ 'focus': 'whether to focus on the task terminal',
			\ 'close': 'to close the task terminal when task is finished',
			\ 'program': 'command modifier',
			\ 'notify': 'notify a message when task is finished',
			\ 'strip': 'trim header+footer in the quickfix',
			\ 'scroll': 'is auto-scroll allowed in the quickfix',
			\ 'encoding': 'task stdin/stdout encoding',
			\ 'once': 'buffer output and flush when job is finished',
			\ }

let s:text_system = {
			\ 'win32': '<for windows only>',
			\ 'linux': '<for linux only>',
			\ 'darwin': '<for macOS only>',
			\ }

"----------------------------------------------------------------------
" standard GPT generated function
"----------------------------------------------------------------------
function! MyOmniFunc(findstart, base)
	" If findstart is non-zero, return the column number of the start of the word
	if a:findstart
		let line = getline('.')
		let start = col('.') - 1
		while start > 0 && line[start - 1] =~ '\w'
			let start -= 1
		endwhile
		echom printf("first: pos=%d start=%d", col('.'), start)
		return start
	else
		" If findstart is zero, return a list of completions for the base
		let completions = []
		if a:base == 'foo'
			call add(completions, 'foobar')
			call add(completions, 'foobaz')
		elseif a:base == 'bar'
			call add(completions, 'barfoo')
			call add(completions, 'barbaz')
		endif
		echom printf("second: pos=%d base='%s'", col('.'), a:base)
		return completions
	endif
endfunction


" setlocal omnifunc=
setlocal omnifunc=comptask#omnifunc

inoremap <expr><c-\>a printf("%s", complete_info(['mode', 'pum_visible']))
setlocal directory=C:\Users\Linwei\.vim\bundles\vim-dict\dict\word.dict

runtime site/opt/apc3.vim
ApcEnable

