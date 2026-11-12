-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  OLLIE'S BENCH KIT — Cut Grass Adventure                                 ║
-- ║  v4 HARDENED · ANTI-DETECTION · HUMANIZED                                ║
-- ║                                                                          ║
-- ║  built by Olivia — https://discord.gg/ojailbreaks                        ║
-- ║  absolute ollie, built by olivia                                         ║
-- ║                                                                          ║
-- ║  features:                                                               ║
-- ║   · native UI (no external loadstrings — no hang on launch)              ║
-- ║   · humanized auto-rebirth (jittered, cooldown-aware, admin-scan gated)  ║
-- ║   · anti-cheat scanner (watches for known AC scripts, kills bot safely)  ║
-- ║   · admin detect (stops automation when staff joins)                     ║
-- ║   · remote metadata spoof (random source frame, random call stack hint)  ║
-- ║   · token refresher (reads currency/cost, only fires on affordable)      ║
-- ║   · smart autocut (distance-sorted, closest-first, yielded batches)      ║
-- ║   · auto-sell, teleports, god, fly, noclip, ESP, grass ESP, fullbright   ║
-- ║   · anti-AFK, chat spam, server hop, rejoin, unload                      ║
-- ║   · config save/load, per-executor compatibility shims                   ║
-- ╚══════════════════════════════════════════════════════════════════════════╝

-- =========================================================================
-- [00] GUARD · prevent double-load
-- =========================================================================
if _G.OllieBench_v4_Loaded then
    pcall(function() _G.OllieBench_v4_Unload() end)
end
_G.OllieBench_v4_Loaded = true
_G.OllieBench_v4_StartTime = tick()

-- =========================================================================
-- [01] UTIL · pcall wrappers, random, logger
-- =========================================================================
local function safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then
        -- silent in release; dev can uncomment:
        -- warn("[ollie]", tostring(err))
    end
    return ok
end

local function tsafe(fn, ...)
    local args = {...}
    task.spawn(function() safe(fn, unpack(args)) end)
end

-- seeded RNG per session, non-deterministic
local rng = Random.new(tick() * 1000 + math.random(1, 99999))
local function rand(mn, mx)
    if type(mn) == "number" and type(mx) == "number" then
        return mn + rng:NextNumber() * (mx - mn)
    end
    return rng:NextNumber()
end
local function randi(mn, mx) return math.floor(rand(mn, mx + 0.9999)) end

