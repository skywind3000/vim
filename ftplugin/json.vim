if exists('b:ftplugin_init_json')
	finish
endif

let b:ftplugin_init_json = 1

setlocal formatprg=python\ -m\ json.tool


