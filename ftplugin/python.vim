if exists('b:ftplugin_init_python')
	finish
endif

let b:ftplugin_init_python = 1

setlocal shiftwidth=4 
setlocal tabstop=4
setlocal expandtab

setlocal omnifunc=python3complete#Complete

