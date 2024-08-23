" vim: set ts=4 sw=4 tw=80 ft=vim noet :
"======================================================================
"
" altmeta.vim - Fix key encodings for console Vim.
"
" Author: drmikehenry 2021
" Originate: https://github.com/drmikehenry/vim-fixkey
"
" Modified by skywind on 2022/09/01
" Last Modified: 2022/09/01 17:01
"
"======================================================================

" skip for GVim / NeoVim
if has('gui_running') || has('nvim') || exists('g:altmeta_loaded')
	finish
endif

" let g:altmeta_loaded = 1

" Save 'cpoptions' and set Vim default to enable line continuations.
let s:save_cpoptions = &cpoptions
set cpoptions&vim

function! s:set_key(key, keyCode)
	if get(g:, 'altmeta_skip_meta', 0) == 0
		execute "set " . a:key . "=" . a:keyCode
	endif
endfunc

function! s:map_key(key, value)
	if get(g:, 'altmeta_skip_meta', 0) == 0
		execute "map  " . a:key . " " . a:value
		execute "map! " . a:key . " " . a:value
	endif
endfunc

let s:fn_num_spare_keys = 50
let s:fn_spare_keys_used = 0

" Allocate a new key, set it to use the passed-in keyCode, then map it to
" the passed-in key.
" New keys are taken from <F13> through <F37> and <S-F13> through <S-F37>,
" for a total of 50 keys.
function! s:set_newkey(key, keyCode)
	if get(g:, 'altmeta_skip_meta', 0) == 0
		if s:fn_spare_keys_used >= s:fn_num_spare_keys
			echohl WarningMsg
			echomsg "Unable to map " . a:key . ": ran out of spare keys"
			echohl None
			return
		endif
		let fn = s:fn_spare_keys_used
		let half = s:fn_num_spare_keys / 2
		let shift = ""
		if fn >= half
			let fn -= half
			let shift = "S-"
		endif
		let newKey = "<" . shift . "F" . (13 + fn) . ">"
		call s:set_key(newKey, a:keyCode)
		call s:map_key(newKey, a:key)
		let s:fn_spare_keys_used += 1
	endif
endfunc

function! s:unset_key(key)
	try
		execute "set <" . a:key . ">="
	catch /E518/
		" Ignore unknown keys.
	endtry
endfunc

function! s:init_meta_numbers()
	let c = '0'
	while c <= '9'
		call s:set_key("<M-" .  c . ">", "\e" . c)
		let c = nr2char(char2nr(c) + 1)
	endwhile
endfunc

function! s:reset_meta_numbers()
	let c = '0'
	while c <= '9'
		call s:set_key("<M-" .  c . ">", nr2char(char2nr(c)  + 0x80))
		let c = nr2char(char2nr(c) + 1)
	endwhile
endfunc

function! s:init_meta_shift_numbers()
	for c in split('!@#$%^&*()', '\zs')
		if c == '@'
			" For some reason, M-@ is special in console Vim.
			" See https://github.com/vim/vim/issues/5759 for some details.
			call s:set_newkey("<M-" . c . ">", "\e" . c)
		else
			call s:set_key("<M-" . c . ">", "\e" . c)
		endif
		" On XTerm with modifyOtherKeys in use, keys like <M-!> are recognized
		" as <M-S-!> (with a redundant shift modifier).  Map these back to
		" their canonical form.
		execute 'map <m-s-' . c . '> <m-' . c . '>'
		execute 'map! <m-s-' . c . '> <m-' . c . '>'
	endfor
endfunc

function! s:reset_meta_shift_numbers()
	for c in split('!@#$%^&*()', '\zs')
		call s:set_key("<M-" . c . ">", nr2char(char2nr(c)  + 0x80))
	endfor
endfunc

function! s:init_meta_letters()
	let c = 'a'
	while c <= 'z'
		let uc = toupper(c)
		call s:set_key("<M-" .  c . ">", "\e" . c)
		" Since many keycodes have "\eO" in them, we can't use "\eO" for <M-O>.
		if uc != 'O'
			call s:set_key("<M-" . uc . ">", "\e" . uc)
		endif
		let c = nr2char(char2nr(c) + 1)
	endwhile
