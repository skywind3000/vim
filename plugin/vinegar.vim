"======================================================================
"
" vinegar.vim - Vinegar & Oil (fork from tpope/vim-vinegar)
"
" Created by skywind on 2017/06/30
" Last Modified: 2018/03/16 22:33
"
" Split windows and the project drawer go together like oil and 
" vinegar. I don't mean to say that you can combine them to create a 
" delicious salad dressing. I mean that they don't mix well!
"    --   Drew Neil
"
"======================================================================

let s:netrw_up = ''
let s:windows = has('win32') || has('win64') || has('win16') || has('win95')


"----------------------------------------------------------------------
" configure
"----------------------------------------------------------------------

" hot key to back to directory
if !exists('g:vinegar_key')
	let g:vinegar_key = '-'
endif

if !exists('g:vinegar_nerdtree_as_netrw')
	let g:vinegar_nerdtree_as_netrw = 0
endif


"----------------------------------------------------------------------
" write log
"----------------------------------------------------------------------
function! s:log(text)
	call LogWrite(a:text)
endfunc


"----------------------------------------------------------------------
" seek
"----------------------------------------------------------------------
function! s:seek(file) abort
	let sname = fnamemodify(a:file, ':t')
	if get(b:, 'netrw_liststyle') == 2
		let pattern = '\%(^\|\s\+\)\zs'.escape(sname, '.*[]~\').'[/*|@=]\=\%($\|\s\+\)'
	elseif get(b:, 'netrw_liststyle') == 1
		let pattern = '^'.escape(sname, '.*[]~\').'[/*|@=]\=\%($\|\s\+\)'
	else
		let pattern = '^\%(| \)*'.escape(sname, '.*[]~\').'[/*|@=]\=\%($\|\t\)'
	endif
	if has('win32') || has('win16') || has('win95') || has('win64')
		let savecase = &l:ignorecase
		setlocal ignorecase
		if &buftype == 'nofile' && &filetype == 'nerdtree'
			let pattern = '^ *\%(▸ \)\?'.escape(sname, '.*[]~\').'\>'
		elseif &buftype == 'nofile' && &filetype == 'dirvish'
			let pattern = '^.*\(\\\|\/\)'.escape(sname, '.*[]~\').'[/*|@=]\=\%($\|\s\+\)'
		endif
		call search(pattern, 'wc')
		let l:ignorecase = savecase
	else
		if &buftype == 'nofile' && &filetype == 'nerdtree'
			let pattern = '^ *\%(▸ \)\?'.escape(sname, '.*[]~\').'\>'
		elseif &buftype == 'nofile' && &filetype == 'dirvish'
			let pattern = '^.*\(\\\|\/\)'.escape(sname, '.*[]~\').'[/*|@=]\=\%($\|\s\+\)'
		endif
		call search(pattern, 'wc')
	endif
	return pattern
endfunc



"----------------------------------------------------------------------
" open upper directory
"----------------------------------------------------------------------
function! s:open(cmd) abort
	let filename = expand('%:p')
	let shortname = expand('%:t')
	call s:log('[vinegar] ' . expand('%:p'))
	if &buftype == "nofile" || &buftype == "quickfix"
		if (&ft != 'nerdtree') && (&ft != 'netrw') && (&ft != 'dirvish')
			return
		endif
	endif
	if &filetype ==# 'netrw'
		if s:netrw_up == ''
			return
		endif
		let currdir = fnamemodify(b:netrw_curdir, ':t')
		let nextdir = fnamemodify(b:netrw_curdir, ':h:p')
		if s:windows && strlen(nextdir) == 3 
			let t = strpart(nextdir, 1, 2)
			if t == ':/' || t == ":\\"
				let t = nextdir . '.'
				if tolower(nextdir) != tolower(b:netrw_curdir)
					execute a:cmd t
					call s:seek(currdir)
				endif
				return
			endif
		endif
		exec s:netrw_up
		call s:seek(currdir)
	elseif &filetype ==# 'nerdtree'
		let currdir = b:NERDTreeRoot.path.str()
		exec "normal " . g:NERDTreeMapUpdir
		call s:seek(currdir)
	elseif &filetype ==# 'dirvish'
		let currdir = expand('%:p')
		exec 'Dirvish %:p:h:h'
		call s:seek(currdir)
	elseif &modifiable == 0 && &ft != 'help'
		return 
	elseif shortname == ""
		exec a:cmd '.'
	elseif expand('%') =~# '^$\|^term:[\/][\/]'	
		exec a:cmd '.'
	else
		exec a:cmd '%:p:h'
		let hr = s:seek(filename)
	endif
endfunc


command! -nargs=1 VinegarOpen call s:open(<f-args>)



"----------------------------------------------------------------------
" nerdtree
"----------------------------------------------------------------------
function! <SID>nerdtree_enter()
	let currentNode = g:NERDTreeFileNode.GetSelected()
	if currentNode.path.isDirectory
		exec "normal e"
	else
		exec "normal o"
	endif
endfunc

function! <SID>nerdtree_metadata()
	let treenode = g:NERDTreeFileNode.GetSelected()
	let nodename = treenode.path.str()
	call nerdtree#echo("hahahah no meta info: " . string(nodename))
endfunc


"----------------------------------------------------------------------
" initialize
"----------------------------------------------------------------------
function! s:setup_vinegar()
	let key = g:vinegar_key
	if &ft == 'netrw'
		if s:netrw_up == ''
			let s:netrw_up = substitute(maparg('-', 'n'), '\c^:\%(<c-u>\)\=', '', '')
			let s:netrw_up = strpart(s:netrw_up, 0, strlen(s:netrw_up)-4)
		endif
		nnoremap <buffer><silent> - :VinegarOpen edit<cr>
		if key != '-'
			exec 'nnoremap <buffer><silent> ' . key. ' :VinegarOpen edit<cr>'
		endif
		nnoremap <buffer> ~ :edit ~/<CR>
		nnoremap <buffer> ` :edit <C-R>=fnameescape(asyncrun#get_root('%'))<CR><CR>
	elseif &ft == 'nerdtree'
		nmap <buffer> - :VinegarOpen edit<cr>
		if key != '-'
			exec 'nmap <buffer><silent> ' . key. ' :VinegarOpen edit<cr>'
		endif
		nnoremap <silent><buffer> ` :edit <C-R>=fnameescape(asyncrun#get_root(exists('b:NERDTree')?b:NERDTree.root.path.str():''))<CR><CR>
		nnoremap <silent><buffer> % :call NERDTreeAddNode()<cr>
		nnoremap <silent><buffer> a :call <SID>nerdtree_metadata()<cr>
		if g:vinegar_nerdtree_as_netrw
			nnoremap <silent><buffer> <cr> :call <SID>nerdtree_enter()<cr>
		endif
	elseif &ft == 'dirvish'
        exec 'nmap <buffer><silent> ' . key. ' <Plug>(dirvish_up)'
		nnoremap <silent><buffer> r :Dirvish %<cr>
	endif
endfunc


"----------------------------------------------------------------------
" events
"----------------------------------------------------------------------
augroup VinegarGroup
	autocmd!
	autocmd FileType netrw call s:setup_vinegar()
	autocmd FileType nerdtree call s:setup_vinegar()
	autocmd FileType dirvish call s:setup_vinegar()
augroup END


"----------------------------------------------------------------------
" initialize NERDTree
"----------------------------------------------------------------------
if g:vinegar_nerdtree_as_netrw
    " let NERDTreeCascadeSingleChildDir = 0
    " let NERDTreeCascadeOpenSingleChildDir = 0
endif


"----------------------------------------------------------------------
" Setup keymap
"----------------------------------------------------------------------
if g:vinegar_key != ''
	exec 'noremap <silent> '.g:vinegar_key. ' :VinegarOpen edit<cr>'
endif

" vim: set ts=4 sw=4 tw=78 et :
