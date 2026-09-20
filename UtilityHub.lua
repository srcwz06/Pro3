-- ============================================================================
-- Utility Hub — main loader (เล็กมาก ~10KB โหลดโมดูลจากโฟลเดอร์ modules/)
-- ============================================================================

local bootLog = {}
local function logBoot(msg)
    bootLog[#bootLog + 1] = "[" .. tostring(tick()) .. "] " .. msg
    pcall(function()
        if not isfolder("UtilityHub_Data") then makefolder("UtilityHub_Data") end
        writefile("UtilityHub_Data/UtilityHub_boot.txt", table.concat(bootLog, "\n"))
    end)
end
logBoot("start")

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Camera = workspace.CurrentCamera
if not Camera then
    repeat task.wait() until workspace.CurrentCamera
    Camera = workspace.CurrentCamera
end

local function getSafeParent()
    if gethui then return gethui() end
    if pcall(function() return CoreGui.Name end) then return CoreGui end
    return (LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")) or CoreGui
end

local function ProtectMyUI(gui)
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
        elseif protectgui then
            protectgui(gui)
        end
        if gethui then
            gui.Parent = gethui()
        end
    end)
end

local BootMarker = nil
local function createBootMarker()
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "UtilityHubBootMarker"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.Parent = getSafeParent()
        local lbl = Instance.new("TextLabel", gui)
        lbl.Size = UDim2.new(0, 340, 0, 42)
        lbl.Position = UDim2.new(0.5, -170, 0, 60)
        lbl.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        lbl.BorderSizePixel = 0
        lbl.Text = "🛠️ UtilityHub: กำลังโหลดโมดูล..."
        lbl.TextColor3 = Color3.fromRGB(245, 245, 250)
        lbl.TextSize = 14
        lbl.Font = Enum.Font.GothamBold
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
        ProtectMyUI(gui)
        BootMarker = { gui = gui, lbl = lbl }
    end)
end
local function setBootMarker(text, color)
    if BootMarker then
        BootMarker.lbl.Text = text
        if color then BootMarker.lbl.TextColor3 = color end
    end
end
local function destroyBootMarker()
    if BootMarker then
        pcall(function() BootMarker.gui:Destroy() end)
        BootMarker = nil
    end
end

createBootMarker()

if _G.UtilityHubCleanup then
    pcall(_G.UtilityHubCleanup)
    task.wait(0.1)
end

local Colors = {
    Bg = Color3.fromRGB(18, 18, 24),
    Panel = Color3.fromRGB(30, 30, 42),
    Sidebar = Color3.fromRGB(24, 24, 32),
    CardBg = Color3.fromRGB(30, 30, 42),
    CardHover = Color3.fromRGB(38, 38, 52),
    CardBorder = Color3.fromRGB(45, 45, 62),
    Text = Color3.fromRGB(245, 245, 250),
    TextDim = Color3.fromRGB(150, 150, 165),
    TextDark = Color3.fromRGB(15, 23, 42),
    Status = Color3.fromRGB(150, 150, 165),
    Green = Color3.fromRGB(34, 197, 94),
    AccentGreen = Color3.fromRGB(34, 197, 94),
    AccentBlue = Color3.fromRGB(14, 165, 233),
    AccentPurple = Color3.fromRGB(139, 92, 246),
    AccentPink = Color3.fromRGB(236, 72, 153),
    AccentYellow = Color3.fromRGB(250, 204, 21),
    AccentRed = Color3.fromRGB(239, 68, 68),
    AccentOrange = Color3.fromRGB(249, 115, 22),
    ButtonESP = Color3.fromRGB(250, 204, 21),
    ButtonAim = Color3.fromRGB(239, 68, 68),
    FOVColor = Color3.fromRGB(236, 72, 153),
    Warning = Color3.fromRGB(239, 68, 68),
    Corpse = Color3.fromRGB(139, 92, 246),
    Pred = Color3.fromRGB(14, 165, 233),
    Team = Color3.fromRGB(14, 165, 233)
}

