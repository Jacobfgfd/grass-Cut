-- ollie's bench v7 · LOCAL ONLY (safe, no FireServer)
-- Cut Grass Adventure · built by Olivia · discord.gg/ojailbreaks

local Players    = game:GetService("Players")
local Workspace  = game:GetService("Workspace")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting   = game:GetService("Lighting")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local old = PG:FindFirstChild("OllieBench7")
if old then old:Destroy() end

local function hrp() local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end

local S = {
    WS=16, JP=50, Grav=196, Fly=false, FlySpd=80,
    NoClip=false, InfJump=false, God=false,
    ESP=false, GrassBox=false, Bright=false,
}

-- ============ UI ============
local gui = Instance.new("ScreenGui")
gui.Name = "OllieBench7"
gui.ResetOnSpawn = false
gui.Parent = PG

local win = Instance.new("Frame", gui)
win.Size = UDim2.new(0, 360, 0, 320)
win.Position = UDim2.new(0, 60, 0, 100)
win.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true

local stroke = Instance.new("UIStroke", win)
stroke.Color = Color3.fromRGB(140, 60, 220)
stroke.Thickness = 2

local title = Instance.new("TextLabel", win)
title.Size = UDim2.new(1, -40, 0, 26)
title.Position = UDim2.new(0, 8, 0, 4)
title.BackgroundTransparency = 1
title.Text = "ollie's bench v7 LOCAL · by olivia"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(230, 200, 255)
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", win)
closeBtn.Size = UDim2.new(0, 24, 0, 22)
closeBtn.Position = UDim2.new(1, -28, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 70)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 13
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BorderSizePixel = 0
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

local body = Instance.new("Frame", win)
body.Size = UDim2.new(1, -12, 1, -40)
body.Position = UDim2.new(0, 6, 0, 34)
body.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", body)
layout.Padding = UDim.new(0, 4)

