local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

_G.DogTag_MINOR_VERSION = MINOR_VERSION

if GetLocale() == "zhCN" then

DogTag_funcs[#DogTag_funcs+1] = function(DogTag)
	local L = DogTag.L

	L["DogTag Help"] = "DogTag帮助"
	L["True"] = "真"
end

end