local FriendlyPlayers = {}

local State = {
    TeamCheckEnabled = true,
    FriendCheckEnabled = true,
    TeamDebugEnabled = false,
    isAimbotting = false,
    hardLockedPlayer = nil,
    currentTarget = nil,
    TargetBotsEnabled = false,
    SilentAimEnabled = false,
    FOVEnabled = false,
    FOVRadius = 150,
    AimTargetPart = "HumanoidRootPart",
    WallCheckEnabled = false,
    PredictionEnabled = false,
    PredictionAmt = 0.1,
    AutoShootEnabled = false,
    SmartBoneEnabled = false,
    BallisticsEnabled = false,
    BulletSpeed = 1000,
    HitboxEnabled = false,
    HitboxPart = "Head",
    HitboxSize = 10,
    HitboxTransparency = 0.5,
    PlayerESPEnabled = false,
    BotESPEnabled = false,
    CorpseESPEnabled = false,
    WeaponESPEnabled = false,
    TracersEnabled = false,
    TracerMode = "All",
    TracerThickness = 1.5,
    StatsEnabled = false,
    GunWarningEnabled = false,
    AimingPlayers = {},
    InfJumpEnabled = false,
    NoClipEnabled = false,
    AlwaysDayEnabled = false,
    FPSBoostEnabled = false,
    HitSoundEnabled = false,
    AutoDelAllEnabled = false,
    DeleteModeEnabled = false,
    PoleModeEnabled = false,
    ObjectScalerEnabled = false,
    ObjectScaleMultiplier = 2.0,
    ObjectScaleAxis = "All",
    SelectedObject = nil,
    AntiFallEnabled = false,
    AutoLootEnabled = false,
    LootRadius = 30,
    GodModeEnabled = false,
    GodModeStyle = "Regen",
    WarpOffset = "Behind",
    selectedWarpTarget = nil,
    AutoRejoinEnabled = false,
    FakeLagEnabled = false,
    FakeLagLimit = 0.3,
    isAnyBinding = false,
    draggingSlider = false,
    draggingPred = false,
    draggingFOV = false,
    draggingTracerThickness = false,
    draggingHitbox = false,
    draggingScale = false,
    draggingLoot = false,
    draggingBulletSpeed = false,
    draggingFakeLag = false,
    Bindings = {
        Aim = Enum.KeyCode.E,
        Lock = Enum.KeyCode.KeypadTwo,
        Warp = Enum.KeyCode.Z,
        FakeLag = Enum.KeyCode.F,
        Pole = Enum.KeyCode.X,
        Del = Enum.KeyCode.G,
        Scaler = Enum.KeyCode.H,
        ScaleUp = Enum.KeyCode.RightBracket,
        ScaleDown = Enum.KeyCode.LeftBracket,
        ClearTeam = Enum.KeyCode.KeypadMinus,
        ScanNearby = Enum.KeyCode.KeypadPlus
    }
}

local robloxFriendsCache = {}
local function isRobloxFriend(player)
    if not player or not player:IsA("Player") then return false end
    if robloxFriendsCache[player.UserId] ~= nil then
        return robloxFriendsCache[player.UserId]
    end
    local ok, isFriend = pcall(function()
        return LocalPlayer:IsFriendsWith(player.UserId)
    end)
    if ok and type(isFriend) == "boolean" then
        robloxFriendsCache[player.UserId] = isFriend
        return isFriend
    end
    return false
end

local ignoredTeamValues = {
    [""] = true, ["0"] = true, ["none"] = true, ["neutral"] = true,
    ["solo"] = true, ["ffa"] = true, ["default"] = true, ["noteam"] = true,
    ["nil"] = true, ["civ"] = true, ["civilian"] = true, ["lobby"] = true,
    ["spectator"] = true, ["spectators"] = true,
    ["player"] = true, ["players"] = true, ["human"] = true, ["bot"] = true,
    ["npc"] = true, ["alive"] = true, ["dead"] = true, ["user"] = true
}