endfunc

function! s:reset_meta_letters()
	let c = 'a'
	while c <= 'z'
		let uc = toupper(c)
		call s:set_key("<M-" .  c . ">", nr2char(char2nr(c)  + 0x80))
		if uc != 'O'
			call s:set_key("<M-" . uc . ">", nr2char(char2nr(uc) + 0x80))
		endif
		let c = nr2char(char2nr(c) + 1)
	endwhile
endfunc

function! s:init_meta_marks()
	let c1 = [',', '.', '/', ';', '{', '}']
	let c2 = ['?', ':', '-', '_', '+', '=', "'"]
	for c in c1 + c2
		call s:set_key("<M-" . c . ">", "\e" . c)
	endfor
endfunc

function! s:unset_function_keys()
	let n = 1
	while n <= 37
		if n <= 4
			call s:unset_key("xF" . n)
		endif
		if n <= 12
			call s:unset_key("S-F" . n)
		endif
		call s:unset_key("F" . n)
		let n = n + 1
	endwhile
endfunc

function! s:init_xterm_f1_to_f4()
	call s:set_key("<F1>", "\e[1;*P")
	call s:set_key("<F2>", "\e[1;*Q")
	call s:set_key("<F3>", "\e[1;*R")
	call s:set_key("<F4>", "\e[1;*S")
endfunc

function! s:init_vt100_extra_f1_to_f4()
	call s:set_key("<xF1>", "\eO*P")
	call s:set_key("<xF2>", "\eO*Q")
	call s:set_key("<xF3>", "\eO*R")
	call s:set_key("<xF4>", "\eO*S")
endfunc

function! s:init_xterm_function_keys()
	call s:init_xterm_f1_to_f4()
	call s:init_vt100_extra_f1_to_f4()
	call s:set_key("<F5>",  "\e[15;*~")
	call s:set_key("<F6>",  "\e[17;*~")
	call s:set_key("<F7>",  "\e[18;*~")
	call s:set_key("<F8>",  "\e[19;*~")
	call s:set_key("<F9>",  "\e[20;*~")
	call s:set_key("<F10>", "\e[21;*~")
	call s:set_key("<F11>", "\e[23;*~")
	call s:set_key("<F12>", "\e[24;*~")
endfunc

function! s:init_xterm_home_end()
	call s:set_key("<Home>",  "\e[1;*H")
	call s:set_key("<End>",   "\e[1;*F")
endfunc

function! s:init_vt100_extra_home_end()
	call s:set_key("<xHome>", "\eO*H")
	call s:set_key("<xEnd>",  "\eO*F")
endfunc

function! s:init_xterm_arrows()
	call s:set_key("<Up>",     "\e[1;*A")
	call s:set_key("<Down>",   "\e[1;*B")
	call s:set_key("<Left>",   "\e[1;*D")
	call s:set_key("<Right>",  "\e[1;*C")
endfunc

function! s:init_vt100_extra_arrows()
	" Oddly, Vim sets <Up> to \eO*A and <xUp> to \e[1;*A, which seems
	" backward compared to <F1>=\e[1;*P and <xF1>=\eO*P.  This seems
	" to cause trouble with Konsole's use of these arrow keys.  Switching
	" to the vt100-compatible keycodes on <xArrows> allows Konsole
	" to use these codes directly.
	call s:set_key("<xUp>",    "\eO*A")
	call s:set_key("<xDown>",  "\eO*B")
	call s:set_key("<xLeft>",  "\eO*D")
	call s:set_key("<xRight>", "\eO*C")
endfunc

function! s:init_xterm_navigation_keys()
	call s:init_xterm_home_end()
	call s:init_vt100_extra_home_end()
	call s:init_xterm_arrows()
	call s:init_vt100_extra_arrows()
endfunc

