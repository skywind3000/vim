--=====================================================================
--
-- ascmini.lua - 
--
-- Created by skywind on 2023/08/26
-- Last Modified: 2023/08/26 11:44:06
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
-- Environment
-----------------------------------------------------------------------
local windows = package.config:sub(1, 1) ~= '/' and true or false
local in_module = pcall(debug.getlocal, 4, 1) and true or false
local utils = {}

os.path = {}
os.argv = arg ~= nil and arg or {}
os.path.sep = windows and '\\' or '/'
os.has_nvim = (vim ~= nil) and (vim.fn.has('nvim') ~= 0) or false


-----------------------------------------------------------------------
-- Capacity
-----------------------------------------------------------------------
local vim = vim
if vim ~= nil then
	vim.has = {}
	vim.has.nvim = (vim.fn.has('nvim') ~= 0)
	vim.has.isabsolutepath = (vim.fn.exists('*isabsolutepath') ~= 0)
	vim.asc = package.loaded[modname]
end


-----------------------------------------------------------------------
-- string lib
-----------------------------------------------------------------------
function string:split(sSeparator, nMax, bRegexp)
	assert(sSeparator ~= '')
	assert(nMax == nil or nMax >= 1)
	local aRecord = {}
	if self:len() > 0 then
		local bPlain = not bRegexp
		nMax = nMax or -1
		local nField, nStart = 1, 1
		local nFirst, nLast = self:find(sSeparator, nStart, bPlain)
		while nFirst and nMax ~= 0 do
			aRecord[nField] = self:sub(nStart, nFirst - 1)
			nField = nField + 1
			nStart = nLast + 1
			nFirst, nLast = self:find(sSeparator, nStart, bPlain)
			nMax = nMax - 1
		end
		aRecord[nField] = self:sub(nStart)
	else
		aRecord[1] = ''
	end
	return aRecord
end

function string:startswith(text)
	local size = text:len()
	if self:sub(1, size) == text then
		return true
	end
	return false
end

