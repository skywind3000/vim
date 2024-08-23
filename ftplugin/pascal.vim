if exists('b:ftplugin_inited')
	if get(b:, 'did_ftplugin', 0) == 2
		finish
	endif
endif

let b:ftplugin_inited = 1

" prevent vim-plug set ft=? twice
if exists('b:did_ftplugin')
	let b:did_ftplugin = 2
endif

setlocal shiftwidth=2
setlocal tabstop=2
setlocal sts=2
setlocal expandtab

compiler fpc

let b:cursorword = 1


