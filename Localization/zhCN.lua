local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_Unit_MINOR_VERSION then
	_G.DogTag_Unit_MINOR_VERSION = MINOR_VERSION
end

if GetLocale() == "zhCN" then

DogTag_funcs[#DogTag_funcs+1] = function(DogTag)
	local L = DogTag.L
	
	L["True"] = "True"
	
	L["DogTag Help"] = "DogTag帮助"
	L["Player"] = "玩家"
	L["Target"] = "目标"
	L["Pet"] = "宠物"
	L["Syntax"] = "语法"
	L["Modifiers"] = "修饰符"
	L["Arguments"] = "参数"
	L["Literals"] = "文字"
	L["Logic Branching (if statements)"] = "逻辑判断(if语句)"
	L["Examples"] = "举例"
	L["Unit specification"] = "目标指定"
	L["Arithmetic operators"] = "算术操作符"
	L["Comparison operators"] = "比较操作符"
	L["Concatenation"] = "拼接"
	L["Tags"] = "标签"
	L["Tags matching %q"] = "符合%q的标签"
	
	-- Categories
	L["Mathematics"] = "数学"
	L["Operators"] = "运算符"
	L["Text manipulation"] = "文字处理"
	L["Miscellaneous"] = "其它"
	
	-- Colors
	L["White"] = "白色"
	L["Red"] = "红色"
	L["Green"] = "绿色"
	L["Blue"] = "蓝色"
	L["Cyan"] = "青色"
	L["Fuchsia"] = "紫红色"
	L["Yellow"] = "黄色"
	L["Gray"] = "灰色"
	
	-- Docs
	-- Math
	L["Round number to the one's place or the place specified by digits"] = "四舍五入数字到个位，或者到所指定的位数"
	L["Take the floor of number"] = "返回小于等于指定数字的最大整数"
	L["Take the ceiling of number"] = "返回小于等于指定数字的最小整数"
	L["Take the absolute value of number"] = "返回指定数字的绝对值"
	L["Take the signum of number"] = "返回指定数字的符号"
	L["Return the greatest value of the given arguments"] = "返回给定参数中的最大值"
	L["Return the smallest value of the given arguments"] = "返回给定参数中的最小值"
	L["Return the mathematical number π, or %s"] = "返回π的值，即%s"
	L["Convert radian into degrees"] = "将弧度转换为角度"
	L["Convert degree into radians"] = "将角度转换为弧度"
	L["Return the cosine of radian"] = "返回弧度的余弦值"
	L["Return the sin of radian"] = "返回弧度的正弦值"
	L["Return the natural log of number"] = "返回指定数字的自然对数"
	L["Return the log base 10 of number"] = "返回指定数字以10为底的对数"
	-- Operators
	L["Add left and right together"] = "将左右值相加"
	L["Subtract right from left"] = "从左值中减去右值"
	L["Multiple left and right together"] = "将左右值相乘"
	L["Divide left by right"] = "用左值除以右值"
	L["Take the modulus of left and right"] = "用左值除以右值，返回余数"
	L["Raise left to the right power"] = "返回左值的右值次幂"
	L["Check if left is less than right, if so, return left"] = "如果左值比右值小，则返回左值"
	L["Check if left is greater than right, if so, return left"] = "如果左值比右值大，则返回左值"
	L["Check if left is less than or equal to right, if so, return left"] = "如果左值小于等于右值，则返回左值"
	L["Check if left is greater than or equal to right, if so, return left"] = "如果左值大于等于右值，则返回左值"
	L["Check if left is equal to right, if so, return left"] = "如果左右两值相等，则返回左值"
	L["Check if left is not equal to right, if so, return left"] = "如果左右两值不等，则返回左值"
	L["Return the negative of number"] = "返回指定数字的相反值"
	-- Text manipulation
	L["Append a percentage sign to the end of number"] = "在数字后面添加一个百分数符号"
	L["Shorten value to have at maximum 3 decimal places showing"] = "将数字简写到最多只有3位的显示方式"
	L["Shorten value to its closest denomination"] = "将数字简写到最贴近的千位值"
	L["Turn value into an uppercase string"] = "将值转换为全部大写的形式"
	L["Turn value into an lowercase string"] = "将值转换为全部小写的形式"
	L["Wrap value with square brackets"] = "将值用方括号括起来"
	L["Wrap value with angle brackets"] = "将值用尖括号括起来"
	L["Wrap value with braces"] = "将值用大括号括起来"
	L["Wrap value with parentheses"] = "将值用小括号括起来"
	L["Truncate value to the length specified by number, adding ellipses by default"] = "将值截断到指定的长度，默认添加省略号"
	L["Return the characters specified by start and finish. If either are negative, it means take from the end instead of the beginning"] = "返回两个参数所指定的位置之间的字符串。如果其中一个参数为负，则表明是从后往前而不是从前往后"
	L["Repeat value number times"] = "将值重复拼接指定的次数"
	L["Return the length of value"] = "返回值的长度"
	L["Turn number_value into a roman numeral."] = "将一个数字值转化为罗马样式"
	L["Abbreviate value if a space is found"] = "如果值有空格，则返回整个值的首字母缩写"
	L["Concatenate the values of ... as long as they are all non-blank"] = "当所有给定值都不为空时，拼接所有的值"
	L["Append right to left if right exists"] = "如果右值存在，则将右值附加在左值之后"
	L["Prepend left to right if right exists"] = "如果右值存在，则将右值附加在左值之前"
	-- Misc
	L["Return True if the Alt key is held down"] = "如果Alt正在按下则返回True"
	L["Return True if the Shift key is held down"] = "如果Shift正在按下则返回True"
	L["Return True if the Ctrl key is held down"] = "如果Ctrl正在按下则返回True"
	L["Return the current time in seconds, specified by WoW's internal format"] = "以魔兽的内部格式返回当前的时间，以秒为单位"
	L["Set the transparency of the FontString according to argument"] = "依据参数设置FontString的透明度"
	L["Set the FontString to be outlined"] = "让FontString有外描线"
	L["Set the FontString to be outlined thickly"] = "让FontString有较粗的外描线"
	L["Return True if currently mousing over the Frame the FontString is harbored in"] = "如果当前鼠标悬停框体是FontString所停靠的话，返回True"
	L["Return the color or wrap value with the rrggbb color of argument"] = "返回颜色，或者依据参数用颜色代码(rrggbb)将值括起来"
	L["Return the color or wrap value with %s color"] = "返回颜色，或者用%s代码将值括起来"
	L["Return value if value is within ..."] = "如果值存在于参数中，则返回值"
	L["Hide value if value is within ..."] = "如果值不存在于参数中，则返回值"
	L["Return left if left contains right"] = "如果左值包含了右值，则返回左值"
	L["Return True if non-blank"] = "如果值不为空则返回True"
	L["Return a string formatted by format"] = "返回按指定格式格式化的字符串"
	L["Return a string formatted by format. Use 'e' for extended, 'f' for full, 's' for short, 'c' for compressed."] = "返回按指定格式格式化的字符串。'e'为扩展格式，'f'为完整格式，'s'为简短格式，'c'为压缩格式。"
	L["Return an icon using the given path"] = "返回依据指定的路径和大小所生成的图标"
end

end
