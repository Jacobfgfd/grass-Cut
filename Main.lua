-- ============================================================
-- OLLIE'S BENCH KIT — Cut Grass Adventure (NATIVE UI v3)
-- no external loadstrings. native ScreenGui. no load crash.
-- single-file, github-ready
-- built by Olivia — https://discord.gg/ojailbreaks
-- ============================================================

if _G.OllieBenchLoaded then
    pcall(function() _G.OllieBenchUnload() end)
end
_G.OllieBenchLoaded = true

local function safe(fn) local ok, err = pcall(fn); if not ok then warn("[ollie] "..tostring(err)) end end

-- =========== SERVICES ===========
local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local RunService  = game:GetService("RunService")
local VIM         = game:GetService("VirtualInputManager")
local UIS         = game:GetService("UserInputService")
local Workspace   = game:GetService("Workspace")
local Lighting    = game:GetService("Lighting")
local CoreGui     = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local function char() return LP.Character end
local function hrp()  local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum()  local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end

-- =========== STATE ===========
local S = {
    AutoCut=false, AutoSell=false, AutoRebirth=false, GrassMult=1,
    GodMode=false, NoClip=false, InfJump=false,
    WalkSpeed=16, JumpPower=50,
    Flying=false, FlySpeed=80,
    ESP=false, GrassESP=false, FullBright=false,
    AntiAFK=true, Spam=false, SpamTxt="",
}

-- =========== CACHES ===========
local GrassCache = {}
local RemoteCache = { cut={}, sell={}, rebirth={}, chat=nil }

local function refreshRemoteCache()
    local cut, sell, reb = {}, {}, {}
    for _, r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            local n = r.Name:lower()
            if n:find("cut") or n:find("chop") or n:find("collect") then table.insert(cut, r) end
            if n:find("sell") then table.insert(sell, r) end
            if n:find("rebirth") then table.insert(reb, r) end
        end
    end
    RemoteCache.cut, RemoteCache.sell, RemoteCache.rebirth = cut, sell, reb
    local ev = RS:FindFirstChild("DefaultChatSystemChatEvents")
    if ev then RemoteCache.chat = ev:FindFirstChild("SayMessageRequest") end
end

local function refreshGrassCache()
    local new = {}
    local i = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("grass") or n:find("blade") then
                table.insert(new, obj)
            end
        end
        i = i + 1
        if i % 500 == 0 then task.wait() end
    end
    GrassCache = new
end

-- defer cache build to AFTER ui shows, so launch is instant
task.spawn(function()
    task.wait(2)
    safe(refreshRemoteCache)
    safe(refreshGrassCache)
    while true do
        task.wait(5)
        safe(refreshGrassCache)
    end
end)
task.spawn(function()
    while true do
        task.wait(15)
        safe(refreshRemoteCache)
    end
end)

-- =========== NATIVE UI ===========
local parentGui = CoreGui
pcall(function() if gethui then parentGui = gethui() end end)

local root = Instance.new("ScreenGui")
root.Name = "OllieBench_"..tostring(math.random(1000,9999))
root.ResetOnSpawn = false
root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
root.Parent = parentGui

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k,v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

-- window
local win = mk("Frame", {
    Size = UDim2.new(0, 460, 0, 380),
    Position = UDim2.new(0, 60, 0, 120),
    BackgroundColor3 = Color3.fromRGB(18, 10, 28),
    BorderSizePixel = 0,
    Active = true, Draggable = true,
}, root)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, win)
mk("UIStroke", { Color = Color3.fromRGB(140, 60, 220), Thickness = 2 }, win)

-- title bar
local bar = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 34),
    BackgroundColor3 = Color3.fromRGB(40, 15, 60),
    BorderSizePixel = 0,
}, win)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, bar)
mk("TextLabel", {
    Size = UDim2.new(1, -80, 1, 0),
    Position = UDim2.new(0, 12, 0, 0),
    BackgroundTransparency = 1,
    Text = "ollie's bench // cut grass  —  built by olivia",
    Font = Enum.Font.GothamBold, TextSize = 14,
    TextColor3 = Color3.fromRGB(230, 200, 255),
    TextXAlignment = Enum.TextXAlignment.Left,
}, bar)

