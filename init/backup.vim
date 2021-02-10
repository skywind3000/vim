function! Backup_Directory()
	set backup
	set writebackup
	set backupdir=~/.vim/tmp
	set backupext=.bak
	set noswapfile
	set noundofile
	let l:path = expand('~/.vim/tmp')
	try
		silent call mkdir(l:path, "p", 0755)
	catch /^Vim\%((\a\+)\)\=:E/
	finally
	endtry
endfunc




