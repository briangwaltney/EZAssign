SLASH_RESET1 = "/ezreset"
SLASH_RESETDB1 = "/ezresetdb"
SLASH_DB1 = "/ezdb"
SLASH_CREATELIST1 = "/ezCreateList"
SLASH_DELETELIST1 = "/ezdelete"
SLASH_ASSIGNLIST1 = "/ezassignlist"

-- Default colors
local headerFont = "GameFontNormal"
local normalFont = "GameFontHighlight"

local function printTableValues(tbl, indent)
	indent = indent or 0

	for key, value in pairs(tbl) do
		if type(value) == "table" then
			print(string.rep("  ", indent) .. key .. " (table):")
			printTableValues(value, indent + 1)
		else
			print(string.rep("  ", indent) .. key .. ": " .. tostring(value))
		end
	end
end

local defaultDB = {
	lists = {
		Default = {
			{},
			{},
			{},
			{},
			{},
		},
	},
}

EZAssignDB = EZAssignDB or defaultDB
M = {
	nameInputs = {},
	assignmentInputs = {},
	currentList = "Default",
	prio = 1,
	givenPrio = 1,
	myAssignments = {
		"",
		"",
		"",
		"",
		"",
	},
}

M.resetDB = function()
	EZAssignDB = defaultDB
end

M.Min = function(a, b)
	if a < b then
		return a
	else
		return b
	end
end

M.Max = function(a, b)
	if a > b then
		return a
	else
		return b
	end
end

M.textToRaidIcon = function(str)
	str = string.gsub(string.lower(str), "{star}", "{rt1}")
	str = string.gsub(string.lower(str), "{circle}", "{rt2}")
	str = string.gsub(string.lower(str), "{coin}", "{rt2}")
	str = string.gsub(string.lower(str), "{diamond}", "{rt3}")
	str = string.gsub(string.lower(str), "{triangle}", "{rt4}")
	str = string.gsub(string.lower(str), "{moon}", "{rt5}")
	str = string.gsub(string.lower(str), "{square}", "{rt6}")
	str = string.gsub(string.lower(str), "{cross}", "{rt7}")
	str = string.gsub(string.lower(str), "{skull}", "{rt8}")
	return str
end

M.createList = function(name)
	EZAssignDB.lists[name] = {
		{},
		{},
		{},
		{},
		{},
	}
end

--- Opts:
---     name (string): Name of the dropdown (lowercase)
---     parent (Frame): Parent frame of the dropdown.
---     items (Table): String table of the dropdown options.
---     defaultVal (String): String value for the dropdown to default to (empty otherwise).
---     changeFunc (Function): A custom function to be called, after selecting a dropdown option.
local function createDropdown(opts)
	local dropdown_name = "$parent_" .. opts["name"] .. "_dropdown"
	local menu_items = opts["items"] or {}
	local title_text = opts["title"] or ""
	local dropdown_width = 0
	local default_val = opts["defaultVal"] or ""
	local change_func = opts["changeFunc"] or function(dropdown_val) end

	local dropdown = CreateFrame("Frame", dropdown_name, opts["parent"], "UIDropDownMenuTemplate")
	local dd_title = dropdown:CreateFontString(dropdown_name .. "_title", "OVERLAY", "GameFontNormal")
	dd_title:SetPoint("TOPLEFT", 20, 15)

	for _, item in pairs(menu_items) do -- Sets the dropdown width to the largest item string width.
		dd_title:SetText(item)
		local text_width = dd_title:GetStringWidth() + 20
		if text_width > dropdown_width then
			dropdown_width = text_width
		end
	end

	UIDropDownMenu_SetWidth(dropdown, dropdown_width)
	UIDropDownMenu_SetText(dropdown, default_val)
	dd_title:SetText(title_text)

	UIDropDownMenu_Initialize(dropdown, function(self, level, _)
		local info = UIDropDownMenu_CreateInfo()
		for key, val in pairs(menu_items) do
			info.text = val
			info.checked = false
			info.menuList = key
			info.hasArrow = false
			info.func = function(b)
				UIDropDownMenu_SetSelectedValue(dropdown, b.value, b.value)
				UIDropDownMenu_SetText(dropdown, b.value)
				b.checked = true
				change_func(dropdown, b.value)
			end
			UIDropDownMenu_AddButton(info)
		end
	end)

	return dropdown
