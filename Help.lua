local MAJOR_VERSION = "LibDogTag-3.0"
local MINOR_VERSION = tonumber(("$Revision$"):match("%d+")) or 0

if MINOR_VERSION > _G.DogTag_MINOR_VERSION then
	_G.DogTag_MINOR_VERSION = MINOR_VERSION
end

DogTag_funcs[#DogTag_funcs+1] = function(DogTag)

local L = DogTag.L

local newList, newDict, newSet, del = DogTag.newList, DogTag.newDict, DogTag.newSet, DogTag.del

local helpFrame
--[[
Notes:
	This opens the in-game documentation, which provides information to users on syntax as well as the available tags and modifiers.
]]
function DogTag:OpenHelp()
	helpFrame = CreateFrame("Frame", MAJOR_VERSION .. "_HelpFrame", UIParent)
	helpFrame:SetWidth(600)
	helpFrame:SetHeight(300)
	helpFrame:SetPoint("CENTER", UIParent, "CENTER")
	helpFrame:EnableMouse(true)
	helpFrame:SetMovable(true)
	helpFrame:SetResizable(true)
	helpFrame:SetMinResize(600, 300)
	helpFrame:SetFrameLevel(50)
	helpFrame:SetFrameStrata("FULLSCREEN_DIALOG")

	local bg = newDict(
		'bgFile', [[Interface\DialogFrame\UI-DialogBox-Background]],
		'edgeFile', [[Interface\DialogFrame\UI-DialogBox-Border]],
		'tile', true,
		'tileSize', 32,
		'edgeSize', 32,
		'insets', newDict(
			'left', 5,
			'right', 6,
			'top', 5,
			'bottom', 6
		)
	)
	helpFrame:SetBackdrop(bg)
	bg.insets = del(bg.insets)
	bg = del(bg)
	helpFrame:SetBackdropColor(0, 0, 0)
	helpFrame:SetClampedToScreen(true)
	
	local header = CreateFrame("Frame", helpFrame:GetName() .. "_Header", helpFrame)
	helpFrame.header = header
	header:SetHeight(34.56)
	header:SetClampedToScreen(true)
	local left = header:CreateTexture(header:GetName() .. "_TextureLeft", "ARTWORK")
	header.left = left
	left:SetPoint("TOPLEFT")
	left:SetPoint("BOTTOMLEFT")
	left:SetWidth(11.54)
	left:SetTexture([[Interface\DialogFrame\UI-DialogBox-Header]])
	left:SetTexCoord(0.235, 0.28, 0.04, 0.58)
	local right = header:CreateTexture(header:GetName() .. "_TextureRight", "ARTWORK")
	header.right = right
	right:SetPoint("TOPRIGHT")
	right:SetPoint("BOTTOMRIGHT")
	right:SetWidth(11.54)
	right:SetTexture([[Interface\DialogFrame\UI-DialogBox-Header]])
	right:SetTexCoord(0.715, 0.76, 0.04, 0.58)
	local center = header:CreateTexture(header:GetName() .. "_TextureCenter", "ARTWORK")
	header.center = center
	center:SetPoint("TOPLEFT", left, "TOPRIGHT")
	center:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
	center:SetTexture([[Interface\DialogFrame\UI-DialogBox-Header]])
	center:SetTexCoord(0.28, 0.715, 0.04, 0.58)
	
	local closeButton = CreateFrame("Button", helpFrame:GetName() .. "_CloseButton", helpFrame, "UIPanelCloseButton")
	helpFrame.closeButton = closeButton
	closeButton:SetFrameLevel(helpFrame:GetFrameLevel()+5)
	closeButton:SetScript("OnClick", function(this)
		this:GetParent():Hide()
	end)
	closeButton:SetPoint("TOPRIGHT", helpFrame, "TOPRIGHT", -5, -5)
	
	header:EnableMouse(true)
	header:RegisterForDrag("LeftButton")
	header:SetScript("OnDragStart", function(this)
		isDragging = true
		this:GetParent():StartMoving()
	end)
	header:SetScript("OnDragStop", function(this)
		isDragging = false
		this:GetParent():StopMovingOrSizing()
	end)

	local titleText = header:CreateFontString(header:GetName() .. "_FontString", "OVERLAY", "GameFontNormal")
	helpFrame.titleText = titleText
	titleText:SetText(L["DogTag Help"])
	titleText:SetPoint("CENTER", helpFrame, "TOP", 0, -8)
	titleText:SetHeight(26)
	titleText:SetShadowColor(0, 0, 0)
	titleText:SetShadowOffset(1, -1)

	header:SetPoint("LEFT", titleText, "LEFT", -32, 0)
	header:SetPoint("RIGHT", titleText, "RIGHT", 32, 0)
	
	local sizer_se = CreateFrame("Frame", helpFrame:GetName() .. "_SizerSoutheast", helpFrame)
	helpFrame.sizer_se = sizer_se
	sizer_se:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", 0, 0)
	sizer_se:SetWidth(25)
	sizer_se:SetHeight(25)
	sizer_se:EnableMouse(true)
	sizer_se:RegisterForDrag("LeftButton")
	sizer_se:SetScript("OnDragStart", function(this)
		isDragging = true
		this:GetParent():StartSizing("BOTTOMRIGHT")
	end)
	sizer_se:SetScript("OnDragStop", function(this)
		isDragging = false
		this:GetParent():StopMovingOrSizing()
	end)
	local line1 = sizer_se:CreateTexture(sizer_se:GetName() .. "_Line1", "BACKGROUND")
	line1:SetWidth(14)
	line1:SetHeight(14)
	line1:SetPoint("BOTTOMRIGHT", -10, 10)
	line1:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	local x = 0.1 * 14/17
	line1:SetTexCoord(1/32 - x, 0.5, 1/32, 0.5 + x, 1/32, 0.5 - x, 1/32 + x, 0.5)

	local line2 = sizer_se:CreateTexture(sizer_se:GetName() .. "_Line2", "BACKGROUND")
	line2:SetWidth(11)
	line2:SetHeight(11)
	line2:SetPoint("BOTTOMRIGHT", -10, 10)
	line2:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	local x = 0.1 * 11/17
	line2:SetTexCoord(1/32 - x, 0.5, 1/32, 0.5 + x, 1/32, 0.5 - x, 1/32 + x, 0.5)

	local line3 = sizer_se:CreateTexture(sizer_se:GetName() .. "_Line3", "BACKGROUND")
	line3:SetWidth(8)
	line3:SetHeight(8)
	line3:SetPoint("BOTTOMRIGHT", -10, 10)
	line3:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
	local x = 0.1 * 8/17
	line3:SetTexCoord(1/32 - x, 0.5, 1/32, 0.5 + x, 1/32, 0.5 - x, 1/32 + x, 0.5)
	
	local mainPane = CreateFrame("Frame", helpFrame:GetName() .. "_MainPane", helpFrame)
	helpFrame.mainPane = mainPane
	local bg = newDict(
		'bgFile', [[Interface\Buttons\WHITE8X8]],
		'edgeFile', [[Interface\Tooltips\UI-Tooltip-Border]],
		'tile', true,
		'tileSize', 16,
		'edgeSize', 16,
		'insets', newDict(
			'left', 3,
			'right', 3,
			'top', 3,
			'bottom', 3
		)
	)
	mainPane:SetBackdrop(bg)
	bg.insets = del(bg.insets)
	bg = del(bg)
	mainPane:SetBackdropBorderColor(0.6, 0.6, 0.6)
	mainPane:SetBackdropColor(0, 0, 0)
	mainPane:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", 12, -35)
	mainPane:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -12, 30)
	
	local scrollFrame = CreateFrame("ScrollFrame", mainPane:GetName() .. "_ScrollFrame", mainPane)
	local scrollChild = CreateFrame("Frame", mainPane:GetName() .. "_ScrollChild", scrollFrame)
	local scrollBar = CreateFrame("Slider", mainPane:GetName() .. "_ScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
	mainPane.scrollFrame = scrollFrame
	mainPane.scrollChild = scrollChild
	mainPane.scrollBar = scrollBar

	scrollFrame:SetScrollChild(scrollChild)
	scrollFrame:SetPoint("TOPLEFT", mainPane, "TOPLEFT", 9, -9)
	scrollFrame:SetPoint("BOTTOMRIGHT", mainPane, "BOTTOMRIGHT", -28, 12)
	scrollFrame:EnableMouseWheel(true)
	scrollFrame:SetScript("OnMouseWheel", function(this, change)
		local childHeight = scrollChild:CalculateHeight()
		local frameHeight = scrollFrame:GetHeight()
		if childHeight <= frameHeight then
			return
		end

		nextFreeScroll = GetTime() + 1

		local diff = childHeight - frameHeight

		local delta = 1
		if change > 0 then
			delta = -1
		end

		local value = scrollBar:GetValue() + delta*24/diff
		if value < 0 then
			value = 0
		elseif value > 1 then
			value = 1
		end
		scrollBar:SetValue(value) -- will trigger OnValueChanged
	end)

	scrollChild:SetHeight(10)
	scrollChild:SetWidth(10)

	local first = true
	function scrollChild:CalculateHeight()
		local html = self.html
		local t = newList(html:GetRegions())
		local top, bottom
		for i,v in ipairs(t) do
			if v:GetTop() and (not top or top < v:GetTop()) then
				top = v:GetTop()
			end
			if v:GetBottom() and (not bottom or bottom > v:GetBottom()) then
				bottom = v:GetBottom()
			end
		end
		t = del(t)
		return top and (top - bottom) or 10
	end
	_G.scrollChild = scrollChild

	scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 0, -16)
	scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 0, 16)
	scrollBar:SetMinMaxValues(0, 1)
	scrollBar:SetValueStep(1e-5)
	scrollBar:SetValue(0)
	scrollBar:SetWidth(16)
	scrollBar:SetScript("OnValueChanged", function(this)
		local max = scrollChild:CalculateHeight() - scrollFrame:GetHeight()

		local val = scrollBar:GetValue() * max
		
		if math.abs(scrollFrame:GetVerticalScroll() - val) < 1 then
			return
		end

		scrollFrame:SetVerticalScroll(val)

		scrollFrame:UpdateScrollChildRect()
	end)
	scrollBar:EnableMouseWheel(true)
	scrollBar:SetScript("OnMouseWheel", function(this, ...)
		scrollFrame:GetScript("OnMouseWheel")(scrollFrame, ...)
	end)
	
	local html = CreateFrame("SimpleHTML", scrollChild:GetName() .. "_HTML", scrollChild)
	scrollChild.html = html
	html:SetFontObject('p', GameFontNormal)
	html:SetSpacing('p', 3)
	
	html:SetFontObject('h1', GameFontHighlightLarge)
	local font, height, flags = GameFontHighlightLarge:GetFont()
	height = height * 1.25
	html:SetFont('h1', font, height, flags)
	html:SetSpacing('h1', height/2)
	
	html:SetFontObject('h2', GameFontHighlightLarge)
	local _, height = GameFontHighlightLarge:GetFont()
	html:SetSpacing('h2', height/2)
	
	html:SetFontObject('h3', GameFontHighlightNormal)
	local _, height = GameFontHighlightLarge:GetFont()
	html:SetSpacing('h3', height/2)
	
	html:SetHeight(1)
	html:SetWidth(400)
	html:SetPoint("TOPLEFT", 0, 0)
	html:SetJustifyH("LEFT")
	html:SetJustifyV("TOP")
	
	
	local searchBox = CreateFrame("EditBox", helpFrame:GetName() .. "_SearchBox", helpFrame)
	searchBox:SetFontObject(ChatFontNormal)
	searchBox:SetHeight(17)
	searchBox:SetAutoFocus(false)
	
	local searchBox_line1 = searchBox:CreateTexture(searchBox:GetName() .. "_Line1", "BACKGROUND")
	searchBox_line1:SetTexture([[Interface\Buttons\WHITE8X8]])
	searchBox_line1:SetHeight(1)
	searchBox_line1:SetPoint("TOPLEFT", searchBox, "BOTTOMLEFT", 0, 1)
	searchBox_line1:SetPoint("TOPRIGHT", searchBox, "BOTTOMRIGHT", 0, 1)
	searchBox_line1:SetVertexColor(3/4, 3/4, 3/4, 1)
	
	local searchBox_line2 = searchBox:CreateTexture(searchBox:GetName() .. "_Line2", "BACKGROUND")
	searchBox_line2:SetTexture([[Interface\Buttons\WHITE8X8]])
	searchBox_line2:SetWidth(1)
	searchBox_line2:SetPoint("TOPLEFT", searchBox, "TOPRIGHT", -1, 0)
	searchBox_line2:SetPoint("BOTTOMLEFT", searchBox, "BOTTOMRIGHT", -1, 0)
	searchBox_line2:SetVertexColor(3/4, 3/4, 3/4, 1)
	
	local searchBox_line3 = searchBox:CreateTexture(searchBox:GetName() .. "_Line3", "BACKGROUND")
	searchBox_line3:SetTexture([[Interface\Buttons\WHITE8X8]])
	searchBox_line3:SetHeight(1)
	searchBox_line3:SetPoint("BOTTOMLEFT", searchBox, "TOPLEFT", 0, -1)
	searchBox_line3:SetPoint("BOTTOMRIGHT", searchBox, "TOPRIGHT", 0, -1)
	searchBox_line3:SetVertexColor(3/8, 3/8, 3/8, 1)
	
	local searchBox_line4 = searchBox:CreateTexture(searchBox:GetName() .. "_Line4", "BACKGROUND")
	searchBox_line4:SetTexture([[Interface\Buttons\WHITE8X8]])
	searchBox_line4:SetWidth(1)
	searchBox_line4:SetPoint("TOPRIGHT", searchBox, "TOPLEFT", 1, 0)
	searchBox_line4:SetPoint("BOTTOMRIGHT", searchBox, "BOTTOMLEFT", 1, 0)
	searchBox_line4:SetVertexColor(3/8, 3/8, 3/8, 1)
	
	local editBox = CreateFrame("EditBox", helpFrame:GetName() .. "_EditBox", helpFrame)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetHeight(17)
	editBox:SetWidth(200)
	editBox:SetAutoFocus(false)
	
	local editBox_line1 = editBox:CreateTexture(editBox:GetName() .. "_Line1", "BACKGROUND")
	editBox_line1:SetTexture([[Interface\Buttons\WHITE8X8]])
	editBox_line1:SetHeight(1)
	editBox_line1:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, 1)
	editBox_line1:SetPoint("TOPRIGHT", editBox, "BOTTOMRIGHT", 0, 1)
	editBox_line1:SetVertexColor(3/4, 3/4, 3/4, 1)
	
	local editBox_line2 = editBox:CreateTexture(editBox:GetName() .. "_Line2", "BACKGROUND")
	editBox_line2:SetTexture([[Interface\Buttons\WHITE8X8]])
	editBox_line2:SetWidth(1)
	editBox_line2:SetPoint("TOPLEFT", editBox, "TOPRIGHT", -1, 0)
	editBox_line2:SetPoint("BOTTOMLEFT", editBox, "BOTTOMRIGHT", -1, 0)
	editBox_line2:SetVertexColor(3/4, 3/4, 3/4, 1)
	
	local editBox_line3 = editBox:CreateTexture(editBox:GetName() .. "_Line3", "BACKGROUND")
	editBox_line3:SetTexture([[Interface\Buttons\WHITE8X8]])
	editBox_line3:SetHeight(1)
	editBox_line3:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", 0, -1)
	editBox_line3:SetPoint("BOTTOMRIGHT", editBox, "TOPRIGHT", 0, -1)
	editBox_line3:SetVertexColor(3/8, 3/8, 3/8, 1)
	
	local editBox_line4 = editBox:CreateTexture(editBox:GetName() .. "_Line4", "BACKGROUND")
	editBox_line4:SetTexture([[Interface\Buttons\WHITE8X8]])
	editBox_line4:SetWidth(1)
	editBox_line4:SetPoint("TOPRIGHT", editBox, "TOPLEFT", 1, 0)
	editBox_line4:SetPoint("BOTTOMRIGHT", editBox, "BOTTOMLEFT", 1, 0)
	editBox_line4:SetVertexColor(3/8, 3/8, 3/8, 1)
	
	local currentUnit = "player"
	
	local fontString = helpFrame:CreateFontString(helpFrame:GetName() .. "_FontString", "ARTWORK")
	fontString:SetPoint("LEFT", editBox, "RIGHT", 20, 0)
	fontString:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -20, 13)
	fontString:SetHeight(17)
	fontString:SetFontObject(ChatFontNormal)
	
	editBox:SetScript("OnEscapePressed", function(this)
		this:ClearFocus()
		this:SetText(DogTag:CleanCode(this:GetText()))
	end)
	
	editBox:SetScript("OnEnterPressed", editBox:GetScript("OnEscapePressed"))
	
	editBox:SetScript("OnTextChanged", function(this)
		local kwargs = newList()
		kwargs.unit = currentUnit
		DogTag:AddFontString(fontString, helpFrame, editBox:GetText(), "Unit", kwargs)
		kwargs = del(kwargs)
	end)
	
	editBox:SetText("[Name]")
	
	searchBox:SetScript("OnEscapePressed", function(this)
		this:ClearFocus()
	end)
	searchBox:SetScript("OnEnterPressed", searchBox:GetScript("OnEscapePressed"))
	
	local dropdown = CreateFrame("Frame", helpFrame:GetName() .. "_DropDown", helpFrame, "UIDropDownMenuTemplate")
	
	local function dropdown_OnClick()
		UIDropDownMenu_SetSelectedValue(dropdown, this.value)
		currentUnit = this.value
		DogTag:AddFontString(fontString, helpFrame, currentUnit, editBox:GetText())
	end
	UIDropDownMenu_Initialize(dropdown, function()
		local info = newList()
		info.text = L["Player"]
		info.value = "player"
		info.func = dropdown_OnClick
		UIDropDownMenu_AddButton(info)
		info = del(info)
		
		local info = newList()
		info.text = L["Target"]
		info.value = "target"
		info.func = dropdown_OnClick
		UIDropDownMenu_AddButton(info)
		info = del(info)
		
		local info = newList()
		info.text = L["Pet"]
		info.value = "pet"
		info.func = dropdown_OnClick
		UIDropDownMenu_AddButton(info)
		info = del(info)
	end)
	UIDropDownMenu_SetSelectedValue(dropdown, currentUnit)
	
	scrollFrame:SetScript("OnSizeChanged", function(this)
		html:SetWidth(this:GetWidth())
		html:SetText(html.text)
		editBox:SetWidth(this:GetWidth()*1/2 - 20)
	end)
	
	dropdown:SetPoint("BOTTOMLEFT", helpFrame, "BOTTOMLEFT", -5, 6)
	editBox:SetPoint("LEFT", _G[dropdown:GetName() .. "Button"], "RIGHT", 5, 0)
	searchBox:SetPoint("RIGHT", closeButton, "LEFT", -5, 0)
	searchBox:SetPoint("BOTTOM", closeButton, "BOTTOM", 0, 5)
	searchBox:SetPoint("LEFT", header, "RIGHT", 15, 0)
	
	local function _fix__handler(text)
		if text:sub(1, 2) == "{{" and text:sub(-2) == "}}" then
			local x = text:sub(3, -3)
			x = "[" .. x .. "]"
			x = DogTag:ColorizeCode(x)
			local y = x:match("^|cff%x%x%x%x%x%x%[|r(|cff%x%x%x%x%x%x.*|r)|cff%x%x%x%x%x%x%]|r$")
			return y
		end
		return DogTag:ColorizeCode(text:sub(2, -2))
	end
	local function fix__handler(text)
		return _fix__handler(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	end
	local function fix__handler2(text)
		return "|cffffffff" .. text:sub(1, -2) .. '|cffffffff"|r'
	end
	local function fix(text)
		return text:gsub('(%b"")', fix__handler2):gsub("(%b{})", fix__handler):gsub("&lbrace;", "{"):gsub("&rbrace;", "}")
	end
	
	local function dataToHTML(data)
		local t = newList()
		t[#t+1] = "<html>"
		t[#t+1] = "<body>"
		for _,h1 in ipairs(data) do
			local title = h1[1]
			t[#t+1] = "<h1>"
			t[#t+1] = fix(title)
			t[#t+1] = "</h1>"
			local description = type(h1[2]) == "string" and h1[2]
			if description then
				t[#t+1] = "<p>"
				t[#t+1] = fix(description)
				t[#t+1] = "</p>"
				t[#t+1] = "<br />"
			end
			for i = description and 3 or 2, #h1 do
				local h2 = h1[i]
				local title = h2[1]
				local description = type(h2[2]) == "string" and h2[2]
				t[#t+1] = "<h2>"
				t[#t+1] = fix(title)
				t[#t+1] = "</h2>"
				if description then
					t[#t+1] = "<p>"
					t[#t+1] = fix(description)
					t[#t+1] = "</p>"
					t[#t+1] = "<br />"
				end
				for j = description and 3 or 2, #h2 do
					local h3 = h2[j]
					local title = h3[1]
					t[#t+1] = "<h2>"
					t[#t+1] = fix(title)
					t[#t+1] = "</h2>"
					for k = 2, #h3 do
						local description = h3[k]
						t[#t+1] = "<p>"
						t[#t+1] = fix(description)
						t[#t+1] = "</p>"
						t[#t+1] = "<br />"
					end
				end
			end
		end
		while t[#t] == "<br />" do
			t[#t] = nil
		end
		t[#t+1] = "</body>"
		t[#t+1] = "</html>"
		local result = table.concat(t)
		t = del(t)
		return result
	end
	
	local syntaxHTML = dataToHTML({
		{
			L["Syntax"], [=[LibDogTag-3.0 works by allowing normal text with interspersed tags wrapped in brackets, e.g. {Hello [Tag] There}. Syntax is in the standard form alpha {[Tag]} bravo where alpha is a literal word, bravo is a literal word and {[Tag]} will be replaced by the associated dynamic text. All tags and modifiers are case-insensitive, but will be corrected to proper casing if the tags are legal.]=],
			{ L["Modifiers"], [=[Modifiers can change how a tag's output looks. For example, the {{:Hide(0)}} modifier will hide the result if it is equal to the number {{0}}, so {[HP:Hide(0)]} will show the current health except when it's equal to {{0}}, at which point it will be blank. You can chain together multiple modifiers as well, e.g. {[MissingHP:Hide(0):Red]} will show the missing health as red and not show it if it's equal to {{0}}. Modifiers are actually syntactic sugar for tags. {[HP:Hide(0)]} is exactly the same as {[Hide(HP, 0)]}. All modifiers work this way and all tags can be used as modifiers if they accept an argument.]=] },
			{ L["Arguments"], [=[Tags and modifiers can also take an argument, and can be fed in in a syntax similar to {[Tag(argument)]} or {[Tag:Modifier(argument)]}. You can specify arguments out of order by name Using the syntax {[HP(unit='player')]}. This is exactly equal to {[HP('player')]} and {['player':HP]}.]=] },
			{ L["Literals"], [=[Strings require either double or single quotes and are used like ["Hello" ' There']. Numbers can be typed just as normal numbers, e.g. {[1234 56.78 1e6]}. There are also the literals {{nil}}, {{true}}, and {{false}}, which act just like tags.]=]},
			{ L["Logic Branching (if statements)"], [=[
			* The {{&}} and {{and}} operators function as boolean AND. e.g. {[Alpha and Bravo]} will check if Alpha is non-false, if so, run Bravo.<br />
			* The {{||}} and {{or}} operators function as boolean OR. e.g. {[Alpha or Bravo]} will check if Alpha is false, if so, run Bravo, otherwise just show Alpha.<br />
			* The {{?}} operator functions as an if statement. It can be used in conjunction with {{!}} to create an if-else statement. e.g. {[IsPlayer ? "Player"]} or {[IsPlayer ? "Player" ! "NPC"]}.
			* The {{if}} operator functions as an if statement. It can be used in conjunction with {{else}} to create an if-else statement. e.g. {[if IsPlayer then "Player"]} or {[if IsPlayer then "Player" else "NPC"]}.
			* The {{not}} and {{~}} operators turn a false value into true and true value into false. e.g. {[not IsPlayer]} or {[~IsPlayer]}
			]=],
				{ L["Examples"], [=[
					{[Status || FractionalHP(known=true) || PercentHP]}<br />
					Will return one of the following (but only one): <br /><br />
					* "Dead", "Offline", "Ghost", etc -- no further information since the OR indicates that there is already a legitimate return<br />
					* "3560/8490" or "130/6575" (but not "62/100" unless the target in fact has {{100}} hit points) -- and not "0/2340" or "0/3592" because that would mean it is dead and that would have already been taken care of by the first tag in the sequence<br />
					* "25" or "35" or "72" (percent health) -- if the unit is not dead, offline, etc, and your addon is uncertain of your target's maximum and current health, it will display percent health.<br /><br />
					{[Status || (IsPlayer ? HP(known=true)) || PercentHP:Percent]} will deliver similar returns as to that above, but in a slightly different format which should be fairly apparent already.<br /><br />
					But to clarify, the nested {{(IsPlayer ? HP(known=true))}} creates an if statement which means that if {{IsPlayer}} is false, the whole value is taken to be false, and if you've read this far you deserve a cookie. If {{IsPlayer}} is true, the actual returned value of this nested expression is actually the term following the AND -- in this case, {{HP(known=true)}}. So this will show {{HP(known=true)}} if {{IsPlayer}} is found true (that is, if the unit is actually a player).
				]=], [=[
					{[if IsFriend then -MissingHP:Green else HP:Red]}<br /> 
					Will return one of the following (but only one):<br /><br />
					* If the unit is friendly, it will display the amount of health they must be healed to meet their maximum. It will be displayed in green, and with a negative sign in front of it.<br /> 
					* If the unit is an enemy, it will display their current health. As this sequence is written, it will not consider whether it is a valid health value or not. On enemies where the health value is uncertain, it will show a percentage (but without a percent sign), until a more reliable value can be determined. This value will be displayed in red.
				]=]}
			},
			{ "Unit specification", [=[
				Units are typically pre-specified by the addon which uses DogTag, whether {{"player"}}, {{"mouseover"}}, or otherwise. You can override the unit a specific tag or modifier operates on by using the form {[Tag(unit="myunit")]} or {[Tag:Modifier(unit="myunit")]}. e.g. {[HP(unit='player')]} gets the player's health.
			]=], { "List of example units", [=[
				* player - your character<br />
				* target - your target<br />
				* targettarget - your target's target<br />
				* pet - your pet<br />
				* mouseover - the unit you are currently hovering over<br />
				* focus - your focus unit<br />
				* party1 - the first member of your party<br />
				* partypet2 - the pet of the second member of your party<br />
				* raid3 - the third member of your raid<br />
				* raidpet4 - the pet of the fourth member of your raid<br />
				]=] }
			},
			{ "Arithmetic operators", [=[
			You can use arithmetic operators in your DogTag sequences without issue, they function as expected with proper order-of-operations.
			* {{+}} - Addition<br />
			* {{-}} - Subtraction<br />
			* {{*}} - Multiplication<br />
			* {{/}} - Division<br />
			* {{%}} - Modulus<br />
			* {{^}} - Exponentiation
			]=]},
			{ "Comparison operators", [=[
			You can use comparison operators in your DogTag very similarly to arithmetic operators.<br /><br />
			* {{=}} - Equality<br />
			* {{~=}} - Inequality<br />
			* {{<}} - Less than<br />
			* {{>}} - Greater than<br />
			* {{<=}} - Less than or equal<br />
			* {{>=}} - Greater than or equal
			]=]},
			{ "Concatenation", [=[
			Concatenation (joining two pieces of text together) is very easy, all you have to do is place them next to each other separated by a space, e.g. {['Hello' " There"]} =&gt; "Hello There". For a more true-to-life example, {[HP '/' MaxHP]} => "50/100".
			]=]}
		}
	})
	
	local function wrapWhite(text)
		return "|cffffffff" .. text .. "|r"
	end
	
	local function highlightWords(text)
		text = text:gsub("%f[A-Za-z0-9_](unit)%f[^A-Za-z0-9_]", wrapWhite)
		text = text:gsub("%f[A-Za-z0-9_](argument)%f[^A-Za-z0-9_]", wrapWhite)
		text = text:gsub("%f[A-Za-z0-9_](value)%f[^A-Za-z0-9_]", wrapWhite)
		text = text:gsub("%f[A-Za-z0-9_](number_value)%f[^A-Za-z0-9_]", wrapWhite)
		text = text:gsub("%f[A-Za-z0-9_](number)%f[^A-Za-z0-9_]", wrapWhite)
		return text
	end
	
	local tags = newList()
	local tagCategories_tmp = newSet()
	local Tags, getTagData = DogTag.Tags, DogTag.getTagData
	for k,v in pairs(Tags["Base"]) do
		if v.doc then
			tags[#tags+1] = k
		end
	end
	if Tags["Unit"] then
		for k,v in pairs(Tags["Unit"]) do
			if v.doc then
				tags[#tags+1] = k
			end
		end
	end
	table.sort(tags)
	for _,k in ipairs(tags) do
		local v = getTagData(k, "Base;Unit")
		if v.category then
			tagCategories_tmp[v.category] = true
		end
	end
	local tagCategories = newList()
	for k in pairs(tagCategories_tmp) do
		tagCategories[#tagCategories+1] = k
	end
	tagCategories_tmp = del(tagCategories_tmp)
	table.sort(tagCategories)
	
	local tagCache = {}
	
	for _, k in ipairs(tags) do
		local tagData = getTagData(k, "Base;Unit")
		local v = tagData.doc
		local arg = tagData.arg
		
		tagCache[k] = {}
		tagCache[k].category = tagData.category
		
		local t = newList()
		
		t[#t+1] = "{["
		t[#t+1] = k
		if arg then
			t[#t+1] = "("
			for i = 1, #arg, 3 do
				if i > 1 then
					t[#t+1] = ", "
				end
				local argName, argTypes, argDefault = arg[i], arg[i+1], arg[i+2]
				t[#t+1] = argName
				if argName ~= "..." and argDefault ~= "@req" then
					t[#t+1] = "="
					if argDefault == "@undef" then
						t[#t+1] = "undef"
					elseif argDefault == false then
						if argTypes:match("boolean") then
							t[#t+1] = "false"
						else
							t[#t+1] = "nil"
						end
					elseif type(argDefault) == "string" then
						t[#t+1] = ("%q"):format(argDefault)
					else
						t[#t+1] = tostring(argDefault)
					end
				end
			end
			t[#t+1] = ")"
		end
		t[#t+1] = "]}"
		t[#t+1] = " - "
		t[#t+1] = v -- highlightWords(v)
		if tagData.alias then
			t[#t+1] = " - "
			t[#t+1] = L["alias for "]
			t[#t+1] = "{["
			t[#t+1] = tagData.alias
			t[#t+1] = "]}"
		end
		tagCache[k].topLine = table.concat(t)
		t = del(t)
		tagCache[k].examples = {}
		local examples = newList((";"):split(tagData.example))
		for i, u in ipairs(examples) do
			local tag, result = u:trim():match("(.*) => (.*)")
			tagCache[k].examples[tag] = true
		end
		examples = del(examples)
	end
	
	local function caseDesensitize__handler(c)
		return ("[%s%s]"):format(c:lower(), c:upper())
	end
	local function caseDesensitize(searchText)
		return searchText:gsub("%a", caseDesensitize__handler)
	end
	
	local function escapeSearch(searchText)
		return searchText:gsub("([%%%[%]%^%$%.%+%*%?%(%)])", "%%%1")
	end
	
	local tagsHTML
	local function updateTagsPage(searchText)
		local title = L["Tags"]
		searchText = (searchText or ''):trim():gsub("%s%s+", " ")
		local searches
		if searchText ~= '' then
			title = L["Tags matching %q"]:format(searchText)
			searches = newList((" "):split(searchText))
			for i, v in ipairs(searches) do
				searches[i] = caseDesensitize(escapeSearch(v))
			end
		end
		local tagsData = newList(newList(title))
		for _, category in ipairs(tagCategories) do
			local t = newList()
			for _, k in ipairs(tags) do
				local data = tagCache[k]
			
				if data.category == category then
					local good = true
					if searches then
						for i, v in ipairs(searches) do
							if not data.topLine:match(v) then
								good = false
							end
						end
					end
					if good then
						t[#t+1] = data.topLine
						t[#t+1] = "<br/>"
						t[#t+1] = "e.g. "
						local first = true
						for example in pairs(data.examples) do
							if first then
								first = false
							else
								t[#t+1] = "; "
							end
							t[#t+1] = "{"
							t[#t+1] = example
							t[#t+1] = "} =&gt; \""
							t[#t+1] = (tostring(DogTag:Evaluate(example, "Unit") or '')):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
							t[#t+1] = "\""
						end
						t[#t+1] = "<br/>"
						t[#t+1] = "<br/>"
					end
				end
			end
			while t[#t] == "<br/>" do
				t[#t] = nil
			end
			if #t > 0 then
				tagsData[1][#tagsData[1]+1] = newList(category, table.concat(t))
			end
			t = del(t)
		end
		tagsHTML = dataToHTML(tagsData)
		for i, v in ipairs(tagsData[1]) do
			if type(v) == "table" then
				del(v)
			end
			tagsData[1][i] = nil
		end
		tagsData[1] = del(tagsData[1])
		tagsData = del(tagsData)
	end
	
	local tabCount = 0
	local function makeTab(name)
		tabCount = tabCount + 1
		local tab = CreateFrame("Button", helpFrame:GetName() .. "Tab" .. tabCount, helpFrame, "TabButtonTemplate")
		tab:SetText(name)
		PanelTemplates_TabResize(0, tab)
		tab:SetID(tabCount)
		tab:SetScript("OnClick", function(this)
			PanelTemplates_SetTab(this:GetParent(), this:GetID())
			if this.Select then
				this:Select()
			end
			scrollBar:SetValue(0)
		end)
		tab:SetFrameLevel(tab:GetFrameLevel()+10)
		return tab
	end
	local tab1, tab2 = makeTab(L["Syntax"]), makeTab(L["Tags"])
	
	tab1:SetPoint("TOPLEFT", 30, -5)
	tab2:SetPoint("LEFT", tab1, "RIGHT")
--	tab3:SetPoint("LEFT", tab2, "RIGHT")
	
	PanelTemplates_SetNumTabs(helpFrame, 2)
	helpFrame.selectedTab = 1
	PanelTemplates_SetTab(helpFrame, 1)
	
	function tab1:Select()
		html.text = syntaxHTML
		html:SetText(syntaxHTML)
	end
	
	function tab2:Select()
		updateTagsPage(searchBox:GetText())
		html.text = tagsHTML
		html:SetText(tagsHTML)
	end
	
	tab1:Select()
	
	local nextUpdateTime = 0
	searchBox:SetScript("OnUpdate", function(this)
		if GetTime() < nextUpdateTime then
			return
		end
		nextUpdateTime = GetTime() + 5
		if PanelTemplates_GetSelectedTab(helpFrame) == 2 then
			updateTagsPage(this:GetText())
			html.text = tagsHTML
			html:SetText(tagsHTML)
		end
	end)
	searchBox:SetScript("OnTextChanged", function(this)
		nextUpdateTime = GetTime() + 0.5
	end)
	
	function DogTag:OpenHelp()
		helpFrame:Show()
	end
end

_G.SlashCmdList.DOGTAG = function()
	DogTag:OpenHelp()
end

_G.SLASH_DOGTAG1 = "/dogtag"
_G.SLASH_DOGTAG2 = "/dog"
_G.SLASH_DOGTAG3 = "/dt"

end
