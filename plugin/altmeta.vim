"======================================================================
"
" altmeta.vim - enable alt key in terminal vim as the meta key
"
" Created by skywind on 2020/01/08
" Last Modified: 2020/01/08 21:16:47
"
"======================================================================

" enable alt key in terminal vim
if has('nvim') == 0 && has('gui_running') == 0
	set ttimeout
	if $TMUX != ''
		set ttimeoutlen=30
	elseif &ttimeoutlen > 80 || &ttimeoutlen <= 0
		set ttimeoutlen=80
	endif
	function! s:meta_code(key)
		if get(g:, 'altmeta_skip_meta', 0) == 0
			exec "set <M-".a:key.">=\e".a:key
		endif
	endfunc
	for i in range(10)
		call s:meta_code(nr2char(char2nr('0') + i))
	endfor
	for i in range(26)
		call s:meta_code(nr2char(char2nr('a') + i))
	endfor
	for i in range(15) + range(16, 25)
		call s:meta_code(nr2char(char2nr('A') + i))
	endfor
	for c in [',', '.', '/', ';', '{', '}']
		call s:meta_code(c)
	endfor
	for c in ['?', ':', '-', '_', '+', '=', "'"]
		call s:meta_code(c)
	endfor
	function! s:key_escape(name, code)
		if get(g:, 'altmeta_skip_meta', 0) == 0
			exec "set ".a:name."=\e".a:code
		endif
	endfunc
	let s:array = [')', '!', '@', '#', '$', '%', '^', '&', '*', '(']
	if get(g:, 'altmeta_num_shift', 0) != 0
		for i in range(10)
			call s:key_escape('<m-' . i . '>', s:array[i])
		endfor
	endif
	if get(g:, 'altmeta_ctrl_meta', 0) != 0
		for i in range(26)
			let aa = nr2char(char2nr('a') + i)
			if index(['i', 'j', 'v'], aa) < 0
				exec 'let cc="\<c-' . aa . '>"'
				call s:key_escape('<m-c-' . aa . '>', cc)
			endif
		endfor
	endif
	if get(g:, 'altmeta_skip_fn', 0) == 0
		call s:key_escape('<F1>', 'OP')
		call s:key_escape('<F2>', 'OQ')
		call s:key_escape('<F3>', 'OR')
		call s:key_escape('<F4>', 'OS')
		call s:key_escape('<S-F1>', '[1;2P')
		call s:key_escape('<S-F2>', '[1;2Q')
		call s:key_escape('<S-F3>', '[1;2R')
		call s:key_escape('<S-F4>', '[1;2S')
		call s:key_escape('<S-F5>', '[15;2~')
		call s:key_escape('<S-F6>', '[17;2~')
		call s:key_escape('<S-F7>', '[18;2~')
		call s:key_escape('<S-F8>', '[19;2~')
		call s:key_escape('<S-F9>', '[20;2~')
		call s:key_escape('<S-F10>', '[21;2~')
		call s:key_escape('<S-F11>', '[23;2~')
		call s:key_escape('<S-F12>', '[24;2~')
	endif
endif


