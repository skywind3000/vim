
" root markers used to locate project
if !exists('g:projectile#marker')
	let g:projectile#marker = '.svn,.git,.projectile'
endif

" returns nearest parent directory contains one of the markers
function! projectile#find_root(name)
	let name = fnamemodify((a:name != '')? a:name : bufname(), ':p')
	let finding = ''
	" iterate all markers
	for marker in split(g:projectile#marker, ',')
		if marker != ''
			" search as a file
			let x = findfile(marker, name . '/;')
			let x = (x == '')? '' : fnamemodify(x, ':p:h')
			" search as a directory
			let y = finddir(marker, name . '/;')
			let y = (y == '')? '' : fnamemodify(y, ':p:h:h')
			" which one is the nearest directory ?
			let z = (strchars(x) > strchars(y))? x : y
			" keep the nearest one in finding
			let finding = (strchars(z) > strchars(finding))? z : finding
		endif
	endfor
	return (finding == '')? '' : fnamemodify(finding, ':p')
endfunc


" returns nearest parent directory contains one of the markers
" if matching failed, returns the directory containing the file
function! projectile#find_home(name)
	let name = fnamemodify((a:name != '')? a:name : bufname(), ':p')
	let path = projectile#find_root(name)
	if path != ''
		return path
	else
		return isdirectory(name)? name : fnamemodify(name, ':h')
	endif
endfunc


" project-wide grep
function! projectile#grep(what)
	let home = projectile#find_home('')
	if home != ''
		exec "vimgrep /" . a:what . "/g " . fnameescape(home) . '**/*'
	endif
endfunc

" goto project
function! projectile#go_home()
	let home = projectile#find_home('')
	if home != ''
		exec "e " . fnameescape(home)
	endif
endfunc


