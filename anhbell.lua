-- [[ HỆ THỐNG KIỂM TRA KEY ONLINE - BY BURGERBOY ]]
local KeyLink = "https://github.com/HuyBeodz/Burgerboy/blob/main/key" -- THAY LINK RAW KEY CỦA BẠN VÀO ĐÂY
local UserKey = _G.Key or "" 

-- Lấy Key từ trên mạng về
local success, CorrectKey = pcall(function()
    return game:HttpGet(KeyLink):gsub("%s+", "") -- Lấy text và xóa khoảng trắng thừa
end)

if not success or UserKey ~= CorrectKey then
    -- Thông báo lỗi hoặc sai key
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCore("SendNotification", {
        Title = "Burgerboy System",
        Text = (not success and "Lỗi kết nối máy chủ Key!" or "Sai Key rồi! Vui lòng nhập đúng Key."),
        Duration = 10,
        Button1 = "OK"
    })
    return -- Ngắt script
end

-- [[ NẾU ĐÚNG KEY - CHẠY TIẾP PHẦN DƯỚI ]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- == CẤU HÌNH ==
local SETTINGS = {
    ToggleKey = Enum.KeyCode.J,
    AimKey = Enum.UserInputType.MouseButton2,
    UnloadKey = Enum.KeyCode.L,
    
    FOV = 150,
    Smoothness = 0.15, 
    PredictionFactor = 0.135,
    AimbotMaxDistance = 500,
    WarningDistance = 250,
    ESPDistance = 500,
    BoxColor = Color3.fromRGB(255, 255, 255),
    WarningColor = Color3.fromRGB(255, 255, 0)
}

local aimbotEnabled = false
local isAiming = false
local isUnloaded = false
local lockedTarget = nil 
local espCache = {}
local connections = {}

-- == 1. TẠO STATUS UI ==
local statusLabel = Drawing.new("Text")
statusLabel.Visible = true
statusLabel.Size = 18
statusLabel.Color = Color3.fromRGB(255, 0, 0)
statusLabel.Position = Vector2.new(20, 20)
statusLabel.Text = "AIMBOT: OFF [J]"
statusLabel.Outline = true

-- == 2. HÀM UNLOAD ==
local function Unload()
    isUnloaded = true
    lockedTarget = nil
    for _, conn in pairs(connections) do if conn then conn:Disconnect() end end
    statusLabel:Remove()
    for _, data in pairs(espCache) do 
        if data.Box then data.Box:Remove() end 
        if data.Name then data.Name:Remove() end
    end
    table.clear(espCache)
end

-- == 3. LOGIC TÌM MỤC TIÊU ==
local function GetClosestTarget()
    local mouseLoc = UserInputService:GetMouseLocation()
    local target = nil
    local shortestDist = SETTINGS.FOV
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    if not myRoot then return nil end

    for player, data in pairs(espCache) do
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            if root and head then
                local worldDist = (root.Position - myRoot.Position).Magnitude
                if worldDist <= SETTINGS.AimbotMaxDistance then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local mouseDist = (Vector2.new(pos.X, pos.Y) - mouseLoc).Magnitude
                        if mouseDist < shortestDist then
                            shortestDist = mouseDist
                            target = {Character = char, Root = root, Head = head}
                        end
                    end
                end
            end
        end
    end
    return target
end

-- == 4. VÒNG LẶP CHÍNH ==
local renderConn = RunService.RenderStepped:Connect(function()
    if isUnloaded then return end
    
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for player, data in pairs(espCache) do
        local char = player.Character
        if char and char.Parent and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
            local root = char.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local dist = myRoot and (myRoot.Position - root.Position).Magnitude or 0

            if onScreen and dist < SETTINGS.ESPDistance then
                local sizeX = 2000 / pos.Z
                local sizeY = 3000 / pos.Z
                
                data.Box.Visible = true
                data.Box.Size = Vector2.new(sizeX, sizeY)
                data.Box.Position = Vector2.new(pos.X - sizeX / 2, pos.Y - sizeY / 2)
                
                data.Name.Visible = true
                data.Name.Position = Vector2.new(pos.X, pos.Y + (sizeY / 2) + 5)
                data.Name.Text = player.Name .. " [" .. math.floor(dist) .. "m]"

                local color = (dist <= SETTINGS.WarningDistance) and SETTINGS.WarningColor or SETTINGS.BoxColor
                data.Box.Color = color
                data.Name.Color = color
            else
                data.Box.Visible = false
                data.Name.Visible = false
            end
        else
            data.Box.Visible = false
            data.Name.Visible = false
        end
    end

    if aimbotEnabled and isAiming and lockedTarget then
        if lockedTarget.Character and lockedTarget.Character.Parent and lockedTarget.Character.Humanoid.Health > 0 then
            local predictPos = lockedTarget.Head.Position + (lockedTarget.Root.Velocity * SETTINGS.PredictionFactor)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, predictPos), SETTINGS.Smoothness)
        else
            lockedTarget = nil
        end
    end
end)
table.insert(connections, renderConn)

-- == 5. INPUT ==
local inputBegan = UserInputService.InputBegan:Connect(function(input, gp)
    if gp or isUnloaded then return end
    if input.KeyCode == SETTINGS.ToggleKey then
        aimbotEnabled = not aimbotEnabled
        statusLabel.Text = "AIMBOT: " .. (aimbotEnabled and "ON" or "OFF")
        statusLabel.Color = aimbotEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)
    elseif input.KeyCode == SETTINGS.UnloadKey then
        Unload()
    elseif input.UserInputType == SETTINGS.AimKey then
        isAiming = true
        lockedTarget = GetClosestTarget()
    end
end)
table.insert(connections, inputBegan)

local inputEnded = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == SETTINGS.AimKey then
        isAiming = false
        lockedTarget = nil
    end
end)
table.insert(connections, inputEnded)

-- == 6. HÀM TẠO BOX ESP ==
local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1
    box.Filled = false
    box.Transparency = 1
    box.Color = SETTINGS.BoxColor

    local name = Drawing.new("Text")
    name.Visible = false
    name.Center = true
    name.Outline = true
    name.Size = 13
    name.Color = Color3.new(1,1,1)

    espCache[player] = {
        Box = box,
        Name = name
    }
end

for _, p in pairs(Players:GetPlayers()) do CreateESP(p) end
table.insert(connections, Players.PlayerAdded:Connect(CreateESP))
table.insert(connections, Players.PlayerRemoving:Connect(function(p)
    if espCache[p] then
        espCache[p].Box:Remove()
        espCache[p].Name:Remove()
        espCache[p] = nil
    end
end))