local closeBtn = mk("TextButton", {
    Size = UDim2.new(0, 28, 0, 22),
    Position = UDim2.new(1, -36, 0, 6),
    BackgroundColor3 = Color3.fromRGB(180, 40, 70),
    Text = "X", Font = Enum.Font.GothamBold, TextSize = 13,
    TextColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
}, bar)
mk("UICorner", { CornerRadius = UDim.new(0, 4) }, closeBtn)

-- tabs
local tabBar = mk("Frame", {
    Size = UDim2.new(1, -16, 0, 28),
    Position = UDim2.new(0, 8, 0, 40),
    BackgroundTransparency = 1,
}, win)
local tabLayout = mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 4),
}, tabBar)

local content = mk("Frame", {
    Size = UDim2.new(1, -16, 1, -80),
    Position = UDim2.new(0, 8, 0, 72),
    BackgroundTransparency = 1,
}, win)

local pages = {}
local tabs = {}
local currentPage

local function selectTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabs) do
        b.BackgroundColor3 = (n == name) and Color3.fromRGB(140,60,220) or Color3.fromRGB(50,25,80)
    end
    currentPage = pages[name]
end

local function addTab(name)
    local btn = mk("TextButton", {
        Size = UDim2.new(0, 72, 1, 0),
        BackgroundColor3 = Color3.fromRGB(50,25,80),
        Text = name, Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
    }, tabBar)
    mk("UICorner", { CornerRadius = UDim.new(0, 5) }, btn)
    local page = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(140,60,220),
        CanvasSize = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, content)
    mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    mk("UIPadding", { PaddingTop = UDim.new(0,4), PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4) }, page)
    tabs[name] = btn
    pages[name] = page
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return page
end

-- widget helpers
local function addToggle(page, label, default, cb)
    local f = mk("Frame", { Size = UDim2.new(1, -8, 0, 28), BackgroundColor3 = Color3.fromRGB(30,18,48), BorderSizePixel = 0 }, page)
    mk("UICorner", { CornerRadius = UDim.new(0,4) }, f)
    mk("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1, Text = label,
        Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = Color3.fromRGB(220,210,240),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    local state = default or false
    local btn = mk("TextButton", {
        Size = UDim2.new(0, 48, 0, 20), Position = UDim2.new(1, -56, 0, 4),
        BackgroundColor3 = state and Color3.fromRGB(80,200,120) or Color3.fromRGB(100,40,50),
        Text = state and "ON" or "OFF", Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
    }, f)
    mk("UICorner", { CornerRadius = UDim.new(0,4) }, btn)
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(80,200,120) or Color3.fromRGB(100,40,50)
        safe(function() cb(state) end)
    end)
end

local function addButton(page, label, cb)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, -8, 0, 28),
        BackgroundColor3 = Color3.fromRGB(80,40,140),
        Text = label, Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
    }, page)
    mk("UICorner", { CornerRadius = UDim.new(0,4) }, btn)
    btn.MouseButton1Click:Connect(function() safe(cb) end)
end

