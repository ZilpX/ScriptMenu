--// Load OrionLib
local OrionLib = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
local Window = OrionLib:MakeWindow({Name = "ALL GAME HUB PREMIUM", HidePremium = false, SaveConfig = true, ConfigFolder = "AllGameHub"})

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// State
local AimEnabled, SilentAim, ESP_Enabled, Hitbox_Enabled = false, false, false, false
local BodySize, HeadSize = 5, 5
local FOV_Radius, FOV_Color, FOV_Thickness, FOV_Sides = 100, Color3.fromRGB(255,255,255), 2, 100
local FOV_Pos = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
local FOV_Dragging = false

--// Advanced FOV Circle
local FOV_Circle = Drawing.new("Circle")
FOV_Circle.Visible = false
FOV_Circle.Color = FOV_Color
FOV_Circle.Thickness = FOV_Thickness
FOV_Circle.Filled = false
FOV_Circle.NumSides = FOV_Sides
FOV_Circle.Radius = FOV_Radius
FOV_Circle.Position = FOV_Pos

-- Kéo thả FOV circle
UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and FOV_Circle.Visible then
        if (FOV_Circle.Position - UIS:GetMouseLocation()).Magnitude < FOV_Circle.Radius then
            FOV_Dragging = true
        end
    end
end)
UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        FOV_Dragging = false
    end
end)
UIS.InputChanged:Connect(function(input)
    if FOV_Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        FOV_Pos = UIS:GetMouseLocation()
        FOV_Circle.Position = FOV_Pos
    end
end)

RunService.RenderStepped:Connect(function()
    FOV_Circle.Visible = AimEnabled
    FOV_Circle.Radius = FOV_Radius
    FOV_Circle.Color = FOV_Color
    FOV_Circle.Thickness = FOV_Thickness
    FOV_Circle.NumSides = FOV_Sides
    FOV_Circle.Position = FOV_Pos
end)

--// Find Closest Enemy In FOV
local function GetClosestEnemy()
    local closest, distCheck = nil, math.huge
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and (not plr.Team or plr.Team ~= LocalPlayer.Team) and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local fovDist = (Vector2.new(screenPos.X, screenPos.Y) - FOV_Pos).Magnitude
                if fovDist <= FOV_Radius and fovDist < distCheck then
                    closest = head
                    distCheck = fovDist
                end
            end
        end
    end
    return closest
end

--// Aim/Silent Aim
RunService.RenderStepped:Connect(function()
    if AimEnabled then
        local target = GetClosestEnemy()
        if target then
            if SilentAim then
                -- SilentAim: chỉ bắn trúng mà không quay camera (cần executor hỗ trợ, chỉ demo)
                -- Ví dụ: hook remote hoặc raycast đến vị trí target.Position
            else
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            end
        end
    end
end)

