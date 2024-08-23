return {
	{
		-- Set lualine as statusline
		'nvim-lualine/lualine.nvim',
		-- See `:help lualine.txt`
		opts = {
			options = {
				icons_enabled = false,
				-- theme = 'PaperColor',
				-- theme = 'molokai',
				-- theme = 'onedark',
				theme = 'nord',
				component_separators = '|',
				section_separators = '',
			},
		},
	},

	{
		-- Add indentation guides even on blank lines
		'lukas-reineke/indent-blankline.nvim',
		-- Enable `lukas-reineke/indent-blankline.nvim`
		-- See `:help indent_blankline.txt`
		config = function() 
			require('ibl').setup({
				indent = {
					char = '┊',
				},
			});
		end,
		-- opts = {
		-- 	char = '┊',
		-- 	show_trailing_blankline_indent = false,
		-- },
	},

}


