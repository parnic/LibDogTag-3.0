local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_MINOR_VERSION then
	_G.DogTag_MINOR_VERSION = MINOR_VERSION
end

DogTag_funcs[#DogTag_funcs+1] = function()

local DogTag = _G.DogTag

local DOGTAG, SEGMENT, TAG_SEQUENCE, CHUNK, SPACE, MULTI_SPACE, EXPONENTIATION, MULTIPLICATION, ADDITION, CONCATENATION, LOGIC, MULTI_DIGIT, ALPHANUM, SIGNED_INTEGER, INNER_PARAM_LIST, COMPARISON, IF_STATEMENT, INNER_TAG_SEQUENCE, TAG, PARAM_LIST, NUMBER, STRING, GROUPING, NEGATION, CHUNK_WITH_MODIFIER

local table_concat = _G.table.concat
local table_insert = _G.table.insert
local table_sort = _G.table.sort
local type = _G.type
local newList, del, deepDel = DogTag.newList, DogTag.del, DogTag.deepDel

local reserved = {
	["if"] = true,
	["then"] = true,
	["else"] = true,
	["and"] = true,
	["or"] = true,
	["not"] = true,
}

-- { SEGMENT }
function DOGTAG(tokens)
	local position = 1
	local isConcatList = false
	local list
	while true do
		local data
		position, data = SEGMENT(tokens, position)
		if position then
			if list then
				if isConcatList then
					list[#list+1] = data
				else
					list = newList(" ", list, data)
					isConcatList = true
				end
			else
				list = data
			end
		else
			break
		end
	end
	return list
end

-- { TAG_SEQUENCE } | { OUTER_STRING };
function SEGMENT(tokens, position)
	local pos, data = TAG_SEQUENCE(tokens, position)
	if pos then
		return pos, data
	end
	
	local c = tokens[position]
	if c then
		return position+1, c
	end
	
	return nil
end

-- IF_STATEMENT
function INNER_TAG_SEQUENCE(tokens, position)
	local position, data = IF_STATEMENT(tokens, position)
	if not position then
		return nil
	end
	return position, data
end

-- "[", MULTI_SPACE, INNER_TAG_SEQUENCE, MULTI_SPACE, "]"
function TAG_SEQUENCE(tokens, position)
	if tokens[position] ~= "[" then
		return nil
	end
	
	position = MULTI_SPACE(tokens, position+1)
	
	local position, data = INNER_TAG_SEQUENCE(tokens, position)
	if not position then
		return nil
	end
	
	position = MULTI_SPACE(tokens, position)
	
	if tokens[position] ~= "]" then
		data = deepDel(data)
		return nil
	end
	return position+1, data
end

-- CHUNK, { MULTI_SPACE, ":", [ "~" ], TAG, [ PARAM_LIST ] }
function CHUNK_WITH_MODIFIER(tokens, position)
	local position, data = CHUNK(tokens, position)
	if not position then
		return nil
	end
	
	while true do
		local pos = MULTI_SPACE(tokens, position)
		
		if tokens[pos] ~= ":" then
			return position, data
		end
	
		pos = MULTI_SPACE(tokens, pos+1)
	
		if tokens[pos] == "~" then
			pos = MULTI_SPACE(tokens, pos+1)
		
			local pos, d = TAG(tokens, pos)
			if not pos then
				return position, data
			end
			local p, list = PARAM_LIST(tokens, pos)
			if p then
				table_insert(list, 1, "mod")
				table_insert(list, 2, d)
				table_insert(list, 3, data)
				position, data = p, newList("~", list)
			else
				position, data = pos, newList("~", newList("mod", d, data))
			end
		else
			local pos, d = TAG(tokens, pos)
			if not pos then
				return position, data
			end
			local p, list = PARAM_LIST(tokens, pos)
			if p then
				table_insert(list, 1, "mod")
				table_insert(list, 2, d)
				table_insert(list, 3, data)
				position, data = p, list
			else
				position, data = pos, newList("mod", d, data)
			end
		end
	end
end

-- GROUPING | STRING | NUMBER | TAG, [ PARAM_LIST ]
function CHUNK(tokens, position)
	local pos, data = GROUPING(tokens, position)
	if pos then
		return pos, data
	end
	
	pos, data = STRING(tokens, position)
	if pos then
		if data == "" then
			return pos, newList("nil")
		end
		return pos, data
	end
	
	pos, data = NUMBER(tokens, position)
	if pos then
		return pos, data
	end
	
	local pos, data = TAG(tokens, position)
	if pos then
		if data:lower() == 'nil' then
			return pos, newList("nil")
		end
		local p, list = PARAM_LIST(tokens, pos)
		if p then
			table_insert(list, 1, "tag")
			table_insert(list, 2, data)
			return p, list
		else
			return pos, newList("tag", data)
		end
	end
	
	return nil
end

local groupings = {
	["["] = "]",
	["("] = ")"
}

--   "(", MULTI_SPACE, INNER_TAG_SEQUENCE, MULTI_SPACE, ")"
-- | "[", MULTI_SPACE, INNER_TAG_SEQUENCE, MULTI_SPACE, "]"
function GROUPING(tokens, position)
	local start = tokens[position]
	local shouldFinish = groupings[start]
	if not shouldFinish then
		return nil
	end
	
	position = MULTI_SPACE(tokens, position+1)
	
	local position, data = INNER_TAG_SEQUENCE(tokens, position)
	if not position then
		return nil
	end
	
	position = MULTI_SPACE(tokens, position)
	
	if tokens[position] ~= shouldFinish then
		data = deepDel(data)
		return nil
	end
	return position+1, newList(start, data)
end

-- ALPHANUM
function TAG(tokens, position)
	local position, tag = ALPHANUM(tokens, position)
	if not position then
		return nil
	end
	if tag and type(tag) == "string" then
		local tag_lower = tag:lower()
		if reserved[tag_lower] then
			return nil
		elseif tag_lower == "nil" then
			-- TODO
		end
	end
	return position, tag
end

-- INNER_TAG_SEQUENCE, { MULTI_SPACE, ",", MULTI_SPACE, INNER_TAG_SEQUENCE }, { MULTI_SPACE, ",", MULTI_SPACE, ALPHANUM, "=", INNER_TAG_SEQUENCE }
function INNER_PARAM_LIST(tokens, position)
	local pos, key = ALPHANUM(tokens, position)
	local data
	if pos and tokens[pos] == "=" and key:lower() == key then
		local value
		position, value = INNER_TAG_SEQUENCE(tokens, pos+1)
		if not position then
			return nil
		end
		data = newList()
		data.kwarg = newList()
		data.kwarg[key] = value
	else
		position, data = INNER_TAG_SEQUENCE(tokens, position)
		if not position then
			return nil
		end
		data = newList(data)
	end
	while true do
		position = MULTI_SPACE(tokens, position)
		if tokens[position] ~= "," then
			return position, data
		end
		position = MULTI_SPACE(tokens, position+1)
		local pos, key = ALPHANUM(tokens, position)
		if pos and tokens[pos] == "=" and key:lower() == key then
			pos, value = INNER_TAG_SEQUENCE(tokens, pos+1)
			if not pos then
				return position, data
			end
			position = pos
			if not data.kwarg then
				data.kwarg = newList()
			end
			data.kwarg[key] = value
		else
			local pos, chunk = INNER_TAG_SEQUENCE(tokens, position)
			if not pos then
				return position, data
			end
			position = pos
			data[#data+1] = chunk
		end
	end
end

-- "(", MULTI_SPACE, INNER_PARAM_LIST, MULTI_SPACE, ")"
function PARAM_LIST(tokens, position)
	if tokens[position] ~= "(" then
		return nil
	end
	
	position = MULTI_SPACE(tokens, position+1)
	
	local position, data = INNER_PARAM_LIST(tokens, position)
	if not position then
		return nil
	end
	
	position = MULTI_SPACE(tokens, position)
	
	if tokens[position] ~= ")" then
		data = deepDel(data)
		return nil
	end
	
	return position+1, data
end

local quotes = {
	["'"] = true,
	['"'] = true,
}

-- '"', ( ANY - '"' ), '"' | "'", ( ANY - "'" ), "'"
function STRING(tokens, position)
	local c = tokens[position]
	if not quotes[c] then
		return nil
	end
	local t = newList()
	local lastEscape = false
	for i = position+1, #tokens do
		local v = tokens[i]
		if v == [=[\]=] then
			if lastEscape then
				lastEscape = false
				t[#t+1] = [=[\]=]
			else
				lastEscape = true
			end
		elseif v == c then
			if lastEscape then
				lastEscape = false
				t[#t+1] = c
			else
				local s = table_concat(t)
				t = del(t)
				return i+1, s
			end
		else
			if lastEscape then
				lastEscape = false
				if v:find("^%d+$") then
					if #v <= 3 then
						t[#t+1] = string.char(v+0)
					else
						t[#t+1] = string.char(v:sub(1, 3)+0)
						t[#t+1] = v:sub(4)
					end
				else
					t[#t+1] = [=[\]=]
					t[#t+1] = v
				end
			else
				t[#t+1] = v
			end
		end
	end
	t = del(t)
	return nil
end

-- SIGNED_INTEGER, [ ".", MULTI_DIGIT | ("e" | "E"), SIGNED_INTEGER ]
function NUMBER(tokens, position)
	local pos, number = SIGNED_INTEGER(tokens, position)
	if not pos then
		return nil
	end
	
	local c = tokens[pos]
	if c == "." then
		local pos2, num = MULTI_DIGIT(tokens, pos+1)
		if pos2 then
			local negative = number < 0
			if negative then
				number = -number
			end
			for i = 1, #num do
				number = number + (10^-i)*(num:byte(i) - ('0'):byte())
			end
			if negative then
				number = -number
			end
			return pos2, number
		end
	else
		local pos2, n = ALPHANUM(tokens, pos)
		if pos2 then
		 	if n:match("^[eE][0-9]+$") then
				return pos2, number * 10^(n:sub(2)+0)
			elseif n == "e" then
				pos2, n = SIGNED_INTEGER(tokens, pos2)
				return pos2, number * 10^n
			end
		end
	end
	return pos, number
end

-- [ "-", ] MULTI_DIGIT
function SIGNED_INTEGER(tokens, position)
	local c = tokens[position]
	if c == "-" then
		local pos, number = MULTI_DIGIT(tokens, position+1)
		if pos then
			return pos, 0-number
		else
			return nil
		end
	else
		local pos, number = MULTI_DIGIT(tokens, position)
		if pos then
			return pos, 0+number
		else
			return nil
		end
	end
end

-- ('A'..'Z' | 'a'..'z' | '_'), { '0'..'9' | 'A'..'Z' | 'a'..'z' | '_' }
function ALPHANUM(tokens, position)
	local c = tokens[position]
	if c:match("^[A-Za-z_][0-9A-Za-z_]*$") then
		return position+1, c
	else
		return nil
	end
end

-- '0'..'9', { '0'..'9' }
function MULTI_DIGIT(tokens, position)
	local c = tokens[position]
	if c:match("^[0-9]+$") then
		return position+1, c
	end
end

-- { SPACE }
function MULTI_SPACE(tokens, position)
	while true do
		local pos = SPACE(tokens, position)
		if pos then
			position = pos
		else
			return position
		end
	end
end

-- " " | "\t" | "\n" | "\r"
function SPACE(tokens, position)
	local c = tokens[position]
	if c == " " or c == "\t" or c == "\n" or c == "\r" then
		return position+1
	else
		return nil
	end
end

--   COMPARISON, [ MULTI_SPACE, "?", MULTI_SPACE, COMPARISON, [ MULTI_SPACE, "!", MULTI_SPACE, COMPARISON ] ]
-- | "if", MULTI_SPACE, COMPARISON, MULTI_SPACE, "then", MULTI_SPACE, COMPARISON, [ MULTI_SPACE, "else", MULTI_SPACE, COMPARISON ]
function IF_STATEMENT(tokens, position)
	local c = tokens[position]
	if type(c) == "string" and c:lower() == "if" then
		position = MULTI_SPACE(tokens, position+1)
		local position, data = COMPARISON(tokens, position)
		if not position then
			return nil
		end
		position = MULTI_SPACE(tokens, position)
		c = tokens[position]
		if type(c) == "string" then
			c = c:lower()
		end
		if c ~= "then" then
			data = deepDel(data)
			return nil
		end
		position = MULTI_SPACE(tokens, position+1)
		local position, d = COMPARISON(tokens, position)
		if not position then
			data = deepDel(data)
			return nil
		end
		data = newList("if", data, d)
		
		local pos = MULTI_SPACE(tokens, position)
		
		local c = tokens[pos]
		if type(c) == "string" then
			c = c:lower()
		end
		if c ~= "else" then
			return position, data
		end
	
		pos = MULTI_SPACE(tokens, pos+1)
	
		pos, d = COMPARISON(tokens, pos)
		if not pos then
			return position, data
		end
		position = pos
		data[4] = d
	
		return position, data
	else
		local position, data = COMPARISON(tokens, position)
		if not position then
			return nil
		end
	
		local pos = MULTI_SPACE(tokens, position)
	
		if tokens[pos] ~= "?" then
			return position, data
		end
	
		pos = MULTI_SPACE(tokens, pos+1)
	
		local pos, d = COMPARISON(tokens, pos)
		if not pos then
			return position, data
		end
		position = pos
		data = newList("?", data, d)
		
		pos = MULTI_SPACE(tokens, pos)
	
		if tokens[pos] ~= "!" then
			return position, data
		end
	
		pos = MULTI_SPACE(tokens, pos+1)
	
		pos, d = COMPARISON(tokens, pos)
		if not pos then
			return position, data
		end
		position = pos
		data[4] = d
	
		return position, data
	end
end

-- LOGIC, { MULTI_SPACE, ("<=" | "<" | ">" | ">=" | "=" | "~="), MULTI_SPACE, LOGIC }
function COMPARISON(tokens, position)
	local position, data = LOGIC(tokens, position)
	if not position then
		return nil
	end
	
	while true do
		local pos = MULTI_SPACE(tokens, position)
		local c = tokens[pos]
		local op
		if c == "<" then
			if tokens[pos+1] == "=" then
				op = "<="
				pos = pos+1
			else
				op = "<"
			end
		elseif c == ">" then
			if tokens[pos+1] == "=" then
				op = ">="
				pos = pos+1
			else
				op = ">"
			end
		elseif c == "=" then
			op = "="
		elseif c == "~" then
			if tokens[pos+1] ~= "=" then
				break
			end
			pos = pos+1
			op = "~="
		else
			break
		end
		pos = MULTI_SPACE(tokens, pos+1)
		local pos, chunk = LOGIC(tokens, pos)
		if not pos then
			break
		end
		position = pos
		data = newList(op, data, chunk)
	end
	
	return position, data
end

-- CONCATENATION, { MULTI_SPACE, ( "and" | "or" | "&" | "|" ), MULTI_SPACE, CONCATENATION }
function LOGIC(tokens, position)
	local position, data = CONCATENATION(tokens, position)
	if not position then
		return nil
	end
	
	while true do
		local pos = MULTI_SPACE(tokens, position)
		local op = tokens[pos]
		if type(op) == "string" then
			op = op:lower()
		end
		if op ~= "and" and op ~= "&" and op ~= "or" and op ~= "|" then
			break
		end
		pos = MULTI_SPACE(tokens, pos+1)
		local pos, chunk = CONCATENATION(tokens, pos)
		if not pos then
			break
		end
		position = pos
		data = newList(op, data, chunk)
	end
	
	return position, data
end

-- ADDITION, { SPACE, MULTI_SPACE, ADDITION }
function CONCATENATION(tokens, position)
	local position, data = ADDITION(tokens, position)
	if not position then
		return nil
	end
	
	local list
	
	while true do
		local pos = SPACE(tokens, position)
		if not pos then
			break
		end
		pos = MULTI_SPACE(tokens, pos)
		local pos, chunk = ADDITION(tokens, pos)
		if not pos then
			break
		end
		position = pos
		if list then
			list[#list+1] = chunk
		else
			list = newList(" ", data, chunk)
		end
	end
	
	return position, list or data
end

-- MULTIPLICATION, { MULTI_SPACE, ( "+" | "-" ), MULTIPLICATION }
function ADDITION(tokens, position)
	local position, data = MULTIPLICATION(tokens, position)
	if not position then
		return nil
	end
	
	while true do
		local pos = MULTI_SPACE(tokens, position)
		local op = tokens[pos]
		if op ~= "+" and op ~= "-" then
			break
		end
		pos = MULTI_SPACE(tokens, pos+1)
		local pos, chunk = MULTIPLICATION(tokens, pos)
		if not pos then
			break
		end
		position = pos
		data = newList(op, data, chunk)
	end
	
	return position, data
end

-- NEGATION, { MULTI_SPACE, ( "*" | "/" | "%" ), MULTI_SPACE, NEGATION }
function MULTIPLICATION(tokens, position)
	local position, data = NEGATION(tokens, position)
	if not position then
		return nil
	end
	
	while true do
		local pos = MULTI_SPACE(tokens, position)
		local op = tokens[pos]
		if op ~= "*" and op ~= "/" and op ~= "%" then
			break
		end
		pos = MULTI_SPACE(tokens, pos+1)
		local pos, chunk = NEGATION(tokens, pos)
		if not pos then
			break
		end
		position = pos
		data = newList(op, data, chunk)
	end
	
	return position, data
end

-- { ( "not" | "~" ), MULTI_SPACE, } EXPONENTIATION
function NEGATION(tokens, position)
	local nots = newList()
	while true do
		local op = tokens[position]
		
		if op ~= "not" and op ~= "~" then
			local data
			position, data = EXPONENTIATION(tokens, position)
			if not position then
				nots = del(nots)
				return nil
			end
			for i = #nots, 1, -1 do
				data = newList(nots[i], data)
			end
			nots = del(nots)
			return position, data
		end
		
		nots[#nots+1] = op
		
		position = MULTI_SPACE(tokens, position+1)
	end
end

-- UNARY_MINUS, { MULTI_SPACE, "^", MULTI_SPACE UNARY_MINUS }
function EXPONENTIATION(tokens, position)
	local position, data = UNARY_MINUS(tokens, position)
	if not position then
		return nil
	end
	
	while true do
		local pos = MULTI_SPACE(tokens, position)
		local op = tokens[pos]
		if op ~= "^" then
			break
		end
		pos = MULTI_SPACE(tokens, pos+1)
		local pos, chunk = UNARY_MINUS(tokens, pos)
		if not pos then
			break
		end
		position = pos
		data = newList(op, data, chunk)
	end
	
	return position, data
end

-- [ "-", MULTI_SPACE, ] CHUNK_WITH_MODIFIER
function UNARY_MINUS(tokens, position)
	local op = tokens[position]

	if op ~= "-" then
		local position, data = CHUNK_WITH_MODIFIER(tokens, position)
		if not position then
			return nil
		end
		return position, data
	end

	local pos = MULTI_SPACE(tokens, position+1)

	if tokens[pos] == "-" then
		-- don't have double negatives without parentheses
		return nil
	end
	local position, data = CHUNK_WITH_MODIFIER(tokens, pos)
	if not position then
		return nil
	end
	if type(data) == "number" then
		return position, -data
	else
		-- TODO: this should not be this way.
		local current, next_ = nil, data
		while type(next_) == "table" do
			if next_[1] == "mod" then
				current = next_
				next_ = next_[3]
			else
				break
			end
		end
		if current and current[1] == "mod" then
			if type(next_) == "number" then
				current[3] = -current[3]
				return position, data
			elseif type(next_) == "table" and next_[1] == "tag" then
				current[3] = newList("unm", next_)
				return position, data
			end
		end
		return position, newList("unm", data)
	end
end

local function tokenize(code)
	local next_start = 1
	local tokens = newList()
	while true do
		local start, finish, literal_left, code_right = code:find("^(.-)(%b[])", next_start)
		if not start then
			break
		end
		if literal_left ~= "" then
			tokens[#tokens+1] = literal_left
		end
		next_start = finish+1
		local last_type
		local alphanum_start
		for i = 1, #code_right do
			local b = code_right:byte(i)
			local b_type
			if b >= ('0'):byte() and b <= ('9'):byte() then
				if last_type ~= 'alphanum' and last_type ~= 'number' then
					alphanum_start = i
					last_type = 'number'
				end
			elseif (b >= ('a'):byte() and b <= ('z'):byte()) or (b >= ('A'):byte() and b <= ('Z'):byte()) or b == ("_"):byte() then
				if last_type == 'number' then
					tokens[#tokens+1] = code_right:sub(alphanum_start, i-1)
				end
				if last_type ~= 'alphanum' then
					alphanum_start = i
					last_type = 'alphanum'
				end
			else
				if last_type == 'alphanum' or last_type == 'number' then
					tokens[#tokens+1] = code_right:sub(alphanum_start, i-1)
				end
				tokens[#tokens+1] = code_right:sub(i, i)
				last_type = 'symbol'
			end
		end
		if last_type == 'alphanum' or last_type == 'number' then
			tokens[#tokens+1] = code_right:sub(alphanum_start)
		end
	end
	local literal_right = code:sub(next_start)
	if literal_right ~= "" then
		tokens[#tokens+1] = literal_right
	end
	
	return tokens
end

local function parse(code)
	if code == "" then
		return newList( "nil" )
	end
	local tokens = tokenize(code)
	local ast = DOGTAG(tokens)
	tokens = del(tokens)
	return ast
end
DogTag.parse = parse

local standardizations = {
	['mod'] = 'tag',
	['?'] = 'if',
	['&'] = 'and',
	['|'] = 'or',
	['~'] = 'not',
}

local function standardize(ast, parent)
	if type(ast) ~= "table" then
		return ast
	end
	
	local kind = ast[1]
	
	if kind == "(" or kind == "[" then
		local ast_2 = ast[2]
		standardize(ast_2, ast)
		local parent__i
		if parent then
			for i, v in pairs(parent) do -- use pairs, might be kwarg
				if v == ast then
					parent__i = i
					break
				end
			end
		end
		del(ast)
		if parent__i then
			parent[parent__i] = ast_2
		end
		return ast_2
	else
		ast[1] = standardizations[kind] or kind
	
		for i = 2, #ast do
			standardize(ast[i], ast)
		end
		local kwarg = ast.kwarg
		if kwarg then
			for k,v in pairs(kwarg) do
				standardize(v, kwarg)
			end
		end
	end
	
	return ast
end
DogTag.standardize = standardize

local orderOfOperations = {
	"GROUPING",
	"MODIFIER",
	"UNARY_MINUS",
	"EXPONENTIATION",
	"NEGATION",
	"MULTIPLICATION",
	"ADDITION",
	"CONCATENATION",
	"LOGIC",
	"COMPARISON",
	"IF_STATEMENT",
}
do
	local tmp = orderOfOperations
	orderOfOperations = newList()
	for i,v in ipairs(tmp) do
		orderOfOperations[v] = i
	end
	tmp = del(tmp)
end

local operators = {
	["+"] = "ADDITION",
	["-"] = "ADDITION",
	["*"] = "MULTIPLICATION",
	["/"] = "MULTIPLICATION",
	["%"] = "MULTIPLICATION",
	["^"] = "EXPONENTIATION",
	["<"] = "COMPARISON",
	[">"] = "COMPARISON",
	["<="] = "COMPARISON",
	[">="] = "COMPARISON",
	["="] = "COMPARISON",
	["~="] = "COMPARISON",
	["and"] = "LOGIC",
	["or"] = "LOGIC",
	["&"] = "LOGIC",
	["|"] = "LOGIC",
	["mod"] = "MODIFIER",
	["tag"] = "MODIFIER",
	["string"] = "MODIFIER",
	["number"] = "MODIFIER",
	[" "] = "CONCATENATION",
	["~"] = "NEGATION",
	["not"] = "NEGATION",
	["if"] = "IF_STATEMENT",
	["?"] = "IF_STATEMENT",
	["unm"] = "UNARY_MINUS",
	["("] = "GROUPING",
	["["] = "GROUPING",
}
for k,v in pairs(operators) do
	operators[k] = orderOfOperations[v]
end

local function getKind(ast)
	local type_ast = type(ast)
	if type_ast ~= "table" then
		return type_ast
	else
		return ast[1]
	end
end

local function unparse(ast, t, inner, negated, parentOperatorPrecedence)
	local type_ast = getKind(ast)
	if type_ast == "string" then
		if not inner then
			if t then
				t[#t+1] = ast
				return
			else
				return ast
			end
		else
			local str
			if ast:match('"') and not ast:match("'") then
				str = "'" .. ast .. "'"
			else
				str = ("%q"):format(ast)
			end
			if t then
				t[#t+1] = str
				return
			else
				return str
			end
		end
	elseif type_ast == "number" then
		if t then
			if not inner then
				t[#t+1] = "["
			end
			t[#t+1] = tostring(ast)
			if not inner then
				t[#t+1] = "]"
			end
			return
		else
			if not inner then
				return ("[%s]"):format(ast)
			else
				return tostring(ast)
			end
		end
	elseif type_ast == "nil" then
		if t then
			if not inner then
				return
			else
				t[#t+1] = "nil"
				return
			end
		else
			if not inner then
				return ""
			else
				return "nil"
			end
		end
	end
	local madeT = not t
	if madeT then
		t = newList()
	end
	
	local operators_type_ast = operators[type_ast]
	if not operators_type_ast then
		error(("Unknown operator: %q"):format(type_ast))
	end
	local manualGrouping = parentOperatorPrecedence and parentOperatorPrecedence < operators_type_ast
	if type_ast == " " then
		if inner then
			if manualGrouping then
				t[#t+1] = "("
			end
			unparse(ast[2], t, true, false, operators_type_ast)
			for i = 3, #ast do
				t[#t+1] = " "
				unparse(ast[i], t, true, false, operators_type_ast)
			end
			if manualGrouping then
				t[#t+1] = ")"
			end
		else
			local need_to_do_last = false
			local bracket_open = false
			for i = 2, #ast do
				if type(ast[i]) == "string" then
					if need_to_do_last then
						if bracket_open then
							t[#t+1] = " "
							unparse(ast[i-1], t, true, false, operators_type_ast)
							t[#t+1] = ']'
						else
							unparse(ast[i-1], t, false, false, operators_type_ast)
						end
					end
					unparse(ast[i], t, false, false, operators_type_ast)
					need_to_do_last = false
				else
					if need_to_do_last then
						if bracket_open then
							t[#t+1] = " "
						else
							t[#t+1] = "["
							bracket_open = true
						end
						unparse(ast[i-1], t, true, false, operators_type_ast)
					end
					need_to_do_last = true
				end
			end
			if need_to_do_last then
				if bracket_open then
					t[#t+1] = " "
					unparse(ast[#ast], t, true, false, operators_type_ast)
					t[#t+1] = "]"
				else
					unparse(ast[#ast], t, false, false, operators_type_ast)
				end
			end
		end
	else
		if not inner then
			t[#t+1] = '['
		end
		if manualGrouping then
			t[#t+1] = "("
		end
		if groupings[type_ast] then
			t[#t+1] = type_ast
			unparse(ast[2], t, true, false, nil)
			t[#t+1] = groupings[type_ast]
		elseif type_ast == "tag" then
			if negated then
				t[#t+1] = '~'
			end
			t[#t+1] = ast[2]
			if ast[3] or ast.kwarg then
				t[#t+1] = '('
				local first = true
				for i = 3, #ast do
					if not first then
						t[#t+1] = ', '
					end
					first = false
					unparse(ast[i], t, true, false, nil)
				end
				if ast.kwarg then
					local keys = newList()
					for k in pairs(ast.kwarg) do
						keys[#keys+1] = k
					end
					table_sort(keys)
					for _,k in ipairs(keys) do
						if not first then
							t[#t+1] = ', '
						end
						first = false
						t[#t+1] = k
						t[#t+1] = '='
						unparse(ast.kwarg[k], t, true, false, nil)
					end
					keys = del(keys)
				end
				t[#t+1] = ')'
			end
		elseif type_ast == "mod" then
			unparse(ast[3], t, true, false, operators_type_ast)
			t[#t+1] = ':'
			if negated then
				t[#t+1] = '~'
			end
			t[#t+1] = ast[2]
			if ast[4] or ast.kwarg then
				t[#t+1] = '('
				local first = true
				for i = 4, #ast do
					if not first then
						t[#t+1] = ', '
					end
					first = false
					unparse(ast[i], t, true, false, nil)
				end
				if ast.kwarg then
					local keys = newList()
					for k in pairs(ast.kwarg) do
						keys[#keys+1] = k
					end
					table_sort(keys)
					for _,k in ipairs(keys) do
						if not first then
							t[#t+1] = ', '
						end
						first = false
						t[#t+1] = k
						t[#t+1] = '='
						unparse(ast.kwarg[k], t, true, false, nil)
					end
					keys = del(keys)
				end
				t[#t+1] = ')'
			end
		elseif type_ast == "~" then
			if type(ast[2]) == "table" and (ast[2][1] == "tag" or ast[2][1] == "mod") then
				unparse(ast[2], t, true, true, operators_type_ast)
			else
				t[#t+1] = '~'
				unparse(ast[2], t, true, false, operators_type_ast)
			end
		elseif type_ast == "not" then
			-- TODO: Test
			t[#t+1] = 'not '
			unparse(ast[2], t, true, false, operators_type_ast)
		elseif type_ast == "?" then
			unparse(ast[2], t, true, false, operators_type_ast)
			t[#t+1] = ' ? '
			unparse(ast[3], t, true, false, operators_type_ast)
			if ast[4] then
				t[#t+1] = ' ! '
				unparse(ast[4], t, true, false, operators_type_ast)
			end
		elseif type_ast == "if" then
			t[#t+1] = "if "
			unparse(ast[2], t, true, false, operators_type_ast)
			t[#t+1] = " then "
			unparse(ast[3], t, true, false, operators_type_ast)
			if ast[4] then
				t[#t+1] = " else "
				unparse(ast[4], t, true, false, operators_type_ast)
			end
		elseif type_ast == "unm" then
			t[#t+1] = "-"
			unparse(ast[2], t, true, false, operators_type_ast)
		elseif operators_type_ast then
			unparse(ast[2], t, true, false, operators_type_ast)
			t[#t+1] = ' '
			t[#t+1] = type_ast
			t[#t+1] = ' '
			unparse(ast[3], t, true, false, operators_type_ast)
		end
		if manualGrouping then
			t[#t+1] = ")"
		end
		if not inner then
			t[#t+1] = ']'
		end
	end
	
	if madeT then
		local s = table_concat(t)
		t = del(t)
		return s
	end
end
DogTag.unparse = unparse

local function cleanAST(ast)
	if type(ast) ~= "table" then
		return ast
	end
	
	local astType = ast[1]
	for i = 2, #ast do
		ast[i] = cleanAST(ast[i])
	end
	local kwarg = ast.kwarg
	if kwarg then
		for k,v in pairs(kwarg) do
			kwarg[k] = cleanAST(v)
		end
	end
	if groupings[astType] then
		local ast_2 = ast[2]
		if type(ast_2) ~= "table" or ast_2[1] == "tag" or ast_2[1] == "mod" then
			del(ast)
			return ast_2
		end
	end
	return ast
end

function DogTag:CleanCode(code)
	local ast = parse(code)
	ast = cleanAST(ast)
	local result = unparse(ast)
	ast = deepDel(ast)
	return result
end

end