function string:endswith(text)
	return text == "" or self:sub(-#text) == text
end

function string:lstrip()
	if self == nil then return nil end
	local s = self:gsub('^%s+', '')
	return s
end

function string:rstrip()
	if self == nil then return nil end
	local s = self:gsub('%s+$', '')
	return s
end

function string:strip()
	return self:lstrip():rstrip()
end

function string:rfind(key)
	if key == '' then
		return self:len(), 0
	end
	local length = self:len()
	local start, ends = self:reverse():find(key:reverse(), 1, true)
	if start == nil then
		return nil
	end
	return (length - ends + 1), (length - start + 1)
end

function string:join(parts)
	if parts == nil or #parts == 0 then
		return ''
	end
	local size = #parts
	local text = ''
	local index = 1
	while index <= size do
		if index == 1 then
			text = text .. parts[index]
		else
			text = text .. self .. parts[index]
		end
		index = index + 1
	end
	return text
end


-----------------------------------------------------------------------
-- table size
-----------------------------------------------------------------------
function table.length(T)
	local count = 0
	if T == nil then return 0 end
	for _ in pairs(T) do count = count + 1 end
	return count
end


-----------------------------------------------------------------------
-- print table
-----------------------------------------------------------------------
function dump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end


-----------------------------------------------------------------------
-- print table
-----------------------------------------------------------------------
function printT(table, level)
	key = ""
	local func = function(table, level) end
	func = function(table, level)
		level = level or 1
		local indent = ""
		for i = 1, level do
			indent = indent.."  "
		end
		if key ~= "" then
			print(indent..key.." ".."=".." ".."{")
		else
			print(indent .. "{")
		end
		key = ""
		for k, v in pairs(table) do
			if type(v) == "table" then
				key = k
				func(v, level + 1)
			else
				local content = string.format("%s%s = %s", indent .. "  ",tostring(k), tostring(v))
				print(content)
			end
		end
		print(indent .. "}")
	end
	func(table, level)
end


-----------------------------------------------------------------------
-- invoke command and retrive output
-----------------------------------------------------------------------
function os.call(command)
	local fp = io.popen(command)
	if fp == nil then
		return nil
	end
	local line = fp:read('*l')
	fp:close()
	return line
end


-----------------------------------------------------------------------
-- write log
-----------------------------------------------------------------------
function os.log(text)
	if not os.LOG_NAME then
		return
	end
	local fp = io.open(os.LOG_NAME, 'a')
	if not fp then
		return
	end
	local date = "[" .. os.date('%Y-%m-%d %H:%M:%S') .. "] "
	fp:write(date .. text .. "\n")
	fp:close()
end


-----------------------------------------------------------------------
-- ffi optimize (luajit has builtin ffi module)
-----------------------------------------------------------------------
os.native = {}
os.native.status, os.native.ffi =  pcall(require, "ffi")
if os.native.status then
	local ffi = os.native.ffi
	if windows then
		ffi.cdef[[
		int GetFullPathNameA(const char *name, uint32_t size, char *out, char **name);
		int ReplaceFileA(const char *dstname, const char *srcname, void *, uint32_t, void *, void *);
		uint32_t GetTickCount(void);
		uint32_t GetFileAttributesA(const char *name);
		uint32_t GetCurrentDirectoryA(uint32_t size, char *ptr);
		uint32_t GetShortPathNameA(const char *longname, char *shortname, uint32_t size);
		uint32_t GetLongPathNameA(const char *shortname, char *longname, uint32_t size);
		]]
		local kernel32 = ffi.load('kernel32.dll')
		local buffer = ffi.new('char[?]', 4100)
		local INVALID_FILE_ATTRIBUTES = 0xffffffff
		local FILE_ATTRIBUTE_DIRECTORY = 0x10
		os.native.kernel32 = kernel32
		function os.native.GetFullPathName(name)
			local hr = kernel32.GetFullPathNameA(name, 4096, buffer, nil)
			return (hr > 0) and ffi.string(buffer, hr) or nil
		end
		function os.native.ReplaceFile(replaced, replacement)
			local hr = kernel32.ReplaceFileA(replaced, replacement, nil, 2, nil, nil)
			return (hr ~= 0) and true or false
		end
		function os.native.GetTickCount()
			return kernel32.GetTickCount()
		end
		function os.native.GetFileAttributes(name)
			return kernel32.GetFileAttributesA(name)
		end
		function os.native.GetLongPathName(name)
			local hr = kernel32.GetLongPathNameA(name, buffer, 4096)
			return (hr ~= 0) and ffi.string(buffer, hr) or nil
		end
		function os.native.GetShortPathName(name)
			local hr = kernel32.GetShortPathNameA(name, buffer, 4096)
			return (hr ~= 0) and ffi.string(buffer, hr) or nil
		end
		function os.native.GetRealPathName(name)
			local short = os.native.GetShortPathName(name)
			if short then
				return os.native.GetLongPathName(short)
			end
			return nil
		end
		function os.native.exists(name)
			local attr = os.native.GetFileAttributes(name)
			return attr ~= INVALID_FILE_ATTRIBUTES
		end
		function os.native.isdir(name)
			local attr = os.native.GetFileAttributes(name)
			local isdir = FILE_ATTRIBUTE_DIRECTORY
			if attr == INVALID_FILE_ATTRIBUTES then
				return false
			end
			return (attr % (2 * isdir)) >= isdir
		end
		function os.native.getcwd()
			local hr = kernel32.GetCurrentDirectoryA(4096, buffer)
			if hr <= 0 then return nil end
			return ffi.string(buffer, hr)
		end
	else
		ffi.cdef[[
		typedef struct { long tv_sec; long tv_usec; } timeval;
		int gettimeofday(timeval *tv, void *tz);
		int access(const char *name, int mode);
		char *realpath(const char *path, char *resolve);
		char *getcwd(char *buf, size_t size);
		]]
		local timeval = ffi.new('timeval[?]', 1)
		local buffer = ffi.new('char[?]', 4100)
		function os.native.gettimeofday()
			local hr = ffi.C.gettimeofday(timeval, nil)
			local sec = tonumber(timeval[0].tv_sec)
			local usec = tonumber(timeval[0].tv_usec)
			return sec + (usec * 0.000001)
		end
		function os.native.access(name, mode)
			return ffi.C.access(name, mode)
		end
		function os.native.realpath(name)
			local path = ffi.C.realpath(name, buffer)
			return (path ~= nil) and ffi.string(buffer) or nil
		end
		function os.native.getcwd()
			local hr = ffi.C.getcwd(buffer, 4099)
			return hr ~= nil and ffi.string(buffer) or nil
		end
	end
	function os.native.tickcount()
		if windows then
			return os.native.GetTickCount()
		else
			return math.floor(os.native.gettimeofday() * 1000)
		end
	end
	os.native.init = true
end


-----------------------------------------------------------------------
-- get current path
-----------------------------------------------------------------------
function os.pwd()
	if vim ~= nil then
		return vim.fn.getcwd()
	end
	if os.native and os.native.getcwd then
		local hr = os.native.getcwd()
		if hr then return hr end
	end
	if os.getcwd then
		return os.getcwd()
	end
	if windows then
		local fp = io.popen('cd')
		if fp == nil then
			return ''
		end
		local line = fp:read('*l')
		fp:close()
		return line
	else
		local fp = io.popen('pwd')
		if fp == nil then
			return ''
		end
		local line = fp:read('*l')
		fp:close()
		return line
	end
end


-----------------------------------------------------------------------
-- which executable
-----------------------------------------------------------------------
function os.path.which(exename)
	local path = os.getenv('PATH')
	if windows then
		paths = ('.;' .. path):split(';')
	else
		paths = path:split(':')
	end
	for _, path in pairs(paths) do
		if not windows then
			local name = path .. '/' .. exename
			if os.path.exists(name) then
				return name
			end
		else
			for _, ext in pairs({'.exe', '.cmd', '.bat'}) do
				local name = path .. '\\' .. exename .. ext
				if path == '.' then
					name = exename .. ext
				end
				if os.path.exists(name) then
					return name
				end
			end
		end
	end
	return nil
end


-----------------------------------------------------------------------
-- absolute path (simulated)
-----------------------------------------------------------------------
function os.path.absolute(path)
	if vim ~= nil then
		return vim.fn.fnamemodify(path, ':p')
	end
	local pwd = os.pwd()
	return os.path.normpath(os.path.join(pwd, path))
end


-----------------------------------------------------------------------
-- absolute path (system call, can fall back to os.path.absolute)
-----------------------------------------------------------------------
function os.path.abspath(path)
	if path == '' then path = '.' end
	if vim ~= nil then
		return vim.fn.fnamemodify(path, ':p')
	end
	if os.native and os.native.GetFullPathName then
		local test = os.native.GetFullPathName(path)
		if test then return test end
	end
	if windows then
		local script = 'FOR /f "delims=" %%i IN ("%s") DO @echo %%~fi'
		local script = string.format(script, path)
		local script = 'cmd.exe /C ' .. script .. ' 2> nul'
		local output = os.call(script)
		local test = output:gsub('%s$', '')
		if test ~= nil and test ~= '' then
			return test
		end
	else
		local test = os.path.which('realpath')
		if test ~= nil and test ~= '' then
			test = os.call('realpath -s \'' .. path .. '\' 2> /dev/null')
			if test ~= nil and test ~= '' then
				return test
			end
			test = os.call('realpath \'' .. path .. '\' 2> /dev/null')
			if test ~= nil and test ~= '' then
				return test
			end
		end
		local test = os.path.which('perl')
		if test ~= nil and test ~= '' then
			local s = 'perl -MCwd -e "print Cwd::realpath(\\$ARGV[0])" \'%s\''
			local s = string.format(s, path)
			test = os.call(s)
			if test ~= nil and test ~= '' then
				return test
			end
		end
		for _, python in pairs({'python3', 'python2', 'python'}) do
			local s = 'sys.stdout.write(os.path.abspath(sys.argv[1]))'
			local s = '-c "import os, sys;' .. s .. '" \'' .. path .. '\''
			local s = python .. ' ' .. s
			local test = os.path.which(python)
			if test ~= nil and test ~= '' then
				test = os.call(s)
				if test ~= nil and test ~= '' then
					return test
				end
			end
		end
	end
	return os.path.absolute(path)
end


-----------------------------------------------------------------------
-- dir exists
-----------------------------------------------------------------------
function os.path.isdir(pathname)
	if pathname == '/' then
		return true
	elseif pathname == '' then
		return false
	elseif windows then
		if pathname == '\\' then
			return true
		end
	end
	if vim ~= nil then
		return (vim.fn.isdirectory(pathname) ~= 0) and true or false
	end
	if os.native and os.native.isdir then
		return os.native.isdir(pathname)
	end
	if clink and os.isdir then
		return os.isdir(pathname)
	end
	local name = pathname
	if (not name:endswith('/')) and (not name:endswith('\\')) then
		name = name .. os.path.sep
	end
	return os.path.exists(name)
end


-----------------------------------------------------------------------
-- file or path exists
-----------------------------------------------------------------------
function os.path.exists(name)
	if name == '/' then
		return true
	end
	if vim ~= nil then
		if vim.fn.isdirectory(name) ~= 0 then
			return true
		elseif vim.fn.filereadable(name) ~= 0 then
			return true
		elseif vim.loop ~= nil then
			return (vim.loop.fs_state(name)) and true or false
		else
			return false
		end
	end
	if os.native and os.native.exists then
		return os.native.exists(name)
	end
	local ok, err, code = os.rename(name, name)
	if not ok then
		if code == 13 or code == 17 then
			return true
		elseif code == 30 then
			local f = io.open(name,"r")
			if f ~= nil then
				io.close(f)
				return true
			end
		elseif name:sub(-1) == '/' and code == 20 and (not windows) then
			local test = name .. '.'
			ok, err, code = os.rename(test, test)
			if code == 16 or code == 13 or code == 22 then
				return true
			end
		end
		return false
	end
	return true
end


-----------------------------------------------------------------------
-- is absolute path
-----------------------------------------------------------------------
function os.path.isabs(path)
	if path == nil or path == '' then
		return false
	elseif path:sub(1, 1) == '/' then
		return true
	end
	if vim ~= nil then
		if vim.has.isabsolutepath then
			return (vim.fn.isabsolutepath(path) ~= 0) and true or false
		end
	end
	if windows then
		local head = path:sub(1, 1)
		if head == '\\' then
			return true
		elseif path:match('^%a:[/\\]') ~= nil then
			return true
		end
	end
	return false
end


-----------------------------------------------------------------------
-- normalize path
-----------------------------------------------------------------------
function os.path.norm(pathname)
	if windows then
		pathname = pathname:gsub('\\', '/')
	end
	if windows then
		pathname = pathname:gsub('/', '\\')
	end
	return pathname
end


-----------------------------------------------------------------------
-- normalize . and ..
-----------------------------------------------------------------------
function os.path.normpath(path)
	if os.path.sep ~= '/' then
		path = path:gsub('\\', '/')
	end
	path = path:gsub('/+', '/')
	local srcpath = path
	local basedir = ''
	local isabs = false
	if windows and path:sub(2, 2) == ':' then
		basedir = path:sub(1, 2)
		path = path:sub(3, -1)
	end
	if path:sub(1, 1) == '/' then
		basedir = basedir .. '/'
		isabs = true
		path = path:sub(2, -1)
	end
	local parts = path:split('/')
	local output = {}
	for _, path in ipairs(parts) do
		if path == '.' or path == '' then
		elseif path == '..' then
			local size = #output
			if size == 0 then
				if not isabs then
					table.insert(output, '..')
				end
			elseif output[size] == '..' then
				table.insert(output, '..')
			else
				table.remove(output, size)
			end
		else
			table.insert(output, path)
		end
	end
	path = basedir .. string.join('/', output)
	if windows then path = path:gsub('/', '\\') end
	return path == '' and '.' or path
end


-----------------------------------------------------------------------
-- join two path
-----------------------------------------------------------------------
function os.path.join(path1, path2)
	if path1 == nil or path1 == '' then
		if path2 == nil or path2 == '' then
			return ''
		else
			return path2
		end
	elseif path2 == nil or path2 == '' then
		local head = path1:sub(-1, -1)
		if head == '/' or (windows and head == '\\') then
			return path1
		end
		return path1 .. os.path.sep
	elseif os.path.isabs(path2) then
		if windows then
			local head = path2:sub(1, 1)
			if head == '/' or head == '\\' then
				if path1:match('^%a:') then
					return path1:sub(1, 2) .. path2
				end
			end
		end
		return path2
	elseif windows then
		local d1 = path1:match('^%a:') and path1:sub(1, 2) or ''
		local d2 = path2:match('^%a:') and path2:sub(1, 2) or ''
		if d1 ~= '' then
			if d2 ~= '' then
				if d1:lower() == d2:lower() then
					return d2 .. os.path.join(path1:sub(3), path2:sub(3))
				else
					return path2
				end
			end
		elseif d2 ~= '' then
			return path2
		end
	end
	local postsep = true
	local len1 = path1:len()
	local len2 = path2:len()
	if path1:sub(-1, -1) == '/' then
		postsep = false
	elseif windows then
		if path1:sub(-1, -1) == '\\' then
			postsep = false
		elseif len1 == 2 and path1:sub(2, 2) == ':' then
			postsep = false
		end
	end
	if postsep then
		return path1 .. os.path.sep .. path2
	else
		return path1 .. path2
	end
end


-----------------------------------------------------------------------
-- split
-----------------------------------------------------------------------
function os.path.split(path)
	if path == '' then
		return '', ''
	end
	local pos = path:rfind('/')
	if os.path.sep == '\\' then
		local p2 = path:rfind('\\')
		if pos == nil and p2 ~= nil then
			pos = p2
		elseif pos ~= nil and p2 ~= nil then
			pos = (pos < p2) and pos or p2
		end
		if path:match('^%a:[/\\]') and pos == nil then
			return path:sub(1, 2), path:sub(3)
		end
	end
	if pos == nil then
		if windows then
			local drive = path:match('^%a:') and path:sub(1, 2) or ''
			if drive ~= '' then
				return path:sub(1, 2), path:sub(3)
			end
		end
		return '', path
	elseif pos == 1 then
		return path:sub(1, 1), path:sub(2)
	elseif windows then
		local drive = path:match('^%a:') and path:sub(1, 2) or ''
		if pos == 3 and drive ~= '' then
			return path:sub(1, 3), path:sub(4)
		end
	end
	local head = path:sub(1, pos)
	local tail = path:sub(pos + 1)
	if not windows then
		local test = string.rep('/', head:len())
		if head ~= test then
			head = head:gsub('/+$', '')
		end
	else
		local t1 = string.rep('/', head:len())
		local t2 = string.rep('\\', head:len())
		if head ~= t1 and head ~= t2 then
			head = head:gsub('[/\\]+$', '')
		end
	end
	return head, tail
end


-----------------------------------------------------------------------
-- check subdir
-----------------------------------------------------------------------
function os.path.subdir(basename, subname)
	if windows then
		basename = basename:gsub('\\', '/')
		subname = subname:gsub('\\', '/')
		basename = basename:lower()
		subname = subname:lower()
	end
	local last = basename:sub(-1, -1)
	if last ~= '/' then
		basename = basename .. '/'
	end
	if subname:find(basename, 0, true) == 1 then
		return true
	end
	return false
end


-----------------------------------------------------------------------
-- check single name element
-----------------------------------------------------------------------
function os.path.single(path)
	if string.match(path, '/') then
		return false
	end
	if windows then
		if string.match(path, '\\') then
			return false
		end
	end
	return true
end


-----------------------------------------------------------------------
-- expand user home
-----------------------------------------------------------------------
function os.path.expand(pathname)
	if not pathname:find('~') then
		return pathname
	end
	local home = ''
	if windows then
		home = os.getenv('USERPROFILE')
	else
		home = os.getenv('HOME')
	end
	if pathname == '~' then
		return home
	end
	local head = pathname:sub(1, 2)
	if windows then
		if head == '~/' or head == '~\\' then
			return home .. '\\' .. pathname:sub(3, -1)
		end
	elseif head == '~/' then
		return home .. '/' .. pathname:sub(3, -1)
	end
	return pathname
end


-----------------------------------------------------------------------
-- get lua executable
-----------------------------------------------------------------------
function os.interpreter()
	if os.argv == nil then
		io.stderr:write("cannot get arguments (arg), recompiled your lua\n")
		return nil
	end
	local lua = os.argv[-1]
	if lua == nil then
		io.stderr:write("cannot get executable name, recompiled your lua\n")
	end
	if os.path.single(lua) then
		local path = os.path.which(lua)
		if not os.path.isabs(path) then
			return os.path.abspath(path)
		end
		return path
	end
	return os.path.abspath(lua)
end


-----------------------------------------------------------------------
-- get script name
-----------------------------------------------------------------------
function os.scriptname()
	if os.argv == nil then
		io.stderr:write("cannot get arguments (arg), recompiled your lua\n")
		return nil
	end
	local script = os.argv[0]
	if script == nil then
		io.stderr:write("cannot get script name, recompiled your lua\n")
	end
	return os.path.abspath(script)
end


-----------------------------------------------------------------------
-- get environ
-----------------------------------------------------------------------
function os.environ(name, default)
	local value = os.getenv(name)
	if os.envmap ~= nil and type(os.envmap) == 'table' then
		local t = os.envmap[name]
		value = (t ~= nil and type(t) == 'string') and t or value
	end
	if value == nil then
		return default
	elseif type(default) == 'boolean' then
		value = value:lower()
		if value == '0' or value == '' or value == 'no' then
			return false
		elseif value == 'false' or value == 'n' or value == 'f' then
			return false
		else
			return true
		end
	elseif type(default) == 'number' then
		value = tonumber(value)
		if value == nil then
			return default
		else
			return value
		end
	elseif type(default) == 'string' then
		return value
	elseif type(default) == 'table' then
		return value:sep(',')
	end
end


-----------------------------------------------------------------------
-- case insensitive
-----------------------------------------------------------------------
function os.path.case_insensitive()
	if windows then
		return true
	end
	local eos = os.getenv('OS')
	eos = eos ~= nil and eos or ''
	eos = eos:lower()
	if eos:sub(1, 7) == 'windows' then
		return true
	end
	return false
end


-----------------------------------------------------------------------
-- generate random seed
-----------------------------------------------------------------------
function math.random_init()
	-- random seed from os.time()
	local seed = tostring(os.time() * 1000)
	seed = seed .. tostring(math.random(99999999))
	if os.argv ~= nil then
		for _, key in ipairs(os.argv) do
			seed = seed .. '/' .. key
		end
	end
	local ppid = os.getenv('PPID')
	seed = (ppid ~= nil) and (seed .. '/' .. ppid) or seed
	-- random seed from socket.gettime()
	local status, socket = pcall(require, 'socket')
	if status then
		seed = seed .. tostring(socket.gettime())
	end
	-- random seed from _ZL_RANDOM
	local rnd = os.getenv('_ZL_RANDOM')
	if rnd ~= nil then
		seed = seed .. rnd
	end
	seed = seed .. tostring(os.clock() * 10000000)
	if os.native and os.native.tickcount then
		seed = seed .. tostring(os.native.tickcount())
	end
	local number = 0
	for i = 1, seed:len() do
		local k = string.byte(seed:sub(i, i))
		number = ((number * 127) % 0x7fffffff) + k
	end
	math.randomseed(number)
end


-----------------------------------------------------------------------
-- math random string
-----------------------------------------------------------------------
function math.random_string(N)
	local text = ''
	for i = 1, N do
		local k = math.random(0, 26 * 2 + 10 - 1)
		if k < 26 then
			text = text .. string.char(0x41 + k)
		elseif k < 26 * 2 then
			text = text .. string.char(0x61 + k - 26)
		elseif k < 26 * 2 + 10 then
			text = text .. string.char(0x30 + k - 26 * 2)
		else
		end
	end
	return text
end


-----------------------------------------------------------------------
-- parse option
-----------------------------------------------------------------------
function os.getopt(argv)
	local args = {}
	local options = {}
	argv = argv ~= nil and argv or os.argv
	if argv == nil then
		return nil, nil
	elseif (#argv) == 0 then
		return options, args
	end
	local count = #argv
	local index = 1
	while index <= count do
		local arg = argv[index]
		local head = arg:sub(1, 1)
		if arg ~= '' then
			if head ~= '-' then
				break
			end
			if arg == '-' then
				options['-'] = ''
			elseif arg == '--' then
				options['-'] = '-'
			elseif arg:match('^-%d+$') then
				options['-'] = arg:sub(2)
			else
				local part = arg:split('=')
				options[part[1]] = part[2] ~= nil and part[2] or ''
			end
		end
		index = index + 1
	end
	while index <= count do
		table.insert(args, argv[index])
		index = index + 1
	end
	return options, args
end


-----------------------------------------------------------------------
-- call vim function
-----------------------------------------------------------------------
function call(funcname, args)
	if vim.fn.has('nvim') == 0 then
		local argv = vim.eval('[]')
		for _, arg in ipairs(args) do
			argv:add(arg)
		end
		return vim.fn.call(funcname, argv)
	else
		return vim.fn.call(funcname, args)
	end
end


-----------------------------------------------------------------------
-- call function
-----------------------------------------------------------------------
if vim ~= nil then
	vim.call_function = call
end


-----------------------------------------------------------------------
-- test1
-----------------------------------------------------------------------
function test1(x, y)
	print(x, y, x + y)
end


-----------------------------------------------------------------------
-- 
-----------------------------------------------------------------------
function test2()
	return os.pwd()
end


-----------------------------------------------------------------------
-- check if __name__ == '__main__'
-----------------------------------------------------------------------
if not pcall(debug.getlocal, 4, 1) then
	-- print('suck')
end



