"----------------------------------------------------------------------
" LSP
"----------------------------------------------------------------------
let g:lsp_servers = get(g:, 'lsp_servers', {})

let g:lsp_servers.clangd = #{
			\ filetype: ['c', 'cpp', 'objc', 'objcpp', 'cuda'],
			\ path: "/usr/local/opt/bin/clangd",
			\ args: ['--background-index', '--clang-tidy'],
			\ root: ['.git', '.svn', '.root', '.project', '.hg'],
			\ }

let g:lsp_servers.pyright = #{
			\ filetype: ['python'],	
			\ path: 'pyright-langserver',
			\ args: ['--stdio'],
			\ root: ['.git', '.svn', '.root', '.project', '.hg'],
			\ workspace: {
			\   'python': {'analysis': {'useLibraryCodeForTypes': v:true}, },
			\ },
			\ }

let g:lsp_servers.vimlsp = #{
			\ filetype: ['vim'],
			\ path: 'vim-language-server',
			\ args: ['--stdio'],
			\ root: ['.git', '.svn', '.root', '.project', '.hg'],
			\ }

if get(g:, 'lsp', '') == 'yegappan'
	let g:lsp_servers.basics = #{
				\ filetype: ['text', 'bash'],
				\ path: 'd:/dev/node/node/basics-language-server.cmd',
				\ args: ['--stdio'],
				\ root: ['.git', '.svn', '.root', '.project', '.hg'],
				\ }
endif


