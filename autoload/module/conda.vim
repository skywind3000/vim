"======================================================================
"
" conda.vim - 
"
" Created by skywind on 2025/02/12
" Last Modified: 2025/02/12 22:41:40
"
"======================================================================

let s:windows = has('win32') || has('win64') || has('win95') || has('win16')
let s:_conda_root = ''


"----------------------------------------------------------------------
" get miniconda installation root
"----------------------------------------------------------------------
function! module#conda#root() abort
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
	if s:windows
		if isdirectory($HOME . '\miniconda3')
			let s:_conda_root = $HOME . '\miniconda3'
		elseif isdirectory('C:\ProgramData\miniconda3')
			let s:_conda_root = 'C:\ProgramData\miniconda3'
		elseif isdirectory('C:\Miniconda3')
			let s:_conda_root = 'C:\Miniconda3'
		elseif isdirectory('D:\Dev\MiniConda3')
			let s:_conda_root = 'D:\Dev\MiniConda3'
		endif
	else
		if isdirectory($HOME . '/miniconda3')
			let s:_conda_root = $HOME . '/miniconda3'
		elseif isdirectory('/usr/local/miniconda3')
			let s:_conda_root = '/usr/local/miniconda3'
		elseif isdirectory('/usr/local/app/miniconda3')
			let s:_conda_root = '/usr/local/app/miniconda3'
		elseif isdirectory('/usr/local/opt/miniconda3')
			let s:_conda_root = '/usr/local/opt/miniconda3'
		elseif isdirectory('/home/data/miniconda3')
			let s:_conda_root = '/home/data/miniconda3'
		endif
	endif
	return s:_conda_root
endfunc


"----------------------------------------------------------------------
" get current environtment
"----------------------------------------------------------------------
function! module#conda#conda_current() abort
	if exists('$CONDA_DEFAULT_ENV')
		return $CONDA_DEFAULT_ENV
	endif
	return ''
endfunc


"----------------------------------------------------------------------
" get infomation
"----------------------------------------------------------------------
function! module#conda#conda_info(envname) abort
	let root = module#conda#_conda_root()
	if root == ''
		return 'Conda not found'
	endif
	if envname == ''
		return 'Conda not activated'
	endif

endfunc


