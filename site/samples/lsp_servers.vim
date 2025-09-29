"----------------------------------------------------------------------
" LSP
"----------------------------------------------------------------------
let g:lsp_servers = get(g:, 'lsp_servers', {})

let g:lsp_servers.clangd = #{
			\ filetype: ['c', 'cpp', 'objc', 'objcpp', 'cuda'],
			\ path: 'd:/Linux/clang64/bin/clangd.exe',
			\ args: ['--background-index'],
			\ root: ['.git', '.svn', '.root', '.project', '.hg'],
			\ }

if get(g:, 'lsp', '') == 'yegappan'
	let g:lsp_servers.basics = #{
				\ filetype: ['vim', 'text', 'bash'],
				\ path: 'd:/dev/node/node/basics-language-server.cmd',
				\ args: ['--stdio'],
				\ root: ['.git', '.svn', '.root', '.project', '.hg'],
				\ }
endif