function! s:init_xterm_keys()
	call s:init_meta_numbers()
	call s:init_meta_shift_numbers()
	call s:init_meta_letters()
	call s:init_xterm_function_keys()
	call s:init_xterm_navigation_keys()

	" In case this is actually konsole:
	call s:set_newkey("<S-Enter>", "\eOM")
	" For both xterm and konsole.
	call s:set_key("<M-Enter>", "\e\r")
endfunc

function! s:init_gnome_terminal_keys()
	call s:init_meta_numbers()
	call s:init_meta_shift_numbers()
	call s:init_meta_letters()
	call s:init_xterm_function_keys()
	call s:init_xterm_navigation_keys()
	" Can't get this to work:
	" call s:set_key("<M-Enter>", "\e\r")
endfunc

function! s:init_konsole_keys()
	call s:init_meta_numbers()
	call s:init_meta_shift_numbers()
	call s:init_meta_letters()
	call s:init_xterm_function_keys()
	call s:init_xterm_navigation_keys()
	call s:set_newkey("<S-Enter>", "\eOM")
	call s:set_key("<M-Enter>", "\e\r")
endfunc

function! s:init_linux_keys()
	call s:init_meta_numbers()
	call s:init_meta_shift_numbers()
	call s:init_meta_letters()
	call s:set_key("<F1>",  "\e[[A")
	call s:set_key("<F2>",  "\e[[B")
	call s:set_key("<F3>",  "\e[[C")
	call s:set_key("<F4>",  "\e[[D")
	call s:set_key("<F5>",  "\e[[E")
	call s:set_key("<F6>",  "\e[17~")
	call s:set_key("<F7>",  "\e[18~")
	call s:set_key("<F8>",  "\e[19~")
	call s:set_key("<F9>",  "\e[20~")
	call s:set_key("<F10>", "\e[21~")
	call s:set_key("<F11>", "\e[23~")
	call s:set_key("<F12>", "\e[24~")
	call s:set_newkey("<S-F1>", "\e[25~")
	call s:set_newkey("<S-F2>", "\e[26~")
	call s:set_newkey("<S-F3>", "\e[28~")
	call s:set_newkey("<S-F4>", "\e[29~")
	call s:set_newkey("<S-F5>", "\e[31~")
	call s:set_newkey("<S-F6>", "\e[32~")
	call s:set_newkey("<S-F7>", "\e[33~")
	call s:set_newkey("<S-F8>", "\e[34~")
	call s:set_key("<M-Enter>", "\e\r")
endfunc

function! s:init_putty_f1_to_f12()
	call s:set_key("<F1>",  "\e[11~")
	call s:set_key("<F2>",  "\e[12~")
	call s:set_key("<F3>",  "\e[13~")
	call s:set_key("<F4>",  "\e[14~")
	call s:set_key("<F5>",  "\e[15~")
	call s:set_key("<F6>",  "\e[17~")
	call s:set_key("<F7>",  "\e[18~")
	call s:set_key("<F8>",  "\e[19~")
	call s:set_key("<F9>",  "\e[20~")
	call s:set_key("<F10>", "\e[21~")
	call s:set_key("<F11>", "\e[23~")
	call s:set_key("<F12>", "\e[24~")
endfunc

function! s:init_putty_shift_f3_to_f10()
	call s:set_newkey("<S-F3>",  "\e[25~")
	call s:set_newkey("<S-F4>",  "\e[26~")
	call s:set_newkey("<S-F5>",  "\e[28~")
	call s:set_newkey("<S-F6>",  "\e[29~")
	call s:set_newkey("<S-F7>",  "\e[31~")
	call s:set_newkey("<S-F8>",  "\e[32~")
	call s:set_newkey("<S-F9>",  "\e[33~")
	call s:set_newkey("<S-F10>", "\e[34~")
endfunc

