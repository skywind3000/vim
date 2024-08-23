
return {
	'ThePrimeagen/vim-be-good',
	'rktjmp/shenzhen-solitaire.nvim',
	'alec-gibson/nvim-tetris',
	'seandewar/nvimesweeper',

	{
		'jim-fx/sudoku.nvim',
		cmd = "Sudoku",
		config = function()
			require("sudoku").setup({
					-- configuration ...
				})
		end
	},

	{
		'alanfortlink/blackjack.nvim',
		dependencies = {
			'nvim-lua/plenary.nvim',
		},
		config = function()
		end,
	},
}