end

M.assignList = function()
	local list = EZAssignDB.lists[M.currentList][M.prio]
	if list ~= nil then
		for _, assignment in ipairs(list) do
			if assignment.name ~= "" and assignment.assignment ~= "" then
				SendChatMessage(assignment.name .. ": " .. assignment.assignment, "RAID")
			end
		end
	else
		print("List not found")
	end
end

M.deleteList = function(listName)
	EZAssignDB.lists[listName] = nil
	for name, _ in pairs(EZAssignDB.lists) do
		M.currentList = name
		break
	end
	M.mainFrame.Title:SetText(M.currentList)
	M.CreateListDropDowns()
	M.displayList(M.currentList)
end

-- opts = {
--  name,
--  onTextChanged,
--  width,
--  justifyH,
--  parent
-- }
-- set point after creation
M.createInputBox = function(opts)
	local textBox = CreateFrame(
		"EditBox",
		"EZAssign_TextBox_" .. opts.name,
		opts.parent or M.mainFrame.ScrollChild,
		"InputBoxTemplate"
	)
	textBox:SetAutoFocus(false)
	textBox:SetFontObject("GameFontHighlightSmall")
	textBox:SetHeight(22)
	textBox:SetWidth(opts.width or 120)
	textBox:SetJustifyH(opts.justifyH or "LEFT")
	textBox:EnableMouse(true)
	textBox:SetMaxLetters(240)
	textBox:SetTextInsets(0, 5, 2, 0)
	textBox:SetText(opts.text or "")
	textBox:HookScript("OnTextChanged", opts.onTextChanged)
	return textBox
end

-- ASSIGNMENT TEXT --

M.assignmentTextFrame = CreateFrame("Frame", "EZAssignAssignment", UIParent, "BasicFrameTemplateWithInset")
M.assignmentTextFrame:SetSize(250, 150)
M.assignmentTextFrame:SetPoint("CENTER", 0, 0)
M.assignmentTextFrame:EnableMouse(true)
M.assignmentTextFrame:SetMovable(true)
M.assignmentTextFrame:RegisterForDrag("LeftButton")
M.assignmentTextFrame:SetScript("OnDragStart", M.assignmentTextFrame.StartMoving)
M.assignmentTextFrame:SetScript("OnDragStop", M.assignmentTextFrame.StopMovingOrSizing)

M.assignmentTextFrame.Title = M.assignmentTextFrame:CreateFontString(nil, "OVERLAY")
M.assignmentTextFrame.Title:SetFontObject("GameFontHighlight")
M.assignmentTextFrame.Title:SetPoint("CENTER", M.assignmentTextFrame.TitleBg, "CENTER", 11, 0)
M.assignmentTextFrame.Title:SetText("My Assignments")
M.assignmentTextFrame:Hide()

M.assignmentText = M.assignmentTextFrame:CreateFontString("EZAssignFrameContent", "OVERLAY", normalFont)
M.assignmentText:SetPoint("TOPLEFT", 12, -32)
M.assignmentText:SetJustifyH("LEFT")
M.assignmentText:SetJustifyV("TOP")
M.assignmentText:SetWidth(M.assignmentTextFrame:GetWidth() - 44)
M.assignmentText:SetNonSpaceWrap(true)
M.assignmentText:SetFont(STANDARD_TEXT_FONT, 14)
M.assignmentText:SetSpacing(5)
M.assignmentText:SetText("No assignments")

