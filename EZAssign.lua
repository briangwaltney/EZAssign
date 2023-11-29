SLASH_RESET1 = "/ezreset"
SLASH_RESETDB1 = "/ezresetdb"
SLASH_DB1 = "/ezdb"
SLASH_DELETELIST1 = "/ezdelete"
SLASH_ASSIGNLIST1 = "/ezassignlist"
SLASH_SHOWFRAME1 = "/ezshow"

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
local M = {
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

M.resetCurrentAssignments = function()
	for i = 1, 5 do
		M.myAssignments[i] = ""
	end
end

M.sendReset = function()
	SendAddonMessage("EZAssign", "reset", "RAID")
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

M.UpdateAssignment = function()
	local msg = ""
	for i, assignment in ipairs(M.myAssignments) do
		if assignment ~= "" then
			msg = msg .. i .. ": " .. assignment .. "\n"
		end
	end
	M.MyAssignmentsText:SetText(msg)
	local height = M.MyAssignmentsText:GetHeight()
	M.MyAssignmentsFrame:SetHeight(M.Max(height * 1.3, 150))
	M.MyAssignmentsFrame:Show()
end

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
		textBox:SetPoint("TOPLEFT", 42, -25 * (i - 1))
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
		textBox:SetPoint("TOPLEFT", 42 + 145, -25 * (i - 1))
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

M.displayList = function(listName)
	local list = EZAssignDB.lists[listName][M.prio] or {}
	M.currentList = listName
	M.mainFrame.Title:SetText(listName .. " Assignments")
	M.EditListNameInput:SetText(listName)
	M.EditListNameInput:SetWidth(M.Max(string.len(M.currentList) * 9, 120))
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

M.MyAssignmentsFrame = CreateFrame("Frame", "EZAssignAssignment", UIParent, "BasicFrameTemplateWithInset")
M.MyAssignmentsFrame:SetSize(250, 150)
M.MyAssignmentsFrame:SetPoint("CENTER", 0, 0)
M.MyAssignmentsFrame:EnableMouse(true)
M.MyAssignmentsFrame:SetMovable(true)
M.MyAssignmentsFrame:RegisterForDrag("LeftButton")
M.MyAssignmentsFrame:SetScript("OnDragStart", M.MyAssignmentsFrame.StartMoving)
M.MyAssignmentsFrame:SetScript("OnDragStop", M.MyAssignmentsFrame.StopMovingOrSizing)

M.MyAssignmentsFrame.Title = M.MyAssignmentsFrame:CreateFontString(nil, "OVERLAY")
M.MyAssignmentsFrame.Title:SetFontObject("GameFontHighlight")
M.MyAssignmentsFrame.Title:SetPoint("CENTER", M.MyAssignmentsFrame.TitleBg, "CENTER", 11, 0)
M.MyAssignmentsFrame.Title:SetText("My Assignments")
M.MyAssignmentsFrame:Hide()

M.MyAssignmentsFrame:RegisterEvent("CHAT_MSG_RAID")
M.MyAssignmentsFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
M.MyAssignmentsFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
M.MyAssignmentsFrame:SetScript("OnEvent", function(_, _, msg)
	local prioReset = msg:match("ASSIGNMENTS SET .- (%d+)$")
	if prioReset then
		M.givenPrio = tonumber(prioReset)
		if M.givenPrio == 1 then
			M.resetCurrentAssignments()
		end
		return
	end
	local myName = UnitName("player")
	local name, str = msg:match("^(.+): (.+)$")
	if not str then
		return
	end
	local filtered = str:gsub("[{}]", "")
	if name ~= myName then
		return
	end
	M.myAssignments[M.givenPrio] = filtered
	if str then
		M.UpdateAssignment()
	end
end)

M.MyAssignmentsText = M.MyAssignmentsFrame:CreateFontString("EZAssignFrameContent", "OVERLAY", normalFont)
M.MyAssignmentsText:SetPoint("TOPLEFT", 12, -32)
M.MyAssignmentsText:SetJustifyH("LEFT")
M.MyAssignmentsText:SetJustifyV("TOP")
M.MyAssignmentsText:SetWidth(M.MyAssignmentsFrame:GetWidth() - 44)
M.MyAssignmentsText:SetNonSpaceWrap(true)
M.MyAssignmentsText:SetFont(STANDARD_TEXT_FONT, 14)
M.MyAssignmentsText:SetSpacing(5)
M.MyAssignmentsText:SetText("No assignments")

M.toggleButton = CreateFrame("Button", "EzAssignToggleButton", RaidFrame, "GameMenuButtonTemplate")
M.toggleButton:SetText("Show EZ Assign")
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
	if M.MyAssignmentsFrame:IsShown() then
		M.MyAssignmentsFrame:Hide()
	else
		M.MyAssignmentsFrame:Show()
	end
end)

