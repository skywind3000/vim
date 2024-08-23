local utils = require('core.utils')
local package_enabled = utils.package_enabled

return {
	{
		'rcarriga/nvim-notify',

		enabled = package_enabled('notify'),

		config = function ()
			vim.notify = require("notify")
		end
	},
}