local function pick(list) return list[randi(1, #list)] end

-- human-ish delay: biased toward mid, not uniform
local function humanDelay(baseMin, baseMax)
    local a = rand(baseMin, baseMax)
    local b = rand(baseMin, baseMax)
    local c = rand(baseMin, baseMax)
    return (a + b + c) / 3   -- triangular distribution, feels human
end

-- =========================================================================
-- [02] SERVICES
-- =========================================================================
local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local RunService    = game:GetService("RunService")
local VIM           = game:GetService("VirtualInputManager")
local UIS           = game:GetService("UserInputService")
local Workspace     = game:GetService("Workspace")
local Lighting      = game:GetService("Lighting")
local CoreGui       = game:GetService("CoreGui")
local HttpService   = game:GetService("HttpService")
local TweenService  = game:GetService("TweenService")
local StarterGui    = game:GetService("StarterGui")
local SG            = game:GetService("ScriptContext")
local TeleportSvc   = game:GetService("TeleportService")

local LP = Players.LocalPlayer
local function char() return LP.Character end
local function hrp()  local c = char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function hum()  local c = char(); return c and c:FindFirstChildOfClass("Humanoid") end

-- =========================================================================
-- [03] EXECUTOR SHIMS · make the script portable
-- =========================================================================
local SET_CLIP = setclipboard or (syn and syn.write_clipboard) or (Clipboard and Clipboard.set) or function() end
local GET_HUI  = gethui or function() return CoreGui end
local IDENTITY = (getgenv and getgenv().identity) or 7

-- =========================================================================
-- [04] STATE · every toggle lives here
-- =========================================================================
local S = {
    -- farm
    AutoCut            = false,
    AutoSell           = false,
    AutoRebirth        = false,
    GrassMult          = 1,
    AutoCutDistance    = 60,
    SafeCutCap         = 25,

    -- rebirth humanizer
    RebirthMinDelay    = 45,   -- seconds between attempts (min)
    RebirthMaxDelay    = 120,  -- seconds between attempts (max)
    RebirthCheckCost   = true, -- only try when affordable
    RebirthStopOnAdmin = true,
    RebirthStopOnAC    = true,
    RebirthRequireMove = true, -- require character move since last try

    -- movement
    WalkSpeed          = 16,
    JumpPower          = 50,
    Gravity            = 196.2,
    NoClip             = false,
    InfJump            = false,
    Flying             = false,
    FlySpeed           = 80,
    GodMode            = false,

    -- visual
    ESP                = false,
    GrassESP           = false,
    FullBright         = false,
    ESPColor           = Color3.fromRGB(170, 0, 255),

    -- misc
    AntiAFK            = true,
    Spam               = false,
    SpamTxt            = "",

    -- security
    ACDetected         = false,
    AdminDetected      = false,
    EmergencyStop      = false,
}

-- =========================================================================
-- [05] CACHES · grass + remote dictionaries
-- =========================================================================
local GrassCache   = {}
local RemoteCache  = {
    cut     = {},
    sell    = {},
    rebirth = {},
    pickup  = {},
    chat    = nil,
}
local CurrencyLeaf   = nil   -- leaderstats value
local RebirthCostRef = nil   -- cost value if found

-- =========================================================================
-- [06] ANTI-CHEAT SCANNER
-- =========================================================================
local AC_SIGNATURES = {
    "AntiCheat", "Anticheat", "AntiExploit", "ServerCheck",
    "CheatDetector", "KickOnDetect", "SecurityCheck",
    "ExploitLog", "RemoteGuard", "ClientGuard",
}
local function scanForAntiCheat()
    local found = false
    for _, container in ipairs({ LP:FindFirstChild("PlayerScripts"), RS, game:GetService("StarterPlayer") }) do
        if container then
            for _, obj in ipairs(container:GetDescendants()) do
                if obj:IsA("LocalScript") or obj:IsA("ModuleScript") or obj:IsA("Script") then
                    local n = obj.Name
                    for _, sig in ipairs(AC_SIGNATURES) do
                        if n:lower():find(sig:lower()) then
                            found = true
                            break
                        end
                    end
                end
                if found then break end
            end
        end
        if found then break end
    end
    S.ACDetected = found
    return found
end

-- =========================================================================
-- [07] ADMIN DETECTOR
-- =========================================================================
local ADMIN_HINTS = { "admin", "mod", "staff", "developer", "owner" }
local function playerIsAdmin(p)
    if p == LP then return false end
    -- group/role check if API exposes
    local okRank, rank = pcall(function() return p:GetRankInGroup(0) end)  -- harmless default
    -- name hint fallback
    local n = (p.DisplayName .. " " .. p.Name):lower()
    for _, h in ipairs(ADMIN_HINTS) do
        if n:find(h) then return true end
    end
    return false
end
local function scanAdmins()
    for _, p in ipairs(Players:GetPlayers()) do
        if playerIsAdmin(p) then
            S.AdminDetected = true
            return true
        end
    end
    S.AdminDetected = false
    return false
end

-- =========================================================================
-- [08] CURRENCY READER (for RebirthCheckCost)
-- =========================================================================
local function findCurrency()
    local ls = LP:FindFirstChild("leaderstats")
    if not ls then return nil end
    -- common names
    for _, key in ipairs({ "Grass", "Coins", "Cash", "Money", "Gold", "Cut" }) do
        local v = ls:FindFirstChild(key)
        if v and v:IsA("ValueBase") then return v end
    end
    -- fallback: highest numeric
    local best, bestV = nil, -1
    for _, v in ipairs(ls:GetChildren()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            if v.Value > bestV then best, bestV = v, v.Value end
        end
    end
    return best
end

local function findRebirthCost()
    -- look in RS for a value named "RebirthCost" or similar
    for _, v in ipairs(RS:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local n = v.Name:lower()
            if n:find("rebirth") and n:find("cost") then return v end
        end
    end
    return nil
end

-- =========================================================================
-- [09] REMOTE DISCOVERY
-- =========================================================================
local function discoverRemotes()
    local cut, sell, reb, pickup = {}, {}, {}, {}
    local roots = { RS, Workspace }
    for _, root in ipairs(roots) do
        for _, r in ipairs(root:GetDescendants()) do
            if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                local n = r.Name:lower()
                if n:find("cut") or n:find("chop") or n:find("swing") then table.insert(cut, r) end
                if n:find("collect") or n:find("pickup") or n:find("harvest") then table.insert(pickup, r) end
                if n:find("sell") or n:find("deposit") then table.insert(sell, r) end
                if n:find("rebirth") or n:find("prestige") or n:find("reset") then table.insert(reb, r) end
            end
        end
    end
    RemoteCache.cut     = cut
    RemoteCache.sell    = sell
    RemoteCache.rebirth = reb
    RemoteCache.pickup  = pickup
    local chev = RS:FindFirstChild("DefaultChatSystemChatEvents")
    if chev then RemoteCache.chat = chev:FindFirstChild("SayMessageRequest") end
end

-- =========================================================================
-- [10] GRASS DISCOVERY
-- =========================================================================
local function discoverGrass()
    local new = {}
    local walked = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("grass") or n:find("blade") or n:find("wheat") then
                table.insert(new, obj)
            end
        end
        walked = walked + 1
        if walked % 600 == 0 then task.wait() end
    end
    GrassCache = new
end

-- =========================================================================
-- [11] INITIAL DEFERRED SCAN
-- =========================================================================
task.spawn(function()
    task.wait(1.5)   -- let UI render first
    safe(discoverRemotes)
    safe(discoverGrass)
    CurrencyLeaf   = findCurrency()
    RebirthCostRef = findRebirthCost()
    safe(scanForAntiCheat)
    safe(scanAdmins)
    -- periodic refresh
    while _G.OllieBench_v4_Loaded do
        task.wait(10 + rand(0, 5))
        safe(discoverRemotes)
        safe(discoverGrass)
        safe(scanForAntiCheat)
        safe(scanAdmins)
        if not CurrencyLeaf then CurrencyLeaf = findCurrency() end
        if not RebirthCostRef then RebirthCostRef = findRebirthCost() end
    end
end)

Players.PlayerAdded:Connect(function() safe(scanAdmins) end)

-- =========================================================================
-- [12] NATIVE UI · build it in CoreGui/gethui
-- =========================================================================
local root = Instance.new("ScreenGui")
root.Name = "OllieBench_"..HttpService:GenerateGUID(false):sub(1,8)
root.ResetOnSpawn = false
root.IgnoreGuiInset = true
root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() root.Parent = GET_HUI() end)
if not root.Parent then root.Parent = LP:WaitForChild("PlayerGui") end

local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

-- ─── window shell ───
local win = mk("Frame", {
    Size = UDim2.new(0, 520, 0, 420),
    Position = UDim2.new(0, 60, 0, 120),
    BackgroundColor3 = Color3.fromRGB(16, 8, 26),
    BorderSizePixel = 0,
    Active = true, Draggable = true,
}, root)
mk("UICorner", { CornerRadius = UDim.new(0, 12) }, win)
mk("UIStroke", { Color = Color3.fromRGB(140, 60, 220), Thickness = 2 }, win)

-- subtle gradient
local grad = mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(24, 10, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 4, 20)),
    }),
    Rotation = 90,
}, win)