local function isValidTeamValue(val)
    if val == nil then return false end
    local str = tostring(val):lower():gsub("%s+", "")
    if ignoredTeamValues[str] then return false end
    return true
end

local defaultSpawnColors = {
    ["Medium stone grey"] = true,
    ["White"] = true,
    ["Institutional white"] = true
}

local function checkRobloxTeam(player)
    if LocalPlayer.Team ~= nil and player.Team ~= nil then
        if LocalPlayer.Team == player.Team then return true end
        if isValidTeamValue(LocalPlayer.Team.Name) and tostring(LocalPlayer.Team.Name):lower() == tostring(player.Team.Name):lower() then
            return true
        end
    end
    return false
end

local function checkTeamColor(player)
    if LocalPlayer.TeamColor ~= nil and player.TeamColor ~= nil then
        if LocalPlayer.TeamColor == player.TeamColor and not defaultSpawnColors[LocalPlayer.TeamColor.Name] then
            return true
        end
    end
    return false
end

local function checkTeamsService(player)
    local okTeams, teamsService = pcall(function() return game:GetService("Teams") end)
    if okTeams and teamsService then
        for _, team in ipairs(teamsService:GetTeams()) do
            if isValidTeamValue(team.Name) then
                local hasMe = false
                local hasThem = false
                for _, p in ipairs(team:GetPlayers()) do
                    if p == LocalPlayer then hasMe = true end
                    if p == player then hasThem = true end
                end
                if hasMe and hasThem then return true end
            end
        end
    end
    return false
end

local checkKeywords = { "team", "squad", "party", "faction", "clan", "crew", "group", "side", "role", "guild", "gang" }
local function checkAttributes(player)
    local myAttrs = LocalPlayer:GetAttributes()
    local theirAttrs = player:GetAttributes()
    for k, v in pairs(myAttrs) do
        local lk = tostring(k):lower()
        for _, w in ipairs(checkKeywords) do
            if lk:find(w) and isValidTeamValue(v) and theirAttrs[k] == v then
                return true
            end
        end
    end

    if LocalPlayer.Character and player.Character then
        local myCAttrs = LocalPlayer.Character:GetAttributes()
        local theirCAttrs = player.Character:GetAttributes()
        for k, v in pairs(myCAttrs) do
            local lk = tostring(k):lower()
            for _, w in ipairs(checkKeywords) do
                if lk:find(w) and isValidTeamValue(v) and theirCAttrs[k] == v then
                    return true
                end
            end
        end
    end
    return false
end

local teamValueKeys = { "Team", "team", "Squad", "squad", "Party", "party", "Faction", "faction", "Clan", "clan", "Crew", "crew", "Side", "side" }
local function checkValueContainers(player)
    local checkContainers = {
        { LocalPlayer, player },
        { LocalPlayer.Character, player.Character },
        { LocalPlayer:FindFirstChild("leaderstats"), player:FindFirstChild("leaderstats") },
        { LocalPlayer:FindFirstChild("NRPBS"), player:FindFirstChild("NRPBS") },
        { LocalPlayer:FindFirstChild("DataFolder"), player:FindFirstChild("DataFolder") },
        { LocalPlayer:FindFirstChild("Data"), player:FindFirstChild("Data") },
        { LocalPlayer:FindFirstChild("Stats"), player:FindFirstChild("Stats") },
        { LocalPlayer:FindFirstChild("Values"), player:FindFirstChild("Values") }
    }

    for _, pair in ipairs(checkContainers) do
        local myC, theirC = pair[1], pair[2]
        if myC and theirC then
            for _, key in ipairs(teamValueKeys) do
                local myVal = myC:FindFirstChild(key)
                local theirVal = theirC:FindFirstChild(key)
                if myVal and theirVal then
                    if myVal:IsA("ValueBase") and theirVal:IsA("ValueBase") then
                        if myVal.Value == theirVal.Value and isValidTeamValue(myVal.Value) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function checkOverheadTags(player)
    if LocalPlayer.Character and player.Character then
        local myHead = LocalPlayer.Character:FindFirstChild("Head")
        local theirHead = player.Character:FindFirstChild("Head")
        if myHead and theirHead then
            for _, bg in ipairs(myHead:GetChildren()) do
                if bg:IsA("BillboardGui") and bg.Name ~= "HealthESP" and bg.Name ~= "WeaponESP_UI" then
                    local theirBg = theirHead:FindFirstChild(bg.Name)
                    if theirBg then
                        for _, tl in ipairs(bg:GetDescendants()) do
                            if tl:IsA("TextLabel") and isValidTeamValue(tl.Text) and tl.Text ~= LocalPlayer.Name and tl.Text ~= LocalPlayer.DisplayName then
                                for _, ttl in ipairs(theirBg:GetDescendants()) do
                                    if ttl:IsA("TextLabel") and ttl.Text == tl.Text then
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

