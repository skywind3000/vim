if exists('b:ftplugin_minic')
	finish
endif

let b:ftplugin_minic = 1

if !exists('g:ftplugin_init_splint')
	if get(g:, 'ale_enabled', 0) != 0
		IncScript site/opt/ale_splint.vim
		let g:ftplugin_init_splint = 1
	endif
endif

" IncScript site/opt/ale_cppcheck.vim

setlocal commentstring=//\ %s
setlocal comments-=:// comments+=:///,://

let b:commentary_format = "// %s"


