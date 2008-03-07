local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

_G.DogTag_MINOR_VERSION = MINOR_VERSION

DogTag_funcs[#DogTag_funcs+1] = function()

if GetLocale() == "koKR" then
	local L = _G.DogTag__L

	L["DogTag Help"] = "DogTag帮助"
	-- races
	L["Blood Elf"] = "血精灵"
	L["Draenei"] = "德莱尼"
	L["Dwarf"] = "矮人"
	L["Gnome"] = "侏儒"
	L["Human"] = "人类"
	L["Night Elf"] = "暗夜精灵"
	L["Orc"] = "兽人"
	L["Tauren"] = "牛头人"
	L["Troll"] = "巨魔"
	L["Undead"] = "亡灵"

	-- short races
	L["Blood Elf_short"] = "血"
	L["Draenei_short"] = "德"
	L["Dwarf_short"] = "矮"
	L["Gnome_short"] = "侏"
	L["Human_short"] = "人"
	L["Night Elf_short"] = "暗"
	L["Orc_short"] = "兽"
	L["Tauren_short"] = "牛"
	L["Troll_short"] = "巨"
	L["Undead_short"] = "亡"

	-- classes
	L["Warrior"] = "战士"
	L["Priest"] = "牧师"
	L["Mage"] = "法师"
	L["Shaman"] = "萨满祭司"
	L["Paladin"] = "圣骑士"
	L["Warlock"] = "术士"
	L["Druid"] = "德鲁伊"
	L["Rogue"] = "潜行者"
	L["Hunter"] = "猎人"

	-- short classes
	L["Warrior_short"] = "战"
	L["Priest_short"] = "牧"
	L["Mage_short"] = "法"
	L["Shaman_short"] = "萨"
	L["Paladin_short"] = "圣"
	L["Warlock_short"] = "术"
	L["Druid_short"] = "德"
	L["Rogue_short"] = "贼"
	L["Hunter_short"] = "猎"

--使用wow自身local
	L["Player"] = PLAYER
	L["Target"] = TARGET
	L["Focus-target"] = FOCUS
	L["Mouse-over"] = "鼠标目标"
	L["%s's pet"] = "%s的宠物"
	L["%s's target"] = "%s的目标"
	L["Party member #%d"] = "队伍成员#%d"
	L["Raid member #%d"] = "团队成员#%d"

	-- classifications
	L["Rare"] = "稀有"
	L["Rare-Elite"] = "稀有" .. "-" .. ELITE
	L["Elite"] = "精英"
	L["Boss"] = BOSS
	-- short classifications
	L["Rare_short"] = "稀"
	L["Rare-Elite_short"] = "稀+"
	L["Elite_short"] = "+"
	L["Boss_short"] = "首"

	L["Feigned Death"] = "假死"
	L["Stealthed"] = "潜行"
	L["Soulstoned"] = "灵魂已保存"

	L["Dead"] = "死亡"
	L["Ghost"] = "鬼魂"
	L["Offline"] = "离线"
	L["Online"] = "在线"
	L["Combat"] = "战斗"
	L["Resting"] = "休息"
	L["Tapped"] = "已被攻击"
	L["AFK"] = "暂离"
	L["DND"] = "勿扰"

	L["True"] = "真"

	L["Rage"] = "怒气值"
	L["Focus"] = "集中值"
	L["Energy"] = "能量值"
	L["Mana"] = "魔法值"

	L["PvP"] = PVP
	L["FFA"] = "FFA"

	-- genders
	L["Male"] = "男"
	L["Female"] = "女"

	-- forms
	L["Bear"] = "熊"
	L["Cat"] = "猎豹"
	L["Moonkin"] = "枭兽"
	L["Aquatic"] = "水栖"
	L["Flight"] = "飞行"
	L["Travel"] = "旅行"
	L["Tree"] = "树"

	L["Bear_short"] = "熊"
	L["Cat_short"] = "豹"
	L["Moonkin_short"] = "枭"
	L["Aquatic_short"] = "水"
	L["Flight_short"] = "飞"
	L["Travel_short"] = "旅"
	L["Tree_short"] = "树"

	-- shortgenders
	L["Male_short"] = "男"
	L["Female_short"] = "女"

	L["Leader"] = "队长"

	-- spell trees
	L["Hybrid"] = "混合" -- for all 3 trees
	L["Druid_Tree_1"] = "平衡"
	L["Druid_Tree_2"] = "野性战斗"
	L["Druid_Tree_3"] = "恢复"
	L["Hunter_Tree_1"] = "野兽掌握"
	L["Hunter_Tree_2"] = "射击"
	L["Hunter_Tree_3"] = "生存"
	L["Mage_Tree_1"] = "奥术"
	L["Mage_Tree_2"] = "火焰"
	L["Mage_Tree_3"] = "冰霜"
	L["Paladin_Tree_1"] = "神圣"
	L["Paladin_Tree_2"] = "防护"
	L["Paladin_Tree_3"] = "惩戒"
	L["Priest_Tree_1"] = "戒律"
	L["Priest_Tree_2"] = "神圣"
	L["Priest_Tree_3"] = "暗影"
	L["Rogue_Tree_1"] = "刺杀"
	L["Rogue_Tree_2"] = "战斗"
	L["Rogue_Tree_3"] = "敏锐"
	L["Shaman_Tree_1"] = "元素战斗"
	L["Shaman_Tree_2"] = "增强"
	L["Shaman_Tree_3"] = "恢复"
	L["Warrior_Tree_1"] = "武器"
	L["Warrior_Tree_2"] = "狂怒"
	L["Warrior_Tree_3"] = "防御"
	L["Warlock_Tree_1"] = "痛苦"
	L["Warlock_Tree_2"] = "恶魔学识"
	L["Warlock_Tree_3"] = "毁灭"
end

end