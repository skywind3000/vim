local custom = require('config.custom')

-- turn off diagnostic
vim.diagnostic.disable()

-- To instead override globally
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview

---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or custom.border
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

