local MM = {}

function MM.query(ft)
	local has_luasnip, luasnip = pcall(require, "luasnip")
	if not has_luasnip then
		return {}
	end
	local snippets = luasnip.get_snippets(ft)
	local result = {}
	for _, snippet in ipairs(snippets) do
		local item = {snippet.name, snippet.trigger, snippet:get_docstring()}
		table.insert(result, item)
	end
	return result
end

return MM


