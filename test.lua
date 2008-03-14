-- $Id$

local function escape_char(c)
	return ("\\%03d"):format(c:byte())
end

local function table_len(t)
	for i = 1, #t do
		if t[i] == nil then
			return i-1
		end
	end
	return #t
end

function pprint(...)
	print(ptostring(...))
end

local function key_sort(alpha, bravo)
	local type_alpha, type_bravo = type(alpha), type(bravo)
	if type_alpha ~= type_bravo then
		return type_alpha < type_bravo
	end
	
	if type_alpha == "string" then
		return alpha:lower() < bravo:lower()
	elseif type_alpha == "number" then
		return alpha < bravo
	elseif type_alpha == "table" then
		return tostring(alpha) < tostring(bravo)
	else
		return false
	end
end

local first_ptostring = true
function ptostring(...)
	local t = {}
	for i = 1, select('#', ...) do
		if i > 1 then
			t[#t+1] = ",\t"
		end
		local v = select(i, ...)
		if type(v) == "string" then
			t[#t+1] = (("%q"):format(v):gsub("[\001-\031\128-\255]", escape_char))
		elseif type(v) == "table" then
			t[#t+1] = "{ "
			local keys = {}
			for a in pairs(v) do
				keys[#keys+1] = a
			end
			table.sort(keys, key_sort)
			local first = true
			for _,a in ipairs(keys) do
				local b = v[a]
				if first then
					first = nil
				else
					t[#t+1] = ", "
				end
				if type(a) ~= "number" or a < 1 or a > table_len(v) then
					if type(a) == "string" and a:match("^[a-zA-Z_][a-zA-Z_0-9]*$") then
						t[#t+1] = a
						t[#t+1] = " = "
					else
						t[#t+1] = "["
						t[#t+1] = ptostring(a)
						t[#t+1] = "] = "
					end
				end
				t[#t+1] = ptostring(b)
			end
			t[#t+1] = " }"
		else
			t[#t+1] = tostring(v)
		end
	end
	return table.concat(t)
end

local function is_equal(alpha, bravo)
	if type(alpha) ~= type(bravo) then
		return false
	end
	
	if type(alpha) == "number" then
		return alpha == bravo or tostring(alpha) == tostring(bravo) or math.abs(alpha - bravo) < 1e-15
	elseif type(alpha) ~= "table" then
		return alpha == bravo
	end
	
	local num = 0
	for k,v in pairs(alpha) do
		num = num + 1
		if not is_equal(v, bravo[k]) then
			return false
		end
	end
	
	for k,v in pairs(bravo) do
		num = num - 1
	end
	if num ~= 0 then
		return false
	end
	return true
end

function assert_equal(alpha, bravo)
	if not is_equal(alpha, bravo) then
		error(("Assertion failed: %s == %s"):format(ptostring(alpha), ptostring(bravo)), 2)
	end
end

function geterrorhandler()
	return error
end

local function CreateFontString(parent, name, layer)
	local fs = {
		[0] = newproxy(), -- fake userdata
	}
	function fs:GetObjectType()
		return "FontString"
	end
	local text
	function fs:SetText(x)
		text = x
	end
	function fs:GetText()
		return text
	end
	local alpha = 1
	function fs:SetAlpha(a)
		alpha = a
	end
	function fs:GetAlpha()
		return alpha
	end
	return fs
end
local frames = {}
local frameRegisteredEvents = {}
local ALL_EVENTS = newproxy()
function CreateFrame(frameType, ...)
	local frame = {
		[0] = newproxy(), -- fake userdata
	}
	frames[frame] = true
	function frame:GetObjectType()
		return frameType
	end
	function frame:GetFrameType()
		return frameType
	end
	local scripts = {}
	function frame:SetScript(script, func)
		scripts[script] = func
	end
	function frame:GetScript(script)
		return scripts[script]
	end
	local events = {}
	frameRegisteredEvents[frame] = events
	function frame:RegisterEvent(event)
		events[event] = true
	end
	function frame:UnregisterEvent(event)
		events[event] = nil
	end
	function frame:UnregisterAllEvents()
		for event in pairs(events) do
			events[event] = nil
		end
	end
	function frame:RegisterAllEvents()
		events[ALL_EVENTS] = true
	end
	function frame:CreateFontString(...)
		return CreateFontString(frame, ...)
	end
	return frame
end

local currentTime = 1e5 -- initial time
function GetTime()
	return currentTime
end

function FireOnUpdate(elapsed)
	if not elapsed then
		elapsed = 1
	end
	currentTime = currentTime + elapsed
	for frame in pairs(frames) do
		local OnUpdate = frame:GetScript("OnUpdate")
		if OnUpdate then
			OnUpdate(frame, elapsed)
		end
	end
end

function FireEvent(event, ...)
	for frame in pairs(frames) do
		if frameRegisteredEvents[frame][event] or frameRegisteredEvents[frame][ALL_EVENTS] then
			local OnEvent = frame:GetScript("OnEvent")
			if OnEvent then
				OnEvent(frame, event, ...)
			end
		end
	end
end

local GetMouseFocus_data = nil
function GetMouseFocus()
	return GetMouseFocus_data
end

local IsAltKeyDown_data = nil
function IsAltKeyDown()
	return IsAltKeyDown_data
end

local IsShiftKeyDown_data = nil
function IsShiftKeyDown()
	return IsShiftKeyDown_data
end

local IsControlKeyDown_data = nil
function IsControlKeyDown()
	return IsControlKeyDown_data
end

DogTag_DEBUG = true

dofile("LibStub/LibStub.lua")
dofile("Localization/enUS.lua")
dofile("Helpers.lua")
dofile("LibDogTag-3.0.lua")
dofile("Parser.lua")
dofile("Compiler.lua")
dofile("Events.lua")
dofile("Modules/Math.lua")
dofile("Modules/Misc.lua")
dofile("Modules/Operators.lua")
dofile("Modules/TextManip.lua")
dofile("Cleanup.lua")

local DogTag = LibStub("LibDogTag-3.0")
local getPoolNum, setPoolNum = DogTag.getPoolNum, DogTag.setPoolNum
local parse = DogTag.parse
local standardize = DogTag.standardize

local function assert_table_usage(func, tableChange)
	local previousPoolNum = getPoolNum()
	func()
	local afterPoolNum = getPoolNum()
	local actualChange = afterPoolNum-previousPoolNum
	if tableChange ~= actualChange then
--		error(("Unexpected table usage: %d instead of expected %d"):format(actualChange, tableChange), 2)
	end
end

local function countTables(t)
	if type(t) ~= "table" then
		return 0
	end
	local n = 1
	for k, v in pairs(t) do
		n = n + countTables(k) + countTables(v)
	end
	return n
end

local function deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local x = {}
	for k,v in pairs(t) do
		x[k] = deepCopy(v)
	end
	return x
end

local old_parse = parse
function parse(arg)
	local start = DogTag.getPoolNum()
	local ret = old_parse(arg)
	local finish = DogTag.getPoolNum()
	local change = finish - start
	local num_tables = countTables(ret)
	if change ~= num_tables then
--		error(("Unknown table usage: %d instead of %d"):format(change, num_tables), 2)
	end
	local r = deepCopy(ret)
	DogTag.deepDel(ret)
	return r
end

local old_standardize = standardize
function standardize(arg)
	local realStart = DogTag.getPoolNum()
	local start = realStart - countTables(arg)
	local ret = old_standardize(arg)
	local finish = DogTag.getPoolNum()
	local change = finish - start
	local num_tables = countTables(ret)
	if change ~= num_tables then
--		error(("Unknown table usage: %d instead of %d"):format(change, num_tables), 2)
	end
	DogTag.setPoolNum(realStart)
	return ret
end

DogTag:Evaluate("")

local old_DogTag_Evaluate = DogTag.Evaluate
function DogTag:Evaluate(...)
	local start = DogTag.getPoolNum()
	local rets = { old_DogTag_Evaluate(self, ...) }
	local finish = DogTag.getPoolNum()
	local change = finish - start
	if change ~= 0 then
--		error(("Unknown table usage: %d instead of %d"):format(change, 0), 2)
	end
	return unpack(rets)
end

local old_DogTag_CleanCode = DogTag.CleanCode
function DogTag:CleanCode(...)
	local start = DogTag.getPoolNum()
	local ret = old_DogTag_CleanCode(self, ...)
	local finish = DogTag.getPoolNum()
	local change = finish - start
	if change ~= 0 then
--		error(("Unknown table usage: %d instead of %d"):format(change, 0), 2)
	end
	return ret
end

DogTag:AddTag("Base", "One", {
	code = [=[return 1]=],
	ret = "number",
	doc = "Return the number 1",
	example = '[One] => "1"',
	category = "Testing"
})

DogTag:AddTag("Base", "Two", {
	code = [=[return 2]=],
	ret = "number",
	doc = "Return the number 2",
	example = '[Two] => "2"',
	category = "Testing"
})

DogTag:AddTag("Base", "PlusOne", {
	code = [=[return ${number} + 1]=],
	arg = {
		'number', 'number', "@req"
	},
	ret = "number",
	doc = "Return the number 1",
	example = '[One] => "1"',
	category = "Testing"
})

DogTag:AddTag("Base", "Subtract", {
	code = [=[return ${left} - ${right}]=],
	arg = {
		'left', 'number', "@req",
		'right', 'number', "@req"
	},
	ret = "number",
	doc = "Subtract right from left",
	example = '[AddNumbers(1, 2)] => "-1"',
	category = "Testing"
})

DogTag:AddTag("Base", "SubtractFive", {
	alias = [=[Subtract(number, 5)]=],
	arg = {
		'number', 'number', '@req',
	},
	doc = "Subtract 5 from number",
	example = '[SubtractFive(10)] => "5"',
	category = "Testing",
})

DogTag:AddTag("Base", "SubtractFromFive", {
	alias = [=[Subtract(5, number)]=],
	arg = {
		'number', 'number', 0,
	},
	doc = "Subtract number from 5",
	example = '[SubtractFromFive(10)] => "-5"; [SubtractFromFive] => "5"',
	category = "Testing",
})

DogTag:AddTag("Base", "ReverseSubtract", {
	alias = [=[Subtract(right, left)]=],
	arg = {
		'left', 'number', "@req",
		'right', 'number', "@req"
	},
	ret = "number",
	doc = "Subtract left from right",
	example = '[ReverseSubtract(1, 2)] => "1"',
	category = "Testing"
})

DogTag:AddTag("Base", "AbsAlias", {
	alias = [=[number < 0 ? -number ! number]=],
	arg = {
		'number', 'number', "@req",
	},
	ret = "number",
	doc = "Get the absolute value of number",
	example = '[AbsAlias(5)] => "5"; [AbsAlias(-5)] => "5"',
	category = "Testing"
})

local GlobalCheck_data = "Hello World"
_G.testfunc = function()
	return GlobalCheck_data
end

DogTag:AddTag("Base", "GlobalCheck", {
	code = [=[return testfunc()]=],
	ret = "string;number;nil",
	doc = "Return the results of testfunc",
	globals = 'testfunc',
	example = '[GlobalCheck] => "Hello World"',
	category = "Testing"
})

testtable = {
	testfunc = function()
		return GlobalCheck_data
	end
}

DogTag:AddTag("Base", "SubGlobalCheck", {
	code = [=[return testtable_testfunc()]=],
	ret = "string;number;nil",
	doc = "Return the results of testtable.testfunc",
	globals = 'testtable.testfunc',
	example = '[GlobalCheck] => "Hello World"',
	category = "Testing"
})

local myfunc_num = 0
function _G.myfunc()
	myfunc_num = myfunc_num + 1
	return myfunc_num
end

DogTag:AddTag("Base", "FunctionNumberCheck", {
	code = [=[return myfunc()]=],
	ret = "number;nil",
	doc = "Return the results of myfunc",
	globals = 'myfunc',
	example = '[FunctionNumberCheck] => "1"',
	category = "Testing"
})


DogTag:AddTag("Base", "AbsoluteValue", {
	code = [=[return math_abs(${number})]=],
	arg = {
		'number', 'number', "@req",
	},
	ret = "number",
	globals = "math.abs",
	doc = "Get the absolute value of number",
	example = '[AbsoluteValue(5)] => "5"; [AbsoluteValue(-5)] => "5"',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckNumDefault", {
	code = [=[return ${value}]=],
	arg = {
		'value', 'number', 50
	},
	ret = "number",
	doc = "Return the given argument or 50",
	example = '[CheckStrDefault(1)] => "1"; [CheckStrDefault] => "50"',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckStrDefault", {
	code = [=[return ${value}]=],
	arg = {
		'value', 'string', 'Value'
	},
	ret = "string",
	doc = "Return the given argument or value",
	example = '[CheckStrDefault(1)] => "1"; [CheckStrDefault] => "Value"',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckNilDefault", {
	code = [=[return ${value}]=],
	arg = {
		'value', 'nil;number', false
	},
	ret = "nil;number",
	doc = "Return the given argument or nil",
	example = '[CheckNilDefault(1)] => "1"; [CheckNilDefault] => ""',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckNumTuple", {
	code = [=[return ("-"):join(${...})]=],
	arg = {
		'...', 'list-number', false
	},
	ret = "string",
	doc = "Join ... separated by dashes",
	example = '[CheckNumTuple(1)] => "1"; [CheckNumTuple] => ""',
	category = "Testing"
})

DogTag:AddTag("Base", "TupleAlias", {
	alias = [=[CheckNumTuple(5, ...)]=],
	arg = {
		'...', 'list-number', false
	},
	doc = "Join ... separated by dashes",
	example = '[TupleAlias(1)] => "1"; [TupleAlias] => ""',
	category = "Testing"
})

DogTag:AddTag("Base", "OtherTupleAlias", {
	alias = [=[Subtract(...)]=],
	arg = {
		'...', 'list-number', false
	},
	doc = "Subtract the values of ...",
	example = '[OtherTupleAlias(5, 2)] => "3"',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckAnotherNumTuple", {
	code = [=[return math_max(0, ${...})]=],
	arg = {
		'...', 'list-number', false
	},
	ret = "string",
	doc = "Return the largest number of ...",
	globals = 'math.max',
	example = '[CheckAnotherNumTuple(1)] => "1"; [CheckAnotherNumTuple] => "0"',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckStrTuple", {
	code = [=[
		local x = ''
		for i = 1, select('#', ${...}) do
			x = x .. select(i, ${...}):gsub('[aeiou]', 'y')
		end
		return x
	]=],
	arg = {
		'...', 'list-string', false
	},
	ret = "string",
	doc = "Join ..., replacing vowels with 'y'",
	example = '[CheckStrTuple("Hello")] => "Hylly"; [CheckStrTuple] => ""',
	category = "Testing"
})

DogTag:AddTag("Base", "CheckAnotherStrTuple", {
	code = [=[
		local x = ''
		for i = 1, ${#...} do
			x = x .. select(i, ${...}):gsub('[aeiou]', 'y')
		end
		return x
	]=],
	arg = {
		'...', 'list-string', false
	},
	ret = "string",
	doc = "Join ..., replacing vowels with 'y'",
	example = '[CheckAnotherStrTuple("Hello")] => "Hylly"; [CheckAnotherStrTuple] => ""',
	category = "Testing"
})

DogTag:AddTag("Base", "Reverse", {
	code = [=[return ${value}:reverse()]=],
	arg = {
		'value', 'string', '@req'
	},
	ret = "string",
	doc = "Reverse the characters in value",
	example = '[Reverse(Hello)] => "olleH"',
	category = "Testing",
})

DogTag:AddTag("Base", "OtherReverse", {
	code = [=[if ${value}:reverse() ~= "Stuff" then
		return ${value}:reverse()
	else
		return "ffutS"
	end]=],
	arg = {
		'value', 'string', '@req'
	},
	ret = "string",
	doc = "Reverse the characters in value",
	example = '[OtherReverse(Hello)] => "olleH"',
	category = "Testing",
})

DogTag:AddTag("Base", "KwargAndTuple", {
	code = [=[return ${value} * math_max(${...})]=],
	arg = {
		'value', 'number', '@req',
		'...', 'list-number', false
	},
	ret = 'number',
	globals = 'math.max';
	doc = "Return the maximum of ... multiplied by value",
	example = '[KwargAndTuple(5, 1, 2, 3)] => "15"',
})

DogTag:AddTag("Base", "TupleAndKwarg", {
	code = [=[return ${value} * math_max(${...})]=],
	arg = {
		'...', 'list-number', false,
		'value', 'number', '@req'
	},
	ret = 'number',
	globals = 'math.max';
	doc = "Return the maximum of ... multiplied by value",
	example = '[KwargAndTuple(5, 1, 2, 3)] => "15"',
})

DogTag:AddTag("Base", "Type", {
	code = [=[return ${value:type}]=],
	arg = {
		'value', 'number;nil;string', '@req'
	},
	ret = 'string',
	doc = "Return the type of value",
	example = '[Type(nil)] => "nil"; [Type("Hello")] => "string"; [Type(5)] => "number"',
})

DogTag:AddTag("Base", "ToString", {
	code = [=[return '`' .. ${value:string}:reverse():reverse() .. '`']=],
	arg = {
		'value', 'number;nil;string', '@req'
	},
	ret = 'string',
	doc = "Return value surrounded by tickmarks",
	example = '[ToString(nil)] => "``"; [ToString("Hello")] => "`Hello`"; [ToString(5)] => "`5`"',
})

local RetSame_types
DogTag:AddTag("Base", "RetSame", {
	code = [=[return ${value}]=],
	arg = {
		'value', 'number;nil;string', '@req'
	},
	ret = function(args)
		RetSame_types = args.value.types
		return args.value.types
	end
})

DogTag:AddTag("Base", "DynamicCodeTest", {
	code = function(args)
		if args.value.isLiteral then
			return ([=[return "literal, %s"]=]):format(tostring(args.value.value))
		else
			local value = args.value.value
			return ([=[return "dynamic, %s"]=]):format(value[1] == "tag" and value[2] or value[1])
		end
	end,
	arg = {
		'value', 'number;nil;string', '@req'
	},
	ret = "string",
})

local DynamicGlobalCheck_data = "Hello World"
local LiteralGlobalCheck_data = "Hello World"

dynamictable = {
	dynamictestfunc = function()
		return DynamicGlobalCheck_data
	end,
	literaltestfunc = function()
		return LiteralGlobalCheck_data
	end,
}

DogTag:AddTag("Base", "DynamicGlobalCheck", {
	code = function(args)
		if args.value.isLiteral then
			return [=[
				assert(not dynamictable_dynamictestfunc)
				return dynamictable_literaltestfunc()
			]=]
		else
			return [=[
				assert(not dynamictable_literaltestfunc)
				return dynamictable_dynamictestfunc()
			]=]
		end
	end,
	arg = {
		'value', 'nil;number;string', '@req'
	},
	ret = "string;number;nil",
	doc = "Return the results of testfunc",
	globals = function(args)
		if args.value.isLiteral then
			return 'dynamictable.literaltestfunc'
		else
			return 'dynamictable.dynamictestfunc'
		end
	end,
	example = '[DynamicGlobalCheck] => "Hello World"',
	category = "Testing"
})

_G.BlizzEventTest_num = 0
DogTag:AddTag("Base", "BlizzEventTest", {
	code = [=[
		_G.BlizzEventTest_num = _G.BlizzEventTest_num + 1
		return _G.BlizzEventTest_num
	]=],
	arg = {
		'value', 'string', "@req"
	},
	ret = "number",
	events = "FAKE_BLIZZARD_EVENT#$value",
	doc = "Return the results of BlizzEventTest_num after incrementing",
	example = '[BlizzEventTest] => "1"',
	category = "Testing"
})
_G.OtherBlizzEventTest_num = 0
DogTag:AddTag("Base", "OtherBlizzEventTest", {
	code = [=[
		_G.OtherBlizzEventTest_num = _G.OtherBlizzEventTest_num + 1
		return _G.OtherBlizzEventTest_num
	]=],
	ret = "number",
	events = "OTHER_FAKE_BLIZZARD_EVENT",
	doc = "Return the results of OtherBlizzEventTest_num after incrementing",
	example = '[OtherBlizzEventTest] => "1"',
	category = "Testing"
})

assert_equal(parse("[MyTag]"), { "tag", "MyTag" })
assert_equal(DogTag:CleanCode("[MyTag]"), "[MyTag]")
assert_equal(parse("Alpha [MyTag]"), {" ", "Alpha ", { "tag", "MyTag" } })
assert_equal(DogTag:CleanCode("Alpha [MyTag]"), "Alpha [MyTag]")
assert_equal(parse("[MyTag] Bravo"), {" ", { "tag", "MyTag" }, " Bravo" })
assert_equal(DogTag:CleanCode("[MyTag] Bravo"), "[MyTag] Bravo")
assert_equal(parse("Alpha [MyTag] Bravo"), {" ", "Alpha ", { "tag", "MyTag" }, " Bravo" })
assert_equal(DogTag:CleanCode("Alpha [MyTag] Bravo"), "Alpha [MyTag] Bravo")
assert_equal(parse("[Alpha][Bravo]"), { " ", { "tag", "Alpha" }, { "tag", "Bravo" } })
assert_equal(parse("[Alpha Bravo]"), { " ", { "tag", "Alpha" }, { "tag", "Bravo" } })
assert_equal(DogTag:CleanCode("[Alpha][Bravo]"), "[Alpha Bravo]")
assert_equal(parse("[Alpha][Bravo][Charlie]"), { " ", { "tag", "Alpha" }, { "tag", "Bravo" }, { "tag", "Charlie"} })
assert_equal(parse("[Alpha Bravo Charlie]"), { " ", { "tag", "Alpha" }, { "tag", "Bravo" }, { "tag", "Charlie"} })
assert_equal(DogTag:CleanCode("[Alpha][Bravo][Charlie]"), "[Alpha Bravo Charlie]")
assert_equal(DogTag:CleanCode("Alpha [Bravo][Charlie] Delta"), "Alpha [Bravo Charlie] Delta")
assert_equal(DogTag:CleanCode("[Alpha] [Bravo] [Charlie]"), "[Alpha] [Bravo] [Charlie]")
assert_equal(DogTag:CleanCode("Alpha [Bravo] [Charlie] Delta"), "Alpha [Bravo] [Charlie] Delta")

assert_equal(parse("[Alpha(Bravo)]"), { "tag", "Alpha", { "tag", "Bravo" } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo)]"), "[Alpha(Bravo)]")
assert_equal(parse("[Alpha(Bravo, Charlie)]"), { "tag", "Alpha", { "tag", "Bravo" }, { "tag", "Charlie"} })
assert_equal(DogTag:CleanCode("[Alpha(Bravo, Charlie)]"), "[Alpha(Bravo, Charlie)]")
assert_equal(parse("[Alpha:Delta]"), { "mod", "Delta", { "tag", "Alpha" } })
assert_equal(DogTag:CleanCode("[Alpha:Delta]"), "[Alpha:Delta]")
assert_equal(parse("[Alpha:Bravo:Charlie]"), { "mod", "Charlie", { "mod", "Bravo", { "tag", "Alpha" } } })
assert_equal(DogTag:CleanCode("[Alpha:Bravo:Charlie]"), "[Alpha:Bravo:Charlie]")
assert_equal(standardize(parse("[Alpha:Delta]")), { "tag", "Delta", { "tag", "Alpha" } })
assert_equal(standardize(parse("[Alpha:Bravo:Charlie]")), { "tag", "Charlie", { "tag", "Bravo", { "tag", "Alpha" } } })
assert_equal(parse("[Alpha:Delta(Echo)]"), { "mod", "Delta", { "tag", "Alpha" }, { "tag", "Echo" } })
assert_equal(DogTag:CleanCode("[Alpha:Delta(Echo)]"), "[Alpha:Delta(Echo)]")
assert_equal(parse("[Alpha(Bravo):Delta]"), { "mod", "Delta", { "tag", "Alpha", { "tag", "Bravo"} } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo):Delta]"), "[Alpha(Bravo):Delta]")
assert_equal(parse("[Alpha(Bravo, Charlie):Delta(Echo, Foxtrot)]"), { "mod", "Delta", { "tag", "Alpha", { "tag", "Bravo"}, {"tag", "Charlie"} }, {"tag", "Echo"}, {"tag", "Foxtrot"} })
assert_equal(DogTag:CleanCode("[Alpha(Bravo, Charlie):Delta(Echo, Foxtrot)]"), "[Alpha(Bravo, Charlie):Delta(Echo, Foxtrot)]")
assert_equal(parse("[Alpha:~Delta]"), { "~", { "mod", "Delta", { "tag", "Alpha" } } })
assert_equal(standardize(parse("[Alpha:~Delta]")), { "not", { "tag", "Delta", { "tag", "Alpha" } } })
assert_equal(standardize(parse("[not Alpha:Delta]")), { "not", { "tag", "Delta", { "tag", "Alpha" } } })
assert_equal(DogTag:CleanCode("[Alpha:~Delta]"), "[Alpha:~Delta]")
assert_equal(parse("[Alpha(Bravo, Charlie):~Delta(Echo, Foxtrot)]"), { "~", { "mod", "Delta", { "tag", "Alpha", { "tag", "Bravo"}, {"tag", "Charlie"} }, {"tag", "Echo"}, {"tag", "Foxtrot"} } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo, Charlie):~Delta(Echo, Foxtrot)]"), "[Alpha(Bravo, Charlie):~Delta(Echo, Foxtrot)]")
assert_equal(parse("[Func('Alpha')]"), { "tag", "Func", "Alpha" })
assert_equal(DogTag:CleanCode("[Func('Alpha')]"), '[Func("Alpha")]')
assert_equal(parse([=[[Func('Alp"ha')]]=]), { "tag", "Func", 'Alp"ha' })
assert_equal(DogTag:CleanCode([=[[Func('Alp"ha')]]=]), [=[[Func('Alp"ha')]]=])

assert_equal(parse(""), { "nil" })
assert_equal(parse("['']"), { "nil" })
assert_equal(parse('[""]'), { "nil" })
assert_equal(parse("[nil]"), { "nil" })
assert_equal(parse("[false]"), { "false" })
assert_equal(standardize(parse("[false]")), { "nil" })
assert_equal(parse("[true]"), { "true" })
assert_equal(standardize(parse("[true]")), "True")
assert_equal(DogTag:CleanCode("[nil]"), "")
assert_equal(DogTag:CleanCode("[nil nil]"), "[nil nil]")
assert_equal(DogTag:CleanCode("[false]"), "[false]")
assert_equal(DogTag:CleanCode("[false false]"), "[false false]")
assert_equal(DogTag:CleanCode("[true]"), "[true]")
assert_equal(DogTag:CleanCode("[true true]"), "[true true]")
assert_equal(parse("['Alpha']"), "Alpha")
assert_equal(parse('["Alpha"]'), "Alpha")
assert_equal(DogTag:CleanCode("['Alpha']"), "Alpha")
assert_equal(DogTag:CleanCode('["Alpha"]'), "Alpha")
assert_equal(parse("[1234]"), 1234)
assert_equal(parse("['1234']"), "1234")
assert_equal(standardize(parse("['1234']")), 1234)
assert_equal(DogTag:CleanCode("[1234]"), "[1234]")
assert_equal(parse("[-1234]"), -1234)
assert_equal(DogTag:CleanCode("[-1234]"), "[-1234]")
assert_equal(parse("[1234.5678]"), 1234.5678)
assert_equal(DogTag:CleanCode("[-1234.5678]"), "[-1234.5678]")
assert_equal(parse("[-1234.5678]"), -1234.5678)
assert_equal(DogTag:CleanCode("[-1234.5678]"), "[-1234.5678]")
assert_equal(parse("[1234e5]"), 123400000)
assert_equal(DogTag:CleanCode("[1234e5]"), "[123400000]")
assert_equal(parse("[1234e-5]"), 0.01234)
assert_equal(DogTag:CleanCode("[1234e-5]"), "[0.01234]")
assert_equal(parse("[-1234e5]"), -123400000)
assert_equal(DogTag:CleanCode("[-1234e5]"), "[-123400000]")
assert_equal(parse("[-1234e-5]"), -0.01234)
assert_equal(DogTag:CleanCode("[-1234e-5]"), "[-0.01234]")

assert_equal(parse("[1 + 2]"), { "+", 1, 2, })
assert_equal(DogTag:CleanCode("[1 + 2]"), "[1 + 2]")
assert_equal(parse("[1 - 2]"), { "-", 1, 2, })
assert_equal(DogTag:CleanCode("[1 - 2]"), "[1 - 2]")
assert_equal(parse("[1 * 2]"), { "*", 1, 2, })
assert_equal(DogTag:CleanCode("[1 * 2]"), "[1 * 2]")
assert_equal(parse("[1 / 2]"), { "/", 1, 2, })
assert_equal(DogTag:CleanCode("[1 / 2]"), "[1 / 2]")
assert_equal(parse("[1 ^ 2]"), { "^", 1, 2, })
assert_equal(DogTag:CleanCode("[1 ^ 2]"), "[1 ^ 2]")
assert_equal(parse("[1 % 2]"), { "%", 1, 2, })
assert_equal(DogTag:CleanCode("[1 % 2]"), "[1 % 2]")
assert_equal(parse("[1 < 2]"), { "<", 1, 2 })
assert_equal(DogTag:CleanCode("[1 < 2]"), "[1 < 2]")
assert_equal(parse("[1 > 2]"), { ">", 1, 2 })
assert_equal(DogTag:CleanCode("[1 > 2]"), "[1 > 2]")
assert_equal(parse("[1 <= 2]"), { "<=", 1, 2 })
assert_equal(DogTag:CleanCode("[1 <= 2]"), "[1 <= 2]")
assert_equal(parse("[1 >= 2]"), { ">=", 1, 2 })
assert_equal(DogTag:CleanCode("[1 >= 2]"), "[1 >= 2]")
assert_equal(parse("[1 = 2]"), { "=", 1, 2 })
assert_equal(DogTag:CleanCode("[1 = 2]"), "[1 = 2]")
assert_equal(parse("[1 ~= 2]"), { "~=", 1, 2 })
assert_equal(DogTag:CleanCode("[1 ~= 2]"), "[1 ~= 2]")
assert_equal(parse("[1 and 2]"), { "and", 1, 2 })
assert_equal(DogTag:CleanCode("[1 and 2]"), "[1 and 2]")
assert_equal(parse("[1 or 2]"), { "or", 1, 2 })
assert_equal(DogTag:CleanCode("[1 or 2]"), "[1 or 2]")
assert_equal(parse("[1 & 2]"), { "&", 1, 2 })
assert_equal(DogTag:CleanCode("[1 & 2]"), "[1 & 2]")
assert_equal(parse("[1 | 2]"), { "|", 1, 2 })
assert_equal(parse("[1 || 2]"), { "|", 1, 2 })
assert_equal(DogTag:CleanCode("[1 | 2]"), "[1 || 2]")
assert_equal(DogTag:CleanCode("[1 || 2]"), "[1 || 2]")
assert_equal(parse("[Alpha Bravo]"), { " ", { "tag", "Alpha" }, { "tag", "Bravo"}, })
assert_equal(DogTag:CleanCode("[Alpha Bravo]"), "[Alpha Bravo]")
assert_equal(parse("[1 ? 2]"), { "?", 1, 2 })
assert_equal(DogTag:CleanCode("[1 ? 2]"), "[1 ? 2]")
assert_equal(parse("[1 ? 2 ! 3]"), { "?", 1, 2, 3 })
assert_equal(DogTag:CleanCode("[1 ? 2 ! 3]"), "[1 ? 2 ! 3]")
assert_equal(parse("[if 1 then 2]"), { "if", 1, 2 })
assert_equal(DogTag:CleanCode("[if 1 then 2]"), "[if 1 then 2]")
assert_equal(parse("[if 1 then 2 else 3]"), { "if", 1, 2, 3 })

assert_equal(parse("[Func('Hello' 'There')]"), { "tag", "Func", {" ", "Hello", "There"} })
assert_equal(DogTag:CleanCode("[Func('Hello' 'There')]"), '[Func("Hello" "There")]')

assert_equal(standardize(parse("[1 & 2]")), { "and", 1, 2 })
assert_equal(standardize(parse("[1 | 2]")), { "or", 1, 2 })
assert_equal(standardize(parse("[1 || 2]")), { "or", 1, 2 })
assert_equal(standardize(parse("[1 ? 2]")), { "if", 1, 2 })
assert_equal(standardize(parse("[1 ? 2 ! 3]")), { "if", 1, 2, 3 })

assert_equal(parse("[1+2]"), { "+", 1, 2, })
assert_equal(parse("[1-2]"), { "-", 1, 2, })
assert_equal(parse("[1*2]"), { "*", 1, 2, })
assert_equal(parse("[1/2]"), { "/", 1, 2, })
assert_equal(parse("[1^2]"), { "^", 1, 2, })
assert_equal(parse("[1%2]"), { "%", 1, 2, })
assert_equal(parse("[1<2]"), { "<", 1, 2 })
assert_equal(parse("[1>2]"), { ">", 1, 2 })
assert_equal(parse("[1<=2]"), { "<=", 1, 2 })
assert_equal(parse("[1>=2]"), { ">=", 1, 2 })
assert_equal(parse("[1=2]"), { "=", 1, 2 })
assert_equal(parse("[1~=2]"), { "~=", 1, 2 })
assert_equal(parse("[1&2]"), { "&", 1, 2 })
assert_equal(parse("[1|2]"), { "|", 1, 2 })
assert_equal(parse("[1||2]"), { "|", 1, 2 })
assert_equal(parse("[1?2]"), { "?", 1, 2 })
assert_equal(parse("[1?2!3]"), { "?", 1, 2, 3 })

assert_equal(parse("[1 and 2 or 3]"), { "or", { "and", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 and 2 or 3]"), "[1 and 2 or 3]")
assert_equal(parse("[1 or 2 and 3]"), { "and", { "or", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 or 2 and 3]"), "[1 or 2 and 3]")
assert_equal(parse("[1 + 2 - 3]"), { "-", { "+", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 + 2 - 3]"), "[1 + 2 - 3]")
assert_equal(parse("[1 - 2 + 3]"), { "+", { "-", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 - 2 + 3]"), "[1 - 2 + 3]")
assert_equal(parse("[1 * 2 / 3]"), { "/", { "*", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 * 2 / 3]"), "[1 * 2 / 3]")
assert_equal(parse("[1 / 2 * 3]"), { "*", { "/", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 / 2 * 3]"), "[1 / 2 * 3]")
assert_equal(parse("[1 * 2 % 3]"), { "%", { "*", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 * 2 % 3]"), "[1 * 2 % 3]")
assert_equal(parse("[1 % 2 * 3]"), { "*", { "%", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 % 2 * 3]"), "[1 % 2 * 3]")

assert_equal(parse("[1 ? 2 and 3]"), { "?", 1, { "and", 2, 3 } })
assert_equal(DogTag:CleanCode("[1 ? 2 and 3]"), "[1 ? 2 and 3]")
assert_equal(parse("[1 and 2 ? 3]"), { "?", { "and", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 and 2 ? 3]"), "[1 and 2 ? 3]")
assert_equal(parse("[1 ? 2 and 3 ! 4 or 5]"), { "?", 1, { "and", 2, 3 }, { "or", 4, 5 } })
assert_equal(DogTag:CleanCode("[1 ? 2 and 3 ! 4 or 5]"), "[1 ? 2 and 3 ! 4 or 5]")
assert_equal(parse("[1 and 2 ? 3 ! 4]"), { "?", { "and", 1, 2 }, 3, 4 })
assert_equal(DogTag:CleanCode("[1 and 2 ? 3 ! 4]"), "[1 and 2 ? 3 ! 4]")
assert_equal(parse("[1 and 2 < 3]"), { "<", { "and", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 and 2 < 3]"), "[1 and 2 < 3]")
assert_equal(parse("[1 < 2 and 3]"), { "<", 1, { "and", 2, 3 } })
assert_equal(DogTag:CleanCode("[1 < 2 and 3]"), "[1 < 2 and 3]")
assert_equal(parse("[1 + 2 and 3]"), { "and", { "+", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 + 2 and 3]"), "[1 + 2 and 3]")
assert_equal(parse("[1 and 2 + 3]"), { "and", 1, { "+", 2, 3 } })
assert_equal(DogTag:CleanCode("[1 and 2 + 3]"), "[1 and 2 + 3]")
assert_equal(parse("[1 + 2 * 3]"), { "+", 1, { "*", 2, 3 }, })
assert_equal(DogTag:CleanCode("[1 + 2 * 3]"), "[1 + 2 * 3]")
assert_equal(parse("[1 * 2 + 3]"), { "+", { "*", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 * 2 + 3]"), "[1 * 2 + 3]")
assert_equal(parse("[1 * 2 ^ 3]"), { "*", 1, { "^", 2, 3 }, })
assert_equal(DogTag:CleanCode("[1 * 2 ^ 3]"), "[1 * 2 ^ 3]")
assert_equal(parse("[1 ^ 2 * 3]"), { "*", { "^", 1, 2 }, 3 })
assert_equal(DogTag:CleanCode("[1 ^ 2 * 3]"), "[1 ^ 2 * 3]")

assert_equal(parse("[(1 ^ 2) * 3]"), { "*", { "(", { "^", 1, 2 } }, 3 })
assert_equal(parse("[[1 ^ 2] * 3]"), { "*", { "[", { "^", 1, 2 } }, 3 })
-- pointless parenthesization should stay
assert_equal(DogTag:CleanCode("[(1 ^ 2) * 3]"), "[(1 ^ 2) * 3]")
assert_equal(DogTag:CleanCode("[[1 ^ 2] * 3]"), "[[1 ^ 2] * 3]")

assert_equal(parse("[(1) * 3]"), { "*", { "(", 1 }, 3 })
assert_equal(parse("[[1] * 3]"), { "*", { "[", 1 }, 3 })

-- but parenthesization of a tag, number, or string should go away
assert_equal(DogTag:CleanCode("[(1) * 3]"), "[1 * 3]")
assert_equal(DogTag:CleanCode("[[1] * 3]"), "[1 * 3]")
assert_equal(DogTag:CleanCode("[1 * (3)]"), "[1 * 3]")
assert_equal(DogTag:CleanCode("[1 * [3]]"), "[1 * 3]")
assert_equal(DogTag:CleanCode("[Func(('Hello') 'There')]"), '[Func("Hello" "There")]')
assert_equal(DogTag:CleanCode("[Func(['Hello'] 'There')]"), '[Func("Hello" "There")]')
assert_equal(DogTag:CleanCode("[Func('Hello' ('There'))]"), '[Func("Hello" "There")]')
assert_equal(DogTag:CleanCode("[Func('Hello' ['There'])]"), '[Func("Hello" "There")]')
assert_equal(DogTag:CleanCode("[(Alpha) * Bravo]"), "[Alpha * Bravo]")
assert_equal(DogTag:CleanCode("[[Alpha] * Bravo]"), "[Alpha * Bravo]")
assert_equal(DogTag:CleanCode("[(Alpha) * Bravo]"), "[Alpha * Bravo]")
assert_equal(DogTag:CleanCode("[[Alpha] * Bravo]"), "[Alpha * Bravo]")

assert_equal(parse("[1 ^ (2 * 3)]"), { "^", 1, { "(", { "*", 2, 3 } } })
assert_equal(parse("[1 ^ [2 * 3]]"), { "^", 1, { "[", { "*", 2, 3 } } })
assert_equal(DogTag:CleanCode("[1 ^ (2 * 3)]"), "[1 ^ (2 * 3)]")
assert_equal(DogTag:CleanCode("[1 ^ [2 * 3]]"), "[1 ^ [2 * 3]]")
assert_equal(parse("[(1 + 2) * 3]"), { "*", { "(", { "+", 1, 2 } }, 3 })
assert_equal(DogTag:CleanCode("[(1 + 2) * 3]"), "[(1 + 2) * 3]")
assert_equal(parse("[1 + (2 ? 3)]"), { "+", 1, { "(", { "?", 2, 3 } } })
assert_equal(DogTag:CleanCode("[1 + (2 ? 3)]"), "[1 + (2 ? 3)]")
assert_equal(parse("[(2 ? 3 ! 4) + 1]"), { "+", { "(", { "?", 2, 3, 4 } }, 1 })
assert_equal(DogTag:CleanCode("[(2 ? 3 ! 4) + 1]"), "[(2 ? 3 ! 4) + 1]")
assert_equal(parse("[1 + (if 2 then 3)]"), { "+", 1, { "(", { "if", 2, 3 } } })
assert_equal(DogTag:CleanCode("[1 + (if 2 then 3)]"), "[1 + (if 2 then 3)]")
assert_equal(parse("[(if 2 then 3 else 4) + 1]"), { "+", { "(", { "if", 2, 3, 4 } }, 1 })
assert_equal(DogTag:CleanCode("[(if 2 then 3 else 4) + 1]"), "[(if 2 then 3 else 4) + 1]")

assert_equal(parse("[Alpha(Bravo + Charlie)]"), { "tag", "Alpha", { "+", {"tag", "Bravo"}, {"tag", "Charlie"} } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo + Charlie)]"), "[Alpha(Bravo + Charlie)]")
assert_equal(parse("[Alpha (Bravo + Charlie)]"), { " ", {"tag", "Alpha"}, { "(", { "+", {"tag", "Bravo"}, {"tag", "Charlie"} } } })
assert_equal(DogTag:CleanCode("[Alpha (Bravo + Charlie)]"), "[Alpha (Bravo + Charlie)]")

assert_equal(parse("[not Alpha]"), { "not", { "tag", "Alpha" }, })
assert_equal(DogTag:CleanCode("[not Alpha]"), "[not Alpha]")
assert_equal(parse("[not not Alpha]"), { "not", { "not", { "tag", "Alpha" }, }, })
assert_equal(DogTag:CleanCode("[not not Alpha]"), "[not not Alpha]")
assert_equal(parse("[~Alpha]"), { "~", { "tag", "Alpha" }, })
assert_equal(DogTag:CleanCode("[~Alpha]"), "[~Alpha]")
assert_equal(parse("[~(1 > 2)]"), { "~", { "(", { ">", 1, 2 } }, })
assert_equal(DogTag:CleanCode("[~(1 > 2)]"), "[~(1 > 2)]")
assert_equal(parse("[not(1 > 2)]"), { "not", { "(", { ">", 1, 2 } }, })
assert_equal(DogTag:CleanCode("[not(1 > 2)]"), "[not (1 > 2)]")
assert_equal(standardize(parse("[~Alpha]")), { "not", { "tag", "Alpha" }, })

assert_equal(standardize(parse("[Alpha(bravo=(Charlie+2))]")), { "tag", "Alpha", kwarg = { bravo = { "+", { "tag", "Charlie" }, 2 } } })

assert_equal(parse("[Alpha(key=Bravo)]"), { "tag", "Alpha", kwarg = { key = { "tag", "Bravo" } } })
assert_equal(DogTag:CleanCode("[Alpha(key=Bravo)]"), "[Alpha(key=Bravo)]")
assert_equal(parse("[Alpha(Bravo, key=Charlie)]"), { "tag", "Alpha", { "tag", "Bravo" }, kwarg = { key = { "tag", "Charlie" } } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo, key=Charlie)]"), "[Alpha(Bravo, key=Charlie)]")
assert_equal(parse("[Alpha(bravo=Charlie, delta=Echo)]"), { "tag", "Alpha", kwarg = { bravo = { "tag", "Charlie" }, delta = { "tag", "Echo" } } })
assert_equal(DogTag:CleanCode("[Alpha(bravo=Charlie, delta=Echo)]"), "[Alpha(bravo=Charlie, delta=Echo)]")
assert_equal(DogTag:CleanCode("[Alpha(delta=Echo, bravo=Charlie)]"), "[Alpha(bravo=Charlie, delta=Echo)]")
assert_equal(parse("[Alpha((key=Bravo))]"), { "tag", "Alpha", { "(", { "=", { "tag", "key" }, { "tag", "Bravo" } } } })
assert_equal(DogTag:CleanCode("[Alpha(key = Bravo)]"), "[Alpha(key = Bravo)]")
assert_equal(DogTag:CleanCode("[Alpha((key=Bravo))]"), "[Alpha((key = Bravo))]")
assert_equal(parse("[Class(unit='mouseovertarget')]"), { "tag", "Class", kwarg = { unit = "mouseovertarget" } })
assert_equal(parse("[Alpha(key=Bravo, Charlie)]"), { "tag", "Alpha", { "tag", "Charlie" }, kwarg = { key = { "tag", "Bravo" } } })
assert_equal(parse("[Alpha(Bravo Charlie)]"), { "tag", "Alpha", { " ", { "tag", "Bravo"}, { "tag", "Charlie" } } })
assert_equal(parse("[Alpha(Bravo ' ' Charlie)]"), { "tag", "Alpha", { " ", { "tag", "Bravo"}, " ", { "tag", "Charlie" } } })
assert_equal(DogTag:CleanCode("[Alpha(Bravo ' ' Charlie)]"), "[Alpha(Bravo \" \" Charlie)]")
assert_equal(DogTag:CleanCode("[Alpha(Bravo \" \" Charlie)]"), "[Alpha(Bravo \" \" Charlie)]")

assert_equal(parse("[Alpha:Bravo(key=Charlie)]"), { "mod", "Bravo", { "tag", "Alpha" }, kwarg = { key = { "tag", "Charlie" } } })
assert_equal(DogTag:CleanCode("[Alpha:Bravo(key=Charlie)]"), "[Alpha:Bravo(key=Charlie)]")
assert_equal(parse("[Alpha:Bravo(Charlie, key=Delta)]"), { "mod", "Bravo", { "tag", "Alpha" }, { "tag", "Charlie" }, kwarg = { key = { "tag", "Delta" } } })
assert_equal(DogTag:CleanCode("[Alpha:Bravo(Charlie, key=Delta)]"), "[Alpha:Bravo(Charlie, key=Delta)]")
assert_equal(parse("[Tag:Alpha(bravo=Charlie, delta=Echo)]"), { "mod", "Alpha", { "tag", "Tag" }, kwarg = { bravo = { "tag", "Charlie" }, delta = { "tag", "Echo" } } })
assert_equal(DogTag:CleanCode("[Tag:Alpha(bravo=Charlie, delta=Echo)]"), "[Tag:Alpha(bravo=Charlie, delta=Echo)]")
assert_equal(DogTag:CleanCode("[Tag:Alpha(delta=Echo, bravo=Charlie)]"), "[Tag:Alpha(bravo=Charlie, delta=Echo)]")
assert_equal(parse("[Tag:Alpha((key=Bravo))]"), { "mod", "Alpha", { "tag", "Tag" }, { "(", { "=", { "tag", "key" }, { "tag", "Bravo" } } } })
assert_equal(DogTag:CleanCode("[Tag:Alpha(key = Bravo)]"), "[Tag:Alpha(key = Bravo)]")
assert_equal(DogTag:CleanCode("[Tag:Alpha((key=Bravo))]"), "[Tag:Alpha((key = Bravo))]")
assert_equal(parse("[Class(unit='mouseovertarget'):ClassColor(unit='mouseovertarget')]"), { "mod", "ClassColor", { "tag", "Class", kwarg = { unit = "mouseovertarget" } }, kwarg = { unit = "mouseovertarget" } })

assert_equal(parse("[-MissingHP]"), { "unm", { "tag", "MissingHP" } })
assert_equal(DogTag:CleanCode("[-MissingHP]"), "[-MissingHP]")
assert_equal(parse("[-(-1)]"), { "unm", { "(", -1 } })
assert_equal(standardize(parse("[-(-1)]")), 1)
assert_equal(standardize(parse("[-(-(-1))]")), -1)
assert_equal(parse("[AbsoluteValue(-5)]"), { "tag", "AbsoluteValue", -5 })
assert_equal(parse("[(-5):AbsoluteValue]"), { "mod", "AbsoluteValue", { "(", -5 } })
assert_equal(parse("[-5:AbsoluteValue]"), { "mod", "AbsoluteValue", -5})
assert_equal(parse("[-5:AbsoluteValue:AbsoluteValue]"), { "mod", "AbsoluteValue", { "mod", "AbsoluteValue", -5} })
assert_equal(parse("[-MissingHP:AbsoluteValue]"), { "mod", "AbsoluteValue", { "unm", { "tag", "MissingHP" } } })

assert_equal(DogTag:Evaluate("[One]"), 1)
assert_equal(DogTag:Evaluate("[One:PlusOne]"), 2)
assert_equal(DogTag:Evaluate("[PlusOne(One):PlusOne]"), 3)
assert_equal(DogTag:Evaluate("[PlusOne(number=One)]"), 2)
assert_equal(DogTag:Evaluate("[GlobalCheck]"), "Hello World")
assert_equal(DogTag:Evaluate("[SubGlobalCheck]"), "Hello World")
myfunc_num = 0
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 1)
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 2)
assert_equal(DogTag:Evaluate("[FunctionNumberCheck] [FunctionNumberCheck]"), "3 3") -- check caching

assert_equal(DogTag:Evaluate("[AbsoluteValue(5)]"), 5)
assert_equal(DogTag:Evaluate("[AbsoluteValue(-5)]"), 5)
assert_equal(DogTag:Evaluate("[5:AbsoluteValue]"), 5)
assert_equal(DogTag:Evaluate("[-5:AbsoluteValue]"), 5)

GlobalCheck_data = 2
assert_equal(DogTag:Evaluate("[GlobalCheck + One]"), 3)
assert_equal(DogTag:Evaluate("[One + GlobalCheck]"), 3)
assert_equal(DogTag:Evaluate("[GlobalCheck + GlobalCheck]"), 4)

assert_equal(DogTag:Evaluate("[PlusOne]"), [=[Arg #1 (number) req'd for PlusOne]=])
assert_equal(DogTag:Evaluate("[Unknown]"), [=[Unknown tag Unknown]=])
assert_equal(DogTag:Evaluate("[Subtract]"), [=[Arg #1 (left) req'd for Subtract]=])
assert_equal(DogTag:Evaluate("[Subtract(1)]"), [=[Arg #2 (right) req'd for Subtract]=])
assert_equal(DogTag:Evaluate("[Subtract(right=2)]"), [=[Arg #1 (left) req'd for Subtract]=])
assert_equal(DogTag:Evaluate("[Subtract(left=1)]"), [=[Arg #2 (right) req'd for Subtract]=])
assert_equal(DogTag:Evaluate("[Subtract(1, 2, extra='Stuff')]"), -1)
assert_equal(DogTag:Evaluate("[Subtract(1, 2, 3)]"), [=[Too many args for Subtract]=])
assert_equal(DogTag:Evaluate("[CheckNumDefault(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckNumDefault]"), 50)
assert_equal(DogTag:Evaluate("[CheckNumDefault(50)]"), 50)
assert_equal(DogTag:Evaluate("[CheckNumDefault(One)]"), 1)
assert_equal(DogTag:Evaluate("[CheckNumDefault('Test')]"), 0)
assert_equal(DogTag:Evaluate("[CheckStrDefault(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckStrDefault]"), "Value")
assert_equal(DogTag:Evaluate("[CheckStrDefault(50)]"), 50)
assert_equal(DogTag:Evaluate("[CheckStrDefault(One)]"), 1)
assert_equal(DogTag:Evaluate("[CheckStrDefault('Test')]"), "Test")
assert_equal(DogTag:Evaluate("[CheckNilDefault(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckNilDefault]"), nil)
assert_equal(DogTag:Evaluate("[CheckNilDefault(50)]"), 50)
assert_equal(DogTag:Evaluate("[CheckNilDefault('Test')]"), nil)
assert_equal(DogTag:Evaluate("[CheckNilDefault(One)]"), 1)

assert_equal(DogTag:Evaluate("[1 + 2]"), 3)
assert_equal(DogTag:Evaluate("[1 - 2]"), -1)
assert_equal(DogTag:Evaluate("[1 * 2]"), 2)
assert_equal(DogTag:Evaluate("[1 / 2]"), 1/2)
assert_equal(DogTag:Evaluate("[0 / 0]"), 0) -- odd case, good for WoW
assert_equal(standardize(parse("[1 / 0]")), math.huge)
assert_equal(standardize(parse("[(1 / 0)]")), math.huge)
assert_equal(DogTag:Evaluate("[1 / 0]"), 1/0)
assert_equal(DogTag:Evaluate("[(1 / 0)]"), 1/0)
assert_equal(DogTag:Evaluate("[-1 / 0]"), -1/0)
assert_equal(DogTag:Evaluate("[-(1 / 0)]"), -1/0)
assert_equal(parse("[(1 / 0)]"), { "(", { "/", 1, 0 } })
assert_equal(DogTag:Evaluate("[5 % 3]"), 2)
assert_equal(DogTag:Evaluate("[5 ^ 3]"), 125)
assert_equal(DogTag:Evaluate("[5 < 3]"), nil)
assert_equal(DogTag:Evaluate("[3 < 5]"), 3)
assert_equal(DogTag:Evaluate("[3 < 3]"), nil)
assert_equal(DogTag:Evaluate("[5 > 3]"), 5)
assert_equal(DogTag:Evaluate("[3 > 5]"), nil)
assert_equal(DogTag:Evaluate("[3 > 3]"), nil)
assert_equal(DogTag:Evaluate("[5 <= 3]"), nil)
assert_equal(DogTag:Evaluate("[3 <= 5]"), 3)
assert_equal(DogTag:Evaluate("[3 <= 3]"), 3)
assert_equal(DogTag:Evaluate("[5 >= 3]"), 5)
assert_equal(DogTag:Evaluate("[3 >= 5]"), nil)
assert_equal(DogTag:Evaluate("[3 >= 3]"), 3)
assert_equal(DogTag:Evaluate("[1 = 1]"), 1)
assert_equal(DogTag:Evaluate("[1 = 2]"), nil)
assert_equal(DogTag:Evaluate("[1 ~= 1]"), nil)
assert_equal(DogTag:Evaluate("[1 ~= 2]"), 1)
assert_equal(DogTag:Evaluate("[1 and 2]"), 2)
assert_equal(DogTag:Evaluate("[1 or 2]"), 1)
assert_equal(DogTag:Evaluate("[(1 = 2) and 2]"), nil)
assert_equal(DogTag:Evaluate("[(1 = 2) or 2]"), 2)
assert_equal(DogTag:Evaluate("[1 & 2]"), 2)
assert_equal(DogTag:Evaluate("[1 | 2]"), 1)
assert_equal(DogTag:Evaluate("[1 || 2]"), 1)
assert_equal(DogTag:Evaluate("[(1 = 2) & 2]"), nil)
assert_equal(DogTag:Evaluate("[(1 = 2) | 2]"), 2)
assert_equal(DogTag:Evaluate("[(1 = 2) || 2]"), 2)
assert_equal(DogTag:Evaluate("[if 1 then 2]"), 2)
assert_equal(DogTag:Evaluate("[if 1 then 2 else 3]"), 2)
assert_equal(DogTag:Evaluate("[if 1 = 2 then 2]"), nil)
assert_equal(DogTag:Evaluate("[if 1 = 2 then 2 else 3]"), 3)
assert_equal(DogTag:Evaluate("[1 ? 2]"), 2)
assert_equal(DogTag:Evaluate("[1 ? 2 ! 3]"), 2)
assert_equal(DogTag:Evaluate("[1 = 2 ? 2]"), nil)
assert_equal(DogTag:Evaluate("[1 = 2 ? 2 ! 3]"), 3)
assert_equal(DogTag:Evaluate("['Hello' 'There']"), "HelloThere")
assert_equal(DogTag:Evaluate("[-(-1)]"), 1)
assert_equal(DogTag:Evaluate("[-One]"), -1)
assert_equal(DogTag:Evaluate("[not 'Hello']"), nil)
assert_equal(DogTag:Evaluate("[not not 'Hello']"), "True")
GlobalCheck_data = 'Hello World'
assert_equal(DogTag:Evaluate("[GlobalCheck]"), "Hello World")
assert_equal(DogTag:Evaluate("[not GlobalCheck]"), nil)
assert_equal(DogTag:Evaluate("[not not GlobalCheck]"), "True")
assert_equal(DogTag:Evaluate("[One + One]"), 2)
assert_equal(DogTag:Evaluate("[Subtract(1, 2)]"), -1)
assert_equal(DogTag:Evaluate("[Subtract(2, 1)]"), 1)
assert_equal(DogTag:Evaluate("[Subtract(1, right=2)]"), -1)
assert_equal(DogTag:Evaluate("[Subtract(right=1, 2)]"), 1)
assert_equal(DogTag:Evaluate("[Subtract(left=1, right=2)]"), -1)
assert_equal(DogTag:Evaluate("[Subtract(right=1, left=2)]"), 1)
assert_equal(DogTag:Evaluate("[1:Subtract(2)]"), -1)
assert_equal(DogTag:Evaluate("[2:Subtract(1)]"), 1)
assert_equal(DogTag:Evaluate("[false]"), nil)
assert_equal(DogTag:Evaluate("[not false]"), "True")
assert_equal(DogTag:Evaluate("[true]"), "True")
assert_equal(DogTag:Evaluate("[not true]"), nil)
assert_equal(DogTag:Evaluate("[nil nil]"), nil)
assert_equal(DogTag:Evaluate("[false false]"), nil)
assert_equal(DogTag:Evaluate("[nil '' false]"), nil)
assert_equal(DogTag:Evaluate("[not nil not '' not false]"), "TrueTrueTrue")
assert_equal(DogTag:Evaluate("[nil 'Hello' nil]"), "Hello")
assert_equal(DogTag:Evaluate("[nil 1234 nil]"), 1234)
assert_equal(DogTag:Evaluate("[nil 1234 One nil]"), 12341)
GlobalCheck_data = 5
assert_equal(DogTag:Evaluate("[nil 1234 GlobalCheck nil]"), 12345)
GlobalCheck_data = 'Hello'
assert_equal(DogTag:Evaluate("[nil 1234 GlobalCheck nil]"), '1234Hello')

myfunc_num = 0
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 1)
assert_equal(DogTag:Evaluate("[true and FunctionNumberCheck]"), 2)
assert_equal(DogTag:Evaluate("[false and FunctionNumberCheck]"), nil) -- shouldn't call FunctionNumberCheck
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 3)
assert_equal(DogTag:Evaluate("[true or FunctionNumberCheck]"), "True") -- shouldn't call FunctionNumberCheck
assert_equal(DogTag:Evaluate("[false or FunctionNumberCheck]"), 4)
assert_equal(DogTag:Evaluate("[if true then FunctionNumberCheck]"), 5)
assert_equal(DogTag:Evaluate("[if false then FunctionNumberCheck]"), nil)
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 6)
assert_equal(DogTag:Evaluate("[if true then 'True' else FunctionNumberCheck]"), 'True')
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 7)
assert_equal(DogTag:Evaluate("[if false then 'True' else FunctionNumberCheck]"), 8)

myfunc_num = 0
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 1)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[GlobalCheck and FunctionNumberCheck]"), 2)
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[GlobalCheck and FunctionNumberCheck]"), nil) -- shouldn't call FunctionNumberCheck
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 3)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[GlobalCheck or FunctionNumberCheck]"), "True") -- shouldn't call FunctionNumberCheck
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[GlobalCheck or FunctionNumberCheck]"), 4)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[if GlobalCheck then FunctionNumberCheck]"), 5)
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[if GlobalCheck then FunctionNumberCheck]"), nil)
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 6)
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[if GlobalCheck then 'True' else FunctionNumberCheck]"), 'True')
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 7)
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[if GlobalCheck then 'True' else FunctionNumberCheck]"), 8)

assert_equal(DogTag:Evaluate("[PlusOne(1 1)]"), 12)

assert_equal(DogTag:Evaluate("[CheckNumTuple(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckNumTuple(1, 2)]"), '1-2')
assert_equal(DogTag:Evaluate("[CheckNumTuple(1, 2, 3)]"), '1-2-3')
assert_equal(DogTag:Evaluate("[CheckNumTuple(1, 2, 3, 'Hello')]"), '1-2-3-0')
assert_equal(DogTag:Evaluate("[CheckNumTuple(1, 2, 3, One, 'Hello')]"), '1-2-3-1-0')
assert_equal(DogTag:Evaluate("[CheckNumTuple]"), nil)

assert_equal(DogTag:Evaluate("[CheckAnotherNumTuple(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckAnotherNumTuple(1, 2)]"), 2)
assert_equal(DogTag:Evaluate("[CheckAnotherNumTuple(1, 2, 3)]"), 3)
assert_equal(DogTag:Evaluate("[CheckAnotherNumTuple(1, -2, One:PlusOne, -3)]"), 2)
assert_equal(DogTag:Evaluate("[CheckAnotherNumTuple]"), 0) -- special cause it does math.max(0, ...), which should turn into math.max(0), not math.max(0, )

assert_equal(DogTag:Evaluate("[CheckStrTuple('Hello')]"), 'Hylly')
assert_equal(DogTag:Evaluate("[CheckStrTuple(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckStrTuple(One)]"), 1)
assert_equal(DogTag:Evaluate("[CheckStrTuple('Hello', \"There\", 'Friend')]"), 'HyllyThyryFryynd')
assert_equal(DogTag:Evaluate("[CheckStrTuple]"), nil)
assert_equal(DogTag:Evaluate("[CheckStrTuple('Hello', 52, 'Friend', One)]"), 'Hylly52Fryynd1')

assert_equal(DogTag:Evaluate("[CheckAnotherStrTuple('Hello')]"), 'Hylly')
assert_equal(DogTag:Evaluate("[CheckAnotherStrTuple(1)]"), 1)
assert_equal(DogTag:Evaluate("[CheckAnotherStrTuple(One)]"), 1)
assert_equal(DogTag:Evaluate("[CheckAnotherStrTuple('Hello', \"There\", 'Friend')]"), 'HyllyThyryFryynd')
assert_equal(DogTag:Evaluate("[CheckAnotherStrTuple]"), nil)
assert_equal(DogTag:Evaluate("[CheckAnotherStrTuple('Hello', 52, 'Friend', One)]"), 'Hylly52Fryynd1')
assert_equal(DogTag:Evaluate("[Reverse('Hello')]"), "olleH")
assert_equal(DogTag:Evaluate("[Reverse('Hello'):Reverse]"), "Hello")
assert_equal(DogTag:Evaluate("[OtherReverse('Hello')]"), "olleH")
assert_equal(DogTag:Evaluate("[OtherReverse('Hello'):OtherReverse]"), "Hello")

old_DogTag_Evaluate(DogTag, "", { left = 0, right = 0 })

assert_equal(DogTag:Evaluate("[Subtract]", { left = 2, right = 1 }), 1)
assert_equal(DogTag:Evaluate("[Subtract]", { left = 1, right = 2 }), -1)

old_DogTag_Evaluate(DogTag, "", { number = 5 })

assert_equal(DogTag:Evaluate("[PlusOne]", { number = 5 }), 6)
assert_equal(DogTag:Evaluate("[PlusOne]", { number = 6 }), 7)
assert_equal(DogTag:Evaluate("[PlusOne]", { number = 7 }), 8)

assert_equal(DogTag:Evaluate("[KwargAndTuple]"), [=[Arg #1 (value) req'd for KwargAndTuple]=])
assert_equal(DogTag:Evaluate("[KwargAndTuple(5, 1, 2, 3)]"), 15)
assert_equal(DogTag:Evaluate("[KwargAndTuple(0.5, 2, 3, 4)]"), 2)
assert_equal(DogTag:Evaluate("[KwargAndTuple(value=0.5, 2, 3, 4)]"), 2)
assert_equal(DogTag:Evaluate("[TupleAndKwarg]"), [=[Arg #2 (value) req'd for TupleAndKwarg]=])
assert_equal(DogTag:Evaluate("[TupleAndKwarg(value=1/4, 2, 3, 4)]"), 1)
assert_equal(DogTag:Evaluate("[TupleAndKwarg(2, 3, 4, value=0.5)]"), 2)

assert_equal(parse([=[['Alpha\'Bravo']]=]), "Alpha'Bravo")
assert_equal(parse([=[["Alpha\"Bravo"]]=]), 'Alpha"Bravo')
assert_equal(parse([=[['Alpha\'Bravo"Charlie']]=]), "Alpha'Bravo\"Charlie")
assert_equal(parse([=[["Alpha\"Bravo'Charlie"]]=]), 'Alpha"Bravo\'Charlie')
assert_equal(parse([=[["\1alpha"]]=]), '\001alpha')
assert_equal(parse([=[["\12alpha"]]=]), '\012alpha')
assert_equal(parse([=[["\123alpha"]]=]), '\123alpha')
assert_equal(parse([=[["\124cffff0000"]]=]), '|cffff0000')
assert_equal(parse([=[["\123456"]]=]), '\123' .. '456')

assert_equal(parse([=[[Func('Alpha\'Bravo')]]=]), { "tag", "Func", "Alpha'Bravo" })
assert_equal(parse([=[[Func("Alpha\"Bravo")]]=]), { "tag", "Func", 'Alpha"Bravo' })
assert_equal(parse([=[[Func('Alpha\'Bravo"Charlie')]]=]), { "tag", "Func", "Alpha'Bravo\"Charlie" })
assert_equal(parse([=[[Func("Alpha\"Bravo'Charlie")]]=]), { "tag", "Func", 'Alpha"Bravo\'Charlie' })
assert_equal(parse([=[[Func("\124cffff0000")]]=]), { "tag", "Func", '|cffff0000' })
assert_equal(parse([=[[Func("\123456")]]=]), { "tag", "Func", '\123' .. '456' })

assert_equal(DogTag:CleanCode([=[['Alpha\'Bravo']]=]), "Alpha'Bravo")
assert_equal(DogTag:CleanCode([=[["Alpha\"Bravo"]]=]), 'Alpha"Bravo')
assert_equal(DogTag:CleanCode([=[['Alpha\'Bravo"Charlie']]=]), "Alpha'Bravo\"Charlie")
assert_equal(DogTag:CleanCode([=[["Alpha\"Bravo'Charlie"]]=]), 'Alpha"Bravo\'Charlie')
assert_equal(DogTag:CleanCode([=[["\124cffff0000"]]=]), '|cffff0000')
assert_equal(DogTag:CleanCode([=[["\123456"]]=]), '\123' .. '456')

assert_equal(DogTag:CleanCode([=[[Func('Alpha\'Bravo')]]=]), [=[[Func("Alpha'Bravo")]]=])
assert_equal(DogTag:CleanCode([=[[Func("Alpha\"Bravo")]]=]), [=[[Func('Alpha"Bravo')]]=])
assert_equal(DogTag:CleanCode([=[[Func('Alpha\'Bravo"Charlie')]]=]), [=[[Func("Alpha'Bravo\"Charlie")]]=])
assert_equal(DogTag:CleanCode([=[[Func("Alpha\"Bravo'Charlie")]]=]), [=[[Func("Alpha\"Bravo'Charlie")]]=])
assert_equal(DogTag:CleanCode([=[[Func("\124cffff0000")]]=]), [=[[Func("|cffff0000")]]=]) -- TODO: make it do \124, cause pipes are funky
assert_equal(DogTag:CleanCode([=[[Func("\123456")]]=]), [=[[Func("{456")]]=])

assert_equal(DogTag:Evaluate("[Type(nil)]"), "nil")
assert_equal(DogTag:Evaluate("[Type('Hello')]"), "string")
assert_equal(DogTag:Evaluate("[Type(5)]"), "number")
assert_equal(DogTag:Evaluate("[Type(false)]"), "nil")
assert_equal(DogTag:Evaluate("[Type(true)]"), "string")

GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[Type(GlobalCheck)]"), "nil")
GlobalCheck_data = "Hello"
assert_equal(DogTag:Evaluate("[Type(GlobalCheck)]"), "string")
GlobalCheck_data = 5
assert_equal(DogTag:Evaluate("[Type(GlobalCheck)]"), "number")

assert_equal(DogTag:Evaluate("[ToString(nil)]"), "``")
assert_equal(DogTag:Evaluate("[ToString('Hello')]"), "`Hello`")
assert_equal(DogTag:Evaluate("[ToString(5)]"), "`5`")
assert_equal(DogTag:Evaluate("[ToString(false)]"), "``")
assert_equal(DogTag:Evaluate("[ToString(true)]"), "`True`")

GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[ToString(GlobalCheck)]"), "``")
GlobalCheck_data = "Hello"
assert_equal(DogTag:Evaluate("[ToString(GlobalCheck)]"), "`Hello`")
GlobalCheck_data = 5
assert_equal(DogTag:Evaluate("[ToString(GlobalCheck)]"), "`5`")

assert_equal(DogTag:Evaluate("[RetSame(nil)]"), nil)
assert_equal(RetSame_types, "nil")
assert_equal(DogTag:Evaluate("[RetSame('Hello')]"), "Hello")
assert_equal(RetSame_types, "string")
assert_equal(DogTag:Evaluate("[RetSame(5)]"), 5)
assert_equal(RetSame_types, "number")
assert_equal(DogTag:Evaluate("[RetSame(false)]"), nil)
assert_equal(RetSame_types, "nil")
assert_equal(DogTag:Evaluate("[RetSame(true)]"), "True")
assert_equal(RetSame_types, "string")

GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[RetSame(GlobalCheck)]"), nil)
assert_equal(RetSame_types, "nil;number;string")
GlobalCheck_data = "Hello"
assert_equal(DogTag:Evaluate("[RetSame(GlobalCheck)]"), "Hello")
assert_equal(RetSame_types, "nil;number;string")
GlobalCheck_data = 5
assert_equal(DogTag:Evaluate("[RetSame(GlobalCheck)]"), 5)
assert_equal(RetSame_types, "nil;number;string")

assert_equal(DogTag:Evaluate("[RetSame(One)]"), 1)
assert_equal(RetSame_types, "number")
assert_equal(DogTag:Evaluate("[RetSame(CheckNilDefault(5))]"), 5)
assert_equal(RetSame_types, "nil;number")
assert_equal(DogTag:Evaluate("[RetSame(CheckNilDefault)]"), nil)
assert_equal(RetSame_types, "nil;number")

assert_equal(DogTag:Evaluate("[DynamicCodeTest(nil)]"), "literal, nil")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(5)]"), "literal, 5")
assert_equal(DogTag:Evaluate("[DynamicCodeTest('Hello')]"), "literal, Hello")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(false)]"), "literal, nil")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(true)]"), "literal, True")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(One)]"), "dynamic, One")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(GlobalCheck)]"), "dynamic, GlobalCheck")
assert_equal(DogTag:Evaluate("[DynamicCodeTest(1 + One)]"), "dynamic, +")

DynamicGlobalCheck_data = "This is dynamic"
LiteralGlobalCheck_data = "This is not dynamic"
assert_equal(DogTag:Evaluate("[DynamicGlobalCheck(nil)]"), "This is not dynamic")
assert_equal(DogTag:Evaluate("[DynamicGlobalCheck(5)]"), "This is not dynamic")
assert_equal(DogTag:Evaluate("[DynamicGlobalCheck('Hello')]"), "This is not dynamic")
assert_equal(DogTag:Evaluate("[DynamicGlobalCheck(false)]"), "This is not dynamic")
assert_equal(DogTag:Evaluate("[DynamicGlobalCheck(true)]"), "This is not dynamic")
assert_equal(DogTag:Evaluate("[DynamicGlobalCheck(One)]"), "This is dynamic")
assert_equal(DogTag:Evaluate("[DynamicGlobalCheck(GlobalCheck)]"), "This is dynamic")
assert_equal(DogTag:Evaluate("[DynamicGlobalCheck(1 + One)]"), "This is dynamic")

assert_equal(DogTag:Evaluate("[BlizzEventTest]", { value = 'player' }), 1)

local fired = false
DogTag:AddCallback("[BlizzEventTest('player')]", function(code, kwargs)
	assert_equal(code, "[BlizzEventTest('player')]")
	assert_equal(kwargs, nil)
	fired = true
end)
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false

local fired = false
local function func(code, kwargs)
	assert_equal(code, "[BlizzEventTest]")
	assert_equal(kwargs, { value = "player" })
	fired = true
end
DogTag:AddCallback("[BlizzEventTest]", func, { value = "player" })
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
DogTag:RemoveCallback("[BlizzEventTest]", func, { value = "player" })
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, false)

local fired = false
local func = function(code, kwargs)
	assert_equal(code, "[OtherBlizzEventTest]")
	assert_equal(kwargs, nil)
	fired = true
end
DogTag:AddCallback("[OtherBlizzEventTest]", func)
FireEvent("OTHER_FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, true)
fired = false
FireEvent("OTHER_FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
DogTag:RemoveCallback("[OtherBlizzEventTest]", func)
FireEvent("OTHER_FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, false)

local fired = false
local function func(code, kwargs)
	assert_equal(code, "[BlizzEventTest(GlobalCheck)]")
	assert_equal(kwargs, nil)
	fired = true
end
DogTag:AddCallback("[BlizzEventTest(GlobalCheck)]", func)
GlobalCheck_data = 'player'
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, true)
fired = false
GlobalCheck_data = 'pet'
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, true)
fired = false
FireEvent("FAKE_BLIZZARD_EVENT", 'player')
assert_equal(fired, false)
DogTag:RemoveCallback("[BlizzEventTest(GlobalCheck)]", func)
FireEvent("FAKE_BLIZZARD_EVENT", 'pet')
assert_equal(fired, false)

local f = CreateFrame("Frame")
local fs = f:CreateFontString(nil, "ARTWORK")
assert_equal(fs:GetText(), nil)
DogTag:AddFontString(fs, f, "[One]")
assert_equal(fs:GetText(), 1)
DogTag:RemoveFontString(fs)
assert_equal(fs:GetText(), nil)

_G.OtherBlizzEventTest_num = 1
DogTag:AddFontString(fs, f, "[OtherBlizzEventTest]")
assert_equal(fs:GetText(), 2)
FireEvent("OTHER_FAKE_BLIZZARD_EVENT")
FireOnUpdate(0)
assert_equal(fs:GetText(), 2)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 3)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 3)
FireOnUpdate(1000)
FireEvent("OTHER_FAKE_BLIZZARD_EVENT")
FireOnUpdate(0.04)
assert_equal(fs:GetText(), 3)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 4)
FireOnUpdate(0.01)

_G.BlizzEventTest_num = 1
GlobalCheck_data = 'player'
DogTag:AddFontString(fs, f, "[BlizzEventTest(GlobalCheck)]")
assert_equal(fs:GetText(), 2)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)
FireEvent("OTHER_FAKE_BLIZZARD_EVENT")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 2)
FireEvent("FAKE_BLIZZARD_EVENT", "player")
assert_equal(fs:GetText(), 2)
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 3)
FireOnUpdate(1000)
assert_equal(fs:GetText(), 3)
FireEvent("FAKE_BLIZZARD_EVENT", "pet")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 3)
FireEvent("FAKE_BLIZZARD_EVENT", "player")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 4)
GlobalCheck_data = 'pet'
FireEvent("FAKE_BLIZZARD_EVENT", "player")
FireOnUpdate(1000)
assert_equal(fs:GetText(), 4)
FireEvent("FAKE_BLIZZARD_EVENT", "pet")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 5)
GlobalCheck_data = 'player'
FireEvent("FAKE_BLIZZARD_EVENT", "player")
FireOnUpdate(0.05)
assert_equal(fs:GetText(), 6)

-- Test Math module
assert_equal(DogTag:Evaluate("[Round(0)]"), 0)
assert_equal(DogTag:Evaluate("[Round(0.5)]"), 0)
assert_equal(DogTag:Evaluate("[Round(0.500001)]"), 1)
assert_equal(DogTag:Evaluate("[Round(1)]"), 1)
assert_equal(DogTag:Evaluate("[Round(1.499999)]"), 1)
assert_equal(DogTag:Evaluate("[Round(1.5)]"), 2)

assert_equal(DogTag:Evaluate("[Floor(-0.0000000001)]"), -1)
assert_equal(DogTag:Evaluate("[Floor(0)]"), 0)
assert_equal(DogTag:Evaluate("[Floor(0.9999999999)]"), 0)
assert_equal(DogTag:Evaluate("[Floor(1)]"), 1)

assert_equal(DogTag:Evaluate("[Ceil(-0.9999999999)]"), 0)
assert_equal(DogTag:Evaluate("[Ceil(0)]"), 0)
assert_equal(DogTag:Evaluate("[Ceil(0.0000000001)]"), 1)
assert_equal(DogTag:Evaluate("[Ceil(1)]"), 1)

assert_equal(DogTag:Evaluate("[Abs(-5)]"), 5)
assert_equal(DogTag:Evaluate("[Abs(5)]"), 5)
assert_equal(DogTag:Evaluate("[Abs(0)]"), 0)

assert_equal(DogTag:Evaluate("[Sign(-5)]"), -1)
assert_equal(DogTag:Evaluate("[Sign(5)]"), 1)
assert_equal(DogTag:Evaluate("[Sign(0)]"), 0)

assert_equal(DogTag:Evaluate("[Max(1)]"), 1)
assert_equal(DogTag:Evaluate("[Max(1, 3, 4, 2)]"), 4)

assert_equal(DogTag:Evaluate("[Min(1)]"), 1)
assert_equal(DogTag:Evaluate("[Min(5, 3, 4, 2)]"), 2)

assert_equal(DogTag:Evaluate("[Pi]"), math.pi)

assert_equal(DogTag:Evaluate("[0:Deg]"), 0)
assert_equal(DogTag:Evaluate("[Deg(Pi/2)]"), 90)
assert_equal(DogTag:Evaluate("[Pi:Deg]"), 180)

assert_equal(DogTag:Evaluate("[0:Rad]"), 0)
assert_equal(DogTag:Evaluate("[90:Rad]"), math.pi/2)
assert_equal(DogTag:Evaluate("[180:Rad]"), math.pi)

assert_equal(DogTag:Evaluate("[0:Cos]"), 1)
assert_equal(DogTag:Evaluate("[(Pi/4):Cos]"), 0.5^0.5)
assert_equal(DogTag:Evaluate("[(Pi/2):Cos]"), 0)

assert_equal(DogTag:Evaluate("[0:Sin]"), 0)
assert_equal(DogTag:Evaluate("[(Pi/4):Sin]"), 0.5^0.5)
assert_equal(DogTag:Evaluate("[(Pi/2):Sin]"), 1)

assert_equal(DogTag:Evaluate("[E]"), math.exp(1))

assert_equal(DogTag:Evaluate("[1:Ln]"), 0)
assert_equal(DogTag:Evaluate("[E:Ln]"), 1)
assert_equal(DogTag:Evaluate("[[E^2]:Ln]"), 2)

assert_equal(DogTag:Evaluate("[1:Log]"), 0)
assert_equal(DogTag:Evaluate("[10:Log]"), 1)
assert_equal(DogTag:Evaluate("[100:Log]"), 2)

assert_equal(DogTag:Evaluate("[100:Percent]"), "100%")
assert_equal(DogTag:Evaluate("[50:Percent]"), "50%")
assert_equal(DogTag:Evaluate("[0:Percent]"), "0%")

assert_equal(DogTag:Evaluate("[100:Short]"), 100)
assert_equal(DogTag:Evaluate("[1000:Short]"), 1000)
assert_equal(DogTag:Evaluate("[10000:Short]"), '10.0k')
assert_equal(DogTag:Evaluate("[100000:Short]"), '100k')
assert_equal(DogTag:Evaluate("[1000000:Short]"), '1.00m')
assert_equal(DogTag:Evaluate("[10000000:Short]"), '10.0m')
assert_equal(DogTag:Evaluate("[100000000:Short]"), '100.0m')
assert_equal(DogTag:Evaluate("[-100:Short]"), -100)
assert_equal(DogTag:Evaluate("[-1000:Short]"), -1000)
assert_equal(DogTag:Evaluate("[-10000:Short]"), '-10.0k')
assert_equal(DogTag:Evaluate("[-100000:Short]"), '-100k')
assert_equal(DogTag:Evaluate("[-1000000:Short]"), '-1.00m')
assert_equal(DogTag:Evaluate("[-10000000:Short]"), '-10.0m')
assert_equal(DogTag:Evaluate("[-100000000:Short]"), '-100.0m')

assert_equal(DogTag:Evaluate("['100/1000':Short]"), '100/1000')
assert_equal(DogTag:Evaluate("['1000/10000':Short]"), '1000/10.0k')
assert_equal(DogTag:Evaluate("['10000/100000':Short]"), '10.0k/100k')
assert_equal(DogTag:Evaluate("['100000/1000000':Short]"), '100k/1.00m')
assert_equal(DogTag:Evaluate("['1000000/10000000':Short]"), '1.00m/10.0m')
assert_equal(DogTag:Evaluate("['10000000/100000000':Short]"), '10.0m/100.0m')

assert_equal(DogTag:Evaluate("[100:VeryShort]"), 100)
assert_equal(DogTag:Evaluate("[1000:VeryShort]"), '1k')
assert_equal(DogTag:Evaluate("[10000:VeryShort]"), '10k')
assert_equal(DogTag:Evaluate("[100000:VeryShort]"), '100k')
assert_equal(DogTag:Evaluate("[1000000:VeryShort]"), '1m')
assert_equal(DogTag:Evaluate("[10000000:VeryShort]"), '10m')
assert_equal(DogTag:Evaluate("[100000000:VeryShort]"), '100m')
assert_equal(DogTag:Evaluate("[-100:VeryShort]"), -100)
assert_equal(DogTag:Evaluate("[-1000:VeryShort]"), '-1k')
assert_equal(DogTag:Evaluate("[-10000:VeryShort]"), '-10k')
assert_equal(DogTag:Evaluate("[-100000:VeryShort]"), '-100k')
assert_equal(DogTag:Evaluate("[-1000000:VeryShort]"), '-1m')
assert_equal(DogTag:Evaluate("[-10000000:VeryShort]"), '-10m')
assert_equal(DogTag:Evaluate("[-100000000:VeryShort]"), '-100m')

assert_equal(DogTag:Evaluate("['100/1000':VeryShort]"), '100/1k')
assert_equal(DogTag:Evaluate("['1000/10000':VeryShort]"), '1k/10k')
assert_equal(DogTag:Evaluate("['10000/100000':VeryShort]"), '10k/100k')
assert_equal(DogTag:Evaluate("['100000/1000000':VeryShort]"), '100k/1m')
assert_equal(DogTag:Evaluate("['1000000/10000000':VeryShort]"), '1m/10m')
assert_equal(DogTag:Evaluate("['10000000/100000000':VeryShort]"), '10m/100m')

assert_equal(DogTag:Evaluate("['Hello':Upper]"), 'HELLO')
assert_equal(DogTag:Evaluate("['Hello':Lower]"), 'hello')

assert_equal(DogTag:Evaluate("['Hello':Bracket]"), '[Hello]')
assert_equal(DogTag:Evaluate("['Hello':Angle]"), '<Hello>')
assert_equal(DogTag:Evaluate("['Hello':Brace]"), '{Hello}')
assert_equal(DogTag:Evaluate("['Hello':Paren]"), '(Hello)')

assert_equal(DogTag:Evaluate("['Hello':Truncate(3)]"), 'Hel...')
assert_equal(DogTag:Evaluate("['Über':Truncate(3)]"), 'Übe...')
assert_equal(DogTag:Evaluate("['Hello':Truncate(4)]"), 'Hell...')
assert_equal(DogTag:Evaluate("['Hello':Truncate(4, true)]"), 'Hell...')
assert_equal(DogTag:Evaluate("['Hello':Truncate(4, ellipses=true)]"), 'Hell...')
assert_equal(DogTag:Evaluate("['Hello':Truncate(5)]"), 'Hello')
assert_equal(DogTag:Evaluate("['Hello':Truncate(3, ellipses=nil)]"), 'Hel')
assert_equal(DogTag:Evaluate("['Hello':Truncate(3, ellipses=false)]"), 'Hel')
assert_equal(DogTag:Evaluate("['Über':Truncate(3, nil)]"), 'Übe')
assert_equal(DogTag:Evaluate("['Hello':Truncate(4, nil)]"), 'Hell')
assert_equal(DogTag:Evaluate("['Hello':Truncate(5, ellipses=nil)]"), 'Hello')

assert_equal(DogTag:Evaluate("['Hello':Repeat(0)]"), nil)
assert_equal(DogTag:Evaluate("['Hello':Repeat(1)]"), 'Hello')
assert_equal(DogTag:Evaluate("['Hello':Repeat(2)]"), 'HelloHello')
assert_equal(DogTag:Evaluate("['Hello':Repeat(2.5)]"), 'HelloHello')

assert_equal(DogTag:Evaluate("['Hello':Length]"), 5)
assert_equal(DogTag:Evaluate("['Über':Length]"), 4)

assert_equal(DogTag:Evaluate("[0:Romanize]"), "N")
assert_equal(DogTag:Evaluate("[1:Romanize]"), "I")
assert_equal(DogTag:Evaluate("[4:Romanize]"), "IV")
assert_equal(DogTag:Evaluate("[500:Romanize]"), "D")
assert_equal(DogTag:Evaluate("[1666:Romanize]"), "MDCLXVI")
assert_equal(DogTag:Evaluate("[1666666:Romanize]"), "(MDCLXV)MDCLXVI")
assert_equal(DogTag:Evaluate("[4999999:Romanize]"), "(MMMMCMXCIX)CMXCIX")
assert_equal(DogTag:Evaluate("[-1:Romanize]"), "-I")
assert_equal(DogTag:Evaluate("[-4:Romanize]"), "-IV")
assert_equal(DogTag:Evaluate("[-500:Romanize]"), "-D")
assert_equal(DogTag:Evaluate("[-1666:Romanize]"), "-MDCLXVI")
assert_equal(DogTag:Evaluate("[-1666666:Romanize]"), "-(MDCLXV)MDCLXVI")
assert_equal(DogTag:Evaluate("[-4999999:Romanize]"), "-(MMMMCMXCIX)CMXCIX")

assert_equal(DogTag:Evaluate("[nil:Length]"), nil)
assert_equal(DogTag:Evaluate("[false:Length]"), nil)
assert_equal(DogTag:Evaluate("[true:Length]"), 4)

assert_equal(DogTag:Evaluate("[nil:Short]"), nil)
assert_equal(DogTag:Evaluate("[false:Short]"), nil)

IsAltKeyDown_data = nil
assert_equal(DogTag:Evaluate("[Alt]"), nil)
IsAltKeyDown_data = 1
assert_equal(DogTag:Evaluate("[Alt]"), "True")

IsShiftKeyDown_data = nil
assert_equal(DogTag:Evaluate("[Shift]"), nil)
IsShiftKeyDown_data = 1
assert_equal(DogTag:Evaluate("[Shift]"), "True")

IsControlKeyDown_data = nil
assert_equal(DogTag:Evaluate("[Ctrl]"), nil)
IsControlKeyDown_data = 1
assert_equal(DogTag:Evaluate("[Ctrl]"), "True")

local now = GetTime()
FireOnUpdate(1)
assert_equal(DogTag:Evaluate("[CurrentTime]"), now+1)
FireOnUpdate(1)
assert_equal(DogTag:Evaluate("[CurrentTime]"), now+2)

assert_equal(DogTag:Evaluate("[Alpha(1)]"), nil)
assert_equal(select(2, DogTag:Evaluate("[Alpha(1)]")), 1)
assert_equal(select(2, DogTag:Evaluate("[Alpha(0)]")), 0)
assert_equal(select(2, DogTag:Evaluate("[Alpha(0.5)]")), 0.5)
assert_equal(select(2, DogTag:Evaluate("[Alpha(2)]")), 1)
assert_equal(select(2, DogTag:Evaluate("[Alpha(-1)]")), 0)

DogTag:AddFontString(fs, f, "[IsMouseOver]")
assert_equal(fs:GetText(), nil)
GetMouseFocus_data = f
assert_equal(fs:GetText(), nil)
FireOnUpdate(0)
assert_equal(fs:GetText(), "True")
FireOnUpdate(1000)
assert_equal(fs:GetText(), "True")
GetMouseFocus_data = nil
FireOnUpdate(0)
assert_equal(fs:GetText(), nil)
DogTag:RemoveFontString(fs)

assert_equal(DogTag:Evaluate("['Hello':Color('ff0000')]"), "|cffff0000Hello|r")
assert_equal(DogTag:Evaluate("['There':Color('00ff00')]"), "|cff00ff00There|r")
assert_equal(DogTag:Evaluate("['Friend':Color(0, 0, 1)]"), "|cff0000ffFriend|r")
assert_equal(DogTag:Evaluate("['Broken':Color('00ff00a')]"), "|cffffffffBroken|r")
assert_equal(DogTag:Evaluate("['Large nums':Color(180, 255, -60)]"), "|cffffff00Large nums|r")

assert_equal(DogTag:Evaluate("[nil:Color('ff0000')]"), nil)
assert_equal(DogTag:Evaluate("[nil:Color(0, 0, 1)]"), nil)
assert_equal(DogTag:Evaluate("[false:Color(0, 0, 1)]"), nil)
assert_equal(DogTag:Evaluate("[true:Color(0, 0, 1)]"), "|cff0000ffTrue|r")

assert_equal(DogTag:Evaluate("[Color('ff0000')]"), "|cffff0000")
assert_equal(DogTag:Evaluate("[Color('00ff00')]"), "|cff00ff00")
assert_equal(DogTag:Evaluate("[Color(0, 0, 1)]"), "|cff0000ff")
assert_equal(DogTag:Evaluate("[Color('00ff00a')]"), "|cffffffff")
assert_equal(DogTag:Evaluate("[Color(180, 255, -60)]"), "|cffffff00")

for name, color in pairs({
	White = "ffffff",
	Red = "ff0000",
	Green = "00ff00",
	Blue = "0000ff",
	Cyan = "00ffff",
	Fuschia = "ff00ff",
	Yellow = "ffff00",
	Gray = "afafaf",
}) do
	assert_equal(DogTag:Evaluate("['Hello':" .. name .. "]"), "|cff" .. color .. "Hello|r")
	assert_equal(DogTag:Evaluate("[" .. name .. " 'Hello']"), "|cff" .. color .. "Hello")
	assert_equal(DogTag:Evaluate("[nil:" .. name .. "]"), nil)
	assert_equal(DogTag:Evaluate("[false:" .. name .. "]"), nil)
	assert_equal(DogTag:Evaluate("[true:" .. name .. "]"), "|cff" .. color .. "True|r")
end

assert_equal(DogTag:Evaluate("['Hello':Abbreviate]"), "Hello")
assert_equal(DogTag:Evaluate("['Hello World':Abbreviate]"), "HW")
assert_equal(DogTag:Evaluate("[nil:Abbreviate]"), nil)
assert_equal(DogTag:Evaluate("[false:Abbreviate]"), nil)
assert_equal(DogTag:Evaluate("[true:Abbreviate]"), "True")

assert_equal(DogTag:Evaluate("[SubtractFive(10)]"), 5)
assert_equal(DogTag:Evaluate("[SubtractFive(12)]"), 7)
assert_equal(DogTag:Evaluate("[SubtractFive(One)]"), -4)
assert_equal(DogTag:Evaluate("[SubtractFive]"), "Arg #1 (number) req'd for SubtractFive")
assert_equal(DogTag:Evaluate("[SubtractFive(number=10)]"), 5)
assert_equal(DogTag:Evaluate("[SubtractFive]", { number = 10 }), 5)

assert_equal(DogTag:Evaluate("[SubtractFromFive(10)]"), -5)
assert_equal(DogTag:Evaluate("[SubtractFromFive(12)]"), -7)
assert_equal(DogTag:Evaluate("[SubtractFromFive(One)]"), 4)
assert_equal(DogTag:Evaluate("[SubtractFromFive]"), 5)

assert_equal(DogTag:Evaluate("[ReverseSubtract(4, 2)]"), -2)
assert_equal(DogTag:Evaluate("[ReverseSubtract(2, 4)]"), 2)
assert_equal(DogTag:Evaluate("[2:ReverseSubtract(4)]"), 2)
assert_equal(DogTag:Evaluate("[ReverseSubtract(1)]"), "Arg #2 (right) req'd for ReverseSubtract")
assert_equal(DogTag:Evaluate("[ReverseSubtract]"), "Arg #1 (left) req'd for ReverseSubtract")

assert_equal(DogTag:Evaluate("[AbsAlias(10)]"), 10)
assert_equal(DogTag:Evaluate("[AbsAlias(-10)]"), 10)

assert_equal(DogTag:Evaluate("[TupleAlias]"), 5)
assert_equal(DogTag:Evaluate("[TupleAlias(1)]"), "5-1")
assert_equal(DogTag:Evaluate("[TupleAlias(1, 2, 3)]"), "5-1-2-3")

assert_equal(DogTag:Evaluate("[OtherTupleAlias(5, 2)]"), 3)
assert_equal(DogTag:Evaluate("[OtherTupleAlias(2, 5)]"), -3)
assert_equal(DogTag:Evaluate("[OtherTupleAlias(5, 6, 7)]"), "Too many args for Subtract")
assert_equal(DogTag:Evaluate("[OtherTupleAlias(5)]"), "Arg #2 (right) req'd for Subtract")

assert_equal(DogTag:Evaluate("[5:IsIn]"), nil)
assert_equal(DogTag:Evaluate("[5:IsIn(6, 7, 8)]"), nil)
assert_equal(DogTag:Evaluate("[5:IsIn(1, 2, 3, 4, 5)]"), 5)

assert_equal(DogTag:Evaluate("[One:Hide(6, 7, 8)]"), 1)
assert_equal(DogTag:Evaluate("[One:Hide(1, 6, 7, 8)]"), nil)
assert_equal(DogTag:Evaluate("[One:Hide(2):Hide(3)]"), 1)
assert_equal(DogTag:Evaluate("[One:Hide(2):Hide(3):Hide(1)]"), nil)
GlobalCheck_data = 1
assert_equal(DogTag:Evaluate("[GlobalCheck:Hide(6, 7, 8)]"), 1)
assert_equal(DogTag:Evaluate("[GlobalCheck:Hide(1, 6, 7, 8)]"), nil)
assert_equal(DogTag:Evaluate("[GlobalCheck:Hide(2):Hide(3)]"), 1)
assert_equal(DogTag:Evaluate("[GlobalCheck:Hide(2):Hide(1):Hide(3)]"), nil)
assert_equal(DogTag:Evaluate("[5:Hide(6, 7, 8)]"), 5)
assert_equal(DogTag:Evaluate("[5:Hide(1, 2, 3, 4, 5)]"), nil)

assert_equal(DogTag:Evaluate("['Hello':Contains('There')]"), nil)
assert_equal(DogTag:Evaluate("['Hello':Contains('ello')]"), "Hello")
assert_equal(DogTag:Evaluate("['Hello':~Contains('There')]"), "Hello")
assert_equal(DogTag:Evaluate("['Hello':~Contains('ello')]"), nil)

GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[GlobalCheck ? 'Hello' One ! 'There' Two]"), 'Hello1')
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[GlobalCheck ? 'Hello' One ! 'There' Two]"), 'There2')
GlobalCheck_data = "True"
assert_equal(DogTag:Evaluate("[(GlobalCheck ? 'Hello' One ! 'There' Two) 'Buddy']"), 'Hello1Buddy')
GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[(GlobalCheck ? 'Hello' One ! 'There' Two) 'Buddy']"), 'There2Buddy')

print("LibDogTag-3.0: Tests succeeded")
