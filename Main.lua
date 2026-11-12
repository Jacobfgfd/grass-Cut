-- ============================================================
-- OLLIE'S BENCH KIT — Cut Grass Adventure
-- single-file build, github-ready, paste into any executor
-- loader: loadstring(game:HttpGet("<raw-url>"))()
-- built by Olivia — https://discord.gg/ojailbreaks
-- ============================================================

-- =========== RAYFIELD UI BOOT ===========
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)
if not ok or not Rayfield then
    warn("[ollie] rayfield failed to load — check executor http perms")
    return
end

-- =========== SERVICES ===========
local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local RunService  = game:GetService("RunService")
local VIM         = game:GetService("VirtualInputManager")
local UIS         = game:GetService("UserInputService")
local TS          = game:GetService("TweenService")
local Workspace   = game:GetService("Workspace")
local Lighting    = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local function char() return LP.Character or LP.CharacterAdded:Wait() end
local function hrp()  return char():WaitForChild("HumanoidRootPart") end
local function hum()  return char():WaitForChild("Humanoid") end

-- =========== STATE ===========
local S = {
    AutoCut=false, AutoSell=false, AutoRebirth=false,
    InfGrass=false, GrassMult=100,
    GodMode=false, NoClip=false, InfJump=false,
    WalkSpeed=16, JumpPower=50,
    Flying=false, FlySpeed=80,
    ESP=false, GrassESP=false,
    ESPColor=Color3.fromRGB(170,0,255),
    AntiAFK=true, Spam=false, SpamTxt="",
    TPTarget=nil,
}

-- =========== WINDOW ===========
local Window = Rayfield:CreateWindow({
   Name = "ollie's bench // cut grass",
   LoadingTitle = "absolute ollie, built by olivia",
   LoadingSubtitle = "iron's hot — discord.gg/ojailbreaks",
   ConfigurationSaving = { Enabled = true, FolderName = "OllieBench", FileName = "CutGrass" },
   KeySystem = false,
   Theme = "Amethyst"
})

-- =========== MAIN TAB ===========
local Main = Window:CreateTab("Main", 4483362458)
Main:CreateSection("Status")
Main:CreateParagraph({ Title = "loaded", Content = "ollie's bench live. built by Olivia — discord.gg/ojailbreaks" })

Main:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
    end
})

Main:CreateButton({
    Name = "Server Hop (new server)",
    Callback = function()
        local TSvc = game:GetService("TeleportService")
        local ok2, raw = pcall(function()
            return game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId))
        end)
        if not ok2 then return end
        local data = HttpService:JSONDecode(raw)
        for _, s in ipairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TSvc:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                break
            end
        end
    end
})

Main:CreateButton({
    Name = "Copy Discord Invite",
    Callback = function()
        if setclipboard then setclipboard("https://discord.gg/ojailbreaks") end
        Rayfield:Notify({ Title="copied", Content="discord.gg/ojailbreaks", Duration=4 })
    end
})

-- =========== FARM TAB ===========
local Farm = Window:CreateTab("Farm", 7733678994)
Farm:CreateSection("Grass automation")

Farm:CreateToggle({ Name="Auto Cut Grass",       CurrentValue=false, Flag="AutoCut",  Callback=function(v) S.AutoCut=v end })
Farm:CreateToggle({ Name="Auto Sell on Full",    CurrentValue=false, Flag="AutoSell", Callback=function(v) S.AutoSell=v end })
Farm:CreateToggle({ Name="Auto Rebirth",         CurrentValue=false, Flag="AutoReb",  Callback=function(v) S.AutoRebirth=v end })

Farm:CreateSlider({
    Name="Grass Multiplier (local x N)",
    Range={1,500}, Increment=1, Suffix="x",
    CurrentValue=100, Flag="GrassMult",
    Callback=function(v) S.GrassMult=v end
})

Farm:CreateToggle({ Name="Inf Grass (local pickup loop)", CurrentValue=false, Flag="InfGrass", Callback=function(v) S.InfGrass=v end })

Farm:CreateButton({
    Name = "Collect All Nearby (one-shot)",
    Callback = function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:lower():find("grass") or obj.Name:lower():find("blade")) then
                for _, remote in ipairs(RS:GetDescendants()) do
                    if remote:IsA("RemoteEvent") and remote.Name:lower():find("cut") then
                        pcall(function() remote:FireServer(obj) end)
                    end
                end
            end
        end
    end
})

