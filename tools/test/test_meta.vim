
for i in range(12)
	let n = i + 1
	let fn = 'F' . (i + 1)
	exec printf("noremap <%s> :echo '%s'<cr>", fn, fn)
	exec printf("noremap <s-%s> :echo 'shift+%s'<cr>", fn, fn)
	exec printf("noremap <c-%s> :echo 'ctrl+%s'<cr>", fn, fn)
	exec printf("noremap <m-%s> :echo 'meta+%s'<cr>", fn, fn)
endfor

for t in ['up', 'down', 'left', 'right']
	exec printf("noremap <s-%s> :echo 'shift+%s'<cr>", t, t)
	exec printf("noremap <c-%s> :echo 'ctrl+%s'<cr>", t, t)
	exec printf("noremap <m-%s> :echo 'meta+%s'<cr>", t, t)
endfor

let skip = ['i', 'j', 'v']

for i in range(26)
	let c = nr2char(char2nr('a') + i)
	let u = toupper(c)
	exec printf("noremap <m-%s> :echo 'meta+%s'<cr>", c, c)
	exec printf("noremap <m-%s> :echo 'meta+shift+%s'<cr>", u, c)
	exec printf("noremap <c-%s> :echo 'ctrl+%s'<cr>", c, c)
	" exec printf("noremap <m-c-%s> :echo 'meta+ctrl+%s'<cr>", c, c)
endfor


let s:array = [')', '!', '@', '#', '$', '%', '^', '&', '*', '(']
for i in range(10)
	exec printf("noremap <m-%d> :echo 'meta+%d'<cr>", i, i)
	exec printf("noremap <m-%s> :echo 'meta+shift+%d'<cr>", s:array[i], i)
endfor


