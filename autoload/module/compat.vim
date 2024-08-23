"======================================================================
"
" compat.vim - 
"
" Created by skywind on 2023/08/30
" Last Modified: 2023/08/30 15:27:59
"
"======================================================================


"----------------------------------------------------------------------
" jump word
"----------------------------------------------------------------------
function! module#compat#easymotion_word()
	if mapcheck("<plug>(easymotion-bd-w)", 'n') != ''
		call feedkeys("\<plug>(easymotion-bd-w)")
	elseif exists(':HopWord')
		exec 'HopWord'
	else
		if !exists('s:has_stargate')
			if exists('g:stargate_chars')
				let s:has_stargate = 1
			endif
			let hr = findfile('autoload/stargate.vim', &rtp)
			let s:has_stargate = (hr != '')? 1 : 0
		endif
		if s:has_stargate
			call stargate#OKvim('\<')
		endif
	endif
endfunc


