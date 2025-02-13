"======================================================================
"
" conda.vim - 
"
" Created by skywind on 2025/02/12
" Last Modified: 2025/02/12 22:41:40
"
"======================================================================


"----------------------------------------------------------------------
" internal variables 
"----------------------------------------------------------------------
let s:windows = has('win32') || has('win64') || has('win95') || has('win16')
let s:_conda_root = ''


"----------------------------------------------------------------------
" guess conda root
"----------------------------------------------------------------------
function! s:guess_root() abort
	let p = $HOME . '/.conda/environments.txt'
	if !filereadable(p) 
		return ''
	endif
	let lines = readfile(p)
	for line in lines
		let line = substitute(line, '\s*#.*$', '', '')
		let line = substitute(line, '\s*$', '', '')
		if line == ''
			continue
		endif
		let text = fnamemodify(line, ':h')
		if text !~ 'envs$'
			continue
		endif
		let text = fnamemodify(text, ':h')
		if !isdirectory(text)
			continue
		endif
		if s:windows
			if !executable(text . '\Scripts\conda.exe')
				continue
			elseif !executable(text . '\python.exe')
				continue
			endif
		else
			if !executable(text . '/bin/conda')
				continue
			elseif !executable(text . '/bin/python')
				continue
			endif
		endif
		return text
	endfor
	return ''
endfunc


"----------------------------------------------------------------------
" get miniconda installation root
"----------------------------------------------------------------------
function! s:installation_root() abort
	if exists('g:conda_root')
		return g:conda_root
	elseif s:_conda_root != ''
		return s:_conda_root
	elseif exists('$CONDA_ROOT')
		if isdirectory($CONDA_ROOT)
			let s:_conda_root = $CONDA_ROOT
			return s:_conda_root
		endif
	endif
	let test = []
	if s:windows
		call add(test, $HOME . '\miniconda3')
		call add(test, 'C:\ProgramData\miniconda3')
		call add(test, 'C:\Miniconda3')
		call add(test, 'D:\Dev\MiniConda3')
		call add(test, $HOME . '\miniforge3')
		call add(test, 'C:\ProgramData\miniforge3')
		call add(test, 'C:\Miniforge3')
		call add(test, 'D:\Dev\MiniForge3')
	else
		call add(test, $HOME . '/miniconda3')
		call add(test, '/usr/local/miniconda3')
		call add(test, '/usr/local/app/miniconda3')
		call add(test, '/usr/local/opt/miniconda3')
		call add(test, '/home/data/app/miniconda3')
		call add(test, '/home/data/miniconda3')
		call add(test, $HOME . '/miniforge3')
		call add(test, '/usr/local/miniforge3')
		call add(test, '/usr/local/app/miniforge3')
		call add(test, '/usr/local/opt/miniforge3')
		call add(test, '/home/data/app/miniforge3')
		call add(test, '/home/data/miniforge3')
	endif
	for t in test
		if isdirectory(t)
			let s:_conda_root = t
			break
		endif
	endfor
	if s:_conda_root == ''
		let s:_conda_root = s:guess_root()
	endif
	return s:_conda_root
endfunc


"----------------------------------------------------------------------
" get conda root
"----------------------------------------------------------------------
function! module#conda#root() abort
	let root = s:installation_root()
	if root == ''
		return ''
	endif
	let root = asclib#path#normalize(root)
	if s:windows
		let root = substitute(root, '\/', '\\', 'g')
	endif
	return root
endfunc


