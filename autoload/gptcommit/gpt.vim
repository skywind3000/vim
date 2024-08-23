"======================================================================
"
" gpt.vim - 
"
" Created by skywind on 2024/02/14
" Last Modified: 2024/02/19 14:35
"
"======================================================================


"----------------------------------------------------------------------
" errmsg
"----------------------------------------------------------------------
function! s:errmsg(msg)
	call gptcommit#utils#errmsg(a:msg)
endfunc


"----------------------------------------------------------------------
" generate commit message 
"----------------------------------------------------------------------
function! gptcommit#gpt#generate(path) abort
	let args = []
	let engine = get(g:, 'gpt_commit_engine', 'chatgpt')
	if engine != 'chatgpt'
		let args += ['--engine=' . engine]
	endif
	if engine == 'chatgpt'
		let apikey = get(g:, 'gpt_commit_key', '')
		if apikey == ''
			call s:errmsg('g:gpt_commit_key is undefined')
			return ''
		endif
		let args += ['--key=' . apikey]
		let url = get(g:, 'gpt_commit_url', '')
		if url != ''
			let args += ['--url=' . url]
		endif
		let model = get(g:, 'gpt_commit_model', '')
		if model != ''
			let args += ['--model=' . model]
		endif
	elseif engine == 'ollama'
		let ollama_model = get(g:, 'gpt_commit_ollama_model', '')
		if ollama_model == ''
			call s:errmsg('g:gpt_commit_ollama_model is undefined')
			return ''
		endif
		let args += ['--ollama_model=' . ollama_model]
		let ollama_url = get(g:, 'gpt_commit_ollama_url', '')
		if ollama_url != ''
			let args += ['--ollama_url=' . ollama_url]
		endif
	endif
	if !isdirectory(a:path)
		call s:errmsg('invalid path: ' . a:path)
		return ''
	endif
	if get(g:, 'gpt_commit_staged', 1)
		let args += ['--staged']
	endif
	let proxy = get(g:, 'gpt_commit_proxy', '')
	if proxy != ''
		let args += ['--proxy=' . proxy]
	endif
	let maxline = get(g:, 'gpt_commit_max_line', 0)
	if maxline > 0
		let args += ['--maxline=' . maxline]
	endif
	let lang = get(g:, 'gpt_commit_lang', '')
	if lang != ''
		let args += ['--lang=' . lang]
	endif
	if get(g:, 'gpt_commit_concise', 0)
		let args += ['--concise']
	endif
	let prompt = get(g:, 'gpt_commit_prompt', '')
	if prompt != ''
		let args += ['--prompt=' . prompt]
	endif
	if get(g:, 'gpt_commit_fake', 0)
		let args += ['--fake']
	endif
	let path = a:path
	if has('win32') || has('win64') || has('win95') || has('win16')
		let path = tr(path, '\', '/')
	endif
	let args += [path]
	" echo args
	let hr = gptcommit#utils#request(args)
	if get(g:, 'gpt_commit_fake', 0)
		if exists('g:gpt_commit_fake_msg')
			if type(g:gpt_commit_fake_msg) == type([])
				let hr = join(g:gpt_commit_fake_msg, "\n")
			else
				let hr = g:gpt_commit_fake_msg
			endif
		endif
	endif
	return hr
endfunc


"----------------------------------------------------------------------
" :GptCommit command
"----------------------------------------------------------------------
function! gptcommit#gpt#cmd(bang, path)
	let path = a:path
	if path == ''
		let path = gptcommit#utils#current_path()
	endif
	if path == ''
		call s:errmsg('can not detect path info')
		return 1
	elseif !isdirectory(path)
		call s:errmsg('directory does not exist: ' . path)
		return 2
	elseif gptcommit#utils#repo_root(path) == ''
		call s:errmsg('not in a git repository: ' . path) 
		return 3
	endif
	if a:bang == 0
		if gptcommit#utils#buffer_writable() == 0
			call s:errmsg('buffer is not writable')
		endif
	endif
	redraw
	echohl Title
	echo 'Generating commit message ...'
	echohl None
	redraw
	let text = gptcommit#gpt#generate(path)
	if text == ''
		redraw
		return 4
	endif
	if a:bang == 0
		let content = split(text, "\n")
		call append(line('.') - 1, content)
		echohl Title
		echo "Generated"
		echohl None
		redraw
	else
		let @* = text
		echohl Title
		echo 'Generated (saved in the unnamed register, paste manually by "*p).'
		echohl None
		redraw
	endif
	return 0
endfunc