function! s:init_putty_meta_f1_to_f12()
	call s:set_newkey("<M-F1>",  "\e\e[11~")
	call s:set_newkey("<M-F2>",  "\e\e[12~")
	call s:set_newkey("<M-F3>",  "\e\e[13~")
	call s:set_newkey("<M-F4>",  "\e\e[14~")
	call s:set_newkey("<M-F5>",  "\e\e[15~")
	call s:set_newkey("<M-F6>",  "\e\e[17~")
	call s:set_newkey("<M-F7>",  "\e\e[18~")
	call s:set_newkey("<M-F8>",  "\e\e[19~")
	call s:set_newkey("<M-F9>",  "\e\e[20~")
	call s:set_newkey("<M-F10>", "\e\e[21~")
	call s:set_newkey("<M-F11>", "\e\e[23~")
	call s:set_newkey("<M-F12>", "\e\e[24~")
endfunc

function! s:init_putty_meta_shift_f3_to_f10()
	call s:set_newkey("<M-S-F3>",  "\e\e[25~")
	call s:set_newkey("<M-S-F4>",  "\e\e[26~")
	call s:set_newkey("<M-S-F5>",  "\e\e[28~")
	call s:set_newkey("<M-S-F6>",  "\e\e[29~")
	call s:set_newkey("<M-S-F7>",  "\e\e[31~")
	call s:set_newkey("<M-S-F8>",  "\e\e[32~")
	call s:set_newkey("<M-S-F9>",  "\e\e[33~")
	call s:set_newkey("<M-S-F10>", "\e\e[34~")
endfunc

function! s:init_putty_ctrl_arrows()
	call s:set_newkey("<C-Up>",    "\eOA")
	call s:set_newkey("<C-Down>",  "\eOB")
	call s:set_newkey("<C-Left>",  "\eOD")
	call s:set_newkey("<C-Right>", "\eOC")
endfunc

function! s:init_putty_meta_arrows()
	call s:set_newkey("<M-Up>",    "\e\e[A")
	call s:set_newkey("<M-Down>",  "\e\e[B")
	call s:set_newkey("<M-Left>",  "\e\e[D")
	call s:set_newkey("<M-Right>", "\e\e[C")
endfunc

function! s:init_putty_meta_ctrl_arrows()
	call s:set_newkey("<M-C-Up>",    "\e\eOA")
	call s:set_newkey("<M-C-Down>",  "\e\eOB")
	call s:set_newkey("<M-C-Left>",  "\e\eOD")
	call s:set_newkey("<M-C-Right>", "\e\eOC")
endfunc

function! s:init_putty_meta_home_end()
	call s:set_newkey("<M-Home>",    "\e\e[1~")
	call s:set_newkey("<M-End>",     "\e\e[4~")
endfunc

function! s:init_putty_keys()
	call s:unset_function_keys()
	call s:init_meta_numbers()
	call s:init_meta_shift_numbers()
	call s:init_meta_letters()
	call s:init_putty_f1_to_f12()
	call s:init_putty_shift_f3_to_f10()
	call s:init_putty_meta_f1_to_f12()
	call s:init_putty_meta_shift_f3_to_f10()
	call s:init_putty_ctrl_arrows()
	call s:init_putty_meta_arrows()
	call s:init_putty_meta_ctrl_arrows()
	call s:init_putty_meta_home_end()
	call s:set_key("<M-Enter>", "\e\r")
endfunc

function! s:init_putty_sco_f1_to_f12()
	call s:set_key("<F1>",  "\e[M")
	call s:set_key("<F2>",  "\e[N")
	call s:set_key("<F3>",  "\e[O")
	call s:set_key("<F4>",  "\e[P")
	call s:set_key("<F5>",  "\e[Q")
	call s:set_key("<F6>",  "\e[R")
	call s:set_key("<F7>",  "\e[S")
	call s:set_key("<F8>",  "\e[T")
	call s:set_key("<F9>",  "\e[U")
	call s:set_key("<F10>", "\e[V")
	call s:set_key("<F11>", "\e[W")
	call s:set_key("<F12>", "\e[X")
endfunc