local function checkAutoTeam(player)
    if not player or not player:IsA("Player") then return false end
    if player == LocalPlayer then return true end

    if checkRobloxTeam(player) then return true end
    if checkTeamColor(player) then return true end
    if checkTeamsService(player) then return true end
    if checkAttributes(player) then return true end
    if checkValueContainers(player) then return true end
    if checkOverheadTags(player) then return true end

    return false
end

local function checkBotTeam(model)
    if not model or not model:IsA("Model") then return false end
    if model == LocalPlayer.Character then return true end

    local p = Players:GetPlayerFromCharacter(model)
    if p then return isSameTeam(p) end

    if FriendlyPlayers[model.Name] then return true end

    if not State.TeamCheckEnabled then return false end

    if LocalPlayer.Character and LocalPlayer.Character.Parent and model.Parent then
        local myFolder = LocalPlayer.Character.Parent
        local botFolder = model.Parent
        if myFolder == botFolder and myFolder ~= workspace then
            local fName = myFolder.Name:lower()
            if fName:find("blue") or fName:find("red") or fName:find("team") or fName:find("allies") or fName:find("axis") or fName:find("ct") or fName:find("t") or fName:find("cop") or fName:find("crim") or fName:find("alpha") or fName:find("bravo") or fName:find("friend") then
                return true
            end
        end

        if LocalPlayer.Team and isValidTeamValue(LocalPlayer.Team.Name) then
            local tName = LocalPlayer.Team.Name:lower()
            if botFolder.Name:lower():find(tName) then return true end
        end
    end

    local checkAttrs = { "team", "teamname", "side", "faction", "squad", "teamcolor", "group", "clan", "party" }
    local botAttrs = model:GetAttributes()

    if LocalPlayer.Team and isValidTeamValue(LocalPlayer.Team.Name) then
        local myTeamStr = tostring(LocalPlayer.Team.Name):lower()
        for k, v in pairs(botAttrs) do
            local lk = tostring(k):lower()
            for _, kw in ipairs(checkAttrs) do
                if lk:find(kw) and isValidTeamValue(v) and tostring(v):lower() == myTeamStr then
                    return true
                end
            end
        end
    end

    if LocalPlayer.Character then
        local myCAttrs = LocalPlayer.Character:GetAttributes()
        for k, v in pairs(myCAttrs) do
            local lk = tostring(k):lower()
            for _, kw in ipairs(checkAttrs) do
                if lk:find(kw) and isValidTeamValue(v) and botAttrs[k] == v then
                    return true
                end
            end
        end
    end

    local myPAttrs = LocalPlayer:GetAttributes()
    for k, v in pairs(myPAttrs) do
        local lk = tostring(k):lower()
        for _, kw in ipairs(checkAttrs) do
            if lk:find(kw) and isValidTeamValue(v) and botAttrs[k] == v then
                return true
            end
        end
    end

    local checkValueKeys = { "Team", "team", "TeamColor", "teamColor", "Side", "side", "Faction", "faction", "Squad", "squad" }
    for _, key in ipairs(checkValueKeys) do
        local botVal = model:FindFirstChild(key)
        if botVal and botVal:IsA("ValueBase") and isValidTeamValue(botVal.Value) then
            if LocalPlayer.Team and tostring(botVal.Value):lower() == tostring(LocalPlayer.Team.Name):lower() then
                return true
            end
            if LocalPlayer.Character then
                local myVal = LocalPlayer.Character:FindFirstChild(key)
                if myVal and myVal:IsA("ValueBase") and myVal.Value == botVal.Value then
                    return true
                end
            end
            local myPVal = LocalPlayer:FindFirstChild(key)
            if myPVal and myPVal:IsA("ValueBase") and myPVal.Value == botVal.Value then
                return true
            end
        end
    end

    local botHead = model:FindFirstChild("Head")
    if botHead and LocalPlayer.Character then
        local myHead = LocalPlayer.Character:FindFirstChild("Head")
        for _, bg in ipairs(botHead:GetChildren()) do
            if bg:IsA("BillboardGui") and bg.Name ~= "HealthESP" and bg.Name ~= "WeaponESP_UI" then
                if myHead then
                    local myBg = myHead:FindFirstChild(bg.Name)
                    if myBg then
                        for _, tl in ipairs(bg:GetDescendants()) do
                            if tl:IsA("TextLabel") and isValidTeamValue(tl.Text) then
                                for _, myTl in ipairs(myBg:GetDescendants()) do
                                    if myTl:IsA("TextLabel") and myTl.Text == tl.Text then
                                        return true
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

