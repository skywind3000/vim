
let s:status = 0
let s:url = ''

function! tweak#pastebin#post(text)
	if type(a:text) == v:t_string
		if a:text == ''
			return -1
		endif
		let text = split(a:text, "\n")
	elseif type(a:text) == v:t_list
		if len(a:text) == 0
			return -1
		endif
		let text = a:text
	else
		call asclib#core#errmsg('error argument type !!')
		return -1
	endif
	if !executable('curl')
		call asclib#core#errmsg('curl not find !!')
		return -2
	endif
	let cmd = 'curl -s -F "content=<-" http://dpaste.com/api/v2/'
	let cmd = asclib#core#script_write('vim_pastebin', cmd, 0)
	if s:status != 0
		call asclib#core#errmsg('task still running')
		return -3
	endif
	let s:task = asclib#task#new(function('s:task_cb'), "pastbin task")
	let s:url = ''
	let hr = s:task.start(cmd, {'err2out': 1, 'in_null': 0})
	if hr != 0
		call asclib#core#errmsg('job start failed: ' . hr)
		return -4
	endif
	let s:status = 1
	let hr = s:task.send(a:text)
	call s:task.close()
endfunc

function! s:task_cb(task, event, data) abort
	if a:event == 'stdout'
		let s:url = asclib#string#strip(a:data)
	elseif a:event == 'exit'
		if a:data == 0
			let url = s:url . '.txt'
			" echom "url: " . s:url
			" sleep 100m
			call asclib#utils#open_url(url)
		else
			call asclib#core#errmsg('bad curl return code: ' . a:data)
		endif
		let s:status = 0
	endif
endfunc


