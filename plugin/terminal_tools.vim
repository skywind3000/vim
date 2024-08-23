
let g:quickui_terminal_tools = get(g:, 'quickui_terminal_tools', {})

let g:quickui_terminal_tools.lazygit = {
			\ 'title': '| LazyGit |',
			\ 'cmd': 'lazygit',
			\ 'cwd': '<root>',
			\ 'w': 0.8,
			\ 'h': 0.8,
			\ }

let g:quickui_terminal_tools.cloc = {
			\ 'title': '| CLOC |',
			\ 'cmd': 'cloc .',
			\ 'cwd': '<root>',
			\ 'w': 90,
			\ 'h': 30,
			\ 'pause': 1,
			\ }


