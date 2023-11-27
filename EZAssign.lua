SLASH_ASSIGN1 = "/ez"
SLASH_ASSIGN2 = "/assign"
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
			prio = 1,
			assignments = {},
		},
	},
	prio = 1,
}

EZAssignDB = EZAssignDB or defaultDB
M = {
	listButtons = {},
	nameInputs = {},
	assignmentInputs = {},
	currentList = "Default",
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

local SendAddonMessage = C_ChatInfo.SendAddonMessage

M.createList = function(name)
	local prio = EZAssignDB.prio
	EZAssignDB.lists[name] = {
		prio = prio,
		assignments = {},
	}
end

M.assignIndividual = function(msg)
	local name = UnitName("target")
	SendChatMessage("ASSIGN " .. name .. " 1: " .. msg, "RAID")
end

M.assignList = function()
	local list = EZAssignDB.lists[M.currentList]
	if list ~= nil then
		for _, assignment in ipairs(list.assignments) do
			SendChatMessage("ASSIGN " .. assignment.name .. " " .. list.prio .. ": " .. assignment.assignment, "RAID")
		end
	else
		print("List not found")
	end
end

M.deleteList = function(list)
	if EZAssignDB.lists[list] then
		EZAssignDB.lists[list] = nil
		M.createListButtons()
	end
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
	textBox:SetMaxLetters(2500)
	textBox:SetTextInsets(0, 5, 2, 0)
	textBox:SetText(opts.text or "")
	textBox:HookScript("OnTextChanged", opts.onTextChanged)
	return textBox
end

-- ASSIGNMENT TEXT --

M.assignmentTextFrame = CreateFrame("Frame", "EZAssignAssignment", UIParent, "BasicFrameTemplateWithInset")
M.assignmentTextFrame:SetSize(200, 75)
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
M.assignmentText:SetWordWrap(true)
M.assignmentText:SetIndentedWordWrap(false)
M.assignmentText:SetNonSpaceWrap(true)
M.assignmentText:SetFont(STANDARD_TEXT_FONT, 14)
M.assignmentText:SetSpacing(5)
M.assignmentText:SetText("No assignments")
M.assignmentText:SetHeight(56)

M.UpdateAssignment = function()
	local length = 0
	local lines = 0
	local msg = ""
	for i, assignment in ipairs(M.myAssignments) do
		if string.len(assignment) > 0 then
			length = length + string.len(assignment)
			lines = lines + math.ceil(string.len(assignment) / 20)
			msg = msg .. i .. ": " .. assignment .. "\n"
		end
	end
	local height = 35 + (lines * 21)
	M.assignmentTextFrame:SetSize(200, height)
	M.assignmentText:SetText(msg)
	M.assignmentTextFrame:Show()
end

M.assignmentTextFrame:RegisterEvent("CHAT_MSG_RAID")
M.assignmentTextFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
M.assignmentTextFrame:SetScript("OnEvent", function(self, event, msg, ...)
	local myName = UnitName("player")
	local pattern = "^ASSIGN " .. myName .. " "
	local msgWithNum = string.match(msg, pattern) and string.sub(msg, string.len(string.match(msg, pattern)) + 1)
	local num, str = string.match(msgWithNum, "^(%d):%s(.+)$")
	local filtered = str:gsub("[{}]", "")
	num = tonumber(num)
	if not num then
		return
	end
	M.myAssignments[num] = filtered
	if num and str then
		M.UpdateAssignment()
	end
end)

-- User interface

M.mainFrame = CreateFrame("Frame", "EZAssignMainFrame", RaidFrame, "BasicFrameTemplateWithInset")
M.mainFrame:SetSize(600, RaidFrame:GetHeight() + 420)
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

M.nameLabel = M.mainFrame.ScrollChild:CreateFontString("EZAssignFrameNameLabel", "OVERLAY", normalFont)
M.nameLabel:SetPoint("TOPLEFT", 40, -4)
M.nameLabel:SetJustifyH("LEFT")
M.nameLabel:SetJustifyV("TOP")
M.nameLabel:SetWidth(120)
M.nameLabel:SetFont(STANDARD_TEXT_FONT, 12)
M.nameLabel:SetSpacing(5)
M.nameLabel:SetText("Name")

M.assignmentLabel = M.mainFrame.ScrollChild:CreateFontString("EZAssignFrameAssignmentLabel", "OVERLAY", normalFont)
M.assignmentLabel:SetPoint("TOPLEFT", 180, -4)
M.assignmentLabel:SetJustifyH("LEFT")
M.assignmentLabel:SetJustifyV("TOP")
M.assignmentLabel:SetWidth(200)
M.assignmentLabel:SetFont(STANDARD_TEXT_FONT, 12)
M.assignmentLabel:SetSpacing(5)
M.assignmentLabel:SetText("Assignment")

M.deleteListButton = CreateFrame("Button", "EZAssignDeleteListButton", M.mainFrame, "UIPanelButtonTemplate")
M.deleteListButton:SetSize(80, 18)
M.deleteListButton:SetPoint("TOPRIGHT", M.mainFrame, "TOPRIGHT", -40, -30)
M.deleteListButton:SetText("Delete List")
M.deleteListButton:SetScript("OnClick", function()
	EZAssignDB.lists[M.currentList] = nil
	for name, _ in pairs(EZAssignDB.lists) do
		M.currentList = name
		break
	end
	M.mainFrame.Title:SetText(M.currentList)
	M.displayList(M.currentList)
	M.createListButtons()
end)

M.modifyAssignmentName = function(idx, name)
	if not EZAssignDB.lists[M.currentList].assignments[idx] then
		EZAssignDB.lists[M.currentList].assignments[idx] = {}
	end
	EZAssignDB.lists[M.currentList].assignments[idx].name = name
end

M.modifyAssignment = function(idx, assignment)
	if not EZAssignDB.lists[M.currentList].assignments[idx] then
		EZAssignDB.lists[M.currentList].assignments[idx] = {}
	end
	EZAssignDB.lists[M.currentList].assignments[idx].assignment = assignment
end

M.createListInputs = function()
	for i = 1, 40 do
		local name = "EZAssign_NameInput_" .. i
		local default = ""
		if EZAssignDB.lists[M.currentList].assignments[i] then
			default = EZAssignDB.lists[M.currentList].assignments[i].name or ""
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
		textBox:SetPoint("TOPLEFT", 42, -25 * i)
		table.insert(M.nameInputs, textBox)
	end
	for i = 1, 40 do
		local name = "EZAssign_AssignmentInput_" .. i
		local default = ""
		if EZAssignDB.lists[M.currentList].assignments[i] then
			default = EZAssignDB.lists[M.currentList].assignments[i].assignment or ""
		end
		local textBox = M.createInputBox({
			text = default,
			width = 395,
			name = name,
			onTextChanged = function(self, userInput)
				if userInput then
					M.modifyAssignment(i, self:GetText())
				end
			end,
		})
		textBox:SetPoint("TOPLEFT", 42 + 145, -25 * i)
		table.insert(M.assignmentInputs, textBox)
	end
end

M.togglePrio = function()
	for i, item in pairs(M.prioButtons) do
		if i == EZAssignDB.prio then
			item.button:SetNormalTexture(item.highlight)
			EZAssignDB.lists[M.currentList].prio = i
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
		toggleButton:SetAttribute("normal", "hello")
		toggleButton:SetAttribute("highlight", "goodbye")
		toggleButton:SetText("Priority " .. i)
		toggleButton:SetSize(120, 22)
		toggleButton:SetPoint("TOPLEFT", M.mainFrame, "TOPLEFT", (i - 1) * 120, 22)
		toggleButton:HookScript("OnClick", function(self)
			EZAssignDB.prio = i
			M.togglePrio()
		end)
		table.insert(M.prioButtons, { button = toggleButton, highlight = highlightTexture })
	end
	M.togglePrio()
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
M.IssueAssignmentsButton:SetPoint("TOPRIGHT", M.mainFrame, "TOPRIGHT", 0, 44)
M.IssueAssignmentsButton:HookScript("OnClick", function()
	SendChatMessage("ASSIGMENTS SET", "RAID_WARNING")
	M.assignList(M.currentList)
end)

M.newListButton = CreateFrame("Button", "EzAssignToggleButton", M.mainFrame, "GameMenuButtonTemplate")
M.newListButton:SetText("Create New List")
M.newListButton:SetSize(150, 22)
M.newListButton:SetPoint("TOPRIGHT", M.mainFrame, "BOTTOMRIGHT", 0, 0)
M.newListButton:HookScript("OnClick", function()
	if EZAssignDB.lists[M.createListInput:GetText()] then
		print("List already exists")
		return
	end
	M.createList(M.createListInput:GetText())
	M.currentList = M.createListInput:GetText()
	M.displayList(M.currentList)
	M.createListButtons()
	M.createListInput:SetText("")
end)

M.createListInput = M.createInputBox({
	name = "EZAssign_CreateListInput",
	parent = M.newListButton,
	width = 120,
	onTextChanged = function(self, userInput)
		if userInput then
			M.modifyListName(self:GetText())
		end
	end,
})
M.createListInput:SetPoint("RIGHT", M.newListButton, "LEFT", 0, 0)

M.displayList = function(listName)
	local list = EZAssignDB.lists[listName]

	M.currentList = listName
	EZAssignDB.prio = list.prio or 1
	M.togglePrio()
	M.mainFrame.Title:SetText(listName .. " Assignments")
	for i, item in pairs(M.nameInputs) do
		if list.assignments[i] then
			item:SetText(list.assignments[i].name or "")
		else
			item:SetText("")
		end
	end
	for i, item in pairs(M.assignmentInputs) do
		if list.assignments[i] then
			item:SetText(list.assignments[i].assignment or "")
		else
			item:SetText("")
		end
	end

	for k, item in pairs(M.listButtons) do
		if k == listName then
			item.button:SetNormalTexture(item.highlight)
		else
			item.button:SetNormalTexture(item.button:CreateTexture())
		end
	end
end

M.createListButtons = function()
	local vertIdx = 1
	local horzIdx = 1
	for _, item in pairs(M.listButtons) do
		item.button:Hide()
		item.button:SetParent(nil)
	end

	local sortedKeys = {}
	for k in pairs(EZAssignDB.lists) do
		table.insert(sortedKeys, k)
	end

	table.sort(sortedKeys)

	for _, listName in pairs(sortedKeys) do
		local b = CreateFrame("Button", "EzAssignListButton" .. vertIdx, M.mainFrame, "GameMenuButtonTemplate")
		b:SetText(listName)
		b:SetSize(100, 22)
		b:SetPoint("TOPRIGHT", M.mainFrame, "TOPRIGHT", 100 * horzIdx, vertIdx * -22)
		b:HookScript("OnClick", function()
			M.displayList(listName)
		end)
		vertIdx = vertIdx + 1
		if vertIdx == 19 then
			vertIdx = 0
			horzIdx = horzIdx + 1
		end
		local highlightTexture = b:GetHighlightTexture()
		M.listButtons[listName] = { button = b, highlight = highlightTexture }
	end
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
			M.createListButtons()
			M.createListInputs()
			M.createPrioButtons()
			M.displayList(M.currentList)
		end
	end
end)

SlashCmdList["ASSIGN"] = M.assignIndividual
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