function! s:init_putty_sco_shift_f1_to_f12()
	call s:set_newkey("<S-F1>",  "\e[Y")
	call s:set_newkey("<S-F2>",  "\e[Z")
	call s:set_newkey("<S-F3>",  "\e[a")
	call s:set_newkey("<S-F4>",  "\e[b")
	call s:set_newkey("<S-F5>",  "\e[c")
	call s:set_newkey("<S-F6>",  "\e[d")
	call s:set_newkey("<S-F7>",  "\e[e")
	call s:set_newkey("<S-F8>",  "\e[f")
	call s:set_newkey("<S-F9>",  "\e[g")
	call s:set_newkey("<S-F10>", "\e[h")
	call s:set_newkey("<S-F11>", "\e[i")
	call s:set_newkey("<S-F12>", "\e[j")
endfunc

function! s:init_putty_sco_ctrl_f1_to_f12()
	call s:set_newkey("<C-F1>",  "\e[k")
	call s:set_newkey("<C-F2>",  "\e[l")
	call s:set_newkey("<C-F3>",  "\e[m")
	call s:set_newkey("<C-F4>",  "\e[n")
	call s:set_newkey("<C-F5>",  "\e[o")
	call s:set_newkey("<C-F6>",  "\e[p")
	call s:set_newkey("<C-F7>",  "\e[q")
	call s:set_newkey("<C-F8>",  "\e[r")
	call s:set_newkey("<C-F9>",  "\e[s")
	call s:set_newkey("<C-F10>", "\e[t")
	call s:set_newkey("<C-F11>", "\e[u")
	call s:set_newkey("<C-F12>", "\e[v")
endfunc

function! s:init_putty_sco_ctrl_shift_f1_to_f12()
	call s:set_newkey("<C-S-F1>",  "\e[w")
	call s:set_newkey("<C-S-F2>",  "\e[x")
	call s:set_newkey("<C-S-F3>",  "\e[y")
	call s:set_newkey("<C-S-F4>",  "\e[z")
	call s:set_newkey("<C-S-F5>",  "\e[@")
	call s:set_newkey("<C-S-F6>",  "\e[[")
	call s:set_newkey("<C-S-F7>",  "\e[\\")
	call s:set_newkey("<C-S-F8>",  "\e[]")
	call s:set_newkey("<C-S-F9>",  "\e[^")
	call s:set_newkey("<C-S-F10>", "\e[_")
	call s:set_newkey("<C-S-F11>", "\e[`")
	call s:set_newkey("<C-S-F12>", "\e[{")
endfunc

function! s:init_putty_sco_meta_f1_to_f12()
	call s:set_newkey("<M-F1>",  "\e\e[M")
	call s:set_newkey("<M-F2>",  "\e\e[N")
	call s:set_newkey("<M-F3>",  "\e\e[O")
	call s:set_newkey("<M-F4>",  "\e\e[P")
	call s:set_newkey("<M-F5>",  "\e\e[Q")
	call s:set_newkey("<M-F6>",  "\e\e[R")
	call s:set_newkey("<M-F7>",  "\e\e[S")
	call s:set_newkey("<M-F8>",  "\e\e[T")
	call s:set_newkey("<M-F9>",  "\e\e[U")
	call s:set_newkey("<M-F10>", "\e\e[V")
	call s:set_newkey("<M-F11>", "\e\e[W")
	call s:set_newkey("<M-F12>", "\e\e[X")
endfunc

function! s:init_putty_sco_meta_home_end()
	call s:set_newkey("<M-Home>",    "\e\e[H")
	call s:set_newkey("<M-End>",     "\e\e[F")
endfunc

function! s:init_putty_sco_keys()
	call s:unset_function_keys()
	call s:init_meta_numbers()
	call s:init_meta_shift_numbers()
	call s:init_meta_letters()
	call s:init_putty_sco_f1_to_f12()
	call s:init_putty_sco_shift_f1_to_f12()
	call s:init_putty_sco_ctrl_f1_to_f12()
	" Not working yet (seems like too many "setNewKey" calls):
	"call s:init_putty_sco_ctrl_shift_f1_to_f12()
	call s:init_putty_sco_meta_f1_to_f12()
	call s:init_putty_ctrl_arrows()
	call s:init_putty_meta_arrows()
	call s:init_putty_meta_ctrl_arrows()
	call s:init_putty_sco_meta_home_end()
	call s:set_key("<M-Enter>", "\e\r")
