local utils = require('core.utils')
local custom = require('config.custom')
local package_enabled = utils.package_enabled
local inc = utils.include_script
local has_py3 = (vim.fn.has('python3') ~= 0)

return {
	{
		'itchyny/vim-cursorword',
		enabled = package_enabled('cursorword'),
		config = function()
			vim.g.cursorword_delay = 100
			vim.g.cursorword = 0
		end,
	},

	{
		'justinmk/vim-dirvish', 
		enabled = not package_enabled('oil'),
		config = function() 
			inc('site/bundle/dirvish.vim') 
		end 
	},

	{
		'stevearc/oil.nvim',
		enabled = package_enabled('oil'),
		config = function()
			require('oil').setup()
		end
	},

	{
		'andymass/vim-matchup',
		enabled = package_enabled('matchup'),
		config = function()
			-- disable matchit
			vim.g.loaded_matchit = 1
			inc('site/bundle/matchup.vim')
		end
	},

	{
		"NeogitOrg/neogit",
		enabled = package_enabled('neogit'),
		dependencies = {
			"nvim-lua/plenary.nvim",         -- required
			"sindrets/diffview.nvim",        -- optional - Diff integration

			-- Only one of these is needed, not both.
			"nvim-telescope/telescope.nvim", -- optional
			"ibhagwan/fzf-lua",              -- optional
		},
		config = true
	},

	{
		"kdheepak/lazygit.nvim",
		-- optional for floating window border decoration
		enabled = package_enabled('lazygit'),
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
	},

	{
		'liuchengxu/vista.vim',
		enabled = package_enabled('vista'),
		config = function()
			-- require('vista')
		end,
	},

	{
		'stevearc/aerial.nvim',
		enabled = package_enabled('aerial'),
		config = function() 
			require("aerial").setup({
					-- optionally use on_attach to set keymaps when aerial has attached to a buffer
					on_attach = function(bufnr)
						-- Jump forwards/backwards with '{' and '}'
						vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
						vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
					end,
				})
		end,
	},

	{
		'hedyhli/outline.nvim',
		enabled = package_enabled('outline'),
		config = function()
			require("outline").setup({
				})
		end,
	},

	{
		'simrat39/symbols-outline.nvim',
		enabled = package_enabled('symbols-outline'),
		config = function() 
			require('symbols-outline').setup({
				})
		end,
	},

	{
		"X3eRo0/dired.nvim",
		enabled = package_enabled('dired'),
		dependencies = {"MunifTanjim/nui.nvim"},
		config = function()
			require("dired").setup {
				path_separator = "/",
				show_banner = false,
				show_icons = false,
				show_hidden = true,
				show_dot_dirs = true,
				show_colors = true,
			}
		end
	},

	{
		'nvim-tree/nvim-tree.lua',
		enabled = package_enabled('nvim-tree'),
		config = function()
			require("nvim-tree").setup({
				})
		end,
	},

	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		enabled = package_enabled('neo-tree'),
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},
	},

}


