
function! s:myfactory()
	let config = {}
	let config.factory1 = {
				\ 'command': ':echo "factory1"',
				\ }
	let config.factory2 = {
				\ 'command': ':echo "factory2"',
				\ }
	let root = asyncrun#current_root()
	if !asclib#path#equal(root, 'c:/share/vim')
		return {}
	endif
	return config
endfunc

let g:asynctasks_factory = [function('s:myfactory')]

