"======================================================================
"
" task.vim - 
"
" Created by skywind on 2018/04/25
" Last Modified: 2018/04/25 16:11:35
"
"======================================================================

let s:task = {}

let g:asclib#task#shell = ''
let g:asclib#task#shellcmdflag = ''


"----------------------------------------------------------------------
" internal state
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')
let s:support = 0
let s:nvim = has('nvim')
let s:tasks = {}
let s:task_id = 1

" check has advanced mode
if (v:version >= 800 || has('patch-7.4.1829')) && (!has('nvim'))
	if has('job') && has('channel') 
		let s:support = 1
	endif
elseif has('nvim')
	let s:support = 1
endif

" display error message
function! s:errmsg(text)
	echohl ErrorMsg
	echom a:text
	echohl None
endfunc

" allocate free task id
function! s:allocate()
	while 1
		if !has_key(s:tasks, s:task_id)
			return s:task_id
		endif
		let s:task_id += 1
		if s:task_id >= 0x7fffffff
			let s:task_id = 1
		endif
	endwhile
endfunc

" change directory with right command
function! s:chdir(path)
	if has('nvim')
		let cmd = haslocaldir()? 'lcd' : (haslocaldir(-1, 0)? 'tcd' : 'cd')
	else
		let cmd = haslocaldir()? ((haslocaldir() == 1)? 'lcd' : 'tcd') : 'cd'
	endif
	silent execute cmd . ' '. fnameescape(a:path)
endfunc


"----------------------------------------------------------------------
" object initialize
"----------------------------------------------------------------------
let s:task.__private = {}
let s:task.__private.state = 0
let s:task.__private.opts = {}
let s:task.__private.id = 0
let s:task.__private.name = ''


"----------------------------------------------------------------------
" task.__prepare_opts
"----------------------------------------------------------------------
function! s:init_cbs(task) abort
	let obj = {}
	let obj.task = a:task
	let a:task.__private.is_closed = 0
	let a:task.__private.is_exited = 0
	function! obj.out_cb(channel, text) abort
		if has_key(self.task, 'cb')
			let text = a:text
			if s:windows
				let text = substitute(text, '\r$', '', 'g')
			endif
			call self.task.cb(self.task, 'stdout', text)
		endif
	endfunc
	function! obj.err_cb(channel, text) abort
		if has_key(self.task, 'cb')
			let text = a:text
			if s:windows
				let text = substitute(text, '\r$', '', 'g')
			endif
			call self.task.cb(self.task, 'stderr', text)
		endif
	endfunc
	function! obj.close_cb(channel) abort
		let options = {'timeout':0}
		let options['part'] = 'out'
		let limit = 64
		while ch_status(a:channel) == 'buffered'
			let text = ch_read(a:channel, options)
			if text == '' 
				let limit -= 1
				if limit < 0 | break | endif
			else
				call self.out_cb(a:channel, text)
			endif
		endwhile
		let options['part'] = 'err'
		let limit = 64
		while ch_status(a:channel) == 'buffered'
			let text = ch_read(a:channel, options)
			if text == '' 
				let limit -= 1
				if limit < 0 | break | endif
			else
				call self.err_cb(a:channel, text)
			endif
		endwhile
		if has_key(self.task.__private, 'job')
			call job_status(self.task.__private.job)
		endif
		let self.task.__private.is_closed = 1
		call self.check_finish()
	endfunc
	function! obj.exit_cb(job, message) abort
		let self.task.__private.is_exited = 1
		let self.task.__private.code = a:message
		call self.check_finish()
	endfunc
	function! obj.check_finish() abort
		if self.task.__private.is_closed == 0
			return
		endif
		if self.task.__private.is_exited == 0
			return
		endif
		if has_key(self.task.__private, 'job')
			unlet self.task.__private.job
		endif
		if has_key(s:tasks, self.task.__private.id)
			unlet s:tasks[self.task.__private.id]
		endif
		let self.task.__private.id = 0
		let self.task.__private.state = 0
		let self.task.state = self.task.__private.state
		let self.task.id = self.task.__private.id
		if has_key(self.task, 'cb')
			call self.task.cb(self.task, 'exit', self.task.__private.code)
		endif
	endfunc
	function! obj.neovim_dispatch(event, data)
		if has_key(self.task, 'cb')
			let task = self.task
			let size = len(a:data)
			let cache = ''
			if a:event == 'stdout'
				let cache = self.task.__private.nvim_stdout
			else
				let cache = self.task.__private.nvim_stderr
			endif
			for index in range(size)
				let cache .= a:data[index]
				if l:index + 1 < size
					let text = cache
					let cache = ''
					if s:windows
						let text = substitute(text, '\r$', '', 'g')
					endif
					call task.cb(task, a:event, text)
				endif
			endfor
			if a:event == 'stdout'
				let self.task.__private.nvim_stdout = cache
			else
				let self.task.__private.nvim_stderr = cache
			endif
		endif
	endfunc
	function! obj.neovim_cb(job_id, data, event) abort
		let task = self.task
		if a:event == 'stdout'
			if has_key(self.task, 'cb')
				call self.neovim_dispatch('stdout', a:data)
			endif
		elseif a:event == 'stderr'
			if has_key(self.task, 'cb')
				if self.task.__private.err2out == 0
					call self.neovim_dispatch('stderr', a:data)
				else
					call self.neovim_dispatch('stdout', a:data)
				endif
			endif
		elseif a:event == 'exit'
			if has_key(self.task, 'cb')
				let stdout = self.task.__private.nvim_stdout
				let stderr = self.task.__private.nvim_stderr
				if stdout != ''
					call task.cb(task, 'stdout', stdout)
				endif
				if stderr != ''
					call task.cb(task, 'stderr', stderr)
				endif
			endif
			let self.task.__private.is_closed = 1
			let self.task.__private.is_exited = 1
			let self.task.__private.code = a:data
			call self.check_finish()
		endif
	endfunc
	return obj