local teamCache = {}

local function isSameTeam(target)
    if not target then return false end
    if target == LocalPlayer or target == LocalPlayer.Character then return true end

    local player = nil
    local model = nil

    if typeof(target) == "Instance" then
        if target:IsA("Player") then
            player = target
        elseif target:IsA("Model") then
            player = Players:GetPlayerFromCharacter(target)
            model = target
        end
    elseif type(target) == "table" then
        if target.Character and typeof(target.Character) == "Instance" and target.Character:IsA("Model") then
            model = target.Character
            player = Players:GetPlayerFromCharacter(model)
        elseif target.Model and typeof(target.Model) == "Instance" and target.Model:IsA("Model") then
            model = target.Model
            player = Players:GetPlayerFromCharacter(model)
        end
    end

    if player then
        if player == LocalPlayer then return true end
        if FriendlyPlayers[player.Name] or FriendlyPlayers[player.DisplayName] or (player.UserId and FriendlyPlayers[player.UserId]) then
            return true
        end

        local now = tick()
        local cached = teamCache[player]
        if cached and cached.expiresAt > now then
            return cached.isTeam
        end

        local result = false
        if State.FriendCheckEnabled and isRobloxFriend(player) then
            result = true
        elseif State.TeamCheckEnabled and checkAutoTeam(player) then
            result = true
        end

        teamCache[player] = { isTeam = result, expiresAt = now + 0.5 }
        return result
    end

    if model then
        local now = tick()
        local cached = teamCache[model]
        if cached and cached.expiresAt > now then
            return cached.isTeam
        end

        local result = checkBotTeam(model)
        teamCache[model] = { isTeam = result, expiresAt = now + 0.5 }
        return result
    end

    return false
end

local function isPlayerCharacter(part)
    if not part then return false end
    local model = part:FindFirstAncestorOfClass("Model")
    if model and Players:GetPlayerFromCharacter(model) then return true end
    if LocalPlayer.Character and part:IsDescendantOf(LocalPlayer.Character) then return true end
    return false
end