M.UpdateAssignment = function()
	local msg = ""
	for i, assignment in ipairs(M.myAssignments) do
		if assignment ~= "" then
			msg = msg .. i .. ": " .. assignment .. "\n"
		end
	end
	M.assignmentText:SetText(msg)
	local height = M.assignmentText:GetHeight()
	M.assignmentTextFrame:SetHeight(M.Max(height * 1.3, 150))
	M.assignmentTextFrame:Show()
end

M.assignmentTextFrame:RegisterEvent("CHAT_MSG_RAID")
M.assignmentTextFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
M.assignmentTextFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
M.assignmentTextFrame:SetScript("OnEvent", function(self, event, msg, ...)
	local prioReset = msg:match("ASSIGNMENTS SET .- (%d+)$")
	if prioReset then
		M.givenPrio = tonumber(prioReset)
		return
	end
	local myName = UnitName("player")
	local name, str = msg:match("^(.+): (.+)$")
	local filtered = str:gsub("[{}]", "")
	if name ~= myName then
		return
	end
	M.myAssignments[M.givenPrio] = filtered
	if str then
		M.UpdateAssignment()
	end
end)

-- User interface

M.mainFrame = CreateFrame("Frame", "EZAssignMainFrame", RaidFrame, "BasicFrameTemplateWithInset")
M.mainFrame:SetSize(800, RaidFrame:GetHeight() + 420)
M.mainFrame:SetPoint("LEFT", RaidFrame, "RIGHT", 10, 0)
M.mainFrame.Title = M.mainFrame:CreateFontString(nil, "OVERLAY")
M.mainFrame.Title:SetFontObject("GameFontHighlight")
M.mainFrame.Title:SetPoint("CENTER", M.mainFrame.TitleBg, "CENTER", 11, 0)
M.mainFrame.Title:SetText("Default Assignments")
M.mainFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, M.mainFrame, "UIPanelScrollFrameTemplate")
M.mainFrame.ScrollFrame:SetPoint("TOPLEFT", M.mainFrame, "TOPLEFT", -26, -28)
M.mainFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", M.mainFrame, "BOTTOMRIGHT", -31, 6)
M.mainFrame.ScrollChild = CreateFrame("Frame", nil, M.mainFrame.ScrollFrame)
M.mainFrame.ScrollChild:SetSize(M.mainFrame:GetWidth(), M.mainFrame:GetHeight() - 100)
M.mainFrame.ScrollFrame:SetScrollChild(M.mainFrame.ScrollChild)

M.ListNameInput = CreateFrame("EditBox", "EZAssign_List_Name", M.mainFrame.ScrollChild, "InputBoxTemplate")
M.ListNameInput:SetAutoFocus(false)
M.ListNameInput:SetFontObject("GameFontHighlightSmall")
M.ListNameInput:SetHeight(22)
M.ListNameInput:SetWidth(string.len(M.currentList) * 6)
M.ListNameInput:SetJustifyH("LEFT")
M.ListNameInput:EnableMouse(true)
M.ListNameInput:SetMaxLetters(240)
M.ListNameInput:SetTextInsets(0, 5, 2, 0)
M.ListNameInput:SetText(M.currentList)
M.ListNameInput:SetPoint("TOPLEFT", M.mainFrame.ScrollChild, "TOPLEFT", 42, 0)

M.ListNameSaveButton = CreateFrame("Button", "EzAssignLisNameSaveButton", M.ListNameInput, "GameMenuButtonTemplate")
M.ListNameSaveButton:SetText("Save List Name")
M.ListNameSaveButton:SetSize(120, 22)
M.ListNameSaveButton:SetPoint("LEFT", M.ListNameInput, "RIGHT", 10, 0)
M.ListNameSaveButton:HookScript("OnClick", function()
	local newName = M.ListNameInput:GetText()
	if newName == "" then
		print("List must have a name")
		return
	end
	EZAssignDB.lists[newName] = EZAssignDB.lists[M.currentList]
	EZAssignDB.lists[M.currentList] = nil
	M.currentList = newName
	M.CreateListDropDowns()
	M.displayList(M.currentList)
end)

