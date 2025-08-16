--// Load OrionLib
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Window = OrionLib:MakeWindow({Name = "ALL GAME MENU", HidePremium = false, SaveConfig = true, ConfigFolder = "AllGameHub"})

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// State
local AimEnabled = false
local ESP_Enabled = false
local Hitbox_Enabled = false
local BodySize, HeadSize = 5, 5
local FOV_Radius = 100

--// FOV Circle
local FOV_Circle = Drawing.new("Circle")
FOV_Circle.Visible = false
FOV_Circle.Color = Color3.fromRGB(255,255,255)
FOV_Circle.Thickness = 2
FOV_Circle.Filled = false
FOV_Circle.NumSides = 100
FOV_Circle.Radius = FOV_Radius

RunService.RenderStepped:Connect(function()
    if FOV_Circle.Visible then
        FOV_Circle.Position = UIS:GetMouseLocation()
    end
end)

--// Find Closest Enemy In FOV
local function GetClosestEnemy()
    local closest, distCheck = nil, math.huge
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team ~= LocalPlayer.Team and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local fovDist = (Vector2.new(screenPos.X, screenPos.Y) - Camera.ViewportSize/2).Magnitude
                if fovDist <= FOV_Radius and fovDist < distCheck then
                    closest = head
                    distCheck = fovDist
                end
            end
        end
    end
    return closest
end

--// Aimbot Auto Lock
RunService.RenderStepped:Connect(function()
    if AimEnabled then
        local target = GetClosestEnemy()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)

--// ESP
local ESP_Objects = {}
local function CreateESP(player)
    if player == LocalPlayer then return end
    local text = Drawing.new("Text")
    text.Size = 14
    text.Center = true
    text.Outline = true
    text.Color = Color3.fromRGB(0,255,0)
    text.Visible = false

    ESP_Objects[player] = text

    RunService.RenderStepped:Connect(function()
        if ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen and player.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                    (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
                text.Position = Vector2.new(pos.X, pos.Y - 30)
                text.Text = string.format("%s | HP: %d | %.1fm", player.Name, humanoid.Health, dist/3)
                text.Visible = true
            else
                text.Visible = false
            end
        else
            text.Visible = false
        end
    end)
end

-- Auto tạo ESP
for _,plr in pairs(Players:GetPlayers()) do
    CreateESP(plr)
end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(function(plr)
    if ESP_Objects[plr] then
        ESP_Objects[plr]:Remove()
        ESP_Objects[plr] = nil
    end
end)

--// Hitbox Extender
local function ApplyHitboxToChar(char, player)
    if not Hitbox_Enabled then return end
    if player.Team == LocalPlayer.Team then return end -- không áp cho đồng đội
    if char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.Size = Vector3.new(BodySize, BodySize, BodySize)
        char.HumanoidRootPart.Transparency = 0.7
        char.HumanoidRootPart.BrickColor = BrickColor.new("Really red")
        char.HumanoidRootPart.Material = Enum.Material.Neon
        char.HumanoidRootPart.CanCollide = false
    end
    if char:FindFirstChild("Head") then
        char.Head.Size = Vector3.new(HeadSize, HeadSize, HeadSize)
        char.Head.Transparency = 0.7
        char.Head.BrickColor = BrickColor.new("Bright blue")
        char.Head.Material = Enum.Material.Neon
        char.Head.CanCollide = false
    end
end

local function ApplyHitbox(player)
    if player == LocalPlayer then return end
    if player.Character then ApplyHitboxToChar(player.Character, player) end
    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart")
        ApplyHitboxToChar(char, player)
    end)
end

-- Auto apply hitbox
for _,plr in pairs(Players:GetPlayers()) do
    ApplyHitbox(plr)
end
Players.PlayerAdded:Connect(ApplyHitbox)

-- Update liên tục
RunService.RenderStepped:Connect(function()
    if Hitbox_Enabled then
        for _,plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                if plr.Team ~= LocalPlayer.Team and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                    ApplyHitboxToChar(plr.Character, plr)
                end
            end
        end
    end
end)

--// Tabs & Menu
local Tab_Aim = Window:MakeTab({Name = "🎯 AIM", Icon = "rbxassetid://4483345998", PremiumOnly = false})
Tab_Aim:AddToggle({
    Name = "Bật/Tắt Aim (FOV)",
    Default = false,
    Callback = function(Value)
        AimEnabled = Value
        FOV_Circle.Visible = Value
    end
})
Tab_Aim:AddTextbox({
    Name = "Nhập POV (50-200)",
    Default = "100",
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 50 and num <= 200 then
            FOV_Radius = num
            FOV_Circle.Radius = num
        end
    end
})

local Tab_ESP = Window:MakeTab({Name = "👀 ESP", Icon = "rbxassetid://4483345998", PremiumOnly = false})
Tab_ESP:AddToggle({
    Name = "Bật/Tắt ESP",
    Default = false,
    Callback = function(Value)
        ESP_Enabled = Value
    end
})

local Tab_Hitbox = Window:MakeTab({Name = "📦 Hitbox", Icon = "rbxassetid://4483345998", PremiumOnly = false})
Tab_Hitbox:AddToggle({
    Name = "Bật/Tắt Hitbox (chỉ địch)",
    Default = false,
    Callback = function(Value)
        Hitbox_Enabled = Value
    end
})
Tab_Hitbox:AddTextbox({
    Name = "Hitbox Thân (5-50)",
    Default = "5",
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 5 and num <= 50 then
            BodySize = num
        end
    end
})
Tab_Hitbox:AddTextbox({
    Name = "Hitbox Đầu (5-10)",
    Default = "5",
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 5 and num <= 10 then
            HeadSize = num
        end
    end
})

--// Init
OrionLib:Init()