"----------------------------------------------------------------------
" get current environtment
"----------------------------------------------------------------------
function! module#conda#current() abort
	if exists('$CONDA_DEFAULT_ENV')
		return $CONDA_DEFAULT_ENV
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get environment infomation
"----------------------------------------------------------------------
function! module#conda#info(envname) abort
	let root = module#conda#root()
	let name = (a:envname != '')? a:envname : module#conda#current()
	let item = {}
	let item.root = root
	if root == ''
		return v:null
	elseif name == ''
		return v:null
	endif
	if s:windows
		let item.prefix = root . '\envs\' . name
	else
		let item.prefix = root . '/envs/' . name
	endif
	if !isdirectory(item.prefix)
		return v:null
	endif
	let item.current = name
	let item.CONDA_PREFIX = item.prefix
	let item.CONDA_PROMPT_MODIFIER = '(' . name . ') '
	let item.CONDA_SHLVL = '1'
	if s:windows
		let item.CONDA_EXE = root . '\Scripts\conda.exe'
		let item.CONDA_PYTHON_EXE = root . '\python.exe'
	else
		let item.CONDA_EXE = root . '/bin/conda'
		let item.CONDA_PYTHON_EXE = root . '/bin/python'
	endif
	if !executable(item.CONDA_EXE)
		return v:null
	elseif !executable(item.CONDA_PYTHON_EXE)
		return v:null
	endif
	let item.PATH = []
	if s:windows
		call add(item.PATH, item.prefix)
		call add(item.PATH, item.prefix . '\Library\mingw-w64\bin')
		call add(item.PATH, item.prefix . '\Library\usr\bin')
		call add(item.PATH, item.prefix . '\Library\bin')
		call add(item.PATH, item.prefix . '\Scripts')
		call add(item.PATH, item.prefix . '\bin')
		call add(item.PATH, root . '\condabin')
	else
		call add(item.PATH, item.prefix . '/bin')
		call add(item.PATH, root . '/condabin')
	endif
	return item
endfunc


"----------------------------------------------------------------------
" list available conda environments
"----------------------------------------------------------------------
function! module#conda#list() abort
	let root = module#conda#root()
	let items = []
	if root == ''
		return items
	endif
	let envs = asclib#path#join(root, 'envs')
	for name in asclib#path#list(envs)
		let p = asclib#path#join(envs, name)
		if isdirectory(p)
			if s:windows
				let t = asclib#path#join(p, 'python.exe')
			else
				let t = asclib#path#join(p, 'bin/python')
			endif
			if executable(t)
				call add(items, name)
			endif
		endif
	endfor
	return items
endfunc


"----------------------------------------------------------------------
" deactivate
"----------------------------------------------------------------------
function! module#conda#deactivate() abort
	let root = module#conda#root()
	let sep = (s:windows != 0)? ';' : ':'
	if root == ''
		call asclib#common#errmsg('conda not found')
		return -1
	endif
	unlet $CONDA_DEFAULT_ENV
	unlet $CONDA_PREFIX
	unlet $CONDA_PROMPT_MODIFIER
	unlet $CONDA_SHLVL
	unlet $CONDA_EXE
	unlet $CONDA_PYTHON_EXE
	let paths = []
	for path in split($PATH, sep)
		if asclib#path#contains(root, path) == 0
			if !asclib#path#equal(root, path)
				call add(paths, path)
			endif
		endif
	endfor
	let $PATH = join(paths, sep)
	if s:windows
		unlet $SSL_CERT_FILE
		unlet $__CONDA_OPENSLL_CERT_FILE_SET
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" activate conda environment
"----------------------------------------------------------------------
function! module#conda#activate(name) abort
	let root = module#conda#root()
	let sep = (s:windows)? ';' : ':'
	if root == ''
		call asclib#common#errmsg('conda not found')
		return -1
	endif
	let info = module#conda#info(a:name)
	if type(info) == type(v:null)
		call asclib#common#errmsg('conda environment not found:', a:name)
		return -2
	endif
	silent call module#conda#deactivate()
	let $CONDA_DEFAULT_ENV = info.current
	let $CONDA_PREFIX = info.CONDA_PREFIX
	let $CONDA_PROMPT_MODIFIER = info.CONDA_PROMPT_MODIFIER
	let $CONDA_SHLVL = info.CONDA_SHLVL
	let $CONDA_EXE = info.CONDA_EXE
	let $CONDA_PYTHON_EXE = info.CONDA_PYTHON_EXE
	let path = join(info.PATH, sep)
	let $PATH = path . sep . $PATH
	if s:windows
		let cert = info.prefix . '\Library\ssl\cacert.pem'
		if filereadable(cert)
			let $SSL_CERT_FILE = cert
			let $__CONDA_OPENSLL_CERT_FILE_SET = "1"
		endif
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" complete
"----------------------------------------------------------------------
function! module#conda#complete(ArgLead, CmdLine, CursorPos) abort
	let keys = module#conda#list()
	return asclib#common#complete(a:ArgLead, a:CmdLine, a:CursorPos, keys)
endfunc