M.nameLabel = M.mainFrame.ScrollChild:CreateFontString("EZAssignFrameNameLabel", "OVERLAY", normalFont)
M.nameLabel:SetPoint("TOPLEFT", 40, -34)
M.nameLabel:SetJustifyH("LEFT")
M.nameLabel:SetJustifyV("TOP")
M.nameLabel:SetWidth(120)
M.nameLabel:SetFont(STANDARD_TEXT_FONT, 12)
M.nameLabel:SetSpacing(5)
M.nameLabel:SetText("Name")

M.assignmentLabel = M.mainFrame.ScrollChild:CreateFontString("EZAssignFrameAssignmentLabel", "OVERLAY", normalFont)
M.assignmentLabel:SetPoint("TOPLEFT", 180, -34)
M.assignmentLabel:SetJustifyH("LEFT")
M.assignmentLabel:SetJustifyV("TOP")
M.assignmentLabel:SetWidth(200)
M.assignmentLabel:SetFont(STANDARD_TEXT_FONT, 12)
M.assignmentLabel:SetSpacing(5)
M.assignmentLabel:SetText("Assignment")

M.assignmentLabel = M.mainFrame.ScrollChild:CreateFontString("EZAssignFrameAssignmentLabel", "OVERLAY", normalFont)
M.assignmentLabel:SetPoint("TOPRIGHT", -20, -34)
M.assignmentLabel:SetJustifyH("RIGHT")
M.assignmentLabel:SetJustifyV("TOP")
M.assignmentLabel:SetWidth(250)
M.assignmentLabel:SetFont(STANDARD_TEXT_FONT, 12)
M.assignmentLabel:SetSpacing(5)
M.assignmentLabel:SetText("To delete: /ezdelete NameOfList")

M.modifyAssignmentName = function(idx, name)
	if not EZAssignDB.lists[M.currentList][M.prio][idx] then
		EZAssignDB.lists[M.currentList][M.prio][idx] = {}
	end
	EZAssignDB.lists[M.currentList][M.prio][idx].name = name
end

M.modifyAssignment = function(idx, assignment)
	if not EZAssignDB.lists[M.currentList][M.prio][idx] then
		EZAssignDB.lists[M.currentList][M.prio][idx] = {}
	end
	EZAssignDB.lists[M.currentList][M.prio][idx].assignment = assignment
end

M.tabPressed = function(self)
	if IsShiftKeyDown() then
		self:ClearFocus() -- Shift+Tab goes to the previous input
		self.prevInput:SetFocus()
	else
		self:ClearFocus() -- Tab goes to the next input
		self.nextInput:SetFocus()
	end
end

M.createListInputs = function()
	for i = 1, 40 do
		local name = "EZAssign_NameInput_" .. i
		local default = ""
		if EZAssignDB.lists[M.currentList][M.prio][i] then
			default = EZAssignDB.lists[M.currentList][M.prio][i].name or ""
		end
		local textBox = M.createInputBox({
			text = default,
			name = name,
			onTextChanged = function(self, userInput)
				if userInput then
					M.modifyAssignmentName(i, self:GetText())
				end
			end,
		})
		textBox:SetPoint("TOPLEFT", 42, -25 * i - 30)
		table.insert(M.nameInputs, textBox)
	end
	for i = 1, 40 do
		local name = "EZAssign_AssignmentInput_" .. i
		local default = ""
		if EZAssignDB.lists[M.currentList][M.prio][i] then
			default = EZAssignDB.lists[M.currentList][M.prio][i].assignment or ""
		end
		local textBox = M.createInputBox({
			text = default,
			width = 595,
			name = name,
			onTextChanged = function(self, userInput)
				if userInput then
					M.modifyAssignment(i, self:GetText())
				end
			end,
		})
		textBox:SetPoint("TOPLEFT", 42 + 145, -25 * i - 30)
		table.insert(M.assignmentInputs, textBox)
	end
	for i = 1, 40 do
		M.nameInputs[i]:SetScript("OnTabPressed", M.tabPressed)
		M.nameInputs[i].nextInput = M.assignmentInputs[i]
		M.nameInputs[i].prevInput = M.assignmentInputs[i - 1] or M.assignmentInputs[40]
		M.assignmentInputs[i]:SetScript("OnTabPressed", M.tabPressed)
		M.assignmentInputs[i].nextInput = M.nameInputs[i + 1] or M.nameInputs[1]
		M.assignmentInputs[i].prevInput = M.nameInputs[i]
	end
