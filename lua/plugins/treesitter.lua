return {
	"nvim-treesitter/nvim-treesitter",

	event = "VeryLazy",

	dependencies = {
		{ "windwp/nvim-ts-autotag" },
		-- { "JoosepAlviste/nvim-ts-context-commentstring" },
		{ "RRethy/nvim-treesitter-endwise" },
		{ "RRethy/nvim-treesitter-textsubjects", enabled = false },
		{ 'nvim-treesitter/nvim-treesitter-textobjects' },
	},

	build = ":TSUpdate",
	config = function()
		-- if vim.uv.os_uname().sysname == "Windows" then
		-- 	require("nvim-treesitter.install").prefer_git = false
		-- end

		require("nvim-treesitter.configs").setup {
			-- Add languages to be installed here that you want installed for treesitter
			ensure_installed = { 'c', 'cpp', 'go', 'lua', 
				'python', 'rust', 'zig', 'javascript', 'html', 
				'awk', 'hlsl', 'ini', 'org',
				'tsx', 'typescript', 'vimdoc', 'vim' },

			highlight = {
				enable = true,
				additional_vim_regex_highlighting = {'org'},
			},
			indent = {
				enable = false,
			},
			autotag = {
				enable = true,
			},
			endwise = {
				enable = true,
			},

			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = '<c-space>',
					node_incremental = '<c-space>',
					scope_incremental = '<c-s>',
					node_decremental = '<M-space>',
				},
			},

			textobjects = {
				select = {
					enable = true,
					lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
					keymaps = {
						-- You can use the capture groups defined in textobjects.scm
						-- ['aa'] = '@parameter.outer',
						-- ['ia'] = '@parameter.inner',
						['af'] = '@function.outer',
						['if'] = '@function.inner',
						['ac'] = '@class.outer',
						['ic'] = '@class.inner',
					},
				},
				move = {
					enable = true,
					set_jumps = true, -- whether to set jumps in the jumplist
					goto_next_start = {
						[']m'] = '@function.outer',
						[']]'] = '@class.outer',
					},
					goto_next_end = {
						[']M'] = '@function.outer',
						[']['] = '@class.outer',
					},
					goto_previous_start = {
						['[m'] = '@function.outer',
						['[['] = '@class.outer',
					},
					goto_previous_end = {
						['[M'] = '@function.outer',
						['[]'] = '@class.outer',
					},
				},
				swap = {
					enable = true,
					swap_next = {
						['<leader>a'] = '@parameter.inner',
					},
					swap_previous = {
						['<leader>A'] = '@parameter.inner',
					},
				},
			},
		}
	end,
}



