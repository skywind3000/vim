"----------------------------------------------------------------------
" guard: take care vim-plug call setfiletype multiple times
"----------------------------------------------------------------------
if exists('b:ftplugin_init_cpp')
	finish
endif

let b:ftplugin_init_cpp = 1

setlocal commentstring=//\ %s
let b:commentary_format = "// %s"