endfunc


"----------------------------------------------------------------------
" task.start
"----------------------------------------------------------------------
function! s:task_start(task, cmd, opts) abort
	let task = a:task
	let running = 0
	if has_key(task.__private, 'job')
		if s:nvim == 0
			let running = (job_status(task.__private.job) == 'run')? 1 : 0
		else
			let running = (task.__private.job > 0)? 1 : 0
		endif
	endif
	if task.__private.state != 0 || running != 0
		return -1
	endif
	if a:cmd == ''
		return -2
	endif
	let task.__private.opts = copy(a:opts)
	let task.__private.err2out = get(a:opts, 'err2out', 0)? 1 : 0
	let task.__private.in_null = get(a:opts, 'in_null', 0)? 1 : 0
	let task.__private.cwd = get(a:opts, 'cwd', '')
	let l:shell = &shell
	let l:shellcmdflag = &shellcmdflag
	if g:asclib#task#shell != ''
		let l:shell = g:asclib#task#shell
		let l:shellcmdflag = g:asclib#task#shellcmdflag
	endif
	if get(a:opts, 'shell', '') != ''
		let l:shell = get(a:opts, 'shell', '')
		let l:shellcmdflag = get(a:opts, 'shellcmdflag', '')
	endif
	if !executable(l:shell)
		return -3
	endif
	let args = [l:shell]
	if l:shellcmdflag != ''
		let args += [l:shellcmdflag]
	endif
	let task.__private.state = 0
	let task.__private.args = args + [a:cmd]
	let task.__private.cmd = a:cmd
	let task.__private.id = 0
	let success = 0
	if s:support != 0
		if s:nvim == 0
			let callback = s:init_cbs(task)
			let opts = {}
			let opts['out_io'] = 'pipe'
			let opts['err_io'] = task.__private.err2out? 'out' : 'pipe'
			let opts['in_io'] = task.__private.in_null? 'null' : 'pipe'
			let opts['in_mode'] = 'nl'
			let opts['out_mode'] = 'nl'
			let opts['err_mode'] = 'nl'
			let opts['stoponexit'] = 'term'
			let opts['out_cb'] = callback.out_cb
			let opts['err_cb'] = callback.err_cb
			let opts['close_cb'] = callback.close_cb
			let opts['exit_cb'] = callback.exit_cb
			let task.__private.job = job_start(task.__private.args, opts)
			let success = (job_status(task.__private.job) != 'fail')? 1 : 0
		else
			let opts = s:init_cbs(task)
			let opts['on_stdout'] = opts.neovim_cb
			let opts['on_stderr'] = opts.neovim_cb
			let opts['on_exit'] = opts.neovim_cb
			let opts['task'] = task
			" echo keys(opts.task)
			let task.__private.nvim_stdout = ''
			let task.__private.nvim_stderr = ''
			let task.__private.job = jobstart(task.__private.args, opts)
			let success = (task.__private.job > 0)? 1 : 0
			if success
				if task.__private.in_null
					if exists('*chanclose')
						call chanclose(task.__private.job, 'stdin')
					elseif exists('*jobclose')
						call jobclose(task.__private.job, 'stdin')
					endif
				endif
			endif
		endif
		if success
			let task.__private.state = or(task.__private.state, 1)
			let task.__private.id = s:allocate()
			let s:tasks[task.__private.id] = task
		endif
	else
		let task.__private.state = 1
		let command = a:cmd
		let tmp1 = tempname()
		let tmp2 = tempname()
		if task.__private.err2out == 0
			let command .= ' > '.shellescape(tmp1).' 2> '.shellescape(tmp2)
		else
			let command .= ' > '.shellescape(tmp1).' 2>&1'
		endif
		exec 'silent !'.command
		let task.__private.state = 0
		let success = (v:shell_error < 0)? 0 : 1
		if success != 0
			if filereadable(tmp1)
				for text in readfile(tmp1)
					call task.cb(task, 'stdout', text)
				endfor
				silent! call delete(tmp1)
			endif
			if task.__private.err2out == 0
				if filereadable(tmp2)
					for text in readfile(tmp2)
						call task.cb(task, 'stderr', text)
					endfor
					silent! call delete(tmp2)
				endif
			endif
			call task.cb(task, 'exit', v:shell_error)
		endif
	endif
	if success == 0
		if has_key(task.__private, 'job')
			unlet task.__private.job
		endif
		return -4
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" start job
"----------------------------------------------------------------------
function! s:task.start(command, opts) abort
	let macros = {}
	let macros['VIM_FILEPATH'] = expand("%:p")
	let macros['VIM_FILENAME'] = expand("%:t")
	let macros['VIM_FILEDIR'] = expand("%:p:h")
	let macros['VIM_FILENOEXT'] = expand("%:t:r")
	let macros['VIM_FILEEXT'] = "." . expand("%:e")
	let macros['VIM_CWD'] = getcwd()
	let macros['VIM_CWORD'] = expand("<cword>")
	let macros['VIM_VERSION'] = ''.v:version
	let macros['VIM_SVRNAME'] = v:servername
	let macros['VIM_COLUMNS'] = ''.&columns
	let macros['VIM_LINES'] = ''.&lines
	let macros['VIM_GUI'] = has('gui_running')? 1 : 0
	let ss = getcwd()
	let sn = get(a:opts, 'cwd', ss)
	for [l:key, l:val] in items(macros)
		exec 'let $'.l:key.' = l:val'
	endfor
	if sn != ''
		silent! call s:chdir(sn)
	endif
	let self.__private.cwd = getcwd()
	let self.cwd = self.__private.cwd
	let $VIM_CWD = self.__private.cwd
	let $VIM_RELDIR = expand("%:h:.")
	let $VIM_RELNAME = expand("%:p:.")
	let $VIM_CFILE = expand("<cfile>")
	let hr = s:task_start(self, a:command, a:opts)
	if sn != ''
		silent! call s:chdir(ss)
	endif
	let self.state = self.__private.state
	let self.id = self.__private.id
	if hr == -1
		call s:errmsg('background job is still running')
		return -1
	endif
	if hr == -2
		call s:errmsg('empty command')
		return -2
	endif
	if hr == -3
		let text = 'invalid config in &shell and &shellcmdflag'
		call s:errmsg(text . ', &shell must be executable')
		return -3
	endif
	if hr == -4
		call s:errmsg('start job failed')
		return -4
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" stop background job
"----------------------------------------------------------------------
function! s:task.stop(how) abort
	let how = (a:how != '')? a:how : 'term'
	if s:support == 0
		call errmsg('not support')
		return -1
	endif
	if has_key(self.__private, 'job')
		if s:nvim == 0
			if job_status(self.__private.job) == 'run'
				if job_stop(self.__private.job, how)
					return 0
				else
					return -2
				endif
			else
				return -3
			endif
		else
			if self.__private.job > 0
				silent! call jobstop(self.__private.job)
			endif
		endif
	else
		return -4
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" job status
"----------------------------------------------------------------------
function! s:task.status()
	if has_key(self.__private, 'job')
		if s:nvim == 0
			return job_status(self.__private.job)
		else
			return 'run'
		endif
	else
		return 'none'
	endif
