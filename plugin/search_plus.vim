

" Visual mode pressing * or # searches for the current selection
vnoremap <silent> * :<C-u>call EscapedSearch2()<CR>/<C-R>=@/<CR><CR>N
vnoremap <silent> # :<C-u>call EscapedSearch2()<CR>?<C-R>=@/<CR><CR>N


function! EscapedSearch2() range

	" Backup what's in default register
	let l:saved_reg = @"

	" Copy selection
	execute 'normal! vgvy'

	" Escape special chars
	let l:pattern = escape(@", "\\/.*'$^~[]")
	let l:pattern = substitute(l:pattern, "\n$", "", "")

	" Set search
	let @/ = l:pattern

	" Restore default register
	let @" = l:saved_reg

endfunction



