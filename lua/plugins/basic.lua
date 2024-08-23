local utils = require('core.utils')
local inc = utils.include_script

return {
	{'tpope/vim-fugitive', config = function() inc('site/bundle/git.vim') end },
	'tpope/vim-rhubarb',
	'tpope/vim-unimpaired',
	-- 'tpope/vim-surround',
	{
		'kylechui/nvim-surround',
		config = function()
			require("nvim-surround").setup({ })
		end,
	},

	{'bootleq/vim-cycle', config = function() inc('site/bundle/dirvish.vim') end },

	{
		't9md/vim-choosewin',
		keys = {
			{'<m-e>', '<plug>(choosewin)', desc = 'choose-tab-win' },
		},
	},

	'tommcdo/vim-exchange', 
	'tommcdo/vim-lion',
	'skywind3000/vim-dict',

	{
		'rbong/vim-flog',
		cmd = {'Flog', 'Floggit', 'Flogjump', 'Flogmarks', 'Flogsetargs', 'Flogsplit' },
	},

	{
		'terryma/vim-expand-region',
		keys = {
			{'<m-+>', '<Plug>(expand_region_expand)', mode = 'n'},
			{'<m-+>', '<Plug>(expand_region_expand)', mode = 'v'},
			{'<m-->', '<Plug>(expand_region_shrink)', mode = 'n'},
			{'<m-->', '<Plug>(expand_region_shrink)', mode = 'v'},
		},
	},

	{
		'godlygeek/tabular',
		cmd = 'Tabularize',
		keys = {
			{'gb=', ':Tabularize /=<cr>', mode = 'n'},
			{'gb=', ':Tabularize /=<cr>', mode = 'v'},
			{'gb/', ':Tabularize /\\/\\//l4c1<cr>', mode = 'n'},
			{'gb/', ':Tabularize /\\/\\//l4c1<cr>', mode = 'v'},
			{'gb*', ':Tabularize /\\/\\*/l4c1<cr>', mode = 'n'},
			{'gb*', ':Tabularize /\\/\\*/l4c1<cr>', mode = 'v'},
			{'gb,', ':Tabularize /,/r0l1<cr>', mode = 'n'},
			{'gb,', ':Tabularize /,/r0l1<cr>', mode = 'v'},
			{'gbl', ':Tabularize /\\|<cr>', mode = 'n'},
			{'gbl', ':Tabularize /\\|<cr>', mode = 'v'},
			{'gbc', ':Tabularize /#/l4c1<cr>', mode = 'n'},
			{'gbc', ':Tabularize /#/l4c1<cr>', mode = 'v'},
			{'gb<bar>', ':Tabularize /\\|<cr>', mode = 'n'},
			{'gb<bar>', ':Tabularize /\\|<cr>', mode = 'v'},
			{'gbr', ':Tabularize /\\|/r0<cr>', mode = 'n'},
			{'gbr', ':Tabularize /\\|/r0<cr>', mode = 'v'},
		},
	},

	{
		'justinmk/vim-sneak',
		keys = {
			{'gz', '<Plug>Sneak_s', mode = 'n'},
			{'gZ', '<Plug>Sneak_S', mode = 'n'},
			{'gz', '<Plug>Sneak_s', mode = 'v'},
			{'gZ', '<Plug>Sneak_S', mode = 'v'},
			{'gz', '<Plug>Sneak_s', mode = 'x'},
			{'gZ', '<Plug>Sneak_S', mode = 'x'},
		},
	},

	{ 
		'phaazon/hop.nvim',
		branch = 'v2', -- optional but strongly recommended
		config = function()
			-- you can configure Hop the way you like here; see :h hop-config
			require'hop'.setup { keys = 'asdghklqwertyuiopzxcvbnmfj;' }
		end
	},
	
	-- "gc" to comment visual regions/lines
	{ 'numToStr/Comment.nvim', opts = {} },

	{
		'tpope/vim-eunuch',
		config = function()
			vim.g.eunuch_no_maps = 1
		end,
	}
}