endfunc

function! s:init_rxvt_shift_f3_to_f12()
	call s:set_key("<S-F3>",  "\e[25~")
	call s:set_key("<S-F4>",  "\e[26~")
	call s:set_key("<S-F5>",  "\e[28~")
	call s:set_key("<S-F6>",  "\e[29~")
	call s:set_key("<S-F7>",  "\e[31~")
	call s:set_key("<S-F8>",  "\e[32~")
	call s:set_key("<S-F9>",  "\e[33~")
	call s:set_key("<S-F10>", "\e[34~")
	call s:set_key("<S-F11>", "\e[23$")
	call s:set_key("<S-F12>", "\e[24$")
endfunc

function! s:init_rxvt_ctrl_f1_to_f12()
	call s:set_newkey("<C-F1>",  "\e[11^")
	call s:set_newkey("<C-F2>",  "\e[12^")
	call s:set_newkey("<C-F3>",  "\e[13^")
	call s:set_newkey("<C-F4>",  "\e[14^")
	call s:set_newkey("<C-F5>",  "\e[15^")
	call s:set_newkey("<C-F6>",  "\e[17^")
	call s:set_newkey("<C-F7>",  "\e[18^")
	call s:set_newkey("<C-F8>",  "\e[19^")
	call s:set_newkey("<C-F9>",  "\e[20^")
	call s:set_newkey("<C-F10>", "\e[21^")
	call s:set_newkey("<C-F11>", "\e[23^")
	call s:set_newkey("<C-F12>", "\e[24^")
endfunc

function! s:init_rxvt_meta_f1_to_f12()
	call s:set_newkey("<M-F1>",  "\e\e[11~")
	call s:set_newkey("<M-F2>",  "\e\e[12~")
	call s:set_newkey("<M-F3>",  "\e\e[13~")
	call s:set_newkey("<M-F4>",  "\e\e[14~")
	call s:set_newkey("<M-F5>",  "\e\e[15~")
	call s:set_newkey("<M-F6>",  "\e\e[17~")
	call s:set_newkey("<M-F7>",  "\e\e[18~")
	call s:set_newkey("<M-F8>",  "\e\e[19~")
	call s:set_newkey("<M-F9>",  "\e\e[20~")
	call s:set_newkey("<M-F10>", "\e\e[21~")
	call s:set_newkey("<M-F11>", "\e\e[23~")
	call s:set_newkey("<M-F12>", "\e\e[24~")
endfunc

function! s:init_rxvt_shift_arrows()
	call s:set_key("<S-Up>",    "\e[a")
	call s:set_key("<S-Down>",  "\e[b")
	call s:set_key("<S-Left>",  "\e[d")
	call s:set_key("<S-Right>", "\e[c")
endfunc

function! s:init_rxvt_ctrl_arrows()
	call s:set_newkey("<C-Up>",    "\eOa")
	call s:set_newkey("<C-Down>",  "\eOb")
	call s:set_newkey("<C-Left>",  "\eOd")
	call s:set_newkey("<C-Right>", "\eOc")
endfunc

function! s:init_rxvt_meta_arrows()
	call s:set_newkey("<M-Up>",    "\e\eOA")
	call s:set_newkey("<M-Down>",  "\e\eOB")
	call s:set_newkey("<M-Left>",  "\e\eOD")
	call s:set_newkey("<M-Right>", "\e\eOC")
endfunc

function! s:init_rxvt_meta_shift_arrows()
	call s:set_newkey("<M-S-Up>",    "\e\e[a")
	call s:set_newkey("<M-S-Down>",  "\e\e[b")
	call s:set_newkey("<M-S-Left>",  "\e\e[d")
	call s:set_newkey("<M-S-Right>", "\e\e[c")
endfunc

function! s:init_rxvt_meta_ctrl_arrows()
	call s:set_newkey("<M-C-Up>",    "\e\eOa")
	call s:set_newkey("<M-C-Down>",  "\e\eOb")
	call s:set_newkey("<M-C-Left>",  "\e\eOd")
	call s:set_newkey("<M-C-Right>", "\e\eOc")
