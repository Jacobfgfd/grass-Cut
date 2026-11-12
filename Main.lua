-- ============================================================
-- OLLIE'S BENCH v5 — MINIMAL, CRASH-PROOF
-- Cut Grass Adventure · built by Olivia · discord.gg/ojailbreaks
-- ============================================================

local function try(f, ...) local ok, err = pcall(f, ...); if not ok then warn("[ollie]", err) end end

try(function()

if _G.OllieBench5 then pcall(function() _G.OllieBench5:Destroy() end) end

-- services
local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local Workspace  = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")
local CoreGui    = game:GetService("CoreGui")
local VIM        = game:GetService("VirtualInputManager")
local TPS        = game:GetService("TeleportService")
local LP         = Players.LocalPlayer

local function char() return LP.Character end
local function hrp()  local c=char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum()  local c=char(); return c and c:FindFirstChildOfClass("Humanoid") end

-- state
local S = {
    AutoCut=false, AutoSell=false, AutoRebirth=false, Mult=1,
    WS=16, JP=50, NoClip=false, InfJump=false, God=false,
    Fly=false, FlySpd=80, ESP=false, Bright=false,
    RebMin=50, RebMax=140,
    Stop=false,
}

-- caches (filled later, deferred)
local Grass, Cuts, Sells, Rebs = {}, {}, {}, {}

-- ============ UI ============
local gui = Instance.new("ScreenGui")
gui.Name = "OllieBench5"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
_G.OllieBench5 = gui

-- parent safely
local parented = false
pcall(function()
    if gethui then gui.Parent = gethui(); parented = true end
end)
if not parented then pcall(function() gui.Parent = CoreGui; parented = true end) end
if not parented then gui.Parent = LP:WaitForChild("PlayerGui") end

local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do pcall(function() o[k]=v end) end
    if parent then o.Parent = parent end
    return o
end

local win = mk("Frame", {
    Size = UDim2.new(0,440,0,360),
    Position = UDim2.new(0,80,0,120),
    BackgroundColor3 = Color3.fromRGB(18,10,28),
    BorderSizePixel = 0,
    Active = true, Draggable = true,
}, gui)
mk("UICorner", {CornerRadius=UDim.new(0,8)}, win)
mk("UIStroke", {Color=Color3.fromRGB(140,60,220), Thickness=2}, win)

local bar = mk("Frame", {
    Size=UDim2.new(1,0,0,32), BackgroundColor3=Color3.fromRGB(42,16,68), BorderSizePixel=0
}, win)
mk("UICorner",{CornerRadius=UDim.new(0,8)},bar)
mk("TextLabel",{
    Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,12,0,0),
    BackgroundTransparency=1, Text="ollie's bench v5 · built by olivia",
    Font=Enum.Font.GothamBold, TextSize=13,
    TextColor3=Color3.fromRGB(230,200,255),
    TextXAlignment=Enum.TextXAlignment.Left,
},bar)
local closeBtn = mk("TextButton",{
    Size=UDim2.new(0,26,0,22), Position=UDim2.new(1,-32,0,5),
    BackgroundColor3=Color3.fromRGB(180,40,70), Text="X",
    Font=Enum.Font.GothamBold, TextSize=12,
    TextColor3=Color3.new(1,1,1), BorderSizePixel=0,
},bar)
mk("UICorner",{CornerRadius=UDim.new(0,4)},closeBtn)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- tabs
local tabBar = mk("Frame",{
    Size=UDim2.new(1,-12,0,26), Position=UDim2.new(0,6,0,38),
    BackgroundTransparency=1,
},win)
mk("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,4)},tabBar)

local body = mk("Frame",{
    Size=UDim2.new(1,-12,1,-72), Position=UDim2.new(0,6,0,68),
    BackgroundTransparency=1,
},win)

local pages, tabs = {}, {}
local function pick(name)
    for n,p in pairs(pages) do p.Visible = (n==name) end
    for n,b in pairs(tabs) do
        b.BackgroundColor3 = (n==name) and Color3.fromRGB(140,60,220) or Color3.fromRGB(50,24,86)
    end
end

local function addTab(name)
    local b = mk("TextButton",{
        Size=UDim2.new(0,70,1,0), BackgroundColor3=Color3.fromRGB(50,24,86),
        Text=name, Font=Enum.Font.GothamBold, TextSize=12,
        TextColor3=Color3.new(1,1,1), BorderSizePixel=0,
    },tabBar)
    mk("UICorner",{CornerRadius=UDim.new(0,4)},b)
    local p = mk("ScrollingFrame",{
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
        ScrollBarThickness=3, CanvasSize=UDim2.new(0,0,0,1000),
        Visible=false,
    },body)
    mk("UIListLayout",{Padding=UDim.new(0,4)},p)
    mk("UIPadding",{PaddingTop=UDim.new(0,4), PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4)},p)
    tabs[name] = b; pages[name] = p
    b.MouseButton1Click:Connect(function() pick(name) end)
    return p