endfunc


"----------------------------------------------------------------------
" send
"----------------------------------------------------------------------
function! s:task.send(data)
	if s:support == 0
		call s:errmsg('not support')
		return -1
	endif
	if has_key(self.__private, 'job')
		if s:nvim == 0
			let job = self.__private.job
			let channel = job_getchannel(job)
			if type(a:data) == 1
				call ch_sendraw(channel, a:data. "\n")
			else
				for text in a:data
					call ch_sendraw(channel, text. "\n")
				endfor
			endif
		else
			if type(a:data) == 1
				if exists('*chansend')
					call chansend(self.__private.job, [a:data, ''])
				elseif exists('*jobsend')
					call jobsend(self.__private.job, [a:data, ''])
				endif
			else
				if exists('*chansend')
					call chansend(self.__private.job, a:data + [''])
				elseif exists('*jobsend')
					call jobsend(self.__private.job, a:data + [''])
				endif
			endif
		endif
	else
		return -2
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" close stdin
"----------------------------------------------------------------------
function! s:task.close()
	if s:support == 0
		call s:errmsg('not support')
		return -1
	endif
	if has_key(self.__private, 'job')
		if s:nvim == 0
			let job = self.__private.job
			silent! call ch_close_in(job)
		else
			let job = self.__private.job
			if exists('*chanclose')
				silent! call chanclose(job, 'stdin')
			elseif exists('*jobclose')
				silent! call jobclose(job, 'stdin')
			endif
		endif
	endif