endfunc

function! s:init_rxvt_ctrl_home_end()
	call s:set_newkey("<C-Home>",  "\e[7^")
	call s:set_newkey("<C-End>",   "\e[8^")
endfunc

function! s:init_rxvt_ctrl_shift_home_end()
	call s:set_newkey("<C-S-Home>",  "\e[7@")
	call s:set_newkey("<C-S-End>",   "\e[8@")
endfunc

function! s:init_rxvt_meta_home_end()
	call s:set_newkey("<M-Home>",  "\e\e[7~")
	call s:set_newkey("<M-End>",   "\e\e[8~")
endfunc

function! s:init_rxvt_meta_shift_home_end()
	call s:set_newkey("<M-S-Home>",  "\e\e[7$")
	call s:set_newkey("<M-S-End>",   "\e\e[8$")
endfunc

function! s:init_rxvt_meta_ctrl_home_end()
	call s:set_newkey("<M-C-Home>",  "\e\e[7^")
	call s:set_newkey("<M-C-End>",   "\e\e[8^")
endfunc

function! s:init_rxvt_meta_ctrl_shift_home_end()
	call s:set_newkey("<M-C-S-Home>",  "\e\e[7@")
	call s:set_newkey("<M-C-S-End>",   "\e\e[8@")
endfunc

function! s:init_rxvt_keys()
	" <Undo> is \e[26~, which aliases <S-F4>.  Undefine it to avoid conflict.
	set <Undo>=
	" <Help> is \e28~, which aliases <S-F5>.  Undefine it to avoid conflict.
	set <Help>=
	call s:init_meta_numbers()
	call s:init_meta_shift_numbers()
	call s:init_meta_letters()
	call s:init_rxvt_shift_f3_to_f12()
	call s:init_rxvt_ctrl_f1_to_f12()
	call s:init_rxvt_meta_f1_to_f12()
	call s:init_rxvt_shift_arrows()
	call s:init_rxvt_ctrl_arrows()
	call s:init_rxvt_meta_arrows()
	call s:init_rxvt_meta_shift_arrows()
	call s:init_rxvt_meta_ctrl_arrows()
	call s:init_rxvt_ctrl_home_end()
	call s:init_rxvt_ctrl_shift_home_end()
	call s:init_rxvt_meta_home_end()
	call s:init_rxvt_meta_shift_home_end()
	call s:init_rxvt_meta_ctrl_home_end()
	" Not enough mappable keys:
	"call s:init_rxvt_meta_ctrl_shift_home_end()
	call s:set_key("<M-Enter>", "\e\r")
endfunc

function! s:init_screen_extra_home_end()
	" These are the same codes TERM=linux used.
	call s:set_key("<xHome>", "\e[1~")
	call s:set_key("<xEnd>", "\e[4~")
endfunc

function! s:init_screen_compatible_keys()
	call s:init_meta_numbers()
	call s:init_meta_shift_numbers()
	call s:init_meta_letters()
	call s:init_xterm_function_keys()
	call s:init_xterm_home_end()
	call s:init_screen_extra_home_end()
	call s:init_xterm_arrows()
	call s:init_vt100_extra_arrows()
	call s:set_key("<M-Enter>", "\e\r")
	" <S-Enter> works when hosted under konsole.
	call s:set_newkey("<S-Enter>", "\eOM")
endfunc

function! s:init_screen_keys()
	call s:init_screen_compatible_keys()
endfunc

function! s:init_tmux_keys()
	call s:init_screen_compatible_keys()
endfunc

