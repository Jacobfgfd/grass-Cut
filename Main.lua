-- ollie's bench v6 · POTASSIUM tuned
-- Cut Grass Adventure · built by Olivia · discord.gg/ojailbreaks

local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local Workspace  = game:GetService("Workspace")
local UIS        = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting   = game:GetService("Lighting")
local TPS        = game:GetService("TeleportService")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

-- cleanup previous
local old = PG:FindFirstChild("OllieBench6")
if old then old:Destroy() end

local function hrp() local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c=LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end

local S = {
    AutoCut=false, AutoSell=false, AutoRebirth=false,
    WS=16, JP=50, Fly=false, FlySpd=80, NoClip=false, InfJump=false, God=false,
    Mult=1, RebMin=50, RebMax=140, Stop=false,
}
local Grass, Cuts, Sells, Rebs = {}, {}, {}, {}

-- ============ UI (PlayerGui only, simple) ============
local gui = Instance.new("ScreenGui")
gui.Name = "OllieBench6"
gui.ResetOnSpawn = false
gui.Parent = PG

local win = Instance.new("Frame", gui)
win.Size = UDim2.new(0, 400, 0, 340)
win.Position = UDim2.new(0, 60, 0, 100)
win.BackgroundColor3 = Color3.fromRGB(20, 10, 30)
win.BorderSizePixel = 0
win.Active = true
win.Draggable = true

local stroke = Instance.new("UIStroke", win)
stroke.Color = Color3.fromRGB(140, 60, 220)
stroke.Thickness = 2

local title = Instance.new("TextLabel", win)
title.Size = UDim2.new(1, -40, 0, 28)
title.Position = UDim2.new(0, 8, 0, 4)
title.BackgroundTransparency = 1
title.Text = "ollie's bench v6 · built by olivia"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.TextColor3 = Color3.fromRGB(230, 200, 255)
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", win)
closeBtn.Size = UDim2.new(0, 24, 0, 22)
closeBtn.Position = UDim2.new(1, -28, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 70)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 13
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.BorderSizePixel = 0
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- tab bar
local tabBar = Instance.new("Frame", win)
tabBar.Size = UDim2.new(1, -12, 0, 24)
tabBar.Position = UDim2.new(0, 6, 0, 36)
tabBar.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout", tabBar)
layout.FillDirection = Enum.FillDirection.Horizontal
layout.Padding = UDim.new(0, 3)

-- body
local body = Instance.new("Frame", win)
body.Size = UDim2.new(1, -12, 1, -68)
body.Position = UDim2.new(0, 6, 0, 64)
body.BackgroundTransparency = 1

local pages, tabs = {}, {}
local function pickTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabs) do
        if n == name then b.BackgroundColor3 = Color3.fromRGB(140, 60, 220)
        else b.BackgroundColor3 = Color3.fromRGB(50, 24, 86) end
    end
end

local function addTab(name)
    local b = Instance.new("TextButton", tabBar)
    b.Size = UDim2.new(0, 66, 1, 0)
    b.BackgroundColor3 = Color3.fromRGB(50, 24, 86)
    b.Text = name
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 12
    b.TextColor3 = Color3.new(1,1,1)
    b.BorderSizePixel = 0

    local p = Instance.new("Frame", body)
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false

    local pl = Instance.new("UIListLayout", p)
    pl.Padding = UDim.new(0, 4)

    tabs[name] = b
    pages[name] = p
    b.MouseButton1Click:Connect(function() pickTab(name) end)
    return p
end

local function addToggle(p, label, cb)
    local f = Instance.new("Frame", p)
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
        if st then
            tb.Text = "ON"
            tb.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
        else
            tb.Text = "OFF"
            tb.BackgroundColor3 = Color3.fromRGB(100, 40, 50)
        end
        pcall(cb, st)
    end)
end

local function addBtn(p, label, cb)
    local b = Instance.new("TextButton", p)
    b.Size = UDim2.new(1, -4, 0, 24)
    b.BackgroundColor3 = Color3.fromRGB(80, 40, 140)
    b.Text = label
    b.Font = Enum.Font.SourceSansBold
    b.TextSize = 12
    b.TextColor3 = Color3.new(1,1,1)
    b.BorderSizePixel = 0
    b.MouseButton1Click:Connect(function() pcall(cb) end)
end

local function addSlider(p, label, mn, mx, def, cb)
    local f = Instance.new("Frame", p)
    f.Size = UDim2.new(1, -4, 0, 38)
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

-- build tabs
local tM = addTab("Main")
local tF = addTab("Farm")
local tR = addTab("Rebirth")
local tP = addTab("Player")
local tV = addTab("Visual")

-- Main
local info = Instance.new("TextLabel", tM)
info.Size = UDim2.new(1, -4, 0, 70)
info.BackgroundTransparency = 1
info.Text = "ollie's bench v6\npotassium tuned\n\nbuilt by olivia\ndiscord.gg/ojailbreaks"
info.Font = Enum.Font.SourceSans
info.TextSize = 13
info.TextColor3 = Color3.fromRGB(200, 180, 240)
info.TextWrapped = true

addBtn(tM, "Rejoin Server", function() TPS:Teleport(game.PlaceId, LP) end)