endfunc


"----------------------------------------------------------------------
" new task object
"----------------------------------------------------------------------
function! asclib#task#new(callback, name)
	let newobj = deepcopy(s:task)
	let newobj.__private.name = a:name
	let newobj.name = a:name
	let newobj.state = 0
	let newobj.id = 0
	if type(a:callback) == 1
		let newobj.cb = function(a:callback)
	else
		let newobj.cb = a:callback
	endif
	return newobj
endfunc


"----------------------------------------------------------------------
" copy list
"----------------------------------------------------------------------
function! asclib#task#list()
	return copy(s:tasks)
endfunc



"----------------------------------------------------------------------
" testing case
"----------------------------------------------------------------------
if 0
	function! s:my_cb(task, event, data) abort
		if a:event == 'stdout' 
			caddexpr '['. (a:task.name) .'/'. (a:task.id) .' stdout] '. a:data
		elseif a:event == 'stderr'
			caddexpr '['. (a:task.name) .'/'. (a:task.id) .' stderr] '. a:data
		elseif a:event == 'exit'
			caddexpr '['. (a:task.name) .'/'. (a:task.id) .'] '. '[end]'
		endif
		cbottom
	endfunc
	let t1 = asclib#task#new(function('s:my_cb'), "test task A")
	let t2 = asclib#task#new(function('s:my_cb'), "test task B")
	cexpr ""
	" call t1.start('dir', {})
	if s:windows == 0
		call t1.start('python ~/tmp/timer.py', {'err2out':0})
	else
		call t1.start('python e:/lab/timer.py', {'err2out':0})
	endif
	call t2.start('python e:/lab/timer.py', {})
endif