end

local function addToggle(p, label, def, cb)
    local f = mk("Frame",{Size=UDim2.new(1,-8,0,28), BackgroundColor3=Color3.fromRGB(30,16,48), BorderSizePixel=0},p)
    mk("UICorner",{CornerRadius=UDim.new(0,4)},f)
    mk("TextLabel",{
        Size=UDim2.new(1,-60,1,0), Position=UDim2.new(0,10,0,0),
        BackgroundTransparency=1, Text=label,
        Font=Enum.Font.Gotham, TextSize=12,
        TextColor3=Color3.fromRGB(220,210,240),
        TextXAlignment=Enum.TextXAlignment.Left,
    },f)
    local st = def and true or false
    local b = mk("TextButton",{
        Size=UDim2.new(0,48,0,20), Position=UDim2.new(1,-54,0,4),
        BackgroundColor3 = st and Color3.fromRGB(80,200,120) or Color3.fromRGB(100,40,50),
        Text = st and "ON" or "OFF",
        Font=Enum.Font.GothamBold, TextSize=11,
        TextColor3=Color3.new(1,1,1), BorderSizePixel=0,
    },f)
    mk("UICorner",{CornerRadius=UDim.new(0,4)},b)
    b.MouseButton1Click:Connect(function()
        st = not st
        b.Text = st and "ON" or "OFF"
        b.BackgroundColor3 = st and Color3.fromRGB(80,200,120) or Color3.fromRGB(100,40,50)
        try(cb, st)
    end)
end

local function addBtn(p, label, cb)
    local b = mk("TextButton",{
        Size=UDim2.new(1,-8,0,26), BackgroundColor3=Color3.fromRGB(80,40,140),
        Text=label, Font=Enum.Font.GothamBold, TextSize=12,
        TextColor3=Color3.new(1,1,1), BorderSizePixel=0,
    },p)
    mk("UICorner",{CornerRadius=UDim.new(0,4)},b)
    b.MouseButton1Click:Connect(function() try(cb) end)
end

