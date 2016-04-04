
"----------------------------------------------------------------------
" variables
"----------------------------------------------------------------------
if !exists('g:escope_cscope_system')
	let g:escope_cscope_system = 0
endif

if !exists('g:escope_gtags_label')
	let g:escope_gtags_label = ''
endif

if !exists('g:escope_verbose')
	let g:escope_verbose = 1
endif

if !exists('g:escope_days_keep')
	let g:escope_days_keep = 30
endif

if !exists('g:escope_database')
	let g:escope_database = ''
endif

if !exists('g:escope_rootmarks')
    let g:escope_rootmarks = ['.project', '.git', '.hg', '.svn', '.root']
endif



"----------------------------------------------------------------------
" private defintion
"----------------------------------------------------------------------

" homes
let s:escope_home = fnamemodify(resolve(expand('<sfile>:p')), ':h')
let s:plugin_home = fnamemodify(s:escope_home, ':h')
let s:escope_script = s:plugin_home . '/lib/escope.py'
let s:escope_script = substitute(s:escope_script, '\', '/', 'g')

" check running in windows
if has('win32') || has('win64') || has('win95') || has('win16')
	let s:escope_windows = 1
else
	let s:escope_windows = 0
endif

" error message
function! s:ErrorMsg(msg)
	echohl ErrorMsg
	echom 'ERROR: '. a:msg
	echohl NONE
endfunc

if !filereadable(s:escope_script)
	call s:ErrorMsg('cannot find: ' . s:escope_script)
	finish
endif

" join two path
function! s:PathJoin(home, name)
    let l:size = strlen(a:home)
    if l:size == 0 | return a:name | endif
    let l:last = strpart(a:home, l:size - 1, 1)
    if has("win32") || has("win64") || has("win16") || has('win95')
        if l:last == "/" || l:last == "\\"
            return a:home . a:name
        else
            return a:home . '/' . a:name
        endif
    else
        if l:last == "/"
            return a:home . a:name
        else
            return a:home . '/' . a:name
        endif
    endif
endfunc


"----------------------------------------------------------------------
" get full filename, '' as current cwd, '%' as current buffer
"----------------------------------------------------------------------
function! escope#fullname(f)
	let f = a:f
	if f =~ "'."
		try
			redir => m
			silent exe ':marks' f[1]
			redir END
			let f = split(split(m, '\n')[-1])[-1]
			let f = filereadable(f)? f : ''
		catch
			let f = '%'
		endtry
	endif
	let f = (f != '%')? f : expand('%')
	let f = fnamemodify(f, ':p')
	if s:escope_windows
		let f = substitute(f, "\\", '/', 'g')
	endif
	if len(f) > 1
		let size = len(f)
		if f[size - 1] == '/'
			let f = strpart(f, 0, size - 1)
		endif
	endif
	return f
endfunc


"----------------------------------------------------------------------
" get project root
"----------------------------------------------------------------------
function! escope#get_root(path)
    function! s:guess_root(filename)
        let fullname = escope#fullname(a:filename)
        if exists('b:escope_root')
            let l:escope_root = fnamemodify(b:escope_root, ':p')
            if stridx(fullfile, l:escope_root) == 0
                return b:escope_root
            endif
        endif
        if fullname =~ '^fugitive:/'
            if exists('b:git_dir')
                return fnamemodify(b:git_dir, ':h')
            endif
            return '' " skip any fugitive buffers early
        endif
		let pivot = fullname
		if !isdirectory(pivot)
			let pivot = fnamemodify(pivot, ':h')
		endif
		while 1
			let prev = pivot
			for marker in g:escope_rootmarks
				let newname = s:PathJoin(pivot, marker)
				if filereadable(newname)
					return pivot
				elseif isdirectory(newname)
					return pivot
				endif
			endfor
			let pivot = fnamemodify(pivot, ':h')
			if pivot == prev
				break
			endif
		endwhile
        return ''
    endfunc
	let root = s:guess_root(a:path)
	if len(root)
		return escope#fullname(root)
	endif
	" Not found: return parent directory of current file / file itself.
	let fullname = escope#fullname(a:path)
	if isdirectory(fullname)
		return fullname
	endif
	return escope#fullname(fnamemodify(fullname, ':h'))
endfunc


"----------------------------------------------------------------------
" build cross reference database
"----------------------------------------------------------------------
function! escope#build(backend, root, update)
	let options = {'cwd': a:root, 'raw':1}
	let command = 'python '.shellescape(s:escope_script).' -B -k '.a:backend.' '
	if g:escope_cscope_system != 0 && a:backend == 'cscope'
		let command .= '-s '
	endif
	if g:escope_gtags_label != '' && a:backend == 'gtags'
		let command .= '-l '.g:escope_gtags_label.' '
	endif
	if a:update != 0 && a:backend == 'gtags'
		let command .= '-u '
	endif
	if g:escope_verbose != 0
		let command .= '-v '
	endif
	call asyncrun#run('', options, command)
endfunc


"----------------------------------------------------------------------
" find in different modes
"----------------------------------------------------------------------
function! escope#find(backend, root, mode, name)
	let options = {'cwd': a:root}
	let command = 'python '.shellescape(s:escope_script).' -F -k '.a:backend.' '
	if a:mode == '0' || a:mode == 's'
		let command .= '-0 '
	elseif a:mode == '1' || a:mode == 'g'
		let command .= '-1 '
	elseif a:mode == '2' || a:mode == 'd'
		let command .= '-2 '
	elseif a:mode == '3' || a:mode == 'c'
		let command .= '-3 '
	elseif a:mode == '4' || a:mode == 't'
		let command .= '-4 '
	elseif a:mode == '5' || a:mode == 'x'
		let command .= '-5 '
	elseif a:mode == '6' || a:mode == 'e'
		let command .= '-6 '
	elseif a:mode == '7' || a:mode == 'f'
		let command .= '-7 '
	elseif a:mode == '8' || a:mode == 'i'
		let command .= '-8 '
	elseif a:mode == '9' || a:mode == 'a'
		let command .= '-9 '
	else
		call s:ErrorMsg('unknow mode: '.a:mode)
		return
	endif
	let command .= ' '.a:name
	call asyncrun#run('', options, command)
endfunc



"----------------------------------------------------------------------
" list database
"----------------------------------------------------------------------
function! escope#list()
	exec 'AsyncRun python '.shellescape(s:escope_script).' -L'
endfunc


"----------------------------------------------------------------------
" clean database
"----------------------------------------------------------------------
function! escope#clean()
	exec 'AsyncRun python '.shellescape(s:escope_script). ' -C -d '.
				\ g:escope_days_keep
endfunc


"----------------------------------------------------------------------
" escope command
"----------------------------------------------------------------------
function! escope#command(bang, ...)
	if a:0 == 0
		call s:ErrorMsg('require operation, see (:Es help)')
		return
	endif
	let command = a:1
	if command == 'build'
		if a:0 == 1
			call s:ErrorMsg('backend required, see (:Es help)')
			return
		endif
		let backend = a:2
		let path = (a:0 >= 3)? a:3 : getcwd()
		if a:bang == '!'
			let path = escope#get_root(path)
		endif
		call escope#build(backend, path, 0)
	elseif command == 'update'
		if a:0 == 1
			call s:ErrorMsg('backend required, see (:Es help)')
			return
		endif
		let backend = a:2
		if backend != 'gtags'
			call s:ErrorMsg('gtags backend required, see (:Es help)')
		endif
		let path = (a:0 >= 3)? a:3 : getcwd()
		if a:bang == '!'
			let path = escope#get_root(path)
		endif
		call escope#build(backend, path, 1)
	elseif command == 'find'
		if a:0 < 4
			call s:ErrorMsg('not enough arguments, see (:Es help)')
			return
		endif
		let backend = a:2
		let mode = a:3
		let name = a:4
		let path = (a:0 >= 5)? a:5 : getcwd()
		if a:bang == '!'
			let path = escope#get_root(path)
		endif
		call escope#find(backend, path, mode, name)
	elseif command == 'list'
		call escope#list()
	elseif command == 'clean'
		call escope#clean()
	elseif command == 'help'
		echo ':Es[!] build [backend] {path}'
		echo ':Es[!] update [backend] {path}'
		echo ':Es[!] find [backend] [0-9] [pattern] {path}'
		echo ':Es list'
		echo ':Es clear'
		echo '[backend] can be one of cscope/pycscope/gtags'
		echo 'Current directory is used if {path} is not given'
		echo 'if "!" is included, escope will seach the project directory'
	else
		call s:ErrorMsg('bad operation, see (:Es help)')
	endif
endfunc