M.mainFrame = CreateFrame("Frame", "EZAssignMainFrame", UIParent, "BasicFrameTemplateWithInset")
M.mainFrame:SetSize(800, RaidFrame:GetHeight() + 420)
M.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
M.mainFrame.Title = M.mainFrame:CreateFontString(nil, "OVERLAY")
M.mainFrame.Title:SetFontObject("GameFontHighlight")
M.mainFrame.Title:SetPoint("CENTER", M.mainFrame.TitleBg, "CENTER", 11, 0)
M.mainFrame.Title:SetText("Default Assignments")
M.mainFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, M.mainFrame, "UIPanelScrollFrameTemplate")
M.mainFrame.ScrollFrame:SetPoint("TOPLEFT", M.mainFrame, "TOPLEFT", -26, -80)
M.mainFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", M.mainFrame, "BOTTOMRIGHT", -31, 6)
M.mainFrame.ScrollChild = CreateFrame("Frame", nil, M.mainFrame.ScrollFrame)
M.mainFrame.ScrollChild:SetSize(M.mainFrame.ScrollFrame:GetWidth(), M.mainFrame.ScrollFrame:GetHeight())
M.mainFrame.ScrollFrame:SetScrollChild(M.mainFrame.ScrollChild)
M.mainFrame:EnableMouse(true)
M.mainFrame:SetMovable(true)
M.mainFrame:RegisterForDrag("LeftButton")
M.mainFrame:SetScript("OnDragStart", M.mainFrame.StartMoving)
M.mainFrame:SetScript("OnDragStop", M.mainFrame.StopMovingOrSizing)
M.mainFrame:Hide()

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

M.ListDropdownFrame = CreateFrame("Frame", "EZAssign_DropdownFrame", M.mainFrame, "InsetFrameTemplate")
M.ListDropdownFrame:SetSize(300, 300)
M.ListDropdownFrame:SetPoint("TOPRIGHT", M.mainFrame, "TOPRIGHT", -30, -40)
M.ListDropdownFrame:SetFrameStrata("DIALOG")
M.ListDropdownFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, M.ListDropdownFrame, "UIPanelScrollFrameTemplate")
M.ListDropdownFrame.ScrollFrame:SetPoint("TOPLEFT", M.ListDropdownFrame, "TOPLEFT", -26, -6)
M.ListDropdownFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", M.ListDropdownFrame, "BOTTOMRIGHT", -28, 6)
M.ListDropdownFrame.ScrollChild = CreateFrame("Frame", nil, M.ListDropdownFrame.ScrollFrame)
M.ListDropdownFrame.ScrollChild:SetSize(M.ListDropdownFrame:GetWidth(), M.ListDropdownFrame:GetHeight() - 100)
M.ListDropdownFrame.ScrollFrame:SetScrollChild(M.ListDropdownFrame.ScrollChild)
M.ListDropdownFrame:Hide()

M.EditListNameInput = CreateFrame("EditBox", "EZAssign_List_Name", M.mainFrame, "InputBoxTemplate")
M.EditListNameInput:SetAutoFocus(false)
M.EditListNameInput:SetFontObject("GameFontHighlightSmall")
M.EditListNameInput:SetHeight(22)
M.EditListNameInput:SetWidth(string.len(M.currentList) * 6)
M.EditListNameInput:SetJustifyH("LEFT")
M.EditListNameInput:EnableMouse(true)
M.EditListNameInput:SetMaxLetters(240)
M.EditListNameInput:SetTextInsets(0, 5, 2, 0)
M.EditListNameInput:SetText(M.currentList)
M.EditListNameInput:SetPoint("TOPLEFT", M.mainFrame, "TOPLEFT", 15, -30)