function! AltMeta_Detect()
	if $TERM =~# '^xterm\(-\d*color\)\?$'
		if $COLORTERM == "gnome-terminal"
			let termType = "gnome"
		else
			let termType = "xterm"
		endif

	elseif $TERM =~# '^gnome\(-\d*color\)\?$'
		let termType = "gnome"

	elseif $TERM =~# '^konsole\(-\d*color\)\?$'
		let termType = "konsole"

	elseif $TERM =~# 'linux\(-\d*color\)\?$'
		let termType = "linux"

	elseif $TERM == 'putty-sco'
		let termType = "putty-sco"

	elseif $TERM =~# '^putty\(-\d*color\)\?$'
		let termType = "putty"

	elseif $TERM =~# '^rxvt\(-unicode\)\?\(-\d*color\)\?$'
		let termType = "rxvt"

	elseif $TERM =~# '\v^screen([-.].*)?$'
		let termType = "screen"

	elseif $TERM =~# '\v^tmux(-\d*color|-bce|-it|-s)*$'
		let termType = "tmux"
	else
		let termType = "unknown"
	endif
	return termType
endfunc

function! AltMeta_Setup()
	if !exists('g:altmeta_term_type')
		let g:altmeta_term_type = AltMeta_Detect()
	endif
	if g:altmeta_term_type == '' || g:altmeta_term_type == 'unknown'
		return
	endif

	" Ensure keycode timeouts are enabled.
	set ttimeout
	if $TMUX != ''
		set ttimeoutlen=20
	elseif &ttimeoutlen > 50 || &ttimeoutlen <= 0
		set ttimeoutlen=50
	endif

	if g:altmeta_term_type == 'xterm'
		call s:init_xterm_keys()
	elseif g:altmeta_term_type == 'gnome'
		call s:init_gnome_terminal_keys()
	elseif g:altmeta_term_type == 'konsole'
		call s:init_konsole_keys()
	elseif g:altmeta_term_type == 'linux'
		call s:init_linux_keys()
	elseif g:altmeta_term_type == 'putty-sco'
		call s:init_putty_sco_keys()
	elseif g:altmeta_term_type == 'putty'
		call s:init_putty_keys()
	elseif g:altmeta_term_type == 'rxvt'
		call s:init_rxvt_keys()
	elseif g:altmeta_term_type == 'screen'
		call s:init_screen_keys()
	elseif g:altmeta_term_type == 'tmux'
		call s:init_tmux_keys()
		" When TERM begins with "screen", Vim helpfully sets 'ttymouse' to
		" "xterm".  This same logic is required for tmux to work correctly, but
		" Vim lacks support for it before v8.0.0030.  As a work-around for this
		" problem, we ensure 'ttymouse' is set to Vim's default if it's
		" currently empty (otherwise, we leave it alone).
		if &ttymouse == ''
			set ttymouse=xterm
		endif
	else
		echoerr "Unsupported terminal: g:altmeta_term_type=" . g:altmeta_term_type
		return
	endif
	call s:init_meta_marks()
	if exists('g:altmeta_extension')
		if type(g:altmeta_extension) == type([])
			for n in g:altmeta_extension
				let key = n[0]
				let code = n[1]
				call s:set_newkey(key, code)
			endfor
		endif
	endif
	" echom printf("spared %d/50", s:fn_spare_keys_used)
endfunc

" With newer Xterm, Vim enters an extended negotiation during startup.  First
" Vim queries for Xterm's version and receives the response into v:termresponse.
" When Xterm's patchlevel is 141 or higher, Vim continues querying for Xterm's
" key codes.  These negotiations happen after fixkey.vim is sourced.  With
" Fixkey's mappings in place, Vim misinterprets Xterm's startup responses.  To
" avoid this, Fixkey attempts to delay its setup until after Xterm negotiations
" have completed.

if !exists("g:altmeta_delay")
	let g:altmeta_delay = 0
endif

if g:altmeta_delay == 0
	call AltMeta_Setup()
elseif exists('*timer_start') && g:altmeta_delay > 0
	function! s:setup_callback(timerId)
		call AltMeta_Setup()
	endfunc
	call timer_start(g:altmeta_delay, function('s:setup_callback'))
else
	augroup Fixkey
		autocmd!
		autocmd TermResponse * call AltMeta_Setup()
	augroup END
endif

" Restore saved 'cpoptions'.
let &cpoptions = s:save_cpoptions

