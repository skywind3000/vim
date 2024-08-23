
"----------------------------------------------------------------------
" ignores
"----------------------------------------------------------------------
let s:ignore = ['.obj', '.so', '.a', '~', '.tmp', '.egg', '.class', '.jar']
let s:ignore += ['.tar.gz', '.zip', '.7z', '.bz2', '.rar', '.jpg', '.png']
let s:ignore += ['.chm', '.docx', '.xlsx', '.pptx', '.pdf', '.dll', '.pyd']
let s:ignore += ['.xls', '.mobi', '.mp4', '.mp3']


"----------------------------------------------------------------------
" NERDTree
"----------------------------------------------------------------------
let NERDTreeIgnore = ['\~$', '\$.*$', '\.swp$', '\.pyc$', '#.\{-\}#$']

for s:extname in s:ignore
	let NERDTreeIgnore += [escape(s:extname, '.~$')]
endfor

let NERDTreeRespectWildIgnore = 1

" let g:vinegar_nerdtree_as_netrw = 1

let g:NERDTreeMinimalUI = 1
let g:NERDTreeDirArrows = 1
let g:NERDTreeHijackNetrw = 0

" let g:NERDTreeFileExtensionHighlightFullName = 1
" let g:NERDTreeExactMatchHighlightFullName = 1
" let g:NERDTreePatternMatchHighlightFullName = 1

nnoremap <space>tn :exec "NERDTree " . fnameescape(asclib#path#get_root('%'))<cr>
nnoremap <space>to :NERDTreeFocus<cr>
nnoremap <space>tm :NERDTreeMirror<cr>
nnoremap <space>tt :exec "NERDTreeToggle " . fnameescape(asclib#path#get_root('%'))<cr>


"----------------------------------------------------------------------
" enable cursorlineopt
"----------------------------------------------------------------------
function! s:init_nerdtree_ft()
	if exists('+cursorlineopt')
		setlocal cursorlineopt=number,line
	endif
endfunc


"----------------------------------------------------------------------
" register event handler
"----------------------------------------------------------------------
augroup MyNERDTreeEvent
	au!
	au FileType nerdtree call s:init_nerdtree_ft()
augroup END


