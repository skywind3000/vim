local utils = require('core.utils')
local package_enabled = utils.package_enabled
local inc = utils.include_script

return {
	{
		'skywind3000/vim-gutentags',
		enable = function()
			return (vim.fn.executable('ctags') ~= 0)
		end,
		config = function()
			local modules = {}
			if vim.fn.executable('ctags') ~= 0 then
				table.insert(modules, 'ctags')
			end
			if vim.fn.executable('gtags-cscope') ~= 0 then
				table.insert(modules, 'gtags_cscope')
			end
			vim.g.gutentags_modules = modules
		end,
	},

	'jamessan/vim-gnupg',

	-- 'kana/vim-textobj-user',
	{ 'kana/vim-textobj-syntax', dependencies = {'kana/vim-textobj-user'} },
	{ 'sgur/vim-textobj-parameter', dependencies = {'kana/vim-textobj-user'} },
	{ 'bps/vim-textobj-python', dependencies = {'kana/vim-textobj-user'} },
	{ 'jceb/vim-textobj-uri', dependencies = {'kana/vim-textobj-user'} },
	{ 'wellle/targets.vim', },

	{
		'nvim-orgmode/orgmode',
		config = function()
			utils.defer_init(10, function()
				require('orgmode').setup_ts_grammar()
				require('orgmode').setup {
				}
			end)
		end
	},

	{ 'kshenoy/vim-signature', },
	{ 'mhinz/vim-signify', },

	{
		'akinsho/toggleterm.nvim', 
		version = "*",
		config = function()
			local toggleterm = require('toggleterm')
			toggleterm.setup()
			vim.cmd [[
			tnoremap <silent><c-t> <Cmd>exe v:count1 . "ToggleTerm"<CR>

			" By applying the mappings this way you can pass a count to your
			" mapping to open a specific window.
			" For example: 2<C-t> will open terminal 2
			nnoremap <silent><c-t> <Cmd>exe v:count1 . "ToggleTerm"<CR>
			inoremap <silent><c-t> <Esc><Cmd>exe v:count1 . "ToggleTerm"<CR>
			]]
		end,
	},

}