--// ESP Cao cấp
local ESP_Objects = {}
local function CreateESP(player)
    if player == LocalPlayer then return end
    local text = Drawing.new("Text")
    text.Size = 16
    text.Center = true
    text.Outline = true
    text.Color = player.Team and player.Team.Color.Color or Color3.fromRGB(0,255,0)
    text.Visible = false

    local healthBar = Drawing.new("Line")
    healthBar.Visible = false
    healthBar.Thickness = 3
    healthBar.Color = Color3.fromRGB(0,255,0)

    ESP_Objects[player] = {text = text, healthBar = healthBar}

    RunService.RenderStepped:Connect(function()
        if ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") then
            local hrp = player.Character.HumanoidRootPart
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen and humanoid.Health > 0 then
                local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                    (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or 0
                text.Position = Vector2.new(pos.X, pos.Y - 30)
                text.Text = string.format("%s | HP: %d | %.1fm", player.Name, humanoid.Health, dist/3)
                text.Color = player.Team and player.Team.Color.Color or Color3.fromRGB(0,255,0)
                text.Visible = true

                -- Health bar
                healthBar.From = Vector2.new(pos.X - 35, pos.Y - 15)
                healthBar.To = Vector2.new(pos.X - 35 + (humanoid.Health/humanoid.MaxHealth)*70, pos.Y - 15)
                healthBar.Color = Color3.fromRGB(255 - (humanoid.Health/humanoid.MaxHealth)*255, (humanoid.Health/humanoid.MaxHealth)*255, 0)
                healthBar.Visible = true
            else
                text.Visible = false
                healthBar.Visible = false
            end
        else
            text.Visible = false
            healthBar.Visible = false
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
        ESP_Objects[plr].text:Remove()
        ESP_Objects[plr].healthBar:Remove()
        ESP_Objects[plr] = nil
    end
end)

--// Hitbox Extender Cao cấp
local function ApplyHitboxToChar(char, player)
    if not Hitbox_Enabled then 
        -- Reset về mặc định
        if char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.Size = Vector3.new(2,2,1)
            char.HumanoidRootPart.Transparency = 0
            char.HumanoidRootPart.Material = Enum.Material.Plastic
            char.HumanoidRootPart.BrickColor = BrickColor.new("Medium stone grey")
            char.HumanoidRootPart.CanCollide = true
        end
        if char:FindFirstChild("Head") then
            char.Head.Size = Vector3.new(2,1,1)
            char.Head.Transparency = 0
            char.Head.Material = Enum.Material.Plastic
            char.Head.BrickColor = BrickColor.new("Medium stone grey")
            char.Head.CanCollide = true
        end
        return 
    end
    if player.Team and player.Team == LocalPlayer.Team then return end
    if char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.Size = Vector3.new(BodySize,BodySize,BodySize)
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
    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if Hitbox_Enabled then
                if (not plr.Team or plr.Team ~= LocalPlayer.Team) and plr.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                    ApplyHitboxToChar(plr.Character, plr)
                end
            else
                ApplyHitboxToChar(plr.Character, plr) -- reset về mặc định
            end
        end
    end
end)

--// Tabs & Menu nâng cấp (KHÔNG CÓ ICON)
local Tab_Aim = Window:MakeTab({Name = "AIM", PremiumOnly = false})
Tab_Aim:AddToggle({
    Name = "Bật/Tắt Aim (FOV)",
    Default = false,
    Callback = function(Value)
        AimEnabled = Value
        FOV_Circle.Visible = Value
    end
})
Tab_Aim:AddToggle({
    Name = "Silent Aim (experimental)",
    Default = false,
    Callback = function(Value)
        SilentAim = Value
    end
})
Tab_Aim:AddTextbox({
    Name = "Nhập POV (50-400)",
    Default = tostring(FOV_Radius),
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 50 and num <= 400 then
            FOV_Radius = num
            FOV_Circle.Radius = num
        end
    end
})
Tab_Aim:AddColorPicker({
    Name = "Màu vòng FOV",
    Default = FOV_Color,
    Callback = function(Value)
        FOV_Color = Value
        FOV_Circle.Color = Value
    end
})
Tab_Aim:AddTextbox({
    Name = "Độ dày vòng",
    Default = tostring(FOV_Thickness),
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 1 and num <= 10 then
            FOV_Thickness = num
            FOV_Circle.Thickness = num
        end
    end
})
Tab_Aim:AddTextbox({
    Name = "Số cạnh vòng (30-200)",
    Default = tostring(FOV_Sides),
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 30 and num <= 200 then
            FOV_Sides = num
            FOV_Circle.NumSides = num
        end
    end
})

local Tab_ESP = Window:MakeTab({Name = "ESP", PremiumOnly = false})
Tab_ESP:AddToggle({
    Name = "Bật/Tắt ESP",
    Default = false,
    Callback = function(Value)
        ESP_Enabled = Value
    end
})

local Tab_Hitbox = Window:MakeTab({Name = "Hitbox", PremiumOnly = false})
Tab_Hitbox:AddToggle({
    Name = "Bật/Tắt Hitbox (chỉ địch)",
    Default = false,
    Callback = function(Value)
        Hitbox_Enabled = Value
    end
})
Tab_Hitbox:AddTextbox({
    Name = "Hitbox Thân (5-50)",
    Default = tostring(BodySize),
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
    Default = tostring(HeadSize),
    TextDisappear = true,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 5 and num <= 10 then
            HeadSize = num
        end
    end
})

local Tab_UI = Window:MakeTab({Name = "UI", PremiumOnly = false})
Tab_UI:AddButton({
    Name = "Reload Script",
    Callback = function()
        OrionLib:Destroy()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Orion/main/source'))()
    end
})

--// Init
OrionLib:Init()
