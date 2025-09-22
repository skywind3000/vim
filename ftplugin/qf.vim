"======================================================================
"
" qf.vim - quickfix enhancement
"
" Created by skywind on 2024/03/08
" Last Modified: 2024/03/08 17:39:11
"
"======================================================================


"----------------------------------------------------------------------
" context menu
"----------------------------------------------------------------------
let g:context_menu_quickfix = [
			\ ["&Preview\tp", 'call quickui#tools#preview_quickfix()'],
			\ ["&Filter\tx", "call module#quickfix#filter()"],
			\ ["&Convert to GBK\tc", "call module#quickfix#iconv('gbk')"],
			\ ["&Clear All", 'call setqflist([])'],
			\ ["--", ],
			\ ["&Close\tq", 'close'],
			\ ]


"----------------------------------------------------------------------
" local mapping
"----------------------------------------------------------------------
nnoremap <silent><buffer>K :call quickui#tools#clever_context('qf', g:context_menu_quickfix, {})<cr>

nnoremap <silent><buffer> p :call quickui#tools#preview_quickfix()<cr>
nnoremap <silent><buffer> P :PreviewClose<cr>
nnoremap <silent><buffer> q :close<cr>
setlocal nonumber

nnoremap <silent><buffer> x :call module#quickfix#filter()<cr>
nnoremap <silent><buffer> c :call module#quickfix#iconv('gbk')<cr>
nnoremap <silent><buffer> <s-f10> :call module#quickfix#filter()<cr>

