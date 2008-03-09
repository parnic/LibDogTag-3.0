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

local L = DogTag__L
DogTag.L = L

local newList, del, deepCopy = DogTag.newList, DogTag.del, DogTag.deepCopy
local select2 = DogTag.select2
local getNamespaceList = DogTag.getNamespaceList
local memoizeTable = DogTag.memoizeTable
local kwargsToKwargTypes = DogTag.kwargsToKwargTypes
local fsNeedUpdate, fsNeedQuickUpdate, codeToFunction, codeToEventList, eventData
DogTag_funcs[#DogTag_funcs+1] = function()
	fsNeedUpdate = DogTag.fsNeedUpdate
	fsNeedQuickUpdate = DogTag.fsNeedQuickUpdate
	codeToFunction = DogTag.codeToFunction
	codeToEventList = DogTag.codeToEventList
	eventData = DogTag.eventData
end

local fsToFrame = {}
DogTag.fsToFrame = fsToFrame
local fsToCode = {}
DogTag.fsToCode = fsToCode
local fsToNSList = {}
DogTag.fsToNSList = fsToNSList
local fsToKwargs = {}
DogTag.fsToKwargs = fsToKwargs

local FakeGlobals = { ["Base"] = {} }
DogTag.FakeGlobals = FakeGlobals
local Tags = { ["Base"] = {} }
DogTag.Tags = Tags

local sortStringList = DogTag.sortStringList

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
					if not key:match("^[a-z]+$") then
						error("arg must have its key be a string of lowercase letters.", 2)
					end
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
		if type(globals) == "string" then
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
		elseif type(globals) == "function" then
			tagData.globals = globals
		elseif globals then
			error(("globals must be a string, a function which returns a string, or nil, got %s"):format(type(globals)), 2)
		end
		tagData.alias = data.fakeAlias
	end
	tagData.doc = data.doc
	tagData.example = data.example
	tagData.category = data.category
	if not data.alias then
		tagData.code = data.code
		if type(data.code) ~= "string" and type(data.code) ~= "function" then
			error(("code must be a string or a function which returns a string, got %s"):format(type(data.code)), 2)
		end
	end
	del(data)
end

local function updateFontString(fs)
	fsNeedUpdate[fs] = nil
	fsNeedQuickUpdate[fs] = nil
	local code = fsToCode[fs]
	local nsList = fsToNSList[fs]
	local kwargs = fsToKwargs[fs]
	local kwargTypes = kwargsToKwargTypes[kwargs]
	local func = codeToFunction[nsList][kwargTypes][code]
	DogTag.__isMouseover = DogTag.__lastMouseover == fsToFrame[fs]
	local success, ret, alpha = pcall(func, kwargs)
	if success then
		fs:SetText(ret)
		if alpha then
			if alpha < 0 then
				alpha = 0
			elseif alpha > 1 then
				alpha = 1
			end
			fs:SetAlpha(alpha)
		end
	else
		geterrorhandler()(("%s.%d: Error with code %q%s. %s"):format(MAJOR_VERSION, MINOR_VERSION, code, nsList == "Base" and "" or " (" .. nsList .. ")", ret))
	end
end
DogTag.updateFontString = updateFontString

function DogTag:AddFontString(fs, frame, code, ...)
	if type(fs) ~= "table" then
		error(("Bad argument #2 to `AddFontString'. Expected %q, got %q."):format("table", type(fs)), 2)
	end
	if type(frame) ~= "table" then
		error(("Bad argument #3 to `AddFontString'. Expected %q, got %q."):format("table", type(frame)), 2)
	end
	if type(code) ~= "string" then
		error(("Bad argument #4 to `AddFontString'. Expected %q, got %q."):format("string", type(code)), 2)
	end
	local n = select('#', ...)
	local kwargs
	if n > 0 then
		kwargs = select(n, ...)
		if type(kwargs) == "table" then
			n = n - 1
		else
			kwargs = nil
		end
	end
	for i = 1, n do
		if type(select(i, ...)) ~= "string" then
			error(("Bad argument #%d to `AddFontString'. Expected %q, got %q"):format(i+4, "string", type(select(i, ...))), 2)
		end
	end
	
	local nsList = getNamespaceList(select2(1, n, ...))
	
	kwargs = memoizeTable(deepCopy(kwargs))
	
	if fsToCode[fs] then
		if fsToFrame[fs] == frame and fsToCode[fs] == code and fsToNSList[fs] == nsList and fsToKwargs[fs] == kwargs then
			fsNeedUpdate[fs] = true
			return
		end
		self:RemoveFontString(fs)
	end
	fsToFrame[fs] = frame
	fsToCode[fs] = code
	fsToNSList[fs] = nsList
	fsToKwargs[fs] = kwargs
	
	local kwargTypes = kwargsToKwargTypes[kwargs]
	
	local codeToEventList_nsList_kwargTypes_code = codeToEventList[nsList][kwargTypes][code]
	if codeToEventList_nsList_kwargTypes_code == nil then
		local _ = codeToFunction[nsList][kwargTypes][code]
		codeToEventList_nsList_kwargTypes_code = codeToEventList[nsList][kwargTypes][code]
		assert(codeToEventList_nsList_kwargTypes_code ~= nil)
	end
	if codeToEventList_nsList_kwargTypes_code then
		for event, arg in pairs(codeToEventList_nsList_kwargTypes_code) do
			eventData[event][fs] = arg
		end
	end
	
	updateFontString(fs)
end

function DogTag:RemoveFontString(fs)
	if type(fs) ~= "table" then
		error(("Bad argument #2 to `RemoveFontString'. Expected %q, got %q"):format("table", type(fs)), 2)
	end
	local code = fsToCode[fs]
	if not code then
		return
	end
	local frame = fsToFrame[fs]
	local nsList = fsToNSList[fs]
	local kwargs = fsToKwargs[fs]
	
	fsToCode[fs], fsToFrame[fs], fsToNSList[fs], fsToKwargs[fs] = nil, nil, nil, nil
	
	local kwargTypes = kwargsToKwargTypes[kwargs]
	
	local codeToEventList_nsList_kwargTypes_code = codeToEventList[nsList][kwargTypes][code]
	if codeToEventList_nsList_kwargTypes_code then
		for event in pairs(codeToEventList_nsList_kwargTypes_code) do
			eventData[event][fs] = nil
		end
	end
	
	fs:SetText(nil)
end

function DogTag:AddFakeGlobal(namespace, key, value)
	if type(namespace) ~= "string" then
		error(("Bad argument #2 to `AddFakeGlobal'. Expected %q, got %q"):format("string", type(namespace)), 2)
	end
	if type(key) ~= "string" then
		error(("Bad argument #3 to `AddFakeGlobal'. Expected %q, got %q"):format("string", type(key)), 2)
	end
	if type(value) ~= "table" and type(value) ~= "function" then
		error(("Bad argument #4 to `AddFakeGlobal'. Expected %q or %q, got %q"):format("table", "function", type(value)), 2)
	end
	if not FakeGlobals[namespace] then
		FakeGlobals[namespace] = newList()
	end
	FakeGlobals[namespace]["__" .. key] = value
end

end