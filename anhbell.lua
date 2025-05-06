local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer

local Clipon = false
local ESPEnabled = false
local SteppedConnection
local ESPObjects = {}

-- GUI Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NoclipGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 130)
mainFrame.Position = UDim2.new(0.05, 0, 0.85, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 2
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Title Label
local bybeodzLabel = Instance.new("TextLabel")
bybeodzLabel.Size = UDim2.new(1, 0, 0.4, 0)
bybeodzLabel.Position = UDim2.new(0, 0, 0, 0)
bybeodzLabel.BackgroundTransparency = 1
bybeodzLabel.Text = "BYBEODZ"
bybeodzLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bybeodzLabel.Font = Enum.Font.Arcade
bybeodzLabel.TextSize = 28
bybeodzLabel.TextStrokeTransparency = 0
bybeodzLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
bybeodzLabel.Parent = mainFrame

-- Noclip Checkbox
local noclipCheckbox = Instance.new("TextButton")
noclipCheckbox.Size = UDim2.new(0, 180, 0, 30)
noclipCheckbox.Position = UDim2.new(0, 10, 0.4, 5)
noclipCheckbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
noclipCheckbox.TextColor3 = Color3.fromRGB(255, 255, 255)
noclipCheckbox.Font = Enum.Font.SourceSansBold
noclipCheckbox.TextSize = 20
noclipCheckbox.Text = "Noclip: OFF"
noclipCheckbox.Parent = mainFrame

-- ESP Checkbox
local espCheckbox = Instance.new("TextButton")
espCheckbox.Size = UDim2.new(0, 180, 0, 30)
espCheckbox.Position = UDim2.new(0, 10, 0.7, 5)
espCheckbox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
espCheckbox.TextColor3 = Color3.fromRGB(255, 255, 255)
espCheckbox.Font = Enum.Font.SourceSansBold
espCheckbox.TextSize = 20
espCheckbox.Text = "ESP: OFF"
espCheckbox.Parent = mainFrame

-- Toggle Noclip
local function toggleNoclip()
	Clipon = not Clipon
	noclipCheckbox.Text = "Noclip: " .. (Clipon and "ON" or "OFF")
	noclipCheckbox.BackgroundColor3 = Clipon and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(50, 50, 50)

	if Clipon then
		SteppedConnection = RunService.Stepped:Connect(function()
			if player.Character then
				for _, part in ipairs(player.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end)
	else
		if SteppedConnection then SteppedConnection:Disconnect() end
		if player.Character then
			for _, part in ipairs(player.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
	end
end

-- ESP Utilities
-- ESP Utilities
local function createESPForCharacter(char)
	if ESPObjects[char] then return end

	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.new(1, 0, 0)
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0.3
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = char
	highlight.Parent = game:GetService("CoreGui")

	ESPObjects[char] = highlight

	-- Theo dõi liên tục để cập nhật màu theo team
	task.spawn(function()
		while highlight and highlight.Parent and ESPEnabled do
			local p = Players:GetPlayerFromCharacter(char)
			if p and p.Team then
				if p.Team.Name == "Police" then
					highlight.OutlineColor = Color3.fromRGB(0, 0, 255)
				elseif p.Team.Name == "Criminal" then
					highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
				else
					highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
				end
			end
			task.wait(1) -- Cập nhật mỗi giây
		end
	end)
end

local function removeESPForCharacter(char)
	if ESPObjects[char] then
		ESPObjects[char]:Destroy()
		ESPObjects[char] = nil
	end
end

-- Toggle ESP
local function toggleESP()
	ESPEnabled = not ESPEnabled
	espCheckbox.Text = "ESP: " .. (ESPEnabled and "ON" or "OFF")
	espCheckbox.BackgroundColor3 = ESPEnabled and Color3.fromRGB(0, 0, 100) or Color3.fromRGB(50, 50, 50)

	for _, p in pairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			if ESPEnabled then
				createESPForCharacter(p.Character)
			else
				removeESPForCharacter(p.Character)
			end
		end
	end
end

-- Checkbox Button Events
noclipCheckbox.MouseButton1Click:Connect(toggleNoclip)
espCheckbox.MouseButton1Click:Connect(toggleESP)

-- Keybind for Noclip
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.N then
		toggleNoclip()
	end
end)

-- Auto apply ESP to future players
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		if ESPEnabled then
			createESPForCharacter(char)
		end
	end)
end)

for _, p in pairs(Players:GetPlayers()) do
	if p ~= player and p.Character then
		if ESPEnabled then
			createESPForCharacter(p.Character)
		end
	end
	p.CharacterAdded:Connect(function(char)
		if ESPEnabled then
			createESPForCharacter(char)
		end
	end)
end

-- Clean ESP when player leaves
Players.PlayerRemoving:Connect(function(p)
	if p.Character then
		removeESPForCharacter(p.Character)
	end
end)
