local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_MINOR_VERSION then
	_G.DogTag_MINOR_VERSION = MINOR_VERSION
end

DogTag_funcs[#DogTag_funcs+1] = function(DogTag)

local L = DogTag.L

DogTag:AddTag("Base", "Alt", {
	code = [[return IsAltKeyDown()]],
	ret = "boolean",
	events = "MODIFIER_STATE_CHANGED#ALT;MODIFIER_STATE_CHANGED#LALT;MODIFIER_STATE_CHANGED#RALT",
	globals = "IsAltKeyDown",
	doc = L["Return True if the Alt key is held down"],
	example = ('[Alt] => %q; [Alt] => ""'):format(L["True"]),
	category = L["Miscellaneous"]
})

DogTag:AddTag("Base", "Shift", {
	code = [[return IsShiftKeyDown()]],
	ret = "boolean",
	events = "MODIFIER_STATE_CHANGED#SHIFT;MODIFIER_STATE_CHANGED#LSHIFT;MODIFIER_STATE_CHANGED#RSHIFT",
	globals = "IsShiftKeyDown",
	doc = L["Return True if the Shift key is held down"],
	example = ('[Shift] => %q; [Shift] => ""'):format(L["True"]),
	category = L["Miscellaneous"]
})

DogTag:AddTag("Base", "Ctrl", {
	code = [[return IsControlKeyDown()]],
	ret = "boolean",
	events = "MODIFIER_STATE_CHANGED#CTRL;MODIFIER_STATE_CHANGED#LCTRL;MODIFIER_STATE_CHANGED#RCTRL",
	globals = "IsControlKeyDown",
	doc = L["Return True if the Ctrl key is held down"],
	example = ('[Ctrl] => %q; [Ctrl] => ""'):format(L["True"]),
	category = L["Miscellaneous"]
})

DogTag:AddTag("Base", "CurrentTime", {
	code = [[return GetTime()]],
	ret = "number",
	events = "FastUpdate",
	globals = "GetTime",
	doc = L["Return the current time in seconds, specified by WoW's internal format"],
	example = ('[CurrentTime] => "%s"'):format(GetTime()),
	category = L["Miscellaneous"]
})

DogTag:AddTag("Base", "Alpha", {
	code = [[opacity = ${number}
	return nil]],
	arg = {
		'number', 'number', "@req"
	},
	ret = "nil",
	doc = L["Set the transparency of the FontString according to argument"],
	example = '[Alpha(1)] => "Bright"; [Alpha(0)] => "Dim"',
	category = L["Miscellaneous"]
})

DogTag:AddTag("Base", "IsMouseOver", {
	code = [[return DogTag.__isMouseOver]],
	ret = "boolean",
	events = "Mouseover",
	doc = L["Return True if currently mousing over the Frame the FontString is harbored in"],
	example = ('[IsMouseOver] => %q; [IsMouseOver] => ""'):format(L["True"]),
	category = L["Miscellaneous"]
})

DogTag:AddTag("Base", "Color", {
	code = [=[local value, color, r, g, b
		if ${value} and (${red:type} == "nil" or (${red:type} == "number" and ${blue:type} == "nil")) then
			-- tag
			if ${value:type} == "string" then
				color = ${value}
			else
				r, g, b = ${value}, ${red}, ${green}
			end
		else
			-- modifier
			value = ${value} and ${value:string}
			if ${red:type} == "string" then
				color = ${red}
			else
				r, g, b = ${red}, ${green}, ${blue}
			end
		end
		
		if r then
			if r < 0 then
				r = 0
			elseif r > 1 then
				r = 1
			end
			if g < 0 then
				g = 0
			elseif g > 1 then
				g = 1
			end
			if b < 0 then
				b = 0
			elseif b > 1 then
				b = 1
			end
			if value then
				return ("|cff%02x%02x%02x%s|r"):format(r*255, g*255, b*255, value)
			else
				return ("|cff%02x%02x%02x"):format(r*255, g*255, b*255)
			end
		elseif color then
			if not color:match("^%x%x%x%x%x%x$") then
				color = "ffffff"
			end
			if value then
				return "|cff" .. color .. value .. "|r"
			else
				return "|cff" .. color
			end
		else
			return "|r"
		end
	]=],
	arg = {
		'value', 'string;number;undef', '@undef',
		'red', 'string;number;nil', false,
		'green', 'number;nil', false,
		'blue', 'number;nil', false,
	},
	ret = "string",
	doc = L["Return the color or wrap value with the rrggbb color of argument"],
	example = '["Hello":Color("00ff00")] => "|cff00ff00Hello|r"; ["Hello":Color(0, 1, 0)] => "|cff00ff00Hello|r"',
	category = L["Miscellaneous"]
})

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
	DogTag:AddTag("Base", name, {
		alias = ([=[Color(value, %q)]=]):format(color),
		arg = {
			'value', 'string;undef', "@undef",
		},
		doc = L["Return the color or wrap value with %s color"]:format(name),
		example = ('["Hello":%s] => "|cff%sHello|r"; [%s "Hello"] => "|cff%sHello"'):format(name, color, name, color),
		category = L["Miscellaneous"]
	})
end

DogTag:AddTag("Base", "IsIn", {
	code = [=[local good = false
	for i = 1, ${#...} do
		if ${value} == select(i, ${...}) then
			good = true
			break
		end
	end
	return good and ${value} or nil]=],
	arg = {
		'value', 'number;string', "@req",
		'...', 'list-number;string;nil', "@req",
	},
	ret = "nil;number;string",
	doc = L["Return value if value is within ..."],
	example = '[1:IsIn(1, 2, 3)] => "1"; ["Alpha":IsIn("Bravo", "Charlie")] => ""',
	category = L["Miscellaneous"]
})

DogTag:AddTag("Base", "Hide", {
	alias = [=[not IsIn(value, ...)]=],
	arg = {
		'value', 'number;string', "@req",
		'...', 'list-number;string;nil', "@req",
	},
	doc = L["Hide value if value is within ..."],
	example = '[1:Hide(1, 2, 3)] => ""; ["Alpha":Hide("Bravo", "Charlie")] => "Alpha"',
	category = L["Miscellaneous"]
})

DogTag:AddTag("Base", "Contains", {
	code = [=[if ${left}:match(${right}) then
		return ${left}
	else
		return nil
	end]=],
	arg = {
		'left', 'string', '@req',
		'right', 'string', '@req',
	},
	ret = "string;nil",
	doc = L["Return left if left contains right"],
	example = '["Hello":Contains("There")] => ""; ["Hello"]:Contains("ello") => "Hello"',
	category = L["Miscellaneous"]
})

end