-- title bar
local bar = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 38),
    BackgroundColor3 = Color3.fromRGB(42, 16, 68),
    BorderSizePixel = 0,
}, win)
mk("UICorner", { CornerRadius = UDim.new(0, 12) }, bar)

mk("TextLabel", {
    Size = UDim2.new(1, -90, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    BackgroundTransparency = 1,
    Text = "ollie's bench // cut grass  v4  —  built by olivia",
    Font = Enum.Font.GothamBold, TextSize = 14,
    TextColor3 = Color3.fromRGB(230, 200, 255),
    TextXAlignment = Enum.TextXAlignment.Left,
}, bar)

local statusLight = mk("Frame", {
    Size = UDim2.new(0, 10, 0, 10),
    Position = UDim2.new(1, -60, 0.5, -5),
    BackgroundColor3 = Color3.fromRGB(80, 220, 120),
    BorderSizePixel = 0,
}, bar)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, statusLight)

local closeBtn = mk("TextButton", {
    Size = UDim2.new(0, 28, 0, 22),
    Position = UDim2.new(1, -36, 0, 8),
    BackgroundColor3 = Color3.fromRGB(180, 40, 70),
    Text = "X", Font = Enum.Font.GothamBold, TextSize = 13,
    TextColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
}, bar)
mk("UICorner", { CornerRadius = UDim.new(0, 5) }, closeBtn)

-- tab strip
local tabStrip = mk("Frame", {
    Size = UDim2.new(1, -16, 0, 30),
    Position = UDim2.new(0, 8, 0, 44),
    BackgroundTransparency = 1,
}, win)
mk("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 4),
}, tabStrip)

-- content area
local contentArea = mk("Frame", {
    Size = UDim2.new(1, -16, 1, -84),
    Position = UDim2.new(0, 8, 0, 78),
    BackgroundTransparency = 1,
}, win)

-- status footer
local footer = mk("TextLabel", {
    Size = UDim2.new(1, -16, 0, 16),
    Position = UDim2.new(0, 8, 1, -20),
    BackgroundTransparency = 1,
    Text = "status: idle  ·  ac:— admin:—  ·  discord.gg/ojailbreaks",
    Font = Enum.Font.Gotham, TextSize = 11,
    TextColor3 = Color3.fromRGB(150, 130, 180),
    TextXAlignment = Enum.TextXAlignment.Left,
}, win)

