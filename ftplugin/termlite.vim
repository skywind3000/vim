"======================================================================
"
" termlite.vim - 
"
" Created by skywind on 2023/08/03
" Last Modified: 2023/08/03 06:33:11
"
"======================================================================

if &bt != 'terminal'
	finish
endif


"----------------------------------------------------------------------
" basic 
"----------------------------------------------------------------------
tmap <buffer><tab><tab> <c-\><c-n><tab><tab>
tmap <buffer><tab><space> <c-\><c-n><space><space>
tnoremap <buffer><c-g><tab> <tab>
tnoremap <buffer><tab>h <c-\><c-n><c-w>h
tnoremap <buffer><tab>j <c-\><c-n><c-w>j
tnoremap <buffer><tab>k <c-\><c-n><c-w>k
tnoremap <buffer><tab>l <c-\><c-n><c-w>l

if !has('nvim')
	tnoremap <buffer><c-w> <c-_>
	" tnoremap <buffer>: <c-_>:
else
	tnoremap <buffer><c-w> <c-\><c-n><c-w>
	" tnoremap <buffer>: <c-\><c-n>:
endif


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
for i in range(10)
	let n = printf('%d', i == 0? 10 : i)
	exec printf('tnoremap <buffer>\%d <c-\><c-n>%dgt', i, n)
	exec printf('tnoremap <buffer><m-%d> <c-\><c-n>%dgt', i, n)
endfor

for c in ['g', 'w', 's', 'z']
	exec printf('tnoremap <buffer><c-g><c-%s> <c-%s>', c, c)
endfor

for c in ['h', 'j', 'k', 'l', 'H', 'J', 'K', 'L', 'o', 'w', 'v', 's']
	exec printf('tnoremap <buffer><c-w><c-%s> <c-\><c-n><c-w><c-%s>', c, c)
endfor

for c in ['p', '=', ',', '.', '+', '-']
	exec printf('tnoremap <buffer><c-w><c-%s> <c-\><c-n><c-w><c-%s>', c, c)
endfor


"----------------------------------------------------------------------
" auto insert
"----------------------------------------------------------------------
function! s:buffer_enter()
	" unsilent echom "haha1"
	if &bt == 'terminal'
		if &ft == 'termlite'
			if mode() != 't'
				call feedkeys('i')
			endif
		endif
	endif
endfunc


"----------------------------------------------------------------------
" 
"----------------------------------------------------------------------
augroup TermLiteGroup
	au!
	au WinEnter * call s:buffer_enter()
augroup END