M.SaveListNameButton = CreateFrame("Button", "EzAssignLisNameSaveButton", M.EditListNameInput, "GameMenuButtonTemplate")
M.SaveListNameButton:SetText("Save List Name")
M.SaveListNameButton:SetSize(120, 22)
M.SaveListNameButton:SetPoint("LEFT", M.EditListNameInput, "RIGHT", 10, 0)
M.SaveListNameButton:HookScript("OnClick", function()
	local newName = M.EditListNameInput:GetText()
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

M.headerName = M.mainFrame:CreateFontString("EZAssignFrameNameLabel", "OVERLAY", normalFont)
M.headerName:SetPoint("TOPLEFT", 15, -55)
M.headerName:SetJustifyH("LEFT")
M.headerName:SetJustifyV("TOP")
M.headerName:SetWidth(120)
M.headerName:SetFont(STANDARD_TEXT_FONT, 12)
M.headerName:SetSpacing(5)
M.headerName:SetText("Name")

M.headerAssignment = M.mainFrame:CreateFontString("EZAssignFrameAssignmentLabel", "OVERLAY", normalFont)
M.headerAssignment:SetPoint("TOPLEFT", 155, -55)
M.headerAssignment:SetJustifyH("LEFT")
M.headerAssignment:SetJustifyV("TOP")
M.headerAssignment:SetWidth(200)
M.headerAssignment:SetFont(STANDARD_TEXT_FONT, 12)
M.headerAssignment:SetSpacing(5)
M.headerAssignment:SetText("Assignment")

M.headerDeleteList = M.mainFrame:CreateFontString("EZAssignFrameAssignmentLabel", "OVERLAY", normalFont)
M.headerDeleteList:SetPoint("TOPRIGHT", -40, -55)
M.headerDeleteList:SetJustifyH("RIGHT")
M.headerDeleteList:SetJustifyV("TOP")
M.headerDeleteList:SetWidth(250)
M.headerDeleteList:SetFont(STANDARD_TEXT_FONT, 12)
M.headerDeleteList:SetSpacing(5)
M.headerDeleteList:SetText("To delete: /ezdelete NameOfList")

M.IssueAssignmentsButton = CreateFrame("Button", "EzAssignToggleButton", M.mainFrame, "GameMenuButtonTemplate")
M.IssueAssignmentsButton:SetText("Issue Assignments")
M.IssueAssignmentsButton:SetSize(150, 22)
M.IssueAssignmentsButton:SetPoint("TOPRIGHT", M.mainFrame, "TOPRIGHT", 0, 22)
M.IssueAssignmentsButton:HookScript("OnClick", function()
	SendChatMessage("ASSIGNMENTS SET - " .. M.currentList .. " - " .. M.prio, "RAID_WARNING")
	M.assignList()
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

M.ListDropdownToggle = CreateFrame("Button", "EzAssignDropDownToggle", M.mainFrame, "GameMenuButtonTemplate")
M.ListDropdownToggle:SetText("Change List")
M.ListDropdownToggle:SetSize(120, 22)
M.ListDropdownToggle:SetPoint("TOPRIGHT", M.mainFrame, "TOPRIGHT", -40, -30)
M.ListDropdownToggle:HookScript("OnClick", function()
	if M.ListDropdownFrame:IsShown() then
		M.ListDropdownFrame:Hide()
	else
		M.ListDropdownFrame:Show()
	end
end)

M.CreateDropDownButton = function(listName)
	local button = CreateFrame(
		"Button",
		"EzAssignDropDownButton_" .. listName,
		M.ListDropdownFrame.ScrollChild,
		"GameMenuButtonTemplate"
	)
	button:SetText(listName)
	button:SetSize(270, 22)
	button:HookScript("OnClick", function()
		M.togglePrio(1)
		M.displayList(listName)
		M.ListDropdownFrame:Hide()
	end)
	return button
end

M.CreateListDropDowns = function()
	if M.listDDs then
		for _, dd in ipairs(M.listDDs) do
			dd:Hide()
		end
	else
		M.listDDs = {}
	end
	local listNames = {}
	for k in pairs(EZAssignDB.lists) do
		table.insert(listNames, k)
	end
	table.sort(listNames)
	for i, list in ipairs(listNames) do
		local button = M.CreateDropDownButton(list)
		button:SetPoint("TOPLEFT", M.ListDropdownFrame.ScrollChild, "TOPLEFT", 30, -22 * (i - 1))
		table.insert(M.listDDs, button)
	end
end

M.mainFrame:RegisterEvent("CHAT_MSG_RAID")
M.mainFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")

local addonF = CreateFrame("Frame")
addonF:RegisterEvent("CHAT_MSG_ADDON")
addonF:RegisterEvent("ADDON_LOADED")
addonF:SetScript("OnEvent", function(_, event, ...)
	local arg1 = ...
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

SlashCmdList["RESETDB"] = M.resetDB
SlashCmdList["DB"] = function()
	print("-----------------------")
	printTableValues(EZAssignDB)
	print("-----------------------")
end
SlashCmdList["CREATELIST"] = M.createList
SlashCmdList["DELETELIST"] = M.deleteList
SlashCmdList["ASSIGNLIST"] = M.assignList
SlashCmdList["SHOWFRAME"] = function()
	M.mainFrame:Show()
end
