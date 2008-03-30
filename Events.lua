local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_MINOR_VERSION then
	_G.DogTag_MINOR_VERSION = MINOR_VERSION
end

-- #AUTODOC_NAMESPACE DogTag

DogTag_funcs[#DogTag_funcs+1] = function(DogTag)

local newList, del, deepCopy = DogTag.newList, DogTag.del, DogTag.deepCopy
local getNamespaceList = DogTag.getNamespaceList
local memoizeTable = DogTag.memoizeTable
local select2 = DogTag.select2
local kwargsToKwargTypes = DogTag.kwargsToKwargTypes
local codeToFunction, evaluate, fsToKwargs, fsToFrame, fsToNSList, updateFontString
local fsNeedUpdate, fsNeedQuickUpdate
local _clearCodes
DogTag_funcs[#DogTag_funcs+1] = function()
	codeToFunction = DogTag.codeToFunction
	evaluate = DogTag.evaluate
	fsToFrame = DogTag.fsToFrame
	fsToKwargs = DogTag.fsToKwargs
	fsToNSList = DogTag.fsToNSList
	updateFontString = DogTag.updateFontString
	for fs in pairs(fsToFrame) do
		fsNeedQuickUpdate[fs] = true
	end
	_clearCodes = DogTag._clearCodes
end

local EventHandlers

if DogTag.oldLib then
	fsNeedUpdate = DogTag.oldLib.fsNeedUpdate
	for k in pairs(fsNeedUpdate) do
		fsNeedUpdate[k] = nil
	end
	fsNeedQuickUpdate = DogTag.oldLib.fsNeedQuickUpdate
	for k in pairs(fsNeedQuickUpdate) do
		fsNeedQuickUpdate[k] = nil
	end
	EventHandlers = DogTag.oldLib.EventHandlers or {}
	TimerHandlers = DogTag.oldLib.TimerHandlers or {}
else
	fsNeedUpdate = {}
	fsNeedQuickUpdate = {}
	EventHandlers = {}
	TimerHandlers = {}
end
DogTag.fsNeedUpdate = fsNeedUpdate
DogTag.fsNeedQuickUpdate = fsNeedQuickUpdate
DogTag.EventHandlers = EventHandlers
DogTag.TimerHandlers = TimerHandlers

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
		t[""] = false
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
	local callbacks_mt_mt = {__index=function(self, kwargTypes)
		local t = newList()
		self[kwargTypes] = t
		return t
	end}
	local callbacks_mt = {__index=function(self, nsList)
		local t = setmetatable(newList(), callbacks_mt_mt)
		self[nsList] = t
		return t
	end}
	if DogTag.oldLib then
		callbacks = DogTag.oldLib.callbacks
		setmetatable(callbacks, nil)
		for nsList, callbacks_nsList in pairs(callbacks) do
			setmetatable(callbacks_nsList, nil)
			local tmp = {}
			for k,v in pairs(callbacks_nsList) do
				tmp[k] = v
				callbacks_nsList[k] = nil
			end
			for kwargTypes, callbacks_nsList_kwargTypes in pairs(tmp) do
				local kwargs = next(callbacks_nsList_kwargTypes)
				if kwargs ~= nil then
					local realKwargTypes = kwargsToKwargTypes[kwargs]
					callbacks_nsList[realKwargTypes] = newList()
					for kwargs, callbacks_nsList_kwargTypes_kwargs in pairs(callbacks_nsList_kwargTypes) do
						callbacks_nsList[realKwargTypes][memoizeTable(deepCopy(kwargs))] = callbacks_nsList_kwargTypes_kwargs
					end
				end
			end
		end
		setmetatable(callbacks, callbacks_mt)
		for k, v in pairs(callbacks) do
			setmetatable(v, callbacks_mt_mt)
		end
	else
		callbacks = setmetatable({}, callbacks_mt)
	end
end
DogTag.callbacks = callbacks

local eventData = setmetatable({}, {__index = function(self, key)
	local t = newList()
	self[key] = t
	return t
end})
DogTag.eventData = eventData

function DogTag.hasEvent(event)
	return not not rawget(eventData, event)
end

--[[
Notes:
	Adds a callback that will be called if the code in question is to be updated.
Arguments:
	string - the tag sequence
	function - the function to be called
	tuple - extra namespaces to register with, can be in any order
	[optional] kwargs - a dictionary of default kwargs for all tags in the code to receive
Example:
	LibStub("LibDogTag-3.0"):AddCallback("[Name]", function(code, kwargs)
		-- do something here
	end, "Unit", { unit = 'player' })
]]
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

--[[
Notes:
	Remove a callback that has been previously added
Arguments:
	string - the tag sequence
	function - the function to be called
	tuple - extra namespaces to register with, can be in any order
	[optional] kwargs - a dictionary of default kwargs for all tags in the code to receive
Example:
	LibStub("LibDogTag-3.0"):RemoveCallback("[Name]", func, "Unit", { unit = 'player' })
]]
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

local function OnEvent(this, event, ...)
	if DogTag[event] then
		DogTag[event](DogTag, event, ...)
	end
	for namespace, data in pairs(EventHandlers) do
		if data[event] then
			for func in pairs(data[event]) do
				func(event, ...)
			end
		end
	end
	local arg1 = (...)
	for nsList, codeToEventList_nsList in pairs(codeToEventList) do
		for kwargTypes, codeToEventList_nsList_kwargTypes in pairs(codeToEventList_nsList) do
			for code, eventList in pairs(codeToEventList_nsList_kwargTypes) do
				if eventList then
					local eventList_event = eventList[event]
					if eventList_event then
						local good = false
						local checkKwargs = false
						local mustEvaluate = false
						local checkTable = false
						local multiArg = false
						if eventList_event == true then
							good = true
						elseif type(eventList_event) == "table" then
							good = true
							checkTable = true
						else
							local tab = newList(("#"):split(eventList_event))
							if #tab == 1 then
								if eventList_event == arg1 then
									good = true
								elseif eventList_event:match("^%$") then
									good = true
									checkKwargs = eventList_event:sub(2)
								elseif eventList_event:match("^%[.*%]$") then
									good = true
									mustEvaluate = eventList_event
								end
								tab = del(tab)
							else
								good = true
								multiArg = tab
							end
						end
						if good then
							local callbacks_nsList_kwargTypes = callbacks[nsList][kwargTypes]
							for kwargs, callbacks_nsList_kwargTypes_kwargs in pairs(callbacks_nsList_kwargTypes) do
								good = true
								if multiArg then
									good = false
									for i, v in ipairs(multiArg) do
										local arg = select(i, ...)
										if not arg then
											good = false
										elseif v == arg then
											good = true
										elseif v:match("^%$") then
											good = kwargs[v:sub(2)] == arg
										elseif v:match("^%[.*%]$") then
											good = evaluate(v, nsList, kwargs) == arg
										else
											good = false
										end
										if not good then
											break
										end
									end
									multiArg = del(multiArg)
								elseif checkTable then
									good = false
									for k in pairs(eventList_event) do
										if k == arg1 then
											good = true
										else
											local multiArg = newList(("#"):split(k))
											for i, v in ipairs(multiArg) do
												local arg = select(i, ...)
												if not arg then
													good = false
												elseif v == arg then
													good = true
												elseif v:match("^%$") then
													good = kwargs[v:sub(2)] == arg
												elseif v:match("^%[.*%]$") then
													good = evaluate(v, nsList, kwargs) == arg
												else
													good = false
												end
												if not good then
													break
												end
											end
											multiArg = del(multiArg)
										end
										if good then
											break
										end
									end
								elseif mustEvaluate then
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
	for fs, param in pairs(eventData_event) do
		local kwargs = fsToKwargs[fs]
		local nsList = fsToNSList[fs]
		local good = false
		local checkKwargs = false
		local mustEvaluate = false
		local checkTable = false
		local multiArg = false
		if param == true then
			good = true
		elseif type(param) == "table" then
			good = true
			checkTable = true
		else
			local tab = newList(("#"):split(param))
			if #tab == 1 then
				if param == arg1 then
					good = true
				elseif param:match("^%$") then
					good = true
					checkKwargs = param:sub(2)
				elseif param:match("^%[.*%]$") then
					good = true
					mustEvaluate = param
				end
				tab = del(tab)
			else
				good = true
				multiArg = tab
			end
		end
		if good then
			good = true
			if multiArg then
				good = false
				for i, v in ipairs(multiArg) do
					local arg = select(i, ...)
					if not arg then
						good = false
					elseif v == arg then
						good = true
					elseif v:match("^%$") then
						good = kwargs[v:sub(2)] == arg
					elseif v:match("^%[.*%]$") then
						good = evaluate(v, nsList, kwargs) == arg
					else
						good = false
					end
					if not good then
						break
					end
				end
			elseif checkTable then
				good = false
				for k in pairs(param) do
					if k == arg1 then
						good = true
					else	
						local multiArg = newList(("#"):split(k))
						for i, v in ipairs(multiArg) do
							local arg = select(i, ...)
							if not arg then
								good = false
							elseif v == arg then
								good = true
							elseif v:match("^%$") then
								good = kwargs[v:sub(2)] == arg
							elseif v:match("^%[.*%]$") then
								good = evaluate(v, nsList, kwargs) == arg
							else
								good = false
							end
							if not good then
								break
							end
						end
						multiArg = del(multiArg)
					end
					if good then
						break
					end
				end
			elseif mustEvaluate then
				good = evaluate(mustEvaluate, nsList, kwargs) == arg1
			elseif checkKwargs then
				good = kwargs[checkKwargs] == arg1
			end
			if good then
				fsNeedUpdate[fs] = true
			end
		end
	end
end
frame:SetScript("OnEvent", OnEvent)

local GetMilliseconds
if DogTag_DEBUG then
	function GetMilliseconds()
		return math.floor(GetTime() * 1000 + 0.5)
	end
else
	function GetMilliseconds()
		return GetTime() * 1000
	end
end

local nextTime = 0
local nextUpdateTime = 0
local nextSlowUpdateTime = 0
local num = 0
local function OnUpdate(this, elapsed)
	_clearCodes()
	num = num + 1
	local currentTime = GetMilliseconds()
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
	if currentTime >= nextTime then
		DogTag:FireEvent("FastUpdate")
		if currentTime >= nextUpdateTime then
			nextUpdateTime = currentTime + 150
			DogTag:FireEvent("Update")
		end
		if currentTime >= nextSlowUpdateTime then
			nextSlowUpdateTime = currentTime + 10000
			DogTag:FireEvent("SlowUpdate")
		end
		nextTime = currentTime + 50
		local currentTime_1000 = currentTime/1000
		for i = 1, 9 do
			for ns, data in pairs(TimerHandlers) do
				local data_i = data[i]
				if data_i then
					for func in pairs(data_i) do
						func(num, currentTime_1000)
					end
				end
			end
		end
		
		for fs in pairs(fsNeedUpdate) do
			updateFontString(fs)
		end
	end	
	for fs in pairs(fsNeedQuickUpdate) do
		updateFontString(fs)
	end
end
frame:SetScript("OnUpdate", OnUpdate)

--[[
Notes:
	Register a function to be called when the event is fired
	This should only be called by sublibraries
Arguments:
	string - the namespace to mark ownership with
	string - the name of the event
	function - the function to be called
Example:
	LibStub("LibDogTag-3.0"):AddEventHandler("MyNamespace", "PLAYER_LOGIN", function(event, ...)
		-- do something here.
	end)
]]
function DogTag:AddEventHandler(namespace, event, func)
	if type(namespace) ~= "string" then
		error(("Bad argument #2 to `AddEventHandler'. Expected %q, got %q"):format("string", type(namespace)), 2)
	end
	if type(event) ~= "string" then
		error(("Bad argument #3 to `AddEventHandler'. Expected %q, got %q"):format("string", type(event)), 2)
	end
	if type(func) ~= "function" then
		error(("Bad argument #4 to `AddEventHandler'. Expected %q, got %q"):format("function", type(func)), 2)
	end
	if not EventHandlers[namespace] then
		EventHandlers[namespace] = newList()
	end
	if not EventHandlers[namespace][event] then
		EventHandlers[namespace][event] = newList()
	end
	EventHandlers[namespace][event][func] = true
end

--[[
Notes:
	Remove an event handler that has been previously added
	This should only be called by sublibraries
Arguments:
	string - the namespace to mark ownership with
	string - the name of the event
	function - the function to be called
Example:
	LibStub("LibDogTag-3.0"):RemoveEventHandler("MyNamespace", "PLAYER_LOGIN", func)
]]
function DogTag:RemoveEventHandler(namespace, event, func)
	if type(namespace) ~= "string" then
		error(("Bad argument #2 to `RemoveEventHandler'. Expected %q, got %q"):format("string", type(namespace)), 2)
	end
	if type(event) ~= "string" then
		error(("Bad argument #3 to `RemoveEventHandler'. Expected %q, got %q"):format("string", type(event)), 2)
	end
	if type(func) ~= "function" then
		error(("Bad argument #4 to `RemoveEventHandler'. Expected %q, got %q"):format("function", type(func)), 2)
	end
	local EventHandlers_namespace = EventHandlers[namespace]
	if not EventHandlers_namespace then
		return
	end
	local EventHandlers_namespace_event = EventHandlers_namespace[event]
	if not EventHandlers_namespace_event then
		return
	end
	EventHandlers_namespace_event[func] = nil
	if not next(EventHandlers_namespace_event) then
		EventHandlers_namespace[event] = del(EventHandlers_namespace_event)
	end
	if not next(EventHandlers_namespace) then
		EventHandlers[namespace] = del(EventHandlers_namespace)
	end
end

--[[
Notes:
	Fire an event that any tags, handlers, or callbacks will see.
Arguments:
	string - name of the event
	tuple - a tuple of arguments
Example:
	LibStub("LibDogTag-3.0"):FireEvent("MyEvent", "Data", "goes", "here", 52)
]]
function DogTag:FireEvent(event, ...)
	OnEvent(frame, event, ...)
end

--[[
Notes:
	Register a function to be called roughly every 0.05 seconds
	This should only be called by sublibraries
Arguments:
	string - the namespace to mark ownership with
	function - the function to be called
	[optional] number - a number from 1 to 9 specifying the priority it will be called compared to other timers. 1 being called first and 9 being called last. Is 5 by default.
Example:
	LibStub("LibDogTag-3.0"):AddTimerHandler("MyNamespace", function(num, currentTime)
		-- do something here.
	end)
]]
function DogTag:AddTimerHandler(namespace, func, priority)
	if type(namespace) ~= "string" then
		error(("Bad argument #2 to `AddTimerHandler'. Expected %q, got %q"):format("string", type(namespace)), 2)
	end
	if type(func) ~= "function" then
		error(("Bad argument #3 to `AddTimerHandler'. Expected %q, got %q"):format("function", type(func)), 2)
	end
	if not priority then
		priority = 5
	elseif type(priority) ~= "number" then
		error(("Bad argument #4 to `AddTimerHandler'. Expected %q, got %q"):format("number", type(priority)), 2)
	elseif math.floor(priority) ~= priority then
		error("Bad argument #4 to `AddTimerHandler'. Expected integer, got number", 2)
	elseif priority < 1 or priority > 9 then
		error(("Bad argument #4 to `AddTimerHandler'. Expected [1, 9], got %d"):format(priority), 2)
	end
	self:RemoveTimerHandler(namespace, func)
	if not TimerHandlers[namespace] then
		TimerHandlers[namespace] = newList()
	end
	if not TimerHandlers[namespace][priority] then
		TimerHandlers[namespace][priority] = newList()
	end
	TimerHandlers[namespace][priority][func] = true
end

--[[
Notes:
	Remove a timer handler that has previously been added
	This should only be called by sublibraries
Arguments:
	string - the namespace to mark ownership with
	function - the function to be called
Example:
	LibStub("LibDogTag-3.0"):RemoveTimerHandler("MyNamespace", func)
]]
function DogTag:RemoveTimerHandler(namespace, func)
	if type(namespace) ~= "string" then
		error(("Bad argument #2 to `RemoveTimerHandler'. Expected %q, got %q"):format("string", type(namespace)), 2)
	end
	if type(func) ~= "function" then
		error(("Bad argument #3 to `RemoveTimerHandler'. Expected %q, got %q"):format("function", type(func)), 2)
	end
	if not TimerHandlers[namespace] then
		return
	end
	for k, v in pairs(TimerHandlers[namespace]) do
		v[func] = nil
		if not next(v) then
			TimerHandlers[namespace][k] = del(v)
		end
	end
	if not next(TimerHandlers[namespace]) then
		TimerHandlers[namespace] = del(TimerHandlers[namespace])
	end
end

end