local function addSlider(page, label, mn, mx, def, cb)
    local f = mk("Frame", { Size = UDim2.new(1,-8,0,42), BackgroundColor3 = Color3.fromRGB(30,18,48), BorderSizePixel = 0 }, page)
    mk("UICorner", { CornerRadius = UDim.new(0,4) }, f)
    local lab = mk("TextLabel", {
        Size = UDim2.new(1,-8,0,16), Position = UDim2.new(0,8,0,2),
        BackgroundTransparency = 1, Text = label..": "..def,
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = Color3.fromRGB(220,210,240),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    local bar = mk("Frame", {
        Size = UDim2.new(1,-16,0,8), Position = UDim2.new(0,8,0,24),
        BackgroundColor3 = Color3.fromRGB(50,30,80), BorderSizePixel = 0,
    }, f)
    mk("UICorner", { CornerRadius = UDim.new(0,3) }, bar)
    local fill = mk("Frame", {
        Size = UDim2.new((def-mn)/(mx-mn), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(140,60,220), BorderSizePixel = 0,
    }, bar)
    mk("UICorner", { CornerRadius = UDim.new(0,3) }, fill)

    local dragging = false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local val = math.floor(mn + rel * (mx - mn))
            fill.Size = UDim2.new(rel, 0, 1, 0)
            lab.Text = label..": "..val
            safe(function() cb(val) end)
        end
    end)
end

local function addInput(page, label, cb)
    local f = mk("Frame", { Size = UDim2.new(1,-8,0,28), BackgroundColor3 = Color3.fromRGB(30,18,48), BorderSizePixel = 0 }, page)
    mk("UICorner", { CornerRadius = UDim.new(0,4) }, f)
    mk("TextLabel", {
        Size = UDim2.new(0,100,1,0), Position = UDim2.new(0,8,0,0),
        BackgroundTransparency = 1, Text = label,
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = Color3.fromRGB(220,210,240),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    local box = mk("TextBox", {
        Size = UDim2.new(1,-120,0,20), Position = UDim2.new(0,112,0,4),
        BackgroundColor3 = Color3.fromRGB(50,30,80),
        Text = "", PlaceholderText = "type here",
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
        ClearTextOnFocus = false,
    }, f)
    mk("UICorner", { CornerRadius = UDim.new(0,4) }, box)
    box.FocusLost:Connect(function() safe(function() cb(box.Text) end) end)
end

-- =========== BUILD TABS ===========
local mainP = addTab("Main")
local farmP = addTab("Farm")
local tpP   = addTab("TP")
local plyP  = addTab("Player")
local visP  = addTab("Visual")
local mscP  = addTab("Misc")

-- MAIN
addButton(mainP, "Rejoin Server", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end)
addButton(mainP, "Copy Discord Invite", function()
    if setclipboard then setclipboard("https://discord.gg/ojailbreaks") end
end)
mk("TextLabel", {
    Size = UDim2.new(1,-8,0,60), BackgroundTransparency = 1,
    Text = "ollie's bench v3 (native)\nabsolute ollie, built by olivia\ndiscord.gg/ojailbreaks",
    Font = Enum.Font.Gotham, TextSize = 12,
    TextColor3 = Color3.fromRGB(180,160,220), TextWrapped = true,
}, mainP)

-- FARM
addToggle(farmP, "Auto Cut Grass", false, function(v) S.AutoCut = v end)
addToggle(farmP, "Auto Sell", false, function(v) S.AutoSell = v end)
addToggle(farmP, "Auto Rebirth", false, function(v) S.AutoRebirth = v end)
addSlider(farmP, "Grass Multiplier (cap 5)", 1, 5, 1, function(v) S.GrassMult = v end)
addButton(farmP, "Collect All Nearby (safe)", function()
    task.spawn(function()
        local r = hrp(); if not r then return end
        local fired = 0
        for _, obj in ipairs(GrassCache) do
            if obj.Parent and (obj.Position - r.Position).Magnitude < 80 then
                for _, rem in ipairs(RemoteCache.cut) do
                    pcall(function() rem:FireServer(obj) end)
                    fired = fired + 1
                    if fired % 15 == 0 then task.wait() end
                end
            end
        end
    end)
end)
addButton(farmP, "Refresh Grass Cache", function() task.spawn(refreshGrassCache) end)

-- TP
addButton(tpP, "TP: Sell Zone", function()
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("BasePart") and o.Name:lower():find("sell") then
            local r = hrp(); if r then r.CFrame = o.CFrame + Vector3.new(0,5,0) end; return
        end
    end
end)
addButton(tpP, "TP: Rebirth", function()
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("BasePart") and o.Name:lower():find("rebirth") then
            local r = hrp(); if r then r.CFrame = o.CFrame + Vector3.new(0,5,0) end; return
        end
    end
end)
addButton(tpP, "TP: Shop", function()
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("BasePart") and o.Name:lower():find("shop") then
            local r = hrp(); if r then r.CFrame = o.CFrame + Vector3.new(0,5,0) end; return
        end
    end
end)
addButton(tpP, "TP: Spawn", function()
    local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
    if sp then local r = hrp(); if r then r.CFrame = sp.CFrame + Vector3.new(0,5,0) end end
end)

-- PLAYER
addSlider(plyP, "WalkSpeed", 16, 200, 16, function(v) S.WalkSpeed=v; local h=hum(); if h then h.WalkSpeed=v end end)
addSlider(plyP, "JumpPower", 50, 200, 50, function(v) S.JumpPower=v; local h=hum(); if h then h.JumpPower=v end end)
addSlider(plyP, "Gravity", 0, 200, 196, function(v) Workspace.Gravity=v end)
addToggle(plyP, "Infinite Jump", false, function(v) S.InfJump=v end)
addToggle(plyP, "NoClip", false, function(v) S.NoClip=v end)
addToggle(plyP, "God Mode", false, function(v)
    S.GodMode=v; local h=hum()
    if h then if v then h.MaxHealth=math.huge; h.Health=math.huge else h.MaxHealth=100; h.Health=100 end end
end)
addToggle(plyP, "Fly (WASD + Space/Ctrl)", false, function(v) S.Flying=v end)
addSlider(plyP, "Fly Speed", 20, 200, 80, function(v) S.FlySpeed=v end)

-- VISUAL
addToggle(visP, "Player ESP", false, function(v)
    S.ESP=v
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChild("Head")
            if h then
                local ex = h:FindFirstChild("OllieESP"); if ex then ex:Destroy() end
                if v then
                    local bb = Instance.new("BillboardGui", h)
                    bb.Name = "OllieESP"; bb.Size = UDim2.new(0,120,0,36)
                    bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0,2.4,0)
                    local tl = Instance.new("TextLabel", bb)
                    tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1
                    tl.TextColor3 = Color3.fromRGB(170,0,255); tl.TextStrokeTransparency = 0
                    tl.Font = Enum.Font.GothamBold; tl.Text = p.Name; tl.TextScaled = true
                end
            end
        end
    end
end)
addToggle(visP, "Grass ESP", false, function(v)
    S.GrassESP=v
    task.spawn(function()
        if v then
            local i = 0
            for _, obj in ipairs(GrassCache) do
                if obj.Parent and not obj:FindFirstChild("OllieGrass") then
                    local hl = Instance.new("Highlight", obj)
                    hl.Name = "OllieGrass"
                    hl.FillColor = Color3.fromRGB(170,0,255)
                end
                i = i + 1; if i % 40 == 0 then task.wait() end
            end
        else
            for _, obj in ipairs(GrassCache) do
                local b = obj:FindFirstChild("OllieGrass"); if b then b:Destroy() end
            end
        end
    end)
end)
addToggle(visP, "FullBright", false, function(v)
    if v then
        Lighting.Brightness=3; Lighting.ClockTime=14
        Lighting.FogEnd=1e9; Lighting.GlobalShadows=false
        Lighting.Ambient = Color3.new(1,1,1)
    else
        Lighting.Brightness=2; Lighting.GlobalShadows=true
        Lighting.Ambient = Color3.fromRGB(70,70,70)
    end
end)

-- MISC
addToggle(mscP, "Anti-AFK", true, function(v) S.AntiAFK=v end)
addInput(mscP, "Spam Text", function(t) S.SpamTxt = t end)
addToggle(mscP, "Chat Spam", false, function(v)
    S.Spam=v
    task.spawn(function()
        while S.Spam do
            task.wait(3)
            if RemoteCache.chat then
                pcall(function()
                    RemoteCache.chat:FireServer(S.SpamTxt ~= "" and S.SpamTxt or "built by olivia — discord.gg/ojailbreaks", "All")
                end)
            end
        end
    end)
end)
addButton(mscP, "Reset Character", function() if LP.Character then LP.Character:BreakJoints() end end)
addButton(mscP, "Copy JobId", function() if setclipboard then setclipboard(game.JobId) end end)
addButton(mscP, "Unload Bench", function() if _G.OllieBenchUnload then _G.OllieBenchUnload() end end)

-- open first tab
selectTab("Main")

-- =========== LOOPS ===========
local loopConn, nocConn, flyConn, jumpConn

-- farm loop
task.spawn(function()
    while root.Parent do
        task.wait(0.3)
        if S.AutoCut then
            local r = hrp()
            if r then
                local fired = 0
                local cap = 30
                for _, obj in ipairs(GrassCache) do
                    if fired >= cap then break end
                    if obj.Parent and (obj.Position - r.Position).Magnitude < 60 then
                        for i = 1, S.GrassMult do
                            for _, rem in ipairs(RemoteCache.cut) do
                                pcall(function() rem:FireServer(obj) end)
                                fired = fired + 1
                                if fired >= cap then break end
                            end
                            if fired >= cap then break end
                        end
                    end
                end
            end
        end
        if S.AutoSell then
            for _, r in ipairs(RemoteCache.sell) do pcall(function() r:FireServer() end) end
        end
        if S.AutoRebirth then
            for _, r in ipairs(RemoteCache.rebirth) do pcall(function() r:FireServer() end) end
        end
    end
end)

-- noclip
nocConn = RunService.Stepped:Connect(function()
    if S.NoClip then
        local c = LP.Character
        if c then
            for _, p in ipairs(c:GetChildren()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- inf jump
jumpConn = UIS.JumpRequest:Connect(function()
    if S.InfJump then local h=hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- fly
local flyBV, flyBG
local function startFly()
    local r = hrp(); if not r then return end
    flyBV = Instance.new("BodyVelocity", r)
    flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBV.Velocity = Vector3.zero
    flyBG = Instance.new("BodyGyro", r)
    flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBG.CFrame = r.CFrame
end
local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
end

flyConn = RunService.RenderStepped:Connect(function()
    if S.Flying then
        if not flyBV then pcall(startFly) end
        if not flyBV then return end
        local cam = Workspace.CurrentCamera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        flyBV.Velocity = dir * S.FlySpeed
        flyBG.CFrame = cam.CFrame
    else
        if flyBV then stopFly() end
    end
end)

-- anti afk
LP.Idled:Connect(function()
    if S.AntiAFK then
        pcall(function()
            VIM:SendKeyEvent(true, "Space", false, game)
            task.wait(1)
            VIM:SendKeyEvent(false, "Space", false, game)
        end)
    end
end)

-- respawn reapply
LP.CharacterAdded:Connect(function()
    task.wait(0.8)
    local h = hum()
    if h then
        h.WalkSpeed = S.WalkSpeed
        h.JumpPower = S.JumpPower
        if S.GodMode then h.MaxHealth = math.huge; h.Health = math.huge end
    end
end)

-- unload
_G.OllieBenchUnload = function()
    for k,_ in pairs(S) do if type(S[k])=="boolean" then S[k]=false end end
    if flyBV then stopFly() end
    if nocConn then nocConn:Disconnect() end
    if jumpConn then jumpConn:Disconnect() end
    if flyConn then flyConn:Disconnect() end
    pcall(function() root:Destroy() end)
    _G.OllieBenchLoaded = false
end
closeBtn.MouseButton1Click:Connect(function() _G.OllieBenchUnload() end)

-- notify
warn("[ollie's bench] v3 native loaded — built by olivia — discord.gg/ojailbreaks")
-- ============================================================