local function buildRayFilter(...)
    local filter = {}
    for i = 1, select("#", ...) do
        local inst = select(i, ...)
        if inst then filter[#filter + 1] = inst end
    end
    return filter
end

local env = {
    Players = Players,
    RunService = RunService,
    UserInputService = UserInputService,
    VirtualUser = VirtualUser,
    CoreGui = CoreGui,
    LocalPlayer = LocalPlayer,
    Camera = Camera,
    Colors = Colors,
    State = State,
    getSafeParent = getSafeParent,
    ProtectMyUI = ProtectMyUI,
    isSameTeam = isSameTeam,
    checkAutoTeam = checkAutoTeam,
    isRobloxFriend = isRobloxFriend,
    FriendlyPlayers = FriendlyPlayers,
    isPlayerCharacter = isPlayerCharacter,
    buildRayFilter = buildRayFilter,
}

local Cleanup = nil

local function showBootError(msg)
    warn("[UtilityHub] ❌ " .. msg)
    print("[UtilityHub] ❌ " .. msg)
    logBoot("BOOT FAILED: " .. msg)
    if Cleanup then pcall(Cleanup.run) end
    setBootMarker("❌ UtilityHub โหลดไม่ผ่าน", Color3.fromRGB(239, 68, 68))
    pcall(function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "UtilityHubBootError"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.Parent = getSafeParent()
        local lbl = Instance.new("TextLabel", gui)
        lbl.Size = UDim2.new(1, -60, 0, 260)
        lbl.Position = UDim2.new(0, 30, 0.3, 0)
        lbl.BackgroundColor3 = Color3.fromRGB(50, 25, 30)
        lbl.BorderSizePixel = 0
        lbl.TextWrapped = true
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = "⚠️ UtilityHub โหลดไม่ผ่าน:\n\n" .. msg
        lbl.TextColor3 = Color3.fromRGB(239, 68, 68)
        lbl.TextSize = 13
        lbl.Font = Enum.Font.Gotham
        Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", lbl)
        stroke.Color = Color3.fromRGB(239, 68, 68)
        stroke.Thickness = 1
        ProtectMyUI(gui)
    end)
end

local bootOK, bootErr = pcall(function()
    local loadstringFn = loadstring
    if not loadstringFn and load then
        loadstringFn = function(src, name) return load(src, name) end
    end
    if not loadstringFn then
        error("executor นี้ไม่มีฟังก์ชัน loadstring หรือ load")
    end

    local function readModuleSource(name)
        if not readfile then
            error("executor นี้ไม่มี readfile — ใช้ไม่ได้กับเวอร์ชันแยกไฟล์ ต้องใช้ single-file build หรือบอกชื่อ executor มา")
        end
        local path = "modules/" .. name .. ".lua"
        local ok, data = pcall(readfile, path)
        if ok and type(data) == "string" and #data > 0 then
            return data
        end
        error("อ่านไฟล์โมดูลไม่เจอ: '" .. path .. "' (readfile คืนค่า: " .. tostring(ok) .. " / " .. tostring(data) .. ") — ต้องวางโฟลเดอร์ modules/ ไว้ข้างๆ UtilityHub.lua ใน workspace ของ executor")
    end

    local function loadModule(name)
        logBoot("loading " .. name)
        local src = readModuleSource(name)
        local chunk, compileErr = loadstringFn(src, "@" .. name)
        if not chunk then
            error("compile โมดูล '" .. name .. "' ล้มเหลว: " .. tostring(compileErr))
        end
        local okFactory, factory = pcall(chunk)
        if not okFactory or type(factory) ~= "function" then
            error("โมดูล '" .. name .. "' ต้องคืน function(env) แต่ได้: " .. tostring(factory))
        end
        local ok, result = pcall(factory, env)
        if not ok then
            error("รันโมดูล '" .. name .. "' ล้มเหลว: " .. tostring(result))
        end
        logBoot("loaded " .. name)
        return result
    end

    Cleanup = loadModule("cleanup")
    env.Cleanup = Cleanup

    local LogService = loadModule("logger")
    env.Logger = LogService.Logger
    env.Guard = LogService.Guard
    env.Logger.info("System", "Boot", "UtilityHub Core starting...")

    local UIF = loadModule("ui_factory")
    env.UIF = UIF

    local UI = loadModule("hub")
    env.UI = UI

    local Scanner = loadModule("scanner")
    env.Scanner = Scanner
    env.GameProfile = Scanner.runScan()

    local ESP = loadModule("esp")
    env.ESP = ESP

    local Aimbot = loadModule("aimbot")
    env.Aimbot = Aimbot

    local World = loadModule("world")
    env.World = World

    local GodMode = loadModule("godmode")
    env.GodMode = GodMode

    local Config = loadModule("config")
    env.Config = Config

    local Watchdog = loadModule("watchdog")
    env.Watchdog = Watchdog

    local AntiTamper = loadModule("antitamper")
    env.AntiTamper = AntiTamper

    local Dumper = loadModule("dumper")
    env.Dumper = Dumper

    Cleanup.conn(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Camera = workspace.CurrentCamera or Camera
        env.Camera = Camera
    end))

    _G.UtilityHubCleanup = function()
        Cleanup.run()
        for k in pairs(FriendlyPlayers) do FriendlyPlayers[k] = nil end
    end

    -- ========================================================================
    -- [อัปเดต] รองรับการคลิกหน้าจอในโหมดมือถือ (TouchTap) 
    -- ========================================================================
    Cleanup.conn(UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
        if processedByUI then return end
        
        if State.DeleteModeEnabled and env.World and env.World.clickDeleteIfEnabled then
            env.World.clickDeleteIfEnabled()
        end
        
        if State.ObjectScalerEnabled and env.World and env.World.clickSelectObject then
            env.World.clickSelectObject()
        end
    end))

    Cleanup.conn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if UserInputService:GetFocusedTextBox() then return end
        if State.isAnyBinding then return end

        if input.KeyCode == State.Bindings.ClearTeam or input.KeyCode == Enum.KeyCode.KeypadMinus or input.KeyCode == Enum.KeyCode.Minus then
            for k in pairs(FriendlyPlayers) do FriendlyPlayers[k] = nil end
            if UI.showNotif then UI.showNotif("🗑️ ล้างรายชื่อทีมแล้ว!", 2) end
            return
        end

        if input.KeyCode == State.Bindings.ScanNearby or input.KeyCode == Enum.KeyCode.KeypadPlus or input.KeyCode == Enum.KeyCode.Plus or input.KeyCode == Enum.KeyCode.Equals then
            if UI.scanNearby then UI.scanNearby() end
            return
        end

        if input.KeyCode == State.Bindings.Aim then
            Aimbot.toggle()
        elseif input.KeyCode == State.Bindings.Lock then
            Aimbot.toggleHardLock()
        elseif input.KeyCode == State.Bindings.Del then
            World.toggleDeleteMode()
        elseif input.KeyCode == State.Bindings.Scaler then
            World.toggleScaleMode()
        elseif input.KeyCode == State.Bindings.ScaleUp then
            World.stepScale(0.5)
        elseif input.KeyCode == State.Bindings.ScaleDown then
            World.stepScale(-0.5)
        end

        if input.KeyCode == State.Bindings.FakeLag then
            if World and World.setBurstLag then
                World.setBurstLag(true)
            end
        end

        if input.KeyCode == State.Bindings.Warp then
            if World and World.warpToLockedTarget then
                World.warpToLockedTarget()
            end
        end

        if input.KeyCode == State.Bindings.Pole then
            World.spawnPoleIfEnabled()
        end

        if input.UserInputType == Enum.UserInputType.MouseButton3 then
            World.clickDeleteIfEnabled()
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton3 then
            if State.ObjectScalerEnabled then
                World.clickSelectObject()
            end
        end
    end))

    Cleanup.conn(UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == State.Bindings.FakeLag then
            if World and World.setBurstLag then
                World.setBurstLag(false)
            end
        end
    end))

    UI.buttons.exit.Activated:Connect(function()
        if _G.UtilityHubCleanup then
            _G.UtilityHubCleanup()
        end
    end)

    logBoot("boot ok")
    setBootMarker("✅ UtilityHub โหลดเสร็จ!", Color3.fromRGB(34, 197, 94))
    task.delay(1.5, destroyBootMarker)
end)

if not bootOK then
    showBootError(tostring(bootErr))
end