end

M.togglePrio = function(newPrio)
	M.prio = newPrio
	for i, item in pairs(M.prioButtons) do
		if i == M.prio then
			item.button:SetNormalTexture(item.highlight)
		else
			item.button:SetNormalTexture(item.button:CreateTexture())
		end
	end
end

M.createPrioButtons = function()
	M.prioButtons = {}
	for i = 1, 5 do
		local toggleButton = CreateFrame("Button", "EzAssignPrioButton_" .. i, M.mainFrame, "GameMenuButtonTemplate")
		local highlightTexture = toggleButton:GetHighlightTexture()
		toggleButton:SetText("Priority " .. i)
		toggleButton:SetSize(120, 22)
		toggleButton:SetPoint("TOPLEFT", M.mainFrame, "TOPLEFT", (i - 1) * 120, 22)
		toggleButton:HookScript("OnClick", function(self)
			M.togglePrio(i)
			M.displayList(M.currentList)
		end)
		table.insert(M.prioButtons, { button = toggleButton, highlight = highlightTexture })
	end
	M.togglePrio(M.prio)
end

-- TOGGLE BUTTON

M.toggleButton = CreateFrame("Button", "EzAssignToggleButton", RaidFrame, "GameMenuButtonTemplate")
M.toggleButton:SetText("Hide EZ Assign")
M.toggleButton:SetSize(120, 22)
M.toggleButton:SetPoint("TOPRIGHT", RaidFrame, "TOPRIGHT", 0, 22)
M.toggleButton:HookScript("OnClick", function()
	if M.mainFrame:IsShown() then
		M.mainFrame:Hide()
		M.toggleButton:SetText("Show EZ Assign")
	else
		EZAssignDB.prio = EZAssignDB.prio or 1
		M.mainFrame:Show()
		M.toggleButton:SetText("Hide EZ Assign")
	end
end)

M.showMyAssignmentsButton = CreateFrame("Button", "EzAssignToggleButton", M.toggleButton, "GameMenuButtonTemplate")
M.showMyAssignmentsButton:SetText("My Assignments")
M.showMyAssignmentsButton:SetSize(120, 22)
M.showMyAssignmentsButton:SetPoint("RIGHT", M.toggleButton, "LEFT", 0, 0)
M.showMyAssignmentsButton:HookScript("OnClick", function()
	if M.assignmentTextFrame:IsShown() then
		M.assignmentTextFrame:Hide()
	else
		M.assignmentTextFrame:Show()
	end
end)

M.IssueAssignmentsButton = CreateFrame("Button", "EzAssignToggleButton", M.mainFrame, "GameMenuButtonTemplate")
M.IssueAssignmentsButton:SetText("Issue Assignments")
M.IssueAssignmentsButton:SetSize(150, 22)
M.IssueAssignmentsButton:SetPoint("TOPRIGHT", M.mainFrame, "TOPRIGHT", 0, 22)
M.IssueAssignmentsButton:HookScript("OnClick", function()
	SendChatMessage("ASSIGNMENTS SET - " .. M.currentList .. " - " .. M.prio, "RAID_WARNING")
	M.assignList()
end)

