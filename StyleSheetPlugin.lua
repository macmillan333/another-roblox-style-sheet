local ChangeHistoryService:ChangeHistoryService = game:GetService("ChangeHistoryService")
local CollectionService:CollectionService = game:GetService("CollectionService")
local Selection:Selection = game:GetService("Selection")
local StarterGui:StarterGui = game:GetService("StarterGui")

local toolbar:PluginToolbar = plugin:CreateToolbar("Style Sheets")

local verbose:boolean = true

local newQueue = function()
	return {
		data = {},
		first = 1,
		last = 1,
		size = function(self):number return self.last - self.first end,
		push = function(self, obj)
			self.data[self.last] = obj
			self.last += 1
		end,
		pop = function(self)
			assert(self:size() > 0)
			local value = self.data[self.first]
			self.first += 1
			return value
		end,
		clear = function(self)
			self.data = {}
			self.first = 1
			self.last = 1
		end
	}
end

local displayMessage = function(message:string)
	local widget:DockWidgetPluginGui = plugin:CreateDockWidgetPluginGui("TestWidget", DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		--[[InitialEnabled]] true,
		--[[InitialEnabledShouldOverrideRestore]] false,
		--[[FloatingXSize]] 500,
		--[[FloatingYSize]] 300,
		--[[MinWidth]] 500,
		--[[MinHeight]] 300))
	widget.Title = "Message"

	local messageText:TextLabel = Instance.new("TextLabel")
	messageText.AnchorPoint = Vector2.new(0.5, 0)
	messageText.Position = UDim2.new(0.5, 0, 0, 0)
	messageText.Size = UDim2.new(1, 0, 0.8, 0)
	messageText.TextWrapped = true
	messageText.Text = message
	messageText.Parent = widget

	local okButton:TextButton = Instance.new("TextButton")
	okButton.AnchorPoint = Vector2.new(0.5, 1)
	okButton.Position = UDim2.new(0.5, 0, 1, 0)
	okButton.Size = UDim2.new(1, 0, 0.2, 0)
	okButton.Text = "OK"
	okButton.Parent = widget
	okButton.Activated:Connect(function()
		widget:Destroy()
	end)
end

local printIfVerbose = function(string)
	if verbose then print(string) end
end

local parseSelector = function(selector:string):{string}
	-- Written by GPT-4o
	local parts = {}
	local current = ""
	local in_quotes = false
	local quote_char = nil

	for i = 1, #selector do
		local char = selector:sub(i, i)

		if in_quotes then
			-- If inside quotes, close if matching end quote, otherwise append to current
			if char == quote_char then
				in_quotes = false
			else
				current = current .. char
			end
		else
			if char == '"' or char == "'" then
				-- Start of quoted section
				in_quotes = true
				quote_char = char
			elseif char == " " then
				-- Space ends a current part unless inside quotes
				if #current > 0 then
					table.insert(parts, current)
					current = ""
				end
			else
				-- Normal character
				current = current .. char
			end
		end
	end

	-- Insert the last part if any
	if #current > 0 then
		table.insert(parts, current)
	end

	return parts
end

local instanceMatchesSelectorPart = function(i:Instance, part:string):boolean
	local firstChar = part:sub(1, 1)
	if firstChar == '#' then
		-- Match by instance name
		return i.Name == part:sub(2)
	elseif firstChar == '.' then
		-- Match by tag
		return i:HasTag(part:sub(2))
	else
		-- Match by class
		return i:IsA(part)
	end
end

local findDescendantsThatMatchSelectorPart = function(roots:{Instance}, part:string):{Instance}
	local descendants:{Instance} = {}
	local queue = newQueue()
	for _, root:Instance in roots do queue:push(root) end
	while queue:size() > 0 do
		local i:Instance = queue:pop()
		if instanceMatchesSelectorPart(i, part) then
			table.insert(descendants, i)
		end
		for _, child:Instance in i:GetChildren() do queue:push(child) end
	end
	return descendants
end

local findDescendantsThatMatchSelector = function(roots:{Instance}, selector:string):{Instance}
	local parts:{string} = parseSelector(selector)
	local descendants:{Instance} = roots
	for _, part in parts do
		descendants = findDescendantsThatMatchSelectorPart(descendants, part)
	end
	return descendants
end