local function addSlider(p, label, mn, mx, def, cb)
    local f = mk("Frame",{Size=UDim2.new(1,-8,0,40), BackgroundColor3=Color3.fromRGB(30,16,48), BorderSizePixel=0},p)
    mk("UICorner",{CornerRadius=UDim.new(0,4)},f)
    local lab = mk("TextLabel",{
        Size=UDim2.new(1,-16,0,16), Position=UDim2.new(0,8,0,2),
        BackgroundTransparency=1, Text=label..": "..def,
        Font=Enum.Font.Gotham, TextSize=11,
        TextColor3=Color3.fromRGB(220,210,240),
        TextXAlignment=Enum.TextXAlignment.Left,
    },f)
    local track = mk("Frame",{
        Size=UDim2.new(1,-16,0,6), Position=UDim2.new(0,8,0,24),
        BackgroundColor3=Color3.fromRGB(50,30,80), BorderSizePixel=0,
    },f)
    mk("UICorner",{CornerRadius=UDim.new(0,3)},track)
    local fill = mk("Frame",{
        Size=UDim2.new((def-mn)/(mx-mn),0,1,0),
        BackgroundColor3=Color3.fromRGB(140,60,220), BorderSizePixel=0,
    },track)
    mk("UICorner",{CornerRadius=UDim.new(0,3)},fill)

    local drag = false
    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local rel = math.clamp((i.Position.X - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
            local val = math.floor(mn + rel*(mx-mn))
            fill.Size = UDim2.new(rel,0,1,0)
            lab.Text = label..": "..val
            try(cb, val)
        end
    end)
end

-- build tabs
local tM = addTab("Main")
local tF = addTab("Farm")
local tR = addTab("Rebirth")
local tP = addTab("Player")
local tV = addTab("Visual")
local tX = addTab("Misc")

-- Main
mk("TextLabel",{
    Size=UDim2.new(1,-8,0,80), BackgroundTransparency=1,
    Text="ollie's bench v5\nminimal · crash-proof\n\nabsolute ollie, built by olivia\ndiscord.gg/ojailbreaks",
    Font=Enum.Font.Gotham, TextSize=12,
    TextColor3=Color3.fromRGB(200,180,240), TextWrapped=true,
},tM)
addBtn(tM, "Rejoin Server", function() TPS:Teleport(game.PlaceId, LP) end)
addBtn(tM, "Copy Discord", function()
    if setclipboard then setclipboard("https://discord.gg/ojailbreaks") end
end)

-- Farm
addToggle(tF, "Auto Cut", false, function(v) S.AutoCut=v end)
addToggle(tF, "Auto Sell", false, function(v) S.AutoSell=v end)
addSlider(tF, "Multiplier", 1, 5, 1, function(v) S.Mult=v end)
addBtn(tF, "Collect All Nearby", function()
    task.spawn(function()
        local r = hrp(); if not r then return end
        local fired = 0
        for _, o in ipairs(Grass) do
            if o.Parent and (o.Position-r.Position).Magnitude < 70 then
                for _, rm in ipairs(Cuts) do
                    pcall(function() rm:FireServer(o) end)
                    fired = fired + 1
                    if fired % 15 == 0 then task.wait(0.05) end
                end
            end
        end
    end)
end)
addBtn(tF, "Rescan Grass", function() task.spawn(function()
    Grass = {}
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("BasePart") then
            local n = o.Name:lower()
            if n:find("grass") or n:find("blade") or n:find("wheat") then
                table.insert(Grass, o)
            end
        end
    end
end) end)

-- Rebirth (humanized)
mk("TextLabel",{
    Size=UDim2.new(1,-8,0,40), BackgroundTransparency=1,
    Text="humanized: random 50-140s delay, fires ONE random remote per attempt, aborts if EMERGENCY STOP",
    Font=Enum.Font.Gotham, TextSize=11,
    TextColor3=Color3.fromRGB(180,160,220), TextWrapped=true,
},tR)
addToggle(tR, "Auto Rebirth", false, function(v) S.AutoRebirth=v end)
addSlider(tR, "Min Delay (s)", 20, 300, 50, function(v) S.RebMin=v end)
addSlider(tR, "Max Delay (s)", 60, 600, 140, function(v) S.RebMax=math.max(v, S.RebMin+10) end)
addBtn(tR, "Force One Attempt", function()
    if #Rebs > 0 then
        local r = Rebs[math.random(1,#Rebs)]
        pcall(function() r:FireServer() end)
    end
end)
addToggle(tR, "EMERGENCY STOP", false, function(v)
    S.Stop = v
    if v then S.AutoCut=false; S.AutoSell=false; S.AutoRebirth=false end
end)

-- Player
addSlider(tP, "WalkSpeed", 16, 200, 16, function(v) S.WS=v; local h=hum(); if h then h.WalkSpeed=v end end)
addSlider(tP, "JumpPower", 50, 200, 50, function(v) S.JP=v; local h=hum(); if h then h.JumpPower=v end end)
addSlider(tP, "Gravity", 0, 200, 196, function(v) Workspace.Gravity=v end)
addToggle(tP, "NoClip", false, function(v) S.NoClip=v end)
addToggle(tP, "Infinite Jump", false, function(v) S.InfJump=v end)
addToggle(tP, "God Mode", false, function(v)
    S.God=v; local h=hum()
    if h then
        if v then h.MaxHealth=math.huge; h.Health=math.huge
        else h.MaxHealth=100; h.Health=100 end
    end
end)
addToggle(tP, "Fly (WASD/Space/Ctrl)", false, function(v) S.Fly=v end)
addSlider(tP, "Fly Speed", 20, 200, 80, function(v) S.FlySpd=v end)

-- Visual
addToggle(tV, "Player ESP", false, function(v)
    S.ESP=v
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChild("Head")
            if h then
                local ex = h:FindFirstChild("OllieESP"); if ex then ex:Destroy() end
                if v then
                    local bb = Instance.new("BillboardGui", h)
                    bb.Name="OllieESP"; bb.Size=UDim2.new(0,120,0,36)
                    bb.AlwaysOnTop=true; bb.StudsOffset=Vector3.new(0,2.4,0)
                    local tl = Instance.new("TextLabel", bb)
                    tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1
                    tl.TextColor3=Color3.fromRGB(170,0,255); tl.TextStrokeTransparency=0
                    tl.Font=Enum.Font.GothamBold; tl.Text=p.Name; tl.TextScaled=true
                end
            end
        end
    end
end)
addToggle(tV, "Grass ESP", false, function(v)
    task.spawn(function()
        if v then
            local i=0
            for _, o in ipairs(Grass) do
                if o.Parent and not o:FindFirstChild("OllieHL") then
                    local hl = Instance.new("Highlight", o)
                    hl.Name="OllieHL"
                    hl.FillColor=Color3.fromRGB(170,0,255)
                end
                i=i+1; if i%40==0 then task.wait() end
            end
        else
            for _, o in ipairs(Grass) do
                local h=o:FindFirstChild("OllieHL"); if h then h:Destroy() end
            end
        end
    end)
end)
addToggle(tV, "FullBright", false, function(v)
    if v then
        Lighting.Brightness=3; Lighting.ClockTime=14
        Lighting.FogEnd=1e9; Lighting.GlobalShadows=false
        Lighting.Ambient=Color3.new(1,1,1)
    else
        Lighting.Brightness=2; Lighting.GlobalShadows=true
        Lighting.Ambient=Color3.fromRGB(70,70,70)
    end
end)

-- Misc
addBtn(tX, "Reset Character", function() if LP.Character then LP.Character:BreakJoints() end end)
addBtn(tX, "Copy JobId", function() if setclipboard then setclipboard(game.JobId) end end)
addBtn(tX, "Unload Bench", function() gui:Destroy() end)

pick("Main")

-- ============ DEFERRED SCAN (after UI shown) ============
task.spawn(function()
    task.wait(1.5)
    try(function()
        for _, o in ipairs(Workspace:GetDescendants()) do
            if o:IsA("BasePart") then
                local n = o.Name:lower()
                if n:find("grass") or n:find("blade") or n:find("wheat") then
                    table.insert(Grass, o)
                end
            end
        end
    end)
    try(function()
        for _, r in ipairs(RS:GetDescendants()) do
            if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                local n = r.Name:lower()
                if n:find("cut") or n:find("chop") then table.insert(Cuts, r) end
                if n:find("sell") then table.insert(Sells, r) end
                if n:find("rebirth") or n:find("prestige") then table.insert(Rebs, r) end
            end
        end
    end)
end)

-- ============ LOOPS ============
-- farm loop (slow, capped)
task.spawn(function()
    while gui.Parent do
        task.wait(0.3)
        if not S.Stop then
            if S.AutoCut then
                local r = hrp()
                if r then
                    local fired = 0
                    for _, o in ipairs(Grass) do
                        if fired >= 25 then break end
                        if o.Parent and (o.Position-r.Position).Magnitude < 60 then
                            for i=1, S.Mult do
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

-- humanized rebirth loop
task.spawn(function()
    while gui.Parent do
        local w = S.RebMin + math.random() * (S.RebMax - S.RebMin)
        local el = 0
        while el < w do
            if not S.AutoRebirth then break end
            task.wait(0.5); el = el + 0.5
        end
        if S.AutoRebirth and not S.Stop and #Rebs > 0 then
            local r = Rebs[math.random(1, #Rebs)]
            pcall(function() r:FireServer() end)
        end
    end
end)

-- noclip
RunService.Stepped:Connect(function()
    if S.NoClip and gui.Parent then
        local c = LP.Character
        if c then
            for _, p in ipairs(c:GetChildren()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end
    end
end)

-- inf jump
UIS.JumpRequest:Connect(function()
    if S.InfJump then local h=hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- fly
local flyBV, flyBG
RunService.RenderStepped:Connect(function()
    if not gui.Parent then return end
    if S.Fly then
        if not flyBV then
            local r = hrp()
            if r then
                flyBV = Instance.new("BodyVelocity", r)
                flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                flyBV.Velocity = Vector3.zero
                flyBG = Instance.new("BodyGyro", r)
                flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                flyBG.CFrame = r.CFrame
            end
        end
        if flyBV then
            local cam = Workspace.CurrentCamera
            local dir = Vector3.zero
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
        if flyBV then flyBV:Destroy(); flyBV=nil end
        if flyBG then flyBG:Destroy(); flyBG=nil end
    end
end)

-- respawn reapply
LP.CharacterAdded:Connect(function()
    task.wait(0.8)
    local h = hum()
    if h then
        h.WalkSpeed = S.WS; h.JumpPower = S.JP
        if S.God then h.MaxHealth = math.huge; h.Health = math.huge end
    end
end)

warn("[ollie's bench v5] loaded · built by olivia · discord.gg/ojailbreaks")

end) -- end try
