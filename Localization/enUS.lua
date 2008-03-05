local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

_G.DogTag_MINOR_VERSION = MINOR_VERSION

_G.DogTag_funcs = {}

DogTag_funcs[#DogTag_funcs+1] = function()

_G.DogTag__L = {
	["DogTag Help"] = "DogTag Help",
	
	-- races
	["Blood Elf"] = "Blood Elf",
	["Draenei"] = "Draenei",
	["Dwarf"] = "Dwarf",
	["Gnome"] = "Gnome",
	["Human"] = "Human",
	["Night Elf"] = "Night Elf",
	["Orc"] = "Orc",
	["Tauren"] = "Tauren",
	["Troll"] = "Troll",
	["Undead"] = "Undead",

	-- short races
	["Blood Elf_short"] = "BE",
	["Draenei_short"] = "Dr",
	["Dwarf_short"] = "Dw",
	["Gnome_short"] = "Gn",
	["Human_short"] = "Hu",
	["Night Elf_short"] = "NE",
	["Orc_short"] = "Or",
	["Tauren_short"] = "Ta",
	["Troll_short"] = "Tr",
	["Undead_short"] = "Ud",

	-- classes
	["Warrior"] = "Warrior",
	["Priest"] = "Priest",
	["Mage"] = "Mage",
	["Shaman"] = "Shaman",
	["Paladin"] = "Paladin",
	["Warlock"] = "Warlock",
	["Druid"] = "Druid",
	["Rogue"] = "Rogue",
	["Hunter"] = "Hunter",

	-- short classes
	["Warrior_short"] = "Wr",
	["Priest_short"] = "Pr",
	["Mage_short"] = "Ma",
	["Shaman_short"] = "Sh",
	["Paladin_short"] = "Pa",
	["Warlock_short"] = "Wl",
	["Druid_short"] = "Dr",
	["Rogue_short"] = "Ro",
	["Hunter_short"] = "Hu",

	["Player"] = PLAYER,
	["Target"] = TARGET,
	["Focus-target"] = FOCUS,
	["Mouse-over"] = "Mouse-over",
	["%s's pet"] = "%s's pet",
	["%s's target"] = "%s's target",
	["Party member #%d"] = "Party member #%d",
	["Raid member #%d"] = "Raid member #%d",

	-- classifications
	["Rare"] = ITEM_QUALITY3_DESC,
	["Rare-Elite"] = ITEM_QUALITY3_DESC and ELITE and ITEM_QUALITY3_DESC .. "-" .. ELITE,
	["Elite"] = ELITE,
	["Boss"] = BOSS,
	-- short classifications
	["Rare_short"] = "r",
	["Rare-Elite_short"] = "r+",
	["Elite_short"] = "+",
	["Boss_short"] = "b",

	["Feigned Death"] = "Feigned Death",
	["Stealthed"] = "Stealthed",
	["Soulstoned"] = "Soulstoned",

	["Dead"] = DEAD,
	["Ghost"] = "Ghost",
	["Offline"] = PLAYER_OFFLINE,
	["Online"] = "Online",
	["Combat"] = "Combat",
	["Resting"] = "Resting",
	["Tapped"] = "Tapped",
	["AFK"] = "AFK",
	["DND"] = "DND",

	["True"] = "True",

	["Rage"] = RAGE,
	["Focus"] = FOCUS,
	["Energy"] = ENERGY,
	["Mana"] = MANA,

	["PvP"] = PVP,
	["FFA"] = "FFA",

	-- genders
	["Male"] = MALE,
	["Female"] = FEMALE,

	-- forms
	["Bear"] = "Bear",
	["Cat"] = "Cat",
	["Moonkin"] = "Moonkin",
	["Aquatic"] = "Aquatic",
	["Flight"] = "Flight",
	["Travel"] = "Travel",
	["Tree"] = "Tree",

	["Bear_short"] = "Be",
	["Cat_short"] = "Ca",
	["Moonkin_short"] = "Mk",
	["Aquatic_short"] = "Aq",
	["Flight_short"] = "Fl",
	["Travel_short"] = "Tv",
	["Tree_short"] = "Tr",

	-- shortgenders
	["Male_short"] = "m",
	["Female_short"] = "f",

	["Leader"] = "Leader",

	-- spell trees
	["Hybrid"] = "Hybrid", -- for all 3 trees
	["Druid_Tree_1"] = "Balance",
	["Druid_Tree_2"] = "Feral Combat",
	["Druid_Tree_3"] = "Restoration",
	["Hunter_Tree_1"] = "Beast Mastery",
	["Hunter_Tree_2"] = "Marksmanship",
	["Hunter_Tree_3"] = "Survival",
	["Mage_Tree_1"] = "Arcane",
	["Mage_Tree_2"] = "Fire",
	["Mage_Tree_3"] = "Frost",
	["Paladin_Tree_1"] = "Holy",
	["Paladin_Tree_2"] = "Protection",
	["Paladin_Tree_3"] = "Retribution",
	["Priest_Tree_1"] = "Discipline",
	["Priest_Tree_2"] = "Holy",
	["Priest_Tree_3"] = "Shadow",
	["Rogue_Tree_1"] = "Assassination",
	["Rogue_Tree_2"] = "Combat",
	["Rogue_Tree_3"] = "Subtlety",
	["Shaman_Tree_1"] = "Elemental",
	["Shaman_Tree_2"] = "Enhancement",
	["Shaman_Tree_3"] = "Restoration",
	["Warrior_Tree_1"] = "Arms",
	["Warrior_Tree_2"] = "Fury",
	["Warrior_Tree_3"] = "Protection",
	["Warlock_Tree_1"] = "Affliction",
	["Warlock_Tree_2"] = "Demonology",
	["Warlock_Tree_3"] = "Destruction",
}
for k,v in pairs(_G.DogTag__L) do
	if type(v) ~= "string" then -- some evil addon messed it up
		_G.DogTag__L[k] = k
	end
end
setmetatable(_G.DogTag__L, {__index = function(self, key)
--	local _, ret = pcall(error, ("Error indexing L[%q]"):format(tostring(key)), 2)
--	geterrorhandler()(ret)
	self[key] = key
	return key
end})

end