if exists('b:ftplugin_init_go')
	if get(b:, 'did_ftplugin', 0) == 2
		finish
	endif
endif

let b:ftplugin_init_go = 1

" prevent vim-plug set ft=? twice
if exists('b:did_ftplugin')
	let b:did_ftplugin = 2
endif


"----------------------------------------------------------------------
" once initializer
"----------------------------------------------------------------------
if get(s:, 'once', 0) == 0
	let s:once = 1
	let s:has_go = executable('go')
	let s:has_gofmt = executable('gofmt')
	let s:has_goimports = executable('goimports')
endif

if s:has_goimports
	setlocal formatprg=goimports
elseif s:has_gofmt
	setlocal formatprg=gofmt
endif