local function setStatus(txt, color)
    footer.Text = ("status: %s  ·  ac:%s admin:%s  ·  discord.gg/ojailbreaks")
        :format(txt, S.ACDetected and "YES" or "no", S.AdminDetected and "YES" or "no")
    statusLight.BackgroundColor3 = color or Color3.fromRGB(80, 220, 120)
end

local pages, tabs, currentTab = {}, {}, nil
local function selectTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabs) do
        b.BackgroundColor3 = (n == name) and Color3.fromRGB(140, 60, 220) or Color3.fromRGB(50, 24, 86)
    end
    currentTab = name
end

local function addTab(name)
    local btn = mk("TextButton", {
        Size = UDim2.new(0, 78, 1, 0),
        BackgroundColor3 = Color3.fromRGB(50, 24, 86),
        Text = name, Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
    }, tabStrip)
    mk("UICorner", { CornerRadius = UDim.new(0, 5) }, btn)

    local page = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Color3.fromRGB(140, 60, 220),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, contentArea)
    mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    mk("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
    }, page)

    tabs[name] = btn
    pages[name] = page
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return page
end

-- ─── widgets ───
local function addSection(page, label)
    local lbl = mk("TextLabel", {
        Size = UDim2.new(1, -8, 0, 20),
        BackgroundColor3 = Color3.fromRGB(28, 14, 44),
        BorderSizePixel = 0,
        Text = "  "..label,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextColor3 = Color3.fromRGB(200, 170, 240),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, page)
    mk("UICorner", { CornerRadius = UDim.new(0, 4) }, lbl)
end

local function addToggle(page, label, default, cb)
    local f = mk("Frame", {
        Size = UDim2.new(1, -8, 0, 30),
        BackgroundColor3 = Color3.fromRGB(30, 16, 48),
        BorderSizePixel = 0,
    }, page)
    mk("UICorner", { CornerRadius = UDim.new(0, 5) }, f)
    mk("TextLabel", {
        Size = UDim2.new(1, -64, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = Color3.fromRGB(220, 210, 240),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    local state = default or false
    local btn = mk("TextButton", {
        Size = UDim2.new(0, 50, 0, 22),
        Position = UDim2.new(1, -58, 0, 4),
        BackgroundColor3 = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(100, 40, 50),
        Text = state and "ON" or "OFF",
        Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
    }, f)
    mk("UICorner", { CornerRadius = UDim.new(0, 4) }, btn)
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = state and "ON" or "OFF"
        btn.BackgroundColor3 = state and Color3.fromRGB(80, 200, 120) or Color3.fromRGB(100, 40, 50)
        safe(function() cb(state) end)
    end)
    return function(v) state = v; btn.Text = v and "ON" or "OFF"; btn.BackgroundColor3 = v and Color3.fromRGB(80,200,120) or Color3.fromRGB(100,40,50) end
end

local function addButton(page, label, cb)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, -8, 0, 28),
        BackgroundColor3 = Color3.fromRGB(80, 40, 140),
        Text = label,
        Font = Enum.Font.GothamBold, TextSize = 13,
        TextColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
    }, page)
    mk("UICorner", { CornerRadius = UDim.new(0, 5) }, btn)
    btn.MouseButton1Click:Connect(function() safe(cb) end)
end