-- the loop
task.spawn(function()
    while task.wait(0.05) do
        if S.AutoCut then
            local ok3, root = pcall(hrp)
            if ok3 then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and (obj.Name:lower():find("grass") or obj.Name:lower():find("blade")) then
                        if (obj.Position - root.Position).Magnitude < 60 then
                            for i = 1, S.GrassMult do
                                for _, remote in ipairs(RS:GetDescendants()) do
                                    if remote:IsA("RemoteEvent") then
                                        local n = remote.Name:lower()
                                        if n:find("cut") or n:find("chop") or n:find("collect") then
                                            pcall(function() remote:FireServer(obj) end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        if S.AutoSell then
            for _, remote in ipairs(RS:GetDescendants()) do
                if remote:IsA("RemoteEvent") and remote.Name:lower():find("sell") then
                    pcall(function() remote:FireServer() end)
                end
            end
        end
        if S.AutoRebirth then
            for _, remote in ipairs(RS:GetDescendants()) do
                if remote:IsA("RemoteEvent") and remote.Name:lower():find("rebirth") then
                    pcall(function() remote:FireServer() end)
                end
            end
        end
    end
end)

-- =========== TELEPORT TAB ===========
local TP = Window:CreateTab("Teleport", 7072718362)
TP:CreateSection("Map locations")

local function tpToName(key)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find(key) then
            pcall(function() hrp().CFrame = obj.CFrame + Vector3.new(0,5,0) end)
            return true
        end
    end
    return false
end

TP:CreateButton({ Name="Teleport: Sell Zone", Callback=function() tpToName("sell") end })
TP:CreateButton({ Name="Teleport: Rebirth",   Callback=function() tpToName("rebirth") end })
TP:CreateButton({ Name="Teleport: Shop",      Callback=function() tpToName("shop") end })
TP:CreateButton({ Name="Teleport: Spawn",     Callback=function()
    local sp = Workspace:FindFirstChildOfClass("SpawnLocation") or Workspace:FindFirstChild("SpawnLocation", true)
    if sp then pcall(function() hrp().CFrame = sp.CFrame + Vector3.new(0,5,0) end) end
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
            pcall(function()
                hrp().CFrame = t.Character:WaitForChild("HumanoidRootPart").CFrame + Vector3.new(0,3,0)
            end)
        end
    end
})

Players.PlayerAdded:Connect(function() pcall(function() pDrop:Refresh(playerNames()) end) end)
Players.PlayerRemoving:Connect(function() pcall(function() pDrop:Refresh(playerNames()) end) end)

-- =========== PLAYER TAB ===========
local Ply = Window:CreateTab("Player", 7733996289)
Ply:CreateSection("Movement")

Ply:CreateSlider({
    Name="WalkSpeed", Range={16,500}, Increment=1, CurrentValue=16,
    Callback=function(v) S.WalkSpeed=v; pcall(function() hum().WalkSpeed=v end) end
})
Ply:CreateSlider({
    Name="JumpPower", Range={50,500}, Increment=5, CurrentValue=50,
    Callback=function(v) S.JumpPower=v; pcall(function() hum().JumpPower=v end) end
})
Ply:CreateSlider({
    Name="Gravity", Range={0,200}, Increment=1, CurrentValue=196,
    Callback=function(v) Workspace.Gravity=v end
})

Ply:CreateToggle({ Name="Infinite Jump", CurrentValue=false, Callback=function(v) S.InfJump=v end })
Ply:CreateToggle({ Name="NoClip",        CurrentValue=false, Callback=function(v) S.NoClip=v end })

Ply:CreateToggle({
    Name="God Mode (local)", CurrentValue=false,
    Callback=function(v)
        S.GodMode=v
        pcall(function()
            if v then hum().MaxHealth=math.huge; hum().Health=math.huge
            else hum().MaxHealth=100; hum().Health=100 end
        end)
    end
})

Ply:CreateToggle({ Name="Fly", CurrentValue=false, Callback=function(v) S.Flying=v end })
Ply:CreateSlider({ Name="Fly Speed", Range={20,500}, Increment=5, CurrentValue=80, Callback=function(v) S.FlySpeed=v end })

UIS.JumpRequest:Connect(function()
    if S.InfJump then pcall(function() hum():ChangeState(Enum.HumanoidStateType.Jumping) end) end
end)

RunService.Stepped:Connect(function()
    if S.NoClip then
        for _, p in ipairs(char():GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end
end)

-- fly
local flyBV, flyBG
local function startFly()
    local r = hrp()
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
        if not flyBV or not flyBV.Parent then pcall(startFly) end
        local cam = Workspace.CurrentCamera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        if flyBV then flyBV.Velocity = dir * S.FlySpeed; flyBG.CFrame = cam.CFrame end
    else
        if flyBV then stopFly() end
    end
end)

-- =========== VISUALS TAB ===========
local Vis = Window:CreateTab("Visuals", 7733964388)

local function applyESP(p, on)
    if p == LP or not p.Character then return end
    local h = p.Character:FindFirstChild("Head")
    if not h then return end
    local existing = h:FindFirstChild("OllieESP")
    if existing then existing:Destroy() end
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
    Name="Grass ESP (highlights)",
    Callback=function(v)
        S.GrassESP=v
        if not v then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local b = obj:FindFirstChild("OllieGrass")
                if b then b:Destroy() end
            end
        end
    end
})

