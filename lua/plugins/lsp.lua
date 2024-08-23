local has_words_before = function()
	local line, col = unpack(vim.api.nvim_win_get_cursor(0))
	return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local function Installed(what)
	return false
end

return {

	{
		-- Autocompletion
		'hrsh7th/nvim-cmp',
		dependencies = {
			'neovim/nvim-lspconfig',
			-- Automatically install LSPs to stdpath for neovim
			{ 'williamboman/mason.nvim', config = true },

			'williamboman/mason-lspconfig.nvim',

			-- Useful status updates for LSP
			-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
			{ 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },

			-- Additional lua configuration, makes nvim stuff amazing!
			'folke/neodev.nvim',
			-- Snippet Engine & its associated nvim-cmp source
			'L3MON4D3/LuaSnip',
			'saadparwaiz1/cmp_luasnip',

			-- Adds LSP completion capabilities
			'hrsh7th/cmp-nvim-lsp',

			-- Adds a number of user-friendly snippets
			'rafamadriz/friendly-snippets',

			'onsails/lspkind.nvim',
		},

		config = function()
			-- [[ Configure LSP ]]
			--  This function gets run when an LSP connects to a particular buffer.
			local on_attach = function(_, bufnr)
				-- NOTE: Remember that lua is a real programming language, and as such it is possible
				-- to define small helper and utility functions so you don't have to repeat yourself
				-- many times.
				--
				-- In this case, we create a function that lets us more easily define mappings specific
				-- for LSP related items. It sets the mode, buffer and description for us each time.
				local nmap = function(keys, func, desc)
					if desc then
						desc = 'LSP: ' .. desc
					end

					vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
				end

				nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
				nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

				nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
				nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
				nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
				nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
				nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
				nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

				-- See `:help K` for why this keymap
				nmap('<leader>k', vim.lsp.buf.hover, 'Hover Documentation')
				nmap('<leader>K', vim.lsp.buf.signature_help, 'Signature Documentation')

				-- Lesser used LSP functionality
				nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
				nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
				nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
				nmap('<leader>wl', function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, '[W]orkspace [L]ist Folders')

			-- Create a command `:Format` local to the LSP buffer
			vim.api.nvim_buf_create_user_command(bufnr, 'Format', 
				function(_) vim.lsp.buf.format() end, 
				{ desc = 'Format current buffer with LSP' })
			end

			local servers = {
				-- clangd = {},
				-- gopls = {},
				-- pyright = {},
				-- rust_analyzer = {},
				-- tsserver = {},
				-- html = { filetypes = { 'html', 'twig', 'hbs'} },

				lua_ls = {
					Lua = {
						workspace = { checkThirdParty = false },
						telemetry = { enable = false },
						hint = { enable = true, setType = true },
						codelens = { enable = false },
					},
				},
			}

			-- Setup neovim lua configuration
			require('neodev').setup()

			-- nvim-cmp supports additional completion capabilities, so broadcast that to servers
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

			-- Ensure the servers above are installed
			local mason_lspconfig = require('mason-lspconfig')

			mason_lspconfig.setup {
				ensure_installed = vim.tbl_keys(servers),
			}

			mason_lspconfig.setup_handlers {
				function(server_name)
					require('lspconfig')[server_name].setup {
						capabilities = capabilities,
						on_attach = on_attach,
						settings = servers[server_name],
						filetypes = (servers[server_name] or {}).filetypes,
					}
				end
			}

			-- [[ Configure nvim-cmp ]]
			-- See `:help cmp`
			local cmp = require('cmp')
			local luasnip = require('luasnip')
			local lspkind = require('lspkind')
			local utils = require('core.utils')
			local snipmate = utils.runtime('site/snippets')

			-- require('luasnip.loaders.from_vscode').lazy_load()
			require('luasnip.loaders.from_snipmate').lazy_load({paths = snipmate})

			luasnip.config.setup {}

			cmp.setup {
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				window = {
					-- completion = { border = border },
					-- documentation = { border = border },
					completion = {
						-- border = border('CmpBorder'),
						border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│', },
						-- winhighlight = 'Normal:CmpPmenu,CursorLine:PmenuSel,Search:None',
						col_offset = -1,
					},
					documentation = {
						border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│', },
					},
					hover = {
						border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│', },
					},
				},

				completion = {
					-- completeopt = 'menu,menuone,noinsert',
					completeopt = 'menu,menuone,noselect',
				},
				mapping = cmp.mapping.preset.insert {
					['<C-n>'] = cmp.mapping.select_next_item(),
					['<C-p>'] = cmp.mapping.select_prev_item(),
					['<C-d>'] = cmp.mapping.scroll_docs(-4),
					['<C-f>'] = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete {},
					-- ['<CR>'] = cmp.mapping.confirm {
					-- 	behavior = cmp.ConfirmBehavior.Replace,
					-- 	select = true,
					['<C-CR>'] = cmp.mapping.confirm {
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					},
					['<C-@>'] = cmp.mapping.confirm {
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					},
					['<Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<S-Tab>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<m-e>'] = cmp.mapping(function(fallback)
						if luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { 'i' }),
					['<m-E>'] = cmp.mapping(function(fallback)
						if luasnip.locally_jumpable(-1) then 
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { 'i' }),
				},
				sources = {
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' },
					{ name = 'orgmode' },
				},
				formatting = {
					format = lspkind.cmp_format({
						-- mode = 'symbol', -- show only symbol annotations
						mode = 'symbol_text', -- show only symbol annotations
						maxwidth = 50, -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)
						ellipsis_char = '...', -- when popup menu exceed maxwidth, the truncated part would show ellipsis_char instead (must define maxwidth first)

						-- The function below will be called before any actual modifications from lspkind
						-- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
						before = function (entry, vim_item)
							return vim_item
						end
					}),
				},
			}

			vim.g.snips_author = 'skywind3000'
		end
	},
}


