-- ============================================================
-- OLLIE'S BENCH KIT — Cut Grass Adventure  (LEAN BUILD v2)
-- single-file, github-ready, crash-patched
-- built by Olivia — https://discord.gg/ojailbreaks
-- ============================================================

local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not ok or not Rayfield then warn("[ollie] rayfield load failed") return end

-- =========== SERVICES ===========
local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local RunService  = game:GetService("RunService")
local VIM         = game:GetService("VirtualInputManager")
local UIS         = game:GetService("UserInputService")
local Workspace   = game:GetService("Workspace")
local Lighting    = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local function char() return LP.Character or LP.CharacterAdded:Wait() end
local function hrp()  return char():FindFirstChild("HumanoidRootPart") end
local function hum()  return char():FindFirstChildOfClass("Humanoid") end

-- =========== STATE ===========
local S = {
    AutoCut=false, AutoSell=false, AutoRebirth=false,
    GrassMult=1,
    GodMode=false, NoClip=false, InfJump=false,
    WalkSpeed=16, JumpPower=50,
    Flying=false, FlySpeed=80,
    ESP=false, GrassESP=false,
    ESPColor=Color3.fromRGB(170,0,255),
    AntiAFK=true, Spam=false, SpamTxt="",
    TPTarget=nil,
}

-- =========== CACHE (fix the load crash) ===========
local GrassCache = {}      -- {part,...}
local RemoteCache = {      -- cached once, refreshed slow
    cut = {}, sell = {}, rebirth = {}, chat = nil,
}

local function refreshRemoteCache()
    RemoteCache.cut, RemoteCache.sell, RemoteCache.rebirth = {}, {}, {}
    for _, r in ipairs(RS:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            local n = r.Name:lower()
            if n:find("cut") or n:find("chop") or n:find("collect") then table.insert(RemoteCache.cut, r) end
            if n:find("sell") then table.insert(RemoteCache.sell, r) end
            if n:find("rebirth") then table.insert(RemoteCache.rebirth, r) end
        end
    end
    local ev = RS:FindFirstChild("DefaultChatSystemChatEvents")
    if ev then RemoteCache.chat = ev:FindFirstChild("SayMessageRequest") end
end
refreshRemoteCache()

local function refreshGrassCache()
    GrassCache = {}
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("grass") or n:find("blade") then
                table.insert(GrassCache, obj)
                count = count + 1
                if count % 200 == 0 then task.wait() end -- yield so we don't freeze
            end
        end
    end
end

-- slow background refresher (every 3s, not every frame)
task.spawn(function()
    while true do
        pcall(refreshGrassCache)
        task.wait(3)
    end
end)

task.spawn(function()
    while true do
        pcall(refreshRemoteCache)
        task.wait(10)
    end
end)

-- =========== WINDOW ===========
local Window = Rayfield:CreateWindow({
   Name = "ollie's bench // cut grass v2",
   LoadingTitle = "absolute ollie, built by olivia",
   LoadingSubtitle = "lean build — discord.gg/ojailbreaks",
   ConfigurationSaving = { Enabled = true, FolderName = "OllieBench", FileName = "CutGrassV2" },
   KeySystem = false,
   Theme = "Amethyst"
})

-- =========== MAIN ===========
local Main = Window:CreateTab("Main", 4483362458)
Main:CreateSection("Status")
Main:CreateParagraph({ Title="loaded", Content="ollie's bench v2 — lean + crash-patched. built by Olivia · discord.gg/ojailbreaks" })

Main:CreateButton({
    Name="Rejoin Server",
    Callback=function() game:GetService("TeleportService"):Teleport(game.PlaceId, LP) end
})

Main:CreateButton({
    Name="Server Hop",
    Callback=function()
        task.spawn(function()
            local TSvc = game:GetService("TeleportService")
            local ok2, raw = pcall(function()
                return game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId))
            end)
            if not ok2 then return end
            local okJ, data = pcall(HttpService.JSONDecode, HttpService, raw)
            if not okJ or not data or not data.data then return end
            for _, s in ipairs(data.data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TSvc:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                    break
                end
            end
        end)
    end
})

-- =========== FARM ===========
local Farm = Window:CreateTab("Farm", 7733678994)
Farm:CreateSection("Grass automation (throttled)")

Farm:CreateToggle({ Name="Auto Cut Grass",    CurrentValue=false, Flag="AutoCut",  Callback=function(v) S.AutoCut=v end })
Farm:CreateToggle({ Name="Auto Sell",         CurrentValue=false, Flag="AutoSell", Callback=function(v) S.AutoSell=v end })
Farm:CreateToggle({ Name="Auto Rebirth",      CurrentValue=false, Flag="AutoReb",  Callback=function(v) S.AutoRebirth=v end })

Farm:CreateSlider({
    Name="Grass Multiplier (safe cap 10)",
    Range={1,10}, Increment=1, Suffix="x",
    CurrentValue=1, Flag="GrassMult",
    Callback=function(v) S.GrassMult = math.clamp(v,1,10) end
})

