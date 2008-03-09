local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_MINOR_VERSION then
	_G.DogTag_MINOR_VERSION = MINOR_VERSION
end

DogTag_funcs[#DogTag_funcs+1] = function()

local DogTag = _G.DogTag

local newList, del, deepCopy = DogTag.newList, DogTag.del, DogTag.deepCopy
local getNamespaceList = DogTag.getNamespaceList
local memoizeTable = DogTag.memoizeTable
local select2 = DogTag.select2
local kwargsToKwargTypes = DogTag.kwargsToKwargTypes
local codeToFunction, evaluate, fsToKwargs, fsToFrame, fsToNSList, updateFontString
DogTag_funcs[#DogTag_funcs+1] = function()
	codeToFunction = DogTag.codeToFunction
	evaluate = DogTag.evaluate
	fsToFrame = DogTag.fsToFrame
	fsToKwargs = DogTag.fsToKwargs
	fsToNSList = DogTag.fsToNSList
	updateFontString = DogTag.updateFontString
end

local fsNeedUpdate = {}
DogTag.fsNeedUpdate = fsNeedUpdate
local fsNeedQuickUpdate = {}
DogTag.fsNeedQuickUpdate = fsNeedQuickUpdate

local frame
if DogTag.oldLib then
	frame = DogTag.oldLib.frame
	frame:SetScript("OnEvent", nil)
	frame:SetScript("OnUpdate", nil)
	frame:Show()
	frame:UnregisterAllEvents()
else
	frame = CreateFrame("Frame")
end
DogTag.frame = frame
frame:RegisterAllEvents()

local codeToEventList
do
	local codeToEventList_mt = {__index = function(self, kwargTypes)
		local t = newList()
		self[kwargTypes] = t
		return t
	end}
	codeToEventList = setmetatable({}, {__index = function(self, nsList)
		local t = setmetatable(newList(), codeToEventList_mt)
		self[nsList] = t
		return t
	end})
end
DogTag.codeToEventList = codeToEventList

local callbacks
do
	local callbacks_mt = {__index=function(self, kwargTypes)
		local t = newList()
		self[kwargTypes] = t
		return t
	end}
	callbacks = setmetatable({}, {__index=function(self, nsList)
		local t = setmetatable(newList(), callbacks_mt)
		self[nsList] = t
		return t
	end})
end
DogTag.callbacks = nil

local eventData = setmetatable({}, {__index = function(self, key)
	local t = {}
	self[key] = t
	return t
end})
DogTag.eventData = eventData

function DogTag:AddCallback(code, callback, ...)
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
	local nsList = getNamespaceList(select2(1, n, ...))
	local kwargTypes = kwargsToKwargTypes[kwargs]
	local codeToEventList_nsList_kwargTypes = codeToEventList[nsList][kwargTypes]
	local eventList = codeToEventList_nsList_kwargTypes[code]
	if eventList == nil then
		local _ = codeToFunction[nsList][kwargTypes][code]
		eventList = codeToEventList_nsList_kwargTypes[code]
		assert(eventList ~= nil)
	end
	local callbacks_nsList_kwargTypes = callbacks[nsList][kwargTypes]
	kwargs = memoizeTable(deepCopy(kwargs or false))
	local callbacks_nsList_kwargTypes_kwargs = callbacks_nsList_kwargTypes[kwargs]
	if not callbacks_nsList_kwargTypes_kwargs then
		callbacks_nsList_kwargTypes_kwargs = newList()
		callbacks_nsList_kwargTypes[kwargs] = callbacks_nsList_kwargTypes_kwargs
	end
	local callbacks_nsList_kwargTypes_kwargs_code = callbacks_nsList_kwargTypes_kwargs[code]
	if callbacks_nsList_kwargTypes_kwargs_code then
		if type(callbacks_nsList_kwargTypes_kwargs_code) == "table" then
			callbacks_nsList_kwargTypes_kwargs_code[#callbacks_nsList_kwargTypes_kwargs_code+1] = callback
		else
			callbacks_nsList_kwargTypes_kwargs[code] = newList(callbacks_nsList_kwargTypes_kwargs_code, callback)
		end
	else
		callbacks_nsList_kwargTypes_kwargs[code] = callback
	end
end

function DogTag:RemoveCallback(code, callback, ...)
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
	local nsList = getNamespaceList(select2(1, n, ...))
	
	local kwargTypes = kwargsToKwargTypes[kwargs]
	
	local callbacks_nsList_kwargTypes = callbacks[nsList][kwargTypes]
	
	kwargs = memoizeTable(deepCopy(kwargs or false))
	
	local callbacks_nsList_kwargTypes_kwargs = callbacks_nsList_kwargTypes[kwargs]
	if not callbacks_nsList_kwargTypes_kwargs then
		return
	end
	
	local callbacks_nsList_kwargTypes_kwargs_code = callbacks_nsList_kwargTypes_kwargs[code]
	if not callbacks_nsList_kwargTypes_kwargs_code then
		return
	end
	
	if type(callbacks_nsList_kwargTypes_kwargs_code) == "table" then
		for i, v in ipairs(callbacks_nsList_kwargTypes_kwargs_code) do
			if v == callback then
				table.remove(callbacks_nsList_kwargTypes_kwargs_code, i)
				break
			end
		end
	else -- function
		callbacks_nsList_kwargTypes_kwargs[code] = nil
		if not next(callbacks_nsList_kwargTypes_kwargs) then
			callbacks_nsList_kwargTypes[kwargs] = nil
		end
	end
end

local function OnEvent(this, event, arg1)
	for nsList, codeToEventList_nsList in pairs(codeToEventList) do
		for kwargTypes, codeToEventList_nsList_kwargTypes in pairs(codeToEventList_nsList) do
			for code, eventList in pairs(codeToEventList_nsList_kwargTypes) do
				if eventList then
					local eventList_event = eventList[event]
					if eventList_event then
						local good = false
						local checkKwargs = false
						local mustEvaluate = false
						if eventList_event == true then
							good = true
						elseif eventList_event == arg1 then
							good = true
						elseif eventList_event:match("^%$") then
							good = true
							checkKwargs = eventList_event:sub(2)
						elseif eventList_event:match("^%[.*%]$") then
							good = true
							mustEvaluate = eventList_event
						end
						if good then
							local callbacks_nsList_kwargTypes = callbacks[nsList][kwargTypes]
							for kwargs, callbacks_nsList_kwargTypes_kwargs in pairs(callbacks_nsList_kwargTypes) do
								good = true
								if mustEvaluate then
									good = evaluate(mustEvaluate, nsList, kwargs) == arg1
								elseif checkKwargs then
									good = kwargs[checkKwargs] == arg1
								end
								if good then
									local c = callbacks_nsList_kwargTypes_kwargs[code]
									if c then
										if not kwargs then
											kwargs = nil
										end
										if type(c) == "function" then
											c(code, kwargs)
										else -- table
											for i,v in ipairs(c) do
												v(code, kwargs)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	
	local eventData_event = eventData[event]
	for fs, arg in pairs(eventData_event) do
		local good = false
		local checkKwargs = false
		local mustEvaluate = false
		if arg == true then
			good = true
		elseif arg == arg1 then
			good = true
		elseif arg:match("^%$") then
			good = true
			checkKwargs = eventList_event:sub(2)
		elseif arg:match("^%[.*%]$") then
			good = true
			mustEvaluate = arg
		end
		if good then
			good = true
			if mustEvaluate then
				local kwargs = fsToKwargs[fs]
				local nsList = fsToNSList[fs]
				good = evaluate(mustEvaluate, nsList, kwargs) == arg1
			elseif checkKwargs then
				local kwargs = fsToKwargs[fs]
				good = kwargs[checkKwargs] == arg1
			end
			if good then
				fsNeedUpdate[fs] = true
			end
		end
	end
end
frame:SetScript("OnEvent", OnEvent)

local timePassed = 0
local function OnUpdate(this, elapsed)
	timePassed = timePassed + elapsed
	local oldMouseover = DogTag.__lastMouseover
	local newMouseover = GetMouseFocus()
	DogTag.__lastMouseover = newMouseover
	if oldMouseover ~= DogTag.__lastMouseover then
		for fs, frame in pairs(fsToFrame) do
			if frame == oldMouseover or frame == newMouseover then
				-- TODO: only update if has a mouseover event
				fsNeedQuickUpdate[fs] = true
			end
		end
	end
	if timePassed >= 0.05 then
		timePassed = 0
		for fs in pairs(fsNeedUpdate) do
			updateFontString(fs)
		end
	end	
	for fs in pairs(fsNeedQuickUpdate) do
		updateFontString(fs)
	end
end
frame:SetScript("OnUpdate", OnUpdate)

end