local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_MINOR_VERSION then
	_G.DogTag_MINOR_VERSION = MINOR_VERSION
end

DogTag_funcs[#DogTag_funcs+1] = function()

local L = DogTag.L

DogTag:AddTag("Base", "+", {
	code = [=[return ${left} + ${right}]=],
	arg = {
		'left', 'number', "@req",
		'right', 'number', "@req",
	},
	ret = "number",
	doc = L["Add left and right together"],
	example = '[1 + 2] => "3"',
	category = L["Operators"]
})

DogTag:AddTag("Base", "-", {
	code = [=[return ${left} - ${right}]=],
	arg = {
		'left', 'number', "@req",
		'right', 'number', "@req",
	},
	ret = "number",
	doc = L["Subtract right from left"],
	example = '[1 - 2] => "-1"',
	category = L["Operators"]
})

DogTag:AddTag("Base", "*", {
	code = [=[return ${left} * ${right}]=],
	arg = {
		'left', 'number', "@req",
		'right', 'number', "@req",
	},
	ret = "number",
	doc = L["Multiple left and right together"],
	example = '[1 * 2] => "2"',
	category = L["Operators"]
})

DogTag:AddTag("Base", "/", {
	code = [=[if ${left} == 0 then
		return 0
	else
		return ${left} / ${right}
	end]=],
	arg = {
		'left', 'number', "@req",
		'right', 'number', "@req",
	},
	ret = "number",
	doc = L["Divide left by right"],
	example = '[1 / 2] => "0.5"',
	category = L["Operators"]
})

DogTag:AddTag("Base", "%", {
	code = [=[return ${left} % ${right}]=],
	arg = {
		'left', 'number', "@req",
		'right', 'number', "@req",
	},
	ret = "number",
	doc = L["Take the modulus of left and right"],
	example = '[5 % 3] => "2"',
	category = L["Operators"]
})

DogTag:AddTag("Base", "^", {
	code = [=[return ${left} ^ ${right}]=],
	arg = {
		'left', 'number', "@req",
		'right', 'number', "@req",
	},
	ret = "number",
	doc = L["Raise left to the right power"],
	example = '[5 ^ 3] => "125"',
	category = L["Operators"]
})

DogTag:AddTag("Base", "<", {
	code = [=[if ${left:type} == ${right:type} then
		if ${left} < ${right} then
			return ${left}
		else
			return nil
		end
	else
		if ${left:string} < ${right:string} then
			return ${left}
		else
			return nil
		end
	end]=],
	arg = {
		'left', 'number;string', "@req",
		'right', 'number;string', "@req",
	},
	ret = "number;string;nil",
	doc = L["Check if left is less than right, if so, return left"],
	example = '[5 < 3] => ""; [3 < 5] => "3"; [3 < 3] => ""',
	category = L["Operators"]
})

DogTag:AddTag("Base", ">", {
	code = [=[if ${left:type} == ${right:type} then
		if ${left} > ${right} then
			return ${left}
		else
			return nil
		end
	else
		if ${left:string} > ${right:string} then
			return ${left}
		else
			return nil
		end
	end]=],
	arg = {
		'left', 'number;string', "@req",
		'right', 'number;string', "@req",
	},
	ret = "number;string;nil",
	doc = L["Check if left is greater than right, if so, return left"],
	example = '[5 > 3] => "5"; [3 > 5] => ""; [3 > 3] => ""',
	category = L["Operators"]
})

DogTag:AddTag("Base", "<=", {
	code = [=[if ${left:type} == ${right:type} then
		if ${left} <= ${right} then
			return ${left}
		else
			return nil
		end
	else
		if ${left:string} <= ${right:string} then
			return ${left}
		else
			return nil
		end
	end]=],
	arg = {
		'left', 'number;string', "@req",
		'right', 'number;string', "@req",
	},
	ret = "number;string;nil",
	doc = L["Check if left is less than or equal to right, if so, return left"],
	example = '[5 <= 3] => ""; [3 <= 5] => "3"; [3 <= 3] => "3"',
	category = L["Operators"]
})

DogTag:AddTag("Base", ">=", {
	code = [=[if ${left:type} == ${right:type} then
		if ${left} >= ${right} then
			return ${left}
		else
			return nil
		end
	else
		if ${left:string} >= ${right:string} then
			return ${left}
		else
			return nil
		end
	end]=],
	arg = {
		'left', 'number;string', "@req",
		'right', 'number;string', "@req",
	},
	ret = "number;string;nil",
	doc = L["Check if left is greater than or equal to right, if so, return left"],
	example = '[5 >= 3] => "5"; [3 >= 5] => ""; [3 >= 3] => "3"',
	category = L["Operators"]
})

DogTag:AddTag("Base", "=", {
	code = [=[if ${left} == ${right} or ${left:string} == ${right:string} then
		return ${left}
	else
		return nil
	end]=],
	arg = {
		'left', 'number;string', "@req",
		'right', 'nil;number;string', "@req",
	},
	ret = "number;string;nil",
	doc = L["Check if left is equal to right, if so, return left"],
	example = '[1 = 2] => ""; [1 = 1] => "1"',
	category = L["Operators"]
})

DogTag:AddTag("Base", "~=", {
	code = [=[if ${left:string} ~= ${right:string} then
		return ${left}
	else
		return nil
	end]=],
	arg = {
		'left', 'number;string', "@req",
		'right', 'nil;number;string', "@req",
	},
	ret = "number;string;nil",
	doc = L["Check if left is equal to right, if so, return left"],
	example = '[1 ~= 2] => "1"; [1 ~= 1] => ""',
	category = L["Operators"]
})

DogTag:AddTag("Base", "unm", {
	code = [=[return -${number}]=],
	arg = {
		'number', 'number', "@req",
	},
	ret = "number",
	doc = L["Return the negative of number"],
	example = '[-1] => "-1"; [-(-1)] => "1"',
	category = L["Operators"]
})

end