M.newListButton = CreateFrame("Button", "EzAssignToggleButton", M.mainFrame, "GameMenuButtonTemplate")
M.newListButton:SetText("Create New List")
M.newListButton:SetSize(150, 22)
M.newListButton:SetPoint("TOPRIGHT", M.mainFrame, "BOTTOMRIGHT", 0, 0)
M.newListButton:HookScript("OnClick", function()
	if EZAssignDB.lists[M.newListInput:GetText()] then
		print("List already exists")
		return
	end
	M.createList(M.newListInput:GetText())
	M.currentList = M.newListInput:GetText()
	M.togglePrio(1)
	M.CreateListDropDowns()
	M.displayList(M.currentList)
	M.newListInput:SetText("")
end)

M.newListInput = M.createInputBox({
	name = "EZAssign_CreateListInput",
	parent = M.newListButton,
	width = 120,
	onTextChanged = function(self, userInput)
		if userInput then
			M.modifyListName(self:GetText())
		end
	end,
})
M.newListInput:SetPoint("RIGHT", M.newListButton, "LEFT", 0, 0)

M.displayList = function(listName)
	local list = EZAssignDB.lists[listName][M.prio] or {}
	M.currentList = listName
	M.mainFrame.Title:SetText(listName .. " Assignments")
	M.ListNameInput:SetText(listName)
	M.ListNameInput:SetWidth(M.Max(string.len(M.currentList) * 9, 120))
	for i, item in pairs(M.nameInputs) do
		if list[i] ~= nil then
			item:SetText(list[i].name or "")
		else
			item:SetText("")
		end
	end
	for i, item in pairs(M.assignmentInputs) do
		if list[i] ~= nil then
			item:SetText(list[i].assignment or "")
		else
			item:SetText("")
		end
	end
end

M.CreateListDropDowns = function()
	if M.listDD then
		M.listDD:Hide()
		M.listDD = nil
	end
	local listNames = {}
	for k in pairs(EZAssignDB.lists) do
		table.insert(listNames, k)
	end
	table.sort(listNames)
	local ddSetup = {
		["name"] = "EZAssign_ListDropDown",
		["parent"] = M.mainFrame.ScrollChild,
		["items"] = listNames,
		["defaultVal"] = M.currentList,
		["changeFunc"] = function(dropdown_frame, dropdown_val)
			M.displayList(dropdown_val)
		end,
	}
	M.listDD = createDropdown(ddSetup)
	M.listDD:SetPoint("TOPRIGHT", M.mainFrame.ScrollChild, "TOPRIGHT", -5, 0)
end

M.mainFrame:RegisterEvent("CHAT_MSG_RAID")
M.mainFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")

local addonF = CreateFrame("Frame")
addonF:RegisterEvent("CHAT_MSG_ADDON")
addonF:RegisterEvent("ADDON_LOADED")
addonF:SetScript("OnEvent", function(self, event, ...)
	local arg1, command = ...
	if arg1 == "EZAssign" then
		if event == "ADDON_LOADED" then
			if EZAssignDB.lists.Default then
				M.currentList = "Default"
			else
				for k in pairs(EZAssignDB.lists) do
					M.currentList = k
				end
			end
			M.CreateListDropDowns()
			M.createListInputs()
			M.createPrioButtons()
			M.displayList(M.currentList)
		end
	end
end)

SlashCmdList["RESET"] = M.resetCurrentAssignments
SlashCmdList["RESETDB"] = M.resetDB
SlashCmdList["DB"] = function()
	print("-----------------------")
	printTableValues(EZAssignDB)
	print("-----------------------")
end
SlashCmdList["CREATELIST"] = M.createList
SlashCmdList["DELETELIST"] = M.deleteList
SlashCmdList["ASSIGNLIST"] = M.assignList
