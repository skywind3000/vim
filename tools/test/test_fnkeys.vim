for i in range(12)
	exec printf('nnoremap <buffer> <F%d> :echo "F%d"<CR>', i+1, i+1)
	exec printf('nnoremap <buffer> <s-F%d> :echo "s-F%d"<CR>', i+1, i+1)
	exec printf('nnoremap <buffer> <c-F%d> :echo "c-F%d"<CR>', i+1, i+1)
	exec printf('inoremap <buffer> <F%d> <c-\><c-o>:echo "F%d"<CR>', i+1, i+1)
	exec printf('inoremap <buffer> <s-F%d> <c-\><c-o>:echo "s-F%d"<CR>', i+1, i+1)
	exec printf('inoremap <buffer> <c-F%d> <c-\><c-o>:echo "c-F%d"<CR>', i+1, i+1)
endfor