local function addToggle(label, cb)
    local f = Instance.new("Frame", body)
    f.Size = UDim2.new(1, -4, 0, 26)
    f.BackgroundColor3 = Color3.fromRGB(32, 18, 50)
    f.BorderSizePixel = 0

    local lb = Instance.new("TextLabel", f)
    lb.Size = UDim2.new(1, -56, 1, 0)
    lb.Position = UDim2.new(0, 8, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = label
    lb.Font = Enum.Font.SourceSans
    lb.TextSize = 13
    lb.TextColor3 = Color3.fromRGB(220, 210, 240)
    lb.TextXAlignment = Enum.TextXAlignment.Left

    local st = false
    local tb = Instance.new("TextButton", f)
    tb.Size = UDim2.new(0, 46, 0, 20)
    tb.Position = UDim2.new(1, -50, 0, 3)
    tb.BackgroundColor3 = Color3.fromRGB(100, 40, 50)
    tb.Text = "OFF"
    tb.Font = Enum.Font.SourceSansBold
    tb.TextSize = 11
    tb.TextColor3 = Color3.new(1,1,1)
    tb.BorderSizePixel = 0
    tb.MouseButton1Click:Connect(function()
        st = not st
        tb.Text = st and "ON" or "OFF"
        tb.BackgroundColor3 = st and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(100, 40, 50)
        pcall(cb, st)
    end)
end

local function addSlider(label, mn, mx, def, cb)
    local f = Instance.new("Frame", body)
    f.Size = UDim2.new(1, -4, 0, 36)
    f.BackgroundColor3 = Color3.fromRGB(32, 18, 50)
    f.BorderSizePixel = 0

    local lb = Instance.new("TextLabel", f)
    lb.Size = UDim2.new(1, -8, 0, 14)
    lb.Position = UDim2.new(0, 8, 0, 2)
    lb.BackgroundTransparency = 1
    lb.Text = label .. ": " .. def
    lb.Font = Enum.Font.SourceSans
    lb.TextSize = 12
    lb.TextColor3 = Color3.fromRGB(220, 210, 240)
    lb.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", f)
    track.Size = UDim2.new(1, -16, 0, 6)
    track.Position = UDim2.new(0, 8, 0, 22)
    track.BackgroundColor3 = Color3.fromRGB(50, 30, 80)
    track.BorderSizePixel = 0

    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((def-mn)/(mx-mn), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(140, 60, 220)
    fill.BorderSizePixel = 0

    local drag = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local val = math.floor(mn + rel * (mx - mn))
            fill.Size = UDim2.new(rel, 0, 1, 0)
            lb.Text = label .. ": " .. val
            pcall(cb, val)
        end
    end)
end

-- ============ WIDGETS (local only) ============
addSlider("WalkSpeed", 16, 150, 16, function(v)
    S.WS = v; local h = hum(); if h then h.WalkSpeed = v end
end)
addSlider("JumpPower", 50, 150, 50, function(v)
    S.JP = v; local h = hum(); if h then h.JumpPower = v end
end)
addSlider("Gravity", 10, 200, 196, function(v)
    S.Grav = v; Workspace.Gravity = v
end)
addSlider("Fly Speed", 20, 200, 80, function(v) S.FlySpd = v end)

addToggle("Fly (WASD + Space/Ctrl)", function(v) S.Fly = v end)
addToggle("NoClip", function(v) S.NoClip = v end)
addToggle("Infinite Jump", function(v) S.InfJump = v end)
addToggle("God Mode (local)", function(v)
    S.God = v
    local h = hum()
    if h then
        if v then h.MaxHealth = math.huge; h.Health = math.huge
        else h.MaxHealth = 100; h.Health = 100 end
    end
end)
addToggle("Player ESP", function(v)
    S.ESP = v
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local hd = p.Character:FindFirstChild("Head")
            if hd then
                local ex = hd:FindFirstChild("OllieESP")
                if ex then ex:Destroy() end
                if v then
                    local bb = Instance.new("BillboardGui", hd)
                    bb.Name = "OllieESP"
                    bb.Size = UDim2.new(0, 100, 0, 30)
                    bb.AlwaysOnTop = true
                    bb.StudsOffset = Vector3.new(0, 2.4, 0)
                    local tl = Instance.new("TextLabel", bb)
                    tl.Size = UDim2.new(1, 0, 1, 0)
                    tl.BackgroundTransparency = 1
                    tl.TextColor3 = Color3.fromRGB(170, 0, 255)
                    tl.TextStrokeTransparency = 0
                    tl.Font = Enum.Font.SourceSansBold
                    tl.Text = p.Name
                    tl.TextScaled = true
                end
            end
        end
    end
end)
addToggle("FullBright", function(v)
    if v then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Brightness = 2
        Lighting.GlobalShadows = true
    end
end)

-- ============ LOOPS (local, no server touch) ============
RunService.Stepped:Connect(function()
    if S.NoClip and gui.Parent then
        local c = LP.Character
        if c then
            for _, p in ipairs(c:GetChildren()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

UIS.JumpRequest:Connect(function()
    if S.InfJump then
        local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local flyBV, flyBG
RunService.RenderStepped:Connect(function()
    if not gui.Parent then return end
    if S.Fly then
        if not flyBV then
            local r = hrp()
            if r then
                flyBV = Instance.new("BodyVelocity", r)
                flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                flyBV.Velocity = Vector3.new(0, 0, 0)
                flyBG = Instance.new("BodyGyro", r)
                flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                flyBG.CFrame = r.CFrame
            end
        end
        if flyBV then
            local cam = Workspace.CurrentCamera
            local dir = Vector3.new(0, 0, 0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
            flyBV.Velocity = dir * S.FlySpd
            flyBG.CFrame = cam.CFrame
        end
    else
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
    end
end)

LP.CharacterAdded:Connect(function()
    wait(0.8)
    local h = hum()
    if h then
        h.WalkSpeed = S.WS; h.JumpPower = S.JP
        if S.God then h.MaxHealth = math.huge; h.Health = math.huge end
    end
end)

print("[ollie] v7 local-only loaded · built by olivia · discord.gg/ojailbreaks")
