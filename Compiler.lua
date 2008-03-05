local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_MINOR_VERSION then
	_G.DogTag_MINOR_VERSION = MINOR_VERSION
end

DogTag_funcs[#DogTag_funcs+1] = function()

local DogTag = _G.DogTag

local L = DogTag__L

local FakeGlobals = DogTag.FakeGlobals
local Tags = DogTag.Tags
local newList, newDict, newSet, del = DogTag.newList, DogTag.newDict, DogTag.newSet, DogTag.del

local function getNamespaceList(...)
	local n = select('#', ...)
	if n == 0 then
		return "Base"
	end
	local t = newList()
	t["Base"] = true
	for i = 1, n do
		local v = select(i, ...)
		t[v] = true
	end
	local u = newList()
	for k in pairs(t) do
		u[#u+1] = k
	end
	t = del(t)
	table.sort(u)
	local value = table.concat(u, ';')
	u = del(u)
	return value
end

local function select2(min, max, ...)
	if min <= max then
		return select(min, ...), select2(min+1, max, ...)
	end
end

local function joinSet(set, connector)
	local t = newList()
	for k in pairs(set) do
		t[#t+1] = k
	end
	table.sort(t)
	local s = table.concat(t, connector)
	t = del(t)
	return s
end

local unpackNamespaceList = setmetatable({}, {__index = function(self, key)
	local t = newList((";"):split(key))
	self[key] = t
	return t
end, __call = function(self, key)
	return unpack(self[key])
end})

local function getASTType(ast)
	local type_ast = type(ast)
	if type_ast ~= "table" then
		return type_ast
	end
	return ast[1]
end

local correctTagCasing = setmetatable({}, {__index = function(self, tag)
	for ns, data in pairs(Tags) do
		if data[tag] then
			self[tag] = tag
			return tag
		end
	end
	
	local tag_lower = tag:lower()
	for ns, data in pairs(Tags) do
		for t in pairs(data) do
			if tag_lower == t:lower() then
				self[tag] = t
				return t
			end
		end
	end
	self[tag] = tag
	return tag
end})

local function correctASTCasing(ast)
	if type(ast) ~= "table" then
		return
	end
	local astType = ast[1]
	if astType == "tag" or astType == "mod" then
		ast[2] = correctTagCasing[ast[2]]
		if ast.kwarg then
			for k,v in pairs(ast.kwarg) do
				correctASTCasing(v)
			end
		end
	end
	for i = 1, #ast do
		correctASTCasing(ast[i])
	end
end

local kwargsKeyPool = { [""] = {} }
local function kwargsToKey(kwargs)
	if not kwargs then
		return kwargsKeyPool[""]
	end
	local kwargsKey = newList()
	local keys = newList()
	for k in pairs(kwargs) do
		keys[#keys+1] = k
	end
	table.sort(keys)
	local t = newList()
	for i,k in ipairs(keys) do
		if i > 1 then
			t[#t+1] = ";"
		end
		local v = kwargs[k]
		t[#t+1] = k
		t[#t+1] = "="
		local type_v = type(v)
		t[#t+1] = type_v
		kwargsKey[k] = type_v
	end
	keys = del(keys)
	local s = table.concat(t)
	t = del(t)
	local kwargsKeyPool_s = kwargsKeyPool[s]
	if kwargsKeyPool_s then
		kwargsKey = del(kwargsKey)
		return kwargsKeyPool_s
	end
	kwargsKeyPool[s] = kwargsKey
	return kwargsKey
end
DogTag.kwargsToKey = kwargsToKey

local codeToFunction
do
	local codeToFunction_mt_mt = {__index = function(self, code)
		if not code then
			return self[""]
		end
		local nsList = self[1]
		local kwargsKey = self[2]
		
		local s = DogTag:CreateFunctionFromCode(code, true, kwargsKey, unpackNamespaceList(nsList))
		for i, ns in ipairs(unpackNamespaceList[nsList]) do
			local data = FakeGlobals[ns]
			if data then
				for k, v in pairs(data) do
					DogTag[k] = v
				end
			end
		end
		local func, err = loadstring(s)
		local val
		if not func then
			geterrorhandler()(("%s: Error (%s) loading code %q. Please inform ckknight."):format(MAJOR_VERSION, err, code))
			val = self[""]
		else
			local status, result = pcall(func)
			if not status then
				geterrorhandler()(("%s: Error (%s) running code %q. Please inform ckknight."):format(MAJOR_VERSION, result, code))
				val = self[""]
			else
				val = result
			end
		end
		for i, ns in ipairs(unpackNamespaceList[nsList]) do
			local data = FakeGlobals[ns]
			if data then
				for k in pairs(data) do
					DogTag[k] = nil
				end
			end
		end
		self[code] = val
		return val
	end}
	local codeToFunction_mt = {__index = function(self, kwargsKey)
		local t = setmetatable(newList(self[1], kwargsKey), codeToFunction_mt_mt)
		self[kwargsKey] = t
		return t
	end}
	codeToFunction = setmetatable({}, {__index = function(self, nsList)
		local t = setmetatable(newList(nsList), codeToFunction_mt)
		self[nsList] = t
		return t
	end})
end
DogTag.codeToFunction = codeToFunction

local figureCachedTags
do
	local function _figureCachedTags(ast)
		local cachedTags = newList()
		if type(ast) ~= "table" then
			return cachedTags
		end
		local astType = ast[1]
		if astType == 'tag' then
			if #ast == 2 and not ast.kwarg then
				local tagName = ast[2]
				cachedTags[tagName] = (cachedTags[tagName] or 0) + 1
			else
				if ast.kwarg then
					for key, value in pairs(ast.kwarg) do
						local data = _figureCachedTags(value)
						for k,v in pairs(data) do
							cachedTags[k] = (cachedTags[k] or 0) + v
						end
						data = del(data)
					end
				end
			end
		end
		for i = 2, #ast do
			local data = _figureCachedTags(ast[i])
			for k, v in pairs(data) do
				cachedTags[k] = (cachedTags[k] or 0) + v
			end
			data = del(data)
		end
		return cachedTags
	end
	function figureCachedTags(ast)
		local cachedTags = newList()
		local data = _figureCachedTags(ast)
		for k,v in pairs(data) do
			if v > 1 then
				cachedTags[k] = 1
			end
		end
		data = del(data)
		return cachedTags
	end
end

local figureGlobals
do
	function figureGlobals(ast, nsList, kwargsKey)
		local globals = newList()
		if type(ast) ~= "table" then
			return globals
		end
		local astType = ast[1]
		if astType == 'tag' then
			local tag = ast[2]
			for _,ns in ipairs(unpackNamespaceList[nsList]) do
				local Tags_ns = Tags[ns]
				if Tags_ns then
					local Tags_ns_tag = Tags_ns[tag]
					if Tags_ns_tag then
						local Tags_ns_tag_globals = Tags_ns_tag.globals
						if Tags_ns_tag_globals then
							local g = newList((";"):split(Tags_ns_tag_globals))
							for _,v in ipairs(g) do
								globals[v] = true
							end
							g = del(g)
							break
						end
					end
				end
			end
			if ast.kwarg then
				for k,v in pairs(ast.kwarg) do
					local g = figureGlobals(v, nsList, kwargsKey)
					for k in pairs(g) do
						globals[k] = true
					end
					g = del(g)
				end
			end
		end
		for i = 2, #ast do
			local g = figureGlobals(ast[i], nsList, kwargsKey)
			for k in pairs(g) do
				globals[k] = true
			end
			g = del(g)
		end
		return globals
	end
end

local function enumLines(text)
	text = text:gsub(";", ";\n"):gsub("\r\n", "\n"):gsub("\t", "    "):gsub("%f[A-Za-z_]do%f[^A-Za-z_]", "do\n"):gsub("%f[A-Za-z_]then%f[^A-Za-z_]", "then\n"):gsub("%f[A-Za-z_]else%f[^A-Za-z_]", "else\n"):gsub("\n *", "\n"):gsub("function(%b()) ", "function%1\n")
	local lines = newList(('\n'):split(text))
	local t = newList()
	local indent = 0
	for i = #lines, 1, -1 do
		local v = lines[i]
		if v:match("^%s*$") then
			table.remove(lines, i)
		end
	end
	for i, v in ipairs(lines) do
		if v:match("end;?$") or v:match("else$") or v:match("^ *elseif") then
			indent = indent - 1
		end
		for j = 1, indent do
			t[#t+1] = "    "
		end
		t[#t+1] = v:gsub(";\s*$", "")
		t[#t+1] = " -- "
		t[#t+1] = i
		t[#t+1] = "\n"
		if v:match("then$") or v:match("do$") or v:match("else$") or v:match("function%(.-%)") then
			indent = indent + 1
		end
	end
	lines = del(lines)
	local s = table.concat(t)
	t = del(t)
	return s
end

local newUniqueVar, delUniqueVar, clearUniqueVars, getNumUniqueVars
do
	local num = 0
	local pool = {}
	function newUniqueVar()
		local t = next(pool)
		if t then
			pool[t] = nil
			return t
		end
		num = num + 1
		return 'arg' .. num
	end
	function delUniqueVar(t)
		pool[t] = true
	end
	function clearUniqueVars()
		for k in pairs(pool) do
			pool[k] = nil
		end
		num = 0
	end
	function getNumUniqueVars()
		return num
	end
end


local compile

local function getTagData(tag, nsList)
	for _, ns in ipairs(unpackNamespaceList[nsList]) do
		local Tags_ns = Tags[ns]
		if Tags_ns then
			local Tags_ns_tag = Tags_ns[tag]
			if Tags_ns_tag then
				return Tags_ns_tag
			end
		end
	end
end

local function getKwargsForAST(ast, nsList, extraKwargs)
	if type(ast) ~= "table" then
		return nil, ("%s is not a tag"):format(tostring(ast))
	end
	local tag, startArgs
	if ast[1] == "tag" then
		tag = ast[2]
		startArgs = 3
	else
		tag = ast[1]
		startArgs = 2
	end
	
	local tagData = getTagData(tag, nsList)
	if not tagData then
		return nil, ("Unknown tag %s"):format(tag)
	end
	
	local arg = tagData.arg
	if not arg then
		return newList() -- no issue, but no point
	end
	
	local kwargs = newList()
	if extraKwargs then
		-- extra kwargs specified on fontstring registration, e.g. { unit = "player" }
		for k,v in pairs(extraKwargs) do
			kwargs[k] = extraKwargs
		end
	end
	
	for i = startArgs, #ast do
		local argName = arg[(i-startArgs)*3 + 1]
		local argTypes = arg[(i-startArgs)*3 + 2]
		if argTypes == "list-string" or argTypes == "list-number" then
			for j = i, #ast do
				kwargs[argName .. (j-i+1)] = ast[j]
			end
			break
		end
		if not argName then
			kwargs = del(kwargs)
			return nil, ("Too many args for %s"):format(tag)
		end
		kwargs[argName] = ast[i]
	end
	
	if ast.kwarg then
		for k,v in pairs(ast.kwarg) do
			kwargs[k] = v
		end
	end
	
	-- validate all args are met
	for i = 1, #arg, 3 do
		local argName, argType, default = arg[i], arg[i+1], arg[i+2]
		
		if not kwargs[argName] and argType ~= "list-string" and argType ~= "list-number"then
			if default == "@req" then
				kwargs = del(kwargs)
				return nil, ("Arg #%d (%s) req'd for %s"):format((i-1)/3+1, argName, tag)
			else
				kwargs[argName] = default
			end
		end
	end
	
	return kwargs
end

local interpolationHandler__data
local interpolationHandler__error
local function interpolationHandler(str)
	local data = interpolationHandler__data
	local ast, tagData, nsList, t, isOperator, afterStack, cachedTags, alreadyCompiled, kwargs, extraKwargs = unpack(data)
	local arg = tagData.arg
	local result
	
	if str == '#...' then
		local num = 1
		while kwargs["..." .. num] ~= nil do
			num = num + 1
		end
		return num-1
	end
	
	local str, strModifier = (":"):split(str, 2)
	
	for i = 1, #arg, 3 do
		local argName, argTypes, default = arg[i], arg[i+1], arg[i+2]
		if argName == str then
			local result_t = alreadyCompiled[argName]
			local result, resultTypes, rawResult
			if result_t then
				result, resultTypes, rawResult = result_t[1], result_t[2], result_t[3]
			else
				if kwargs[argName] ~= nil then
					if kwargs[argName] == extraKwargs then
						result = extraKwargs[argName][1]
						resultTypes = extraKwargs[argName][2]
						rawResult = extraKwargs[argName][1]
					else
						result, resultTypes = compile(kwargs[argName] or nil, nsList, t, cachedTags, nil, extraKwargs)
						if not result then
							interpolationHandler__error = types
							return nil
						end
						rawResult = result
					end
					
					argTypes = newSet((";"):split(argTypes))
					local types = newSet((";"):split(resultTypes))
					local unfulfilledTypes = newList()
					for k in pairs(types) do
						if not argTypes[k] then
							unfulfilledTypes[k] = true
						end
					end
					types = del(types)
					if next(unfulfilledTypes) then
						if unfulfilledTypes['nil'] then
							-- we have a possible unrequested nil
							if argTypes['string'] then
								t[#t+1] = result
								t[#t+1] = [=[ = ]=]
								if unfulfilledTypes['number'] then
									-- and a possible unrequested number
									t[#t+1] = [=[tostring(]=]
									t[#t+1] = result
									t[#t+1] = [=[ or '');]=]
								else
									t[#t+1] = [=['';]=]
								end
							elseif argTypes['number'] then
								t[#t+1] = [=[if not ]=]
								t[#t+1] = result
								t[#t+1] = [=[ then ]=]
								t[#t+1] = result
								t[#t+1] = [=[ = ]=]
								t[#t+1] = [=[0;]=]
								t[#t+1] = [=[end;]=]
							end
						elseif unfulfilledTypes['number'] then
							-- we have a possible unrequested number
							if argTypes['string'] then
								if type(result) == "string" and result:match("^arg%d+$") then
									t[#t+1] = result
									t[#t+1] = [=[ = tostring(]=]
									t[#t+1] = result
									t[#t+1] = [=[)]=]
								else
									result = ("%q"):format(tostring(result+0))
								end
							elseif argTypes['nil'] then
								if type(result) == "string" and result:match("^arg%d+$") then
									t[#t+1] = result
									t[#t+1] = [=[ = nil;]=]
								else
									result = "nil"
								end
							end
						elseif unfulfilledTypes['string'] then
							-- we have a possible unrequested string
							if argTypes['number'] then
								if type(result) == "string" and result:match("^arg%d+$") then
									t[#t+1] = result
									t[#t+1] = [=[ = tonumber(]=]
									t[#t+1] = result
									t[#t+1] = [=[)]=]
									if not argTypes['nil'] then
										t[#t+1] = [=[ or 0]=]
									end
									t[#t+1] = [=[;]=]
								else
									result = tonumber(result)
									if not argTypes['nil'] and not result then
										result = 0
									end
									result = tostring(result)
								end
							elseif argTypes['nil'] then
								if type(result) == "string" and result:match("^arg%d+$") then
									t[#t+1] = result
									t[#t+1] = [=[ = nil]=]
								else
									result = "nil"
								end
							end
						end
					end
					unfulfilledTypes = del(unfulfilledTypes)
					argTypes = del(argTypes)
				
					if type(result) == "string" and result:match("^arg%d+$") then
						afterStack[#afterStack+1] = result
					else
						result = ("(%s)"):format(result)
					end
					alreadyCompiled[argName] = newList(result, resultTypes, rawResult)
				elseif argTypes == "list-number" or argTypes == "list-string" then
					local num = 0
					local argList = newList()
					resultTypes = argTypes == "list-number" and "number" or "string"
					while true do
						num = num + 1
						local argName_num = argName .. num
						if not kwargs[argName_num] then
							break
						end
						
						local res, types = compile(kwargs[argName_num] or nil, nsList, t, cachedTags, nil, extraKwargs)
						
						if not res then
							argList = del(argList)
							interpolationHandler__error = types
							return nil
						end
						
						types = newSet((";"):split(types))
						local unfulfilledTypes = newList()
						for k in pairs(types) do
							if (k ~= "number" or argTypes ~= "list-number") and (k ~= "string" or argTypes ~= "list-string") then
								unfulfilledTypes[k] = true
							end
						end
						types = del(types)
						
						if next(unfulfilledTypes) then
							if unfulfilledTypes['nil'] then
								-- we have a possible unrequested nil
								if argTypes == "list-string" then
									if type(res) == "string" and res:match("^arg%d+$") then
										t[#t+1] = res
										t[#t+1] = [=[ = ]=]
										if unfulfilledTypes['number'] then
											-- and a possible unrequested number
											t[#t+1] = [=[tostring(]=]
											t[#t+1] = res
											t[#t+1] = [=[ or '');]=]
										else
											t[#t+1] = [=['';]=]
										end
									else
										res = ("%q"):format(tostring(tonumber(res) or ''))
									end
								else
									t[#t+1] = res
									t[#t+1] = [=[ = ]=]
									t[#t+1] = [=[0;]=]
								end
							elseif unfulfilledTypes['number'] then
								-- we have a possible unrequested number
								if argTypes == "list-string" then
									if type(res) == "string" and res:match("^arg%d+$") then
										t[#t+1] = res
										t[#t+1] = [=[ = tostring(]=]
										t[#t+1] = res
										t[#t+1] = [=[)]=]
									else
										res = ("%q"):format(tostring(res+0))
									end
								end
							elseif unfulfilledTypes['string'] then
								-- we have a possible unrequested string
								if argTypes == "list-number" then
									if type(res) == "string" and res:match("^arg%d+$") then
										t[#t+1] = res
										t[#t+1] = [=[ = tonumber(]=]
										t[#t+1] = res
										t[#t+1] = [=[)]=]
										if not argTypes['nil'] then
											t[#t+1] = [=[ or 0]=]
										end
										t[#t+1] = [=[;]=]
									else
										res = tonumber(res)
										if not argTypes['nil'] then
											res = res or 0
										end
										res = tostring(res)
									end
								end
							end
						end
						
						unfulfilledTypes = del(unfulfilledTypes)
						if type(res) == "string" and res:match("^arg%d+$") then
							afterStack[#afterStack+1] = res
							argList[#argList + 1] = res
						else
							argList[#argList + 1] = ("(%s)"):format(res)
						end
					end
					result = table.concat(argList, ", ")
					argList = del(argList)
					rawResult = result
					alreadyCompiled[argName] = newList(result, resultTypes, result)
				end
			end
			if strModifier == "type" then
				if resultTypes:find(";") then
					return "type(" .. result .. ")"
				else
					return ("%q"):format(resultTypes)
				end
			elseif strModifier == "string" then
				if resultTypes == "string" then
					return result
				elseif resultTypes == "number" then
					if tonumber(rawResult) then
						return ("(%q)"):format(tostring(0+rawResult))
					else
						return "tostring(" .. result .. ")"
					end
				elseif resultTypes == "nil" then
					return "('')"
				elseif resultTypes == "number;string" then
					return "tostring(" .. result .. ")"
				elseif resultTypes == "nil;string" then
					return "(" .. result .. " or '')"
				else--if resultTypes == "nil;number" or resultTypes == "nil;number;string" then
					return "tostring(" .. result .. " or '')"
				end
			else
				return result
			end
		end
	end
end

local function tuple_interpolationHandler()
	local result = interpolationHandler('...')
	if result and result ~= '' then
		return ", " .. result
	else
		return ''
	end
end

local operators = {
	["+"] = true,
	["-"] = true,
	["*"] = true,
	["/"] = true,
	["%"] = true,
	["^"] = true,
	["<"] = true,
	[">"] = true,
	["<="] = true,
	[">="] = true,
	["="] = true,
	["~="] = true,
	["unm"] = true,
}

function compile(ast, nsList, t, cachedTags, storeKey, extraKwargs)
	local astType = getASTType(ast)
	if astType == 'string' then
		if ast == '' then
			return compile(nil, nsList, t, cachedTags, storeKey, extraKwargs)
		else
			if storeKey then
				t[#t+1] = storeKey
				t[#t+1] = [=[ = ]=]
				t[#t+1] = ([=[%q]=]):format(ast)
				t[#t+1] = [=[;]=]
				return storeKey, "string"
			else
				return ([=[%q]=]):format(ast), "string"
			end
		end
	elseif astType == 'number' then
		if storeKey then
			t[#t+1] = storeKey
			t[#t+1] = [=[ = ]=]
			t[#t+1] = ("%.22f"):format(ast)
			t[#t+1] = [=[;]=]
			return storeKey, "number"
		else
			return ("%.22f"):format(ast), "number"
		end
	elseif astType == 'nil' then
		if storeKey then
			t[#t+1] = storeKey
			t[#t+1] = [=[ = ]=]
			t[#t+1] = "nil"
			t[#t+1] = [=[;]=]
			return storeKey, "nil"
		else
			return "nil", "nil"
		end
	elseif astType == 'tag' or operators[astType] then
		local tag = ast[astType == 'tag' and 2 or 1]
		local tagData = getTagData(tag, nsList)
		if not storeKey then
			storeKey = newUniqueVar()
		end
		if tagData then
			local caching, cachingFirst
			if astType == 'tag' and #ast == 2 and not ast.kwarg and cachedTags[tag] then
				caching = true
				cachingFirst = cachedTags[tag] == 1
				cachedTags[tag] = 2
			end
			if caching and not cachingFirst then
				t[#t+1] = [=[if cache_]=]
				t[#t+1] = tag
				t[#t+1] = [=[ ~= NIL then ]=]
				t[#t+1] = storeKey
				t[#t+1] = [=[ = cache_]=]
				t[#t+1] = tag
				t[#t+1] = [=[; else ]=]
			end
			local code = tagData.code
			local arg = tagData.arg
			-- TODO: Check for arguments
			code = code:gsub("return ", storeKey .. " = ")
			local afterStack = newList()
			local kwargs, errMessage = getKwargsForAST(ast, nsList, extraKwargs)
			if not kwargs then
				afterStack = del(afterStack)
				return nil, errMessage
			end
			local alreadyCompiled = newList()
			local data = newList(ast, tagData, nsList, t, astType ~= 'tag', afterStack, cachedTags, alreadyCompiled, kwargs, extraKwargs)
			local prev_interpolationHandler__data = interpolationHandler__data
			interpolationHandler__data = data
			code = code:gsub(",%s*${%.%.%.}", tuple_interpolationHandler)
			interpolationHandler__data = data
			code = code:gsub("${(.-)}", interpolationHandler)
			interpolationHandler__data = prev_interpolationHandler__data
			data = del(data)
			for k, v in pairs(alreadyCompiled) do
				alreadyCompiled[k] = del(v)
			end
			alreadyCompiled = del(alreadyCompiled)
			kwargs = del(kwargs)
			if interpolationHandler__error then
				afterStack = del(afterStack)
				local err = interpolationHandler__error
				interpolationHandler__error = nil
				return nil, err
			end
			t[#t+1] = code
			t[#t+1] = [=[;]=]
			for i,v in ipairs(afterStack) do
				t[#t+1] = v
				delUniqueVar(v)
				t[#t+1] = [=[ = nil;]=]
			end
			afterStack = del(afterStack)
			if caching then
				t[#t+1] = [=[cache_]=]
				t[#t+1] = tag
				t[#t+1] = [=[ = ]=]
				t[#t+1] = storeKey
				t[#t+1] = [=[;]=]
				if not cachingFirst then
					t[#t+1] = [=[end;]=]
				end
			end
			return storeKey, tagData.ret
		else
			t[#t+1] = storeKey
			t[#t+1] = [=[ = ]=]
			t[#t+1] = ("%q"):format(("Unknown tag %s"):format(tag))
			t[#t+1] = [=[;]=]
			return storeKey, "string"
		end
	elseif astType == ' ' then
		local t_num = #t
		local args = newList()
		local argTypes = newList()
		for i = 2, #ast do
			local t_num = #t
			local arg, err = compile(ast[i], nsList, t, cachedTags, nil, extraKwargs)
			if not arg then
				args = del(args)
				argTypes = del(argTypes)
				return arg, err
			end
			args[#args+1] = arg
			argTypes[#argTypes+1] = err
			if #t ~= t_num then
				table.insert(t, t_num+1, [=[do ]=])
				t[#t+1] = [=[end;]=]
			end
		end
		if not storeKey then
			storeKey = newUniqueVar()
		end
		t[#t+1] = storeKey
		t[#t+1] = [=[ = ]=]
		local finalTypes = newList()
		for i,v in ipairs(args) do
			if i > 1 then
				t[#t+1] = [=[ .. ]=]
			end
			local types = argTypes[i]
			types = newSet((';'):split(types))
			if types['nil'] and (types['string'] or types['number']) then
				t[#t+1] = "("
				t[#t+1] = v
				t[#t+1] = " or '')"
			elseif types['nil'] then
				-- just nil
				t[#t+1] = "''"
			else
				-- non-nil
				t[#t+1] = v
			end
			if types['nil'] then
				if not next(finalTypes) then
					finalTypes['nil'] = true
				end
			else
				finalTypes['nil'] = nil
			end
			if types['number'] and not finalTypes['string'] then
				if finalTypes['number'] then
					finalTypes['string'] = true
				end
				finalTypes['number'] = true
			end
			if types['string'] then
				if not types['number'] then
					finalTypes['number'] = nil
				end
				finalTypes['string'] = true
			end
			types = del(types)
		end
		t[#t+1] = [=[;]=]
		if finalTypes['number'] then
			t[#t+1] = [=[if tonumber(]=]
			t[#t+1] = storeKey
			t[#t+1] = [=[) then ]=]
			t[#t+1] = storeKey
			t[#t+1] = [=[ = ]=]
			t[#t+1] = storeKey
			t[#t+1] = [=[+0;]=]
		end
		if finalTypes['nil'] then
			if finalTypes['number'] then
				t[#t+1] = [=[elseif ]=]
			else
				t[#t+1] = [=[if ]=]
			end
			t[#t+1] = storeKey
			t[#t+1] = [=[ == '' then ]=]
			t[#t+1] = storeKey
			t[#t+1] = [=[ = nil;]=]
			t[#t+1] = [=[end;]=]
		else
			if finalTypes['number'] then
				t[#t+1] = [=[end;]=]
			end
		end
		for i,v in ipairs(args) do
			if type(v) == "string" and v:match("^arg%d+$") then
				t[#t+1] = v
				delUniqueVar(v)
				t[#t+1] = [=[ = nil;]=]
			end
		end
		args = del(args)
		argTypes = del(argTypes)
		local s = joinSet(finalTypes, ';')
		finalTypes = del(finalTypes)
		return storeKey, s
	elseif astType == 'and' or astType == 'or' then
		if not storeKey then
			storeKey = newUniqueVar()
		end
		local t_num = #t
		t[#t+1] = [=[do ]=]
		local arg, firstResults = compile(ast[2], nsList, t, cachedTags, storeKey, extraKwargs)
		if not arg then
			return nil, firstResults
		end
		firstResults = newSet((";"):split(firstResults))
		local totalResults = newList()
		t[#t+1] = [=[end;]=]
		if firstResults["nil"] then
			t[#t+1] = [=[if ]=]
			if astType == 'or' then
				t[#t+1] = [=[not ]=]
			end
			t[#t+1] = storeKey
			t[#t+1] = [=[ then ]=]
			local arg, secondResults = compile(ast[3], nsList, t, cachedTags, storeKey, extraKwargs)
			if not arg then
				firstResults = del(firstResults)
				totalResults = del(totalResults)
				return nil, secondResults
			end
			secondResults = newSet((";"):split(secondResults))
			t[#t+1] = [=[end;]=]
			for k in pairs(firstResults) do
				if k ~= "nil" then
					totalResults[k] = true
				end
			end
			for k in pairs(secondResults) do
				totalResults[k] = true
			end
			secondResults = del(secondResults)
		elseif astType == 'and' then
			for i = t_num, #t do
				t[i] = nil
			end
			local arg, secondResults = compile(ast[3], nsList, t, cachedTags, storeKey, extraKwargs)
			if not arg then
				firstResults = del(firstResults)
				totalResults = del(totalResults)
				return nil, secondResults
			end
			secondResults = newSet((";"):split(secondResults))
			for k in pairs(totalResults) do
				totalResults[k] = nil
			end
			for k in pairs(secondResults) do
				totalResults[k] = true
			end
			secondResults = del(secondResults)
		else
			for k in pairs(firstResults) do
				totalResults[k] = true
			end
		end
		firstResults = del(firstResults)
		local s = joinSet(totalResults, ';')
		totalResults = del(totalResults)
		return storeKey, s
	elseif astType == 'if' then
		if not storeKey then
			storeKey = newUniqueVar()
		end
		local t_num = #t
		t[#t+1] = [=[do ]=]
		local storeKey, condResults = compile(ast[2], nsList, t, cachedTags, storeKey, extraKwargs)
		if not storeKey then
			return nil, condResults
		end
		condResults = newSet((';'):split(condResults))
		t[#t+1] = [=[end;]=]
		if condResults["nil"] and (condResults["string"] or condResults["number"]) then
			condResults = del(condResults)
			t[#t+1] = [=[if ]=]
			t[#t+1] = storeKey
			t[#t+1] = [=[ then ]=]
			local arg, firstResults = compile(ast[3], nsList, t, cachedTags, storeKey, extraKwargs)
			if not arg then
				return nil, firstResults
			end
			local totalResults = newSet((";"):split(firstResults))
			t[#t+1] = [=[ else ]=]
			if ast[4] then
				local arg, secondResults = compile(ast[4], nsList, t, cachedTags, storeKey, extraKwargs)
				if not arg then
					totalResults = del(totalResults)
					return nil, secondResults
				end
				secondResults = newSet((";"):split(secondResults))
				for k in pairs(secondResults) do
					totalResults[k] = true
				end
				secondResults = del(secondResults)
			else
				totalResults["nil"] = true
				t[#t+1] = storeKey
				t[#t+1] = [=[ = nil;]=]
			end
			t[#t+1] = [=[end;]=]
			
			local s = joinSet(totalResults, ';')
			totalResults = del(totalResults)
			return storeKey, s
		elseif condResults["nil"] then
			-- just nil
			condResults = del(condResults)
			for i = t_num, #t do
				t[i] = nil
			end
			if type(cond) == "string" and cond:match("^arg%d+$") then
				delUniqueVar(cond)
			end
			local arg, totalResults = compile(ast[4], nsList, t, cachedTags, storeKey, extraKwargs)
			if not arg then
				return nil, totalResults
			end
			return storeKey, totalResults
		else
			-- non-nil
			condResults = del(condResults)
			for i = t_num, #t do
				t[i] = nil
			end
			if type(cond) == "string" and cond:match("^arg%d+$") then
				delUniqueVar(cond)
			end
			local arg, totalResults = compile(ast[3], nsList, t, cachedTags, storeKey, extraKwargs)
			if not arg then
				return nil, totalResults
			end
			return storeKey, totalResults
		end
	elseif astType == 'not' then
		local t_num = #t
		local s, results = compile(ast[2], nsList, t, cachedTags, storeKey, extraKwargs)
		if not s then
			return nil, results
		end
		results = newSet((";"):split(results))
		if results["nil"] and (results["string"] or results["number"]) then
			results = del(results)
			storeKey = s
			
			t[#t+1] = storeKey
			t[#t+1] = [=[ = ]=]
			t[#t+1] = storeKey
			t[#t+1] = [=[ and ]=]
			t[#t+1] = ("%q"):format(L["True"])
			t[#t+1] = [=[ or nil;]=]
			return storeKey, "nil;string"
		elseif results["nil"] then	
			-- just nil
			results = del(results)
			
			for i = t_num, #t do
				t[i] = nil
			end
			if storeKey then
				t[#t+1] = storeKey
				t[#t+1] = [=[ = ]=]
				t[#t+1] = ("%q"):format(L["True"])
				t[#t+1] = [=[;]=]
				return storeKey, "string"
			else
				return ("%q"):format(L["True"]), "string"
			end
		else
			-- non-nil
			results = del(results)
			
			for i = t_num, #t do
				t[i] = nil
			end
			if storeKey then
				t[#t+1] = storeKey
				t[#t+1] = [=[ = nil;]=]
				return storeKey, "nil"
			else
				return "nil", "nil"
			end
		end
	end
	error(("Unknown astType: %q"):format(tostring(astType)))
end

function DogTag:CreateFunctionFromCode(code, ...)
	if type(code) ~= "string" then
		error(("Bad argument #2 to `CreateFunctionFromCode'. Expected %q, got %q."):format("string", type(code)), 2)
	end
	local notDebug = (...) == true
	local kwargsKey = kwargsToKey()
	local nsList
	if notDebug then
		kwargsKey = select(2, ...)
		nsList = getNamespaceList(select(3, ...))
	else
		local n = select('#', ...)
		local kwargs = n > 0 and select(n, ...)
		if type(kwargs) == "table" then
			kwargsKey = kwargsToKey(kwargs)
			n = n - 1
		end
		for i = 1, n do
			if type(select(i, ...)) ~= "string" then
				error(("Bad argument #%d to `CreateFunctionFromCode'. Expected %q, got %q"):format(i+2, "string", type(select(i, ...))), 2)
			end
		end
		nsList = getNamespaceList(select2(1, n, ...))
	end
	
	local ast = DogTag.parse(code)
	ast = DogTag.standardize(ast)
	correctASTCasing(ast)
	
	local t = newList()
	t[#t+1] = ([=[local DogTag = _G.LibStub(%q);]=]):format(MAJOR_VERSION)
	t[#t+1] = [=[local colors = DogTag.__colors;]=]
	t[#t+1] = [=[local NIL = DogTag.__NIL;]=]
	t[#t+1] = [=[local cleanText = DogTag.__cleanText;]=]
	
	local globals = figureGlobals(ast, nsList, nil)
	globals['table.concat'] = true
	globals['tonumber'] = true
	globals['type'] = true
	for global in pairs(globals) do
		if global:find("^[A-Za-z0-9%-]+%-%d+%.%d+$") then
			if Rock then
				Rock(global, false, true) -- try to lod
			end
			if AceLibrary then
				AceLibrary:HasInstance(global) -- try to load
			end
			if LibStub(global, true) then -- catches Rock and AceLibrary libs as well
				t[#t+1] = [=[local ]=]
				t[#t+1] = global:gsub("%-.-$", "")
				if not global:find("^Lib") then
					t[#t+1] = [=[Lib]=]
				end
				t[#t+1] = [=[ = LibStub("]=]
				t[#t+1] = k
				t[#t+1] = [=[");]=]
			end
		else
			t[#t+1] = [=[local ]=]
			t[#t+1] = global:gsub("%.", "_")
			t[#t+1] = [=[ = ]=]
			t[#t+1] = global
			t[#t+1] = [=[;]=]
		end
	end
	globals = del(globals)
	t[#t+1] = [=[return function(kwargs) ]=]
	t[#t+1] = [=[local value, opacity;]=]
	
	local cachedTags = figureCachedTags(ast)
	for k in pairs(cachedTags) do
		t[#t+1] = [=[local cache_]=]
		t[#t+1] = k
		t[#t+1] = [=[ = NIL;]=]
	end
	
	local u = newList()
	local extraKwargs = newList()
	for k, v in pairs(kwargsKey) do
		local arg = newUniqueVar()
		u[#u+1] = arg
		u[#u+1] = [=[ = kwargs["]=]
		u[#u+1] = k
		u[#u+1] = [=["];]=]
		extraKwargs[k] = newList(arg, v)
	end
	local ret, types = compile(ast, nsList, u, cachedTags, 'value', extraKwargs)
	for k, v in pairs(extraKwargs) do
		extraKwargs[k] = del(v)
	end
	extraKwargs = del(extraKwargs)
	ast = deepDel(ast)
	if not ret then
		for i = 1, #u do
			u[i] = nil
		end
		u[#u+1] = [=[value = ]=]
		u[#u+1] = ("%q"):format(types)
		u[#u+1] = [=[;]=]
	end
	for i = 1, getNumUniqueVars() do
		t[#t+1] = [=[local arg]=]
		t[#t+1] = i
		t[#t+1] = [=[;]=]
	end
	for _,v in ipairs(u) do
		t[#t+1] = v
	end
	u = del(u)
	clearUniqueVars()
	
	types = newSet((";"):split(types))
	if types["string"] then
		t[#t+1] = [=[if value == '' then value = nil; elseif tonumber(value) then value = value+0; end;]=]
	end
	types = del(types)
	
	t[#t+1] = [=[return value, opacity;]=]
	
	t[#t+1] = [=[end]=]
	
	cachedTags = del(cachedTags)
	local s = table.concat(t)
	t = del(t)
	if not notDebug then
		s = enumLines(s) -- avoid interning the new string if not debugging
	end
	return s
end

function DogTag:Evaluate(code, ...)
	if type(code) ~= "string" then
		error(("Bad argument #2 to `Evaluate'. Expected %q, got %q"):format("string", type(code)), 2)
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
			error(("Bad argument #%d to `Evaluate'. Expected %q, got %q"):format(i+2, "string", type(select(i, ...))), 2)
		end
	end
	local nsList = getNamespaceList(select2(1, n, ...))
	local kwargsKey = kwargsToKey(kwargs)
	
	DogTag.__isMouseOver = false
	
	local func = codeToFunction[nsList][kwargsKey][code]
	
	local madeKwargs = not kwargs
	if madeKwargs then
		kwargs = newList()
	end
	local success, text, opacity = pcall(func, kwargs)
	if madeKwargs then
		kwargs = del(kwargs)
	end
	if success then
		if opacity then
			if opacity > 1 then
				opacity = 1
			elseif opacity < 0 then
				opacity = 0
			end
		end
		return text, opacity
	else
		geterrorhandler()(("%s.%d: Error with code %q%s. %s"):format(MAJOR_VERSION, MINOR_VERSION, code, nsList == "Base" and "" or " (" .. nsList .. ")", text))
	end
end

end