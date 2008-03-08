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
local kwargsToKey = DogTag.kwargsToKey

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
	local codeToEventList_mt = {__index = function(self, kwargsKey)
		local t = newList()
		self[kwargsKey] = t
		return t
	end}
	codeToEventList = setmetatable({}, {__index = function(self, nsList)
		local t = setmetatable(newList(), codeToEventList_mt)
		self[nsList] = t
		return t
	end})
end
DogTag.codeToEventList = codeToEventList

local function refreshEvents()
	local totalEvents = newList()
	for nsList, codeToEventList_nsList in pairs(codeToEventList) do
		for kwargsKey, codeToEventList_nsList_kwargsKey in pairs(codeToEventList_nsList) do
			for code, eventList in pairs(codeToEventList_nsList_kwargsKey) do
				if eventList then
					for event in pairs(eventList) do
						totalEvents[event] = true
					end
				end
			end
		end
	end
	totalEvents = del(totalEvents)
end
DogTag.refreshEvents = refreshEvents

local callbacks
do
	local callbacks_mt = {__index=function(self, kwargsKey)
		local t = newList()
		self[kwargsKey] = t
		return t
	end}
	callbacks = setmetatable({}, {__index=function(self, nsList)
		local t = setmetatable(newList(), callbacks_mt)
		self[nsList] = t
		return t
	end})
end

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
	local kwargsKey = kwargsToKey(kwargs)
	local codeToEventList_nsList_kwargsKey = codeToEventList[nsList][kwargsKey]
	local eventList = codeToEventList_nsList_kwargsKey[code]
	if eventList == nil then
		local _ = DogTag.codeToFunction[nsList][kwargsKey][code]
		eventList = codeToEventList_nsList_kwargsKey[code]
		assert(eventList ~= nil)
	end
	local callbacks_nsList_kwargsKey = callbacks[nsList][kwargsKey]
	kwargs = memoizeTable(deepCopy(kwargs or false))
	local callbacks_nsList_kwargsKey_kwargs = callbacks_nsList_kwargsKey[kwargs]
	if not callbacks_nsList_kwargsKey_kwargs then
		callbacks_nsList_kwargsKey_kwargs = newList()
		callbacks_nsList_kwargsKey[kwargs] = callbacks_nsList_kwargsKey_kwargs
	end
	local callbacks_nsList_kwargsKey_kwargs_code = callbacks_nsList_kwargsKey_kwargs[code]
	if callbacks_nsList_kwargsKey_kwargs_code then
		if type(callbacks_nsList_kwargsKey_kwargs_code) == "table" then
			callbacks_nsList_kwargsKey_kwargs_code[#callbacks_nsList_kwargsKey_kwargs_code+1] = callback
		else
			callbacks_nsList_kwargsKey_kwargs[code] = newList(callbacks_nsList_kwargsKey_kwargs_code, callback)
		end
	else
		callbacks_nsList_kwargsKey_kwargs[code] = callback
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
	
	local kwargsKey = kwargsToKey(kwargs)
	
	local callbacks_nsList_kwargsKey = callbacks[nsList][kwargsKey]
	
	kwargs = memoizeTable(deepCopy(kwargs or false))
	
	local callbacks_nsList_kwargsKey_kwargs = callbacks_nsList_kwargsKey[kwargs]
	if not callbacks_nsList_kwargsKey_kwargs then
		return
	end
	
	local callbacks_nsList_kwargsKey_kwargs_code = callbacks_nsList_kwargsKey_kwargs[code]
	if not callbacks_nsList_kwargsKey_kwargs_code then
		return
	end
	
	if type(callbacks_nsList_kwargsKey_kwargs_code) == "table" then
		for i, v in ipairs(callbacks_nsList_kwargsKey_kwargs_code) do
			if v == callback then
				table.remove(callbacks_nsList_kwargsKey_kwargs_code, i)
				break
			end
		end
	else -- function
		callbacks_nsList_kwargsKey_kwargs[code] = nil
		if not next(callbacks_nsList_kwargsKey_kwargs) then
			callbacks_nsList_kwargsKey[kwargs] = nil
		end
	end
end

local function OnEvent(this, event, arg1)
	for nsList, codeToEventList_nsList in pairs(codeToEventList) do
		for kwargsKey, codeToEventList_nsList_kwargsKey in pairs(codeToEventList_nsList) do
			for code, eventList in pairs(codeToEventList_nsList_kwargsKey) do
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
							local callbacks_nsList_kwargsKey = callbacks[nsList][kwargsKey]
							for kwargs, callbacks_nsList_kwargsKey_kwargs in pairs(callbacks_nsList_kwargsKey) do
								good = true
								if mustEvaluate then
									good = DogTag.evaluate(mustEvaluate, nsList, kwargs) == arg1
								elseif checkKwargs then
									good = kwargs[checkKwargs] == arg1
								end
								if good then
									local c = callbacks_nsList_kwargsKey_kwargs[code]
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
end
frame:SetScript("OnEvent", OnEvent)

local function OnUpdate(this, elapsed)
end
frame:SetScript("OnUpdate", OnUpdate)

end