local applyStyleTable = function(i:Instance, styleTable:table):boolean
	-- Shortcut for appearance modifiers
	-- https://create.roblox.com/docs/ui/appearance-modifiers
	local appearanceModifierClasses = {"UIGradient", "UIStroke", "UICorner", "UIPadding"}
	for _, modifierClass in appearanceModifierClasses do
		if styleTable[modifierClass] == nil then
			-- No specified modifier. If one exists, remove it.
			for _, child in i:GetChildren() do
				if child:IsA(modifierClass) then
					printIfVerbose("Removing " .. modifierClass .. " from " .. i.Name)
					child:Destroy()
				end
			end
		else
			-- Specified modifier exists. If none exists, create one.
			local modifierInstance = i:FindFirstChildOfClass(modifierClass)
			if modifierInstance == nil then
				printIfVerbose("Adding " .. modifierClass .. " to " .. i.Name)
				modifierInstance = Instance.new(modifierClass)
				modifierInstance.Parent = i
			end
			-- Apply styles
			for key:string, value in styleTable[modifierClass] do
				printIfVerbose(string.format("Applying to %s of %s: key=%s, value=%s", modifierClass, i.Name, key, tostring(value)))
				local success:boolean, errorMessage = pcall(function() modifierInstance[key] = value end)
				if not success then
					local fullMessage = string.format("An error occurred when applying the style sheet to %s of %s:\n\n%s\n\nNo changes were made.",
						modifierClass, i.Name, errorMessage)
					displayMessage(fullMessage)
					return false
				end
			end
		end
	end
	
	-- Other attributes
	for key:string, value in styleTable do
		if table.find(appearanceModifierClasses, key) ~= nil then continue end
		printIfVerbose(string.format("Applying to %s: key=%s, value=%s", i.Name, key, tostring(value)))
		local success:boolean, errorMessage = pcall(function() i[key] = value end)
		if not success then
			local fullMessage = string.format("An error occurred when applying the style sheet to %s:\n\n%s\n\nNo changes were made.",
				i.Name, errorMessage)
			displayMessage(fullMessage)
			return false
		end
	end
	
	return true
end

local applyStyleSheetButton:PluginToolbarButton = toolbar:CreateButton("Apply",	"Apply the style sheet to all ScreenGui, SurfaceGui, BillboardGui and AdGui's.", "rbxassetid://12111879608")
applyStyleSheetButton.ClickableWhenViewportHidden = true

applyStyleSheetButton.Click:Connect(function()
	local styleSheetModule:Instance = StarterGui["StyleSheet"]
	if styleSheetModule == nil then
		displayMessage("Style sheet not found. To use this plugin, place a ModuleScript named \"StyleSheet\" under StarterGui.")
		return
	end
	
	-- If you get "Requested module experienced an error while loading" when applying style sheet,
	-- look in the output panel for an error in your style sheet.
	local styleSheet = require(styleSheetModule:Clone())  -- To prevent caching
	
	-- Find all GUI roots
	local roots:{Instance} = {StarterGui}
	for _, instance:Instance in workspace:GetDescendants() do
		if instance:IsA("SurfaceGui") or instance:IsA("BillboardGui") or instance:IsA("AdGui") then
			table.insert(roots, instance)
		end
	end
	
	-- Begin recording history
	local recordId:string? = ChangeHistoryService:TryBeginRecording("Apply style sheet", "Apply style sheet")
	if recordId == nil then
		-- Attempt to cancel previous recording and retry
		print("Unable to record change history; retrying.")
		ChangeHistoryService:FinishRecording(nil, Enum.FinishRecordingOperation.Cancel)
		recordId = ChangeHistoryService:TryBeginRecording("Apply style sheet", "Apply style sheet")
	end
	if recordId == nil then
		displayMessage("Unable to record changes. Are you in play mode?")
		return
	end
	
	-- Verbose?
	verbose = styleSheet.verbose == true
	
	-- Apply style sheet
	for selector:string, styleTable:table in styleSheet do
		printIfVerbose("Processing selector: " .. selector)
		local instances:{Instance} = findDescendantsThatMatchSelector(roots, selector)
		printIfVerbose("Found " .. tostring(#instances) .. " instances that match this selector.")
		for _, i in instances do
			local success = applyStyleTable(i, styleTable)
			if not success then
				ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Cancel)
				return
			end
		end
	end
	
	-- Stop recording
	ChangeHistoryService:FinishRecording(recordId, Enum.FinishRecordingOperation.Commit)
end)