task.spawn(function()
    while task.wait(1) do
        if S.GrassESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower():find("grass") and not obj:FindFirstChild("OllieGrass") then
                    local hl = Instance.new("Highlight", obj)
                    hl.Name = "OllieGrass"
                    hl.FillColor = S.ESPColor
                    hl.OutlineColor = Color3.fromRGB(255,255,255)
                end
            end
        end
    end
end)

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

Vis:CreateColorPicker({
    Name="ESP Color", Color=Color3.fromRGB(170,0,255),
    Callback=function(c)
        S.ESPColor = c
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local h = p.Character:FindFirstChild("Head")
                if h then
                    local b = h:FindFirstChild("OllieESP")
                    if b then
                        local lab = b:FindFirstChildOfClass("TextLabel")
                        if lab then lab.TextColor3 = c end
                    end
                end
            end
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            local b = obj:FindFirstChild("OllieGrass")
            if b then b.FillColor = c end
        end
    end
})

-- =========== MISC TAB ===========
local Misc = Window:CreateTab("Misc", 7734053495)

Misc:CreateToggle({
    Name="Anti-AFK (never kicked)", CurrentValue=true,
    Callback=function(v) S.AntiAFK=v end
})

LP.Idled:Connect(function()
    if S.AntiAFK then
        pcall(function()
            VIM:SendKeyEvent(true, "Space", false, game)
            task.wait(1)
            VIM:SendKeyEvent(false, "Space", false, game)
        end)
    end
end)

Misc:CreateButton({ Name="Reset Character", Callback=function() pcall(function() LP.Character:BreakJoints() end) end })
Misc:CreateButton({ Name="Copy Server JobId", Callback=function() if setclipboard then setclipboard(game.JobId) end end })

Misc:CreateInput({
    Name="Chat Spam Text", PlaceholderText="type here",
    RemoveTextAfterFocusLost=false,
    Callback=function(txt) S.SpamTxt=txt end
})

Misc:CreateToggle({
    Name="Chat Spam ON",
    Callback=function(v)
        S.Spam=v
        task.spawn(function()
            while S.Spam do
                task.wait(2.5)
                pcall(function()
                    local ev = RS:FindFirstChild("DefaultChatSystemChatEvents")
                    if ev and ev:FindFirstChild("SayMessageRequest") then
                        ev.SayMessageRequest:FireServer(S.SpamTxt ~= "" and S.SpamTxt or "absolute ollie, built by olivia — discord.gg/ojailbreaks", "All")
                    end
                end)
            end
        end)
    end
})

Misc:CreateButton({
    Name="Unload Bench",
    Callback=function()
        S.AutoCut=false; S.AutoSell=false; S.AutoRebirth=false
        S.Flying=false; S.NoClip=false; S.InfJump=false
        S.ESP=false; S.GrassESP=false; S.Spam=false; S.AntiAFK=false
        if flyBV then stopFly() end
        pcall(function() Rayfield:Destroy() end)
    end
})

-- =========== RESPAWN REAPPLY ===========
LP.CharacterAdded:Connect(function()
    task.wait(0.6)
    pcall(function()
        hum().WalkSpeed = S.WalkSpeed
        hum().JumpPower = S.JumpPower
        if S.GodMode then hum().MaxHealth = math.huge; hum().Health = math.huge end
    end)
end)

-- =========== DONE ===========
Rayfield:LoadConfiguration()
Rayfield:Notify({
    Title = "ollie's bench loaded",
    Content = "absolute ollie, built by olivia",
    Duration = 6,
    Image = 4483362458
})

-- ============================================================
-- built by Olivia — https://discord.gg/ojailbreaks
-- ============================================================
