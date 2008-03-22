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

DogTag_funcs[#DogTag_funcs+1] = function(DogTag)

-- #AUTODOC_NAMESPACE DogTag

local L = DogTag.L

local newList, newSet, del, deepCopy = DogTag.newList, DogTag.newSet, DogTag.del, DogTag.deepCopy
local select2 = DogTag.select2
local getNamespaceList = DogTag.getNamespaceList
local memoizeTable = DogTag.memoizeTable
local kwargsToKwargTypes = DogTag.kwargsToKwargTypes
local fsNeedUpdate, fsNeedQuickUpdate, codeToFunction, codeToEventList, eventData, clearCodes
DogTag_funcs[#DogTag_funcs+1] = function()
	fsNeedUpdate = DogTag.fsNeedUpdate
	fsNeedQuickUpdate = DogTag.fsNeedQuickUpdate
	codeToFunction = DogTag.codeToFunction
	codeToEventList = DogTag.codeToEventList
	eventData = DogTag.eventData
	clearCodes = DogTag.clearCodes
end

local fsToFrame = {}
DogTag.fsToFrame = fsToFrame
local fsToCode = {}
DogTag.fsToCode = fsToCode
local fsToNSList = {}
DogTag.fsToNSList = fsToNSList
local fsToKwargs = {}
DogTag.fsToKwargs = fsToKwargs

local Tags = { ["Base"] = {} }
DogTag.Tags = Tags
local AddonFinders = { ["Base"] = {} }
DogTag.AddonFinders = AddonFinders

local sortStringList = DogTag.sortStringList

DogTag.__colors = {
	minHP = { 1, 0, 0 },
	midHP = { 1, 1, 0 },
	maxHP = { 0, 1, 0 },
	unknown = { 0.8, 0.8, 0.8 },
	hostile = { 226/255, 45/255, 75/255 },
	neutral = { 1, 1, 34/255 },
	friendly = { 0.2, 0.8, 0.15 },
	civilian = { 48/255, 113/255, 191/255 },
}
for class, data in pairs(_G.RAID_CLASS_COLORS) do
	DogTag.__colors[class] = { data.r, data.g, data.b, }
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
		Tags[namespace] = {}
	end
	if Tags["Base"][tag] or Tags[namespace][tag] then
		error(("Bad argument #3 to `AddTag'. %q already registered"):format(tag), 2)
	end
	local tagData = newList()
	Tags[namespace][tag] = tagData
	
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
			if types:match("^tuple%-") then
				if key ~= "..." then
					error("arg must have its key be ... if it is a tuple.", 2)
				end
				local tupleTypes = types:sub(7)
				local t = newSet((';'):split(tupleTypes))
				for k in pairs(t) do
					if k ~= "nil" and k ~= "number" and k ~= "string" and k ~= "boolean" then
						error("arg can only have tuples of nil, number, string, or boolean", 2)
					end
				end
				if t["boolean"] and (next(t, "boolean") or next(t) ~= "boolean") then
					error("arg cannot specify both boolean and something else", 2)
				end
				t = del(t)
				arg[i+1] = "tuple-" .. sortStringList(tupleTypes)
			else
				local t = newSet((';'):split(types))
				for k in pairs(t) do
					if k ~= "nil" and k ~= "number" and k ~= "string" and k ~= "undef" and k ~= "boolean" then
						error("arg must have nil, number, string, undef, boolean, or tuple", 2)
					end
				end
				if not key:match("^[a-z]+$") then
					error("arg must have its key be a string of lowercase letters.", 2)
				end
				if t["nil"] and t["undef"] then
					error("arg cannot specify both nil and undef", 2)
				end
				if t["boolean"] and (next(t, "boolean") or next(t) ~= "boolean") then
					error("arg cannot specify both boolean and something else", 2)
				end
				t = del(t)
				arg[i+1] = sortStringList(types)
			end
		end
		tagData.arg = arg
	end
	if data.alias then
		if type(data.alias) == "string" then
			tagData.alias = data.alias
		else -- function
			tagData.alias = data.alias()
			tagData.aliasFunc = data.alias
		end
	else
		local ret = data.ret
		if type(ret) == "string" then
			tagData.ret = sortStringList(ret)
			if ret then
				local rets = newSet((";"):split(ret))
				for k in pairs(rets) do
					if k ~= "nil" and k ~= "number" and k ~= "string" and k ~= "boolean" then
						error("ret must have nil, number, string, or boolean", 2)
					end
				end
				rets = del(rets)
			end
		elseif type(ret) == "function" then
			tagData.ret = ret
		else
			error(("ret must be a string or a function which returns a string, got %s"):format(type(ret)), 2)
		end
		if data.events then
			if type(data.events) == "string" then
				tagData.events = sortStringList(data.events)
			elseif type(data.events) == "function" then
				tagData.events = data.events
			else
				error(("events must be a string, function, or nil, got %s"):format(type(data.events)), 2)
			end
		end
		tagData.alias = data.fakeAlias
		if type(data) == "function" then
			tagData.static = data.static
		else
			tagData.static = data.static and true or nil
		end
		if tagData.static and tagData.events then
			error("Cannot specify both static and events", 2)
		end
		if type(data.code) ~= "function" then
			error(("code must be a function, got %s"):format(type(data.code)), 2)
		end
		tagData.code = data.code
		tagData.dynamicCode = data.dynamicCode and true or nil
	end
	tagData.doc = data.doc
	tagData.example = data.example
	tagData.category = data.category
	del(data)
end

local call__func, call__kwargs, call__code, call__nsList
local function call()
	return call__func(call__kwargs)
end

local function errorhandler(err)
	local _, minor = LibStub(MAJOR_VERSION)
	return geterrorhandler()(("%s.%d: Error with code %q%s. %s"):format(MAJOR_VERSION, minor, call__code, call__nsList == "Base" and "" or " (" .. call__nsList .. ")", err))
end

local function updateFontString(fs)
	fsNeedUpdate[fs] = nil
	fsNeedQuickUpdate[fs] = nil
	local code = fsToCode[fs]
	local nsList = fsToNSList[fs]
	local kwargs = fsToKwargs[fs]
	local kwargTypes = kwargsToKwargTypes[kwargs]
	local func = codeToFunction[nsList][kwargTypes][code]
	DogTag.__isMouseOver = DogTag.__lastMouseover == fsToFrame[fs]
	call__func, call__kwargs, call__code, call__nsList = func, kwargs, code, nsList
	local success, ret, alpha = xpcall(call, errorhandler)
	call__func, call__kwargs, call__code, call__nsList = nil, nil, nil, nil
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

function DogTag:AddAddonFinder(namespace, kind, name, func)
	if type(namespace) ~= "string" then
		error(("Bad argument #2 to `AddAddonFinder'. Expected %q, got %q"):format("string", type(namespace)), 2)
	end
	if type(kind) ~= "string" then
		error(("Bad argument #3 to `AddAddonFinder'. Expected %q, got %q"):format("string", type(kind)), 2)
	end
	if kind ~= "_G" and kind ~= "LibStub" and kind ~= "Rock" and kind ~= "AceLibrary" then
		error(("Bad argument #3 to `AddAddonFinder'. Expected %q, %q, %q or %q, got %q"):format("_G", "LibStub", "Rock", "AceLibrary", kind), 2)
	end
	if type(name) ~= "string" then
		error(("Bad argument #4 to `AddAddonFinder'. Expected %q, got %q"):format("string", type(name)), 2)
	end
	if type(func) ~= "function" then
		error(("Bad argument #5 to `AddAddonFinder'. Expected %q, got %q"):format("function", type(func)), 2)
	end
	if not AddonFinders[namespace] then
		AddonFinders[namespace] = {}
	end
	AddonFinders[namespace][newList(kind, name, func)] = true
end

local subLibraries = {}
DogTag.subLibraries = subLibraries
function DogTag:AddSubLibrary(major)
	subLibraries[major] = true
end

function DogTag:ADDON_LOADED()
	AceLibrary = _G.AceLibrary
	for namespace, data in pairs(AddonFinders) do
		local refresh = false
		local tmp_data = data
		data = newList()
		AddonFinders[namespace] = data
		for k in pairs(tmp_data) do
			local kind, name, func = k[1], k[2], k[3]
			if kind == "_G" then
				if _G[name] then
					tmp_data[k] = nil
					del(k)
					func(_G[name])
					refresh = true
				end
			elseif kind == "AceLibrary" then
				if AceLibrary and AceLibrary:HasInstance(name) then
					tmp_data[k] = nil
					del(k)
					func(AceLibrary(name))
					refresh = true
				end
			elseif kind == "Rock" then
				if Rock and Rock:HasLibrary(name) then
					tmp_data[k] = nil
					del(k)
					func(Rock:GetLibrary(name))
					refresh = true
				end
			elseif kind == "LibStub" then
				if Rock then
					Rock:HasLibrary(name) -- try to load
				end
				if AceLibrary then
					AceLibrary:HasInstance(name) -- try to load
				end
				if LibStub:GetLibrary(name, true) then
					tmp_data[k] = nil
					del(k)
					func(LibStub:GetLibrary(name))
					refresh = true
				end
			end
		end
		for k in pairs(tmp_data) do
			data[k] = true
		end
		tmp_data = del(tmp_data)
		if refresh then
			clearCodes(namespace)
		end
	end
end

end
