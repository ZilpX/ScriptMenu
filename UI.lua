-- Script All Game All Map Roblox
-- Tính năng: Aim POV, Chỉnh Hitbox, ESP, Menu UI đóng/mở/kéo thả

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Menu UI variables
local menuOpen, dragging = false, false
local dragStart, startPos
local aimEnabled, espEnabled = false, true
local aimRadius, hitboxBody, hitboxHead = 100, 10, 5

-- UI
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0,350,0,350)
MainFrame.Position = UDim2.new(0.3,0,0.3,0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30,30,30)
MainFrame.Visible = false
MainFrame.Active = true

local OpenCircle = Instance.new("ImageButton", ScreenGui)
OpenCircle.Size = UDim2.new(0,40,0,40)
OpenCircle.Position = UDim2.new(0,8,0,200)
OpenCircle.Image = "rbxassetid://3926305904"
OpenCircle.BackgroundTransparency = 1

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.Size = UDim2.new(0,30,0,30)
CloseBtn.Position = UDim2.new(1,-35,0,5)
CloseBtn.Text = "X"
CloseBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
CloseBtn.TextColor3 = Color3.new(1,1,1)

local AimToggle = Instance.new("TextButton", MainFrame)
AimToggle.Size = UDim2.new(0,120,0,30)
AimToggle.Position = UDim2.new(0,10,0,50)
AimToggle.Text = "Aim POV: OFF"
AimToggle.BackgroundColor3 = Color3.fromRGB(50,150,255)

local AimRadiusSlider = Instance.new("TextBox", MainFrame)
AimRadiusSlider.Size = UDim2.new(0,120,0,30)
AimRadiusSlider.Position = UDim2.new(0,10,0,90)
AimRadiusSlider.Text = "Aim Radius: "..aimRadius

local HitboxBodyBox = Instance.new("TextBox", MainFrame)
HitboxBodyBox.Size = UDim2.new(0,120,0,30)
HitboxBodyBox.Position = UDim2.new(0,10,0,130)
HitboxBodyBox.Text = "Hitbox Body: "..hitboxBody

local HitboxHeadBox = Instance.new("TextBox", MainFrame)
HitboxHeadBox.Size = UDim2.new(0,120,0,30)
HitboxHeadBox.Position = UDim2.new(0,10,0,170)
HitboxHeadBox.Text = "Hitbox Head: "..hitboxHead

local ESPToggle = Instance.new("TextButton", MainFrame)
ESPToggle.Size = UDim2.new(0,120,0,30)
ESPToggle.Position = UDim2.new(0,10,0,210)
ESPToggle.Text = "ESP: ON"
ESPToggle.BackgroundColor3 = Color3.fromRGB(60,255,100)

-- Kéo thả menu
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Đóng/mở menu
OpenCircle.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    MainFrame.Visible = menuOpen
end)
CloseBtn.MouseButton1Click:Connect(function()
    menuOpen = false
    MainFrame.Visible = false
end)

-- Toggle Aim
AimToggle.MouseButton1Click:Connect(function()
    aimEnabled = not aimEnabled
    AimToggle.Text = "Aim POV: " .. (aimEnabled and "ON" or "OFF")
end)
AimRadiusSlider.FocusLost:Connect(function()
    local num = tonumber(AimRadiusSlider.Text:match("%d+"))
    if num and num >= 50 and num <= 200 then
        aimRadius = num
        AimRadiusSlider.Text = "Aim Radius: "..aimRadius
    else
        AimRadiusSlider.Text = "Aim Radius: "..aimRadius
    end
end)

HitboxBodyBox.FocusLost:Connect(function()
    local num = tonumber(HitboxBodyBox.Text:match("%d+"))
    if num and num >= 5 and num <= 20 then
        hitboxBody = num
        HitboxBodyBox.Text = "Hitbox Body: "..hitboxBody
    else
        HitboxBodyBox.Text = "Hitbox Body: "..hitboxBody
    end
end)
HitboxHeadBox.FocusLost:Connect(function()
    local num = tonumber(HitboxHeadBox.Text:match("%d+"))
    if num and num >= 5 and num <= 10 then
        hitboxHead = num
        HitboxHeadBox.Text = "Hitbox Head: "..hitboxHead
    else
        HitboxHeadBox.Text = "Hitbox Head: "..hitboxHead
    end
end)

ESPToggle.MouseButton1Click:Connect(function()
    espEnabled = not espEnabled
    ESPToggle.Text = "ESP: " .. (espEnabled and "ON" or "OFF")
end)

-- Aim POV vẽ vòng tròn (Drawing API)
local Drawing = Drawing or nil
local povCircle
if Drawing then
    povCircle = Drawing.new("Circle")
    povCircle.Thickness = 2
    povCircle.Transparency = 1
    povCircle.Color = Color3.new(1,1,1)
    povCircle.Filled = false
end

-- Hitbox function
function EditHitbox(player)
    local chr = player.Character
    if chr then
        if chr:FindFirstChild("HumanoidRootPart") then
            chr.HumanoidRootPart.Size = Vector3.new(hitboxBody,hitboxBody,hitboxBody)
        end
        if chr:FindFirstChild("Head") then
            chr.Head.Size = Vector3.new(hitboxHead, hitboxHead, hitboxHead)
        end
    end
end

-- ESP function
local espTable = {}
function UpdateESP()
    for _,v in pairs(espTable) do
        if v then v:Remove() end
    end
    espTable = {}
    for _,player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local Billboard = Instance.new("BillboardGui", head)
            Billboard.Size = UDim2.new(0,150,0,40)
            Billboard.Adornee = head
            Billboard.AlwaysOnTop = true
            local NameLabel = Instance.new("TextLabel", Billboard)
            NameLabel.Size = UDim2.new(1,0,1,0)
            NameLabel.BackgroundTransparency = 1
            NameLabel.Text = player.Name.." | HP: "..(player.Character:FindFirstChildOfClass("Humanoid") and math.floor(player.Character:FindFirstChildOfClass("Humanoid").Health) or "??")
            local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and (head.Position - LocalPlayer.Character.Head.Position).Magnitude) or 0
            NameLabel.Text = NameLabel.Text.." | "..math.floor(dist).."m"
            NameLabel.TextColor3 = Color3.new(1,1,1)
            NameLabel.Font = Enum.Font.SourceSansBold
            NameLabel.TextScaled = true
            table.insert(espTable, Billboard)
        end
    end
end

-- Main Loop
RunService.RenderStepped:Connect(function()
    if aimEnabled and Drawing and povCircle then
        povCircle.Visible = true
        povCircle.Position = UserInputService:GetMouseLocation()
        povCircle.Radius = aimRadius
    elseif Drawing and povCircle then
        povCircle.Visible = false
    end

    if espEnabled then
        pcall(UpdateESP)
    else
        for _,v in pairs(espTable) do
            if v then v:Remove() end
        end
        espTable = {}
    end

    for _,player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            pcall(function() EditHitbox(player) end)
        end
    end
end)

-- Tự động cập nhật khi có người chơi mới
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if espEnabled then
            pcall(UpdateESP)
        end
    end)
end)

-- END SCRIPT
