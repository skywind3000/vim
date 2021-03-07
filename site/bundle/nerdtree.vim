
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
noremap <space>tn :exec "NERDTree " . fnameescape(asclib#path#get_root('%'))<cr>
noremap <space>to :NERDTreeFocus<cr>
noremap <space>tm :NERDTreeMirror<cr>
noremap <space>tt :exec "NERDTreeToggle " . fnameescape(asclib#path#get_root('%'))<cr>

