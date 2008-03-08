--[[
Name: LibDogTag-3.0
Revision: $Rev$
Author: Cameron Kenneth Knight (ckknight@gmail.com)
Website: http://www.wowace.com/
Description: A library to provide a markup syntax
]]

local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_MINOR_VERSION then
	_G.DogTag_MINOR_VERSION = MINOR_VERSION
end

DogTag_funcs[#DogTag_funcs+1] = function()

local DogTag = _G.DogTag

-- #AUTODOC_NAMESPACE DogTag

local oldLib
if next(DogTag) ~= nil then
	oldLib = {}
	for k,v in pairs(DogTag) do
		oldLib[k] = v
		DogTag[k] = nil
	end
end
DogTag.oldLib = oldLib
local L = DogTag__L
DogTag.L = L

local poolNum = 0
local newList, newDict, newSet, del
do
	local pool = setmetatable({}, {__mode='k'})
	function newList(...)
		poolNum = poolNum + 1
		local t = next(pool)
		if t then
			pool[t] = nil
			for i = 1, select('#', ...) do
				t[i] = select(i, ...)
			end
		else
			t = { ... }
		end
		return t
	end
	function newDict(...)
		poolNum = poolNum + 1
		local t = next(pool)
		if t then
			pool[t] = nil
		else
			t = {}
		end
		for i = 1, select('#', ...), 2 do
			t[select(i, ...)] = select(i+1, ...)
		end
		return t
	end
	function newSet(...)
		poolNum = poolNum + 1
		local t = next(pool)
		if t then
			pool[t] = nil
		else
			t = {}
		end
		for i = 1, select('#', ...) do
			t[select(i, ...)] = true
		end
		return t
	end
	function del(t)
		if not t then
			error("Bad argument #1 to `del'. Expected table, got nil.", 2)
		end
		if pool[t] then
			error("Double-free syndrome.", 2)
		end
		pool[t] = true
		poolNum = poolNum - 1
		for k in pairs(t) do
			t[k] = nil
		end
		t[''] = true
		t[''] = nil
		return nil
	end
	function deepDel(t)
		if type(t) == "table" then
			for k,v in pairs(t) do
				deepDel(v)
				deepDel(k)
			end
			del(t)
		end
		return nil
	end
end
DogTag.newList, DogTag.newDict, DogTag.newSet, DogTag.del, DogTag.deepDel = newList, newDict, newSet, del, deepDel

local DEBUG = _G.DogTag_DEBUG -- set in test.lua
if DEBUG then
	DogTag.getPoolNum = function()
		return poolNum
	end
	DogTag.setPoolNum = function(value)
		poolNum = value
	end
end

local FakeGlobals = { ["Base"] = {} }
DogTag.FakeGlobals = FakeGlobals
local Tags = { ["Base"] = {} }
DogTag.Tags = Tags

local function sortStringList(s)
	if not s then
		return nil
	end
	local list = newList((";"):split(s))
	table.sort(list)
	local q = table.concat(list, ';')
	list = del(list)
	return q
end

function DogTag:AddTag(namespace, tag, data)
	if type(namespace) ~= "string" then
		error(("Bad argument #2 to `AddTag'. Expected %q, got %q"):format("string", type(namespace)), 2)
	end
	if type(tag) ~= "string" then
		error(("Bad argument #3 to `AddTag'. Expected %q, got %q"):format("string", type(tag)), 2)
	end
	if type(data) ~= "table" then
		error(("Bad argument #4 to `AddTag'. Expected %q, got %q"):format("table", type(data)), 2)
	end
	
	if not Tags[namespace] then
		Tags[namespace] = newList()
	end
	if Tags["Base"][tag] or Tags[namespace][tag] then
		error(("Bad argument #3 to `AddTag'. %q already registered"):format(tag), 2)
	end
	local tagData = newList()
	Tags[namespace][tag] = tagData
	
	if data.alias then
		if type(data.alias) == "string" then
			tagData.alias = data.alias
		else -- function
			tagData.alias = data.alias()
			tagData.aliasFunc = data.alias
		end
	else
		local arg = data.arg
		if arg then
			if type(arg) ~= "table" then
				error("arg must be a table", 2)
			end
			if #arg % 3 ~= 0 then
				error("arg must be a table with a length a multiple of 3", 2)
			end
			for i = 1, #arg, 3 do
				local key, types, default = arg[i], arg[i+1], arg[i+2]
				if type(key) ~= "string" then
					error("arg must have its keys as strings", 2)
				end
				if type(types) ~= "string" then
					error("arg must have its types as strings", 2)
				end
				if types ~= "list-number" and types ~= "list-string" then
					local a,b,c = (';'):split(types)
					if a ~= "nil" and a ~= "number" and a ~= "string" then
						error("arg must have nil, number, string, list-number, or list-string", 2)
					end
					if b and b ~= "nil" and b ~= "number" and b ~= "string" then
						error("arg must have nil, number, or string", 2)
					end
					if c and c ~= "nil" and c ~= "number" and c ~= "string" then
						error("arg must have nil, number, or string", 2)
					end
				elseif key ~= "..." then
					error("arg must have its key be ... if a list-number or list-string.", 2)
				end
				arg[i+1] = sortStringList(types)
			end
			tagData.arg = arg
		end
		local ret = data.ret
		if type(ret) == "string" then
			tagData.ret = sortStringList(ret)
			if ret then
				local a,b,c = (";"):split(ret)
				if a ~= "nil" and a ~= "number" and a ~= "string" and a ~= "same" then
					error("ret must have same, nil, number, or string", 2)
				end
				if b and b ~= "nil" and b ~= "number" and b ~= "string" and b ~= "same" then
					error("ret must have same, nil, number, or string", 2)
				end
				if c and c ~= "nil" and c ~= "number" and c ~= "string" and c ~= "same" then
					error("ret must have same, nil, number, or string", 2)
				end
			end
		elseif type(ret) == "function" then
			tagData.ret = ret
		else
			error(("ret must be a string or a function which returns a string, got %s"):format(type(ret)), 2)
		end
		tagData.events = sortStringList(data.events)
		local globals = data.globals
		tagData.globals = sortStringList(globals)
		if globals then
			globals = newList((';'):split(globals))
			for _,v in ipairs(globals) do
				if not v:find("%.") and not _G[v] then
					error(("Unknown global: %q"):format(v))
				end
			end
			globals = del(globals)
		end
		tagData.alias = data.fakeAlias
	end
	tagData.doc = data.doc
	tagData.example = data.example
	tagData.category = data.category
	if not data.alias then
		tagData.code = data.code
	end
	del(data)
end

end