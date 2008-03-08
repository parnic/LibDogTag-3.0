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
		return alpha == bravo or math.abs(alpha - bravo) < 1e-10
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

local function assert_equal(alpha, bravo)
	if not is_equal(alpha, bravo) then
		error(("Assertion failed: %s == %s"):format(ptostring(alpha), ptostring(bravo)), 2)
	end
end

DogTag_DEBUG = true

dofile("LibStub/LibStub.lua")
dofile("Localization/enUS.lua")
dofile("LibDogTag-3.0.lua")
dofile("Parser.lua")
dofile("Compiler.lua")
dofile("Modules/Operators.lua")
dofile("Cleanup.lua")

function geterrorhandler()
	return error
end

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
		error(("Unexpected table usage: %d instead of expected %d"):format(actualChange, tableChange), 2)
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
		error(("Unknown table usage: %d instead of %d"):format(change, num_tables), 2)
	end
	local r = deepCopy(ret)
	deepDel(ret)
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
		error(("Unknown table usage: %d instead of %d"):format(change, num_tables), 2)
	end
	DogTag.setPoolNum(realStart)
	return ret
end

DogTag:Evaluate("")

local old_DogTag_Evaluate = DogTag.Evaluate
function DogTag:Evaluate(...)
	local start = DogTag.getPoolNum()
	local ret = old_DogTag_Evaluate(self, ...)
	local finish = DogTag.getPoolNum()
	local change = finish - start
	if change ~= 0 then
		error(("Unknown table usage: %d instead of %d"):format(change, 0), 2)
	end
	return ret
end

local old_DogTag_CleanCode = DogTag.CleanCode
function DogTag:CleanCode(...)
	local start = DogTag.getPoolNum()
	local ret = old_DogTag_CleanCode(self, ...)
	local finish = DogTag.getPoolNum()
	local change = finish - start
	if change ~= 0 then
		error(("Unknown table usage: %d instead of %d"):format(change, 0), 2)
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
assert_equal(DogTag:CleanCode("[nil]"), "")
assert_equal(DogTag:CleanCode("[nil nil]"), "[nil nil]")
assert_equal(parse("['Alpha']"), "Alpha")
assert_equal(parse('["Alpha"]'), "Alpha")
assert_equal(DogTag:CleanCode("['Alpha']"), "Alpha")
assert_equal(DogTag:CleanCode('["Alpha"]'), "Alpha")
assert_equal(parse("[1234]"), 1234)
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
assert_equal(DogTag:CleanCode("[1 | 2]"), "[1 | 2]")
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
assert_equal(standardize(parse("[-(-1)]")), { "unm", -1 })

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
assert_equal(standardize(parse("[1 / 0]")), { "/", 1, 0 })
assert_equal(standardize(parse("[(1 / 0)]")), { "/", 1, 0 })
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
assert_equal(DogTag:Evaluate("[(1 = 2) & 2]"), nil)
assert_equal(DogTag:Evaluate("[(1 = 2) | 2]"), 2)
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
assert_equal(DogTag:Evaluate("[One + One]"), 2)
assert_equal(DogTag:Evaluate("[Subtract(1, 2)]"), -1)
assert_equal(DogTag:Evaluate("[Subtract(2, 1)]"), 1)
assert_equal(DogTag:Evaluate("[Subtract(1, right=2)]"), -1)
assert_equal(DogTag:Evaluate("[Subtract(right=1, 2)]"), 1)
assert_equal(DogTag:Evaluate("[Subtract(left=1, right=2)]"), -1)
assert_equal(DogTag:Evaluate("[Subtract(right=1, left=2)]"), 1)
assert_equal(DogTag:Evaluate("[1:Subtract(2)]"), -1)
assert_equal(DogTag:Evaluate("[2:Subtract(1)]"), 1)
assert_equal(DogTag:Evaluate("[nil]"), nil)
assert_equal(DogTag:Evaluate("[not nil]"), "True")
assert_equal(DogTag:Evaluate("['True']"), "True")
assert_equal(DogTag:Evaluate("[not 'True']"), nil)
assert_equal(DogTag:Evaluate("[nil nil]"), nil)
assert_equal(DogTag:Evaluate("[nil '' nil]"), nil)
assert_equal(DogTag:Evaluate("[not nil not '' not nil]"), "TrueTrueTrue")
assert_equal(DogTag:Evaluate("[nil 'Hello' nil]"), "Hello")
assert_equal(DogTag:Evaluate("[nil 1234 nil]"), 1234)
assert_equal(DogTag:Evaluate("[nil 1234 One nil]"), 12341)
GlobalCheck_data = 5
assert_equal(DogTag:Evaluate("[nil 1234 GlobalCheck nil]"), 12345)
GlobalCheck_data = 'Hello'
assert_equal(DogTag:Evaluate("[nil 1234 GlobalCheck nil]"), '1234Hello')

myfunc_num = 0
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 1)
assert_equal(DogTag:Evaluate("['True' and FunctionNumberCheck]"), 2)
assert_equal(DogTag:Evaluate("[nil and FunctionNumberCheck]"), nil) -- shouldn't call FunctionNumberCheck
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 3)
assert_equal(DogTag:Evaluate("['True' or FunctionNumberCheck]"), "True") -- shouldn't call FunctionNumberCheck
assert_equal(DogTag:Evaluate("[nil or FunctionNumberCheck]"), 4)
assert_equal(DogTag:Evaluate("[if 'True' then FunctionNumberCheck]"), 5)
assert_equal(DogTag:Evaluate("[if nil then FunctionNumberCheck]"), nil)
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 6)
assert_equal(DogTag:Evaluate("[if 'True' then 'True' else FunctionNumberCheck]"), 'True')
assert_equal(DogTag:Evaluate("[FunctionNumberCheck]"), 7)
assert_equal(DogTag:Evaluate("[if nil then 'True' else FunctionNumberCheck]"), 8)

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
assert_equal(DogTag:Evaluate("[TupleAndKwarg(value=0.5, 2, 3, 4)]"), 2)
assert_equal(DogTag:Evaluate("[TupleAndKwarg(2, 3, 4, value=0.5)]"), 2)

assert_equal(parse([=[['Alpha\'Bravo']]=]), "Alpha'Bravo")
assert_equal(parse([=[["Alpha\"Bravo"]]=]), 'Alpha"Bravo')
assert_equal(parse([=[['Alpha\'Bravo"Charlie']]=]), "Alpha'Bravo\"Charlie")
assert_equal(parse([=[["Alpha\"Bravo'Charlie"]]=]), 'Alpha"Bravo\'Charlie')
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

GlobalCheck_data = nil
assert_equal(DogTag:Evaluate("[Type(GlobalCheck)]"), "nil")
GlobalCheck_data = "Hello"
assert_equal(DogTag:Evaluate("[Type(GlobalCheck)]"), "string")
GlobalCheck_data = 5
assert_equal(DogTag:Evaluate("[Type(GlobalCheck)]"), "number")

assert_equal(DogTag:Evaluate("[ToString(nil)]"), "``")
assert_equal(DogTag:Evaluate("[ToString('Hello')]"), "`Hello`")
assert_equal(DogTag:Evaluate("[ToString(5)]"), "`5`")

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

print("Tests succeeded")
