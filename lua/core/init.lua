--=====================================================================
--
-- init.lua - 
--
-- Created by skywind on 2023/08/30
-- Last Modified: 2023/08/30 12:25:42
--
--=====================================================================


-----------------------------------------------------------------------
-- module initialize
-----------------------------------------------------------------------
local modname = ...
if modname ~= nil then
	local MM = {}
	setmetatable(MM, {__index = _G})
	package.loaded[modname] = MM
	if _ENV ~= nil then _ENV = MM else setfenv(1, MM) end
end


-----------------------------------------------------------------------
-- internal
-----------------------------------------------------------------------
local ascmini = require('core.ascmini')
local utils = require('core.utils')