-- Farm
addToggle(tF, "Auto Cut", function(v) S.AutoCut = v end)
addToggle(tF, "Auto Sell", function(v) S.AutoSell = v end)
addSlider(tF, "Mult", 1, 5, 1, function(v) S.Mult = v end)
addBtn(tF, "Collect Nearby", function()
    local r = hrp(); if not r then return end
    local fired = 0
    for _, o in ipairs(Grass) do
        if o.Parent and (o.Position - r.Position).Magnitude < 70 then
            for _, rm in ipairs(Cuts) do
                pcall(function() rm:FireServer(o) end)
                fired = fired + 1
                if fired % 10 == 0 then wait(0.05) end
            end
        end
    end
end)

-- Rebirth
addToggle(tR, "Auto Rebirth (humanized)", function(v) S.AutoRebirth = v end)
addSlider(tR, "Min Delay", 20, 300, 50, function(v) S.RebMin = v end)
addSlider(tR, "Max Delay", 60, 600, 140, function(v) S.RebMax = v end)
addBtn(tR, "Force One Rebirth", function()
    if #Rebs > 0 then
        local r = Rebs[math.random(1, #Rebs)]
        pcall(function() r:FireServer() end)
    end
end)
addToggle(tR, "EMERGENCY STOP", function(v)
    S.Stop = v
    if v then S.AutoCut=false; S.AutoSell=false; S.AutoRebirth=false end
end)

-- Player
addSlider(tP, "WalkSpeed", 16, 200, 16, function(v)
    S.WS = v; local h=hum(); if h then h.WalkSpeed = v end
end)
addSlider(tP, "JumpPower", 50, 200, 50, function(v)
    S.JP = v; local h=hum(); if h then h.JumpPower = v end
end)
addSlider(tP, "Gravity", 0, 200, 196, function(v) Workspace.Gravity = v end)
addToggle(tP, "NoClip", function(v) S.NoClip = v end)
addToggle(tP, "Infinite Jump", function(v) S.InfJump = v end)
addToggle(tP, "God Mode", function(v)
    S.God = v; local h = hum()
    if h then
        if v then h.MaxHealth = math.huge; h.Health = math.huge
        else h.MaxHealth = 100; h.Health = 100 end
    end
end)
addToggle(tP, "Fly", function(v) S.Fly = v end)
addSlider(tP, "Fly Speed", 20, 200, 80, function(v) S.FlySpd = v end)

-- Visual
addToggle(tV, "Player ESP", function(v)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChild("Head")
            if h then
                local ex = h:FindFirstChild("OllieESP")
                if ex then ex:Destroy() end
                if v then
                    local bb = Instance.new("BillboardGui", h)
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
addToggle(tV, "Grass ESP", function(v)
    if v then
        for _, o in ipairs(Grass) do
            if o.Parent and not o:FindFirstChild("OllieHL") then
                local hl = Instance.new("Highlight", o)
                hl.Name = "OllieHL"
                hl.FillColor = Color3.fromRGB(170, 0, 255)
            end
        end
    else
        for _, o in ipairs(Grass) do
            local h = o:FindFirstChild("OllieHL"); if h then h:Destroy() end
        end
    end
end)
addToggle(tV, "FullBright", function(v)
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

pickTab("Main")

-- ============ DEFERRED SCAN ============
spawn(function()
    wait(2)
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("BasePart") then
            local n = string.lower(o.Name)
            if string.find(n, "grass") or string.find(n, "blade") then
                table.insert(Grass, o)
            end
        end
    end
    for _, r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            local n = string.lower(r.Name)
            if string.find(n, "cut") or string.find(n, "chop") then table.insert(Cuts, r) end
            if string.find(n, "sell") then table.insert(Sells, r) end
            if string.find(n, "rebirth") or string.find(n, "prestige") then table.insert(Rebs, r) end
        end
    end
end)

-- ============ LOOPS ============
spawn(function()
    while gui.Parent do
        wait(0.3)
        if not S.Stop then
            if S.AutoCut then
                local r = hrp()
                if r then
                    local fired = 0
                    for _, o in ipairs(Grass) do
                        if fired >= 25 then break end
                        if o.Parent and (o.Position - r.Position).Magnitude < 60 then
                            for i = 1, S.Mult do
                                for _, rm in ipairs(Cuts) do
                                    pcall(function() rm:FireServer(o) end)
                                    fired = fired + 1
                                    if fired >= 25 then break end
                                end
                                if fired >= 25 then break end
                            end
                        end
                    end
                end
            end
            if S.AutoSell then
                for _, rm in ipairs(Sells) do pcall(function() rm:FireServer() end) end
            end
        end
    end
end)

spawn(function()
    while gui.Parent do
        local w = S.RebMin + math.random() * (S.RebMax - S.RebMin)
        local el = 0
        while el < w do
            if not S.AutoRebirth then break end
            wait(0.5); el = el + 0.5
        end
        if S.AutoRebirth and not S.Stop and #Rebs > 0 then
            local r = Rebs[math.random(1, #Rebs)]
            pcall(function() r:FireServer() end)
        end
    end
end)

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
    if S.InfJump then local h=hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
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
                flyBV.Velocity = Vector3.new(0,0,0)
                flyBG = Instance.new("BodyGyro", r)
                flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                flyBG.CFrame = r.CFrame
            end
        end
        if flyBV then
            local cam = Workspace.CurrentCamera
            local dir = Vector3.new(0,0,0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
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

print("[ollie] v6 potassium loaded")
