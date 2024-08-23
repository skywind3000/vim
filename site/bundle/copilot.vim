"======================================================================
"
" copilot.vim - 
"
" Created by skywind on 2024/02/24
" Last Modified: 2024/02/24 23:19:10
"
"======================================================================


"----------------------------------------------------------------------
" settings
"----------------------------------------------------------------------
let g:copilot_no_tab_map = v:true
let g:copilot_proxy_strict_ssl = v:false


"----------------------------------------------------------------------
" mappings
"----------------------------------------------------------------------
imap <silent><script><expr> <c-b> copilot#Accept("\<CR>")
imap <silent><script><expr> <m-f> copilot#Accept("\<CR>")
imap <silent><script><expr> <m-q> copilot#Accept("\<CR>")

imap <silent><m-]> <Plug>(copilot-next)
imap <silent><m-[> <Plug>(copilot-previous)

imap <silent><m-right> <Plug>(copilot-accept-word)
imap <silent><c-right> <Plug>(copilot-accept-line)


"----------------------------------------------------------------------
" setup root
"----------------------------------------------------------------------
function! s:setup_copilot() abort
	if &bt != '' || bufname('') == ''
		return 0
	elseif !module#copilot#check_enabled()
		return 0
	endif
	let root = module#generic#root()
	if !exists('b:workspace_folder')
		if root != ''
			let b:workspace_folder = root
		endif
	endif
	return 0
endfunc


"----------------------------------------------------------------------
" setup copilot
"----------------------------------------------------------------------
augroup CopilotEventGroupX
	au!
	au FileType * call s:setup_copilot()
augroup END


"----------------------------------------------------------------------
" whitelist
"----------------------------------------------------------------------
let g:copilot_filetypes = {
			\ '*': v:false,
			\ 'vim': v:true,
			\ 'gitcommit': v:true,
			\ 'python': v:true,
			\ 'c': v:true,
			\ 'cpp': v:true,
			\ 'javascript': v:true,
			\ 'typescript': v:true,
			\ 'html': v:true,
			\ 'css': v:true,
			\ 'go': v:true,
			\ 'rust': v:true,
			\ 'java': v:true,
			\ 'lua': v:true,
			\ 'sh': v:true,
			\ 'bash': v:true,
			\ 'zsh': v:true,
			\ 'yaml': v:true,
			\ 'json': v:true,
			\ 'xml': v:true,
			\ 'markdown': v:true,
			\ 'php': v:true,
			\ 'ruby': v:true,
			\ 'perl': v:true,
			\ 'scala': v:true,
			\ 'haskell': v:true,
			\ 'erlang': v:true,
			\ 'clojure': v:true,
			\ 'kotlin': v:true,
			\ 'pascal': v:true,
			\ 'fortran': v:true,
			\ 'scheme': v:true,
			\ 'lisp': v:true,
			\ 'zig': v:true,
			\  }