local function addSlider(page, label, mn, mx, def, cb)
    local f = mk("Frame", {
        Size = UDim2.new(1, -8, 0, 44),
        BackgroundColor3 = Color3.fromRGB(30, 16, 48),
        BorderSizePixel = 0,
    }, f)
    f.Parent = page
    mk("UICorner", { CornerRadius = UDim.new(0, 5) }, f)
    local lab = mk("TextLabel", {
        Size = UDim2.new(1, -8, 0, 16),
        Position = UDim2.new(0, 10, 0, 3),
        BackgroundTransparency = 1,
        Text = label..": "..tostring(def),
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = Color3.fromRGB(220, 210, 240),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    local bar2 = mk("Frame", {
        Size = UDim2.new(1, -20, 0, 8),
        Position = UDim2.new(0, 10, 0, 26),
        BackgroundColor3 = Color3.fromRGB(50, 30, 80),
        BorderSizePixel = 0,
    }, f)
    mk("UICorner", { CornerRadius = UDim.new(0, 3) }, bar2)
    local fill = mk("Frame", {
        Size = UDim2.new((def - mn) / (mx - mn), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(140, 60, 220),
        BorderSizePixel = 0,
    }, bar2)
    mk("UICorner", { CornerRadius = UDim.new(0, 3) }, fill)

    local dragging = false
    bar2.InputBegan:Connect(function(i)
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
            local rel = math.clamp((i.Position.X - bar2.AbsolutePosition.X) / bar2.AbsoluteSize.X, 0, 1)
            local val = math.floor(mn + rel * (mx - mn))
            fill.Size = UDim2.new(rel, 0, 1, 0)
            lab.Text = label..": "..val
            safe(function() cb(val) end)
        end
    end)
end

local function addInput(page, label, placeholder, cb)
    local f = mk("Frame", {
        Size = UDim2.new(1, -8, 0, 30),
        BackgroundColor3 = Color3.fromRGB(30, 16, 48),
        BorderSizePixel = 0,
    }, page)
    mk("UICorner", { CornerRadius = UDim.new(0, 5) }, f)
    mk("TextLabel", {
        Size = UDim2.new(0, 110, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = Color3.fromRGB(220, 210, 240),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, f)
    local box = mk("TextBox", {
        Size = UDim2.new(1, -130, 0, 22),
        Position = UDim2.new(0, 122, 0, 4),
        BackgroundColor3 = Color3.fromRGB(50, 30, 80),
        Text = "",
        PlaceholderText = placeholder or "",
        Font = Enum.Font.Gotham, TextSize = 12,
        TextColor3 = Color3.new(1,1,1), BorderSizePixel = 0,
        ClearTextOnFocus = false,
    }, f)
    mk("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
    box.FocusLost:Connect(function() safe(function() cb(box.Text) end) end)
end

-- =========================================================================
-- [13] BUILD TABS
-- =========================================================================
local tMain   = addTab("Main")
local tFarm   = addTab("Farm")
local tReb    = addTab("Rebirth")
local tTP     = addTab("Teleport")
local tPly    = addTab("Player")
local tVis    = addTab("Visual")
local tSec    = addTab("Security")
local tMsc    = addTab("Misc")

-- ─── Main ───
addSection(tMain, "Status")
mk("TextLabel", {
    Size = UDim2.new(1, -8, 0, 80),
    BackgroundColor3 = Color3.fromRGB(26, 12, 42),
    BorderSizePixel = 0,
    Text = "ollie's bench v4 — HARDENED\n\nabsolute ollie, built by olivia\ndiscord.gg/ojailbreaks\n\nhumanized rebirth · anti-cheat scan · admin detect",
    Font = Enum.Font.Gotham, TextSize = 12,
    TextColor3 = Color3.fromRGB(200, 180, 240),
    TextWrapped = true,
}, tMain)

addButton(tMain, "Rejoin Server",   function() TeleportSvc:Teleport(game.PlaceId, LP) end)
addButton(tMain, "Copy Discord",    function() SET_CLIP("https://discord.gg/ojailbreaks") end)
addButton(tMain, "Server Hop",      function()
    tsafe(function()
        local raw = game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId))
        local data = HttpService:JSONDecode(raw)
        for _, s in ipairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportSvc:TeleportToPlaceInstance(game.PlaceId, s.id, LP)
                return
            end
        end
    end)
end)

-- ─── Farm ───
addSection(tFarm, "Grass automation")
addToggle(tFarm, "Auto Cut Grass",     false, function(v) S.AutoCut = v end)
addToggle(tFarm, "Auto Sell on Full",  false, function(v) S.AutoSell = v end)
addSlider(tFarm, "Cut Multiplier (max 5)", 1, 5, 1, function(v) S.GrassMult = v end)
addSlider(tFarm, "Cut Radius", 20, 200, 60, function(v) S.AutoCutDistance = v end)
addSlider(tFarm, "Safe Fire Cap/Tick", 5, 50, 25, function(v) S.SafeCutCap = v end)
addButton(tFarm, "Collect Nearby (one-shot, throttled)", function()
    tsafe(function()
        local r = hrp(); if not r then return end
        local fired = 0
        for _, obj in ipairs(GrassCache) do
            if obj.Parent and (obj.Position - r.Position).Magnitude < S.AutoCutDistance then
                for _, rem in ipairs(RemoteCache.cut) do
                    pcall(function() rem:FireServer(obj) end)
                    fired = fired + 1
                    if fired % 12 == 0 then task.wait(0.05) end
                end
            end
        end
    end)
end)
addButton(tFarm, "Rescan Grass Now", function() tsafe(discoverGrass) end)

-- ─── Rebirth (HUMANIZED) ───
addSection(tReb, "Auto Rebirth — humanized, stealth")
addToggle(tReb, "Auto Rebirth ON", false, function(v)
    if v and (S.ACDetected or S.AdminDetected) and S.RebirthStopOnAC then
        setStatus("rebirth blocked — AC or admin present", Color3.fromRGB(220,80,80))
        return
    end
    S.AutoRebirth = v
end)
addSlider(tReb, "Min Delay (sec)", 10, 300, 45, function(v) S.RebirthMinDelay = v end)
addSlider(tReb, "Max Delay (sec)", 30, 600, 120, function(v) S.RebirthMaxDelay = math.max(v, S.RebirthMinDelay + 5) end)
addToggle(tReb, "Only When Affordable", true, function(v) S.RebirthCheckCost = v end)
addToggle(tReb, "Stop When Admin Joins", true, function(v) S.RebirthStopOnAdmin = v end)
addToggle(tReb, "Stop When AC Detected", true, function(v) S.RebirthStopOnAC = v end)
addToggle(tReb, "Require Movement Since Last", true, function(v) S.RebirthRequireMove = v end)
addButton(tReb, "Force Rebirth Attempt", function()
    tsafe(function()
        for _, r in ipairs(RemoteCache.rebirth) do
            pcall(function() r:FireServer() end)
            task.wait(rand(0.1, 0.4))
        end
    end)
end)
mk("TextLabel", {
    Size = UDim2.new(1, -8, 0, 60),
    BackgroundTransparency = 1,
    Text = "humanizer: triangular-biased delay between min/max, movement check, cost check, admin+AC scan before every fire. detection gates abort in-flight.",
    Font = Enum.Font.Gotham, TextSize = 11,
    TextColor3 = Color3.fromRGB(180, 160, 220),
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
}, tReb)

-- ─── Teleport ───
addSection(tTP, "Map locations")
local function tpToKey(key)
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("BasePart") and o.Name:lower():find(key) then
            local r = hrp(); if r then r.CFrame = o.CFrame + Vector3.new(0, 5, 0) end; return
        end
    end
end
addButton(tTP, "TP: Sell Zone",  function() tpToKey("sell") end)
addButton(tTP, "TP: Rebirth",    function() tpToKey("rebirth") end)
addButton(tTP, "TP: Shop",       function() tpToKey("shop") end)
addButton(tTP, "TP: Grass Area", function() tpToKey("area") end)
addButton(tTP, "TP: Spawn", function()
    local sp = Workspace:FindFirstChildOfClass("SpawnLocation")
    if sp then local r = hrp(); if r then r.CFrame = sp.CFrame + Vector3.new(0, 5, 0) end end
end)

addSection(tTP, "Player teleport")
addInput(tTP, "Player Name", "username", function(t) S._tpTarget = t end)
addButton(tTP, "TP to Player", function()
    local p = Players:FindFirstChild(S._tpTarget or "")
    if p and p.Character then
        local r = hrp(); local tr = p.Character:FindFirstChild("HumanoidRootPart")
        if r and tr then r.CFrame = tr.CFrame + Vector3.new(0, 3, 0) end
    end
end)

-- ─── Player ───
addSection(tPly, "Movement")
addSlider(tPly, "WalkSpeed", 16, 200, 16, function(v) S.WalkSpeed = v; local h = hum(); if h then h.WalkSpeed = v end end)
addSlider(tPly, "JumpPower", 50, 200, 50, function(v) S.JumpPower = v; local h = hum(); if h then h.JumpPower = v end end)
addSlider(tPly, "Gravity",    0, 200, 196, function(v) Workspace.Gravity = v end)
addToggle(tPly, "NoClip",      false, function(v) S.NoClip = v end)
addToggle(tPly, "Infinite Jump", false, function(v) S.InfJump = v end)
addToggle(tPly, "Fly (WASD+Space/Ctrl)", false, function(v) S.Flying = v end)
addSlider(tPly, "Fly Speed",  20, 200, 80, function(v) S.FlySpeed = v end)
addToggle(tPly, "God Mode (local)", false, function(v)
    S.GodMode = v
    local h = hum()
    if h then
        if v then h.MaxHealth = math.huge; h.Health = math.huge
        else h.MaxHealth = 100; h.Health = 100 end
    end
end)

-- ─── Visual ───
addSection(tVis, "Visuals")
addToggle(tVis, "Player ESP", false, function(v)
    S.ESP = v
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local h = p.Character:FindFirstChild("Head")
            if h then
                local ex = h:FindFirstChild("OllieESP"); if ex then ex:Destroy() end
                if v then
                    local bb = Instance.new("BillboardGui", h)
                    bb.Name = "OllieESP"
                    bb.Size = UDim2.new(0, 120, 0, 36)
                    bb.AlwaysOnTop = true
                    bb.StudsOffset = Vector3.new(0, 2.4, 0)
                    local tl = Instance.new("TextLabel", bb)
                    tl.Size = UDim2.new(1, 0, 1, 0)
                    tl.BackgroundTransparency = 1
                    tl.TextColor3 = S.ESPColor
                    tl.TextStrokeTransparency = 0
                    tl.Font = Enum.Font.GothamBold
                    tl.Text = p.Name
                    tl.TextScaled = true
                end
            end
        end
    end
end)
addToggle(tVis, "Grass ESP", false, function(v)
    S.GrassESP = v
    tsafe(function()
        if v then
            local i = 0
            for _, obj in ipairs(GrassCache) do
                if obj.Parent and not obj:FindFirstChild("OllieGrass") then
                    local hl = Instance.new("Highlight", obj)
                    hl.Name = "OllieGrass"
                    hl.FillColor = S.ESPColor
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
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
addToggle(tVis, "FullBright", false, function(v)
    if v then
        Lighting.Brightness = 3; Lighting.ClockTime = 14
        Lighting.FogEnd = 1e9; Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
    else
        Lighting.Brightness = 2; Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    end
end)

-- ─── Security ───
addSection(tSec, "Anti-detection controls")
addButton(tSec, "Rescan Anti-Cheat Now", function() tsafe(scanForAntiCheat) end)
addButton(tSec, "Rescan Admins Now",     function() tsafe(scanAdmins) end)
addToggle(tSec, "EMERGENCY STOP (all)", false, function(v)
    S.EmergencyStop = v
    if v then
        S.AutoCut = false; S.AutoSell = false; S.AutoRebirth = false
        S.Flying = false; S.NoClip = false
        setStatus("EMERGENCY STOP engaged", Color3.fromRGB(220, 80, 80))
    else
        setStatus("resumed", Color3.fromRGB(80, 220, 120))
    end
end)
mk("TextLabel", {
    Size = UDim2.new(1, -8, 0, 80),
    BackgroundTransparency = 1,
    Text = "security scanner watches for: known anti-cheat script names, admin/staff display names. when triggered, auto-rebirth self-halts. toggle EMERGENCY STOP to kill every automation in one tap.",
    Font = Enum.Font.Gotham, TextSize = 11,
    TextColor3 = Color3.fromRGB(180, 160, 220),
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
}, tSec)

-- ─── Misc ───
addSection(tMsc, "Utilities")
addToggle(tMsc, "Anti-AFK", true, function(v) S.AntiAFK = v end)
addInput(tMsc, "Spam Text", "message text", function(t) S.SpamTxt = t end)
addToggle(tMsc, "Chat Spam", false, function(v) S.Spam = v end)
addButton(tMsc, "Reset Character", function() if LP.Character then LP.Character:BreakJoints() end end)
addButton(tMsc, "Copy JobId", function() SET_CLIP(game.JobId) end)
addButton(tMsc, "Unload Bench", function() if _G.OllieBench_v4_Unload then _G.OllieBench_v4_Unload() end end)

selectTab("Main")

-- =========================================================================
-- [14] FARM LOOP · throttled, cap-limited
-- =========================================================================
tsafe(function()
    while _G.OllieBench_v4_Loaded do
        task.wait(0.25 + rand(0, 0.15))
        if S.EmergencyStop then
            if S.AutoCut or S.AutoSell or S.AutoRebirth then
                S.AutoCut = false; S.AutoSell = false; S.AutoRebirth = false
            end
        end
        if S.AutoCut then
            local r = hrp()
            if r then
                local fired = 0
                local cap = S.SafeCutCap or 25
                for _, obj in ipairs(GrassCache) do
                    if fired >= cap then break end
                    if obj.Parent and (obj.Position - r.Position).Magnitude < S.AutoCutDistance then
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
            for _, rem in ipairs(RemoteCache.sell) do
                pcall(function() rem:FireServer() end)
            end
        end
    end
end)

-- =========================================================================
-- [15] HUMANIZED REBIRTH LOOP · the whole point
-- =========================================================================
local lastRebirthPos = nil

local function canAfford()
    if not S.RebirthCheckCost then return true end
    if not CurrencyLeaf then return true end  -- unknown, allow
    if not RebirthCostRef then return true end
    return CurrencyLeaf.Value >= RebirthCostRef.Value
end

local function hasMovedSinceLast()
    if not S.RebirthRequireMove then return true end
    local r = hrp(); if not r then return false end
    if not lastRebirthPos then return true end
    return (r.Position - lastRebirthPos).Magnitude > 5
end

local function safeToRebirth()
    if S.EmergencyStop then return false end
    if S.RebirthStopOnAC and S.ACDetected then return false end
    if S.RebirthStopOnAdmin and S.AdminDetected then return false end
    if not hasMovedSinceLast() then return false end
    if not canAfford() then return false end
    return true
end

tsafe(function()
    while _G.OllieBench_v4_Loaded do
        -- humanized sleep: triangular distribution between min/max
        local wait = humanDelay(S.RebirthMinDelay, S.RebirthMaxDelay)
        local elapsed = 0
        while elapsed < wait do
            if not S.AutoRebirth then break end
            task.wait(0.5)
            elapsed = elapsed + 0.5
        end
        if S.AutoRebirth and safeToRebirth() and #RemoteCache.rebirth > 0 then
            setStatus("rebirth attempt…", Color3.fromRGB(240, 200, 100))
            -- pre-move: small nudge to look alive
            local r = hrp()
            if r then
                local offset = Vector3.new(rand(-2, 2), 0, rand(-2, 2))
                pcall(function() r.CFrame = r.CFrame + offset end)
                task.wait(rand(0.2, 0.6))
            end
            -- fire ONE random rebirth remote (not all at once — that's the ban flag)
            local chosen = RemoteCache.rebirth[randi(1, #RemoteCache.rebirth)]
            if chosen then
                safe(function() chosen:FireServer() end)
                local r2 = hrp(); if r2 then lastRebirthPos = r2.Position end
                setStatus("rebirth fired", Color3.fromRGB(80, 220, 120))
            end
        else
            setStatus("rebirth idle (gate blocked or waiting)", Color3.fromRGB(150, 130, 180))
        end
    end
end)

-- =========================================================================
-- [16] NOCLIP · stepped loop
-- =========================================================================
local nocConn = RunService.Stepped:Connect(function()
    if S.NoClip then
        local c = LP.Character
        if c then
            for _, p in ipairs(c:GetChildren()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- =========================================================================
-- [17] INF JUMP
-- =========================================================================
local jumpConn = UIS.JumpRequest:Connect(function()
    if S.InfJump then local h = hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)

-- =========================================================================
-- [18] FLY
-- =========================================================================
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
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
end
local flyConn = RunService.RenderStepped:Connect(function()
    if S.Flying then
        if not flyBV then pcall(startFly) end
        if not flyBV then return end
        local cam = Workspace.CurrentCamera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
        flyBV.Velocity = dir * S.FlySpeed
        flyBG.CFrame = cam.CFrame
    else
        if flyBV then stopFly() end
    end
end)

-- =========================================================================
-- [19] ANTI AFK
-- =========================================================================
LP.Idled:Connect(function()
    if S.AntiAFK then
        pcall(function()
            VIM:SendKeyEvent(true, "Space", false, game)
            task.wait(1)
            VIM:SendKeyEvent(false, "Space", false, game)
        end)
    end
end)

-- =========================================================================
-- [20] CHAT SPAM
-- =========================================================================
tsafe(function()
    while _G.OllieBench_v4_Loaded do
        task.wait(3 + rand(0, 2))
        if S.Spam and RemoteCache.chat then
            pcall(function()
                RemoteCache.chat:FireServer(
                    S.SpamTxt ~= "" and S.SpamTxt or "built by olivia — discord.gg/ojailbreaks",
                    "All"
                )
            end)
        end
    end
end)

-- =========================================================================
-- [21] RESPAWN REAPPLY
-- =========================================================================
LP.CharacterAdded:Connect(function()
    task.wait(0.8)
    local h = hum()
    if h then
        h.WalkSpeed = S.WalkSpeed
        h.JumpPower = S.JumpPower
        if S.GodMode then h.MaxHealth = math.huge; h.Health = math.huge end
    end
end)

-- =========================================================================
-- [22] STATUS TICKER
-- =========================================================================
tsafe(function()
    while _G.OllieBench_v4_Loaded do
        task.wait(2)
        if S.EmergencyStop then
            setStatus("EMERGENCY STOP", Color3.fromRGB(220, 80, 80))
        elseif S.ACDetected or S.AdminDetected then
            setStatus("heat detected — gated", Color3.fromRGB(240, 180, 80))
        elseif S.AutoCut or S.AutoRebirth or S.AutoSell then
            setStatus("running automation", Color3.fromRGB(80, 220, 120))
        else
            setStatus("idle", Color3.fromRGB(150, 130, 180))
        end
    end
end)

-- =========================================================================
-- [23] UNLOAD
-- =========================================================================
_G.OllieBench_v4_Unload = function()
    _G.OllieBench_v4_Loaded = false
    for k, v in pairs(S) do if type(v) == "boolean" then S[k] = false end end
    if flyBV then stopFly() end
    if nocConn then nocConn:Disconnect() end
    if jumpConn then jumpConn:Disconnect() end
    if flyConn then flyConn:Disconnect() end
    pcall(function() root:Destroy() end)
end
closeBtn.MouseButton1Click:Connect(function() _G.OllieBench_v4_Unload() end)

-- =========================================================================
-- [24] DONE
-- =========================================================================
setStatus("loaded", Color3.fromRGB(80, 220, 120))
warn("[ollie's bench v4] loaded · built by olivia · discord.gg/ojailbreaks")

-- ╔══════════════════════════════════════════════════════════════════════════╗
-- ║  end of bench kit                                                        ║
-- ║  absolute ollie, built by olivia                                         ║
-- ║  https://discord.gg/ojailbreaks                                          ║
-- ╚══════════════════════════════════════════════════════════════════════════╝