Farm:CreateButton({
    Name="Collect All Nearby (throttled one-shot)",
    Callback=function()
        task.spawn(function()
            local root = hrp(); if not root then return end
            local fired = 0
            for _, obj in ipairs(GrassCache) do
                if obj.Parent and (obj.Position - root.Position).Magnitude < 80 then
                    for _, remote in ipairs(RemoteCache.cut) do
                        pcall(function() remote:FireServer(obj) end)
                        fired = fired + 1
                        if fired % 20 == 0 then task.wait() end -- yield every 20 fires
                    end
                end
            end
        end)
    end
})

-- lean auto loop (0.25s cadence, capped fires per tick)
task.spawn(function()
    while true do
        task.wait(0.25)
        if S.AutoCut then
            local root = hrp()
            if root then
                local firedThisTick = 0
                local cap = 40 -- hard cap per cycle, prevents disconnect
                for _, obj in ipairs(GrassCache) do
                    if firedThisTick >= cap then break end
                    if obj.Parent and (obj.Position - root.Position).Magnitude < 60 then
                        for i = 1, S.GrassMult do
                            for _, remote in ipairs(RemoteCache.cut) do
                                pcall(function() remote:FireServer(obj) end)
                                firedThisTick = firedThisTick + 1
                                if firedThisTick >= cap then break end
                            end
                            if firedThisTick >= cap then break end
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

-- =========== TELEPORT ===========
local TP = Window:CreateTab("Teleport", 7072718362)
TP:CreateSection("Map locations")

local function tpToName(key)
    task.spawn(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find(key) then
                local r = hrp(); if r then r.CFrame = obj.CFrame + Vector3.new(0,5,0) end
                return
            end
        end
    end)
end

TP:CreateButton({ Name="Teleport: Sell",    Callback=function() tpToName("sell") end })
TP:CreateButton({ Name="Teleport: Rebirth", Callback=function() tpToName("rebirth") end })
TP:CreateButton({ Name="Teleport: Shop",    Callback=function() tpToName("shop") end })
TP:CreateButton({ Name="Teleport: Spawn",   Callback=function()
    local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
    if sp then local r = hrp(); if r then r.CFrame = sp.CFrame + Vector3.new(0,5,0) end end
end })

TP:CreateSection("Player teleport")
local function playerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(t, p.Name) end
    end
    return t
end
local pDrop = TP:CreateDropdown({
    Name="Pick Player", Options=playerNames(),
    CurrentOption={}, MultipleOptions=false, Flag="TPPlayer",
    Callback=function(opt) S.TPTarget = (type(opt)=="table" and opt[1]) or opt end
})
TP:CreateButton({
    Name="Teleport to Player",
    Callback=function()
        local t = Players:FindFirstChild(S.TPTarget or "")
        if t and t.Character then
            local r = hrp()
            local tr = t.Character:FindFirstChild("HumanoidRootPart")
            if r and tr then r.CFrame = tr.CFrame + Vector3.new(0,3,0) end
        end
    end
})
Players.PlayerAdded:Connect(function() pcall(function() pDrop:Refresh(playerNames()) end) end)
Players.PlayerRemoving:Connect(function() pcall(function() pDrop:Refresh(playerNames()) end) end)

-- =========== PLAYER ===========
local Ply = Window:CreateTab("Player", 7733996289)
Ply:CreateSection("Movement")

Ply:CreateSlider({ Name="WalkSpeed", Range={16,300}, Increment=1, CurrentValue=16,
    Callback=function(v) S.WalkSpeed=v; local h=hum(); if h then h.WalkSpeed=v end end })
Ply:CreateSlider({ Name="JumpPower", Range={50,300}, Increment=5, CurrentValue=50,
    Callback=function(v) S.JumpPower=v; local h=hum(); if h then h.JumpPower=v end end })
Ply:CreateSlider({ Name="Gravity", Range={0,200}, Increment=1, CurrentValue=196,
    Callback=function(v) Workspace.Gravity=v end })

Ply:CreateToggle({ Name="Infinite Jump", CurrentValue=false, Callback=function(v) S.InfJump=v end })
Ply:CreateToggle({ Name="NoClip",        CurrentValue=false, Callback=function(v) S.NoClip=v end })

Ply:CreateToggle({ Name="God Mode (local)", CurrentValue=false,
    Callback=function(v)
        S.GodMode=v
        local h = hum()
        if h then
            if v then h.MaxHealth=math.huge; h.Health=math.huge
            else h.MaxHealth=100; h.Health=100 end
        end
    end
})

Ply:CreateToggle({ Name="Fly", CurrentValue=false, Callback=function(v) S.Flying=v end })
Ply:CreateSlider({ Name="Fly Speed", Range={20,300}, Increment=5, CurrentValue=80,
    Callback=function(v) S.FlySpeed=v end })

UIS.JumpRequest:Connect(function()
    if S.InfJump then local h=hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

RunService.Stepped:Connect(function()
    if S.NoClip then
        local c = LP.Character
        if c then
            for _, p in ipairs(c:GetChildren()) do
                if p:IsA("BasePart") then p.CanCollide=false end
            end
        end
    end
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
RunService.RenderStepped:Connect(function()
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

-- =========== VISUALS ===========
local Vis = Window:CreateTab("Visuals", 7733964388)

local function applyESP(p, on)
    if p == LP or not p.Character then return end
    local h = p.Character:FindFirstChild("Head"); if not h then return end
    local ex = h:FindFirstChild("OllieESP"); if ex then ex:Destroy() end
    if on then
        local bb = Instance.new("BillboardGui", h)
        bb.Name = "OllieESP"
        bb.Size = UDim2.new(0, 120, 0, 36)
        bb.AlwaysOnTop = true
        bb.StudsOffset = Vector3.new(0, 2.4, 0)
        local tl = Instance.new("TextLabel", bb)
        tl.Size = UDim2.new(1,0,1,0)
        tl.BackgroundTransparency = 1
        tl.TextColor3 = S.ESPColor
        tl.TextStrokeTransparency = 0
        tl.Font = Enum.Font.GothamBold
        tl.Text = p.Name
        tl.TextScaled = true
    end
end

Vis:CreateToggle({
    Name="Player ESP",
    Callback=function(v)
        S.ESP=v
        for _, p in ipairs(Players:GetPlayers()) do applyESP(p, v) end
    end
})
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if S.ESP then applyESP(p, true) end
    end)
end)

Vis:CreateToggle({
    Name="Grass ESP (cached, slow)",
    Callback=function(v)
        S.GrassESP=v
        task.spawn(function()
            if v then
                local i = 0
                for _, obj in ipairs(GrassCache) do
                    if obj.Parent and not obj:FindFirstChild("OllieGrass") then
                        local hl = Instance.new("Highlight", obj)
                        hl.Name = "OllieGrass"
                        hl.FillColor = S.ESPColor
                        hl.OutlineColor = Color3.fromRGB(255,255,255)
                    end
                    i = i + 1
                    if i % 50 == 0 then task.wait() end
                end
            else
                for _, obj in ipairs(GrassCache) do
                    local b = obj:FindFirstChild("OllieGrass"); if b then b:Destroy() end
                end
            end
        end)
    end
})

Vis:CreateToggle({
    Name="FullBright",
    Callback=function(v)
        if v then
            Lighting.Brightness = 3; Lighting.ClockTime = 14
            Lighting.FogEnd = 1e9; Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.new(1,1,1)
        else
            Lighting.Brightness = 2; Lighting.GlobalShadows = true
            Lighting.Ambient = Color3.fromRGB(70,70,70)
        end
    end
})

Vis:CreateColorPicker({ Name="ESP Color", Color=Color3.fromRGB(170,0,255),
    Callback=function(c) S.ESPColor=c end })

-- =========== MISC ===========
local Misc = Window:CreateTab("Misc", 7734053495)

Misc:CreateToggle({ Name="Anti-AFK", CurrentValue=true, Callback=function(v) S.AntiAFK=v end })
LP.Idled:Connect(function()
    if S.AntiAFK then
        pcall(function()
            VIM:SendKeyEvent(true, "Space", false, game)
            task.wait(1)
            VIM:SendKeyEvent(false, "Space", false, game)
        end)
    end
end)

Misc:CreateButton({ Name="Reset Character", Callback=function()
    pcall(function() LP.Character:BreakJoints() end)
end })
Misc:CreateButton({ Name="Copy JobId", Callback=function()
    if setclipboard then setclipboard(game.JobId) end
end })

Misc:CreateInput({ Name="Chat Spam Text", PlaceholderText="type here",
    RemoveTextAfterFocusLost=false, Callback=function(txt) S.SpamTxt=txt end })
Misc:CreateToggle({ Name="Chat Spam ON",
    Callback=function(v)
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
    end
})

Misc:CreateButton({ Name="Unload Bench", Callback=function()
    for k,_ in pairs(S) do if type(S[k])=="boolean" then S[k]=false end end
    if flyBV then stopFly() end
    pcall(function() Rayfield:Destroy() end)
end })

-- =========== RESPAWN REAPPLY ===========
LP.CharacterAdded:Connect(function()
    task.wait(0.8)
    local h = hum()
    if h then
        h.WalkSpeed = S.WalkSpeed
        h.JumpPower = S.JumpPower
        if S.GodMode then h.MaxHealth = math.huge; h.Health = math.huge end
    end
end)

-- =========== DONE ===========
pcall(function() Rayfield:LoadConfiguration() end)
Rayfield:Notify({
    Title = "ollie's bench v2",
    Content = "lean build loaded — absolute ollie, built by olivia",
    Duration = 6,
    Image = 4483362458
})
-- ============================================================
-- built by Olivia — https://discord.gg/ojailbreaks
-- ============================================================
