
let s:status = 0
let s:url = ''

function! tweak#pastebin#post(text)
	if a:text == ''
		return -1
	endif
	if !executable('curl')
		call asclib#core#errmsg('curl not find !!')
		return -2
	endif
	let cmd = 'curl -s -F "content=<-" http://dpaste.com/api/v2/'
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
	echo 'hr='.hr
	call s:task.close()
endfunc

function! s:task_cb(task, event, data) abort
	echom "event: " . a:event . " data: ". a:data
	if a:event == 'stdout'
		let s:url = asclib#string#strip(a:data)
		unsilent echom "> " . a:data
	elseif a:event == 'exit'
		echom "url: ". s:url
		echom "exit: " . a:data
	endif
endfunc


