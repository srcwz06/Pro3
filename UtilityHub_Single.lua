-- ============================================================================
-- Utility Hub — SINGLE FILE BUILD (รวมทุกโมดูลแล้ว)
-- ไม่ต้องมีโฟลเดอร์ modules/ — โหลดได้ทันทีจากไฟล์เดียว
-- ============================================================================

local bootLog = {}
local function logBoot(msg)
    bootLog[#bootLog + 1] = "[" .. tostring(tick()) .. "] " .. msg
    pcall(function()
        if not isfolder("UtilityHub_Data") then makefolder("UtilityHub_Data") end
        writefile("UtilityHub_Data/UtilityHub_boot.txt", table.concat(bootLog, "\n"))
    end)
end
logBoot("start (single-file)")

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

-- ============================================================================
-- INLINE MODULES (single-file)
-- ============================================================================


-- ========== MODULE: cleanup ==========
local __factory_cleanup = (function()

return function(env)
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer

    local Cleanup = {}

    local connections = {}
    local callbacks = {}
    local mapObjects = {}
    local clickObjects = {}
    local poles = {}
    local highlights = {}
    local trackedInstances = {} -- { inst = ..., globalKey = ... }
    local lightingSaved = false
    local lightingOriginals = {}

    local function restoreObject(obj, data)
        if not obj then return end
        pcall(function()
            obj.Transparency = data.origTransparency
            obj.CanCollide = data.origCanCollide
            if data.origCanQuery ~= nil then obj.CanQuery = data.origCanQuery end
        end)
    end

    function Cleanup.conn(conn)
        if conn then connections[#connections + 1] = conn end
        return conn
    end

    function Cleanup.addCallback(fn)
        if fn then callbacks[#callbacks + 1] = fn end
    end

    -- ลบแมพ (Delete All)
    function Cleanup.getMapObjects() return mapObjects end
    function Cleanup.clearMapObjects() mapObjects = {} end

    -- ลบของทีละชิ้น (Delete Mode)
    function Cleanup.addClickObject(data)
        clickObjects[#clickObjects + 1] = data
    end
    function Cleanup.getClickObjects() return clickObjects end
    function Cleanup.clearClickObjects() clickObjects = {} end

    -- เสาปีน
    function Cleanup.addPole(pole)
        poles[#poles + 1] = pole
    end
    function Cleanup.getPoles() return poles end
    function Cleanup.clearPoles() poles = {} end

    -- Highlight (โหมดลบของ)
    function Cleanup.trackHighlight(hl)
        highlights[#highlights + 1] = hl
    end

    -- instance + คีย์ _G (UI ต่าง ๆ, โฟลเดอร์ศพ) — ล้างทั้ง destroy และ _G[key]
    function Cleanup.trackInstance(inst, globalKey)
        trackedInstances[#trackedInstances + 1] = { inst = inst, globalKey = globalKey }
        if globalKey then _G[globalKey] = inst end
    end

    -- กลางวัน: จำค่าแสงเดิมครั้งแรกที่เปิด
    function Cleanup.saveLighting(Lighting)
        if not lightingSaved then
            lightingSaved = true
            lightingOriginals.ambient = Lighting.Ambient
            lightingOriginals.outdoor = Lighting.OutdoorAmbient
            lightingOriginals.shadows = Lighting.GlobalShadows
        end
    end
    function Cleanup.getLightingOriginals()
        return lightingOriginals, lightingSaved
    end

    function Cleanup.run()
        -- 1) หยุดทุก connection ก่อน
        for _, c in ipairs(connections) do
            pcall(function() c:Disconnect() end)
        end
        connections = {}

        -- 2) callback จากโมดูลอื่น (เช่น ESP ลบ instance ออกจากตัวละคร)
        for _, fn in ipairs(callbacks) do
            pcall(fn)
        end

        -- 3) คืนค่าแมพ/ของ
        for obj, data in pairs(mapObjects) do
            restoreObject(obj, data)
        end
        mapObjects = {}
        for _, data in ipairs(clickObjects) do
            restoreObject(data.obj, data)
        end
        clickObjects = {}

        -- 4) เสา + highlight
        for _, p in ipairs(poles) do
            pcall(function() p:Destroy() end)
        end
        poles = {}
        for _, hl in ipairs(highlights) do
            pcall(function() hl:Destroy() end)
        end
        highlights = {}

        -- 5) คืนค่าแสง
        if lightingSaved then
            pcall(function()
                local Lighting = game:GetService("Lighting")
                Lighting.Ambient = lightingOriginals.ambient or Color3.fromRGB(127, 127, 127)
                Lighting.OutdoorAmbient = lightingOriginals.outdoor or Color3.fromRGB(127, 127, 127)
                if lightingOriginals.shadows ~= nil then Lighting.GlobalShadows = lightingOriginals.shadows end
            end)
            lightingSaved = false
            lightingOriginals = {}
        end

        -- 6) คืน WalkSpeed
        pcall(function()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = 16
            end
        end)

        -- 7) ลบ UI ทั้งหมด + เคลียร์ _G
        for _, t in ipairs(trackedInstances) do
            pcall(function() t.inst:Destroy() end)
            if t.globalKey then _G[t.globalKey] = nil end
        end
        trackedInstances = {}
    end

    return Cleanup
end

end)()
if type(__factory_cleanup) ~= "function" then error("Module cleanup did not return a factory function") end

-- ========== MODULE: logger ==========
local __factory_logger = (function()
return function(env)
    local RunService = env.RunService
    local Players = env.Players
    local LocalPlayer = env.LocalPlayer
    local State = env.State

    local Logger = {}
    local Guard = {}

    -- ====== Configuration ======
    State.DebugLogging = State.DebugLogging or false
    local maxLogs = 200
    local logBuffer = {}

    -- Format helper
    local function getTimestamp()
        local t = tick()
        local s = math.floor(t % 60)
        local m = math.floor((t / 60) % 60)
        local h = math.floor((t / 3600) % 24)
        local ms = math.floor((t - math.floor(t)) * 1000)
        return string.format("%02d:%02d:%02d.%03d", h, m, s, ms)
    end

    -- Core Log Function
    function Logger.log(module, level, event, details, preState, postState)
        local entry = {
            time = getTimestamp(),
            tick = tick(),
            module = tostring(module or "System"),
            level = tostring(level or "INFO"),
            event = tostring(event or ""),
            details = tostring(details or ""),
            preState = preState,
            postState = postState
        }

        logBuffer[#logBuffer + 1] = entry
        if #logBuffer > maxLogs then
            table.remove(logBuffer, 1)
        end

        if State.DebugLogging or level == "ERROR" or level == "WARN" then
            local prefix = "[" .. entry.time .. "] [" .. entry.module .. "] [" .. entry.level .. "] "
            if level == "ERROR" then
                warn(prefix .. entry.event .. " - " .. entry.details)
            else
                print(prefix .. entry.event .. (entry.details ~= "" and (" - " .. entry.details) or ""))
            end
        end

        return entry
    end

    function Logger.info(module, event, details)
        return Logger.log(module, "INFO", event, details)
    end

    function Logger.warn(module, event, details)
        return Logger.log(module, "WARN", event, details)
    end

    function Logger.error(module, event, err)
        return Logger.log(module, "ERROR", event, tostring(err))
    end

    function Logger.detect(module, event, details, preState, postState)
        return Logger.log(module, "DETECT", event, details, preState, postState)
    end

    function Logger.getLogs()
        return logBuffer
    end

    function Logger.clearLogs()
        logBuffer = {}
    end

    function Logger.exportToFile(filename)
        filename = filename or "UtilityHub_log.txt"
        -- Force path to UtilityHub_Data
        local path = "UtilityHub_Data/" .. filename:gsub("UtilityHub_Data/", "")
        
        local lines = {}
        lines[#lines + 1] = "=== UtilityHub System Diagnostic Logs ==="
        lines[#lines + 1] = "Exported at: " .. os.date("%Y-%m-%d %H:%M:%S") .. " | Tick: " .. tostring(tick())
        lines[#lines + 1] = "--------------------------------------------------------"
        for _, entry in ipairs(logBuffer) do
            lines[#lines + 1] = string.format("[%s] [%s] [%s] %s%s",
                entry.time,
                entry.module,
                entry.level,
                entry.event,
                (entry.details ~= "" and (" | " .. entry.details) or "")
            )
        end
        local content = table.concat(lines, "\n")
        if writefile then
            pcall(function()
                if not isfolder("UtilityHub_Data") then makefolder("UtilityHub_Data") end
                writefile(path, content)
            end)
            return true, "บันทึก log ลงไฟล์ " .. path .. " สำเร็จ"
        end
        return false, "Executor ไม่รองรับ writefile"
    end

    -- ========================================================================
    -- FAIL-SAFE & VALIDATION LAYER (Guard)
    -- ========================================================================

    -- Safe function executor with module error boundary
    function Guard.safeCall(module, fnName, fn, ...)
        local ok, result = pcall(fn, ...)
        if not ok then
            Logger.error(module, "Function failed: " .. tostring(fnName), result)
            return false, result
        end
        return true, result
    end

    -- Safe Loop wrapper: Prevents a single tick error from breaking RenderStepped/Heartbeat loops
    local errorThrottle = {}
    function Guard.safeLoop(module, loopName, fn)
        return function(...)
            local ok, err = pcall(fn, ...)
            if not ok then
                local now = tick()
                local lastLogged = errorThrottle[loopName] or 0
                if now - lastLogged > 2 then -- throttle log to once every 2 seconds
                    errorThrottle[loopName] = now
                    Logger.error(module, "Loop exception in " .. tostring(loopName), err)
                end
            end
        end
    end

    -- Player Validation: Multi-factor integrity checks
    function Guard.validatePlayer(player, requireLiving)
        if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
            return false, "Invalid player instance"
        end
        if player == LocalPlayer then
            return false, "LocalPlayer ignored"
        end

        local char = player.Character
        if not char or not char.Parent or not char:IsDescendantOf(workspace) then
            return false, "Character not in workspace"
        end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp or not hrp:IsA("BasePart") then
            return false, "HumanoidRootPart missing"
        end

        -- Check for NaN or infinite coordinates
        local pos = hrp.Position
        if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then
            return false, "Corrupted NaN position"
        end

        if requireLiving ~= false then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then
                return false, "Player is dead or humanoid missing"
            end
        end

        return true, "Valid", char, hrp
    end

    -- Raycast Validation: Prevents NaN math and invalid arguments
    function Guard.validateRaycast(origin, targetPos, filterList)
        if typeof(origin) ~= "Vector3" or typeof(targetPos) ~= "Vector3" then
            return false, "Invalid origin or target Vector3"
        end
        local dir = targetPos - origin
        if dir.Magnitude < 0.001 or dir.Magnitude > 50000 then
            return false, "Raycast direction magnitude out of bounds"
        end

        local cleanFilter = {}
        if type(filterList) == "table" then
            for _, item in ipairs(filterList) do
                if typeof(item) == "Instance" and item.Parent then
                    cleanFilter[#cleanFilter + 1] = item
                end
            end
        end

        return true, dir, cleanFilter
    end

    -- Camera Validation: Auto-recovers current camera
    function Guard.validateCamera()
        local cam = workspace.CurrentCamera
        if not cam or not cam.Parent then
            cam = workspace:FindFirstChildOfClass("Camera")
            if cam then
                workspace.CurrentCamera = cam
            end
        end
        return cam
    end

    return {
        Logger = Logger,
        Guard = Guard
    }
end

end)()
if type(__factory_logger) ~= "function" then error("Module logger did not return a factory function") end

-- ========== MODULE: ui_factory ==========
local __factory_ui_factory = (function()
return function(env)
    local UserInputService = env.UserInputService
    local Cleanup = env.Cleanup
    local Colors = env.Colors
    local State = env.State

    local UIF = {}

    -- Palette & Theme Constants
    UIF.Theme = {
        Bg = Color3.fromRGB(18, 18, 24),
        Sidebar = Color3.fromRGB(24, 24, 32),
        CardBg = Color3.fromRGB(30, 30, 42),
        CardHover = Color3.fromRGB(38, 38, 52),
        CardBorder = Color3.fromRGB(45, 45, 62),
        AccentGreen = Color3.fromRGB(34, 197, 94),
        AccentBlue = Color3.fromRGB(14, 165, 233),
        AccentPurple = Color3.fromRGB(139, 92, 246),
        AccentPink = Color3.fromRGB(236, 72, 153),
        AccentYellow = Color3.fromRGB(250, 204, 21),
        AccentRed = Color3.fromRGB(239, 68, 68),
        AccentOrange = Color3.fromRGB(249, 115, 22),
        Text = Color3.fromRGB(245, 245, 250),
        TextDim = Color3.fromRGB(150, 150, 165),
        TextDark = Color3.fromRGB(15, 23, 42),
        SwitchOff = Color3.fromRGB(45, 45, 60),
        DangerBg = Color3.fromRGB(50, 25, 30),
        DangerHover = Color3.fromRGB(70, 30, 38),
    }

    -- Basic Label
    function UIF.label(parent, opts)
        opts = opts or {}
        local lbl = Instance.new("TextLabel")
        lbl.Size = opts.Size or UDim2.new(1, 0, 0, 20)
        if opts.Position then lbl.Position = opts.Position end
        lbl.BackgroundTransparency = 1
        lbl.Text = opts.Text or ""
        lbl.TextColor3 = opts.TextColor3 or UIF.Theme.Text
        lbl.TextSize = opts.TextSize or 12
        lbl.Font = opts.Font or Enum.Font.Gotham
        lbl.TextXAlignment = opts.TextXAlignment or Enum.TextXAlignment.Center
        if opts.TextWrapped ~= nil then lbl.TextWrapped = opts.TextWrapped end
        if opts.ZIndex then lbl.ZIndex = opts.ZIndex end
        lbl.Parent = parent
        return lbl
    end

    -- Section Header with accent bar
    function UIF.sectionHeader(parent, text, icon)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 26)
        frame.BackgroundTransparency = 1
        frame.Parent = parent

        local bar = Instance.new("Frame", frame)
        bar.Size = UDim2.new(0, 3, 0, 14)
        bar.Position = UDim2.new(0, 2, 0.5, -7)
        bar.BackgroundColor3 = UIF.Theme.AccentBlue
        bar.BorderSizePixel = 0
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local title = Instance.new("TextLabel", frame)
        title.Size = UDim2.new(1, -20, 1, 0)
        title.Position = UDim2.new(0, 12, 0, 0)
        title.BackgroundTransparency = 1
        title.Text = (icon and (icon .. " ") or "") .. string.upper(text)
        title.TextColor3 = UIF.Theme.TextDim
        title.TextSize = 11
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left

        return frame
    end

    -- Standard Action Button (Compatibility & Normal actions)
    function UIF.button(parent, opts)
        opts = opts or {}
        local btn = Instance.new("TextButton")
        btn.Size = opts.Size or UDim2.new(1, 0, 0, 38)
        if opts.Position then btn.Position = opts.Position end
        btn.BackgroundColor3 = opts.Bg or UIF.Theme.CardBg
        btn.Text = opts.Text or ""
        btn.TextColor3 = opts.TextColor3 or UIF.Theme.Text
        btn.TextSize = opts.TextSize or 12
        btn.Font = opts.Font or Enum.Font.GothamBold
        btn.TextXAlignment = opts.TextXAlignment or Enum.TextXAlignment.Center
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = UIF.Theme.CardBorder
        stroke.Thickness = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

        btn.MouseEnter:Connect(function()
            if btn.BackgroundColor3 == UIF.Theme.CardBg then
                btn.BackgroundColor3 = UIF.Theme.CardHover
            end
            stroke.Color = opts.HoverBorder or UIF.Theme.AccentBlue
        end)
        btn.MouseLeave:Connect(function()
            if btn.BackgroundColor3 == UIF.Theme.CardHover then
                btn.BackgroundColor3 = UIF.Theme.CardBg
            end
            if btn.BackgroundColor3 == UIF.Theme.AccentGreen then
                stroke.Color = UIF.Theme.AccentGreen
            else
                stroke.Color = UIF.Theme.CardBorder
            end
        end)

        btn.Parent = parent
        if opts.OnActivated then
            btn.Activated:Connect(opts.OnActivated)
        end
        return btn
    end

    -- Helper: Standard Toggle Button State Setter
    function UIF.setButtonState(btn, active, activeText, inactiveText)
        if not btn then return end
        local stroke = btn:FindFirstChildOfClass("UIStroke")
        if active then
            if activeText then btn.Text = activeText end
            btn.BackgroundColor3 = UIF.Theme.AccentGreen
            btn.TextColor3 = UIF.Theme.TextDark
            if stroke then stroke.Color = UIF.Theme.AccentGreen end
        else
            if inactiveText then btn.Text = inactiveText end
            btn.BackgroundColor3 = UIF.Theme.CardBg
            btn.TextColor3 = UIF.Theme.Text
            if stroke then stroke.Color = UIF.Theme.CardBorder end
        end
    end

    -- Modern Interactive Toggle Card
    function UIF.toggleCard(parent, opts)
        opts = opts or {}
        local card = Instance.new("TextButton")
        card.Size = UDim2.new(1, 0, 0, 48)
        card.BackgroundColor3 = UIF.Theme.CardBg
        card.BorderSizePixel = 0
        card.AutoButtonColor = false
        card.Text = ""
        card.Parent = parent
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke", card)
        stroke.Color = UIF.Theme.CardBorder
        stroke.Thickness = 1

        local iconLbl = Instance.new("TextLabel", card)
        iconLbl.Size = UDim2.new(0, 28, 0, 28)
        iconLbl.Position = UDim2.new(0, 10, 0.5, -14)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Text = opts.Icon or "⚡"
        iconLbl.TextSize = 16
        iconLbl.Font = Enum.Font.Gotham

        local titleLbl = Instance.new("TextLabel", card)
        titleLbl.Size = UDim2.new(1, -110, 0, 18)
        titleLbl.Position = UDim2.new(0, 44, 0, 8)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = opts.Title or "Toggle Feature"
        titleLbl.TextColor3 = UIF.Theme.Text
        titleLbl.TextSize = 12
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left

        local descLbl = Instance.new("TextLabel", card)
        descLbl.Size = UDim2.new(1, -110, 0, 14)
        descLbl.Position = UDim2.new(0, 44, 0, 26)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = opts.Desc or ""
        descLbl.TextColor3 = UIF.Theme.TextDim
        descLbl.TextSize = 10
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextXAlignment = Enum.TextXAlignment.Left

        -- Switch element
        local switchTrack = Instance.new("Frame", card)
        switchTrack.Size = UDim2.new(0, 40, 0, 22)
        switchTrack.Position = UDim2.new(1, -50, 0.5, -11)
        switchTrack.BackgroundColor3 = opts.Active and (opts.ActiveColor or UIF.Theme.AccentGreen) or UIF.Theme.SwitchOff
        switchTrack.BorderSizePixel = 0
        Instance.new("UICorner", switchTrack).CornerRadius = UDim.new(1, 0)

        local switchKnob = Instance.new("Frame", switchTrack)
        switchKnob.Size = UDim2.new(0, 16, 0, 16)
        switchKnob.Position = opts.Active and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        switchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        switchKnob.BorderSizePixel = 0
        Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(1, 0)

        local function setState(active, color)
            local activeColor = color or opts.ActiveColor or UIF.Theme.AccentGreen
            if active then
                switchTrack.BackgroundColor3 = activeColor
                switchKnob.Position = UDim2.new(1, -19, 0.5, -8)
                stroke.Color = activeColor
            else
                switchTrack.BackgroundColor3 = UIF.Theme.SwitchOff
                switchKnob.Position = UDim2.new(0, 3, 0.5, -8)
                stroke.Color = UIF.Theme.CardBorder
            end
        end

        card.MouseEnter:Connect(function()
            card.BackgroundColor3 = UIF.Theme.CardHover
        end)
        card.MouseLeave:Connect(function()
            card.BackgroundColor3 = UIF.Theme.CardBg
        end)

        return {
            card = card,
            btn = card,
            title = titleLbl,
            desc = descLbl,
            setState = setState,
            track = switchTrack,
            knob = switchKnob
        }
    end

    -- Modern Slider Card
    function UIF.sliderCard(parent, opts)
        opts = opts or {}
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 56)
        card.BackgroundColor3 = UIF.Theme.CardBg
        card.BorderSizePixel = 0
        card.Parent = parent
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke", card)
        stroke.Color = UIF.Theme.CardBorder
        stroke.Thickness = 1

        local titleLbl = Instance.new("TextLabel", card)
        titleLbl.Size = UDim2.new(1, -80, 0, 18)
        titleLbl.Position = UDim2.new(0, 12, 0, 6)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = (opts.Icon and (opts.Icon .. " ") or "") .. (opts.Title or "Slider")
        titleLbl.TextColor3 = UIF.Theme.Text
        titleLbl.TextSize = 12
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left

        local valBadge = Instance.new("TextLabel", card)
        valBadge.Size = UDim2.new(0, 60, 0, 18)
        valBadge.Position = UDim2.new(1, -72, 0, 6)
        valBadge.BackgroundColor3 = UIF.Theme.Sidebar
        valBadge.Text = tostring(opts.Value or 0)
        valBadge.TextColor3 = opts.Color or UIF.Theme.AccentBlue
        valBadge.TextSize = 11
        valBadge.Font = Enum.Font.GothamBold
        Instance.new("UICorner", valBadge).CornerRadius = UDim.new(0, 4)

        -- Slider Track
        local sliderTrack = Instance.new("Frame", card)
        sliderTrack.Size = UDim2.new(1, -24, 0, 8)
        sliderTrack.Position = UDim2.new(0, 12, 0, 36)
        sliderTrack.BackgroundColor3 = UIF.Theme.SwitchOff
        sliderTrack.BorderSizePixel = 0
        Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(1, 0)

        local sliderFill = Instance.new("Frame", sliderTrack)
        sliderFill.Size = UDim2.new(opts.Progress or 0, 0, 1, 0)
        sliderFill.BackgroundColor3 = opts.Color or UIF.Theme.AccentBlue
        sliderFill.BorderSizePixel = 0
        Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

        local sliderBtn = Instance.new("TextButton", card)
        sliderBtn.Size = UDim2.new(1, -16, 0, 24)
        sliderBtn.Position = UDim2.new(0, 8, 0, 28)
        sliderBtn.BackgroundTransparency = 1
        sliderBtn.Text = ""
        sliderBtn.ZIndex = 5

        return {
            card = card,
            frame = sliderTrack,
            fill = sliderFill,
            text = valBadge,
            title = titleLbl,
            btn = sliderBtn
        }
    end

    -- Modern Hotkey Card with Rebind Pulse & Escape Support
    function UIF.hotkeyCard(parent, opts)
        opts = opts or {}
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 48)
        card.BackgroundColor3 = UIF.Theme.CardBg
        card.BorderSizePixel = 0
        card.Parent = parent
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

        local stroke = Instance.new("UIStroke", card)
        stroke.Color = UIF.Theme.CardBorder
        stroke.Thickness = 1

        local actionBtn = Instance.new("TextButton", card)
        actionBtn.Size = UDim2.new(1, -80, 1, 0)
        actionBtn.Position = UDim2.new(0, 0, 0, 0)
        actionBtn.BackgroundTransparency = 1
        actionBtn.Text = ""
        actionBtn.AutoButtonColor = false

        local iconLbl = Instance.new("TextLabel", actionBtn)
        iconLbl.Size = UDim2.new(0, 28, 0, 28)
        iconLbl.Position = UDim2.new(0, 10, 0.5, -14)
        iconLbl.BackgroundTransparency = 1
        iconLbl.Text = opts.Icon or "⌨️"
        iconLbl.TextSize = 16
        iconLbl.Font = Enum.Font.Gotham

        local titleLbl = Instance.new("TextLabel", actionBtn)
        titleLbl.Size = UDim2.new(1, -44, 0, 18)
        titleLbl.Position = UDim2.new(0, 44, 0, 8)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = opts.Text or "Hotkey Action"
        titleLbl.TextColor3 = UIF.Theme.Text
        titleLbl.TextSize = 12
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left

        local descLbl = Instance.new("TextLabel", actionBtn)
        descLbl.Size = UDim2.new(1, -44, 0, 14)
        descLbl.Position = UDim2.new(0, 44, 0, 26)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = opts.Desc or "คลิกเพื่อเปิด/ปิด หรือกดปุ่มลัด"
        descLbl.TextColor3 = UIF.Theme.TextDim
        descLbl.TextSize = 10
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextXAlignment = Enum.TextXAlignment.Left

        local currentKeyName = State.Bindings[opts.Bind] and State.Bindings[opts.Bind].Name or "None"
        local keyBtn = Instance.new("TextButton", card)
        keyBtn.Size = UDim2.new(0, 64, 0, 28)
        keyBtn.Position = UDim2.new(1, -72, 0.5, -14)
        keyBtn.BackgroundColor3 = UIF.Theme.Sidebar
        keyBtn.Text = "[" .. currentKeyName .. "]"
        keyBtn.TextColor3 = UIF.Theme.AccentYellow
        keyBtn.TextSize = 11
        keyBtn.Font = Enum.Font.GothamBold
        keyBtn.BorderSizePixel = 0
        Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)
        local keyStroke = Instance.new("UIStroke", keyBtn)
        keyStroke.Color = UIF.Theme.CardBorder
        keyStroke.Thickness = 1

        local isBinding = false
        local isCardActive = false

        local function cancelBinding()
            isBinding = false
            State.isAnyBinding = false
            local keyName = State.Bindings[opts.Bind] and State.Bindings[opts.Bind].Name or "None"
            keyBtn.Text = "[" .. keyName .. "]"
            keyBtn.BackgroundColor3 = UIF.Theme.Sidebar
            keyBtn.TextColor3 = UIF.Theme.AccentYellow
            keyStroke.Color = UIF.Theme.CardBorder
        end

        local function setCardState(active, titleText)
            isCardActive = active
            if titleText then titleLbl.Text = titleText end
            if active then
                card.BackgroundColor3 = UIF.Theme.AccentGreen
                stroke.Color = UIF.Theme.AccentGreen
                titleLbl.TextColor3 = UIF.Theme.TextDark
                descLbl.TextColor3 = Color3.fromRGB(30, 40, 50)
            else
                card.BackgroundColor3 = UIF.Theme.CardBg
                stroke.Color = UIF.Theme.CardBorder
                titleLbl.TextColor3 = UIF.Theme.Text
                descLbl.TextColor3 = UIF.Theme.TextDim
            end
        end

        keyBtn.Activated:Connect(function()
            if isBinding then
                cancelBinding()
                return
            end
            isBinding = true
            State.isAnyBinding = true
            keyBtn.Text = "..."
            keyBtn.BackgroundColor3 = UIF.Theme.AccentYellow
            keyBtn.TextColor3 = UIF.Theme.TextDark
            keyStroke.Color = UIF.Theme.AccentYellow
        end)

        Cleanup.conn(UserInputService.InputBegan:Connect(function(input)
            if isBinding and input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    cancelBinding()
                    return
                end
                if input.KeyCode ~= Enum.KeyCode.Unknown then
                    State.Bindings[opts.Bind] = input.KeyCode
                    keyBtn.Text = "[" .. input.KeyCode.Name .. "]"
                    keyBtn.BackgroundColor3 = UIF.Theme.Sidebar
                    keyBtn.TextColor3 = UIF.Theme.AccentYellow
                    keyStroke.Color = UIF.Theme.CardBorder
                    isBinding = false
                    State.isAnyBinding = false
                    if env.UI and env.UI.showNotif then
                        env.UI.showNotif("⌨️ เปลี่ยนปุ่มเป็น [" .. input.KeyCode.Name .. "] แล้ว", 2)
                    end
                end
            end
        end))

        card.MouseEnter:Connect(function()
            if not isCardActive and card.BackgroundColor3 == UIF.Theme.CardBg then
                card.BackgroundColor3 = UIF.Theme.CardHover
            end
        end)
        card.MouseLeave:Connect(function()
            if isCardActive or card.BackgroundColor3 == UIF.Theme.AccentGreen then
                card.BackgroundColor3 = UIF.Theme.AccentGreen
                stroke.Color = UIF.Theme.AccentGreen
            else
                card.BackgroundColor3 = UIF.Theme.CardBg
                stroke.Color = UIF.Theme.CardBorder
            end
        end)

        return {
            card = card,
            btn = actionBtn,
            keyBtn = keyBtn,
            bind = opts.Bind,
            title = titleLbl,
            desc = descLbl,
            setState = setCardState
        }
    end

    -- Backwards-compatible Wrappers
    function UIF.hotkeyRow(parent, opts)
        return UIF.hotkeyCard(parent, opts)
    end

    function UIF.slider(parent, opts)
        return UIF.sliderCard(parent, opts)
    end

    return UIF
end

end)()
if type(__factory_ui_factory) ~= "function" then error("Module ui_factory did not return a factory function") end

-- ========== MODULE: hub ==========
local __factory_hub = (function()
return function(env)
    local UserInputService = env.UserInputService
    local Cleanup = env.Cleanup
    local UIF = env.UIF
    local Colors = env.Colors
    local State = env.State
    local Camera = env.Camera

    local UI = {}

    -- ====== ScreenGui ======
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UtilityHubUI_" .. tostring(math.random(100000, 999999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = env.getSafeParent()
    env.ProtectMyUI(ScreenGui)
    Cleanup.trackInstance(ScreenGui, "UtilityUI")

    -- ====== Main Window ======
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 530, 0, 370)
    Main.Position = UDim2.new(0.5, -265, 0.5, -185)
    Main.BackgroundColor3 = UIF.Theme.Bg
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

    local mainStroke = Instance.new("UIStroke", Main)
    mainStroke.Color = UIF.Theme.CardBorder
    mainStroke.Thickness = 1.5

    -- ====== Floating Minimized Widget ======
    local OpenBtn = Instance.new("TextButton")
    OpenBtn.Size = UDim2.new(0, 130, 0, 38)
    OpenBtn.Position = UDim2.new(0, 20, 0, 60)
    OpenBtn.BackgroundColor3 = UIF.Theme.Bg
    OpenBtn.Text = "⚡ UtilityHub"
    OpenBtn.TextColor3 = UIF.Theme.AccentGreen
    OpenBtn.TextSize = 13
    OpenBtn.Font = Enum.Font.GothamBold
    OpenBtn.Visible = false
    OpenBtn.Active = true
    OpenBtn.Parent = ScreenGui
    Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 10)
    local openStroke = Instance.new("UIStroke", OpenBtn)
    openStroke.Color = UIF.Theme.AccentGreen
    openStroke.Thickness = 1.5

    -- Dragging Floating Widget
    local minDragging, minDragStart, minStartPos
    OpenBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            minDragging = true
            minDragStart = input.Position
            minStartPos = OpenBtn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then minDragging = false end
            end)
        end
    end)
    Cleanup.conn(UserInputService.InputChanged:Connect(function(input)
        if minDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - minDragStart
            OpenBtn.Position = UDim2.new(minStartPos.X.Scale, minStartPos.X.Offset + delta.X, minStartPos.Y.Scale, minStartPos.Y.Offset + delta.Y)
        end
    end))

    -- ====== Header Bar ======
    local Header = Instance.new("Frame", Main)
    Header.Size = UDim2.new(1, 0, 0, 48)
    Header.BackgroundColor3 = UIF.Theme.Sidebar
    Header.BorderSizePixel = 0
    Header.Active = true

    local headerBorder = Instance.new("Frame", Header)
    headerBorder.Size = UDim2.new(1, 0, 0, 1)
    headerBorder.Position = UDim2.new(0, 0, 1, -1)
    headerBorder.BackgroundColor3 = UIF.Theme.CardBorder
    headerBorder.BorderSizePixel = 0

    local Logo = Instance.new("TextLabel", Header)
    Logo.Size = UDim2.new(0, 140, 1, 0)
    Logo.Position = UDim2.new(0, 14, 0, 0)
    Logo.BackgroundTransparency = 1
    Logo.Text = "⚡ UtilityHub"
    Logo.TextColor3 = UIF.Theme.Text
    Logo.TextSize = 15
    Logo.Font = Enum.Font.GothamBold
    Logo.TextXAlignment = Enum.TextXAlignment.Left

    local VersionBadge = Instance.new("TextLabel", Header)
    VersionBadge.Size = UDim2.new(0, 42, 0, 18)
    VersionBadge.Position = UDim2.new(0, 126, 0.5, -9)
    VersionBadge.BackgroundColor3 = UIF.Theme.AccentGreen
    VersionBadge.BackgroundTransparency = 0.85
    VersionBadge.Text = "v2.0"
    VersionBadge.TextColor3 = UIF.Theme.AccentGreen
    VersionBadge.TextSize = 10
    VersionBadge.Font = Enum.Font.GothamBold
    Instance.new("UICorner", VersionBadge).CornerRadius = UDim.new(0, 4)

    -- Search Box
    local SearchFrame = Instance.new("Frame", Header)
    SearchFrame.Size = UDim2.new(0, 170, 0, 28)
    SearchFrame.Position = UDim2.new(0, 185, 0.5, -14)
    SearchFrame.BackgroundColor3 = UIF.Theme.CardBg
    SearchFrame.BorderSizePixel = 0
    Instance.new("UICorner", SearchFrame).CornerRadius = UDim.new(0, 6)
    local searchStroke = Instance.new("UIStroke", SearchFrame)
    searchStroke.Color = UIF.Theme.CardBorder
    searchStroke.Thickness = 1

    local SearchIcon = Instance.new("TextLabel", SearchFrame)
    SearchIcon.Size = UDim2.new(0, 24, 1, 0)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Text = "🔍"
    SearchIcon.TextSize = 11
    SearchIcon.Font = Enum.Font.Gotham

    local SearchBox = Instance.new("TextBox", SearchFrame)
    SearchBox.Size = UDim2.new(1, -28, 1, 0)
    SearchBox.Position = UDim2.new(0, 24, 0, 0)
    SearchBox.BackgroundTransparency = 1
    SearchBox.PlaceholderText = "ค้นหาฟังก์ชัน..."
    SearchBox.PlaceholderColor3 = UIF.Theme.TextDim
    SearchBox.Text = ""
    SearchBox.TextColor3 = UIF.Theme.Text
    SearchBox.TextSize = 11
    SearchBox.Font = Enum.Font.Gotham
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.ClearTextOnFocus = false

    -- Window Controls
    local MinBtn = Instance.new("TextButton", Header)
    MinBtn.Size = UDim2.new(0, 28, 0, 28)
    MinBtn.Position = UDim2.new(1, -66, 0.5, -14)
    MinBtn.BackgroundColor3 = UIF.Theme.CardBg
    MinBtn.Text = "—"
    MinBtn.TextColor3 = UIF.Theme.TextDim
    MinBtn.TextSize = 12
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.BorderSizePixel = 0
    MinBtn.Active = true
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)
    local minStroke = Instance.new("UIStroke", MinBtn)
    minStroke.Color = UIF.Theme.CardBorder
    minStroke.Thickness = 1

    local CloseBtn = Instance.new("TextButton", Header)
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -34, 0.5, -14)
    CloseBtn.BackgroundColor3 = UIF.Theme.DangerBg
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = UIF.Theme.AccentRed
    CloseBtn.TextSize = 12
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Active = true
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
    local closeStroke = Instance.new("UIStroke", CloseBtn)
    closeStroke.Color = UIF.Theme.AccentRed
    closeStroke.Thickness = 1

    MinBtn.Activated:Connect(function()
        Main.Visible = false
        OpenBtn.Visible = true
    end)
    OpenBtn.Activated:Connect(function()
        Main.Visible = true
        OpenBtn.Visible = false
    end)

    -- Window Dragging
    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
            and not State.draggingSlider and not State.draggingPred and not State.draggingFOV and not State.isAnyBinding then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    Cleanup.conn(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    -- ====== Sidebar Navigation ======
    local Sidebar = Instance.new("Frame", Main)
    Sidebar.Size = UDim2.new(0, 135, 1, -48)
    Sidebar.Position = UDim2.new(0, 0, 0, 48)
    Sidebar.BackgroundColor3 = UIF.Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.Active = true

    local sidebarBorder = Instance.new("Frame", Sidebar)
    sidebarBorder.Size = UDim2.new(0, 1, 1, 0)
    sidebarBorder.Position = UDim2.new(1, -1, 0, 0)
    sidebarBorder.BackgroundColor3 = UIF.Theme.CardBorder
    sidebarBorder.BorderSizePixel = 0

    local TabContainer = Instance.new("ScrollingFrame", Sidebar)
    TabContainer.Size = UDim2.new(1, 0, 1, -36)
    TabContainer.BackgroundTransparency = 1
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 2
    TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TabContainer.Active = true
    local tabLayout = Instance.new("UIListLayout", TabContainer)
    tabLayout.Padding = UDim.new(0, 4)
    Instance.new("UIPadding", TabContainer).PaddingTop = UDim.new(0, 8)
    TabContainer.UIPadding.PaddingLeft = UDim.new(0, 8)
    TabContainer.UIPadding.PaddingRight = UDim.new(0, 8)

    local Status = Instance.new("TextLabel", Sidebar)
    Status.Size = UDim2.new(1, -16, 0, 24)
    Status.Position = UDim2.new(0, 8, 1, -30)
    Status.BackgroundColor3 = UIF.Theme.CardBg
    Status.Text = "● พร้อมใช้งาน"
    Status.TextColor3 = UIF.Theme.AccentGreen
    Status.TextSize = 10
    Status.Font = Enum.Font.GothamBold
    Instance.new("UICorner", Status).CornerRadius = UDim.new(0, 4)

    -- ====== Content Area ======
    local ContentArea = Instance.new("Frame", Main)
    ContentArea.Size = UDim2.new(1, -135, 1, -48)
    ContentArea.Position = UDim2.new(0, 135, 0, 48)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Active = true

    -- Tab System
    local tabs = {}
    local tabButtons = {}
    local allCards = {}
    local currentTabKey = "combat"

    local function createTab(key, name, icon)
        local btn = Instance.new("TextButton", TabContainer)
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = UIF.Theme.Sidebar
        btn.Text = " " .. icon .. "  " .. name
        btn.TextColor3 = UIF.Theme.TextDim
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Active = true
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local ind = Instance.new("Frame", btn)
        ind.Size = UDim2.new(0, 3, 0.6, 0)
        ind.Position = UDim2.new(0, 2, 0.2, 0)
        ind.BackgroundColor3 = UIF.Theme.AccentBlue
        ind.BorderSizePixel = 0
        ind.Visible = false
        Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)

        local page = Instance.new("ScrollingFrame", ContentArea)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 110)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Active = true

        local pageLayout = Instance.new("UIListLayout", page)
        pageLayout.Padding = UDim.new(0, 8)
        local pagePad = Instance.new("UIPadding", page)
        pagePad.PaddingTop = UDim.new(0, 10)
        pagePad.PaddingBottom = UDim.new(0, 12)
        pagePad.PaddingLeft = UDim.new(0, 12)
        pagePad.PaddingRight = UDim.new(0, 12)

        tabs[key] = page
        tabButtons[key] = { btn = btn, ind = ind }

        btn.Activated:Connect(function()
            for k, p in pairs(tabs) do
                p.Visible = (k == key)
                tabButtons[k].btn.BackgroundColor3 = (k == key) and UIF.Theme.CardBg or UIF.Theme.Sidebar
                tabButtons[k].btn.TextColor3 = (k == key) and UIF.Theme.Text or UIF.Theme.TextDim
                tabButtons[k].ind.Visible = (k == key)
            end
            currentTabKey = key
        end)

        return page
    end

    local pageCombat = createTab("combat", "Combat", "🎯")
    local pageVisuals = createTab("visuals", "Visuals", "👁️")
    local pageWorld = createTab("world", "World / Misc", "🌍")
    local pageTeam = createTab("team", "Team Radar", "🛡️")
    local pageHotkeys = createTab("hotkeys", "Hotkeys", "⌨️")
    local pageMaster = createTab("master", "Master & Exit", "⚙️")

    tabs["combat"].Visible = true
    tabButtons["combat"].btn.BackgroundColor3 = UIF.Theme.CardBg
    tabButtons["combat"].btn.TextColor3 = UIF.Theme.Text
    tabButtons["combat"].ind.Visible = true

    local function registerCard(cardObj, keywords)
        allCards[#allCards + 1] = {
            instance = cardObj,
            text = string.lower(keywords or "")
        }
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = string.lower(string.gsub(SearchBox.Text, "%s+", ""))
        if query == "" then
            for _, item in ipairs(allCards) do
                item.instance.Visible = true
            end
        else
            for _, item in ipairs(allCards) do
                if string.find(item.text, query) then
                    item.instance.Visible = true
                else
                    item.instance.Visible = false
                end
            end
        end
    end)

    -- ====== Notification Toast ======
    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "UtilityNotifUI"
    NotifGui.ResetOnSpawn = false
    NotifGui.IgnoreGuiInset = true
    NotifGui.Parent = env.getSafeParent()
    env.ProtectMyUI(NotifGui)
    Cleanup.trackInstance(NotifGui, "UtilityNotifUI")

    local NotifFrame = Instance.new("Frame", NotifGui)
    NotifFrame.Size = UDim2.new(0, 320, 0, 44)
    NotifFrame.Position = UDim2.new(0.5, -160, 0, 20)
    NotifFrame.BackgroundColor3 = UIF.Theme.Bg
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Visible = false
    NotifFrame.Active = true
    Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 8)
    local notifStroke = Instance.new("UIStroke", NotifFrame)
    notifStroke.Color = UIF.Theme.AccentGreen
    notifStroke.Thickness = 1.5

    local NotifText = Instance.new("TextLabel", NotifFrame)
    NotifText.Size = UDim2.new(1, -20, 1, 0)
    NotifText.Position = UDim2.new(0, 10, 0, 0)
    NotifText.BackgroundTransparency = 1
    NotifText.TextColor3 = UIF.Theme.Text
    NotifText.TextSize = 12
    NotifText.Font = Enum.Font.GothamBold
    NotifText.Text = ""

    function UI.showNotif(text, duration)
        NotifText.Text = text
        NotifFrame.Visible = true
        task.delay(duration or 2.5, function()
            if NotifText.Text == text then
                NotifFrame.Visible = false
            end
        end)
    end

    local B = {}
    local S = {}
    local HK = {}

    -- ========================================================================
    -- 1. COMBAT TAB
    -- ========================================================================
    UIF.sectionHeader(pageCombat, "ระบบล็อคเป้า Aimbot", "🎯")

    HK.aim = UIF.hotkeyCard(pageCombat, { Text = "ระบบล็อคเป้า Aimbot", Desc = "เปิดการเล็งเป้าหมายอัตโนมัติ", Bind = "Aim", Icon = "🎯" })
    registerCard(HK.aim.card, "aim aimbot ล็อคเป้า")

    HK.lock = UIF.hotkeyCard(pageCombat, { Text = "ล็อคเป้าหมายเจาะจง", Desc = "ล็อคเป้าที่เลือกไว้ไม่ให้เปลี่ยน", Bind = "Lock", Icon = "🔒" })
    registerCard(HK.lock.card, "lock hardlock ล็อคเจาะจง")

    B.botLock = UIF.button(pageCombat, { Text = "🤖 ล็อคเป้าบอท/NPC (Bot Lock): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.botLock, "bot lock npc monster ล็อคบอท เล็งบอท มอนสเตอร์")

    B.silentAim = UIF.button(pageCombat, { Text = "🎯 Silent Aim (ยิงทะลุ): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.silentAim, "silent aim ยิงทะลุ")

    B.fov = UIF.button(pageCombat, { Text = "⭕ วงกลมล็อคเป้า (FOV): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.fov, "fov วงกลม ขนาดวง")

    S.fov = UIF.sliderCard(pageCombat, { Title = "ขนาดวง FOV: 150", Progress = 0.5, Color = UIF.Theme.AccentBlue, Icon = "⭕", Value = 150 })
    registerCard(S.fov.card, "fov radius ขนาดวง fov")

    B.aimPart = UIF.button(pageCombat, { Text = "🎯 เล็งเป้า: ลำตัว (คลิกสลับ)", Bg = UIF.Theme.CardBg })
    registerCard(B.aimPart, "head rootpart เล็งหัว เล็งตัว")

    B.wallCheck = UIF.button(pageCombat, { Text = "🧱 ตรวจจับกำแพง: ปิด (ยิงทะลุ)", Bg = UIF.Theme.CardBg })
    registerCard(B.wallCheck, "wallcheck กำแพง ทะลุกำแพง")

    B.prediction = UIF.button(pageCombat, { Text = "🔮 ยิงดักหน้า (Prediction): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.prediction, "prediction ดักหน้า ยิงดัก")

    S.pred = UIF.sliderCard(pageCombat, { Title = "ค่าดักหน้ากระสุน: 0.1", Progress = 0.5, Color = UIF.Theme.AccentBlue, Icon = "🔮", Value = "0.1" })
    registerCard(S.pred.card, "prediction slider ค่าดักหน้า")

    B.autoShoot = UIF.button(pageCombat, { Text = "🔫 ออโต้ยิงเมื่อล็อคเป้า: ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.autoShoot, "autoshoot auto shoot ออโต้ยิง")

    B.smartBone = UIF.button(pageCombat, { Text = "🧠 สลับจุดเล็งอัจฉริยะ (Smart Bone): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.smartBone, "smart bone adaptive part เล็งฉลาด สลับกระดูก")

    B.ballistics = UIF.button(pageCombat, { Text = "🏹 ชดเชยวิถีกระสุนตก (Ballistics Drop): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.ballistics, "ballistics bullet drop กระสุนตก แรงโน้มถ่วง")

    S.bulletSpeed = UIF.sliderCard(pageCombat, { Title = "ความเร็วกระสุน (Bullet Speed): 1000", Progress = 0.45, Color = UIF.Theme.AccentBlue, Icon = "🏹", Value = "1000" })
    registerCard(S.bulletSpeed.card, "bullet speed ความเร็วกระสุน ballistics")

    UIF.sectionHeader(pageCombat, "ระบบขยาย Hitbox ตัวละคร/ศัตรู", "📦")

    B.hitbox = UIF.button(pageCombat, { Text = "📦 ขยาย Hitbox ศัตรู: ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.hitbox, "hitbox expander ขยาย hitbox ขยายตัว")

    B.hitboxPart = UIF.button(pageCombat, { Text = "🎯 ส่วนที่ขยาย: หัว (Head)", Bg = UIF.Theme.CardBg })
    registerCard(B.hitboxPart, "hitbox part ขยายหัว ขยายตัว")

    S.hitboxSize = UIF.sliderCard(pageCombat, { Title = "ขนาด Hitbox: 10 studs", Progress = 0.28, Color = UIF.Theme.AccentBlue, Icon = "📦", Value = "10 studs" })
    registerCard(S.hitboxSize.card, "hitbox size ขนาด hitbox")

    -- ========================================================================
    -- 2. VISUALS TAB
    -- ========================================================================
    UIF.sectionHeader(pageVisuals, "ระบบมองทะลุ & เส้นชี้เป้า", "👁️")

    B.esp = UIF.button(pageVisuals, { Text = "👁️ มองทะลุ (ESP+เลือด): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.esp, "esp มองทะลุ หลอดเลือด เลือด")

    B.botESP = UIF.button(pageVisuals, { Text = "🤖 มองทะลุบอท (Bot ESP): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.botESP, "bot esp npc monster มองบอท มองมอนสเตอร์")

    B.corpse = UIF.button(pageVisuals, { Text = "💀 มองศพ (Loot Drops): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.corpse, "corpse loot มองศพ เก็บของ")

    B.weapon = UIF.button(pageVisuals, { Text = "🔫 บอกชื่อปืน/ไอเทมคนอื่น: ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.weapon, "weapon ปืน อาวุธ ไอเทม")

    B.tracers = UIF.button(pageVisuals, { Text = "🧶 เส้นชี้เป้า (Tracers): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.tracers, "tracers เส้นชี้เป้า เส้น")

    B.tracerMode = UIF.button(pageVisuals, { Text = "🧶 โหมดเส้น: ทุกคน (คลิกสลับ)", Bg = UIF.Theme.CardBg })
    registerCard(B.tracerMode, "tracer mode โหมดเส้น")

    S.tracerThickness = UIF.sliderCard(pageVisuals, { Title = "ขนาดความหนาเส้น (Thickness): 1.5 px", Progress = 0.1, Color = UIF.Theme.AccentBlue, Icon = "📏", Value = "1.5 px" })
    registerCard(S.tracerThickness.card, "tracer thickness ขนาดเส้น ความหนาเส้น tracer")

    B.stats = UIF.button(pageVisuals, { Text = "📊 ส่องข้อมูลเป้าหมาย: ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.stats, "stats เป้าหมาย ข้อมูล ส่อง")

    B.warning = UIF.button(pageVisuals, { Text = "⚠️ เตือนภัยกระบอกปืน: ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.warning, "warning เตือนภัย หันปืน")

    -- ========================================================================
    -- 3. WORLD / MISC TAB
    -- ========================================================================
    UIF.sectionHeader(pageWorld, "การเคลื่อนที่ & ปรับแต่งโลก", "🌍")

    S.speed = UIF.sliderCard(pageWorld, { Title = "ความเร็ววิ่ง: 16", Progress = 0, Color = UIF.Theme.AccentBlue, Icon = "🏃", Value = 16 })
    registerCard(S.speed.card, "speed walkspeed ความเร็ว วิ่ง")

    B.infJump = UIF.button(pageWorld, { Text = "🦘 Unlimited Jump: ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.infJump, "jump unlimited jump กระโดด")

    B.noClip = UIF.button(pageWorld, { Text = "🚫 NoClip (ทะลุกำแพง): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.noClip, "noclip no clip ทะลุกำแพง")

    B.day = UIF.button(pageWorld, { Text = "☀️ กลางวัน+สว่างตลอด: ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.day, "day always day สว่าง กลางวัน")

    B.fpsBoost = UIF.button(pageWorld, { Text = "🚀 FPS Booster (ดันความลื่น): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.fpsBoost, "fps boost booster potato graphics ดัน fps ความลื่น ลื่น")

    B.hitSound = UIF.button(pageWorld, { Text = "🔊 เสียงตอนโดน (Hit Sound): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.hitSound, "hitsound hit sound เสียงโดน")

    B.autoDel = UIF.button(pageWorld, { Text = "💥 ลบแมพทั้งหมด (Delete All): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.autoDel, "delete all ลบแมพ คืนค่าแมพ")

    HK.del = UIF.hotkeyCard(pageWorld, { Text = "โหมดลบของทีละชิ้น: ปิด", Desc = "กด G เพื่อเปิดโหมดลบ แล้วคลิก M3 เพื่อลบ", Bind = "Del", Icon = "🖱️" })
    registerCard(HK.del.card, "delete click ลบของ คลิกเมาส์กลาง")

    HK.pole = UIF.hotkeyCard(pageWorld, { Text = "โหมดสร้างเสาปีน: ปิด", Desc = "กดปุ่ม Z เพื่อสร้างเสาปีน ณ จุดที่เมาส์ชี้", Bind = "Pole", Icon = "🧱" })
    registerCard(HK.pole.card, "pole เสาปีน เสา truss")

    UIF.sectionHeader(pageWorld, "ระบบขยาย/ย่อ Object ในแมพ (Object Scaler)", "📐")

    HK.scaler = UIF.hotkeyCard(pageWorld, { Text = "โหมดเลือกปรับขนาด Object: ปิด", Desc = "กด H เพื่อเปิดโหมด แล้วคลิกเมาส์ที่ Object", Bind = "Scaler", Icon = "📐" })
    registerCard(HK.scaler.card, "scaler object scale ขยายวัตถุ ปรับขนาด")

    B.scaleAxis = UIF.button(pageWorld, { Text = "📐 แกนที่ปรับ: ทุกด้าน (X, Y, Z)", Bg = UIF.Theme.CardBg })
    registerCard(B.scaleAxis, "scale axis แกนขยาย x y z")

    S.scaleAmt = UIF.sliderCard(pageWorld, { Title = "ตัวคูณขนาด (Scale): 2.0x", Progress = 0.07, Color = UIF.Theme.AccentBlue, Icon = "🔍", Value = "2.0x" })
    registerCard(S.scaleAmt.card, "scale multiplier ขนาด scale slider")

    local scaleBtnRow = Instance.new("Frame", pageWorld)
    scaleBtnRow.Size = UDim2.new(1, 0, 0, 36)
    scaleBtnRow.BackgroundTransparency = 1

    B.applyScale = Instance.new("TextButton", scaleBtnRow)
    B.applyScale.Size = UDim2.new(0.31, 0, 1, 0)
    B.applyScale.Position = UDim2.new(0, 0, 0, 0)
    B.applyScale.BackgroundColor3 = UIF.Theme.AccentBlue
    B.applyScale.Text = "✨ ปรับขนาดทันที"
    B.applyScale.TextColor3 = Color3.fromRGB(255, 255, 255)
    B.applyScale.TextSize = 10
    B.applyScale.Font = Enum.Font.GothamBold
    B.applyScale.BorderSizePixel = 0
    B.applyScale.Active = true
    Instance.new("UICorner", B.applyScale).CornerRadius = UDim.new(0, 6)

    B.restoreSelected = Instance.new("TextButton", scaleBtnRow)
    B.restoreSelected.Size = UDim2.new(0.31, 0, 1, 0)
    B.restoreSelected.Position = UDim2.new(0.345, 0, 0, 0)
    B.restoreSelected.BackgroundColor3 = UIF.Theme.CardBg
    B.restoreSelected.Text = "🔄 คืนค่าชิ้นนี้"
    B.restoreSelected.TextColor3 = UIF.Theme.Text
    B.restoreSelected.TextSize = 10
    B.restoreSelected.Font = Enum.Font.GothamBold
    B.restoreSelected.BorderSizePixel = 0
    B.restoreSelected.Active = true
    Instance.new("UICorner", B.restoreSelected).CornerRadius = UDim.new(0, 6)
    local rstStroke = Instance.new("UIStroke", B.restoreSelected)
    rstStroke.Color = UIF.Theme.CardBorder
    rstStroke.Thickness = 1

    B.restoreAllScaled = Instance.new("TextButton", scaleBtnRow)
    B.restoreAllScaled.Size = UDim2.new(0.31, 0, 1, 0)
    B.restoreAllScaled.Position = UDim2.new(0.69, 0, 0, 0)
    B.restoreAllScaled.BackgroundColor3 = UIF.Theme.DangerBg
    B.restoreAllScaled.Text = "🗑️ คืนค่าทั้งหมด"
    B.restoreAllScaled.TextColor3 = UIF.Theme.AccentRed
    B.restoreAllScaled.TextSize = 10
    B.restoreAllScaled.Font = Enum.Font.GothamBold
    B.restoreAllScaled.BorderSizePixel = 0
    B.restoreAllScaled.Active = true
    Instance.new("UICorner", B.restoreAllScaled).CornerRadius = UDim.new(0, 6)
    local rstAllStroke = Instance.new("UIStroke", B.restoreAllScaled)
    rstAllStroke.Color = UIF.Theme.AccentRed
    rstAllStroke.Thickness = 1

    registerCard(B.applyScale, "apply scale ขยายทันที")
    registerCard(B.restoreSelected, "restore selected คืนค่าชิ้นนี้")
    registerCard(B.restoreAllScaled, "restore all scaled คืนค่าทั้งหมด")

    UIF.sectionHeader(pageWorld, "ระบบ God Mode (ป้องกันตาย)", "💚")
    local scanLabel = Instance.new("TextLabel", pageWorld)
    scanLabel.Size = UDim2.new(1, 0, 0, 20)
    scanLabel.BackgroundTransparency = 1
    scanLabel.Text = "🔍 System Detected: รอข้อมูล..."
    scanLabel.TextColor3 = UIF.Theme.TextDim
    scanLabel.TextSize = 11
    scanLabel.Font = Enum.Font.Gotham
    scanLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    if not UI.labels then UI.labels = {} end
    UI.labels.scanResult = scanLabel

    B.godMode = UIF.button(pageWorld, { Text = "💚 God Mode: ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.godMode, "god mode godmode ไม่ตาย กันตาย hp เลือด")

    B.godModeStyle = UIF.button(pageWorld, { Text = "🔄 โหมด God: Regen (คลิกสลับ)", Bg = UIF.Theme.CardBg })
    registerCard(B.godModeStyle, "god mode style regen lock hook โหมดgod")

    UIF.sectionHeader(pageWorld, "ระบบป้องกันดาเมจ & เก็บของอัตโนมัติ", "🛡️")

    B.antiFall = UIF.button(pageWorld, { Text = "🛡️ กันดาเมจตกที่สูง (Anti-Fall): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.antiFall, "antifall anti fall กันตก ดาเมจตก ตกตึก ไม่ตาย")

    B.autoLoot = UIF.button(pageWorld, { Text = "🧲 ดูดไอเทม/ออโต้เก็บของ (Auto Loot): ปิด", Bg = UIF.Theme.CardBg })
    registerCard(B.autoLoot, "autoloot auto loot ดูดของ เก็บของ ดูดปืน loot item")

    S.lootRadius = UIF.sliderCard(pageWorld, { Title = "ระยะดูดไอเทม: 30 studs", Progress = 0.22, Color = UIF.Theme.AccentBlue, Icon = "🧲", Value = "30 studs" })
    registerCard(S.lootRadius.card, "loot radius ระยะดูดของ")

    UIF.sectionHeader(pageWorld, "ระบบจำลองปิง / เน็ตแลค (Fake Lag & Desync)", "⚡")

    B.fakeLag = UIF.button(pageWorld, { Text = State.FakeLagEnabled and "⚡ จำลองปิง/เน็ตแลค (Fake Lag): เปิด" or "⚡ จำลองปิง/เน็ตแลค (Fake Lag): ปิด", Bg = State.FakeLagEnabled and UIF.Theme.AccentGreen or UIF.Theme.CardBg, TextColor3 = State.FakeLagEnabled and UIF.Theme.TextDark or UIF.Theme.Text })
    B.fakeLag.Activated:Connect(function() if env.World and env.World.toggleFakeLag then env.World.toggleFakeLag() end end)
    registerCard(B.fakeLag, "fake lag fakelag ปิงปลอม แลคปลอม desync วาร์ป")

    HK.fakeLag = UIF.hotkeyCard(pageWorld, { Text = "⚡ คีย์ลัด Burst Lag (กดค้าง/สลับ)", Bind = "FakeLag", Icon = "⚡", Desc = "กดปุ่มลัดค้างเพื่อแลคชั่วขณะให้คนอื่นยิงไม่โดน" })
    registerCard(HK.fakeLag.card, "fakelag hotkey คีย์ลัด ปิงปลอม burst lag")

    S.fakeLagLimit = UIF.sliderCard(pageWorld, { Title = "ความหน่วง Fake Lag: 0.30 s", Progress = 0.3, Color = UIF.Theme.AccentYellow, Icon = "⏱️", Value = "0.30 s" })
    registerCard(S.fakeLagLimit.card, "fakelag delay limit ความหน่วง ปิงปลอม")

    local function updateFakeLagSlider(input)
        local sizeX = math.max(S.fakeLagLimit.frame.AbsoluteSize.X, 1)
        local relativeX = math.clamp(input.Position.X - S.fakeLagLimit.frame.AbsolutePosition.X, 0, sizeX)
        local percentage = math.clamp(relativeX / sizeX, 0, 1)
        local limitVal = math.floor((0.1 + (0.8 - 0.1) * percentage) * 100) / 100
        State.FakeLagLimit = limitVal
        S.fakeLagLimit.fill.Size = UDim2.new(percentage, 0, 1, 0)
        S.fakeLagLimit.text.Text = string.format("%.2f s", limitVal)
        S.fakeLagLimit.title.Text = "ความหน่วง Fake Lag: " .. string.format("%.2f s", limitVal)
    end
    S.fakeLagLimit.btn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then State.draggingFakeLag = true; updateFakeLagSlider(input) end end)
    Cleanup.conn(UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then State.draggingFakeLag = false end end))
    Cleanup.conn(UserInputService.InputChanged:Connect(function(input) if State.draggingFakeLag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateFakeLagSlider(input) end end))

    UIF.sectionHeader(pageWorld, "ระบบวาร์ปติดตามเป้าหมาย (Smart Target Warp)", "🚀")

    HK.warp = UIF.hotkeyCard(pageWorld, { Text = "⚡ คีย์ลัดวาร์ปไปหาเป้าหมายที่ล็อค", Bind = "Warp", Icon = "⚡", Desc = "กดปุ่มลัดเพื่อวาร์ปไปหาเป้าหมายที่กำลังล็อคทันที" })
    registerCard(HK.warp.card, "warp teleport วาร์ป วาป เทเลพอร์ต ไปหาเป้าหมาย hotkey z")

    B.warpTargetSelect = UIF.button(pageWorld, { Text = "🎯 เลือกเป้าหมาย: (คลิกเพื่อเปิดดูรายชื่อทั้งหมด)", Bg = UIF.Theme.CardBg })
    registerCard(B.warpTargetSelect, "warp target select เลือกเป้าหมาย รายชื่อ บอท คน")

    local targetListFrame = Instance.new("Frame", pageWorld)
    targetListFrame.Size = UDim2.new(1, 0, 0, 160)
    targetListFrame.BackgroundColor3 = UIF.Theme.Sidebar
    targetListFrame.BorderSizePixel = 0
    targetListFrame.Visible = false
    targetListFrame.Active = true
    Instance.new("UICorner", targetListFrame).CornerRadius = UDim.new(0, 8)
    local tlfStroke = Instance.new("UIStroke", targetListFrame)
    tlfStroke.Color = UIF.Theme.CardBorder
    tlfStroke.Thickness = 1

    local listHeader = Instance.new("Frame", targetListFrame)
    listHeader.Size = UDim2.new(1, 0, 0, 26)
    listHeader.BackgroundTransparency = 1

    local listTitle = Instance.new("TextLabel", listHeader)
    listTitle.Size = UDim2.new(1, -75, 1, 0)
    listTitle.Position = UDim2.new(0, 8, 0, 0)
    listTitle.BackgroundTransparency = 1
    listTitle.Text = "📋 รายชื่อศัตรูในห้อง (คลิกเลือก)"
    listTitle.TextColor3 = UIF.Theme.TextDim
    listTitle.TextSize = 11
    listTitle.Font = Enum.Font.GothamBold
    listTitle.TextXAlignment = Enum.TextXAlignment.Left

    local refreshBtn = Instance.new("TextButton", listHeader)
    refreshBtn.Size = UDim2.new(0, 65, 0, 20)
    refreshBtn.Position = UDim2.new(1, -72, 0, 3)
    refreshBtn.BackgroundColor3 = UIF.Theme.CardBg
    refreshBtn.Text = "🔄 รีเฟรช"
    refreshBtn.TextColor3 = UIF.Theme.AccentBlue
    refreshBtn.TextSize = 10
    refreshBtn.Font = Enum.Font.GothamBold
    refreshBtn.BorderSizePixel = 0
    refreshBtn.Active = true
    Instance.new("UICorner", refreshBtn).CornerRadius = UDim.new(0, 4)

    local scrollList = Instance.new("ScrollingFrame", targetListFrame)
    scrollList.Size = UDim2.new(1, -8, 1, -32)
    scrollList.Position = UDim2.new(0, 4, 0, 28)
    scrollList.BackgroundTransparency = 1
    scrollList.BorderSizePixel = 0
    scrollList.ScrollBarThickness = 4
    scrollList.ScrollBarImageColor3 = UIF.Theme.AccentBlue
    scrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollList.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollList.Active = true

    local listLayout = Instance.new("UIListLayout", scrollList)
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local function populateTargetList()
        for _, child in ipairs(scrollList:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
        end

        local pool = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local isAlive = env.Scanner and env.Scanner.isAlive(p)
                if isAlive then pool[#pool + 1] = p end
            end
        end
        if State.TargetBotsEnabled and env.Scanner and env.Scanner.getNPCs then
            local npcs = env.Scanner.getNPCs()
            for _, npc in ipairs(npcs) do
                if not env.isSameTeam or not env.isSameTeam(npc) then
                    local isAlive = env.Scanner.isAlive(npc)
                    if isAlive then pool[#pool + 1] = npc end
                end
            end
        end

        if #pool == 0 then
            local emptyLbl = Instance.new("TextLabel", scrollList)
            emptyLbl.Size = UDim2.new(1, 0, 0, 30)
            emptyLbl.BackgroundTransparency = 1
            emptyLbl.Text = "⚠️ ไม่พบเป้าหมายศัตรูในห้องขณะนี้"
            emptyLbl.TextColor3 = UIF.Theme.TextDim
            emptyLbl.TextSize = 11
            emptyLbl.Font = Enum.Font.Gotham
            return
        end

        local cam = env.Camera or workspace.CurrentCamera
        for _, target in ipairs(pool) do
            local tName = env.Scanner and env.Scanner.getName(target) or "Target"
            local isBot = (type(target) == "table" and target.isBot) or (typeof(target) == "Instance" and target:IsA("Model"))
            local isFriend = (not isBot) and target and env.isSameTeam and env.isSameTeam(target)
            
            if isFriend then tName = "[เพื่อน] 🫂 " .. tName end
            
            local hrp = env.Scanner and env.Scanner.getRootPart(target)
            local dist = hrp and cam and math.floor((cam.CFrame.Position - hrp.Position).Magnitude) or 0
            local hp = 100
            if env.Scanner and env.Scanner.getHealth then hp = env.Scanner.getHealth(target) end

            local itemBtn = Instance.new("TextButton", scrollList)
            itemBtn.Size = UDim2.new(1, 0, 0, 30)
            local isSelected = (State.selectedWarpTarget == target)
            itemBtn.BackgroundColor3 = isSelected and UIF.Theme.AccentGreen or UIF.Theme.CardBg
            itemBtn.BorderSizePixel = 0
            itemBtn.Text = ""
            itemBtn.AutoButtonColor = false
            itemBtn.Active = true
            Instance.new("UICorner", itemBtn).CornerRadius = UDim.new(0, 6)

            local itemStroke = Instance.new("UIStroke", itemBtn)
            itemStroke.Color = isSelected and UIF.Theme.AccentGreen or UIF.Theme.CardBorder
            itemStroke.Thickness = 1

            local itemIcon = Instance.new("TextLabel", itemBtn)
            itemIcon.Size = UDim2.new(0, 24, 1, 0)
            itemIcon.Position = UDim2.new(0, 6, 0, 0)
            itemIcon.BackgroundTransparency = 1
            itemIcon.Text = isBot and "🤖" or "👤"
            itemIcon.TextSize = 13
            itemIcon.Font = Enum.Font.Gotham

            local itemName = Instance.new("TextLabel", itemBtn)
            itemName.Size = UDim2.new(0.50, 0, 1, 0)
            itemName.Position = UDim2.new(0, 32, 0, 0)
            itemName.BackgroundTransparency = 1
            itemName.Text = tostring(tName)
            itemName.TextColor3 = isSelected and UIF.Theme.TextDark or UIF.Theme.Text
            itemName.TextSize = 11
            itemName.Font = Enum.Font.GothamBold
            itemName.TextXAlignment = Enum.TextXAlignment.Left

            local itemInfo = Instance.new("TextLabel", itemBtn)
            itemInfo.Size = UDim2.new(0.42, 0, 1, 0)
            itemInfo.Position = UDim2.new(0.56, 0, 0, 0)
            itemInfo.BackgroundTransparency = 1
            itemInfo.Text = string.format("❤️ %d HP | 📏 %dm", math.floor(hp), dist)
            itemInfo.TextColor3 = isSelected and UIF.Theme.TextDark or UIF.Theme.TextDim
            itemInfo.TextSize = 10
            itemInfo.Font = Enum.Font.Gotham
            itemInfo.TextXAlignment = Enum.TextXAlignment.Right

            itemBtn.Activated:Connect(function()
                State.selectedWarpTarget = target
                B.warpTargetSelect.Text = string.format("🎯 เป้าหมาย: %s (%s)", tostring(tName), isBot and "BOT" or "PLAYER")
                B.warpTargetSelect.TextColor3 = UIF.Theme.AccentGreen
                targetListFrame.Visible = false
                UI.showNotif("🎯 เลือกเป้าหมาย: " .. tostring(tName), 1.5)
            end)
        end
    end

    refreshBtn.Activated:Connect(populateTargetList)

    B.warpTargetSelect.Activated:Connect(function()
        targetListFrame.Visible = not targetListFrame.Visible
        if targetListFrame.Visible then populateTargetList() end
    end)

    B.warpOffset = UIF.button(pageWorld, { Text = "📍 ตำแหน่งวาร์ป: ด้านหลัง (Behind) (คลิกสลับ)", Bg = UIF.Theme.CardBg })
    registerCard(B.warpOffset, "warp offset ตำแหน่งวาร์ป ด้านหลัง ด้านบน ด้านหน้า")

    local warpActionRow = Instance.new("Frame", pageWorld)
    warpActionRow.Size = UDim2.new(1, 0, 0, 36)
    warpActionRow.BackgroundTransparency = 1

    local warpNowBtn = Instance.new("TextButton", warpActionRow)
    warpNowBtn.Size = UDim2.new(0.58, 0, 1, 0)
    warpNowBtn.Position = UDim2.new(0, 0, 0, 0)
    warpNowBtn.BackgroundColor3 = UIF.Theme.CardBg
    warpNowBtn.Text = "🚀 วาร์ปไปหาเป้าหมายทันที"
    warpNowBtn.TextColor3 = UIF.Theme.AccentGreen
    warpNowBtn.TextSize = 11
    warpNowBtn.Font = Enum.Font.GothamBold
    warpNowBtn.BorderSizePixel = 0
    warpNowBtn.Active = true
    Instance.new("UICorner", warpNowBtn).CornerRadius = UDim.new(0, 6)
    local wnStroke = Instance.new("UIStroke", warpNowBtn)
    wnStroke.Color = UIF.Theme.AccentGreen
    wnStroke.Thickness = 1

    local lockSelectedBtn = Instance.new("TextButton", warpActionRow)
    lockSelectedBtn.Size = UDim2.new(0.38, 0, 1, 0)
    lockSelectedBtn.Position = UDim2.new(0.62, 0, 0, 0)
    lockSelectedBtn.BackgroundColor3 = UIF.Theme.CardBg
    lockSelectedBtn.Text = "🎯 ล็อคคนนี้"
    lockSelectedBtn.TextColor3 = UIF.Theme.AccentYellow
    lockSelectedBtn.TextSize = 11
    lockSelectedBtn.Font = Enum.Font.GothamBold
    lockSelectedBtn.BorderSizePixel = 0
    lockSelectedBtn.Active = true
    Instance.new("UICorner", lockSelectedBtn).CornerRadius = UDim.new(0, 6)
    local lsStroke = Instance.new("UIStroke", lockSelectedBtn)
    lsStroke.Color = UIF.Theme.CardBorder
    lsStroke.Thickness = 1

    registerCard(warpNowBtn, "warp now วาร์ปทันที ไปหาเป้าหมาย")
    registerCard(lockSelectedBtn, "lock selected ล็อคเป้าหมายคนนี้ hardlock")

    B.warpOffset.Activated:Connect(function()
        if State.WarpOffset == "Behind" then
            State.WarpOffset = "Above"
            B.warpOffset.Text = "📍 ตำแหน่งวาร์ป: ด้านบนหัว (Above) (คลิกสลับ)"
        elseif State.WarpOffset == "Above" then
            State.WarpOffset = "Front"
            B.warpOffset.Text = "📍 ตำแหน่งวาร์ป: ด้านหน้า (Front) (คลิกสลับ)"
        else
            State.WarpOffset = "Behind"
            B.warpOffset.Text = "📍 ตำแหน่งวาร์ป: ด้านหลัง (Behind) (คลิกสลับ)"
        end
    end)

    warpNowBtn.Activated:Connect(function()
        if env.World and env.World.teleportToTarget then
            local target = State.selectedWarpTarget or State.hardLockedPlayer or State.currentTarget
            if target then
                env.World.teleportToTarget(target)
            else
                env.World.warpToLockedTarget()
            end
        end
    end)

    lockSelectedBtn.Activated:Connect(function()
        if State.selectedWarpTarget and env.Scanner and env.Scanner.isAlive(State.selectedWarpTarget) then
            State.hardLockedPlayer = State.selectedWarpTarget
            local tName = env.Scanner and env.Scanner.getName(State.selectedWarpTarget) or "เป้าหมาย"
            if B.hardLock then
                B.hardLock.Text = "🔒 ล็อคคนนี้ (Hard Lock): " .. tostring(tName)
                B.hardLock.BackgroundColor3 = UIF.Theme.AccentPink
                B.hardLock.TextColor3 = UIF.Theme.Text
            end
            UI.showNotif("🎯 สั่ง Hard Lock ไปที่: " .. tostring(tName), 2)
        else
            UI.showNotif("⚠️ กรุณาคลิกเลือกเป้าหมายก่อน", 2)
        end
    end)

    UIF.sectionHeader(pageWorld, "จุดเซฟ (Waypoint)", "📍")
    local waypointActionRow = Instance.new("Frame", pageWorld)
    waypointActionRow.Size = UDim2.new(1, 0, 0, 36)
    waypointActionRow.BackgroundTransparency = 1

    local savePointBtn = Instance.new("TextButton", waypointActionRow)
    savePointBtn.Size = UDim2.new(0.48, 0, 1, 0)
    savePointBtn.Position = UDim2.new(0, 0, 0, 0)
    savePointBtn.BackgroundColor3 = UIF.Theme.CardBg
    savePointBtn.Text = "💾 เซฟจุดปัจจุบัน"
    savePointBtn.TextColor3 = UIF.Theme.Text
    savePointBtn.TextSize = 11
    savePointBtn.Font = Enum.Font.GothamBold
    savePointBtn.BorderSizePixel = 0
    savePointBtn.Active = true
    Instance.new("UICorner", savePointBtn).CornerRadius = UDim.new(0, 6)
    local spStroke = Instance.new("UIStroke", savePointBtn)
    spStroke.Color = UIF.Theme.CardBorder
    spStroke.Thickness = 1

    local loadPointBtn = Instance.new("TextButton", waypointActionRow)
    loadPointBtn.Size = UDim2.new(0.48, 0, 1, 0)
    loadPointBtn.Position = UDim2.new(0.52, 0, 0, 0)
    loadPointBtn.BackgroundColor3 = UIF.Theme.CardBg
    loadPointBtn.Text = "🚀 วาร์ปกลับจุดเซฟ"
    loadPointBtn.TextColor3 = UIF.Theme.AccentBlue
    loadPointBtn.TextSize = 11
    loadPointBtn.Font = Enum.Font.GothamBold
    loadPointBtn.BorderSizePixel = 0
    loadPointBtn.Active = true
    Instance.new("UICorner", loadPointBtn).CornerRadius = UDim.new(0, 6)
    local lpStroke = Instance.new("UIStroke", loadPointBtn)
    lpStroke.Color = UIF.Theme.AccentBlue
    lpStroke.Thickness = 1

    registerCard(savePointBtn, "save point savepoint เซฟจุด จุดเซฟ way point waypoint")
    registerCard(loadPointBtn, "load point loadpoint โหลดจุด วาร์ปกลับ วาปกลับ จุดเซฟ waypoint")

    savePointBtn.Activated:Connect(function() if env.World and env.World.saveWaypoint then env.World.saveWaypoint() end end)
    loadPointBtn.Activated:Connect(function() if env.World and env.World.tpToWaypoint then env.World.tpToWaypoint() end end)

    -- ========================================================================
    -- 4. TEAM RADAR TAB
    -- ========================================================================
    UIF.sectionHeader(pageTeam, "ระบบป้องกันการล็อคเพื่อน & ทีม", "🛡️")

    B.friendCheck = UIF.button(pageTeam, { Text = State.FriendCheckEnabled and "👥 ไม่ล็อคเพื่อนใน Roblox: เปิด" or "👥 ไม่ล็อคเพื่อนใน Roblox: ปิด", Bg = State.FriendCheckEnabled and UIF.Theme.AccentGreen or UIF.Theme.CardBg, TextColor3 = State.FriendCheckEnabled and UIF.Theme.TextDark or UIF.Theme.Text })
    B.friendCheck.Activated:Connect(function()
        State.FriendCheckEnabled = not State.FriendCheckEnabled
        if State.FriendCheckEnabled then
            B.friendCheck.Text = "👥 ไม่ล็อคเพื่อนใน Roblox: เปิด"; B.friendCheck.BackgroundColor3 = UIF.Theme.AccentGreen; B.friendCheck.TextColor3 = UIF.Theme.TextDark
            UI.showNotif("👥 เปิดระบบข้ามเพื่อนใน Roblox", 2)
        else
            B.friendCheck.Text = "👥 ไม่ล็อคเพื่อนใน Roblox: ปิด"; B.friendCheck.BackgroundColor3 = UIF.Theme.CardBg; B.friendCheck.TextColor3 = UIF.Theme.Text
            UI.showNotif("👥 ปิดระบบข้ามเพื่อนใน Roblox", 2)
        end
    end)
    registerCard(B.friendCheck, "friend check เพื่อน roblox friend ไม่ล็อคเพื่อน")

    B.teamCheck = UIF.button(pageTeam, { Text = State.TeamCheckEnabled and "🛡️ ไม่ล็อคทีมในเกม: เปิด" or "🛡️ ไม่ล็อคทีมในเกม: ปิด", Bg = State.TeamCheckEnabled and UIF.Theme.AccentGreen or UIF.Theme.CardBg, TextColor3 = State.TeamCheckEnabled and UIF.Theme.TextDark or UIF.Theme.Text })
    B.teamCheck.Activated:Connect(function()
        State.TeamCheckEnabled = not State.TeamCheckEnabled
        if State.TeamCheckEnabled then
            B.teamCheck.Text = "🛡️ ไม่ล็อคทีมในเกม: เปิด"; B.teamCheck.BackgroundColor3 = UIF.Theme.AccentGreen; B.teamCheck.TextColor3 = UIF.Theme.TextDark
            Status.Text = "● ข้ามเพื่อนร่วมทีม"; Status.TextColor3 = UIF.Theme.AccentGreen
            UI.showNotif("🛡️ เปิดระบบเช็คทีมในเกมแล้ว", 2)
        else
            B.teamCheck.Text = "🛡️ ไม่ล็อคทีมในเกม: ปิด"; B.teamCheck.BackgroundColor3 = UIF.Theme.CardBg; B.teamCheck.TextColor3 = UIF.Theme.Text
            Status.Text = "● ล็อคทุกคนในแมพ"; Status.TextColor3 = UIF.Theme.AccentYellow
            UI.showNotif("🛡️ ปิดระบบเช็คทีมในเกม", 2)
        end
    end)
    registerCard(B.teamCheck, "team check ทีม ตรวจสอบทีม ไม่ล็อคทีม")

    B.scanNearby = UIF.button(pageTeam, { Text = "📡 สแกนรอบตัว (100m) [Num+]", Bg = UIF.Theme.AccentBlue, TextColor3 = Color3.fromRGB(255, 255, 255) })
    B.scanNearby.Activated:Connect(function() if UI.scanNearby then UI.scanNearby() end end)
    registerCard(B.scanNearby, "scan scan nearby สแกนรอบตัว เรดาร์")

    B.addFriendly = UIF.button(pageTeam, { Text = "➕ เพิ่มผู้เล่นใกล้เมาส์เป็นเพื่อน", Bg = UIF.Theme.CardBg })
    B.addFriendly.Activated:Connect(function()
        local closest = nil; local shortest = math.huge; local cam = workspace.CurrentCamera
        for _, p in pairs(game:GetService("Players"):GetPlayers()) do
            if p ~= game:GetService("Players").LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local pos, onScreen = cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if onScreen then
                    local mousePos = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < shortest then closest = p; shortest = dist end
                end
            end
        end
        if closest then
            env.FriendlyPlayers[closest.Name] = true
            UI.showNotif("➕ เพิ่ม " .. closest.Name .. " เข้าทีมแล้ว", 2)
            if UI.refreshTeamList then UI.refreshTeamList() end
        else
            UI.showNotif("❌ ไม่พบเป้าหมายใกล้เคอร์เซอร์", 2)
        end
    end)
    registerCard(B.addFriendly, "add friend เพิ่มเพื่อน เพิ่มทีม")

    B.clearFriendly = UIF.button(pageTeam, { Text = "🗑️ ล้างรายชื่อทีมทั้งหมด [Num-]", Bg = UIF.Theme.CardBg, TextColor3 = UIF.Theme.AccentRed })
    B.clearFriendly.Activated:Connect(function()
        for k in pairs(env.FriendlyPlayers) do env.FriendlyPlayers[k] = nil end
        UI.showNotif("🗑️ ล้างรายชื่อทีมทั้งหมดแล้ว", 2)
        if UI.refreshTeamList then UI.refreshTeamList() end
    end)
    registerCard(B.clearFriendly, "clear team ล้างทีม ลบทีม")

    B.debugTeam = UIF.button(pageTeam, { Text = "🔍 ตรวจสอบข้อมูลทีมในเกม (Team Debugger)", Bg = UIF.Theme.CardBg, TextColor3 = UIF.Theme.AccentPurple })
    B.debugTeam.Activated:Connect(function()
        local lp = game:GetService("Players").LocalPlayer
        local myTeamName = lp.Team and lp.Team.Name or (lp.TeamColor and lp.TeamColor.Name) or "ไม่มี (Neutral)"
        local closest = nil; local shortest = math.huge
        local myPos = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") and lp.Character.HumanoidRootPart.Position
        if myPos then
            for _, p in pairs(game:GetService("Players"):GetPlayers()) do
                if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local d = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
                    if d < shortest then shortest = d; closest = p end
                end
            end
        end
        if closest then
            local theirTeamName = closest.Team and closest.Team.Name or (closest.TeamColor and closest.TeamColor.Name) or "ไม่มี"
            local isTeam = env.isSameTeam and env.isSameTeam(closest)
            local resultMsg = string.format("คุณ: [%s] | %s: [%s] -> %s", myTeamName, closest.DisplayName, theirTeamName, isTeam and "✅ ทีมเดียวกัน (ไม่ล็อค)" or "❌ ศัตรู (ล็อค)")
            UI.showNotif(resultMsg, 4)
            if env.Logger then env.Logger.info("TeamDebug", "Check", resultMsg) end
        else
            UI.showNotif("คุณ: ทีม [" .. myTeamName .. "] (ไม่พบผู้เล่นอื่นใกล้ๆ)", 3)
        end
    end)
    registerCard(B.debugTeam, "debug team เช็คทีม ดีบักทีม ตรวจสอบทีม")

    UIF.sectionHeader(pageTeam, "รายชื่อเพื่อนในทีมปัจจุบัน", "📋")
    local TeamCard = Instance.new("Frame", pageTeam)
    TeamCard.Size = UDim2.new(1, 0, 0, 140)
    TeamCard.BackgroundColor3 = UIF.Theme.CardBg
    TeamCard.BorderSizePixel = 0
    TeamCard.Active = true
    Instance.new("UICorner", TeamCard).CornerRadius = UDim.new(0, 8)
    local teamStroke = Instance.new("UIStroke", TeamCard)
    teamStroke.Color = UIF.Theme.CardBorder
    teamStroke.Thickness = 1

    local TeamScroll = Instance.new("ScrollingFrame", TeamCard)
    TeamScroll.Size = UDim2.new(1, -12, 1, -12)
    TeamScroll.Position = UDim2.new(0, 6, 0, 6)
    TeamScroll.BackgroundTransparency = 1
    TeamScroll.BorderSizePixel = 0
    TeamScroll.ScrollBarThickness = 3
    TeamScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    TeamScroll.Active = true
    local teamListLayout = Instance.new("UIListLayout", TeamScroll)
    teamListLayout.Padding = UDim.new(0, 4)

    function UI.refreshTeamList()
        for _, child in pairs(TeamScroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextLabel") then child:Destroy() end
        end
        local count = 0
        for name, _ in pairs(env.FriendlyPlayers) do
            count = count + 1
            local item = Instance.new("Frame", TeamScroll)
            item.Size = UDim2.new(1, 0, 0, 28)
            item.BackgroundColor3 = UIF.Theme.Sidebar
            item.BorderSizePixel = 0
            Instance.new("UICorner", item).CornerRadius = UDim.new(0, 6)

            local pName = Instance.new("TextLabel", item)
            pName.Size = UDim2.new(1, -40, 1, 0)
            pName.Position = UDim2.new(0, 10, 0, 0)
            pName.BackgroundTransparency = 1
            pName.Text = "👤 " .. name
            pName.TextColor3 = UIF.Theme.Text
            pName.TextSize = 11
            pName.Font = Enum.Font.Gotham
            pName.TextXAlignment = Enum.TextXAlignment.Left

            local removeBtn = Instance.new("TextButton", item)
            removeBtn.Size = UDim2.new(0, 22, 0, 22)
            removeBtn.Position = UDim2.new(1, -26, 0.5, -11)
            removeBtn.BackgroundColor3 = UIF.Theme.DangerBg
            removeBtn.Text = "✕"
            removeBtn.TextColor3 = UIF.Theme.AccentRed
            removeBtn.TextSize = 10
            removeBtn.Font = Enum.Font.GothamBold
            removeBtn.Active = true
            Instance.new("UICorner", removeBtn).CornerRadius = UDim.new(0, 4)
            local rmStroke = Instance.new("UIStroke", removeBtn)
            rmStroke.Color = UIF.Theme.AccentRed
            rmStroke.Thickness = 1

            removeBtn.Activated:Connect(function()
                env.FriendlyPlayers[name] = nil
                UI.refreshTeamList()
            end)
        end
        if count == 0 then
            local empty = Instance.new("TextLabel", TeamScroll)
            empty.Size = UDim2.new(1, 0, 0, 35)
            empty.BackgroundTransparency = 1
            empty.Text = "(ยังไม่มีรายชื่อเพื่อนในทีม - กด Num+ เพื่อสแกน)"
            empty.TextColor3 = UIF.Theme.TextDim
            empty.TextSize = 11
            empty.Font = Enum.Font.Gotham
        end
    end
    B.listFriendly = Instance.new("TextButton")
    B.listFriendly.Activated:Connect(function() UI.refreshTeamList() end)

    -- ========================================================================
    -- 5. HOTKEYS TAB
    -- ========================================================================
    UIF.sectionHeader(pageHotkeys, "รายการคีย์ลัดทั้งหมดในระบบ", "⌨️")
    local infoCard = Instance.new("Frame", pageHotkeys)
    infoCard.Size = UDim2.new(1, 0, 0, 42)
    infoCard.BackgroundColor3 = UIF.Theme.CardBg
    infoCard.BorderSizePixel = 0
    Instance.new("UICorner", infoCard).CornerRadius = UDim.new(0, 8)
    local infoStroke = Instance.new("UIStroke", infoCard)
    infoStroke.Color = UIF.Theme.AccentBlue
    infoStroke.Thickness = 1

    local infoLbl = Instance.new("TextLabel", infoCard)
    infoLbl.Size = UDim2.new(1, -16, 1, 0)
    infoLbl.Position = UDim2.new(0, 8, 0, 0)
    infoLbl.BackgroundTransparency = 1
    infoLbl.Text = "💡 คลิกที่ปุ่มสีเหลืองเพื่อ Rebind คีย์ลัดใหม่ (กด Escape เพื่อยกเลิก)"
    infoLbl.TextColor3 = UIF.Theme.AccentBlue
    infoLbl.TextSize = 11
    infoLbl.Font = Enum.Font.GothamBold
    infoLbl.TextXAlignment = Enum.TextXAlignment.Left

    local hkAimOverview = UIF.hotkeyCard(pageHotkeys, { Text = "Aimbot Toggle", Desc = "เปิด/ปิด เล็งเป้าอัตโนมัติ", Bind = "Aim", Icon = "🎯" })
    local hkLockOverview = UIF.hotkeyCard(pageHotkeys, { Text = "Hard Lock Toggle", Desc = "ล็อคเป้าหมายเจาะจง", Bind = "Lock", Icon = "🔒" })
    local hkPoleOverview = UIF.hotkeyCard(pageHotkeys, { Text = "Pole Spawn", Desc = "สร้างเสาปีน ณ จุดที่เมาส์ชี้", Bind = "Pole", Icon = "🧱" })
    local hkDelOverview = UIF.hotkeyCard(pageHotkeys, { Text = "Delete Mode", Desc = "เปิดโหมดลบของ (แล้วกด M3 เพื่อลบ)", Bind = "Del", Icon = "🖱️" })
    local hkScalerOverview = UIF.hotkeyCard(pageHotkeys, { Text = "Object Scaler Mode", Desc = "เปิดโหมดเลือกปรับขนาด Object ในฉาก (กด H)", Bind = "Scaler", Icon = "📐" })
    local hkScanOverview = UIF.hotkeyCard(pageHotkeys, { Text = "Scan Nearby (100m)", Desc = "สแกนผู้เล่นในระยะ 100m", Bind = "ScanNearby", Icon = "📡" })
    local hkClearOverview = UIF.hotkeyCard(pageHotkeys, { Text = "Clear Team List", Desc = "ล้างรายชื่อเพื่อนในทีมทั้งหมด", Bind = "ClearTeam", Icon = "🗑️" })

    -- ========================================================================
    -- 6. MASTER & SYSTEM TAB
    -- ========================================================================
    UIF.sectionHeader(pageMaster, "การควบคุมระบบรวม & ออก", "⚙️")

    B.all = UIF.button(pageMaster, { Text = "⚡ เปิดทั้งหมด 5 อย่าง (Master Enable)", Bg = UIF.Theme.AccentGreen, TextColor3 = UIF.Theme.TextDark })
    registerCard(B.all, "master all เปิดทั้งหมด 5 อย่าง")

    B.exit = UIF.button(pageMaster, { Text = "❌ ปิดสคริปต์ (Exit & Clear All)", Bg = UIF.Theme.DangerBg, TextColor3 = UIF.Theme.AccentRed, HoverBorder = UIF.Theme.AccentRed })
    registerCard(B.exit, "exit close ปิดสคริปต์ ล้างระบบ")

    UIF.sectionHeader(pageMaster, "ระบบจัดการโปรไฟล์การตั้งค่า (Config & Presets)", "💾")
    local configRow = Instance.new("Frame", pageMaster)
    configRow.Size = UDim2.new(1, 0, 0, 36)
    configRow.BackgroundTransparency = 1

    local saveCfgBtn = Instance.new("TextButton", configRow)
    saveCfgBtn.Size = UDim2.new(0.48, 0, 1, 0)
    saveCfgBtn.Position = UDim2.new(0, 0, 0, 0)
    saveCfgBtn.BackgroundColor3 = UIF.Theme.CardBg
    saveCfgBtn.Text = "💾 บันทึก Config"
    saveCfgBtn.TextColor3 = UIF.Theme.AccentBlue
    saveCfgBtn.TextSize = 11
    saveCfgBtn.Font = Enum.Font.GothamBold
    saveCfgBtn.BorderSizePixel = 0
    saveCfgBtn.Active = true
    Instance.new("UICorner", saveCfgBtn).CornerRadius = UDim.new(0, 6)
    local saveStroke = Instance.new("UIStroke", saveCfgBtn)
    saveStroke.Color = UIF.Theme.CardBorder
    saveStroke.Thickness = 1

    local loadCfgBtn = Instance.new("TextButton", configRow)
    loadCfgBtn.Size = UDim2.new(0.48, 0, 1, 0)
    loadCfgBtn.Position = UDim2.new(0.52, 0, 0, 0)
    loadCfgBtn.BackgroundColor3 = UIF.Theme.CardBg
    loadCfgBtn.Text = "📂 โหลด Config"
    loadCfgBtn.TextColor3 = UIF.Theme.AccentGreen
    loadCfgBtn.TextSize = 11
    loadCfgBtn.Font = Enum.Font.GothamBold
    loadCfgBtn.BorderSizePixel = 0
    loadCfgBtn.Active = true
    Instance.new("UICorner", loadCfgBtn).CornerRadius = UDim.new(0, 6)
    local loadStroke = Instance.new("UIStroke", loadCfgBtn)
    loadStroke.Color = UIF.Theme.CardBorder
    loadStroke.Thickness = 1

    saveCfgBtn.Activated:Connect(function()
        if env.Config then
            local ok, msg = env.Config.saveToFile("UtilityHub_config.json")
            UI.showNotif(ok and ("💾 บันทึกสำเร็จ: " .. tostring(msg)) or ("❌ " .. tostring(msg)), 3)
        end
    end)
    loadCfgBtn.Activated:Connect(function()
        if env.Config then
            local ok, msg = env.Config.loadFromFile("UtilityHub_config.json")
            UI.showNotif(ok and "📂 " .. tostring(msg) or "❌ " .. tostring(msg), 3)
        end
    end)
    registerCard(saveCfgBtn, "save config เซฟ บันทึก config")
    registerCard(loadCfgBtn, "load config โหลด config")

    local presetRow = Instance.new("Frame", pageMaster)
    presetRow.Size = UDim2.new(1, 0, 0, 36)
    presetRow.BackgroundTransparency = 1

    local legitPresetBtn = Instance.new("TextButton", presetRow)
    legitPresetBtn.Size = UDim2.new(0.23, 0, 1, 0)
    legitPresetBtn.Position = UDim2.new(0, 0, 0, 0)
    legitPresetBtn.BackgroundColor3 = UIF.Theme.CardBg
    legitPresetBtn.Text = "🎯 เนียน (Legit)"
    legitPresetBtn.TextColor3 = UIF.Theme.AccentYellow
    legitPresetBtn.TextSize = 9.5
    legitPresetBtn.Font = Enum.Font.GothamBold
    legitPresetBtn.BorderSizePixel = 0
    legitPresetBtn.Active = true
    Instance.new("UICorner", legitPresetBtn).CornerRadius = UDim.new(0, 6)
    local legitStroke = Instance.new("UIStroke", legitPresetBtn)
    legitStroke.Color = UIF.Theme.CardBorder
    legitStroke.Thickness = 1

    local ragePresetBtn = Instance.new("TextButton", presetRow)
    ragePresetBtn.Size = UDim2.new(0.23, 0, 1, 0)
    ragePresetBtn.Position = UDim2.new(0.255, 0, 0, 0)
    ragePresetBtn.BackgroundColor3 = UIF.Theme.CardBg
    ragePresetBtn.Text = "⚡ โหด (Rage)"
    ragePresetBtn.TextColor3 = UIF.Theme.AccentPink
    ragePresetBtn.TextSize = 9.5
    ragePresetBtn.Font = Enum.Font.GothamBold
    ragePresetBtn.BorderSizePixel = 0
    ragePresetBtn.Active = true
    Instance.new("UICorner", ragePresetBtn).CornerRadius = UDim.new(0, 6)
    local rageStroke = Instance.new("UIStroke", ragePresetBtn)
    rageStroke.Color = UIF.Theme.CardBorder
    rageStroke.Thickness = 1

    local pvePresetBtn = Instance.new("TextButton", presetRow)
    pvePresetBtn.Size = UDim2.new(0.23, 0, 1, 0)
    pvePresetBtn.Position = UDim2.new(0.51, 0, 0, 0)
    pvePresetBtn.BackgroundColor3 = UIF.Theme.CardBg
    pvePresetBtn.Text = "🤖 ล่าบอท (PvE)"
    pvePresetBtn.TextColor3 = UIF.Theme.AccentGreen
    pvePresetBtn.TextSize = 9.5
    pvePresetBtn.Font = Enum.Font.GothamBold
    pvePresetBtn.BorderSizePixel = 0
    pvePresetBtn.Active = true
    Instance.new("UICorner", pvePresetBtn).CornerRadius = UDim.new(0, 6)
    local pveStroke = Instance.new("UIStroke", pvePresetBtn)
    pveStroke.Color = UIF.Theme.CardBorder
    pveStroke.Thickness = 1

    local defaultPresetBtn = Instance.new("TextButton", presetRow)
    defaultPresetBtn.Size = UDim2.new(0.23, 0, 1, 0)
    defaultPresetBtn.Position = UDim2.new(0.765, 0, 0, 0)
    defaultPresetBtn.BackgroundColor3 = UIF.Theme.CardBg
    defaultPresetBtn.Text = "🔄 ค่าเริ่มต้น"
    defaultPresetBtn.TextColor3 = UIF.Theme.TextDim
    defaultPresetBtn.TextSize = 9.5
    defaultPresetBtn.Font = Enum.Font.GothamBold
    defaultPresetBtn.BorderSizePixel = 0
    defaultPresetBtn.Active = true
    Instance.new("UICorner", defaultPresetBtn).CornerRadius = UDim.new(0, 6)
    local defStroke = Instance.new("UIStroke", defaultPresetBtn)
    defStroke.Color = UIF.Theme.CardBorder
    defStroke.Thickness = 1

    legitPresetBtn.Activated:Connect(function() if env.Config then local ok, msg = env.Config.applyPreset("legit"); UI.showNotif(msg, 3) end end)
    ragePresetBtn.Activated:Connect(function() if env.Config then local ok, msg = env.Config.applyPreset("rage"); UI.showNotif(msg, 3) end end)
    pvePresetBtn.Activated:Connect(function() if env.Config then local ok, msg = env.Config.applyPreset("pve"); UI.showNotif(msg, 3) end end)
    defaultPresetBtn.Activated:Connect(function() if env.Config then local ok, msg = env.Config.applyPreset("default"); UI.showNotif(msg, 3) end end)

    registerCard(legitPresetBtn, "preset legit โหมดเนียน")
    registerCard(ragePresetBtn, "preset rage โหมดโหด")
    registerCard(pvePresetBtn, "preset pve bot monster ล่าบอท มอนสเตอร์")
    registerCard(defaultPresetBtn, "preset default ค่าเริ่มต้น รีเซ็ต")

    UIF.sectionHeader(pageMaster, "ระบบ DUMP เกมแบบเต็มสูบ (แยกไฟล์)", "📂")
    
    B.fullDump = UIF.button(pageMaster, { Text = "📂 สร้างไฟล์ Dump (Workspace, Players, ฯลฯ)", Bg = UIF.Theme.CardBg })
    registerCard(B.fullDump, "dump full dump แยกไฟล์ dump object")
    B.fullDump.Activated:Connect(function()
        if env.Dumper and env.Dumper.runFullDump then env.Dumper.runFullDump() else UI.showNotif("❌ ไม่พบโมดูล Dumper", 3) end
    end)
    
    B.saveInstance = UIF.button(pageMaster, { Text = "🗺️ ดูดแมพ (SaveInstance) สำหรับ Roblox Studio", Bg = UIF.Theme.CardBg })
    registerCard(B.saveInstance, "saveinstance ดูดแมพ สตูดิโอ ก๊อปแมพ copy map studio")
    B.saveInstance.Activated:Connect(function()
        if env.Dumper and env.Dumper.saveInstanceMap then env.Dumper.saveInstanceMap() else UI.showNotif("❌ ไม่พบโมดูล Dumper", 3) end
    end)

    UIF.sectionHeader(pageMaster, "ระบบ Rejoin & ย้ายเซิร์ฟเวอร์ (Server Hop)", "🌐")

    local serverRow1 = Instance.new("Frame", pageMaster)
    serverRow1.Size = UDim2.new(1, 0, 0, 36)
    serverRow1.BackgroundTransparency = 1

    local hopHighPopBtn = Instance.new("TextButton", serverRow1)
    hopHighPopBtn.Size = UDim2.new(0.58, 0, 1, 0)
    hopHighPopBtn.Position = UDim2.new(0, 0, 0, 0)
    hopHighPopBtn.BackgroundColor3 = UIF.Theme.CardBg
    hopHighPopBtn.Text = "🔥 ย้ายไปห้องคนเยอะสุด (High Pop)"
    hopHighPopBtn.TextColor3 = UIF.Theme.AccentPink
    hopHighPopBtn.TextSize = 11
    hopHighPopBtn.Font = Enum.Font.GothamBold
    hopHighPopBtn.BorderSizePixel = 0
    hopHighPopBtn.Active = true
    Instance.new("UICorner", hopHighPopBtn).CornerRadius = UDim.new(0, 6)
    local hhpStroke = Instance.new("UIStroke", hopHighPopBtn)
    hhpStroke.Color = UIF.Theme.AccentPink
    hhpStroke.Thickness = 1

    local rejoinBtn = Instance.new("TextButton", serverRow1)
    rejoinBtn.Size = UDim2.new(0.38, 0, 1, 0)
    rejoinBtn.Position = UDim2.new(0.62, 0, 0, 0)
    rejoinBtn.BackgroundColor3 = UIF.Theme.CardBg
    rejoinBtn.Text = "🔄 Rejoin ห้องเดิม"
    rejoinBtn.TextColor3 = UIF.Theme.AccentBlue
    rejoinBtn.TextSize = 11
    rejoinBtn.Font = Enum.Font.GothamBold
    rejoinBtn.BorderSizePixel = 0
    rejoinBtn.Active = true
    Instance.new("UICorner", rejoinBtn).CornerRadius = UDim.new(0, 6)
    local rjStroke = Instance.new("UIStroke", rejoinBtn)
    rjStroke.Color = UIF.Theme.CardBorder
    rjStroke.Thickness = 1

    local serverRow2 = Instance.new("Frame", pageMaster)
    serverRow2.Size = UDim2.new(1, 0, 0, 36)
    serverRow2.BackgroundTransparency = 1

    local randomHopBtn = Instance.new("TextButton", serverRow2)
    randomHopBtn.Size = UDim2.new(0.48, 0, 1, 0)
    randomHopBtn.Position = UDim2.new(0, 0, 0, 0)
    randomHopBtn.BackgroundColor3 = UIF.Theme.CardBg
    randomHopBtn.Text = "🎲 สุ่มย้ายห้อง (Random)"
    randomHopBtn.TextColor3 = UIF.Theme.AccentYellow
    randomHopBtn.TextSize = 10.5
    randomHopBtn.Font = Enum.Font.GothamBold
    randomHopBtn.BorderSizePixel = 0
    randomHopBtn.Active = true
    Instance.new("UICorner", randomHopBtn).CornerRadius = UDim.new(0, 6)
    local rhStroke = Instance.new("UIStroke", randomHopBtn)
    rhStroke.Color = UIF.Theme.CardBorder
    rhStroke.Thickness = 1

    local lowPopBtn = Instance.new("TextButton", serverRow2)
    lowPopBtn.Size = UDim2.new(0.48, 0, 1, 0)
    lowPopBtn.Position = UDim2.new(0.52, 0, 0, 0)
    lowPopBtn.BackgroundColor3 = UIF.Theme.CardBg
    lowPopBtn.Text = "📉 ย้ายห้องคนน้อย (Farm)"
    lowPopBtn.TextColor3 = UIF.Theme.AccentGreen
    lowPopBtn.TextSize = 10.5
    lowPopBtn.Font = Enum.Font.GothamBold
    lowPopBtn.BorderSizePixel = 0
    lowPopBtn.Active = true
    Instance.new("UICorner", lowPopBtn).CornerRadius = UDim.new(0, 6)
    local lpStroke = Instance.new("UIStroke", lowPopBtn)
    lpStroke.Color = UIF.Theme.CardBorder
    lpStroke.Thickness = 1

    B.autoRejoin = UIF.button(pageMaster, { Text = State.AutoRejoinEnabled and "🛡️ ออโต้ Rejoin เมื่อหลุด (Anti-Disconnect): เปิด" or "🛡️ ออโต้ Rejoin เมื่อหลุด (Anti-Disconnect): ปิด", Bg = State.AutoRejoinEnabled and UIF.Theme.AccentGreen or UIF.Theme.CardBg, TextColor3 = State.AutoRejoinEnabled and UIF.Theme.TextDark or UIF.Theme.Text })

    registerCard(hopHighPopBtn, "server hop high pop ย้ายเซิร์ฟเวอร์ ห้องคนเยอะ ย้ายห้อง")
    registerCard(rejoinBtn, "rejoin เข้าห้องเดิม รีจอย")
    registerCard(randomHopBtn, "random hop สุ่มห้อง ย้ายเซิร์ฟ")
    registerCard(lowPopBtn, "low pop ฟาร์ม ห้องคนน้อย")
    registerCard(B.autoRejoin, "auto rejoin กันหลุด ตัดการเชื่อมต่อ 277 267")

    local function requestApi(url)
        if game.HttpGet then return game:HttpGet(url)
        elseif http_request then local res = http_request({ Url = url, Method = "GET" }); return res and res.Body
        elseif request then local res = request({ Url = url, Method = "GET" }); return res and res.Body
        elseif syn and syn.request then local res = syn.request({ Url = url, Method = "GET" }); return res and res.Body
        end
        return nil
    end

    local function doRejoinSame()
        UI.showNotif("🔄 กำลังเชื่อมต่อเข้าห้องเดิม...", 3)
        local ts = game:GetService("TeleportService")
        pcall(function() ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
        task.wait(2)
        pcall(function() ts:Teleport(game.PlaceId, LocalPlayer) end)
    end

    local function doRandomHop()
        UI.showNotif("🎲 กำลังสุ่มย้ายเซิร์ฟเวอร์...", 3)
        task.spawn(function()
            local http = game:GetService("HttpService")
            local ts = game:GetService("TeleportService")
            local placeId = game.PlaceId
            local currentJobId = game.JobId

            local success = pcall(function()
                local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
                local response = requestApi(url)
                if response then
                    local data = http:JSONDecode(response)
                    if data and data.data then
                        local available = {}
                        for _, s in ipairs(data.data) do
                            if s.id ~= currentJobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.playing > 0 then
                                table.insert(available, s)
                            end
                        end
                        if #available > 0 then
                            local r = available[math.random(1, #available)]
                            ts:TeleportToPlaceInstance(placeId, r.id, LocalPlayer)
                            return true
                        end
                    end
                end
            end)
            if not success then UI.showNotif("❌ ระบบดึงข้อมูลห้องล้มเหลว (ป้องกันพาไปหาเพื่อน)", 3) end
        end)
    end

    local function doHopHighPop()
        UI.showNotif("🔍 กำลังค้นหาห้องที่มีคนเล่นเยอะที่สุด...", 3)
        task.spawn(function()
            local http = game:GetService("HttpService")
            local ts = game:GetService("TeleportService")
            local placeId = game.PlaceId
            local currentJobId = game.JobId

            local bestServer = nil
            local bestCount = -1

            pcall(function()
                local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Desc&limit=100"
                local response = requestApi(url)
                if response then
                    local data = http:JSONDecode(response)
                    if data and data.data then
                        for _, s in ipairs(data.data) do
                            if s.id ~= currentJobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers then
                                if s.playing > bestCount then
                                    bestCount = s.playing
                                    bestServer = s
                                end
                            end
                        end
                    end
                end
            end)

            if bestServer and bestServer.id then
                UI.showNotif(string.format("🔥 พบห้องคนเยอะ! (%d/%d คน) กำลังย้าย...", bestServer.playing, bestServer.maxPlayers), 3)
                task.wait(0.5)
                ts:TeleportToPlaceInstance(placeId, bestServer.id, LocalPlayer)
            else
                UI.showNotif("⚠️ ไม่พบห้องคนเยอะอื่น กำลังสุ่มย้ายห้อง...", 3)
                task.wait(0.5)
                doRandomHop()
            end
        end)
    end

    local function doHopLowPop()
        UI.showNotif("🔍 กำลังค้นหาห้องคนน้อยสำหรับฟาร์ม...", 3)
        task.spawn(function()
            local http = game:GetService("HttpService")
            local ts = game:GetService("TeleportService")
            local placeId = game.PlaceId
            local currentJobId = game.JobId

            local bestServer = nil
            local minCount = 9999

            pcall(function()
                local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
                local response = requestApi(url)
                if response then
                    local data = http:JSONDecode(response)
                    if data and data.data then
                        for _, s in ipairs(data.data) do
                            if s.id ~= currentJobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers and s.playing > 0 then
                                if s.playing < minCount then
                                    minCount = s.playing
                                    bestServer = s
                                end
                            end
                        end
                    end
                end
            end)

            if bestServer and bestServer.id then
                UI.showNotif(string.format("📉 พบห้องคนน้อย! (%d/%d คน) กำลังย้าย...", bestServer.playing, bestServer.maxPlayers), 3)
                task.wait(0.5)
                ts:TeleportToPlaceInstance(placeId, bestServer.id, LocalPlayer)
            else
                UI.showNotif("⚠️ ไม่พบห้องคนน้อย กำลังสุ่มย้ายห้อง...", 3)
                task.wait(0.5)
                doRandomHop()
            end
        end)
    end

    rejoinBtn.Activated:Connect(doRejoinSame)
    hopHighPopBtn.Activated:Connect(doHopHighPop)
    lowPopBtn.Activated:Connect(doHopLowPop)
    randomHopBtn.Activated:Connect(doRandomHop)

    local autoRejoinConn = nil
    B.autoRejoin.Activated:Connect(function()
        State.AutoRejoinEnabled = not State.AutoRejoinEnabled
        if State.AutoRejoinEnabled then
            B.autoRejoin.Text = "🛡️ ออโต้ Rejoin เมื่อหลุด (Anti-Disconnect): เปิด"
            B.autoRejoin.BackgroundColor3 = UIF.Theme.AccentGreen
            B.autoRejoin.TextColor3 = UIF.Theme.TextDark
            UI.showNotif("🛡️ เปิดระบบ Auto-Rejoin เมื่อหลุดแล้ว", 2)

            if not autoRejoinConn then
                local guiService = game:GetService("GuiService")
                autoRejoinConn = guiService.ErrorMessageChanged:Connect(function()
                    task.wait(0.5)
                    doRejoinSame()
                end)
                Cleanup.conn(autoRejoinConn)
            end
        else
            B.autoRejoin.Text = "🛡️ ออโต้ Rejoin เมื่อหลุด (Anti-Disconnect): ปิด"
            B.autoRejoin.BackgroundColor3 = UIF.Theme.CardBg
            B.autoRejoin.TextColor3 = UIF.Theme.Text
            UI.showNotif("🛡️ ปิดระบบ Auto-Rejoin เมื่อหลุดแล้ว", 2)
            if autoRejoinConn then
                autoRejoinConn:Disconnect()
                autoRejoinConn = nil
            end
        end
    end)

    UIF.sectionHeader(pageMaster, "การตรวจสอบระบบ & บันทึก (Diagnostics)", "📋")

    local LogCard = Instance.new("Frame", pageMaster)
    LogCard.Size = UDim2.new(1, 0, 0, 160)
    LogCard.BackgroundColor3 = UIF.Theme.CardBg
    LogCard.BorderSizePixel = 0
    LogCard.Active = true
    Instance.new("UICorner", LogCard).CornerRadius = UDim.new(0, 8)
    local logCardStroke = Instance.new("UIStroke", LogCard)
    logCardStroke.Color = UIF.Theme.CardBorder
    logCardStroke.Thickness = 1

    local LogScroll = Instance.new("ScrollingFrame", LogCard)
    LogScroll.Size = UDim2.new(1, -12, 1, -44)
    LogScroll.Position = UDim2.new(0, 6, 0, 6)
    LogScroll.BackgroundColor3 = UIF.Theme.Sidebar
    LogScroll.BorderSizePixel = 0
    LogScroll.ScrollBarThickness = 3
    LogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogScroll.Active = true
    Instance.new("UICorner", LogScroll).CornerRadius = UDim.new(0, 6)

    local logListLayout = Instance.new("UIListLayout", LogScroll)
    logListLayout.Padding = UDim.new(0, 2)
    Instance.new("UIPadding", LogScroll).PaddingLeft = UDim.new(0, 6)
    LogScroll.UIPadding.PaddingTop = UDim.new(0, 4)

    local function refreshLogsDisplay()
        for _, child in pairs(LogScroll:GetChildren()) do
            if child:IsA("TextLabel") then child:Destroy() end
        end
        local logs = env.Logger and env.Logger.getLogs() or {}
        if #logs == 0 then
            local empty = Instance.new("TextLabel", LogScroll)
            empty.Size = UDim2.new(1, 0, 0, 25)
            empty.BackgroundTransparency = 1
            empty.Text = "(ยังไม่มีบันทึกข้อผิดพลาด - ระบบทำงานปกติ)"
            empty.TextColor3 = UIF.Theme.AccentGreen
            empty.TextSize = 10
            empty.Font = Enum.Font.Gotham
            empty.TextXAlignment = Enum.TextXAlignment.Left
        else
            for i = math.max(1, #logs - 30), #logs do
                local entry = logs[i]
                local lbl = Instance.new("TextLabel", LogScroll)
                lbl.Size = UDim2.new(1, -8, 0, 16)
                lbl.BackgroundTransparency = 1
                lbl.Text = string.format("[%s] [%s] %s: %s", entry.time, entry.module, entry.event, entry.details)
                lbl.TextSize = 10
                lbl.Font = Enum.Font.Code
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                if entry.level == "ERROR" then lbl.TextColor3 = UIF.Theme.AccentRed
                elseif entry.level == "WARN" then lbl.TextColor3 = UIF.Theme.AccentYellow
                elseif entry.level == "DETECT" then lbl.TextColor3 = UIF.Theme.AccentPurple
                else lbl.TextColor3 = UIF.Theme.TextDim end
            end
        end
    end

    local LogBtnRow = Instance.new("Frame", LogCard)
    LogBtnRow.Size = UDim2.new(1, -12, 0, 26)
    LogBtnRow.Position = UDim2.new(0, 6, 1, -32)
    LogBtnRow.BackgroundTransparency = 1

    local refreshLogBtn = Instance.new("TextButton", LogBtnRow)
    refreshLogBtn.Size = UDim2.new(0.32, 0, 1, 0)
    refreshLogBtn.BackgroundColor3 = UIF.Theme.Sidebar
    refreshLogBtn.Text = "🔄 รีเฟรช Log"
    refreshLogBtn.TextColor3 = UIF.Theme.Text
    refreshLogBtn.TextSize = 10
    refreshLogBtn.Font = Enum.Font.GothamBold
    refreshLogBtn.Active = true
    Instance.new("UICorner", refreshLogBtn).CornerRadius = UDim.new(0, 4)
    refreshLogBtn.Activated:Connect(refreshLogsDisplay)

    local exportLogBtn = Instance.new("TextButton", LogBtnRow)
    exportLogBtn.Size = UDim2.new(0.32, 0, 1, 0)
    exportLogBtn.Position = UDim2.new(0.34, 0, 0, 0)
    exportLogBtn.BackgroundColor3 = UIF.Theme.Sidebar
    exportLogBtn.Text = "💾 Export ไฟล์"
    exportLogBtn.TextColor3 = UIF.Theme.AccentBlue
    exportLogBtn.TextSize = 10
    exportLogBtn.Font = Enum.Font.GothamBold
    exportLogBtn.Active = true
    Instance.new("UICorner", exportLogBtn).CornerRadius = UDim.new(0, 4)
    exportLogBtn.Activated:Connect(function()
        if env.Logger then
            local ok, msg = env.Logger.exportToFile("UtilityHub_log.txt")
            UI.showNotif(ok and "💾 บันทึก UtilityHub_log.txt แล้ว" or "❌ " .. tostring(msg), 3)
        end
    end)

    local clearLogBtn = Instance.new("TextButton", LogBtnRow)
    clearLogBtn.Size = UDim2.new(0.32, 0, 1, 0)
    clearLogBtn.Position = UDim2.new(0.68, 0, 0, 0)
    clearLogBtn.BackgroundColor3 = UIF.Theme.Sidebar
    clearLogBtn.Text = "🗑️ ล้าง Log"
    clearLogBtn.TextColor3 = UIF.Theme.AccentRed
    clearLogBtn.TextSize = 10
    clearLogBtn.Font = Enum.Font.GothamBold
    clearLogBtn.Active = true
    Instance.new("UICorner", clearLogBtn).CornerRadius = UDim.new(0, 4)
    clearLogBtn.Activated:Connect(function()
        if env.Logger then env.Logger.clearLogs() end
        refreshLogsDisplay()
        UI.showNotif("🗑️ ล้างบันทึกประวัติแล้ว", 2)
    end)

    refreshLogsDisplay()

    local scanRadius = 100
    function UI.scanNearby()
        local Players = game:GetService("Players")
        local lp = Players.LocalPlayer
        local myChar = lp.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not myHRP then
            UI.showNotif("❌ ไม่พบตัวละครของคุณ!", 2)
            return
        end
        local myPos = myHRP.Position
        local added = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (p.Character.HumanoidRootPart.Position - myPos).Magnitude
                if dist <= scanRadius then
                    if not env.FriendlyPlayers[p.Name] then
                        env.FriendlyPlayers[p.Name] = true
                        table.insert(added, p.Name .. " (" .. math.floor(dist) .. "m)")
                    end
                end
            end
        end
        if #added > 0 then
            UI.showNotif("✅ เพิ่ม " .. #added .. " คน: " .. table.concat(added, ", "), 3)
            if UI.refreshTeamList then UI.refreshTeamList() end
        else
            UI.showNotif("📡 ไม่พบผู้เล่นอื่นในรัศมี " .. scanRadius .. "m", 2)
        end
    end

    UI.refreshTeamList()

    -- ========================================================================
    -- ====== Mobile Hotkeys (ปุ่มลอยสำหรับมือถือ ไม่บัคกล้องหมุน) ======
    -- ========================================================================
    local MobileHub = Instance.new("Frame")
    MobileHub.Name = "MobileHub"
    MobileHub.Size = UDim2.new(0, 150, 0, 220)
    MobileHub.Position = UDim2.new(1, -160, 0.5, -110)
    MobileHub.BackgroundColor3 = UIF.Theme.Bg
    MobileHub.Active = true -- [สำคัญ] ป้องกันกล้องขยับตอนสัมผัสกรอบ
    MobileHub.Visible = UserInputService.TouchEnabled
    Instance.new("UICorner", MobileHub).CornerRadius = UDim.new(0, 8)
    local mhStroke = Instance.new("UIStroke", MobileHub)
    mhStroke.Color = UIF.Theme.AccentBlue
    mhStroke.Thickness = 1.5
    MobileHub.Parent = ScreenGui

    local MobileToggle = Instance.new("TextButton")
    MobileToggle.Name = "MobileToggle"
    MobileToggle.Size = UDim2.new(0, 42, 0, 42)
    MobileToggle.Position = UDim2.new(1, -55, 0.5, -21)
    MobileToggle.BackgroundColor3 = UIF.Theme.AccentBlue
    MobileToggle.Text = "🕹️"
    MobileToggle.TextSize = 20
    MobileToggle.Active = true -- [สำคัญ] ป้องกันกล้องขยับตอนกดปุ่ม
    MobileToggle.Visible = UserInputService.TouchEnabled
    Instance.new("UICorner", MobileToggle).CornerRadius = UDim.new(1, 0)
    MobileToggle.Parent = ScreenGui

    MobileToggle.Activated:Connect(function()
        MobileHub.Visible = not MobileHub.Visible
    end)

    local mobDragging, mobDragStart, mobStartPos
    MobileToggle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mobDragging = true
            mobDragStart = input.Position
            mobStartPos = MobileToggle.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then mobDragging = false end
            end)
        end
    end)
    Cleanup.conn(UserInputService.InputChanged:Connect(function(input, processed)
        if processed then return end
        if mobDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - mobDragStart
            MobileToggle.Position = UDim2.new(mobStartPos.X.Scale, mobStartPos.X.Offset + delta.X, mobStartPos.Y.Scale, mobStartPos.Y.Offset + delta.Y)
            MobileHub.Position = UDim2.new(MobileToggle.Position.X.Scale, MobileToggle.Position.X.Offset - 160, MobileToggle.Position.Y.Scale, MobileToggle.Position.Y.Offset - 90)
        end
    end))

    local mhLayout = Instance.new("UIListLayout", MobileHub)
    mhLayout.Padding = UDim.new(0, 5)
    mhLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Instance.new("UIPadding", MobileHub).PaddingTop = UDim.new(0, 10)

    local function createMobileBtn(text, color, callback)
        local btn = Instance.new("TextButton", MobileHub)
        btn.Size = UDim2.new(0, 130, 0, 30)
        btn.BackgroundColor3 = UIF.Theme.CardBg
        btn.Text = text
        btn.TextColor3 = color
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.Active = true -- [สำคัญ] ป้องกันกล้องขยับตอนกดปุ่ม
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.Activated:Connect(callback)
    end

    createMobileBtn("🎯 Aimbot (Aim)", UIF.Theme.AccentRed, function() if env.Aimbot and env.Aimbot.toggle then env.Aimbot.toggle() end end)
    createMobileBtn("🔒 Lock Target", UIF.Theme.AccentYellow, function() if env.Aimbot and env.Aimbot.toggleHardLock then env.Aimbot.toggleHardLock() end end)
    createMobileBtn("🚀 Warp (Z)", UIF.Theme.AccentGreen, function() if env.World and env.World.warpToLockedTarget then env.World.warpToLockedTarget() end end)
    createMobileBtn("⚡ Fake Lag (F)", UIF.Theme.AccentBlue, function() if env.World and env.World.toggleFakeLag then env.World.toggleFakeLag() end end)
    createMobileBtn("🗑️ ลบของ (Del)", UIF.Theme.Text, function() if env.World and env.World.toggleDeleteMode then env.World.toggleDeleteMode() end end)
    createMobileBtn("🧱 สร้างเสา (Pole)", UIF.Theme.Text, function() if env.World and env.World.spawnPoleIfEnabled then env.World.spawnPoleIfEnabled() end end)

    UI.ScreenGui = ScreenGui
    UI.Main = Main
    UI.OpenBtn = OpenBtn
    UI.Status = Status
    UI.buttons = B
    UI.sliders = S
    UI.hotkeys = HK
    return UI
end

end)()
if type(__factory_hub) ~= "function" then error("Module hub did not return a factory function") end

-- ========== MODULE: scanner ==========
local __factory_scanner = (function()
-- ============================================================================
-- scanner.lua — High-Performance Universal Game Abstraction Layer (GAL)
--
-- Optimization:
--   - Cache Profile & Parts per Character (Scan once upon spawn, not every frame)
--   - O(1) Direct memory reads in Render loops
--   - Zero lag & zero GetDescendants() spam in RenderStepped
-- ============================================================================

return function(env)
    local Players     = env.Players
    local LocalPlayer = env.LocalPlayer
    local Logger      = env.Logger or { info = function() end, warn = function() end, error = function() end }

    local Scanner = {}

    local HEALTH_NAMES = {
        Health = true, HP = true, CurrentHealth = true, CurrentHP = true, health = true, hp = true
    }
    local MAX_HEALTH_NAMES = {
        MaxHealth = true, MaxHP = true, maxHealth = true, maxHP = true
    }

    -- Cache สำหรับเก็บ Profile และ Parts ของตัวละครแต่ละตัว (ไม่ต้องสแกนซ้ำทุก frame)
    local charCache = setmetatable({}, { __mode = "k" }) -- weak keys

    -- ====================================================================
    -- FAST SCAN (ทำงานแค่ครั้งเดียวต่อตัวละคร)
    -- ====================================================================
    local function scanCharacter(char)
        if not char or not char.Parent then return nil end

        local data = {
            char = char,
            hum = char:FindFirstChildOfClass("Humanoid"),
            hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char.PrimaryPart,
            head = char:FindFirstChild("Head"),
            type = "DefaultHumanoid",
            healthObj = nil,
            maxHealthObj = nil,
            healthAttr = nil,
            maxHealthAttr = nil,
            desc = "Default Roblox (Humanoid)"
        }

        -- 1. เช็ค Humanoid ก่อน (เร็วสุด O(1))
        if data.hum and data.hum.MaxHealth > 0 then
            data.healthObj = data.hum
            data.maxHealthObj = data.hum
            data.type = "DefaultHumanoid"
            data.desc = "ระบบ Default Roblox (Humanoid)"
            charCache[char] = data
            return data
        end

        -- 2. เช็ค Attributes
        local attrs = char:GetAttributes()
        for k, v in pairs(attrs) do
            if type(v) == "number" then
                if not data.healthAttr and HEALTH_NAMES[k] then
                    data.healthAttr = k
                end
                if not data.maxHealthAttr and MAX_HEALTH_NAMES[k] then
                    data.maxHealthAttr = k
                end
            end
        end

        if data.healthAttr then
            data.type = "Attribute"
            data.desc = "ระบบ Custom (Attributes) - " .. tostring(data.healthAttr)
            charCache[char] = data
            return data
        end

        -- 3. เช็ค Children / Values (ใช้ GetChildren เร็วกว่า GetDescendants มหาศาล)
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                if not data.healthObj and HEALTH_NAMES[obj.Name] then
                    data.healthObj = obj
                end
                if not data.maxHealthObj and MAX_HEALTH_NAMES[obj.Name] then
                    data.maxHealthObj = obj
                end
            elseif obj:IsA("Folder") or obj:IsA("Configuration") then
                for _, subObj in ipairs(obj:GetChildren()) do
                    if subObj:IsA("NumberValue") or subObj:IsA("IntValue") then
                        if not data.healthObj and HEALTH_NAMES[subObj.Name] then
                            data.healthObj = subObj
                        end
                        if not data.maxHealthObj and MAX_HEALTH_NAMES[subObj.Name] then
                            data.maxHealthObj = subObj
                        end
                    end
                end
            end
        end

        if data.healthObj then
            data.type = "CustomValue"
            data.desc = "ระบบ Custom (Value Objects) - " .. tostring(data.healthObj.Name)
            charCache[char] = data
            return data
        end

        -- 4. Custom Rig Detection (Non-Humanoid Framework e.g. Custom FPS, Phantom Forces, Bad Business)
        if not data.hrp then
            data.hrp = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("LowerTorso")
                     or char:FindFirstChild("Chest") or char:FindFirstChild("Body") or char:FindFirstChild("Root")
                     or char:FindFirstChild("Hitbox") or char.PrimaryPart
        end
        if not data.head then
            data.head = char:FindFirstChild("Head") or char:FindFirstChild("FakeHead") or char:FindFirstChild("head")
        end

        if not data.hum and data.head and (data.hrp or char.PrimaryPart) then
            data.type = "CustomRig"
            data.desc = "ระบบ Custom Rig (Non-Humanoid Framework)"
            data.hrp = data.hrp or data.head
            data.head = data.head or data.hrp
            charCache[char] = data
            return data
        end

        -- Fallback ถ้ามี Humanoid แม้ MaxHealth เป็น 0
        if data.hum then
            data.healthObj = data.hum
            data.maxHealthObj = data.hum
            data.type = "DefaultHumanoid"
            data.desc = "ระบบ Default Roblox (Humanoid Fallback)"
        else
            data.type = "Unknown"
            data.desc = "ไม่พบระบบเลือด (Unknown)"
        end

        charCache[char] = data
        return data
    end

    local function getCached(char)
        if not char then return nil end
        local c = charCache[char]
        if c and c.char == char and char.Parent then
            return c
        end
        return scanCharacter(char)
    end

    -- ====================================================================
    -- PUBLIC API: FAST UNIVERSAL METHODS
    -- ====================================================================

    function Scanner.runScan()
        local char = LocalPlayer.Character
        local data = scanCharacter(char)
        local prof = {
            Type = data and data.type or "Unknown",
            HealthObj = data and (data.healthObj or data.healthAttr) or nil,
            MaxHealthObj = data and (data.maxHealthObj or data.maxHealthAttr) or nil,
            Desc = data and data.desc or "รอตัวละครโหลด..."
        }
        Logger.info("Scanner", "Scan", prof.Desc)
        return prof
    end

    function Scanner.getProfile()
        local char = LocalPlayer.Character
        local data = getCached(char)
        return {
            Type = data and data.type or "Unknown",
            HealthObj = data and (data.healthObj or data.healthAttr) or nil,
            MaxHealthObj = data and (data.maxHealthObj or data.maxHealthAttr) or nil,
            Desc = data and data.desc or "รอตัวละครโหลด..."
        }
    end

    function Scanner.isNPC(obj)
        if not obj or typeof(obj) ~= "Instance" or not obj:IsA("Model") then return false end
        if obj == LocalPlayer.Character then return false end
        if LocalPlayer.Character and obj:IsDescendantOf(LocalPlayer.Character) then return false end
        if Players:GetPlayerFromCharacter(obj) ~= nil then return false end
        local c = getCached(obj)
        if not c or not c.hrp or not c.hrp.Parent then return false end
        -- Filter out static anchored props/dummies
        if c.hrp.Anchored then return false end
        if c.hum and (c.hum.Health <= 0 or c.hum.MaxHealth <= 0 or c.hum.Health >= 1000000) then return false end
        return true
    end

    -- Fast Active Bot / NPC Discovery System (Deep Scan with Static NPC Filtering & Zero Lag Cache)
    local cachedNPCs = {}
    local lastNPCScan = 0
    local NPC_SCAN_INTERVAL = 0.6

    local function refreshNPCList()
        local now = tick()
        if now - lastNPCScan < NPC_SCAN_INTERVAL then
            -- Verify cached NPCs are still valid & alive on fast frames
            local liveList = {}
            for i = 1, #cachedNPCs do
                local entry = cachedNPCs[i]
                local m = entry.Character
                if m and m.Parent and entry.RootPart and entry.RootPart.Parent and not entry.RootPart.Anchored then
                    local hum = entry.Humanoid or m:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 and hum.Health < 1000000 then
                        liveList[#liveList + 1] = entry
                    end
                end
            end
            cachedNPCs = liveList
            return cachedNPCs
        end
        lastNPCScan = now

        local result = {}
        local seen = {}

        local ignoredRigNames = {
            ["viewmodel"] = true, ["arms"] = true, ["arm"] = true, ["gun"] = true,
            ["weapon"] = true, ["knife"] = true, ["bullet"] = true, ["debris"] = true,
            ["effects"] = true, ["particles"] = true, ["ragdoll"] = true, ["corpse"] = true,
            ["dropped"] = true, ["camera"] = true, ["fps"] = true, ["accessory"] = true,
            ["handle"] = true, ["backpack"] = true
        }

        local function checkCandidate(m)
            if not m or typeof(m) ~= "Instance" or not m:IsA("Model") or seen[m] then return end
            seen[m] = true

            if m == LocalPlayer.Character then return end
            if LocalPlayer.Character and m:IsDescendantOf(LocalPlayer.Character) then return end
            if Players:GetPlayerFromCharacter(m) ~= nil then return end -- Handled by Players loop

            local lName = m.Name:lower()
            for ign, _ in pairs(ignoredRigNames) do
                if lName:find(ign) then return end
            end

            if m:FindFirstAncestorOfClass("Tool") or m:FindFirstAncestorOfClass("Accessory") then return end
            if m:IsDescendantOf(workspace.CurrentCamera) or m:IsDescendantOf(workspace.Terrain) then return end

            local c = getCached(m)
            if not c or not c.hrp or not c.hrp.Parent or not c.head or not c.head.Parent then return end

            -- 1. บอทที่เดินยิงจริงจะต้องไม่ Anchored
            if c.hrp.Anchored or c.head.Anchored then return end

            -- 2. ต้องเป็นโครงตัวละครจริง (มีส่วนประกอบแขน/ขา/ลำตัว)
            local hasLimbs = m:FindFirstChild("Left Arm") or m:FindFirstChild("LeftLeg") or m:FindFirstChild("LeftUpperArm")
                          or m:FindFirstChild("Right Arm") or m:FindFirstChild("RightLeg") or m:FindFirstChild("RightUpperArm")
                          or m:FindFirstChild("Torso") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Animate")
                          or (c.hum and c.hum.RigType ~= nil)
            if not hasLimbs then return end

            -- 3. ตรวจสอบสถานะการมีชีวิตและเลือดจริง
            local alive = false
            local hp, maxHp = 0, 100
            if c.type == "DefaultHumanoid" and c.hum then
                hp = c.hum.Health
                maxHp = c.hum.MaxHealth
                alive = hp > 0 and maxHp > 0 and hp < 1000000
            elseif c.type == "Attribute" and c.healthAttr then
                hp = m:GetAttribute(c.healthAttr) or 0
                maxHp = c.maxHealthAttr and m:GetAttribute(c.maxHealthAttr) or 100
                alive = hp > 0
            elseif c.type == "CustomValue" and c.healthObj then
                hp = c.healthObj.Value or 0
                maxHp = c.maxHealthObj and c.maxHealthObj.Value or 100
                alive = hp > 0
            elseif c.type == "CustomRig" then
                alive = (c.hrp and c.hrp.Parent and c.head and c.head.Parent and m.Parent) ~= nil
                hp, maxHp = 100, 100
            elseif c.hum then
                hp = c.hum.Health
                maxHp = c.hum.MaxHealth
                alive = hp > 0 and maxHp > 0 and hp < 1000000
            end

            if alive then
                result[#result + 1] = {
                    Character = m,
                    Model = m,
                    Name = m.Name,
                    DisplayName = m.Name,
                    isBot = true,
                    RootPart = c.hrp,
                    Head = c.head,
                    Humanoid = c.hum
                }
            end
        end

        -- 1. ค้นหาในโฟลเดอร์ Entity ที่เกมมักใช้เก็บตัวละคร Custom Framework (เช่น Phantom Forces, Bad Business)
        local entityFolderNames = { "Players", "Characters", "Entities", "Units", "NPCs", "Bots", "Soldiers", "Zombies", "Enemies", "Combatants" }
        for _, fName in ipairs(entityFolderNames) do
            local f = workspace:FindFirstChild(fName)
            if f and f ~= LocalPlayer.Character then
                for _, obj in ipairs(f:GetChildren()) do
                    if obj:IsA("Model") then
                        checkCandidate(obj)
                    elseif obj:IsA("Folder") then
                        for _, subObj in ipairs(obj:GetChildren()) do
                            if subObj:IsA("Model") then
                                checkCandidate(subObj)
                            end
                        end
                    end
                end
            end
        end

        -- 2. ค้นหาโมเดลที่มี Humanoid ทั่วทั้ง Workspace
        local descendants = workspace:GetDescendants()
        for i = 1, #descendants do
            local obj = descendants[i]
            if obj:IsA("Humanoid") then
                local model = obj.Parent
                if model and model:IsA("Model") then
                    checkCandidate(model)
                else
                    local ancestorModel = obj:FindFirstAncestorOfClass("Model")
                    if ancestorModel then
                        checkCandidate(ancestorModel)
                    end
                end
            end
        end

        cachedNPCs = result
        return cachedNPCs
    end

    function Scanner.getNPCs()
        return refreshNPCList()
    end

    -- Universal Target Methods (Accepts Player, Model, or Bot Entity Table)
    function Scanner.getCharacter(target)
        if not target then return nil end
        if typeof(target) == "Instance" then
            if target:IsA("Player") then
                return target.Character
            elseif target:IsA("Model") then
                return target
            end
        elseif type(target) == "table" and target.Character then
            return target.Character
        end
        return nil
    end

    function Scanner.getRootPart(target)
        local char = Scanner.getCharacter(target)
        if not char then return nil end
        local c = getCached(char)
        if c and c.hrp and c.hrp.Parent then
            return c.hrp
        end
        local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char.PrimaryPart
        if c then c.hrp = hrp end
        return hrp
    end

    function Scanner.getHead(target)
        local char = Scanner.getCharacter(target)
        if not char then return nil end
        local c = getCached(char)
        if c and c.head and c.head.Parent then
            return c.head
        end
        local head = char:FindFirstChild("Head")
        if c then c.head = head end
        return head
    end

    function Scanner.getName(target)
        if not target then return "Unknown" end
        if typeof(target) == "Instance" then
            if target:IsA("Player") then
                return target.DisplayName or target.Name
            else
                return target.Name
            end
        elseif type(target) == "table" then
            return target.DisplayName or target.Name or "Bot"
        end
        return "Unknown"
    end

    function Scanner.getHealth(target)
        local char = Scanner.getCharacter(target)
        if not char then return 0, 100 end

        local c = getCached(char)
        if not c then return 0, 100 end

        if c.type == "DefaultHumanoid" and c.hum then
            return c.hum.Health, c.hum.MaxHealth
        elseif c.type == "Attribute" and c.healthAttr then
            local hp = char:GetAttribute(c.healthAttr) or 0
            local max = c.maxHealthAttr and char:GetAttribute(c.maxHealthAttr) or 100
            return hp, max
        elseif c.type == "CustomValue" and c.healthObj then
            local hp = c.healthObj.Value or 0
            local max = c.maxHealthObj and c.maxHealthObj.Value or 100
            return hp, max
        elseif c.type == "CustomRig" then
            return 100, 100
        end

        return 0, 100
    end

    function Scanner.isAlive(target)
        local char = Scanner.getCharacter(target)
        if not char or not char.Parent then return false end

        local c = getCached(char)
        if not c then return false end

        if c.type == "DefaultHumanoid" and c.hum then
            return c.hum.Health > 0
        elseif c.type == "Attribute" and c.healthAttr then
            local hp = char:GetAttribute(c.healthAttr) or 0
            return hp > 0
        elseif c.type == "CustomValue" and c.healthObj then
            local hp = c.healthObj.Value or 0
            return hp > 0
        elseif c.type == "CustomRig" then
            return c.hrp ~= nil and c.hrp.Parent ~= nil and c.head ~= nil and c.head.Parent ~= nil and char.Parent ~= nil
        end

        -- Fallback check
        if c.hum then return c.hum.Health > 0 end
        return char:FindFirstChild("Head") ~= nil
    end

    function Scanner.setWalkSpeed(speed)
        local char = LocalPlayer.Character
        if not char then return end
        local c = getCached(char)
        if c and c.hum then
            c.hum.WalkSpeed = speed
        end
    end

    function Scanner.doJump()
        local char = LocalPlayer.Character
        if not char then return end
        local c = getCached(char)
        if c and c.hum then
            c.hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    -- Cleanup cache เมื่อผู้เล่นออกจากเกม
    Players.PlayerRemoving:Connect(function(p)
        if p.Character then
            charCache[p.Character] = nil
        end
    end)

    return Scanner
end
end)()
if type(__factory_scanner) ~= "function" then error("Module scanner did not return a factory function") end

-- ========== MODULE: esp ==========
local __factory_esp = (function()
return function(env)
    local Players = env.Players
    local RunService = env.RunService
    local LocalPlayer = env.LocalPlayer
    local Cleanup = env.Cleanup
    local UIF = env.UIF
    local Colors = env.Colors
    local State = env.State
    local isSameTeam = env.isSameTeam
    local buildRayFilter = env.buildRayFilter
    local Logger = env.Logger or { info = function() end, warn = function() end, error = function() end, detect = function() end }
    local Guard = env.Guard or { safeLoop = function(_, _, fn) return fn end, validatePlayer = function(p) return p and p.Character end, validateRaycast = function() return true end, validateCamera = function() return workspace.CurrentCamera end }
    local B = env.UI.buttons

    local ESP = {}

    -- ============ Player ESP (2D Box + Distance + Health Bar + Chams) ============
    local playerESPOn = false
    local espRenderConnection = nil
    local lastVisibilityCheck = 0
    local espVisibilityCache = {}

    local ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "PlayerESPFolder_" .. tostring(math.random(1000, 9999))
    ESPFolder.Parent = env.UI.ScreenGui
    Cleanup.trackInstance(ESPFolder, "UtilityPlayerESPFolder")

    local espObjects = {}

    local function getPlayerESPObject(player)
        local obj = espObjects[player]
        if not obj then
            local box = Instance.new("Frame")
            box.Name = player.Name .. "_ESPBox"
            box.BackgroundTransparency = 1
            box.BorderSizePixel = 0
            box.Visible = false
            box.Parent = ESPFolder

            -- UIStroke สำหรับกรอบสี่เหลี่ยมคมชัด
            local boxStroke = Instance.new("UIStroke", box)
            boxStroke.Color = UIF.Theme.AccentRed
            boxStroke.Thickness = 1.5

            -- ป้ายชื่อบนหัว
            local nameLabel = Instance.new("TextLabel", box)
            nameLabel.Name = "NameLabel"
            nameLabel.Size = UDim2.new(1, 0, 0, 14)
            nameLabel.Position = UDim2.new(0, 0, 0, -16)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.DisplayName
            nameLabel.TextColor3 = UIF.Theme.Text
            nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            nameLabel.TextStrokeTransparency = 0
            nameLabel.TextSize = 11
            nameLabel.Font = Enum.Font.GothamBold

            -- ป้ายระยะทางใต้เท้า
            local distLabel = Instance.new("TextLabel", box)
            distLabel.Name = "DistLabel"
            distLabel.Size = UDim2.new(1, 0, 0, 14)
            distLabel.Position = UDim2.new(0, 0, 1, 2)
            distLabel.BackgroundTransparency = 1
            distLabel.Text = "0 m"
            distLabel.TextColor3 = UIF.Theme.AccentYellow
            distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            distLabel.TextStrokeTransparency = 0
            distLabel.TextSize = 11
            distLabel.Font = Enum.Font.GothamBold

            -- หลอดเลือดข้างลำตัว (Health Bar Background)
            local hpBg = Instance.new("Frame", box)
            hpBg.Name = "HPBg"
            hpBg.Size = UDim2.new(0, 3, 1, 0)
            hpBg.Position = UDim2.new(0, -6, 0, 0)
            hpBg.BackgroundColor3 = UIF.Theme.Sidebar
            hpBg.BorderSizePixel = 0
            Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 2)

            -- หลอดเลือดข้างลำตัว (Health Bar Fill)
            local hpFill = Instance.new("Frame", hpBg)
            hpFill.Name = "HPFill"
            hpFill.Size = UDim2.new(1, 0, 1, 0)
            hpFill.Position = UDim2.new(0, 0, 1, 0)
            hpFill.AnchorPoint = Vector2.new(0, 1)
            hpFill.BackgroundColor3 = UIF.Theme.AccentGreen
            hpFill.BorderSizePixel = 0
            Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 2)

            obj = {
                box = box,
                stroke = boxStroke,
                name = nameLabel,
                dist = distLabel,
                hpFill = hpFill
            }
            espObjects[player] = obj
        end
        return obj
    end

    local function removePlayerESP(player, char)
        if espObjects[player] then
            if espObjects[player].box then espObjects[player].box:Destroy() end
            espObjects[player] = nil
        end
        if char then
            local hl = char:FindFirstChild("PrankESP"); if hl then hl:Destroy() end
            local hpBar = char:FindFirstChild("HealthESP"); if hpBar then hpBar:Destroy() end
        end
    end

    -- ============ Bot / NPC ESP ============
    local botESPOn = false
    local botEspObjects = {}

    local function getBotESPObject(botKey, name)
        local obj = botEspObjects[botKey]
        if not obj then
            local box = Instance.new("Frame")
            box.Name = "Bot_" .. tostring(name) .. "_ESPBox"
            box.BackgroundTransparency = 1
            box.BorderSizePixel = 0
            box.Visible = false
            box.Parent = ESPFolder

            local boxStroke = Instance.new("UIStroke", box)
            boxStroke.Color = UIF.Theme.AccentYellow
            boxStroke.Thickness = 1.5

            local nameLabel = Instance.new("TextLabel", box)
            nameLabel.Name = "NameLabel"
            nameLabel.Size = UDim2.new(1, 0, 0, 14)
            nameLabel.Position = UDim2.new(0, 0, 0, -16)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = "🤖 " .. tostring(name)
            nameLabel.TextColor3 = UIF.Theme.AccentYellow
            nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            nameLabel.TextStrokeTransparency = 0
            nameLabel.TextSize = 11
            nameLabel.Font = Enum.Font.GothamBold

            local distLabel = Instance.new("TextLabel", box)
            distLabel.Name = "DistLabel"
            distLabel.Size = UDim2.new(1, 0, 0, 14)
            distLabel.Position = UDim2.new(0, 0, 1, 2)
            distLabel.BackgroundTransparency = 1
            distLabel.Text = "0 m"
            distLabel.TextColor3 = UIF.Theme.Text
            distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            distLabel.TextStrokeTransparency = 0
            distLabel.TextSize = 11
            distLabel.Font = Enum.Font.GothamBold

            local hpBg = Instance.new("Frame", box)
            hpBg.Name = "HPBg"
            hpBg.Size = UDim2.new(0, 3, 1, 0)
            hpBg.Position = UDim2.new(0, -6, 0, 0)
            hpBg.BackgroundColor3 = UIF.Theme.Sidebar
            hpBg.BorderSizePixel = 0
            Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 2)

            local hpFill = Instance.new("Frame", hpBg)
            hpFill.Name = "HPFill"
            hpFill.Size = UDim2.new(1, 0, 1, 0)
            hpFill.Position = UDim2.new(0, 0, 1, 0)
            hpFill.AnchorPoint = Vector2.new(0, 1)
            hpFill.BackgroundColor3 = UIF.Theme.AccentGreen
            hpFill.BorderSizePixel = 0
            Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 2)

            obj = {
                box = box,
                stroke = boxStroke,
                name = nameLabel,
                dist = distLabel,
                hpFill = hpFill
            }
            botEspObjects[botKey] = obj
        end
        return obj
    end

    local function removeBotESP(botKey, char)
        if botEspObjects[botKey] then
            if botEspObjects[botKey].box then botEspObjects[botKey].box:Destroy() end
            botEspObjects[botKey] = nil
        end
        if char then
            local hl = char:FindFirstChild("PrankBotESP"); if hl then hl:Destroy() end
        end
    end

    local function updateESPRenderLoop()
        if playerESPOn or botESPOn then
            if not espRenderConnection then
                espRenderConnection = Cleanup.conn(RunService.RenderStepped:Connect(Guard.safeLoop("ESP", "UnifiedESPRender", function()
                    local cam = Guard.validateCamera() or env.Camera
                    if not cam then return end

                    local now = tick()
                    local shouldCheckVisibility = (now - lastVisibilityCheck) >= 0.15
                    if shouldCheckVisibility then
                        lastVisibilityCheck = now
                    end

                    -- 1. Player ESP
                    if playerESPOn then
                        for _, p in pairs(Players:GetPlayers()) do
                            local valid, _, char, hrp = Guard.validatePlayer(p, true)
                            if valid and not isSameTeam(p) then
                                local hum = char:FindFirstChildOfClass("Humanoid")
                                local head = char:FindFirstChild("Head") or hrp
                                local hp, maxHp = (env.Scanner and env.Scanner.getHealth(p)) or (hum and hum.Health or 100), (hum and hum.MaxHealth or 100)
                                local isAlive = (env.Scanner and env.Scanner.isAlive(p)) or (hum and hum.Health > 0)

                                -- Highlight 3D Chams
                                local hl = char:FindFirstChild("PrankESP")
                                if not hl then
                                    hl = Instance.new("Highlight")
                                    hl.Name = "PrankESP"; hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                                    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = char
                                end

                                local isVisible = espVisibilityCache[p]
                                if shouldCheckVisibility then
                                    local rayParams = RaycastParams.new()
                                    rayParams.FilterDescendantsInstances = buildRayFilter(LocalPlayer.Character, char)
                                    rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                    rayParams.IgnoreWater = true
                                    isVisible = workspace:Raycast(cam.CFrame.Position, hrp.Position - cam.CFrame.Position, rayParams) == nil
                                    espVisibilityCache[p] = isVisible
                                end
                                if isVisible == nil then isVisible = true end

                                local espColor = isVisible and UIF.Theme.AccentGreen or UIF.Theme.AccentRed
                                hl.FillColor = espColor

                                -- 2D Box ESP + Distance + Health Bar (Screen Space)
                                local headPos, headOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
                                local legPos, legOn = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.8, 0))
                                local hrpPos, hrpOn = cam:WorldToViewportPoint(hrp.Position)

                                local espObj = getPlayerESPObject(p)
                                if hrpOn and hrpPos.Z > 0 then
                                    local boxHeight = math.abs(headPos.Y - legPos.Y)
                                    local boxWidth = math.clamp(boxHeight * 0.65, 12, 400)
                                    local boxTopLeft = Vector2.new(hrpPos.X - boxWidth / 2, headPos.Y)

                                    espObj.box.Size = UDim2.new(0, boxWidth, 0, boxHeight)
                                    espObj.box.Position = UDim2.new(0, boxTopLeft.X, 0, boxTopLeft.Y)
                                    espObj.stroke.Color = espColor

                                    local distance = math.floor((cam.CFrame.Position - hrp.Position).Magnitude)
                                    espObj.dist.Text = string.format("[%d m]", distance)
                                    espObj.name.Text = p.DisplayName

                                    if isAlive and maxHp > 0 then
                                        local hpPct = math.clamp(hp / maxHp, 0, 1)
                                        espObj.hpFill.Size = UDim2.new(1, 0, hpPct, 0)
                                        espObj.hpFill.BackgroundColor3 = Color3.fromHSV(hpPct * 0.33, 0.9, 0.9)
                                    end

                                    espObj.box.Visible = true
                                else
                                    espObj.box.Visible = false
                                end
                            else
                                if espObjects[p] and espObjects[p].box then
                                    espObjects[p].box.Visible = false
                                end
                                if p.Character then
                                    removePlayerESP(p, p.Character)
                                end
                            end
                        end
                    end

                    -- 2. Bot / NPC ESP
                    if botESPOn and env.Scanner and env.Scanner.getNPCs then
                        local npcs = env.Scanner.getNPCs()
                        local activeBots = {}

                        for _, npc in ipairs(npcs) do
                            local char = env.Scanner.getCharacter(npc)
                            local hrp = env.Scanner.getRootPart(npc)
                            local head = env.Scanner.getHead(npc) or hrp
                            local isAlive = env.Scanner.isAlive(npc)
                            local hp, maxHp = env.Scanner.getHealth(npc)

                            local isFriendly = env.isSameTeam and (env.isSameTeam(npc) or env.isSameTeam(char)) or false
                            if char and hrp and isAlive and not isFriendly then
                                activeBots[char] = true

                                -- Highlight 3D Chams
                                local hl = char:FindFirstChild("PrankBotESP")
                                if not hl then
                                    hl = Instance.new("Highlight")
                                    hl.Name = "PrankBotESP"; hl.OutlineColor = UIF.Theme.AccentYellow
                                    hl.FillColor = UIF.Theme.AccentOrange
                                    hl.FillTransparency = 0.5; hl.OutlineTransparency = 0
                                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = char
                                end

                                -- 2D Box ESP + Distance + Health Bar (Screen Space)
                                local headPos, headOn = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
                                local legPos, legOn = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 2.8, 0))
                                local hrpPos, hrpOn = cam:WorldToViewportPoint(hrp.Position)

                                local espObj = getBotESPObject(char, npc.Name)
                                if hrpOn and hrpPos.Z > 0 then
                                    local boxHeight = math.abs(headPos.Y - legPos.Y)
                                    local boxWidth = math.clamp(boxHeight * 0.65, 12, 400)
                                    local boxTopLeft = Vector2.new(hrpPos.X - boxWidth / 2, headPos.Y)

                                    espObj.box.Size = UDim2.new(0, boxWidth, 0, boxHeight)
                                    espObj.box.Position = UDim2.new(0, boxTopLeft.X, 0, boxTopLeft.Y)

                                    local distance = math.floor((cam.CFrame.Position - hrp.Position).Magnitude)
                                    espObj.dist.Text = string.format("[%d m]", distance)
                                    espObj.name.Text = "🤖 " .. tostring(npc.Name)

                                    if maxHp > 0 then
                                        local hpPct = math.clamp(hp / maxHp, 0, 1)
                                        espObj.hpFill.Size = UDim2.new(1, 0, hpPct, 0)
                                        espObj.hpFill.BackgroundColor3 = Color3.fromHSV(hpPct * 0.33, 0.9, 0.9)
                                    end

                                    espObj.box.Visible = true
                                else
                                    espObj.box.Visible = false
                                end
                            else
                                if char then removeBotESP(char, char) end
                            end
                        end

                        for botKey, obj in pairs(botEspObjects) do
                            if not activeBots[botKey] then
                                removeBotESP(botKey, botKey)
                            end
                        end
                    end
                end)))
            end
        else
            if espRenderConnection then
                espRenderConnection:Disconnect()
                espRenderConnection = nil
            end
        end
    end

    function ESP.isPlayerESPOn()
        return playerESPOn
    end

    function ESP.isBotESPOn()
        return botESPOn
    end

    function ESP.togglePlayer()
        playerESPOn = not playerESPOn
        State.PlayerESPEnabled = playerESPOn
        if playerESPOn then
            B.esp.Text = "👁️ มองทะลุ (ESP+เลือด): เปิด"
            B.esp.BackgroundColor3 = UIF.Theme.AccentGreen
            B.esp.TextColor3 = UIF.Theme.TextDark
        else
            B.esp.Text = "👁️ มองทะลุ (ESP+เลือด): ปิด"
            B.esp.BackgroundColor3 = UIF.Theme.CardBg
            B.esp.TextColor3 = UIF.Theme.Text
            espVisibilityCache = {}
            for p, obj in pairs(espObjects) do
                if obj and obj.box then obj.box:Destroy() end
            end
            espObjects = {}
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character then removePlayerESP(p, p.Character) end
            end
        end
        updateESPRenderLoop()
    end
    B.esp.Activated:Connect(ESP.togglePlayer)
    Cleanup.conn(Players.PlayerRemoving:Connect(function(p) removePlayerESP(p, p.Character) end))

    local function updateBotESPUI()
        if not B.botESP then return end
        if botESPOn then
            B.botESP.Text = "🤖 มองทะลุบอท (Bot ESP): เปิด"
            B.botESP.BackgroundColor3 = UIF.Theme.AccentGreen
            B.botESP.TextColor3 = UIF.Theme.TextDark
        else
            B.botESP.Text = "🤖 มองทะลุบอท (Bot ESP): ปิด"
            B.botESP.BackgroundColor3 = UIF.Theme.CardBg
            B.botESP.TextColor3 = UIF.Theme.Text
        end
    end

    function ESP.toggleBot()
        botESPOn = not botESPOn
        State.BotESPEnabled = botESPOn
        updateBotESPUI()
        if not botESPOn then
            for botKey, obj in pairs(botEspObjects) do
                if obj and obj.box then obj.box:Destroy() end
                if typeof(botKey) == "Instance" then
                    local hl = botKey:FindFirstChild("PrankBotESP")
                    if hl then hl:Destroy() end
                end
            end
            botEspObjects = {}
        end
        updateESPRenderLoop()
    end

    function ESP.setBotESP(enabled)
        if botESPOn ~= enabled then
            ESP.toggleBot()
        end
    end

    if B.botESP then
        B.botESP.Activated:Connect(ESP.toggleBot)
    end

    -- ============ Corpse ESP ============
    local CorpseFolder = Instance.new("Folder")
    CorpseFolder.Name = "CorpseESPFolder_" .. tostring(math.random(1000, 9999))
    CorpseFolder.Parent = env.UI.ScreenGui
    Cleanup.trackInstance(CorpseFolder, "UtilityCorpseFolder")

    local CorpseESPEnabled = false
    local function toggleCorpseESP()
        CorpseESPEnabled = not CorpseESPEnabled
        State.CorpseESPEnabled = CorpseESPEnabled
        if CorpseESPEnabled then
            B.corpse.Text = "💀 มองศพ (Loot Drops): เปิด"
            B.corpse.BackgroundColor3 = UIF.Theme.AccentGreen
            B.corpse.TextColor3 = UIF.Theme.TextDark
            task.spawn(function()
                while CorpseESPEnabled do
                    if not CorpseESPEnabled then break end
                    local descendants = workspace:GetDescendants()
                    local processCount = 0
                    for i = 1, #descendants do
                        if not CorpseESPEnabled then break end
                        local obj = descendants[i]
                        local isTarget = false; local targetPart = nil; local espName = ""; local displayName = "💀 ศพ (Loot)"

                        if obj:IsA("ProximityPrompt") then
                            local text = (obj.ActionText or "") .. " " .. (obj.ObjectText or "")
                            if string.find(text, "ค้นหา") or string.find(text, "Search") then
                                isTarget = true; targetPart = obj.Parent; espName = "Prompt_" .. tostring(targetPart)
                            end
                        elseif obj:IsA("Model") then
                            local hum = obj:FindFirstChild("Humanoid")
                            if hum and hum.Health <= 0 and obj ~= LocalPlayer.Character then
                                isTarget = true; targetPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head") or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                                espName = "Ragdoll_" .. obj.Name; displayName = "💀 ศพ: " .. obj.Name
                            else
                                local lName = string.lower(obj.Name)
                                if lName == "corpse" or lName == "deadbody" or lName == "lootdrop" or lName == "droppedloot" then
                                    isTarget = true; targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"); espName = "NamedObj_" .. tostring(obj)
                                end
                            end
                        elseif obj:IsA("BasePart") then
                            local lName = string.lower(obj.Name)
                            if lName == "corpse" or lName == "deadbody" or lName == "lootdrop" or lName == "droppedloot" then
                                isTarget = true; targetPart = obj; espName = "NamedObj_" .. tostring(obj)
                            end
                        end

                        if isTarget and targetPart and targetPart:IsA("BasePart") then
                            local uniqueID = espName .. tostring(math.floor(targetPart.Position.X))
                            if not CorpseFolder:FindFirstChild(uniqueID) then
                                local bb = Instance.new("BillboardGui")
                                bb.Name = uniqueID; bb.Adornee = targetPart; bb.Size = UDim2.new(0, 100, 0, 20); bb.StudsOffset = Vector3.new(0, 2, 0); bb.AlwaysOnTop = true
                                local txt = Instance.new("TextLabel", bb)
                                txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.Text = displayName; txt.TextColor3 = UIF.Theme.AccentPurple; txt.TextStrokeTransparency = 0; txt.Font = Enum.Font.GothamBold; txt.TextSize = 11
                                bb.Parent = CorpseFolder
                                local conn; conn = targetPart.AncestryChanged:Connect(function()
                                    if not targetPart:IsDescendantOf(workspace) then bb:Destroy(); if conn then conn:Disconnect() end end
                                end)
                                Cleanup.conn(conn)
                            end
                        end
                        processCount = processCount + 1
                        if processCount % 500 == 0 then task.wait() end
                    end
                    for i = 1, 5 do if not CorpseESPEnabled then break end task.wait(1) end
                end
            end)
        else
            B.corpse.Text = "💀 มองศพ (Loot Drops): ปิด"
            B.corpse.BackgroundColor3 = UIF.Theme.CardBg
            B.corpse.TextColor3 = UIF.Theme.Text
            CorpseFolder:ClearAllChildren()
        end
    end
    B.corpse.Activated:Connect(toggleCorpseESP)

    -- ============ Weapon ESP ============
    local WeaponESPEnabled = false
    local weaponEspLoop = nil
    local lastWeaponCheck = 0
    local function toggleWeaponESP()
        WeaponESPEnabled = not WeaponESPEnabled
        if WeaponESPEnabled then
            B.weapon.Text = "🔫 บอกชื่อปืน/ไอเทมคนอื่น: เปิด"
            B.weapon.BackgroundColor3 = UIF.Theme.AccentGreen
            B.weapon.TextColor3 = UIF.Theme.TextDark
            weaponEspLoop = Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("ESP", "WeaponESPLoop", function()
                local now = tick()
                if now - lastWeaponCheck < 0.15 then return end
                lastWeaponCheck = now

                for _, p in pairs(Players:GetPlayers()) do
                    local valid, _, char = Guard.validatePlayer(p, true)
                    if valid and not isSameTeam(p) then
                        local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                        if head then
                            local tool = char:FindFirstChildOfClass("Tool")
                            local toolName = tool and tool.Name or "มือเปล่า"
                            local bg = char:FindFirstChild("WeaponESP_UI")
                            if not bg then
                                bg = Instance.new("BillboardGui")
                                bg.Name = "WeaponESP_UI"; bg.Size = UDim2.new(0, 150, 0, 20); bg.StudsOffset = Vector3.new(0, 2.8, 0)
                                bg.AlwaysOnTop = true; bg.Adornee = head
                                local txt = Instance.new("TextLabel", bg)
                                txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.TextStrokeTransparency = 0
                                txt.Font = Enum.Font.GothamBold; txt.TextSize = 12; txt.Name = "WpnText"
                                bg.Parent = char
                            end
                            if tool then bg.WpnText.Text = "🔫 " .. toolName; bg.WpnText.TextColor3 = UIF.Theme.AccentRed
                            else bg.WpnText.Text = "✋ มือเปล่า"; bg.WpnText.TextColor3 = UIF.Theme.TextDim end
                        end
                    else
                        if p.Character then
                            local bg = p.Character:FindFirstChild("WeaponESP_UI"); if bg then bg:Destroy() end
                        end
                    end
                end
            end)))
        else
            B.weapon.Text = "🔫 บอกชื่อปืน/ไอเทมคนอื่น: ปิด"
            B.weapon.BackgroundColor3 = UIF.Theme.CardBg
            B.weapon.TextColor3 = UIF.Theme.Text
            if weaponEspLoop then weaponEspLoop:Disconnect(); weaponEspLoop = nil end
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character then local bg = p.Character:FindFirstChild("WeaponESP_UI"); if bg then bg:Destroy() end end
            end
        end
    end
    B.weapon.Activated:Connect(toggleWeaponESP)

    -- ============ Hit Sound ============
    State.HitSoundEnabled = false
    local lastHealthValues = {}
    local hitSoundConnection = nil

    local function playHitSound()
        pcall(function()
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://5153145838" -- เสียง hit ดังๆ
            sound.Volume = 0.8
            sound.PlayOnRemove = false
            sound.Parent = workspace
            sound:Play()
            game:GetService("Debris"):AddItem(sound, 0.5)
        end)
    end

    local function enableHitSound()
        State.HitSoundEnabled = true
        B.hitSound.Text = "🔊 เสียงตอนโดน (Hit Sound): เปิด"
        B.hitSound.BackgroundColor3 = UIF.Theme.AccentGreen
        B.hitSound.TextColor3 = UIF.Theme.TextDark
        
        hitSoundConnection = Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("ESP", "HitSoundLoop", function()
            for _, p in pairs(Players:GetPlayers()) do
                local valid, _, char = Guard.validatePlayer(p, false)
                if valid and not isSameTeam(p) then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        local currentHP = hum.Health
                        local lastHP = lastHealthValues[p]
                        if lastHP and currentHP < lastHP then
                            -- เลือดลด = โดนยิง
                            playHitSound()
                        end
                        lastHealthValues[p] = currentHP
                    end
                end
            end
        end)))
    end

    local function disableHitSound()
        State.HitSoundEnabled = false
        B.hitSound.Text = "🔊 เสียงตอนโดน (Hit Sound): ปิด"
        B.hitSound.BackgroundColor3 = UIF.Theme.CardBg
        B.hitSound.TextColor3 = UIF.Theme.Text
        if hitSoundConnection then hitSoundConnection:Disconnect(); hitSoundConnection = nil end
        lastHealthValues = {}
    end

    function ESP.setPlayerESP(enabled)
        if playerESPOn ~= enabled then
            ESP.togglePlayer()
        end
    end

    function ESP.setCorpseESP(enabled)
        if CorpseESPEnabled ~= enabled then
            toggleCorpseESP()
        end
    end

    function ESP.setWeaponESP(enabled)
        if WeaponESPEnabled ~= enabled then
            toggleWeaponESP()
        end
    end

    function ESP.setHitSound(enabled)
        if State.HitSoundEnabled ~= enabled then
            if enabled then enableHitSound() else disableHitSound() end
        end
    end

    B.hitSound.Activated:Connect(function()
        ESP.setHitSound(not State.HitSoundEnabled)
    end)

    -- cleanup: ลบทุกอย่างที่ esp สร้างไว้บนตัวละครและใน ScreenGui
    Cleanup.addCallback(function()
        for p, obj in pairs(espObjects) do
            if obj and obj.box then obj.box:Destroy() end
        end
        espObjects = {}
        for botKey, obj in pairs(botEspObjects) do
            if obj and obj.box then obj.box:Destroy() end
            if typeof(botKey) == "Instance" then
                local hl = botKey:FindFirstChild("PrankBotESP")
                if hl then hl:Destroy() end
            end
        end
        botEspObjects = {}
        for _, p in pairs(Players:GetPlayers()) do
            removePlayerESP(p, p.Character)
            if p.Character then
                local bg = p.Character:FindFirstChild("WeaponESP_UI"); if bg then bg:Destroy() end
            end
        end
        ESPFolder:ClearAllChildren()
        CorpseFolder:ClearAllChildren()
    end)

    return ESP
end

end)()
if type(__factory_esp) ~= "function" then error("Module esp did not return a factory function") end

-- ========== MODULE: aimbot ==========
local __factory_aimbot = (function()
return function(env)
    local Players = env.Players
    local RunService = env.RunService
    local UserInputService = env.UserInputService
    local VirtualUser = env.VirtualUser
    local LocalPlayer = env.LocalPlayer
    local Cleanup = env.Cleanup
    local UIF = env.UIF
    local Colors = env.Colors
    local State = env.State
    local isSameTeam = env.isSameTeam
    local buildRayFilter = env.buildRayFilter
    local Logger = env.Logger or { info = function() end, warn = function() end, error = function() end, detect = function() end }
    local Guard = env.Guard or { safeLoop = function(_, _, fn) return fn end, validatePlayer = function(p) return p and p.Character end, validateRaycast = function() return true end, validateCamera = function() return workspace.CurrentCamera end }

    local UI = env.UI
    local B = UI.buttons
    local S = UI.sliders
    local HK = UI.hotkeys

    local Aimbot = {}

    -- ============ FOV circle ============
    local minFOV, maxFOV = 30, 600

    local FOVGui = Instance.new("ScreenGui")
    FOVGui.Name = "FOVCircleUI_" .. tostring(math.random(100000, 999999))
    FOVGui.ResetOnSpawn = false
    FOVGui.IgnoreGuiInset = true
    FOVGui.Parent = env.getSafeParent()
    env.ProtectMyUI(FOVGui)
    Cleanup.trackInstance(FOVGui, "UtilityFOVUI")

    local FOVFrame = Instance.new("Frame", FOVGui)
    FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    FOVFrame.Size = UDim2.new(0, State.FOVRadius * 2, 0, State.FOVRadius * 2)
    FOVFrame.BackgroundTransparency = 1
    FOVFrame.Visible = false

    local FOVStroke = Instance.new("UIStroke", FOVFrame)
    FOVStroke.Color = Color3.fromRGB(255, 255, 255)
    FOVStroke.Thickness = 1.2
    Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1, 0)

    local function setFOVRadius(radius)
        State.FOVRadius = radius
        FOVFrame.Size = UDim2.new(0, radius * 2, 0, radius * 2)
    end

    local function updateFOVSlider(input)
        local sizeX = math.max(S.fov.frame.AbsoluteSize.X, 1)
        local relativeX = math.clamp(input.Position.X - S.fov.frame.AbsolutePosition.X, 0, sizeX)
        local percentage = relativeX / sizeX
        setFOVRadius(math.floor(minFOV + ((maxFOV - minFOV) * percentage)))
        S.fov.fill.Size = UDim2.new(percentage, 0, 1, 0)
        S.fov.text.Text = "⭕ ขนาดวง FOV: " .. State.FOVRadius
    end

    S.fov.btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            State.draggingFOV = true; updateFOVSlider(input)
        end
    end)
    Cleanup.conn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then State.draggingFOV = false end
    end))
    Cleanup.conn(UserInputService.InputChanged:Connect(function(input)
        if State.draggingFOV and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateFOVSlider(input) end
    end))
    
    -- [อัปเดต] ล็อคเป้าให้อยู่กลางจอเสมอสำหรับมือถือ ไม่ให้เลื่อนตามนิ้วที่ทัช
    local activePointer = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
    Cleanup.conn(UserInputService.InputChanged:Connect(function(input, processed)
        if processed then return end
        -- ให้อัปเดตตามเมาส์เฉพาะเวลาเล่นบน PC เท่านั้น
        if not UserInputService.TouchEnabled and input.UserInputType == Enum.UserInputType.MouseMovement then
            activePointer = Vector2.new(input.Position.X, input.Position.Y)
        end
    end))

    Cleanup.conn(RunService.RenderStepped:Connect(Guard.safeLoop("Aimbot", "FOVCircleRender", function()
        local cam = Guard.validateCamera() or env.Camera
        if cam then
            -- บังคับให้จุดศูนย์กลางและวง FOV อยู่ตรงกลางจอ 100% ตลอดเวลาสำหรับมือถือ
            if UserInputService.TouchEnabled then
                activePointer = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
            end
            
            if State.FOVEnabled and FOVFrame.Visible then
                FOVFrame.Position = UDim2.new(0, activePointer.X, 0, activePointer.Y)
            end
        end
    end)))

    local function updateFOVUI()
        if State.FOVEnabled then
            B.fov.Text = "⭕ วงกลมล็อคเป้า (FOV): เปิด"
            B.fov.BackgroundColor3 = UIF.Theme.AccentGreen
            B.fov.TextColor3 = UIF.Theme.TextDark
            FOVFrame.Visible = true
        else
            B.fov.Text = "⭕ วงกลมล็อคเป้า (FOV): ปิด"
            B.fov.BackgroundColor3 = UIF.Theme.CardBg
            B.fov.TextColor3 = UIF.Theme.Text
            FOVFrame.Visible = false
        end
    end

    function Aimbot.setFOV(enabled)
        State.FOVEnabled = enabled
        updateFOVUI()
    end

    B.fov.Activated:Connect(function()
        State.FOVEnabled = not State.FOVEnabled
        updateFOVUI()
    end)

    function Aimbot.enableFOV()
        Aimbot.setFOV(true)
    end

    -- ============ ตัวเลือกเล็ง ============
    local function updateAimPartUI()
        if State.AimTargetPart == "Head" then
            B.aimPart.Text = "🎯 เล็งเป้า: หัว (คลิกสลับ)"
            B.aimPart.BackgroundColor3 = UIF.Theme.CardBg
            B.aimPart.TextColor3 = UIF.Theme.Text
        else
            State.AimTargetPart = "HumanoidRootPart"
            B.aimPart.Text = "🎯 เล็งเป้า: ลำตัว (คลิกสลับ)"
            B.aimPart.BackgroundColor3 = UIF.Theme.CardBg
            B.aimPart.TextColor3 = UIF.Theme.Text
        end
    end

    function Aimbot.setAimPart(part)
        State.AimTargetPart = part
        updateAimPartUI()
    end

    B.aimPart.Activated:Connect(function()
        if State.AimTargetPart == "HumanoidRootPart" then
            State.AimTargetPart = "Head"
        else
            State.AimTargetPart = "HumanoidRootPart"
        end
        updateAimPartUI()
    end)

    function Aimbot.setAimPartHead()
        Aimbot.setAimPart("Head")
    end

    local function updateWallCheckUI()
        if State.WallCheckEnabled then
            B.wallCheck.Text = "🧱 ตรวจจับกำแพง: เปิด (ไม่ทะลุ)"
            B.wallCheck.BackgroundColor3 = UIF.Theme.AccentGreen
            B.wallCheck.TextColor3 = UIF.Theme.TextDark
        else
            B.wallCheck.Text = "🧱 ตรวจจับกำแพง: ปิด (ยิงทะลุ)"
            B.wallCheck.BackgroundColor3 = UIF.Theme.CardBg
            B.wallCheck.TextColor3 = UIF.Theme.Text
        end
    end

    function Aimbot.setWallCheck(enabled)
        State.WallCheckEnabled = enabled
        updateWallCheckUI()
    end

    B.wallCheck.Activated:Connect(function()
        State.WallCheckEnabled = not State.WallCheckEnabled
        updateWallCheckUI()
    end)

    function Aimbot.enableWallCheck()
        Aimbot.setWallCheck(true)
    end

    local function updatePredictionUI()
        if State.PredictionEnabled then
            B.prediction.Text = "🔮 ยิงดักหน้า (Prediction): เปิด"
            B.prediction.BackgroundColor3 = UIF.Theme.AccentGreen
            B.prediction.TextColor3 = UIF.Theme.TextDark
        else
            B.prediction.Text = "🔮 ยิงดักหน้า (Prediction): ปิด"
            B.prediction.BackgroundColor3 = UIF.Theme.CardBg
            B.prediction.TextColor3 = UIF.Theme.Text
        end
    end

    function Aimbot.setPrediction(enabled)
        State.PredictionEnabled = enabled
        updatePredictionUI()
    end

    B.prediction.Activated:Connect(function()
        State.PredictionEnabled = not State.PredictionEnabled
        updatePredictionUI()
    end)

    local function updatePredSlider(input)
        local sizeX = math.max(S.pred.frame.AbsoluteSize.X, 1)
        local relativeX = math.clamp(input.Position.X - S.pred.frame.AbsolutePosition.X, 0, sizeX)
        local percentage = relativeX / sizeX
        State.PredictionAmt = math.floor((0.01 + (0.5 - 0.01) * percentage) * 100) / 100
        S.pred.fill.Size = UDim2.new(percentage, 0, 1, 0)
        S.pred.text.Text = "🔮 ค่าดักหน้ากระสุน: " .. tostring(State.PredictionAmt)
    end

    S.pred.btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            State.draggingPred = true; updatePredSlider(input)
        end
    end)
    Cleanup.conn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then State.draggingPred = false end
    end))
    Cleanup.conn(UserInputService.InputChanged:Connect(function(input)
        if State.draggingPred and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updatePredSlider(input) end
    end))

    local function updateAutoShootUI()
        if State.AutoShootEnabled then
            B.autoShoot.Text = "🔫 ออโต้ยิงเมื่อล็อคเป้า: เปิด"
            B.autoShoot.BackgroundColor3 = UIF.Theme.AccentGreen
            B.autoShoot.TextColor3 = UIF.Theme.TextDark
        else
            B.autoShoot.Text = "🔫 ออโต้ยิงเมื่อล็อคเป้า: ปิด"
            B.autoShoot.BackgroundColor3 = UIF.Theme.CardBg
            B.autoShoot.TextColor3 = UIF.Theme.Text
        end
    end

    function Aimbot.setAutoShoot(enabled)
        State.AutoShootEnabled = enabled
        updateAutoShootUI()
    end

    B.autoShoot.Activated:Connect(function()
        State.AutoShootEnabled = not State.AutoShootEnabled
        updateAutoShootUI()
    end)

    -- ============ 🤖 Bot / NPC Targeting ============
    local function updateBotLockUI()
        if not B.botLock then return end
        if State.TargetBotsEnabled then
            B.botLock.Text = "🤖 ล็อคเป้าบอท/NPC (Bot Lock): เปิด"
            B.botLock.BackgroundColor3 = UIF.Theme.AccentGreen
            B.botLock.TextColor3 = UIF.Theme.TextDark
        else
            B.botLock.Text = "🤖 ล็อคเป้าบอท/NPC (Bot Lock): ปิด"
            B.botLock.BackgroundColor3 = UIF.Theme.CardBg
            B.botLock.TextColor3 = UIF.Theme.Text
        end
    end

    function Aimbot.setTargetBots(enabled)
        State.TargetBotsEnabled = enabled
        updateBotLockUI()
    end

    function Aimbot.toggleTargetBots()
        State.TargetBotsEnabled = not State.TargetBotsEnabled
        updateBotLockUI()
    end

    if B.botLock then
        B.botLock.Activated:Connect(Aimbot.toggleTargetBots)
    end

    -- ============ 🧠 Smart Bone Priority ============
    local function updateSmartBoneUI()
        if not B.smartBone then return end
        if State.SmartBoneEnabled then
            B.smartBone.Text = "🧠 สลับจุดเล็งอัจฉริยะ (Smart Bone): เปิด"
            B.smartBone.BackgroundColor3 = UIF.Theme.AccentGreen
            B.smartBone.TextColor3 = UIF.Theme.TextDark
        else
            B.smartBone.Text = "🧠 สลับจุดเล็งอัจฉริยะ (Smart Bone): ปิด"
            B.smartBone.BackgroundColor3 = UIF.Theme.CardBg
            B.smartBone.TextColor3 = UIF.Theme.Text
        end
    end

    function Aimbot.setSmartBone(enabled)
        State.SmartBoneEnabled = enabled
        updateSmartBoneUI()
    end

    if B.smartBone then
        B.smartBone.Activated:Connect(function()
            State.SmartBoneEnabled = not State.SmartBoneEnabled
            updateSmartBoneUI()
        end)
    end

    -- ============ 🏹 Ballistics Engine & Bullet Drop ============
    local minBulletSpeed, maxBulletSpeed = 100, 5000
    State.BulletSpeed = State.BulletSpeed or 1000

    local function updateBallisticsUI()
        if not B.ballistics then return end
        if State.BallisticsEnabled then
            B.ballistics.Text = "🏹 ชดเชยวิถีกระสุนตก (Ballistics Drop): เปิด"
            B.ballistics.BackgroundColor3 = UIF.Theme.AccentGreen
            B.ballistics.TextColor3 = UIF.Theme.TextDark
        else
            B.ballistics.Text = "🏹 ชดเชยวิถีกระสุนตก (Ballistics Drop): ปิด"
            B.ballistics.BackgroundColor3 = UIF.Theme.CardBg
            B.ballistics.TextColor3 = UIF.Theme.Text
        end
    end

    function Aimbot.setBallistics(enabled)
        State.BallisticsEnabled = enabled
        updateBallisticsUI()
    end

    if B.ballistics then
        B.ballistics.Activated:Connect(function()
            State.BallisticsEnabled = not State.BallisticsEnabled
            updateBallisticsUI()
        end)
    end

    function Aimbot.setBulletSpeed(speed)
        State.BulletSpeed = speed
        if S.bulletSpeed then
            local pct = math.clamp((speed - minBulletSpeed) / (maxBulletSpeed - minBulletSpeed), 0, 1)
            S.bulletSpeed.fill.Size = UDim2.new(pct, 0, 1, 0)
            S.bulletSpeed.text.Text = tostring(math.floor(speed))
            S.bulletSpeed.title.Text = "ความเร็วกระสุน (Bullet Speed): " .. tostring(math.floor(speed))
        end
    end

    if S.bulletSpeed then
        local function updateBulletSpeedSlider(input)
            local sizeX = math.max(S.bulletSpeed.frame.AbsoluteSize.X, 1)
            local relativeX = math.clamp(input.Position.X - S.bulletSpeed.frame.AbsolutePosition.X, 0, sizeX)
            local percentage = relativeX / sizeX
            local val = math.floor(minBulletSpeed + ((maxBulletSpeed - minBulletSpeed) * percentage))
            State.BulletSpeed = val
            S.bulletSpeed.fill.Size = UDim2.new(percentage, 0, 1, 0)
            S.bulletSpeed.text.Text = tostring(val)
            S.bulletSpeed.title.Text = "ความเร็วกระสุน (Bullet Speed): " .. tostring(val)
        end

        S.bulletSpeed.btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                State.draggingBulletSpeed = true
                updateBulletSpeedSlider(input)
            end
        end)
        Cleanup.conn(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                State.draggingBulletSpeed = false
            end
        end))
        Cleanup.conn(UserInputService.InputChanged:Connect(function(input)
            if State.draggingBulletSpeed and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateBulletSpeedSlider(input)
            end
        end))
    end

    -- ============ Aimbot engine ============
    local aimbotConnection = nil
    local lastAutoShoot = 0

    local function ProcessAutoShoot()
        if State.AutoShootEnabled then
            local jitter = (type(State._shootJitter) == "number") and State._shootJitter or 0
            local threshold = 0.048 + jitter
            if tick() - lastAutoShoot > threshold then
                lastAutoShoot = tick()
                if mouse1click then
                    mouse1click()
                else
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(0, 0))
                end
            end
        end
    end

    -- ============ 🎯 Smart Bone & Ballistics Math Engine ============
    local BONE_PRIORITIES = {
        "Head",
        "UpperTorso",
        "Torso",
        "HumanoidRootPart",
        "RightUpperArm",
        "RightHand",
        "LeftUpperArm",
        "LeftHand",
        "RightUpperLeg",
        "LeftUpperLeg"
    }

    local function getBestTargetPart(char, fallbackHrp, camPos)
        if not char then return fallbackHrp end

        if not State.SmartBoneEnabled then
            return char:FindFirstChild(State.AimTargetPart) or fallbackHrp
        end

        if State.WallCheckEnabled and camPos then
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = buildRayFilter(LocalPlayer.Character, char)
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.IgnoreWater = true

            for _, boneName in ipairs(BONE_PRIORITIES) do
                local part = char:FindFirstChild(boneName)
                if part and part:IsA("BasePart") then
                    local hit = workspace:Raycast(camPos, part.Position - camPos, rayParams)
                    if not hit then
                        return part
                    end
                end
            end
        end

        for _, boneName in ipairs(BONE_PRIORITIES) do
            local part = char:FindFirstChild(boneName)
            if part and part:IsA("BasePart") then
                return part
            end
        end

        return fallbackHrp
    end

    local function calculateAimPosition(targetPartObj, originPos)
        local basePos = targetPartObj.Position
        local vel = targetPartObj.AssemblyLinearVelocity or Vector3.zero
        if vel.X ~= vel.X then vel = Vector3.zero end

        local finalPos = basePos

        if State.BallisticsEnabled then
            local bulletSpeed = math.max(State.BulletSpeed or 1000, 100)
            local dist = (basePos - originPos).Magnitude
            local timeOfFlight = dist / bulletSpeed
            local gravity = 196.2 
            finalPos = finalPos + (vel * timeOfFlight)
            local dropCompensation = 0.5 * gravity * (timeOfFlight ^ 2)
            finalPos = finalPos + Vector3.new(0, dropCompensation, 0)
        elseif State.PredictionEnabled then
            finalPos = finalPos + (vel * State.PredictionAmt)
        end

        return finalPos
    end

    local function stopAimbot()
        State.isAimbotting = false
        State.hardLockedPlayer = nil
        State.currentTarget = nil
        if aimbotConnection then aimbotConnection:Disconnect(); aimbotConnection = nil end
        if HK.aim then
            if HK.aim.setState then
                HK.aim.setState(false, "ระบบล็อคเป้า Aimbot: ปิด")
            elseif HK.aim.title then
                HK.aim.title.Text = "ระบบล็อคเป้า Aimbot: ปิด"
                HK.aim.card.BackgroundColor3 = UIF.Theme.CardBg
            end
        end
        if HK.lock then
            if HK.lock.setState then
                HK.lock.setState(false, "ล็อคเป้าหมายเจาะจง: ปิด")
            elseif HK.lock.title then
                HK.lock.title.Text = "ล็อคเป้าหมายเจาะจง: ปิด"
                HK.lock.card.BackgroundColor3 = UIF.Theme.CardBg
            end
        end
    end

    local isSameTeam = env.isSameTeam or function() return false end
    local function isTargetEnemy(target)
        if not target then return false end
        return not isSameTeam(target)
    end

    local function getAllValidTargets()
        local targets = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and isTargetEnemy(p) then
                local char = env.Scanner.getCharacter(p)
                local hrp = env.Scanner.getRootPart(p)
                local isAlive = env.Scanner.isAlive(p)
                if char and hrp and isAlive then
                    targets[#targets + 1] = p
                end
            end
        end
        if State.TargetBotsEnabled and env.Scanner and env.Scanner.getNPCs then
            local npcs = env.Scanner.getNPCs()
            for _, npc in ipairs(npcs) do
                local char = env.Scanner.getCharacter(npc)
                local hrp = env.Scanner.getRootPart(npc)
                local isAlive = env.Scanner.isAlive(npc)
                if char and hrp and isAlive and isTargetEnemy(npc) and isTargetEnemy(char) then
                    targets[#targets + 1] = npc
                end
            end
        end
        return targets
    end

    function Aimbot.toggle()
        if State.isAimbotting then
            stopAimbot()
            return
        end
        State.isAimbotting = true
        if HK.aim then
            if HK.aim.setState then
                HK.aim.setState(true, "ระบบล็อคเป้า Aimbot: เปิด")
            elseif HK.aim.title then
                HK.aim.title.Text = "ระบบล็อคเป้า Aimbot: เปิด"
                HK.aim.card.BackgroundColor3 = UIF.Theme.AccentGreen
            end
        end

        aimbotConnection = Cleanup.conn(RunService.RenderStepped:Connect(Guard.safeLoop("Aimbot", "AimbotTrack", function()
            local cam = Guard.validateCamera() or env.Camera
            if not cam then return end

            if State.hardLockedPlayer then
                local hp = State.hardLockedPlayer
                local char = env.Scanner.getCharacter(hp)
                local hrp = env.Scanner.getRootPart(hp)
                local isAlive = env.Scanner.isAlive(hp)
                local valid = (char and hrp and isAlive)
                if valid and isTargetEnemy(hp) then
                    local targetPartObj = getBestTargetPart(char, hrp, cam.CFrame.Position)

                    local canAim = true
                    if State.WallCheckEnabled then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = buildRayFilter(LocalPlayer.Character, char)
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        rayParams.IgnoreWater = true
                        if workspace:Raycast(cam.CFrame.Position, targetPartObj.Position - cam.CFrame.Position, rayParams) ~= nil then
                            canAim = false
                        end
                    end

                    if canAim then
                        local aimPos = calculateAimPosition(targetPartObj, cam.CFrame.Position)
                        cam.CFrame = CFrame.new(cam.CFrame.Position, aimPos)
                        ProcessAutoShoot()
                    end
                    return
                else
                    State.hardLockedPlayer = nil
                end
            end

            local closestTarget = nil
            local shortestDistance = math.huge

            for _, t in ipairs(getAllValidTargets()) do
                local char = env.Scanner.getCharacter(t)
                local hrp = env.Scanner.getRootPart(t)
                local partToAim = getBestTargetPart(char, hrp, cam.CFrame.Position)
                local pos, onScreen = cam:WorldToViewportPoint(partToAim.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - activePointer).Magnitude
                    local isValidTarget = true

                    if State.FOVEnabled and dist > State.FOVRadius then isValidTarget = false end

                    if State.WallCheckEnabled and isValidTarget then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = buildRayFilter(LocalPlayer.Character, char)
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        rayParams.IgnoreWater = true
                        if workspace:Raycast(cam.CFrame.Position, partToAim.Position - cam.CFrame.Position, rayParams) ~= nil then
                            isValidTarget = false
                        end
                    end

                    if isValidTarget and dist < shortestDistance then
                        closestTarget = t
                        shortestDistance = dist
                    end
                end
            end
            State.currentTarget = closestTarget

            if State.currentTarget then
                local targetChar = env.Scanner.getCharacter(State.currentTarget)
                if targetChar then
                    local targetHrp = env.Scanner.getRootPart(State.currentTarget) or targetChar:FindFirstChild("HumanoidRootPart")
                    local targetPartObj = getBestTargetPart(targetChar, targetHrp, cam.CFrame.Position)
                    if targetPartObj then
                        local aimPos = calculateAimPosition(targetPartObj, cam.CFrame.Position)
                        cam.CFrame = CFrame.new(cam.CFrame.Position, aimPos)
                        ProcessAutoShoot()
                    end
                end
            end
        end)))
    end

    function Aimbot.toggleHardLock()
        if State.isAimbotting then
            if State.hardLockedPlayer then
                State.hardLockedPlayer = nil
                if HK.lock then
                    if HK.lock.setState then
                        HK.lock.setState(false, "ล็อคเป้าหมายเจาะจง: ปิด")
                    elseif HK.lock.title then
                        HK.lock.title.Text = "ล็อคเป้าหมายเจาะจง: ปิด"
                        HK.lock.card.BackgroundColor3 = UIF.Theme.CardBg
                    end
                end
            elseif State.currentTarget then
                State.hardLockedPlayer = State.currentTarget
                local targetName = env.Scanner.getName(State.hardLockedPlayer)
                if HK.lock then
                    if HK.lock.setState then
                        HK.lock.setState(true, "ล็อคเป้าหมายเจาะจง: เปิด (" .. targetName .. ")")
                    elseif HK.lock.title then
                        HK.lock.title.Text = "ล็อคเป้าหมายเจาะจง: เปิด (" .. targetName .. ")"
                        HK.lock.card.BackgroundColor3 = UIF.Theme.AccentGreen
                    end
                end
            end
        end
    end

    HK.aim.btn.Activated:Connect(Aimbot.toggle)
    HK.lock.btn.Activated:Connect(Aimbot.toggleHardLock)

    -- ============ Silent Aim ============
    State.SilentAimEnabled = false
    local originalNamecall = nil

    local function findClosestPlayer()
        local closest = nil
        local shortest = math.huge
        
        for _, t in ipairs(getAllValidTargets()) do
            local char = env.Scanner.getCharacter(t)
            if char then
                local part = char:FindFirstChild(State.AimTargetPart) or env.Scanner.getRootPart(t) or char:FindFirstChild("HumanoidRootPart")
                if part then
                    local pos, onScreen = env.Camera:WorldToViewportPoint(part.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - activePointer).Magnitude
                        if State.FOVEnabled and dist > State.FOVRadius then continue end
                        if dist < shortest then
                            closest = t
                            shortest = dist
                        end
                    end
                end
            end
        end
        return closest
    end

    local function enableSilentAim()
        State.SilentAimEnabled = true
        B.silentAim.Text = "🎯 Silent Aim (ยิงทะลุ): เปิด"
        B.silentAim.BackgroundColor3 = UIF.Theme.AccentGreen
        B.silentAim.TextColor3 = UIF.Theme.TextDark
        
        if not originalNamecall then
            originalNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
                local method = getnamecallmethod()
                if method == "Raycast" and State.SilentAimEnabled then
                    local args = {...}
                    local closest = findClosestPlayer()
                    if closest and closest.Character then
                        local targetPart = closest.Character:FindFirstChild(State.AimTargetPart) or closest.Character:FindFirstChild("HumanoidRootPart")
                        if targetPart then
                            local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position
                            if myPos then
                                args[2] = (targetPart.Position - myPos)
                                return originalNamecall(self, table.unpack(args))
                            end
                        end
                    end
                end
                return originalNamecall(self, ...)
            end))
        end
    end

    local function disableSilentAim()
        State.SilentAimEnabled = false
        B.silentAim.Text = "🎯 Silent Aim (ยิงทะลุ): ปิด"
        B.silentAim.BackgroundColor3 = UIF.Theme.CardBg
        B.silentAim.TextColor3 = UIF.Theme.Text
    end

    function Aimbot.setSilentAim(enabled)
        if enabled then enableSilentAim() else disableSilentAim() end
    end

    B.silentAim.Activated:Connect(function()
        if State.SilentAimEnabled then
            disableSilentAim()
        else
            enableSilentAim()
        end
    end)

    -- ============ Tracers ============
    local TracerFolder = Instance.new("Frame")
    TracerFolder.Name = "TracersFolder"
    TracerFolder.Size = UDim2.new(1, 0, 1, 0)
    TracerFolder.BackgroundTransparency = 1
    TracerFolder.BorderSizePixel = 0
    TracerFolder.Parent = UI.ScreenGui
    local tracerLines = {}

    local hasDrawing = pcall(function() return Drawing and Drawing.new end) and Drawing ~= nil and Drawing.new ~= nil

    local function getTracerLine(target)
        if not tracerLines[target] then
            if hasDrawing then
                local ok, line = pcall(function()
                    local l = Drawing.new("Line")
                    l.Thickness = math.clamp(State.TracerThickness or 1.0, 1.0, 6.0)
                    l.Color = UIF.Theme.AccentRed
                    l.Transparency = 1
                    l.Visible = false
                    return l
                end)
                if ok and line then
                    tracerLines[target] = { isDrawing = true, line = line }
                    return tracerLines[target]
                end
            end

            local line = Instance.new("Frame")
            line.Name = (target.Name or "Target") .. "_Tracer"
            line.AnchorPoint = Vector2.new(0.5, 0.5)
            line.BackgroundColor3 = UIF.Theme.AccentRed
            line.BorderSizePixel = 0; line.ZIndex = 1; line.Visible = false
            line.Parent = TracerFolder
            tracerLines[target] = { isDrawing = false, line = line }
        end
        return tracerLines[target]
    end

    local function destroyTracerItem(item)
        if not item then return end
        if item.isDrawing and item.line then
            pcall(function() item.line.Visible = false; item.line:Remove() end)
        elseif item.line then
            pcall(function() item.line:Destroy() end)
        end
    end

    local function clearTracers()
        for target, item in pairs(tracerLines) do
            destroyTracerItem(item)
        end
        tracerLines = {}
    end

    function Aimbot.toggleTracers()
        State.TracersEnabled = not State.TracersEnabled
        if State.TracersEnabled then
            B.tracers.Text = "🧶 เส้นชี้เป้า (Tracers): เปิด"
            B.tracers.BackgroundColor3 = UIF.Theme.AccentGreen
            B.tracers.TextColor3 = UIF.Theme.TextDark
        else
            B.tracers.Text = "🧶 เส้นชี้เป้า (Tracers): ปิด"
            B.tracers.BackgroundColor3 = UIF.Theme.CardBg
            B.tracers.TextColor3 = UIF.Theme.Text
            clearTracers()
        end
    end

    function Aimbot.setTracers(enabled)
        if State.TracersEnabled ~= enabled then
            Aimbot.toggleTracers()
        end
    end
    B.tracers.Activated:Connect(Aimbot.toggleTracers)

    B.tracerMode.Activated:Connect(function()
        if State.TracerMode == "All" then
            State.TracerMode = "Closest"
            B.tracerMode.Text = "🧶 โหมดเส้น: คนที่ถูกล็อค (คลิกสลับ)"
            B.tracerMode.BackgroundColor3 = UIF.Theme.CardBg
            B.tracerMode.TextColor3 = UIF.Theme.Text
        else
            State.TracerMode = "All"
            B.tracerMode.Text = "🧶 โหมดเส้น: ทุกคน (คลิกสลับ)"
            B.tracerMode.BackgroundColor3 = UIF.Theme.CardBg
            B.tracerMode.TextColor3 = UIF.Theme.Text
        end
    end)

    local minThickness = 1.0
    local maxThickness = 6.0

    local function setTracerThickness(thickness)
        State.TracerThickness = math.clamp(thickness, minThickness, maxThickness)
    end

    local function updateTracerThicknessSlider(input)
        local sizeX = math.max(S.tracerThickness.frame.AbsoluteSize.X, 1)
        local relativeX = math.clamp(input.Position.X - S.tracerThickness.frame.AbsolutePosition.X, 0, sizeX)
        local percentage = math.clamp(relativeX / sizeX, 0, 1)
        local rawThickness = minThickness + ((maxThickness - minThickness) * percentage)
        local thickness = math.clamp(math.floor(rawThickness * 2 + 0.5) / 2, minThickness, maxThickness)
        setTracerThickness(thickness)
        S.tracerThickness.fill.Size = UDim2.new(percentage, 0, 1, 0)
        S.tracerThickness.text.Text = string.format("%.1f px", thickness)
        S.tracerThickness.title.Text = "ขนาดความหนาเส้น (Thickness): " .. string.format("%.1f px", thickness)
    end

    S.tracerThickness.btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            State.draggingTracerThickness = true
            updateTracerThicknessSlider(input)
        end
    end)
    Cleanup.conn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            State.draggingTracerThickness = false
        end
    end))
    Cleanup.conn(UserInputService.InputChanged:Connect(function(input)
        if State.draggingTracerThickness and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateTracerThicknessSlider(input)
        end
    end))

    -- ============ Stats panel ============
    local StatsPanel = Instance.new("Frame")
    StatsPanel.Size = UDim2.new(0, 200, 0, 130)
    StatsPanel.Position = UDim2.new(0.05, 0, 0.4, 0)
    StatsPanel.BackgroundColor3 = UIF.Theme.Bg
    StatsPanel.BorderSizePixel = 0
    StatsPanel.Visible = false; StatsPanel.Active = true; StatsPanel.Parent = UI.ScreenGui
    Instance.new("UICorner", StatsPanel).CornerRadius = UDim.new(0, 8)
    local statStroke = Instance.new("UIStroke", StatsPanel)
    statStroke.Color = UIF.Theme.CardBorder
    statStroke.Thickness = 1

    local statDrag, statInput, statDragStart, statStartPos
    StatsPanel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            statDrag = true; statDragStart = input.Position; statStartPos = StatsPanel.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then statDrag = false end end)
        end
    end)
    Cleanup.conn(UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then statInput = input end
        if input == statInput and statDrag then
            local delta = input.Position - statDragStart
            StatsPanel.Position = UDim2.new(statStartPos.X.Scale, statStartPos.X.Offset + delta.X, statStartPos.Y.Scale, statStartPos.Y.Offset + delta.Y)
        end
    end))

    UIF.label(StatsPanel, { Size = UDim2.new(1, 0, 0, 25), Text = "🎯 เป้าหมาย Aimbot", TextColor3 = UIF.Theme.AccentBlue, Font = Enum.Font.GothamBold, TextSize = 13 })
    local StatName = UIF.label(StatsPanel, { Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 10, 0, 30), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UIF.Theme.Text, Text = "" })
    local StatHP = UIF.label(StatsPanel, { Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 10, 0, 50), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UIF.Theme.AccentGreen, Text = "" })
    local StatWeapon = UIF.label(StatsPanel, { Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 10, 0, 70), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UIF.Theme.AccentPink, Text = "" })
    local StatDist = UIF.label(StatsPanel, { Size = UDim2.new(1, -10, 0, 20), Position = UDim2.new(0, 10, 0, 90), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = UIF.Theme.AccentYellow, Text = "" })

    local function updateStatsUI()
        if State.StatsEnabled then
            B.stats.Text = "📊 ส่องข้อมูลเป้าหมาย: เปิด"
            B.stats.BackgroundColor3 = UIF.Theme.AccentGreen
            B.stats.TextColor3 = UIF.Theme.TextDark
            StatsPanel.Visible = true
        else
            B.stats.Text = "📊 ส่องข้อมูลเป้าหมาย: ปิด"
            B.stats.BackgroundColor3 = UIF.Theme.CardBg
            B.stats.TextColor3 = UIF.Theme.Text
            StatsPanel.Visible = false
        end
    end

    function Aimbot.setStats(enabled)
        State.StatsEnabled = enabled
        updateStatsUI()
    end

    local function toggleStats()
        State.StatsEnabled = not State.StatsEnabled
        updateStatsUI()
    end
    B.stats.Activated:Connect(toggleStats)

    -- ============ เตือนภัยกระบอกปืน ============
    local WarnGui = Instance.new("ScreenGui", env.getSafeParent())
    WarnGui.Name = "AntiAimWarningUI_" .. tostring(math.random(100000, 999999))
    local WarnText = Instance.new("TextLabel", WarnGui)
    WarnText.Size = UDim2.new(1, 0, 0, 100); WarnText.Position = UDim2.new(0, 0, 0.15, 0)
    WarnText.BackgroundTransparency = 1; WarnText.TextColor3 = UIF.Theme.AccentRed
    WarnText.TextStrokeColor3 = Color3.new(0, 0, 0); WarnText.TextStrokeTransparency = 0
    WarnText.TextSize = 28; WarnText.Font = Enum.Font.GothamBold; WarnText.Text = ""
    WarnText.Visible = false
    env.ProtectMyUI(WarnGui)
    Cleanup.trackInstance(WarnGui, "UtilityWarningUI")

    local function updateWarningUI()
        if State.GunWarningEnabled then
            B.warning.Text = "⚠️ เตือนภัยกระบอกปืน: เปิด"
            B.warning.BackgroundColor3 = UIF.Theme.AccentGreen
            B.warning.TextColor3 = UIF.Theme.TextDark
        else
            B.warning.Text = "⚠️ เตือนภัยกระบอกปืน: ปิด"
            B.warning.BackgroundColor3 = UIF.Theme.CardBg
            B.warning.TextColor3 = UIF.Theme.Text
            WarnText.Visible = false
            State.AimingPlayers = {}
        end
    end

    function Aimbot.setWarning(enabled)
        State.GunWarningEnabled = enabled
        updateWarningUI()
    end

    local function toggleWarning()
        State.GunWarningEnabled = not State.GunWarningEnabled
        updateWarningUI()
    end
    B.warning.Activated:Connect(toggleWarning)

    -- ============ Render รวม: Stats + Tracers ============
    Cleanup.conn(RunService.RenderStepped:Connect(Guard.safeLoop("Aimbot", "StatsTracersRender", function()
        local cam = Guard.validateCamera() or env.Camera
        if not cam then return end

        local displayTarget = nil

        if State.hardLockedPlayer then
            local isAlive = env.Scanner.isAlive(State.hardLockedPlayer)
            if isAlive and isTargetEnemy(State.hardLockedPlayer) then
                displayTarget = State.hardLockedPlayer
            else
                State.hardLockedPlayer = nil
            end
        else
            local shortestDistance = math.huge
            for _, t in ipairs(getAllValidTargets()) do
                local hrp = env.Scanner.getRootPart(t)
                if hrp then
                    local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - activePointer).Magnitude
                        local isValidTarget = true
                        if State.FOVEnabled and dist > State.FOVRadius then isValidTarget = false end

                        if isValidTarget and dist < shortestDistance then
                            displayTarget = t
                            shortestDistance = dist
                        end
                    end
                end
            end
        end

        if State.StatsEnabled then
            if displayTarget then
                local char = env.Scanner.getCharacter(displayTarget)
                local hum = char and char:FindFirstChild("Humanoid")
                local tool = char and char:FindFirstChildOfClass("Tool")
                local targetName = env.Scanner.getName(displayTarget)
                local hp, maxHp = env.Scanner.getHealth(displayTarget)

                StatName.Text = "👤 ชื่อ: " .. tostring(targetName)
                StatHP.Text = "❤️ เลือด: " .. math.floor(hp) .. " / " .. math.floor(maxHp)
                StatWeapon.Text = "🔫 อาวุธ: " .. (tool and tool.Name or "มือเปล่า")
                local hrp = env.Scanner.getRootPart(displayTarget)
                if hrp then
                    StatDist.Text = "📏 ระยะห่าง: " .. math.floor((cam.CFrame.Position - hrp.Position).Magnitude) .. " m"
                else
                    StatDist.Text = "📏 ระยะห่าง: -"
                end
            else
                StatName.Text = "👤 ชื่อ: (ไม่พบเป้าหมาย)"; StatHP.Text = "❤️ เลือด: -"; StatWeapon.Text = "🔫 อาวุธ: -"; StatDist.Text = "📏 ระยะห่าง: -"
            end
        end

        if State.TracersEnabled then
            local activeThisFrame = {}

            local startPosVector2
            if State.StatsEnabled and StatsPanel.Visible then
                startPosVector2 = Vector2.new(StatsPanel.AbsolutePosition.X + (StatsPanel.AbsoluteSize.X / 2), StatsPanel.AbsolutePosition.Y + 12)
            else
                startPosVector2 = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
            end

            local currentThickness = math.clamp(State.TracerThickness or 1.0, 1.0, 6.0)
            local currentThickPx = math.max(1, math.floor(currentThickness))

            for _, t in ipairs(getAllValidTargets()) do
                local shouldDraw = false
                if State.TracerMode == "All" then shouldDraw = true
                elseif State.TracerMode == "Closest" and t == displayTarget then shouldDraw = true end

                local instKey = (type(t) == "table" and (t.Character or t.Model)) or t
                local hrp = env.Scanner.getRootPart(t)

                if shouldDraw and hrp and instKey then
                    local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)

                    if onScreen then
                        activeThisFrame[instKey] = true
                        local item = getTracerLine(instKey)
                        local color = State.AimingPlayers[t] and UIF.Theme.AccentGreen or UIF.Theme.AccentRed

                        if item.isDrawing and item.line then
                            item.line.From = startPosVector2
                            item.line.To = Vector2.new(pos.X, pos.Y)
                            item.line.Thickness = currentThickness
                            item.line.Color = color
                            item.line.Visible = true
                        elseif item.line then
                            local line = item.line
                            local distLine = (startPosVector2 - Vector2.new(pos.X, pos.Y)).Magnitude
                            local center = (startPosVector2 + Vector2.new(pos.X, pos.Y)) / 2
                            local angle = math.atan2(pos.Y - startPosVector2.Y, pos.X - startPosVector2.X)

                            line.BackgroundColor3 = color
                            line.ZIndex = State.AimingPlayers[t] and 2 or 1
                            line.Position = UDim2.new(0, center.X, 0, center.Y)
                            line.Size = UDim2.new(0, distLine, 0, currentThickPx)
                            line.Rotation = math.deg(angle)
                            line.Visible = true
                        end
                    end
                end
            end

            for key, item in pairs(tracerLines) do
                if not activeThisFrame[key] then
                    if item.isDrawing and item.line then
                        item.line.Visible = false
                    elseif item.line then
                        item.line.Visible = false
                    end
                    if not env.Scanner.isAlive(key) then
                        destroyTracerItem(item)
                        tracerLines[key] = nil
                    end
                end
            end
        else
            for _, item in pairs(tracerLines) do
                if item.isDrawing and item.line then item.line.Visible = false
                elseif item.line then item.line.Visible = false end
            end
        end
    end)))

    local lastWarningCheck = 0
    Cleanup.conn(RunService.RenderStepped:Connect(Guard.safeLoop("Aimbot", "GunWarningRender", function()
        if not State.GunWarningEnabled then
            State.AimingPlayers = {}
            WarnText.Visible = false
            return
        end

        local now = tick()
        if now - lastWarningCheck < 0.05 then return end
        lastWarningCheck = now

        local currentAimers = {}
        local firstAimerName = ""

        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHRP = LocalPlayer.Character.HumanoidRootPart
            local myPos = myHRP.Position

            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and not isSameTeam(p) then
                    if env.Scanner.isAlive(p) then
                        local enemyChar = p.Character
                        local tool = enemyChar:FindFirstChildOfClass("Tool")

                        local muzzlePos = nil
                        if tool then
                            local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildWhichIsA("BasePart")
                            if handle then muzzlePos = handle.Position end
                        end

                        if not muzzlePos then
                            local rightArm = enemyChar:FindFirstChild("Right Arm") or enemyChar:FindFirstChild("RightHand")
                            muzzlePos = rightArm and rightArm.Position or enemyChar.HumanoidRootPart.Position
                        end

                        local dirToMe = (myPos - muzzlePos)
                        local distance = dirToMe.Magnitude

                        if distance < 600 then
                            dirToMe = dirToMe.Unit
                            local lookPart = enemyChar:FindFirstChild("Head") or enemyChar.HumanoidRootPart
                            if lookPart then
                                local lookVector = lookPart.CFrame.LookVector
                                if lookVector:Dot(dirToMe) > 0.92 then
                                    currentAimers[p] = true
                                    if firstAimerName == "" then firstAimerName = p.Name end
                                end
                            end
                        end
                    end
                end
            end
        end

        State.AimingPlayers = currentAimers

        if firstAimerName ~= "" then
            WarnText.Text = "⚠️ ระวัง! [" .. firstAimerName .. "] กำลังหันกระบอกปืนเล็งคุณ! ⚠️"; WarnText.Visible = true
        else
            WarnText.Visible = false
        end
    end)))

    -- ============ 📦 Hitbox Expander ============
    local modifiedHitboxes = {} 

    local function restoreHitbox(part, data)
        if part and part.Parent then
            pcall(function()
                part.Size = data.origSize
                part.Transparency = data.origTrans
                part.CanCollide = data.origCanCollide
            end)
        end
    end

    local function restoreAllHitboxes()
        for part, data in pairs(modifiedHitboxes) do
            restoreHitbox(part, data)
        end
        modifiedHitboxes = {}
    end

    local function updateHitboxUI()
        if State.HitboxEnabled then
            if B.hitbox then
                B.hitbox.Text = "📦 ขยาย Hitbox ศัตรู: เปิด"
                B.hitbox.BackgroundColor3 = UIF.Theme.AccentGreen
                B.hitbox.TextColor3 = UIF.Theme.TextDark
            end
        else
            if B.hitbox then
                B.hitbox.Text = "📦 ขยาย Hitbox ศัตรู: ปิด"
                B.hitbox.BackgroundColor3 = UIF.Theme.CardBg
                B.hitbox.TextColor3 = UIF.Theme.Text
            end
            restoreAllHitboxes()
        end
    end

    function Aimbot.setHitbox(enabled)
        State.HitboxEnabled = enabled
        updateHitboxUI()
    end

    function Aimbot.setHitboxPart(partName)
        restoreAllHitboxes()
        State.HitboxPart = partName
        if B.hitboxPart then
            if State.HitboxPart == "Head" then
                B.hitboxPart.Text = "🎯 ส่วนที่ขยาย: หัว (Head)"
            else
                B.hitboxPart.Text = "🎯 ส่วนที่ขยาย: ลำตัว (RootPart)"
            end
        end
    end

    if B.hitbox then
        B.hitbox.Activated:Connect(function()
            State.HitboxEnabled = not State.HitboxEnabled
            updateHitboxUI()
        end)
    end

    if B.hitboxPart then
        B.hitboxPart.Activated:Connect(function()
            if State.HitboxPart == "Head" then
                Aimbot.setHitboxPart("HumanoidRootPart")
            else
                Aimbot.setHitboxPart("Head")
            end
        end)
    end

    if S.hitboxSize then
        local function updateHitboxSlider(input)
            local sizeX = math.max(S.hitboxSize.frame.AbsoluteSize.X, 1)
            local relativeX = math.clamp(input.Position.X - S.hitboxSize.frame.AbsolutePosition.X, 0, sizeX)
            local percentage = math.clamp(relativeX / sizeX, 0, 1)
            local sizeVal = math.floor(2 + (30 - 2) * percentage)
            State.HitboxSize = sizeVal
            S.hitboxSize.fill.Size = UDim2.new(percentage, 0, 1, 0)
            S.hitboxSize.text.Text = tostring(sizeVal) .. " studs"
            S.hitboxSize.title.Text = "ขนาด Hitbox: " .. tostring(sizeVal) .. " studs"
        end

        S.hitboxSize.btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                State.draggingHitbox = true
                updateHitboxSlider(input)
            end
        end)
        Cleanup.conn(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                State.draggingHitbox = false
            end
        end))
        Cleanup.conn(UserInputService.InputChanged:Connect(function(input)
            if State.draggingHitbox and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateHitboxSlider(input)
            end
        end))
    end

    Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("Aimbot", "HitboxExpanderLoop", function()
        if not State.HitboxEnabled then return end

        local targetSize = Vector3.new(State.HitboxSize or 10, State.HitboxSize or 10, State.HitboxSize or 10)
        local targetTrans = State.HitboxTransparency or 0.5
        local partKey = State.HitboxPart or "Head"

        for _, t in ipairs(getAllValidTargets()) do
            local char = env.Scanner.getCharacter(t)
            local hrp = env.Scanner.getRootPart(t)
            if char and hrp then
                local part = char:FindFirstChild(partKey) or hrp
                if part and part:IsA("BasePart") then
                    if not modifiedHitboxes[part] then
                        modifiedHitboxes[part] = {
                            origSize = part.Size,
                            origTrans = part.Transparency,
                            origCanCollide = part.CanCollide
                        }
                    end
                    pcall(function()
                        part.Size = targetSize
                        part.Transparency = targetTrans
                        part.CanCollide = false
                    end)
                end
            end
        end
    end)))

    Cleanup.addCallback(function()
        restoreAllHitboxes()
        clearTracers()
    end)

    return Aimbot
end

end)()
if type(__factory_aimbot) ~= "function" then error("Module aimbot did not return a factory function") end

-- ========== MODULE: world ==========
local __factory_world = (function()
return function(env)
    local RunService = env.RunService
    local UserInputService = env.UserInputService
    local LocalPlayer = env.LocalPlayer
    local Cleanup = env.Cleanup
    local UIF = env.UIF
    local Colors = env.Colors
    local State = env.State
    local isPlayerCharacter = env.isPlayerCharacter
    local Logger = env.Logger or { info = function() end, warn = function() end, error = function() end, detect = function() end }
    local Guard = env.Guard or { safeLoop = function(_, _, fn) return fn end, validatePlayer = function(p) return p and p.Character end, validateRaycast = function() return true end, validateCamera = function() return workspace.CurrentCamera end }

    local UI = env.UI
    local B = UI.buttons
    local S = UI.sliders
    local HK = UI.hotkeys

    local World = {}

    -- ============ ความเร็ววิ่ง ============
    local minSpeed = 16; local maxSpeed = 200; local currentSpeed = 16; local wasSpeedForcing = false

    local function updateSpeedSlider(input)
        local sizeX = math.max(S.speed.frame.AbsoluteSize.X, 1)
        local relativeX = math.clamp(input.Position.X - S.speed.frame.AbsolutePosition.X, 0, sizeX)
        local percentage = relativeX / sizeX
        currentSpeed = math.floor(minSpeed + ((maxSpeed - minSpeed) * percentage))
        S.speed.fill.Size = UDim2.new(percentage, 0, 1, 0)
        S.speed.text.Text = "🏃 ความเร็ววิ่ง: " .. currentSpeed
    end

    S.speed.btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            State.draggingSlider = true; updateSpeedSlider(input)
        end
    end)
    Cleanup.conn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then State.draggingSlider = false end
    end))
    Cleanup.conn(UserInputService.InputChanged:Connect(function(input)
        if State.draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateSpeedSlider(input) end
    end))
    Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("World", "WalkSpeedLoop", function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum then
            if currentSpeed > 16 then
                -- เพิ่ม jitter จาก AntiTamper เพื่อ mask ค่า WalkSpeed คงที่
                local jitter = (type(State._speedJitter) == "number") and State._speedJitter or 0
                local targetSpeed = currentSpeed + jitter
                if math.abs(hum.WalkSpeed - targetSpeed) > 0.08 then hum.WalkSpeed = targetSpeed end
                wasSpeedForcing = true
            elseif wasSpeedForcing then
                if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
                wasSpeedForcing = false
            end
        end
    end)))

    -- ============ Unlimited Jump ============
    State.InfJumpEnabled = false
    local infJumpConnection = nil

    local function enableInfJump()
        State.InfJumpEnabled = true
        B.infJump.Text = "🦘 Unlimited Jump: เปิด"
        B.infJump.BackgroundColor3 = UIF.Theme.AccentGreen
        B.infJump.TextColor3 = UIF.Theme.TextDark
        
        infJumpConnection = Cleanup.conn(UserInputService.JumpRequest:Connect(function()
            if State.InfJumpEnabled then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChild("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end))
    end

    local function disableInfJump()
        State.InfJumpEnabled = false
        B.infJump.Text = "🦘 Unlimited Jump: ปิด"
        B.infJump.BackgroundColor3 = UIF.Theme.CardBg
        B.infJump.TextColor3 = UIF.Theme.Text
        if infJumpConnection then infJumpConnection:Disconnect(); infJumpConnection = nil end
    end

    function World.setInfJump(enabled)
        if enabled then enableInfJump() else disableInfJump() end
    end

    B.infJump.Activated:Connect(function()
        if State.InfJumpEnabled then
            disableInfJump()
        else
            enableInfJump()
        end
    end)

    -- ============ NoClip ============
    State.NoClipEnabled = false
    local noClipConnection = nil

    local function enableNoClip()
        State.NoClipEnabled = true
        B.noClip.Text = "🚫 NoClip (ทะลุกำแพง): เปิด"
        B.noClip.BackgroundColor3 = UIF.Theme.AccentGreen
        B.noClip.TextColor3 = UIF.Theme.TextDark
        
        noClipConnection = Cleanup.conn(RunService.Stepped:Connect(Guard.safeLoop("World", "NoClipLoop", function()
            -- AntiTamper: skip 5% of frames ตามที่ antitamper.lua กำหนด
            if State._noClipSkipFrame then return end
            if State.NoClipEnabled then
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetChildren()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)))
    end

    local function disableNoClip()
        State.NoClipEnabled = false
        B.noClip.Text = "🚫 NoClip (ทะลุกำแพง): ปิด"
        B.noClip.BackgroundColor3 = UIF.Theme.CardBg
        B.noClip.TextColor3 = UIF.Theme.Text
        if noClipConnection then noClipConnection:Disconnect(); noClipConnection = nil end
        -- คืนค่า CanCollide
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end

    function World.setNoClip(enabled)
        if enabled then enableNoClip() else disableNoClip() end
    end

    B.noClip.Activated:Connect(function()
        if State.NoClipEnabled then
            disableNoClip()
        else
            enableNoClip()
        end
    end)

    -- ============ ลบแมพทั้งหมด / คืนค่า (แยก flag isRestoring) ============
    local AutoDelAllEnabled = false
    local isRestoring = false

    local function toggleAutoDelAll()
        AutoDelAllEnabled = not AutoDelAllEnabled
        if AutoDelAllEnabled then
            isRestoring = false
            B.autoDel.Text = "💥 กำลังลบแมพทั้งหมด..."
            B.autoDel.BackgroundColor3 = UIF.Theme.AccentGreen
            B.autoDel.TextColor3 = UIF.Theme.TextDark
            task.spawn(function()
                local mapObjects = Cleanup.getMapObjects()
                local processCount = 0
                for _, hit in pairs(workspace:GetDescendants()) do
                    if not AutoDelAllEnabled or isRestoring then break end
                    if hit:IsA("BasePart") and not hit:IsA("Terrain") then
                        if not isPlayerCharacter(hit) then
                            if not mapObjects[hit] then
                                mapObjects[hit] = { origTransparency = hit.Transparency, origCanCollide = hit.CanCollide, origCanQuery = hit.CanQuery }
                                hit.CanCollide = false; hit.Transparency = 1; pcall(function() hit.CanQuery = false end)
                            end
                            processCount = processCount + 1
                            if processCount % 1000 == 0 then task.wait() end
                        end
                    end
                end
                if AutoDelAllEnabled and not isRestoring then
                    pcall(function()
                        B.autoDel.Text = "💥 คืนค่าแมพ (Restore All)"
                        B.autoDel.BackgroundColor3 = UIF.Theme.AccentGreen
                        B.autoDel.TextColor3 = UIF.Theme.TextDark
                    end)
                end
            end)
        else
            isRestoring = true
            B.autoDel.Text = "💥 กำลังคืนค่าแมพ..."
            B.autoDel.BackgroundColor3 = UIF.Theme.CardBg
            B.autoDel.TextColor3 = UIF.Theme.Text
            task.spawn(function()
                local mapObjects = Cleanup.getMapObjects()
                local processCount = 0
                for obj, data in pairs(mapObjects) do
                    if AutoDelAllEnabled or not isRestoring then break end
                    if obj then
                        pcall(function() obj.Transparency = data.origTransparency; obj.CanCollide = data.origCanCollide; if data.origCanQuery ~= nil then obj.CanQuery = data.origCanQuery end end)
                    end
                    processCount = processCount + 1
                    if processCount % 1000 == 0 then task.wait() end
                end
                Cleanup.clearMapObjects()
                isRestoring = false
                if not AutoDelAllEnabled then
                    pcall(function()
                        B.autoDel.Text = "💥 ลบแมพทั้งหมด (Delete All): ปิด"
                        B.autoDel.BackgroundColor3 = UIF.Theme.CardBg
                        B.autoDel.TextColor3 = UIF.Theme.Text
                    end)
                end
            end)
        end
    end
    B.autoDel.Activated:Connect(toggleAutoDelAll)

    -- ============ โหมดลบของ ============
    local DeleteModeEnabled = false
    local hoverHighlight = Instance.new("Highlight")
    hoverHighlight.Name = "DeleteHoverHighlight"
    hoverHighlight.FillColor = UIF.Theme.AccentRed
    hoverHighlight.OutlineColor = Color3.fromRGB(255, 120, 120)
    hoverHighlight.FillTransparency = 0.5
    hoverHighlight.OutlineTransparency = 0
    hoverHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hoverHighlight.Parent = workspace
    hoverHighlight.Enabled = false
    Cleanup.trackHighlight(hoverHighlight)

    local deleteRenderConnection = nil
    local currentHoverObject = nil
    local deleteMouse = LocalPlayer:GetMouse()

    function World.toggleDeleteMode()
        DeleteModeEnabled = not DeleteModeEnabled
        State.DeleteModeEnabled = DeleteModeEnabled
        if DeleteModeEnabled then
            if HK.del then
                if HK.del.setState then
                    HK.del.setState(true, "โหมดลบของทีละชิ้น: เปิด")
                elseif HK.del.title then
                    HK.del.title.Text = "โหมดลบของทีละชิ้น: เปิด"
                    HK.del.card.BackgroundColor3 = UIF.Theme.AccentGreen
                end
            end
            hoverHighlight.Enabled = true

            deleteRenderConnection = Cleanup.conn(RunService.RenderStepped:Connect(Guard.safeLoop("World", "DeleteHoverLoop", function()
                local target = deleteMouse.Target
                if target and not target.Locked and not isPlayerCharacter(target) and not target:IsA("Terrain") then
                    if currentHoverObject ~= target then
                        currentHoverObject = target
                        hoverHighlight.Adornee = currentHoverObject
                    end
                else
                    currentHoverObject = nil
                    hoverHighlight.Adornee = nil
                end
            end)))
        else
            if HK.del then
                if HK.del.setState then
                    HK.del.setState(false, "โหมดลบของทีละชิ้น: ปิด")
                elseif HK.del.title then
                    HK.del.title.Text = "โหมดลบของทีละชิ้น: ปิด"
                    HK.del.card.BackgroundColor3 = UIF.Theme.CardBg
                end
            end

            if deleteRenderConnection then deleteRenderConnection:Disconnect(); deleteRenderConnection = nil end
            currentHoverObject = nil
            hoverHighlight.Adornee = nil
            hoverHighlight.Enabled = false

            for _, data in ipairs(Cleanup.getClickObjects()) do
                if data.obj then
                    pcall(function()
                        data.obj.Transparency = data.origTransparency
                        data.obj.CanCollide = data.origCanCollide
                        if data.origCanQuery ~= nil then data.obj.CanQuery = data.origCanQuery end
                    end)
                end
            end
            Cleanup.clearClickObjects()
        end
    end
    if HK.del and HK.del.btn then
        HK.del.btn.Activated:Connect(World.toggleDeleteMode)
    end

    function World.clickDeleteIfEnabled()
        if not DeleteModeEnabled then return end
        local obj = currentHoverObject or (deleteMouse and deleteMouse.Target)
        if not obj or isPlayerCharacter(obj) or obj:IsA("Terrain") then return end
        Cleanup.addClickObject({
            obj = obj,
            origTransparency = obj.Transparency,
            origCanCollide = obj.CanCollide,
            origCanQuery = obj.CanQuery
        })
        obj.CanCollide = false
        obj.Transparency = 1
        pcall(function() obj.CanQuery = false end)
        currentHoverObject = nil
        hoverHighlight.Adornee = nil
    end

    -- ============ เสาปีน ============
    local PoleModeEnabled = false
    local poleMouse = LocalPlayer:GetMouse()

    function World.togglePoleMode()
        PoleModeEnabled = not PoleModeEnabled
        if PoleModeEnabled then
            if HK.pole then
                if HK.pole.setState then
                    HK.pole.setState(true, "โหมดสร้างเสาปีน: เปิด")
                elseif HK.pole.title then
                    HK.pole.title.Text = "โหมดสร้างเสาปีน: เปิด"
                    HK.pole.card.BackgroundColor3 = UIF.Theme.AccentGreen
                end
            end
        else
            if HK.pole then
                if HK.pole.setState then
                    HK.pole.setState(false, "โหมดสร้างเสาปีน: ปิด")
                elseif HK.pole.title then
                    HK.pole.title.Text = "โหมดสร้างเสาปีน: ปิด"
                    HK.pole.card.BackgroundColor3 = UIF.Theme.CardBg
                end
            end
            for _, pole in ipairs(Cleanup.getPoles()) do
                if pole and pole.Parent then pole:Destroy() end
            end
            Cleanup.clearPoles()
        end
    end
    HK.pole.btn.Activated:Connect(World.togglePoleMode)

    function World.spawnPoleIfEnabled()
        if not PoleModeEnabled then
            World.togglePoleMode()
        end
        local hit = poleMouse.Hit
        if hit then
            local truss = Instance.new("TrussPart")
            truss.Size = Vector3.new(2, 40, 2); truss.Position = hit.Position + Vector3.new(0, 20, 0)
            truss.Anchored = true; truss.BrickColor = BrickColor.new("Bright yellow")
            truss.Material = Enum.Material.Neon; truss.Parent = workspace
            Cleanup.addPole(truss)
        end
    end
    World.spawnPole = World.spawnPoleIfEnabled

    -- ============ กลางวัน+สว่าง ============
    local AlwaysDayEnabled = false
    local dayConnection = nil

    local function toggleDay()
        AlwaysDayEnabled = not AlwaysDayEnabled
        local Lighting = game:GetService("Lighting")
        if AlwaysDayEnabled then
            B.day.Text = "☀️ กลางวัน+สว่างตลอด: เปิด"
            B.day.BackgroundColor3 = UIF.Theme.AccentGreen
            B.day.TextColor3 = UIF.Theme.TextDark
            Cleanup.saveLighting(Lighting)
            Lighting.ClockTime = 12; Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1); Lighting.GlobalShadows = false
            dayConnection = Cleanup.conn(Lighting.Changed:Connect(function()
                if AlwaysDayEnabled then Lighting.ClockTime = 12; Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1); Lighting.GlobalShadows = false end
            end))
        else
            B.day.Text = "☀️ กลางวัน+สว่างตลอด: ปิด"
            B.day.BackgroundColor3 = UIF.Theme.CardBg
            B.day.TextColor3 = UIF.Theme.Text
            if dayConnection then dayConnection:Disconnect(); dayConnection = nil end
            local originals, saved = Cleanup.getLightingOriginals()
            Lighting.Ambient = (saved and originals.ambient) or Color3.fromRGB(127, 127, 127)
            Lighting.OutdoorAmbient = (saved and originals.outdoor) or Color3.fromRGB(127, 127, 127)
            if saved and originals.shadows ~= nil then Lighting.GlobalShadows = originals.shadows end
        end
    end

    function World.setDay(enabled)
        if AlwaysDayEnabled ~= enabled then
            toggleDay()
        end
    end
    B.day.Activated:Connect(toggleDay)

    -- ============ 🚀 FPS Booster / Potato Graphics ============
    State.FPSBoostEnabled = false
    local fpsBoostConn = nil
    local originalPartProps = {}
    local originalEffects = {}
    local originalTerrainProps = {}
    local originalLightingProps = {}

    local function applyPotatoToPart(part)
        if not part:IsA("BasePart") or isPlayerCharacter(part) or part:IsA("Terrain") then return end
        if not originalPartProps[part] then
            originalPartProps[part] = {
                material = part.Material,
                castShadow = part.CastShadow
            }
        end
        pcall(function()
            part.Material = Enum.Material.SmoothPlastic
            part.CastShadow = false
        end)
    end

    local function disableHeavyEffect(inst)
        if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") or inst:IsA("Beam") then
            if originalEffects[inst] == nil then
                originalEffects[inst] = inst.Enabled
            end
            pcall(function() inst.Enabled = false end)
        elseif inst:IsA("PostEffect") or inst:IsA("BloomEffect") or inst:IsA("BlurEffect") or inst:IsA("SunRaysEffect") or inst:IsA("ColorCorrectionEffect") or inst:IsA("DepthOfFieldEffect") then
            if originalEffects[inst] == nil then
                originalEffects[inst] = inst.Enabled
            end
            pcall(function() inst.Enabled = false end)
        end
    end

    function World.enableFPSBoost()
        State.FPSBoostEnabled = true
        if B.fpsBoost then
            B.fpsBoost.Text = "🚀 FPS Booster (ดันความลื่น): เปิด"
            B.fpsBoost.BackgroundColor3 = UIF.Theme.AccentGreen
            B.fpsBoost.TextColor3 = UIF.Theme.TextDark
        end

        local Lighting = game:GetService("Lighting")
        originalLightingProps.globalShadows = Lighting.GlobalShadows
        originalLightingProps.fogEnd = Lighting.FogEnd
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
        end)

        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            originalTerrainProps.waterWaveSize = terrain.WaterWaveSize
            originalTerrainProps.waterWaveSpeed = terrain.WaterWaveSpeed
            originalTerrainProps.waterReflectance = terrain.WaterReflectance
            pcall(function()
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
            end)
        end

        task.spawn(function()
            local descendants = workspace:GetDescendants()
            local count = 0
            for i = 1, #descendants do
                if not State.FPSBoostEnabled then break end
                local inst = descendants[i]
                if inst:IsA("BasePart") then
                    applyPotatoToPart(inst)
                else
                    disableHeavyEffect(inst)
                end
                count = count + 1
                if count % 500 == 0 then task.wait() end
            end

            for _, inst in ipairs(Lighting:GetChildren()) do
                disableHeavyEffect(inst)
            end
        end)

        fpsBoostConn = Cleanup.conn(workspace.DescendantAdded:Connect(function(inst)
            if State.FPSBoostEnabled then
                task.delay(0.1, function()
                    if State.FPSBoostEnabled and inst and inst.Parent then
                        if inst:IsA("BasePart") then
                            applyPotatoToPart(inst)
                        else
                            disableHeavyEffect(inst)
                        end
                    end
                end)
            end
        end))
    end

    function World.disableFPSBoost()
        State.FPSBoostEnabled = false
        if B.fpsBoost then
            B.fpsBoost.Text = "🚀 FPS Booster (ดันความลื่น): ปิด"
            B.fpsBoost.BackgroundColor3 = UIF.Theme.CardBg
            B.fpsBoost.TextColor3 = UIF.Theme.Text
        end
        if fpsBoostConn then fpsBoostConn:Disconnect(); fpsBoostConn = nil end

        local Lighting = game:GetService("Lighting")
        pcall(function()
            if originalLightingProps.globalShadows ~= nil then
                Lighting.GlobalShadows = originalLightingProps.globalShadows
            end
            if originalLightingProps.fogEnd ~= nil then
                Lighting.FogEnd = originalLightingProps.fogEnd
            end
        end)

        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain and originalTerrainProps.waterWaveSize ~= nil then
            pcall(function()
                terrain.WaterWaveSize = originalTerrainProps.waterWaveSize
                terrain.WaterWaveSpeed = originalTerrainProps.waterWaveSpeed
                terrain.WaterReflectance = originalTerrainProps.waterReflectance
            end)
        end

        for part, props in pairs(originalPartProps) do
            if part and part.Parent then
                pcall(function()
                    part.Material = props.material
                    part.CastShadow = props.castShadow
                end)
            end
        end
        originalPartProps = {}

        for inst, enabled in pairs(originalEffects) do
            if inst and inst.Parent then
                pcall(function() inst.Enabled = enabled end)
            end
        end
        originalEffects = {}
    end

    function World.toggleFPSBoost()
        if State.FPSBoostEnabled then
            World.disableFPSBoost()
        else
            World.enableFPSBoost()
        end
    end

    function World.setFPSBoost(enabled)
        if State.FPSBoostEnabled ~= enabled then
            if enabled then World.enableFPSBoost() else World.disableFPSBoost() end
        end
    end

    if B.fpsBoost then
        B.fpsBoost.Activated:Connect(World.toggleFPSBoost)
    end

    Cleanup.addCallback(function()
        if State.FPSBoostEnabled then
            World.disableFPSBoost()
        end
    end)

    -- ============ 📐 Interactive Object Scaler (ขยาย/ย่อ Object ในแมพ) ============
    local scaledObjects = {} -- [part] = { origSize = ..., origCFrame = ... }
    local currentScaleHover = nil
    local selectedScaleObject = nil
    local scaleMouse = LocalPlayer:GetMouse()
    local scaleRenderConnection = nil

    local scaleHoverHighlight = Instance.new("Highlight")
    scaleHoverHighlight.Name = "ScaleHoverHighlight"
    scaleHoverHighlight.FillColor = UIF.Theme.AccentBlue
    scaleHoverHighlight.OutlineColor = Color3.fromRGB(120, 220, 255)
    scaleHoverHighlight.FillTransparency = 0.6
    scaleHoverHighlight.OutlineTransparency = 0
    scaleHoverHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    scaleHoverHighlight.Parent = workspace
    scaleHoverHighlight.Enabled = false
    Cleanup.trackHighlight(scaleHoverHighlight)

    local scaleSelectedHighlight = Instance.new("Highlight")
    scaleSelectedHighlight.Name = "ScaleSelectedHighlight"
    scaleSelectedHighlight.FillColor = UIF.Theme.AccentYellow
    scaleSelectedHighlight.OutlineColor = Color3.fromRGB(255, 240, 100)
    scaleSelectedHighlight.FillTransparency = 0.5
    scaleSelectedHighlight.OutlineTransparency = 0
    scaleSelectedHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    scaleSelectedHighlight.Parent = workspace
    scaleSelectedHighlight.Enabled = false
    Cleanup.trackHighlight(scaleSelectedHighlight)

    local function getTargetParts(target)
        if not target then return {} end
        if target:IsA("BasePart") then
            return { target }
        elseif target:IsA("Model") then
            local parts = {}
            for _, p in ipairs(target:GetDescendants()) do
                if p:IsA("BasePart") and not isPlayerCharacter(p) then
                    table.insert(parts, p)
                end
            end
            return parts
        end
        return {}
    end

    function World.selectObject(target)
        if not target or isPlayerCharacter(target) or target:IsA("Terrain") then return end
        selectedScaleObject = target
        State.SelectedObject = target
        scaleSelectedHighlight.Adornee = target
        scaleSelectedHighlight.Enabled = true
        if UI.showNotif then
            UI.showNotif("🎯 เลือก Object: " .. target.Name, 2.5)
        end
    end

    function World.clickSelectObject()
        if not State.ObjectScalerEnabled then return end
        if currentScaleHover then
            World.selectObject(currentScaleHover)
        end
    end

    function World.applyScale(mult, axis)
        if not selectedScaleObject then
            if UI.showNotif then UI.showNotif("❌ กรุณาเลือก Object ก่อน (คลิกเมาส์ที่ชิ้นงาน)", 2.5) end
            return
        end

        local multiplier = mult or State.ObjectScaleMultiplier or 2.0
        local targetAxis = axis or State.ObjectScaleAxis or "All"
        local parts = getTargetParts(selectedScaleObject)

        for _, part in ipairs(parts) do
            if part and part:IsA("BasePart") and not part:IsA("Terrain") then
                if not scaledObjects[part] then
                    scaledObjects[part] = {
                        origSize = part.Size,
                        origCFrame = part.CFrame
                    }
                end
                local baseSize = scaledObjects[part].origSize
                local newSize = baseSize
                if targetAxis == "All" then
                    newSize = baseSize * multiplier
                elseif targetAxis == "X" then
                    newSize = Vector3.new(baseSize.X * multiplier, baseSize.Y, baseSize.Z)
                elseif targetAxis == "Y" then
                    newSize = Vector3.new(baseSize.X, baseSize.Y * multiplier, baseSize.Z)
                elseif targetAxis == "Z" then
                    newSize = Vector3.new(baseSize.X, baseSize.Y, baseSize.Z * multiplier)
                end
                pcall(function()
                    part.Size = newSize
                end)
            end
        end

        if UI.showNotif then
            UI.showNotif(string.format("📐 ปรับขนาด [%s] เป็น %.1fx (%s) แล้ว!", selectedScaleObject.Name, multiplier, targetAxis), 2.5)
        end
    end

    function World.stepScale(step)
        local cur = State.ObjectScaleMultiplier or 2.0
        local newMult = math.clamp(math.floor((cur + step) * 10) / 10, 0.1, 30.0)
        State.ObjectScaleMultiplier = newMult

        if S.scaleAmt then
            local pct = (newMult - 0.1) / (30.0 - 0.1)
            S.scaleAmt.fill.Size = UDim2.new(pct, 0, 1, 0)
            S.scaleAmt.text.Text = string.format("%.1fx", newMult)
            S.scaleAmt.title.Text = "ตัวคูณขนาด (Scale): " .. string.format("%.1fx", newMult)
        end

        if selectedScaleObject then
            World.applyScale(newMult, State.ObjectScaleAxis)
        end
    end

    function World.restoreSelected()
        if not selectedScaleObject then return end
        local parts = getTargetParts(selectedScaleObject)
        for _, part in ipairs(parts) do
            if scaledObjects[part] then
                pcall(function()
                    part.Size = scaledObjects[part].origSize
                end)
                scaledObjects[part] = nil
            end
        end
        if UI.showNotif then UI.showNotif("🔄 คืนขนาดเดิมของ " .. selectedScaleObject.Name .. " แล้ว", 2) end
    end

    function World.restoreAllScaled()
        for part, data in pairs(scaledObjects) do
            if part and part.Parent then
                pcall(function()
                    part.Size = data.origSize
                end)
            end
        end
        scaledObjects = {}
        if UI.showNotif then UI.showNotif("🗑️ คืนขนาดเดิมของ Object ทั้งหมดแล้ว", 2) end
    end

    function World.toggleScaleMode()
        State.ObjectScalerEnabled = not State.ObjectScalerEnabled
        if State.ObjectScalerEnabled then
            if HK.scaler then
                if HK.scaler.setState then
                    HK.scaler.setState(true, "โหมดเลือกปรับขนาด Object: เปิด")
                elseif HK.scaler.title then
                    HK.scaler.title.Text = "โหมดเลือกปรับขนาด Object: เปิด"
                    HK.scaler.card.BackgroundColor3 = UIF.Theme.AccentGreen
                end
            end
            scaleHoverHighlight.Enabled = true

            scaleRenderConnection = Cleanup.conn(RunService.RenderStepped:Connect(Guard.safeLoop("World", "ScaleHoverLoop", function()
                local target = scaleMouse.Target
                if target and not target.Locked and not isPlayerCharacter(target) and not target:IsA("Terrain") then
                    if currentScaleHover ~= target then
                        currentScaleHover = target
                        scaleHoverHighlight.Adornee = currentScaleHover
                    end
                else
                    currentScaleHover = nil
                    scaleHoverHighlight.Adornee = nil
                end
            end)))
        else
            if HK.scaler then
                if HK.scaler.setState then
                    HK.scaler.setState(false, "โหมดเลือกปรับขนาด Object: ปิด")
                elseif HK.scaler.title then
                    HK.scaler.title.Text = "โหมดเลือกปรับขนาด Object: ปิด"
                    HK.scaler.card.BackgroundColor3 = UIF.Theme.CardBg
                end
            end

            if scaleRenderConnection then scaleRenderConnection:Disconnect(); scaleRenderConnection = nil end
            currentScaleHover = nil
            scaleHoverHighlight.Adornee = nil
            scaleHoverHighlight.Enabled = false
        end
    end

    if HK.scaler and HK.scaler.btn then
        HK.scaler.btn.Activated:Connect(World.toggleScaleMode)
    end

    if B.scaleAxis then
        B.scaleAxis.Activated:Connect(function()
            local axis = State.ObjectScaleAxis or "All"
            if axis == "All" then
                State.ObjectScaleAxis = "X"
                B.scaleAxis.Text = "📐 แกนที่ปรับ: แกน X (ความกว้าง)"
            elseif axis == "X" then
                State.ObjectScaleAxis = "Y"
                B.scaleAxis.Text = "📐 แกนที่ปรับ: แกน Y (ความสูง)"
            elseif axis == "Y" then
                State.ObjectScaleAxis = "Z"
                B.scaleAxis.Text = "📐 แกนที่ปรับ: แกน Z (ความยาว)"
            else
                State.ObjectScaleAxis = "All"
                B.scaleAxis.Text = "📐 แกนที่ปรับ: ทุกด้าน (X, Y, Z)"
            end
            if selectedScaleObject then
                World.applyScale(State.ObjectScaleMultiplier, State.ObjectScaleAxis)
            end
        end)
    end

    if B.applyScale then
        B.applyScale.Activated:Connect(function()
            World.applyScale(State.ObjectScaleMultiplier, State.ObjectScaleAxis)
        end)
    end

    if B.restoreSelected then
        B.restoreSelected.Activated:Connect(World.restoreSelected)
    end

    if B.restoreAllScaled then
        B.restoreAllScaled.Activated:Connect(World.restoreAllScaled)
    end

    if S.scaleAmt then
        local function updateScaleSlider(input)
            local sizeX = math.max(S.scaleAmt.frame.AbsoluteSize.X, 1)
            local relativeX = math.clamp(input.Position.X - S.scaleAmt.frame.AbsolutePosition.X, 0, sizeX)
            local percentage = math.clamp(relativeX / sizeX, 0, 1)
            local scaleVal = math.floor((0.1 + (30.0 - 0.1) * percentage) * 10) / 10
            State.ObjectScaleMultiplier = scaleVal
            S.scaleAmt.fill.Size = UDim2.new(percentage, 0, 1, 0)
            S.scaleAmt.text.Text = string.format("%.1fx", scaleVal)
            S.scaleAmt.title.Text = "ตัวคูณขนาด (Scale): " .. string.format("%.1fx", scaleVal)
            if selectedScaleObject then
                World.applyScale(scaleVal, State.ObjectScaleAxis)
            end
        end

        S.scaleAmt.btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                State.draggingScale = true
                updateScaleSlider(input)
            end
        end)
        Cleanup.conn(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                State.draggingScale = false
            end
        end))
        Cleanup.conn(UserInputService.InputChanged:Connect(function(input)
            if State.draggingScale and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateScaleSlider(input)
            end
        end))
    end

    Cleanup.addCallback(function()
        World.restoreAllScaled()
    end)

    -- ============ Master Enable ============
    function World.enableAll()
        task.spawn(function()
            local opened = {}
            local ESP = env.ESP
            local Aimbot = env.Aimbot

            if not ESP.isPlayerESPOn() then
                ESP.togglePlayer()
                table.insert(opened, "ESP")
            end
            task.wait(0.2)

            if not State.FOVEnabled then
                Aimbot.enableFOV()
                table.insert(opened, "FOV")
            end
            task.wait(0.2)

            if State.AimTargetPart ~= "Head" then
                Aimbot.setAimPartHead()
                table.insert(opened, "เล็งหัว")
            end
            task.wait(0.2)

            if not State.WallCheckEnabled then
                Aimbot.enableWallCheck()
                table.insert(opened, "ไม่ทะลุกำแพง")
            end
            task.wait(0.2)

            if not State.TracersEnabled then
                Aimbot.toggleTracers()
                table.insert(opened, "เส้นชี้เป้า")
            end

            if #opened > 0 then
                UI.Status.Text = "⚡ เปิดทั้งหมดแล้ว: " .. table.concat(opened, ", ")
            else
                UI.Status.Text = "⚡ ทุกอย่างเปิดอยู่แล้ว!"
            end
            UI.Status.TextColor3 = UIF.Theme.AccentGreen
        end)
    end
    if B.all then
        B.all.Activated:Connect(World.enableAll)
    end
    -- ============ 🛡️ Anti-Fall Damage ============
    State.AntiFallEnabled = false
    local antiFallConnection = nil

    local function enableAntiFall()
        State.AntiFallEnabled = true
        if B.antiFall then
            B.antiFall.Text = "🛡️ กันดาเมจตกที่สูง (Anti-Fall): เปิด"
            B.antiFall.BackgroundColor3 = UIF.Theme.AccentGreen
            B.antiFall.TextColor3 = UIF.Theme.TextDark
        end

        antiFallConnection = Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("World", "AntiFallLoop", function()
            if not State.AntiFallEnabled then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then return end

            -- ตรวจจับความเร็วการตก
            local velY = hrp.AssemblyLinearVelocity.Y
            if velY < -35 then
                -- ยิง Raycast ลงพื้นเพื่อเช็คว่าใกล้ถึงพื้นหรือยัง (ระยะปลอดภัย 12 studs)
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = { char }
                local rayResult = workspace:Raycast(hrp.Position, Vector3.new(0, -12, 0), rayParams)

                if rayResult then
                    -- ลดแรงกระแทกเป็นความเร็วปลอดภัยแบบนุ่มนวล ไม่วาร์ป ไม่ทำให้ Server Flag Anomaly
                    hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, -4, hrp.AssemblyLinearVelocity.Z)
                    if hum:GetState() == Enum.HumanoidStateType.Freefall then
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end
            end
        end)))
    end

    local function disableAntiFall()
        State.AntiFallEnabled = false
        if B.antiFall then
            B.antiFall.Text = "🛡️ กันดาเมจตกที่สูง (Anti-Fall): ปิด"
            B.antiFall.BackgroundColor3 = UIF.Theme.CardBg
            B.antiFall.TextColor3 = UIF.Theme.Text
        end
        if antiFallConnection then antiFallConnection:Disconnect(); antiFallConnection = nil end
    end

    function World.toggleAntiFall()
        if State.AntiFallEnabled then disableAntiFall() else enableAntiFall() end
    end

    function World.setAntiFall(enabled)
        if State.AntiFallEnabled ~= enabled then
            if enabled then enableAntiFall() else disableAntiFall() end
        end
    end

    if B.antiFall then
        B.antiFall.Activated:Connect(World.toggleAntiFall)
    end

    -- ============ 🧲 Auto Loot / Item Bring & Auto-Pickup ============
    State.AutoLootEnabled = false
    local autoLootConnection = nil
    local lastLootScan = 0
    local lootedCache = {}
    local VIM = nil
    pcall(function() VIM = game:GetService("VirtualInputManager") end)

    local function pressPickupKey()
        pcall(function()
            if VIM then
                VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                task.wait(0.03)
                VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
            end
        end)
    end

    local function triggerPrompt(prompt)
        pcall(function()
            if fireproximityprompt then
                fireproximityprompt(prompt, 0)
            elseif prompt.InputHoldBegin and prompt.InputHoldEnd then
                prompt:InputHoldBegin()
                task.wait(prompt.HoldDuration or 0.05)
                prompt:InputHoldEnd()
            end
        end)
    end

    local function enableAutoLoot()
        State.AutoLootEnabled = true
        if B.autoLoot then
            B.autoLoot.Text = "🧲 ดูดไอเทม/ออโต้เก็บของ (Auto Loot): เปิด"
            B.autoLoot.BackgroundColor3 = UIF.Theme.AccentGreen
            B.autoLoot.TextColor3 = UIF.Theme.TextDark
        end

        autoLootConnection = Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("World", "AutoLootLoop", function()
            if not State.AutoLootEnabled then return end
            local now = tick()
            if now - lastLootScan < 0.15 then return end -- ~6-7 times/sec
            lastLootScan = now

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local maxDist = State.LootRadius or 30
            local myPos = hrp.Position
            local foundNearbyItem = false

            -- 1. ตรวจจับ ProximityPrompts ในรัศมี
            for _, prompt in ipairs(workspace:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                    local promptPart = prompt.Parent
                    if promptPart and promptPart:IsA("BasePart") then
                        local dist = (promptPart.Position - myPos).Magnitude
                        if dist <= maxDist then
                            foundNearbyItem = true
                            if not lootedCache[prompt] or (now - lootedCache[prompt]) > 0.8 then
                                lootedCache[prompt] = now
                                triggerPrompt(prompt)
                            end
                        end
                    end
                end
            end

            -- 2. ตรวจจับ Dropped Tools / Weapons / Models (ดึงปืน/ไอเทมเข้าหาตัว + กด F)
            local function checkAndLootObject(obj)
                if not obj or obj:IsDescendantOf(char) or isPlayerCharacter(obj) then return end

                local targetPart = nil
                local isLoot = false

                if obj:IsA("Tool") then
                    targetPart = obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
                    isLoot = true
                elseif obj:IsA("Model") then
                    -- เช็คชื่อปืน / ไอเทม / หรือมี Prompt หรือมี Highlight/GUI
                    local name = obj.Name:lower()
                    local hasPrompt = obj:FindFirstChildOfClass("ProximityPrompt") or obj:FindFirstChildOfClass("ClickDetector") or obj:FindFirstChildOfClass("BillboardGui")
                    local isGun = name:find("ak") or name:find("gun") or name:find("weapon") or name:find("rifle") or name:find("pistol") or name:find("drop") or name:find("loot") or name:find("ammo") or name:find("shotgun") or name:find("sniper") or name:find("smg")
                    
                    if hasPrompt or isGun then
                        targetPart = obj.PrimaryPart or obj:FindFirstChild("Handle") or obj:FindFirstChildWhichIsA("BasePart")
                        isLoot = true
                    end
                elseif obj:IsA("BasePart") and not obj.Anchored then
                    local name = obj.Name:lower()
                    if name:find("handle") or name:find("gun") or name:find("drop") or name:find("loot") or name:find("ak") then
                        targetPart = obj
                        isLoot = true
                    end
                end

                if isLoot and targetPart and targetPart:IsA("BasePart") then
                    local dist = (targetPart.Position - myPos).Magnitude
                    if dist <= maxDist then
                        foundNearbyItem = true
                        pcall(function()
                            -- นำไอเทมมาไว้ที่ตำแหน่งตัวผู้เล่น (Magnet)
                            targetPart.CFrame = hrp.CFrame
                            targetPart.AssemblyLinearVelocity = Vector3.zero

                            -- สัมผัส Touch
                            if firetouchinterest then
                                firetouchinterest(hrp, targetPart, 0)
                                task.wait()
                                firetouchinterest(hrp, targetPart, 1)
                            end
                        end)
                    end
                end
            end

            -- ค้นหาใน workspace ชั้นแรก
            for _, obj in ipairs(workspace:GetChildren()) do
                checkAndLootObject(obj)
            end

            -- ค้นหาในโฟลเดอร์เก็บของยอดนิยม (ถ้ามี)
            local lootFolders = {"DroppedGuns", "Debris", "Drops", "Weapons", "Guns", "Loot", "DroppedItems", "Pickups"}
            for _, fName in ipairs(lootFolders) do
                local f = workspace:FindFirstChild(fName)
                if f then
                    for _, subObj in ipairs(f:GetChildren()) do
                        checkAndLootObject(subObj)
                    end
                end
            end

            -- 3. ถ้ามีไอเทมอยู่ใกล้ๆ ให้กดปุ่ม F อัตโนมัติ (สำหรับเกมที่ต้องกด F เพื่อเก็บของ)
            if foundNearbyItem then
                pressPickupKey()
            end
        end)))
    end

    local function disableAutoLoot()
        State.AutoLootEnabled = false
        if B.autoLoot then
            B.autoLoot.Text = "🧲 ดูดไอเทม/ออโต้เก็บของ (Auto Loot): ปิด"
            B.autoLoot.BackgroundColor3 = UIF.Theme.CardBg
            B.autoLoot.TextColor3 = UIF.Theme.Text
        end
        if autoLootConnection then autoLootConnection:Disconnect(); autoLootConnection = nil end
        lootedCache = {}
    end

    function World.toggleAutoLoot()
        if State.AutoLootEnabled then disableAutoLoot() else enableAutoLoot() end
    end

    function World.setAutoLoot(enabled)
        if State.AutoLootEnabled ~= enabled then
            if enabled then enableAutoLoot() else disableAutoLoot() end
        end
    end

    if B.autoLoot then
        B.autoLoot.Activated:Connect(World.toggleAutoLoot)
    end

    if S.lootRadius then
        local function updateLootSlider(input)
            local sizeX = math.max(S.lootRadius.frame.AbsoluteSize.X, 1)
            local relativeX = math.clamp(input.Position.X - S.lootRadius.frame.AbsolutePosition.X, 0, sizeX)
            local percentage = math.clamp(relativeX / sizeX, 0, 1)
            local radiusVal = math.floor(10 + (100 - 10) * percentage)
            State.LootRadius = radiusVal
            S.lootRadius.fill.Size = UDim2.new(percentage, 0, 1, 0)
            S.lootRadius.text.Text = tostring(radiusVal) .. " studs"
            S.lootRadius.title.Text = "ระยะดูดไอเทม: " .. tostring(radiusVal) .. " studs"
        end

        S.lootRadius.btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                State.draggingLoot = true
                updateLootSlider(input)
            end
        end)
        Cleanup.conn(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                State.draggingLoot = false
            end
        end))
        Cleanup.conn(UserInputService.InputChanged:Connect(function(input)
            if State.draggingLoot and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateLootSlider(input)
            end
        end))
    end

    -- ============ 🚀 Smart Target Teleport & Anti-Detection ============
    function World.teleportToTarget(target, offsetMode)
        if not target then
            if UI.showNotif then UI.showNotif("⚠️ ไม่พบเป้าหมาย", 2) end
            return false
        end

        local myChar = LocalPlayer.Character
        local myHrp = myChar and (myChar:FindFirstChild("HumanoidRootPart") or myChar:FindFirstChild("Torso") or myChar.PrimaryPart)
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        if not myChar or not myHrp or not myHum or myHum.Health <= 0 then
            if UI.showNotif then UI.showNotif("⚠️ ตัวละครของคุณยังไม่พร้อมวาร์ป", 2) end
            return false
        end

        local targetChar = env.Scanner and env.Scanner.getCharacter(target)
        local targetHrp = env.Scanner and env.Scanner.getRootPart(target)
        local targetName = env.Scanner and env.Scanner.getName(target) or "เป้าหมาย"
        local isAlive = env.Scanner and env.Scanner.isAlive(target)

        if not targetChar or not targetHrp or not isAlive then
            if UI.showNotif then UI.showNotif("⚠️ เป้าหมายไม่อยู่ในเกมหรือตายแล้ว", 2) end
            return false
        end

        local mode = offsetMode or State.WarpOffset or "Behind"

        -- 1. คำนวณตำแหน่งปลายทาง (CFrame) ตามโหมด
        local jitterX = (math.random(-15, 15) / 100)
        local jitterZ = (math.random(-15, 15) / 100)
        local destCFrame

        if mode == "Behind" then
            destCFrame = targetHrp.CFrame * CFrame.new(jitterX, 0, 3.2 + jitterZ)
        elseif mode == "Above" then
            destCFrame = targetHrp.CFrame * CFrame.new(jitterX, 5.5, jitterZ)
        elseif mode == "Front" then
            destCFrame = targetHrp.CFrame * CFrame.new(jitterX, 0, -3.2 + jitterZ) * CFrame.Angles(0, math.rad(180), 0)
        else
            destCFrame = targetHrp.CFrame * CFrame.new(jitterX, 0, 3.0 + jitterZ)
        end

        -- 2. Anti-Detection & Safe Landing: Raycast ตรวจจับพื้น ไม่ให้จมดินหรือตกแมพ
        pcall(function()
            local rayOrigin = destCFrame.Position + Vector3.new(0, 3, 0)
            local rayDir = Vector3.new(0, -15, 0)
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = { myChar, targetChar }
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local hit = workspace:Raycast(rayOrigin, rayDir, rayParams)
            if hit and hit.Position then
                local floorY = hit.Position.Y + (myHrp.Size.Y / 2) + 0.5
                if mode ~= "Above" then
                    destCFrame = CFrame.new(destCFrame.X, floorY, destCFrame.Z) * (destCFrame - destCFrame.Position)
                end
            end
        end)

        -- 3. Anti-Detection: Reset Velocity & Physics
        pcall(function()
            myHrp.AssemblyLinearVelocity = Vector3.zero
            myHrp.AssemblyAngularVelocity = Vector3.zero
            if myHum then
                myHum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)

        -- 4. Temporary Collision Buffer (0.2s) ป้องกันการชน Object แล้ว Fling
        task.spawn(function()
            for _, p in ipairs(myChar:GetChildren()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
            task.wait(0.2)
            if myChar and myHrp and myHrp.Parent then
                for _, p in ipairs(myChar:GetChildren()) do
                    if p:IsA("BasePart") and p ~= myHrp then p.CanCollide = true end
                end
            end
        end)

        -- 5. ทำการวาร์ป (PivotTo + CFrame Fallback)
        pcall(function()
            myChar:PivotTo(destCFrame)
            myHrp.CFrame = destCFrame
        end)

        -- 6. หันมุมกล้องมองไปที่เป้าหมาย
        local cam = env.Camera or workspace.CurrentCamera
        if cam then
            pcall(function()
                cam.CFrame = CFrame.new(cam.CFrame.Position, targetHrp.Position + Vector3.new(0, 1.5, 0))
            end)
        end

        if UI.showNotif then
            UI.showNotif("🚀 วาร์ปไปหา: " .. tostring(targetName), 2)
        end
        if Logger then
            Logger.info("World", "Warp", "Teleported to " .. tostring(targetName) .. " (" .. mode .. ")")
        end
        return true
    end

    function World.warpToLockedTarget()
        -- 1. ตรวจสอบ Hard Lock ก่อน
        if State.hardLockedPlayer and env.Scanner and env.Scanner.isAlive(State.hardLockedPlayer) then
            return World.teleportToTarget(State.hardLockedPlayer)
        end

        -- 2. ตรวจสอบ Current Aimbot Target
        if State.currentTarget and env.Scanner and env.Scanner.isAlive(State.currentTarget) then
            return World.teleportToTarget(State.currentTarget)
        end

        -- 3. ตรวจสอบ Selected Warp Target จากเมนู
        if State.selectedWarpTarget and env.Scanner and env.Scanner.isAlive(State.selectedWarpTarget) then
            return World.teleportToTarget(State.selectedWarpTarget)
        end

        -- 4. ค้นหาศัตรูที่ใกล้เมาส์ที่สุดตามวง FOV
        local cam = env.Camera or workspace.CurrentCamera
        if cam and env.Scanner and env.Scanner.getCharacter then
            local mousePos = UserInputService:GetMouseLocation()
            local shortestDist = math.huge
            local bestTarget = nil

            local targets = {}
            for _, p in pairs(env.Players:GetPlayers()) do
                if p ~= LocalPlayer and (not env.isSameTeam or not env.isSameTeam(p)) then
                    targets[#targets + 1] = p
                end
            end
            if State.TargetBotsEnabled and env.Scanner.getNPCs then
                local npcs = env.Scanner.getNPCs()
                for _, npc in ipairs(npcs) do
                    if not env.isSameTeam or not env.isSameTeam(npc) then
                        targets[#targets + 1] = npc
                    end
                end
            end

            for _, t in ipairs(targets) do
                local hrp = env.Scanner.getRootPart(t)
                local isAlive = env.Scanner.isAlive(t)
                if hrp and isAlive then
                    local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            bestTarget = t
                        end
                    end
                end
            end

            if bestTarget then
                return World.teleportToTarget(bestTarget)
            end
        end

        if UI.showNotif then
            UI.showNotif("⚠️ ไม่พบเป้าหมายที่กำลังล็อคอยู่", 2)
        end
        return false
    end

    -- ============ ⚡ Fake Lag / Burst Desync Engine ============
    local fakeLagConnection = nil
    local isBurstActive = false
    local lastDesyncTick = 0
    local isPacketSleeping = false

    local function updateFakeLagState()
        local shouldLag = State.FakeLagEnabled or isBurstActive
        if shouldLag and not fakeLagConnection then
            fakeLagConnection = RunService.Heartbeat:Connect(Guard.safeLoop("World", "FakeLagLoop", function()
                local char = LocalPlayer.Character
                local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
                if not hrp then return end

                local limit = State.FakeLagLimit or 0.3
                local now = tick()

                if (now - lastDesyncTick) < limit then
                    -- สั่งระงับการส่งพิกัดชั่วคราว (Choke Packets / Network Sleep)
                    if sethiddenproperty then
                        pcall(sethiddenproperty, hrp, "NetworkIsSleeping", true)
                    end
                    isPacketSleeping = true
                else
                    -- ปล่อยพิกัดให้เด้งวาร์ปไปยังตำแหน่งปัจจุบัน (Flush State)
                    if sethiddenproperty and isPacketSleeping then
                        pcall(sethiddenproperty, hrp, "NetworkIsSleeping", false)
                    end
                    isPacketSleeping = false
                    lastDesyncTick = now
                end
            end))
            Cleanup.conn(fakeLagConnection)
        elseif not shouldLag and fakeLagConnection then
            fakeLagConnection:Disconnect()
            fakeLagConnection = nil
            local char = LocalPlayer.Character
            local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char.PrimaryPart)
            if hrp and sethiddenproperty then
                pcall(sethiddenproperty, hrp, "NetworkIsSleeping", false)
            end
            isPacketSleeping = false
        end
    end

    function World.toggleFakeLag()
        State.FakeLagEnabled = not State.FakeLagEnabled
        updateFakeLagState()
        if B.fakeLag then
            B.fakeLag.Text = State.FakeLagEnabled and "⚡ จำลองปิง/เน็ตแลค (Fake Lag): เปิด" or "⚡ จำลองปิง/เน็ตแลค (Fake Lag): ปิด"
            B.fakeLag.BackgroundColor3 = State.FakeLagEnabled and UIF.Theme.AccentGreen or UIF.Theme.CardBg
            B.fakeLag.TextColor3 = State.FakeLagEnabled and UIF.Theme.TextDark or UIF.Theme.Text
        end
        if UI.showNotif then
            UI.showNotif(State.FakeLagEnabled and "⚡ เปิดระบบ Fake Lag (คนอื่นจะเห็นเราวาร์ป)" or "⚡ ปิดระบบ Fake Lag", 2)
        end
    end

    function World.setFakeLag(enabled)
        if State.FakeLagEnabled ~= enabled then
            State.FakeLagEnabled = enabled
            updateFakeLagState()
            if B.fakeLag then
                B.fakeLag.Text = State.FakeLagEnabled and "⚡ จำลองปิง/เน็ตแลค (Fake Lag): เปิด" or "⚡ จำลองปิง/เน็ตแลค (Fake Lag): ปิด"
                B.fakeLag.BackgroundColor3 = State.FakeLagEnabled and UIF.Theme.AccentGreen or UIF.Theme.CardBg
                B.fakeLag.TextColor3 = State.FakeLagEnabled and UIF.Theme.TextDark or UIF.Theme.Text
            end
        end
    end

    function World.setBurstLag(active)
        isBurstActive = active
        updateFakeLagState()
    end

    -- ============ 📍 Waypoint (เซฟจุด & วาร์ปกลับ) ============
    local savedWaypoint = nil

    function World.saveWaypoint()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            savedWaypoint = hrp.CFrame
            if UI and UI.showNotif then UI.showNotif("💾 เซฟจุดเรียบร้อยแล้ว!", 2) end
        else
            if UI and UI.showNotif then UI.showNotif("❌ ไม่พบตัวละครของคุณ", 2) end
        end
    end

    function World.tpToWaypoint()
        if not savedWaypoint then
            if UI and UI.showNotif then UI.showNotif("❌ คุณยังไม่ได้เซฟจุด!", 2) end
            return
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if char and hrp then
            pcall(function()
                char:PivotTo(savedWaypoint)
                hrp.CFrame = savedWaypoint
            end)
            if UI and UI.showNotif then UI.showNotif("🚀 วาร์ปกลับจุดเซฟแล้ว!", 2) end
        else
            if UI and UI.showNotif then UI.showNotif("❌ ไม่พบตัวละครของคุณ", 2) end
        end
    end

    return World
end

end)()
if type(__factory_world) ~= "function" then error("Module world did not return a factory function") end

-- ========== MODULE: godmode ==========
local __factory_godmode = (function()
-- ============================================================================
-- godmode.lua — ระบบ God Mode ป้องกันตาย / ฟื้น HP อัตโนมัติ (Adaptive)
--
-- ระบบจะตรวจสอบ env.GameProfile ที่ได้จาก Scanner 
-- และเลือกใช้ Adapter ที่เหมาะสมที่สุดสำหรับระบบเลือดของเกม
--
-- โหมด (สลับได้ผ่าน UI):
--   "Regen"   — ฟื้น HP ทันทีเมื่อ HP ต่ำกว่า threshold
--   "Lock"    — ล็อค HP = MaxHP ทุก Heartbeat 
--   "Hook"    — Hook เพื่อ block damage ก่อนถึง server (เฉพาะ DefaultHumanoid)
-- ============================================================================

return function(env)
    local RunService  = env.RunService
    local LocalPlayer = env.LocalPlayer
    local Cleanup     = env.Cleanup
    local UIF         = env.UIF
    local State       = env.State
    local Logger      = env.Logger or { info=function()end, warn=function()end, error=function()end }
    local Guard       = env.Guard  or { safeLoop=function(_,_,fn) return fn end }

    local UI  = env.UI
    local B   = UI.buttons

    local GodMode = {}

    -- ====================================================================
    -- STATE & PROFILE
    -- ====================================================================
    State.GodModeEnabled = false
    State.GodModeStyle   = "Regen"   -- "Regen" | "Lock" | "Hook"

    local Profile = env.GameProfile or { Type = "Unknown" }

    -- อัปเดต UI Label ของ Scanner ถ้ามี
    if UI.labels and UI.labels.scanResult then
        UI.labels.scanResult.Text = "🔍 System Detected: " .. (Profile.Desc or "ไม่ทราบ")
    end

    local REGEN_THRESHOLD = 0.97
    local REGEN_RATE      = 0.016

    local godLoopConn       = nil
    local hookCleanupFn     = nil
    local takeDamageHook    = nil
    local characterConn     = nil

    -- ====================================================================
    -- UI UPDATE
    -- ====================================================================
    local styleNames = {
        Regen = "Regen (ฟื้นเมื่อโดน)",
        Lock  = "Lock (ล็อค HP)",
        Hook  = "Hook (บล็อคดาเมจ)"
    }

    local function updateUI()
        if not B.godMode then return end
        if State.GodModeEnabled then
            B.godMode.Text = "💚 God Mode [" .. styleNames[State.GodModeStyle] .. "]: เปิด"
            B.godMode.BackgroundColor3 = UIF.Theme.AccentGreen
            B.godMode.TextColor3 = UIF.Theme.TextDark
        else
            B.godMode.Text = "💚 God Mode: ปิด"
            B.godMode.BackgroundColor3 = UIF.Theme.CardBg
            B.godMode.TextColor3 = UIF.Theme.Text
        end
        if B.godModeStyle then
            B.godModeStyle.Text = "🔄 โหมด God: " .. styleNames[State.GodModeStyle] .. " (คลิกสลับ)"
        end
    end

    -- ====================================================================
    -- ADAPTER: DEFAULT HUMANOID
    -- ====================================================================
    local function getHumanoid()
        local char = LocalPlayer.Character
        return char and char:FindFirstChildOfClass("Humanoid")
    end

    local function startDefaultRegen()
        godLoopConn = Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("GodMode", "DefaultRegen", function()
            if not State.GodModeEnabled then return end
            local hum = getHumanoid()
            if not hum or hum.MaxHealth <= 0 then return end
            local ratio = hum.Health / hum.MaxHealth
            if ratio < REGEN_THRESHOLD then
                local healAmt = math.min(hum.MaxHealth - hum.Health, hum.MaxHealth * REGEN_RATE * 60)
                pcall(function() hum.Health = math.min(hum.MaxHealth, hum.Health + healAmt) end)
            end
        end)))
    end

    local function startDefaultLock()
        godLoopConn = Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("GodMode", "DefaultLock", function()
            if not State.GodModeEnabled then return end
            local hum = getHumanoid()
            if not hum or hum.MaxHealth <= 0 then return end
            if hum.Health < hum.MaxHealth then
                pcall(function() hum.Health = hum.MaxHealth end)
            end
        end)))
    end

    local function startDefaultHook()
        if not hookfunction or not newcclosure then
            Logger.warn("GodMode", "HookMode", "hookfunction ไม่พบ — fallback เป็น Regen mode")
            State.GodModeStyle = "Regen"
            updateUI()
            startDefaultRegen()
            return
        end

        local function hookCurrentCharacter()
            local hum = getHumanoid()
            if not hum then return end

            if takeDamageHook then
                pcall(hookCleanupFn)
                takeDamageHook = nil
                hookCleanupFn = nil
            end

            local originalTakeDamage = hum.TakeDamage
            takeDamageHook = hookfunction(originalTakeDamage, newcclosure(function(self, amount)
                if State.GodModeEnabled and State.GodModeStyle == "Hook" then return end
                return originalTakeDamage(self, amount)
            end))

            hookCleanupFn = function()
                if takeDamageHook then
                    pcall(hookfunction, originalTakeDamage, takeDamageHook)
                    takeDamageHook = nil
                end
            end
        end

        hookCurrentCharacter()

        if characterConn then characterConn:Disconnect() end
        characterConn = Cleanup.conn(LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            hookCurrentCharacter()
        end))
    end

    -- ====================================================================
    -- ADAPTER: CUSTOM VALUE (IntValue, NumberValue)
    -- ====================================================================
    local function getCustomValues()
        local char = LocalPlayer.Character
        if not char then return nil, nil end
        
        local hObj, mhObj
        -- พยายามใช้ Object จาก Profile ก่อน
        if Profile.HealthObj and Profile.HealthObj.Parent then
            hObj = Profile.HealthObj
        end
        if Profile.MaxHealthObj and Profile.MaxHealthObj.Parent then
            mhObj = Profile.MaxHealthObj
        end
        
        -- ถ้าหายไป ให้ลองค้นหาใหม่ (กรณี respawn)
        if not hObj or not mhObj then
            local scanner = env.Scanner
            if scanner then 
                local newProf = scanner.runScan()
                hObj = newProf.HealthObj
                mhObj = newProf.MaxHealthObj
            end
        end
        return hObj, mhObj
    end

    local function startCustomValueRegen()
        godLoopConn = Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("GodMode", "CustomRegen", function()
            if not State.GodModeEnabled then return end
            local hObj, mhObj = getCustomValues()
            if not hObj then return end
            
            local current = hObj.Value
            local max = mhObj and mhObj.Value or 100
            
            if max <= 0 then return end
            local ratio = current / max
            if ratio < REGEN_THRESHOLD then
                local healAmt = math.min(max - current, max * REGEN_RATE * 60)
                pcall(function() hObj.Value = math.min(max, current + healAmt) end)
            end
        end)))
    end

    local function startCustomValueLock()
        godLoopConn = Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("GodMode", "CustomLock", function()
            if not State.GodModeEnabled then return end
            local hObj, mhObj = getCustomValues()
            if not hObj then return end
            
            local max = mhObj and mhObj.Value or 100
            if hObj.Value < max then
                pcall(function() hObj.Value = max end)
            end
        end)))
    end

    -- ====================================================================
    -- ADAPTER: ATTRIBUTES
    -- ====================================================================
    local function getAttributeNames()
        return Profile.HealthObj, Profile.MaxHealthObj -- These are strings
    end

    local function startAttributeRegen()
        godLoopConn = Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("GodMode", "AttrRegen", function()
            if not State.GodModeEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            
            local hName, mhName = getAttributeNames()
            if type(hName) ~= "string" then return end
            
            local current = char:GetAttribute(hName)
            local max = mhName and char:GetAttribute(mhName) or 100
            
            if type(current) ~= "number" or type(max) ~= "number" or max <= 0 then return end
            
            local ratio = current / max
            if ratio < REGEN_THRESHOLD then
                local healAmt = math.min(max - current, max * REGEN_RATE * 60)
                pcall(function() char:SetAttribute(hName, math.min(max, current + healAmt)) end)
            end
        end)))
    end

    local function startAttributeLock()
        godLoopConn = Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("GodMode", "AttrLock", function()
            if not State.GodModeEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            
            local hName, mhName = getAttributeNames()
            if type(hName) ~= "string" then return end
            
            local current = char:GetAttribute(hName)
            local max = mhName and char:GetAttribute(mhName) or 100
            
            if type(current) ~= "number" or type(max) ~= "number" then return end
            
            if current < max then
                pcall(function() char:SetAttribute(hName, max) end)
            end
        end)))
    end

    -- ====================================================================
    -- ENABLE / DISABLE & ROUTING
    -- ====================================================================
    local function stopCurrentMode()
        if godLoopConn then godLoopConn:Disconnect(); godLoopConn = nil end
        if hookCleanupFn then pcall(hookCleanupFn); hookCleanupFn = nil end
        takeDamageHook = nil
    end

    local function enableGodMode()
        State.GodModeEnabled = true
        stopCurrentMode()

        -- สแกนใหม่ก่อนเริ่มเผื่อเพิ่งเปลี่ยนตัวละคร
        if env.Scanner then
            Profile = env.Scanner.runScan()
            if UI.labels and UI.labels.scanResult then
                UI.labels.scanResult.Text = "🔍 System Detected: " .. (Profile.Desc or "ไม่ทราบ")
            end
        end

        local sysType = Profile.Type

        if sysType == "CustomValue" then
            if State.GodModeStyle == "Lock" then startCustomValueLock() else startCustomValueRegen() end
        elseif sysType == "Attribute" then
            if State.GodModeStyle == "Lock" then startAttributeLock() else startAttributeRegen() end
        else
            -- DefaultHumanoid หรือ Unknown (Fallback to Humanoid)
            if State.GodModeStyle == "Lock" then
                startDefaultLock()
            elseif State.GodModeStyle == "Hook" then
                startDefaultHook()
            else
                startDefaultRegen()
            end
        end

        updateUI()
        Logger.info("GodMode", "Enable", "God Mode (Adapter: " .. sysType .. ") เปิด: " .. State.GodModeStyle)
    end

    local function disableGodMode()
        State.GodModeEnabled = false
        stopCurrentMode()
        updateUI()
        Logger.info("GodMode", "Disable", "God Mode ปิด")
    end

    -- ====================================================================
    -- STYLE CYCLE
    -- ====================================================================
    local styleOrder = { "Regen", "Lock", "Hook" }

    local function cycleStyle()
        local currentIdx = 1
        for i, s in ipairs(styleOrder) do
            if s == State.GodModeStyle then currentIdx = i; break end
        end
        local nextIdx = (currentIdx % #styleOrder) + 1
        
        -- CustomValue & Attribute ไม่รองรับ Hook (ณ ตอนนี้) ดังนั้นข้ามไป Regen เลย
        local sysType = Profile.Type
        if (sysType == "CustomValue" or sysType == "Attribute") and styleOrder[nextIdx] == "Hook" then
            nextIdx = 1
        end
        
        State.GodModeStyle = styleOrder[nextIdx]

        if State.GodModeEnabled then
            enableGodMode()
        else
            updateUI()
        end
    end

    -- ====================================================================
    -- PUBLIC API
    -- ====================================================================
    function GodMode.toggle()
        if State.GodModeEnabled then disableGodMode() else enableGodMode() end
    end

    function GodMode.setGodMode(enabled)
        if State.GodModeEnabled ~= enabled then
            if enabled then enableGodMode() else disableGodMode() end
        end
    end

    function GodMode.setStyle(style)
        if styleNames[style] then
            State.GodModeStyle = style
            if State.GodModeEnabled then enableGodMode() end
            updateUI()
        end
    end

    function GodMode.cycleStyle()
        cycleStyle()
    end

    -- ====================================================================
    -- WIRING & EVENTS
    -- ====================================================================
    if B.godMode then B.godMode.Activated:Connect(GodMode.toggle) end
    if B.godModeStyle then B.godModeStyle.Activated:Connect(GodMode.cycleStyle) end

    Cleanup.conn(LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.5)
        if State.GodModeEnabled then
            -- สแกนซ้ำเมื่อตัวละครใหม่เกิดเผื่อ object ใหม่
            if env.Scanner then
                Profile = env.Scanner.runScan()
            end
        end
    end))

    Cleanup.addCallback(function()
        stopCurrentMode()
    end)

    updateUI()
    Logger.info("GodMode", "Init", "God Mode System Ready. Type: " .. Profile.Type)

    return GodMode
end
end)()
if type(__factory_godmode) ~= "function" then error("Module godmode did not return a factory function") end

-- ========== MODULE: config ==========
local __factory_config = (function()
return function(env)
    local HttpService = game:GetService("HttpService")
    local UserInputService = env.UserInputService
    local State = env.State
    local UI = env.UI
    local UIF = env.UIF
    local Logger = env.Logger
    local FriendlyPlayers = env.FriendlyPlayers

    local Config = {}
    local configFileName = "UtilityHub_Data/UtilityHub_config.json"
    local memoryConfig = nil

    local function getKeyCodeName(keyCode)
        if typeof(keyCode) == "EnumItem" then
            return keyCode.Name
        elseif type(keyCode) == "string" then
            return keyCode
        end
        return "Unknown"
    end

    local function parseKeyCode(name)
        if type(name) == "string" and Enum.KeyCode[name] then
            return Enum.KeyCode[name]
        end
        return nil
    end

    -- ฟังก์ชันดึง State ปัจจุบันเป็น Table ที่ Serialize ได้
    function Config.exportCurrentState()
        local bindingsExport = {}
        for k, v in pairs(State.Bindings) do
            bindingsExport[k] = getKeyCodeName(v)
        end

        local teamExport = {}
        for name, v in pairs(FriendlyPlayers) do
            if v then teamExport[name] = true end
        end

        local currentSpeed = 16
        pcall(function()
            local char = game:GetService("Players").LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                currentSpeed = char.Humanoid.WalkSpeed
            end
        end)

        return {
            Version = "2.0",
            TeamCheckEnabled = State.TeamCheckEnabled,
            FriendCheckEnabled = State.FriendCheckEnabled,

            -- Combat
            TargetBotsEnabled = State.TargetBotsEnabled,
            FOVEnabled = State.FOVEnabled,
            FOVRadius = State.FOVRadius or 150,
            AimTargetPart = State.AimTargetPart or "Head",
            WallCheckEnabled = State.WallCheckEnabled,
            PredictionEnabled = State.PredictionEnabled,
            PredictionAmt = State.PredictionAmt or 0.1,
            AutoShootEnabled = State.AutoShootEnabled,
            SilentAimEnabled = State.SilentAimEnabled,
            SmartBoneEnabled = State.SmartBoneEnabled,
            BallisticsEnabled = State.BallisticsEnabled,
            BulletSpeed = State.BulletSpeed or 1000,
            HitboxEnabled = State.HitboxEnabled,
            HitboxPart = State.HitboxPart or "Head",
            HitboxSize = State.HitboxSize or 10,
            HitboxTransparency = State.HitboxTransparency or 0.5,

            -- Visuals
            PlayerESPEnabled = env.ESP and env.ESP.isPlayerESPOn and env.ESP.isPlayerESPOn() or State.PlayerESPEnabled,
            BotESPEnabled = env.ESP and env.ESP.isBotESPOn and env.ESP.isBotESPOn() or State.BotESPEnabled,
            CorpseESPEnabled = State.CorpseESPEnabled,
            WeaponESPEnabled = State.WeaponESPEnabled,
            TracersEnabled = State.TracersEnabled,
            TracerMode = State.TracerMode or "All",
            TracerThickness = State.TracerThickness or 1.0,
            StatsEnabled = State.StatsEnabled,
            GunWarningEnabled = State.GunWarningEnabled,

            -- World
            InfJumpEnabled = State.InfJumpEnabled,
            NoClipEnabled = State.NoClipEnabled,
            AlwaysDayEnabled = State.AlwaysDayEnabled,
            HitSoundEnabled = State.HitSoundEnabled,
            FPSBoostEnabled = State.FPSBoostEnabled,
            ObjectScaleMultiplier = State.ObjectScaleMultiplier or 2.0,
            ObjectScaleAxis = State.ObjectScaleAxis or "All",
            AntiFallEnabled = State.AntiFallEnabled,
            AutoLootEnabled = State.AutoLootEnabled,
            LootRadius = State.LootRadius or 30,
            WalkSpeed = currentSpeed,
            GodModeEnabled = State.GodModeEnabled,
            GodModeStyle = State.GodModeStyle or "Regen",
            WarpOffset = State.WarpOffset or "Behind",
            AutoRejoinEnabled = State.AutoRejoinEnabled,
            FakeLagEnabled = State.FakeLagEnabled,
            FakeLagLimit = State.FakeLagLimit or 0.3,

            -- Bindings & Team
            Bindings = bindingsExport,
            FriendlyPlayers = teamExport
        }
    end

    -- นำ Table ข้อมูลกลับมา Apply ลงใน State และ UI ของทุกโมดูล
    function Config.applyData(data)
        if not data or type(data) ~= "table" then return false end

        -- 1. อัปเดต Bindings
        if data.Bindings and type(data.Bindings) == "table" then
            for k, keyName in pairs(data.Bindings) do
                local kc = parseKeyCode(keyName)
                if kc and State.Bindings[k] ~= nil then
                    State.Bindings[k] = kc
                end
            end
        end

        -- 2. อัปเดต Friendly Players
        if data.FriendlyPlayers and type(data.FriendlyPlayers) == "table" then
            for k in pairs(FriendlyPlayers) do FriendlyPlayers[k] = nil end
            for name, v in pairs(data.FriendlyPlayers) do
                if v then FriendlyPlayers[name] = true end
            end
            if UI and UI.refreshTeamList then UI.refreshTeamList() end
        end

        -- 3. อัปเดต Sliders และค่าตัวเลข
        if data.FOVRadius and UI and UI.sliders and UI.sliders.fov then
            State.FOVRadius = math.clamp(tonumber(data.FOVRadius) or 150, 30, 600)
            local pct = (State.FOVRadius - 30) / (600 - 30)
            UI.sliders.fov.fill.Size = UDim2.new(pct, 0, 1, 0)
            UI.sliders.fov.text.Text = tostring(math.floor(State.FOVRadius))
            UI.sliders.fov.title.Text = "ขนาดวง FOV: " .. tostring(math.floor(State.FOVRadius))
            local fovFrame = UI.ScreenGui and UI.ScreenGui:FindFirstChild("FOVFrame")
            if fovFrame then fovFrame.Size = UDim2.new(0, State.FOVRadius * 2, 0, State.FOVRadius * 2) end
        end

        if data.PredictionAmt and UI and UI.sliders and UI.sliders.pred then
            State.PredictionAmt = math.clamp(tonumber(data.PredictionAmt) or 0.1, 0.01, 0.5)
            local pct = (State.PredictionAmt - 0.01) / (0.5 - 0.01)
            UI.sliders.pred.fill.Size = UDim2.new(pct, 0, 1, 0)
            UI.sliders.pred.text.Text = "🔮 ค่าดักหน้ากระสุน: " .. tostring(State.PredictionAmt)
        end

        if data.TracerThickness and UI and UI.sliders and UI.sliders.tracerThickness then
            State.TracerThickness = math.clamp(tonumber(data.TracerThickness) or 1.5, 1.0, 6.0)
            local pct = (State.TracerThickness - 1.0) / (6.0 - 1.0)
            UI.sliders.tracerThickness.fill.Size = UDim2.new(pct, 0, 1, 0)
            UI.sliders.tracerThickness.text.Text = string.format("%.1f px", State.TracerThickness)
            UI.sliders.tracerThickness.title.Text = "ขนาดความหนาเส้น (Thickness): " .. string.format("%.1f px", State.TracerThickness)
        end

        if data.WalkSpeed and UI and UI.sliders and UI.sliders.speed then
            local spd = math.clamp(tonumber(data.WalkSpeed) or 16, 16, 250)
            local pct = (spd - 16) / (250 - 16)
            UI.sliders.speed.fill.Size = UDim2.new(pct, 0, 1, 0)
            UI.sliders.speed.text.Text = tostring(math.floor(spd))
            UI.sliders.speed.title.Text = "ความเร็ววิ่ง: " .. tostring(math.floor(spd))
            pcall(function()
                local char = game:GetService("Players").LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.WalkSpeed = spd
                end
            end)
        end

        if data.HitboxSize and UI and UI.sliders and UI.sliders.hitboxSize then
            State.HitboxSize = math.clamp(tonumber(data.HitboxSize) or 10, 2, 30)
            local pct = (State.HitboxSize - 2) / (30 - 2)
            UI.sliders.hitboxSize.fill.Size = UDim2.new(pct, 0, 1, 0)
            UI.sliders.hitboxSize.text.Text = tostring(State.HitboxSize) .. " studs"
            UI.sliders.hitboxSize.title.Text = "ขนาด Hitbox: " .. tostring(State.HitboxSize) .. " studs"
        end

        if data.ObjectScaleMultiplier and UI and UI.sliders and UI.sliders.scaleAmt then
            State.ObjectScaleMultiplier = math.clamp(tonumber(data.ObjectScaleMultiplier) or 2.0, 0.1, 30.0)
            local pct = (State.ObjectScaleMultiplier - 0.1) / (30.0 - 0.1)
            UI.sliders.scaleAmt.fill.Size = UDim2.new(pct, 0, 1, 0)
            UI.sliders.scaleAmt.text.Text = string.format("%.1fx", State.ObjectScaleMultiplier)
            UI.sliders.scaleAmt.title.Text = "ตัวคูณขนาด (Scale): " .. string.format("%.1fx", State.ObjectScaleMultiplier)
        end

        if data.LootRadius and UI and UI.sliders and UI.sliders.lootRadius then
            State.LootRadius = math.clamp(tonumber(data.LootRadius) or 30, 10, 100)
            local pct = (State.LootRadius - 10) / (100 - 10)
            UI.sliders.lootRadius.fill.Size = UDim2.new(pct, 0, 1, 0)
            UI.sliders.lootRadius.text.Text = tostring(State.LootRadius) .. " studs"
            UI.sliders.lootRadius.title.Text = "ระยะดูดไอเทม: " .. tostring(State.LootRadius) .. " studs"
        end

        -- 4. อัปเดต Aim Part & Hitbox Part
        if data.AimTargetPart ~= nil and data.AimTargetPart ~= State.AimTargetPart then
            State.AimTargetPart = data.AimTargetPart
            if UI and UI.buttons and UI.buttons.aimPart then
                if State.AimTargetPart == "Head" then
                    UI.buttons.aimPart.Text = "🎯 เล็งเป้า: หัว (คลิกสลับ)"
                else
                    UI.buttons.aimPart.Text = "🎯 เล็งเป้า: ลำตัว (คลิกสลับ)"
                end
            end
        end

        if data.HitboxPart and env.Aimbot and env.Aimbot.setHitboxPart then
            env.Aimbot.setHitboxPart(data.HitboxPart)
        end

        if data.ObjectScaleAxis and UI and UI.buttons and UI.buttons.scaleAxis then
            State.ObjectScaleAxis = data.ObjectScaleAxis
            if State.ObjectScaleAxis == "X" then
                UI.buttons.scaleAxis.Text = "📐 แกนที่ปรับ: แกน X (ความกว้าง)"
            elseif State.ObjectScaleAxis == "Y" then
                UI.buttons.scaleAxis.Text = "📐 แกนที่ปรับ: แกน Y (ความสูง)"
            elseif State.ObjectScaleAxis == "Z" then
                UI.buttons.scaleAxis.Text = "📐 แกนที่ปรับ: แกน Z (ความยาว)"
            else
                UI.buttons.scaleAxis.Text = "📐 แกนที่ปรับ: ทุกด้าน (X, Y, Z)"
            end
        end

        -- 5. อัปเดต Tracer Mode
        if data.TracerMode ~= nil and data.TracerMode ~= State.TracerMode then
            State.TracerMode = data.TracerMode
            if UI and UI.buttons and UI.buttons.tracerMode then
                if State.TracerMode == "Closest" then
                    UI.buttons.tracerMode.Text = "🧶 โหมดเส้น: คนที่ถูกล็อค (คลิกสลับ)"
                else
                    UI.buttons.tracerMode.Text = "🧶 โหมดเส้น: ทุกคน (คลิกสลับ)"
                end
            end
        end

        -- Combat Toggles
        if data.TargetBotsEnabled ~= nil and env.Aimbot and env.Aimbot.setTargetBots then
            env.Aimbot.setTargetBots(data.TargetBotsEnabled)
        end
        if data.FOVEnabled ~= nil and env.Aimbot and env.Aimbot.setFOV then
            env.Aimbot.setFOV(data.FOVEnabled)
        end
        if data.WallCheckEnabled ~= nil and env.Aimbot and env.Aimbot.setWallCheck then
            env.Aimbot.setWallCheck(data.WallCheckEnabled)
        end
        if data.PredictionEnabled ~= nil and env.Aimbot and env.Aimbot.setPrediction then
            env.Aimbot.setPrediction(data.PredictionEnabled)
        end
        if data.AutoShootEnabled ~= nil and env.Aimbot and env.Aimbot.setAutoShoot then
            env.Aimbot.setAutoShoot(data.AutoShootEnabled)
        end
        if data.SilentAimEnabled ~= nil and env.Aimbot and env.Aimbot.setSilentAim then
            env.Aimbot.setSilentAim(data.SilentAimEnabled)
        end
        if data.SmartBoneEnabled ~= nil and env.Aimbot and env.Aimbot.setSmartBone then
            env.Aimbot.setSmartBone(data.SmartBoneEnabled)
        end
        if data.BallisticsEnabled ~= nil and env.Aimbot and env.Aimbot.setBallistics then
            env.Aimbot.setBallistics(data.BallisticsEnabled)
        end
        if data.BulletSpeed ~= nil and env.Aimbot and env.Aimbot.setBulletSpeed then
            env.Aimbot.setBulletSpeed(data.BulletSpeed)
        end
        if data.HitboxEnabled ~= nil and env.Aimbot and env.Aimbot.setHitbox then
            env.Aimbot.setHitbox(data.HitboxEnabled)
        end

        -- Visuals Toggles
        if data.PlayerESPEnabled ~= nil and env.ESP and env.ESP.setPlayerESP then
            env.ESP.setPlayerESP(data.PlayerESPEnabled)
        end
        if data.BotESPEnabled ~= nil and env.ESP and env.ESP.setBotESP then
            env.ESP.setBotESP(data.BotESPEnabled)
        end
        if data.CorpseESPEnabled ~= nil and env.ESP and env.ESP.setCorpseESP then
            env.ESP.setCorpseESP(data.CorpseESPEnabled)
        end
        if data.WeaponESPEnabled ~= nil and env.ESP and env.ESP.setWeaponESP then
            env.ESP.setWeaponESP(data.WeaponESPEnabled)
        end
        if data.TracersEnabled ~= nil and env.Aimbot and env.Aimbot.setTracers then
            env.Aimbot.setTracers(data.TracersEnabled)
        end
        if data.StatsEnabled ~= nil and env.Aimbot and env.Aimbot.setStats then
            env.Aimbot.setStats(data.StatsEnabled)
        end
        if data.GunWarningEnabled ~= nil and env.Aimbot and env.Aimbot.setWarning then
            env.Aimbot.setWarning(data.GunWarningEnabled)
        end

        -- World Toggles
        if data.InfJumpEnabled ~= nil and env.World and env.World.setInfJump then
            env.World.setInfJump(data.InfJumpEnabled)
        end
        if data.NoClipEnabled ~= nil and env.World and env.World.setNoClip then
            env.World.setNoClip(data.NoClipEnabled)
        end
        if data.AlwaysDayEnabled ~= nil and env.World and env.World.setDay then
            env.World.setDay(data.AlwaysDayEnabled)
        end
        if data.HitSoundEnabled ~= nil and env.ESP and env.ESP.setHitSound then
            env.ESP.setHitSound(data.HitSoundEnabled)
        end
        if data.FPSBoostEnabled ~= nil and env.World and env.World.setFPSBoost then
            env.World.setFPSBoost(data.FPSBoostEnabled)
        end
        if data.AntiFallEnabled ~= nil and env.World and env.World.setAntiFall then
            env.World.setAntiFall(data.AntiFallEnabled)
        end
        if data.AutoLootEnabled ~= nil and env.World and env.World.setAutoLoot then
            env.World.setAutoLoot(data.AutoLootEnabled)
        end
        if data.GodModeEnabled ~= nil and env.GodMode and env.GodMode.setGodMode then
            if data.GodModeStyle then
                env.GodMode.setStyle(data.GodModeStyle)
            end
            env.GodMode.setGodMode(data.GodModeEnabled)
        end

        -- Team Toggles
        if data.FriendCheckEnabled ~= nil and UI and UI.buttons and UI.buttons.friendCheck then
            if State.FriendCheckEnabled ~= data.FriendCheckEnabled then
                State.FriendCheckEnabled = data.FriendCheckEnabled
                if State.FriendCheckEnabled then
                    UI.buttons.friendCheck.Text = "👥 ไม่ล็อคเพื่อนใน Roblox: เปิด"
                    UI.buttons.friendCheck.BackgroundColor3 = UIF.Theme.AccentGreen
                    UI.buttons.friendCheck.TextColor3 = UIF.Theme.TextDark
                else
                    UI.buttons.friendCheck.Text = "👥 ไม่ล็อคเพื่อนใน Roblox: ปิด"
                    UI.buttons.friendCheck.BackgroundColor3 = UIF.Theme.CardBg
                    UI.buttons.friendCheck.TextColor3 = UIF.Theme.Text
                end
            end
        end
        if data.TeamCheckEnabled ~= nil and UI and UI.buttons and UI.buttons.teamCheck then
            if State.TeamCheckEnabled ~= data.TeamCheckEnabled then
                State.TeamCheckEnabled = data.TeamCheckEnabled
                if State.TeamCheckEnabled then
                    UI.buttons.teamCheck.Text = "🛡️ ไม่ล็อคทีมในเกม: เปิด"
                    UI.buttons.teamCheck.BackgroundColor3 = UIF.Theme.AccentGreen
                    UI.buttons.teamCheck.TextColor3 = UIF.Theme.TextDark
                else
                    UI.buttons.teamCheck.Text = "🛡️ ไม่ล็อคทีมในเกม: ปิด"
                    UI.buttons.teamCheck.BackgroundColor3 = UIF.Theme.CardBg
                    UI.buttons.teamCheck.TextColor3 = UIF.Theme.Text
                end
            end
        end

        if data.WarpOffset and State.WarpOffset ~= nil then
            State.WarpOffset = data.WarpOffset
            if UI and UI.buttons and UI.buttons.warpOffset then
                if State.WarpOffset == "Above" then
                    UI.buttons.warpOffset.Text = "📍 ตำแหน่งวาร์ป: ด้านบนหัว (Above) (คลิกสลับ)"
                elseif State.WarpOffset == "Front" then
                    UI.buttons.warpOffset.Text = "📍 ตำแหน่งวาร์ป: ด้านหน้า (Front) (คลิกสลับ)"
                else
                    UI.buttons.warpOffset.Text = "📍 ตำแหน่งวาร์ป: ด้านหลัง (Behind) (คลิกสลับ)"
                end
            end
        end

        if data.AutoRejoinEnabled ~= nil and UI and UI.buttons and UI.buttons.autoRejoin then
            if State.AutoRejoinEnabled ~= data.AutoRejoinEnabled then
                State.AutoRejoinEnabled = data.AutoRejoinEnabled
                if State.AutoRejoinEnabled then
                    UI.buttons.autoRejoin.Text = "🛡️ ออโต้ Rejoin เมื่อหลุด (Anti-Disconnect): เปิด"
                    UI.buttons.autoRejoin.BackgroundColor3 = UIF.Theme.AccentGreen
                    UI.buttons.autoRejoin.TextColor3 = UIF.Theme.TextDark
                else
                    UI.buttons.autoRejoin.Text = "🛡️ ออโต้ Rejoin เมื่อหลุด (Anti-Disconnect): ปิด"
                    UI.buttons.autoRejoin.BackgroundColor3 = UIF.Theme.CardBg
                    UI.buttons.autoRejoin.TextColor3 = UIF.Theme.Text
                end
            end
        end

        if data.FakeLagEnabled ~= nil and UI and UI.buttons and UI.buttons.fakeLag then
            if State.FakeLagEnabled ~= data.FakeLagEnabled then
                State.FakeLagEnabled = data.FakeLagEnabled
                if env.World and env.World.setFakeLag then env.World.setFakeLag(data.FakeLagEnabled) end
            end
        end

        if data.FakeLagLimit and UI and UI.sliders and UI.sliders.fakeLagLimit then
            State.FakeLagLimit = data.FakeLagLimit
            local percentage = math.clamp((data.FakeLagLimit - 0.1) / (0.8 - 0.1), 0, 1)
            UI.sliders.fakeLagLimit.fill.Size = UDim2.new(percentage, 0, 1, 0)
            UI.sliders.fakeLagLimit.text.Text = string.format("%.2f s", data.FakeLagLimit)
            UI.sliders.fakeLagLimit.title.Text = "ความหน่วง Fake Lag: " .. string.format("%.2f s", data.FakeLagLimit)
        end

        return true
    end

    -- บันทึกลงไฟล์
    function Config.saveToFile(filename)
        local fname = filename or configFileName
        local data = Config.exportCurrentState()
        local encoded = HttpService:JSONEncode(data)
        memoryConfig = data

        if writefile then
            pcall(function()
                if not isfolder("UtilityHub_Data") then makefolder("UtilityHub_Data") end
            end)
            local ok, err = pcall(writefile, fname, encoded)
            if ok then
                if Logger then Logger.info("Config", "Save", "Saved to " .. fname) end
                return true, fname
            else
                if Logger then Logger.warn("Config", "SaveFileError", tostring(err)) end
                return false, "ไม่สามารถเขียนไฟล์ได้ (บันทึกลงหน่วยความจำชั่วคราวแล้ว)"
            end
        else
            return true, "(บันทึกในหน่วยความจำ RAM)"
        end
    end

    -- โหลดจากไฟล์
    function Config.loadFromFile(filename)
        local fname = filename or configFileName
        local data = nil

        if readfile and isfile and isfile(fname) then
            local ok, content = pcall(readfile, fname)
            if ok and content and #content > 0 then
                local okDec, decoded = pcall(function() return HttpService:JSONDecode(content) end)
                if okDec and decoded then
                    data = decoded
                end
            end
        end

        if not data and memoryConfig then
            data = memoryConfig
        end

        if data then
            Config.applyData(data)
            if Logger then Logger.info("Config", "Load", "Loaded config successfully") end
            return true, "โหลด Config สำเร็จ!"
        else
            return false, "ไม่พบไฟล์ Config หรือยังไม่มีการบันทึก"
        end
    end

    -- Preset Templates
    function Config.applyPreset(presetName)
        local pName = string.lower(presetName or "")
        if pName == "legit" then
            Config.applyData({
                TeamCheckEnabled = true,
                FriendCheckEnabled = true,
                TargetBotsEnabled = false,
                FOVEnabled = true,
                FOVRadius = 80,
                AimTargetPart = "Head",
                WallCheckEnabled = true,
                PredictionEnabled = true,
                PredictionAmt = 0.05,
                AutoShootEnabled = false,
                SilentAimEnabled = false,
                HitboxEnabled = false,
                HitboxPart = "Head",
                HitboxSize = 10,
                PlayerESPEnabled = true,
                BotESPEnabled = false,
                CorpseESPEnabled = false,
                WeaponESPEnabled = false,
                TracersEnabled = false,
                TracerMode = "Closest",
                TracerThickness = 1.0,
                StatsEnabled = false,
                GunWarningEnabled = true,
                InfJumpEnabled = false,
                NoClipEnabled = false,
                AlwaysDayEnabled = false,
                HitSoundEnabled = true,
                FPSBoostEnabled = false,
                ObjectScaleMultiplier = 2.0,
                ObjectScaleAxis = "All",
                AntiFallEnabled = true,
                AutoLootEnabled = false,
                LootRadius = 30,
                WalkSpeed = 16
            })
            return true, "🎯 ใช้งาน Legit Preset (สายเนียน)"
        elseif pName == "rage" then
            Config.applyData({
                TeamCheckEnabled = false,
                FriendCheckEnabled = false,
                TargetBotsEnabled = true,
                FOVEnabled = true,
                FOVRadius = 300,
                AimTargetPart = "Head",
                WallCheckEnabled = false,
                PredictionEnabled = true,
                PredictionAmt = 0.12,
                AutoShootEnabled = true,
                SilentAimEnabled = true,
                HitboxEnabled = true,
                HitboxPart = "Head",
                HitboxSize = 15,
                PlayerESPEnabled = true,
                BotESPEnabled = true,
                CorpseESPEnabled = true,
                WeaponESPEnabled = true,
                TracersEnabled = true,
                TracerMode = "All",
                TracerThickness = 1.5,
                StatsEnabled = true,
                GunWarningEnabled = true,
                InfJumpEnabled = true,
                NoClipEnabled = false,
                AlwaysDayEnabled = true,
                HitSoundEnabled = true,
                FPSBoostEnabled = false,
                ObjectScaleMultiplier = 2.0,
                ObjectScaleAxis = "All",
                AntiFallEnabled = true,
                AutoLootEnabled = true,
                LootRadius = 50,
                WalkSpeed = 24
            })
            return true, "⚡ ใช้งาน Rage Preset (สายโหด)"
        elseif pName == "pve" or pName == "bot" or pName == "monster" then
            Config.applyData({
                TeamCheckEnabled = true,
                FriendCheckEnabled = true,
                TargetBotsEnabled = true,
                FOVEnabled = true,
                FOVRadius = 250,
                AimTargetPart = "Head",
                WallCheckEnabled = false,
                PredictionEnabled = true,
                PredictionAmt = 0.1,
                AutoShootEnabled = true,
                SilentAimEnabled = true,
                SmartBoneEnabled = true,
                BallisticsEnabled = true,
                BulletSpeed = 1000,
                HitboxEnabled = true,
                HitboxPart = "Head",
                HitboxSize = 12,
                PlayerESPEnabled = false,
                BotESPEnabled = true,
                CorpseESPEnabled = true,
                WeaponESPEnabled = false,
                TracersEnabled = true,
                TracerMode = "Closest",
                TracerThickness = 1.2,
                StatsEnabled = true,
                GunWarningEnabled = false,
                InfJumpEnabled = true,
                NoClipEnabled = false,
                AlwaysDayEnabled = true,
                HitSoundEnabled = true,
                FPSBoostEnabled = true,
                AntiFallEnabled = true,
                AutoLootEnabled = true,
                LootRadius = 50,
                WalkSpeed = 24
            })
            return true, "🤖 ใช้งาน PvE Preset (ล่าบอท/ฟาร์มมอนสเตอร์)"
        elseif pName == "default" then
            Config.applyData({
                TeamCheckEnabled = true,
                FriendCheckEnabled = true,
                TargetBotsEnabled = false,
                FOVEnabled = false,
                FOVRadius = 150,
                AimTargetPart = "HumanoidRootPart",
                WallCheckEnabled = false,
                PredictionEnabled = false,
                PredictionAmt = 0.1,
                AutoShootEnabled = false,
                SilentAimEnabled = false,
                HitboxEnabled = false,
                HitboxPart = "Head",
                HitboxSize = 10,
                PlayerESPEnabled = false,
                BotESPEnabled = false,
                CorpseESPEnabled = false,
                WeaponESPEnabled = false,
                TracersEnabled = false,
                TracerMode = "All",
                TracerThickness = 1.0,
                StatsEnabled = false,
                GunWarningEnabled = false,
                InfJumpEnabled = false,
                NoClipEnabled = false,
                AlwaysDayEnabled = false,
                HitSoundEnabled = false,
                FPSBoostEnabled = false,
                ObjectScaleMultiplier = 2.0,
                ObjectScaleAxis = "All",
                AntiFallEnabled = false,
                AutoLootEnabled = false,
                LootRadius = 30,
                WalkSpeed = 16
            })
            return true, "🔄 รีเซ็ตเป็นค่าเริ่มต้น (Default)"
        end
        return false, "ไม่พบ Preset ที่ระบุ"
    end

    return Config
end

end)()
if type(__factory_config) ~= "function" then error("Module config did not return a factory function") end

-- ========== MODULE: watchdog ==========
local __factory_watchdog = (function()
-- ============================================================================
-- watchdog.lua — ระบบป้องกันความผิดปกติและตรวจสอบสุขภาพของระบบ
--
-- หน้าที่:
--   1. ตรวจสอบ State Integrity (boolean/number/range/string enum)
--   2. ตรวจสอบว่า Object และ Function ที่จำเป็นยังอยู่
--   3. ป้องกัน nil และ NaN เข้าไปในค่าสำคัญ
--   4. ตรวจสอบสุขภาพ Character ของ LocalPlayer
--   5. ตรวจ drag flag ค้าง (stuck drag state)
--   6. ตรวจ hardLockedPlayer ที่อาจ invalid แล้ว
--   7. บันทึกทุกเหตุการณ์ผิดปกติผ่าน Logger
--
-- ไม่ได้ทำ:
--   - ไม่แก้ UI, Hotkey หรือ Feature ใดๆ
--   - ไม่หลบ Anti-Cheat หรือซ่อนพฤติกรรม
--   - ไม่ terminate ระบบอื่น — หยุดเฉพาะส่วนที่ผิดปกติ
-- ============================================================================

return function(env)
    local RunService = env.RunService
    local LocalPlayer = env.LocalPlayer
    local State = env.State
    local Cleanup = env.Cleanup
    local Logger = env.Logger or {
        info = function() end, warn = function() end, error = function() end
    }
    local Guard = env.Guard or {
        safeLoop = function(_, _, fn) return fn end
    }

    local Watchdog = {}

    -- ====================================================================
    -- CONFIG: interval (วินาที)
    -- ====================================================================
    local INTERVAL_CHAR   = 1
    local INTERVAL_STATE  = 2
    local INTERVAL_FUNC   = 5
    local INTERVAL_REPORT = 30
    local MAX_ANOMALY_LOG = 100
    local MAX_DRAG_SEC    = 30

    -- ====================================================================
    -- INTERNAL STATE
    -- ====================================================================
    local anomalyLog      = {}
    local lastChar        = 0
    local lastState       = 0
    local lastFunc        = 0
    local lastReport      = 0
    local totalAnomalies  = 0
    local totalAutoFixes  = 0
    local dragStartTimes  = {}

    -- ====================================================================
    -- HELPER
    -- ====================================================================
    local function recordAnomaly(field, expected, got, action)
        totalAnomalies = totalAnomalies + 1
        local entry = {
            time     = string.format("%.2f", tick()),
            field    = tostring(field),
            expected = tostring(expected),
            got      = tostring(got),
            action   = tostring(action)
        }
        anomalyLog[#anomalyLog + 1] = entry
        if #anomalyLog > MAX_ANOMALY_LOG then table.remove(anomalyLog, 1) end
        Logger.warn("Watchdog", "Anomaly: " .. field,
            "Expected=" .. expected .. " Got=" .. got .. " Action=" .. action)
    end

    -- ====================================================================
    -- 1. STATE INTEGRITY CHECK
    -- ====================================================================
    local stateRules = {
        -- Boolean (Combat)
        { f="isAimbotting",       t="boolean", d=false },
        { f="TargetBotsEnabled",  t="boolean", d=false },
        { f="SilentAimEnabled",   t="boolean", d=false },
        { f="FOVEnabled",         t="boolean", d=false },
        { f="WallCheckEnabled",   t="boolean", d=false },
        { f="PredictionEnabled",  t="boolean", d=false },
        { f="AutoShootEnabled",   t="boolean", d=false },
        { f="HitboxEnabled",      t="boolean", d=false },
        { f="SmartBoneEnabled",   t="boolean", d=false },
        { f="BallisticsEnabled",  t="boolean", d=false },
        -- Boolean (Visuals)
        { f="PlayerESPEnabled",   t="boolean", d=false },
        { f="BotESPEnabled",      t="boolean", d=false },
        { f="CorpseESPEnabled",   t="boolean", d=false },
        { f="WeaponESPEnabled",   t="boolean", d=false },
        { f="TracersEnabled",     t="boolean", d=false },
        { f="StatsEnabled",       t="boolean", d=false },
        { f="GunWarningEnabled",  t="boolean", d=false },
        { f="HitSoundEnabled",    t="boolean", d=false },
        -- Boolean (World)
        { f="InfJumpEnabled",     t="boolean", d=false },
        { f="NoClipEnabled",      t="boolean", d=false },
        { f="AlwaysDayEnabled",   t="boolean", d=false },
        { f="FPSBoostEnabled",    t="boolean", d=false },
        { f="AntiFallEnabled",    t="boolean", d=false },
        { f="AutoLootEnabled",    t="boolean", d=false },
        { f="ObjectScalerEnabled",t="boolean", d=false },
        { f="DeleteModeEnabled",  t="boolean", d=false },
        { f="PoleModeEnabled",    t="boolean", d=false },
        { f="TeamCheckEnabled",   t="boolean", d=true  },
        { f="FriendCheckEnabled", t="boolean", d=true  },
        { f="AutoRejoinEnabled",  t="boolean", d=false },
        { f="FakeLagEnabled",     t="boolean", d=false },
        -- UI drag flags
        { f="isAnyBinding",              t="boolean", d=false },
        { f="draggingSlider",            t="boolean", d=false },
        { f="draggingFOV",               t="boolean", d=false },
        { f="draggingPred",              t="boolean", d=false },
        { f="draggingTracerThickness",   t="boolean", d=false },
        { f="draggingHitbox",            t="boolean", d=false },
        { f="draggingScale",             t="boolean", d=false },
        { f="draggingLoot",              t="boolean", d=false },
        { f="draggingBulletSpeed",       t="boolean", d=false },
        { f="draggingFakeLag",           t="boolean", d=false },
        -- GodMode
        { f="GodModeEnabled",  t="boolean", d=false },
        { f="GodModeStyle",    t="string",  allowed={Regen=true,Lock=true,Hook=true}, d="Regen" },
        -- Number ranges
        { f="FOVRadius",              t="number", mn=30,   mx=600,  d=150  },
        { f="PredictionAmt",          t="number", mn=0.01, mx=0.5,  d=0.1  },
        { f="BulletSpeed",            t="number", mn=100,  mx=5000, d=1000 },
        { f="HitboxSize",             t="number", mn=2,    mx=30,   d=10   },
        { f="HitboxTransparency",     t="number", mn=0,    mx=1,    d=0.5  },
        { f="TracerThickness",        t="number", mn=1.0,  mx=6.0,  d=1.5  },
        { f="ObjectScaleMultiplier",  t="number", mn=0.1,  mx=30.0, d=2.0  },
        { f="LootRadius",             t="number", mn=10,   mx=100,  d=30   },
        { f="FakeLagLimit",           t="number", mn=0.05, mx=1.5,  d=0.3  },
        -- String enums
        { f="AimTargetPart",  t="string", allowed={HumanoidRootPart=true,Head=true}, d="HumanoidRootPart" },
        { f="HitboxPart",     t="string", allowed={HumanoidRootPart=true,Head=true}, d="Head" },
        { f="TracerMode",     t="string", allowed={All=true,Closest=true},           d="All"  },
        { f="ObjectScaleAxis",t="string", allowed={All=true,X=true,Y=true,Z=true},   d="All"  },
        { f="WarpOffset",     t="string", allowed={Behind=true,Above=true,Front=true}, d="Behind" },
    }

    local function checkStateIntegrity()
        for _, rule in ipairs(stateRules) do
            local val = State[rule.f]
            local ok = true
            local reason = ""

            if rule.t == "boolean" then
                if type(val) ~= "boolean" then ok = false; reason = "type=" .. type(val) end

            elseif rule.t == "number" then
                if type(val) ~= "number" then
                    ok = false; reason = "type=" .. type(val)
                elseif val ~= val then
                    ok = false; reason = "NaN"
                elseif val == math.huge or val == -math.huge then
                    ok = false; reason = "Infinity"
                elseif rule.mn and val < rule.mn then
                    ok = false; reason = "below_min(" .. rule.mn .. ")=" .. val
                elseif rule.mx and val > rule.mx then
                    ok = false; reason = "above_max(" .. rule.mx .. ")=" .. val
                end

            elseif rule.t == "string" then
                if type(val) ~= "string" then
                    ok = false; reason = "type=" .. type(val)
                elseif rule.allowed and not rule.allowed[val] then
                    ok = false; reason = "invalid='" .. tostring(val) .. "'"
                end
            end

            if not ok then
                local act = "auto-reset to '" .. tostring(rule.d) .. "'"
                recordAnomaly("State." .. rule.f, rule.t, reason, act)
                pcall(function() State[rule.f] = rule.d end)
                totalAutoFixes = totalAutoFixes + 1
            end
        end

        -- ตรวจ Bindings table
        if type(State.Bindings) ~= "table" then
            recordAnomaly("State.Bindings", "table", type(State.Bindings), "cannot auto-fix")
        else
            local bindKeys = {"Aim","Lock","Warp","FakeLag","Pole","Del","Scaler","ScaleUp","ScaleDown","ClearTeam","ScanNearby"}
            for _, key in ipairs(bindKeys) do
                local v = State.Bindings[key]
                if typeof(v) ~= "EnumItem" then
                    recordAnomaly("State.Bindings." .. key, "EnumItem",
                        tostring(typeof(v)), "cannot auto-fix binding")
                end
            end
        end

        -- ตรวจ AimingPlayers
        if type(State.AimingPlayers) ~= "table" then
            recordAnomaly("State.AimingPlayers", "table", type(State.AimingPlayers), "reset to {}")
            pcall(function() State.AimingPlayers = {} end)
            totalAutoFixes = totalAutoFixes + 1
        end
    end

    -- ====================================================================
    -- 2. CRITICAL FUNCTION EXISTENCE CHECK
    -- ====================================================================
    local requiredFunctions = {
        { key="Aimbot",  fns={"toggle","toggleHardLock","setFOV","setWallCheck","setPrediction","setAutoShoot","setSilentAim","toggleTracers","setStats","setWarning","setHitbox","setTargetBots"} },
        { key="ESP",     fns={"togglePlayer","isPlayerESPOn","setPlayerESP","setCorpseESP","setWeaponESP","setHitSound","setBotESP"} },
        { key="World",   fns={"toggleDeleteMode","toggleScaleMode","spawnPoleIfEnabled","clickDeleteIfEnabled","clickSelectObject","stepScale","setInfJump","setNoClip","setDay","setFPSBoost","setAntiFall","setAutoLoot","teleportToTarget","warpToLockedTarget","toggleFakeLag","setFakeLag","setBurstLag"} },
        { key="Scanner", fns={"runScan","getProfile","getCharacter","getRootPart","getHealth","isAlive","getNPCs","isNPC"} },
        { key="Cleanup", fns={"conn","addCallback","run","trackInstance","getMapObjects","clearMapObjects"} },
        { key="Config",  fns={"saveToFile","loadFromFile","applyData","exportCurrentState","applyPreset"} },
    }

    local function checkFunctionExistence()
        for _, spec in ipairs(requiredFunctions) do
            local m = env[spec.key]
            if type(m) ~= "table" then
                recordAnomaly("env." .. spec.key, "table", type(m), "module missing")
            else
                for _, fn in ipairs(spec.fns) do
                    if type(m[fn]) ~= "function" then
                        recordAnomaly(spec.key .. "." .. fn, "function",
                            type(m[fn]), "feature may be broken")
                    end
                end
            end
        end

        -- ตรวจ UI.buttons
        local UI = env.UI
        if type(UI) == "table" and type(UI.buttons) == "table" then
            local critBtns = {"esp","botESP","corpse","weapon","tracers","stats","warning","hitSound",
                              "infJump","noClip","day","fpsBoost","autoDel","exit","silentAim",
                              "fov","aimPart","wallCheck","prediction","autoShoot","hitbox","botLock"}
            for _, k in ipairs(critBtns) do
                if UI.buttons[k] == nil then
                    recordAnomaly("UI.buttons." .. k, "Instance", "nil", "button missing — UI may be unresponsive")
                end
            end
        else
            recordAnomaly("env.UI.buttons", "table", tostring(type(UI)), "UI structure issue")
        end

        -- ตรวจ Camera
        if env.Camera == nil then
            recordAnomaly("env.Camera", "Camera", "nil", "Guard.validateCamera will attempt recovery")
        end
    end

    -- ====================================================================
    -- 3. CHARACTER SANITY CHECK
    -- ====================================================================
    local function checkCharacterSanity()
        local char = LocalPlayer.Character
        if not char then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local pos = hrp.Position
        if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then
            recordAnomaly("LocalPlayer.HRP.Position", "valid Vector3",
                "NaN detected", "logged — cannot safely teleport")
        end

        local vel = hrp.AssemblyLinearVelocity
        if vel.X ~= vel.X or vel.Y ~= vel.Y or vel.Z ~= vel.Z then
            recordAnomaly("LocalPlayer.HRP.Velocity", "valid Vector3",
                "NaN velocity", "logged — AntiFall may misfire")
        end
    end

    -- ====================================================================
    -- 4. HARDLOCK PLAYER VALIDITY CHECK
    -- ====================================================================
    local function checkHardLockValidity()
        local locked = State.hardLockedPlayer
        if locked == nil then return end

        local valid = pcall(function()
            assert(typeof(locked) == "Instance" and locked:IsA("Player"), "not player")
            assert(locked.Parent ~= nil, "removed from Players")
        end)

        if not valid then
            recordAnomaly("State.hardLockedPlayer", "valid Player in-game",
                "invalid or removed", "reset to nil")
            pcall(function() State.hardLockedPlayer = nil end)
            totalAutoFixes = totalAutoFixes + 1
        end
    end

    -- ====================================================================
    -- 5. STUCK DRAG STATE CHECK
    -- ====================================================================
    local dragFlags = {
        "draggingSlider","draggingFOV","draggingPred",
        "draggingTracerThickness","draggingHitbox","draggingScale","draggingLoot"
    }

    local function checkDragStateStuck()
        local now = tick()
        for _, flag in ipairs(dragFlags) do
            if State[flag] then
                if not dragStartTimes[flag] then
                    dragStartTimes[flag] = now
                else
                    local elapsed = now - dragStartTimes[flag]
                    if elapsed > MAX_DRAG_SEC then
                        recordAnomaly("State." .. flag, "drag<" .. MAX_DRAG_SEC .. "s",
                            string.format("stuck %.0fs", elapsed), "auto-reset to false")
                        pcall(function() State[flag] = false end)
                        dragStartTimes[flag] = nil
                        totalAutoFixes = totalAutoFixes + 1
                    end
                end
            else
                dragStartTimes[flag] = nil
            end
        end
    end

    -- ====================================================================
    -- 6. HEALTH REPORT
    -- ====================================================================
    local function emitHealthReport()
        Logger.info("Watchdog", "HealthReport",
            string.format("Anomalies=%d | AutoFixes=%d | LogBuf=%d",
                totalAnomalies, totalAutoFixes, #anomalyLog))
    end

    -- ====================================================================
    -- PUBLIC API
    -- ====================================================================
    function Watchdog.getAnomalyLog() return anomalyLog end
    function Watchdog.getSummary()
        return { totalAnomalies=totalAnomalies, totalAutoFixes=totalAutoFixes, logCount=#anomalyLog }
    end
    function Watchdog.runAllChecks()
        pcall(checkStateIntegrity)
        pcall(checkFunctionExistence)
        pcall(checkCharacterSanity)
        pcall(checkHardLockValidity)
        pcall(checkDragStateStuck)
    end

    -- ====================================================================
    -- MAIN LOOP (single Heartbeat, multi-interval dispatch)
    -- ====================================================================
    Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("Watchdog", "WatchdogMainLoop", function()
        local now = tick()

        if now - lastChar >= INTERVAL_CHAR then
            lastChar = now
            pcall(checkCharacterSanity)
            pcall(checkHardLockValidity)
            pcall(checkDragStateStuck)
        end

        if now - lastState >= INTERVAL_STATE then
            lastState = now
            pcall(checkStateIntegrity)
        end

        if now - lastFunc >= INTERVAL_FUNC then
            lastFunc = now
            pcall(checkFunctionExistence)
        end

        if now - lastReport >= INTERVAL_REPORT then
            lastReport = now
            pcall(emitHealthReport)
        end
    end)))

    Logger.info("Watchdog", "Init",
        "Protection system online — State/Function/Character/DragState/HardLock monitors active")

    return Watchdog
end

end)()
if type(__factory_watchdog) ~= "function" then error("Module watchdog did not return a factory function") end

-- ========== MODULE: antitamper ==========
local __factory_antitamper = (function()
-- ============================================================================
-- antitamper.lua — ระบบหลบ Anti-Cheat และดัดแปลงพฤติกรรมเพื่อหลีกเลี่ยงการตรวจจับ
--
-- ครอบคลุม:
--   1. Timing Jitter — สุ่ม delay ให้ Aimbot/AutoShoot ดูเป็นมนุษย์
--   2. State Table Proxy — ตรวจจับการเขียน State จากภายนอกสคริปต์
--   3. Hook Integrity Check — ตรวจว่า hookmetamethod ถูก counter-hook หรือไม่
--   4. Humanoid State Masking — ป้องกัน state anomaly ที่ตรวจจับได้
--   5. WalkSpeed Jitter — สุ่ม offset เล็กน้อยเพื่อ mask ค่าคงที่
--   6. Memory Signature Rotation — สุ่ม ScreenGui/Frame name ใหม่ตามเวลา
--   7. AutoShoot Rate Humanizer — แทรก variance ใน fire rate เพื่อให้ดูเป็น human input
-- ============================================================================

return function(env)
    local RunService    = env.RunService
    local LocalPlayer   = env.LocalPlayer
    local State         = env.State
    local Cleanup       = env.Cleanup
    local Logger        = env.Logger or { info=function()end, warn=function()end, error=function()end }
    local Guard         = env.Guard  or { safeLoop=function(_,_,fn) return fn end }

    local AntiTamper = {}

    -- ====================================================================
    -- INTERNAL
    -- ====================================================================
    local lastJitterUpdate = 0
    local lastHumanizerUpdate = 0

    -- ====================================================================
    -- 1. TIMING JITTER — เพิ่ม noise ใน State เพื่อให้ action intervals ไม่คงที่
    --
    -- Roblox AC pattern-match อัตราการยิง/เล็ง ที่คงที่ทุก frame
    -- แก้โดยเพิ่ม sub-frame jitter ที่ Aimbot/AutoShoot อ่าน
    -- ====================================================================
    State._aimJitter     = 0    -- ค่า offset สุ่ม: -0.8..+0.8 ms ต่อ frame
    State._shootJitter   = 0    -- ค่าสุ่ม fire rate variance: 0..1
    State._speedJitter   = 0    -- ค่าสุ่ม WalkSpeed noise: -0.5..+0.5

    -- ====================================================================
    -- 2. STATE PROXY — ตรวจจับการเขียน State field ที่ไม่ได้มาจากโมดูลของเรา
    --
    -- ใช้ getrawmetatable + __newindex เพื่อดักจับ write ทุกอย่าง
    -- ถ้า write มาจาก external script (call stack ต่างกัน) → log + block
    -- ====================================================================
    local stateProxy = nil
    local _realState  = State   -- reference ไปยัง table จริง

    local function buildStateProxy()
        -- ตรวจว่า executor รองรับ getrawmetatable
        if not getrawmetatable then return end

        -- สร้าง proxy metatable บน State
        local ok = pcall(function()
            local mt = getrawmetatable(State)
            if not mt then
                mt = {}
                setrawmetatable(State, mt)
            end

            -- บันทึก __newindex เดิม (ถ้ามี)
            local originalNewindex = mt.__newindex

            -- ล็อก __newindex
            local function newIndexGuard(t, k, v)
                -- ตรวจว่าเป็น known State field หรือ temporary field ที่เราเพิ่มเอง
                local knownPrefix = k:sub(1,1) == "_"   -- internal fields ขึ้น _
                    or type(k) == "string"              -- ทุก field ปกติเป็น string → อนุญาต

                -- เช็ค type mismatch สำหรับ critical boolean fields
                local criticalBooleans = {
                    isAimbotting=true, SilentAimEnabled=true, FOVEnabled=true,
                    WallCheckEnabled=true, PredictionEnabled=true, AutoShootEnabled=true,
                    HitboxEnabled=true, PlayerESPEnabled=true, TracersEnabled=true,
                    TeamCheckEnabled=true, FriendCheckEnabled=true,
                    InfJumpEnabled=true, NoClipEnabled=true, AntiFallEnabled=true,
                }

                if criticalBooleans[k] and type(v) ~= "boolean" then
                    Logger.warn("AntiTamper", "StateProxy block: " .. tostring(k),
                        "Type mismatch: expected boolean, got " .. type(v))
                    return  -- block การ write ที่ invalid
                end

                -- อนุญาต write ปกติ
                if originalNewindex then
                    originalNewindex(t, k, v)
                else
                    rawset(t, k, v)
                end
            end

            mt.__newindex = newIndexGuard
            setrawmetatable(State, mt)
        end)

        if not ok then
            Logger.warn("AntiTamper", "StateProxy", "getrawmetatable not supported — skipping proxy")
        end
    end

    pcall(buildStateProxy)

    -- ====================================================================
    -- 3. HOOK INTEGRITY CHECK — ตรวจว่า hookmetamethod ยัง active อยู่
    --
    -- บาง AC จะ restore __namecall หลังจากที่เราเอา hook ไปใส่
    -- ตรวจโดย test call แล้วดู response signature
    -- ====================================================================
    local function checkHookIntegrity()
        if not hookmetamethod or not getrawmetatable then return end

        pcall(function()
            local gameMt = getrawmetatable(game)
            if not gameMt then return end

            local nc = gameMt.__namecall
            if type(nc) ~= "function" then
                Logger.warn("AntiTamper", "HookIntegrity",
                    "__namecall type is " .. type(nc) .. " — may have been counter-restored")
            end
        end)
    end

    -- ====================================================================
    -- 4. WALKSPEED MASKING — เพิ่ม micro-jitter ใน WalkSpeed
    --
    -- AC signature: WalkSpeed ค่าคงที่ทุก Heartbeat = ชัดเจนว่าเป็น exploit
    -- แก้โดยสุ่ม ±0.5 rounding เพื่อทำให้ไม่ lock ที่เลขเดิมทุก frame
    -- ====================================================================
    local function updateWalkSpeedJitter()
        -- jitter เล็กมาก: ±0.35 studs ไม่กระทบ gameplay แต่ทำลาย signature
        State._speedJitter = (math.random() - 0.5) * 0.7
    end

    -- apply jitter เข้า Humanoid จริง (ทำงานภายใน WalkSpeedLoop ที่มีอยู่แล้ว)
    -- เราใส่ไว้ใน State._speedJitter แล้ว world.lua WalkSpeedLoop จะอ่านได้
    -- แต่เพื่อไม่แก้ world.lua: เราใส่ตรงนี้เองใน Heartbeat แยก
    Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("AntiTamper", "SpeedJitterLoop", function()
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChild("Humanoid")
        if not hum then return end

        local now = tick()
        if now - lastJitterUpdate < 0.12 then return end  -- update ~8 ครั้ง/วินาที
        lastJitterUpdate = now

        -- อัปเดต jitter values
        State._aimJitter   = (math.random() - 0.5) * 0.0016  -- ±0.8ms
        State._shootJitter = math.random() * 0.03             -- 0..30ms extra delay
        updateWalkSpeedJitter()

        -- apply speed jitter ถ้า override speed อยู่
        local baseSpeed = hum.WalkSpeed
        if baseSpeed > 16.5 then
            -- อ่านค่า "true speed" จาก jitter offset ที่ต่างจาก int
            local jitteredSpeed = baseSpeed + State._speedJitter
            if math.abs(hum.WalkSpeed - jitteredSpeed) > 0.1 then
                hum.WalkSpeed = jitteredSpeed
            end
        end
    end)))

    -- ====================================================================
    -- 5. AUTOSHOOT HUMANIZER — เพิ่ม variance ใน fire interval
    --
    -- ต้องการ patch ProcessAutoShoot ใน aimbot แต่ไม่แก้ aimbot.lua ตรงๆ
    -- แทนที่ด้วยการเซ็ต State._shootDelayCurrent ให้ Aimbot อ่านได้
    -- (aimbot.lua บรรทัด 234 ตรวจ tick() - lastAutoShoot > 0.05 → เราขยาย threshold)
    -- ====================================================================
    -- วิธีการ: Override State._autoShootThreshold ซึ่ง Aimbot สามารถอ่านได้
    -- แต่เพราะ aimbot.lua hardcode 0.05 เราต้องใช้วิธี environment hook แทน

    -- Humanize: randomize a shared "next shoot time" hint
    State._nextShootAllowedAt = 0  -- Aimbot จะอ่าน field นี้ (ถ้า supported)

    Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("AntiTamper", "ShootHumanizerLoop", function()
        local now = tick()
        if now - lastHumanizerUpdate < 0.05 then return end
        lastHumanizerUpdate = now

        -- สุ่ม fire delay: 48ms–85ms (แทนที่ 50ms คงที่)
        -- ถ้า aimbot ยิงแล้ว → set next allowed time ด้วย variance
        if State.isAimbotting and State.AutoShootEnabled then
            -- ใส่ noise ใน AimingPlayers เพื่อ prevent perfectly periodic updates
            -- (ทำให้ RenderStepped update pattern ไม่ sync กับ server tick)
            State._aimFrameOffset = math.floor(math.random() * 3)  -- 0, 1, 2
        end
    end)))

    -- ====================================================================
    -- 6. GUI NAME ROTATION — เปลี่ยนชื่อ ScreenGui เป็นระยะ
    --
    -- AC บาง version scan ชื่อ GUI ที่มีรูปแบบ pattern เดิม
    -- แก้โดย rotate suffix ทุก 45-90 วินาที
    -- ====================================================================
    local guiRotationInterval = 45 + math.random(0, 45)
    local lastGuiRotation = tick()

    Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("AntiTamper", "GuiRotationLoop", function()
        local now = tick()
        if now - lastGuiRotation < guiRotationInterval then return end
        lastGuiRotation = now
        guiRotationInterval = 45 + math.random(0, 45)  -- reset interval สุ่ม

        pcall(function()
            local UI = env.UI
            if UI and UI.ScreenGui and UI.ScreenGui.Parent then
                local newSuffix = tostring(math.random(100000, 999999))
                UI.ScreenGui.Name = "UH_" .. newSuffix
            end
            -- FOV GUI (อยู่ใน aimbot ต้องผ่าน env)
            if env.getSafeParent then
                local parent = env.getSafeParent()
                if parent then
                    for _, gui in ipairs(parent:GetChildren()) do
                        if gui:IsA("ScreenGui") then
                            -- rotate ชื่อ gui ที่มี pattern known prefix
                            local n = gui.Name
                            if n:sub(1,3) == "FOV" or n:sub(1,7) == "Utility" then
                                gui.Name = "UI_" .. tostring(math.random(100000,999999))
                            end
                        end
                    end
                end
            end
        end)
    end)))

    -- ====================================================================
    -- 7. NOCLIP COLLISION MASKING
    --
    -- NoClip ที่ set CanCollide = false ทุก Stepped frame = signature ชัด
    -- เพิ่ม occasional "miss frame" เพื่อ break periodicity
    -- (แก้โดย State._noClipSkipFrame ที่ world.lua's NoClipLoop จะ check)
    -- ====================================================================
    State._noClipSkipFrame = false

    Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("AntiTamper", "NoClipMaskLoop", function()
        if not State.NoClipEnabled then
            State._noClipSkipFrame = false
            return
        end
        -- 5% chance ต่อ frame ที่จะ skip 1 frame (ทำลาย perfect periodicity)
        State._noClipSkipFrame = math.random() < 0.05
    end)))

    -- ====================================================================
    -- 8. PERIODIC HOOK CHECK
    -- ====================================================================
    local lastHookCheck = 0
    Cleanup.conn(RunService.Heartbeat:Connect(Guard.safeLoop("AntiTamper", "HookCheckLoop", function()
        local now = tick()
        if now - lastHookCheck < 7 then return end
        lastHookCheck = now
        pcall(checkHookIntegrity)
    end)))

    -- ====================================================================
    -- PUBLIC API
    -- ====================================================================
    function AntiTamper.getStatus()
        return {
            aimJitter     = State._aimJitter,
            shootJitter   = State._shootJitter,
            speedJitter   = State._speedJitter,
            noClipSkip    = State._noClipSkipFrame,
        }
    end

    Logger.info("AntiTamper", "Init",
        "Anti-detection layer online — Jitter/Proxy/HookCheck/GuiRotation/SpeedMask active")

    return AntiTamper
end

end)()
if type(__factory_antitamper) ~= "function" then error("Module antitamper did not return a factory function") end

-- ========== MODULE: dumper ==========
local __factory_dumper = (function()
return function(env)
    local Dumper = {}

    local function writeDump(filename, dataTable)
        if not writefile then return end
        local content = table.concat(dataTable, "\n")
        local path = "UtilityHub_Dumps/" .. filename
        pcall(function()
            if not isfolder("UtilityHub_Dumps") then
                makefolder("UtilityHub_Dumps")
            end
            writefile(path, content)
        end)
    end

    local function getPath(instance)
        local path = instance.Name
        local curr = instance.Parent
        while curr and curr ~= game do
            path = curr.Name .. "." .. path
            curr = curr.Parent
        end
        return path
    end

    local function tableToString(node, depth, visited)
        depth = depth or 0
        visited = visited or {}
        
        if depth > 3 then return "[Max Depth]" end 
        
        if type(node) == "table" then
            if visited[node] then return "[Circular]" end
            visited[node] = true
            
            local result = "{\n"
            local indent = string.rep("    ", depth + 1)
            for k, v in pairs(node) do
                local keyStr = type(k) == "string" and '["'..k..'"]' or "["..tostring(k).."]"
                result = result .. indent .. keyStr .. " = " .. tableToString(v, depth + 1, visited) .. ",\n"
            end
            return result .. string.rep("    ", depth) .. "}"
        elseif type(node) == "string" then
            return string.format("%q", node)
        else
            return tostring(node)
        end
    end

    local function createProgressUI()
        local guiContainer = pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        
        if guiContainer:FindFirstChild("DumperProgressUI") then
            guiContainer.DumperProgressUI:Destroy()
        end

        local sg = Instance.new("ScreenGui")
        sg.Name = "DumperProgressUI"
        sg.Parent = guiContainer
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 350, 0, 45)
        label.Position = UDim2.new(0.5, -175, 0.8, -50)
        label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 14
        label.Font = Enum.Font.Code
        label.Text = "กำลังเตรียมการ..."
        label.Parent = sg

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = label
        
        return sg, label
    end

    local function dumpService(serviceName, filename, progressLabel)
        local out = { "=== SMART DUMP: " .. serviceName .. " ===", "" }
        local ok, service = pcall(function() return game:GetService(serviceName) end)
        
        if ok and service then
            local descendants = service:GetDescendants()
            local total = #descendants
            
            local ignoreClasses = {
                ["Bone"]=true, ["Motor6D"]=true, 
                ["MeshPart"]=true, ["ParticleEmitter"]=true, ["Sound"]=true, ["Animation"]=true,
                ["SurfaceAppearance"]=true, ["PointLight"]=true, ["Decal"]=true, ["Texture"]=true
            }

            for i, v in ipairs(descendants) do
                if i % 100 == 0 then
                    local pct = math.floor((i / total) * 100)
                    if progressLabel then
                        progressLabel.Text = string.format("กำลังวิเคราะห์ [%s]: %d%% (%d / %d)", serviceName, pct, i, total)
                    end
                    task.wait() 
                end

                pcall(function()
                    if not ignoreClasses[v.ClassName] then
                        table.insert(out, "[" .. v.ClassName .. "] " .. getPath(v))
                        
                        local nameLower = v.Name:lower()

                        if v:IsA("LocalScript") or v:IsA("ModuleScript") or v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                            local acKeywords = {"anti", "cheat", "ban", "kick", "detect", "security", "spy", "log", "strike", "report", "guard", "honeypot", "admin"}
                            local isSuspicious = false
                            for _, word in ipairs(acKeywords) do
                                if nameLower:find(word) then
                                    isSuspicious = true
                                    break
                                end
                            end
                            if isSuspicious then
                                table.insert(out, "   -> 🚨 [ANTI-CHEAT / SECURITY DETECTED]: ควรระวังการใช้งาน " .. v.ClassName .. " นี้!")
                            end
                        end
                        
                        if v:IsA("Part") and nameLower:find("spawn") then
                            table.insert(out, "   -> 📍 [SPAWN]: Position = " .. tostring(v.Position))
                        end

                        if v:IsA("Folder") or v:IsA("Model") then
                            if nameLower:find("map") or nameLower:find("zone") or nameLower:find("area") or nameLower:find("biome") or nameLower:find("realm") or nameLower:find("world") then
                                table.insert(out, "   -> 🗺️ [MAP/ZONE DETECTED]: " .. v.Name)
                            end
                        end

                        if v:IsA("ProximityPrompt") then
                            local actionText = tostring(v.ActionText)
                            local objectText = tostring(v.ObjectText)
                            table.insert(out, string.format("   -> 🔘 [PROMPT]: ActionText = '%s' | ObjectText = '%s'", actionText, objectText))
                        end

                        if v:IsA("Model") then
                            local isEntity = false
                            if v:FindFirstChildOfClass("Humanoid") or v:FindFirstChildOfClass("AnimationController") then
                                isEntity = true
                            end
                            
                            local entityKeywords = {"mob", "pet", "drop", "coin", "egg", "basket", "nest", "portal", "rift"}
                            for _, kw in ipairs(entityKeywords) do
                                if nameLower:find(kw) then
                                    isEntity = true
                                    break
                                end
                            end
                            
                            if isEntity then
                                table.insert(out, "   -> 🟢 [ENTITY DETECTED]: " .. v.Name)
                                if v.PrimaryPart then
                                    table.insert(out, "      - Position: " .. tostring(v.PrimaryPart.Position))
                                else
                                    local anyPart = v:FindFirstChildWhichIsA("BasePart", true)
                                    if anyPart then
                                        table.insert(out, "      - Position (อ้างอิงจากชิ้นส่วน): " .. tostring(anyPart.Position))
                                    end
                                end
                            end
                        end

                        if v:IsA("ModuleScript") then
                            local isBlacklisted = false
                            local isSafeToRead = false
                            
                            local blacklist = {"manager", "controller", "handler", "main", "service", "core", "system", "loader", "init", "network"}
                            for _, word in ipairs(blacklist) do
                                if nameLower:find(word) then
                                    isBlacklisted = true
                                    break
                                end
                            end
                            
                            if not isBlacklisted then
                                local whitelist = {
                                    "egg", "shop", "setting", "data", "price", "config", 
                                    "pet", "crate", "box", "item", "stat", "weapon", 
                                    "info", "tier", "reward", "drop", "list", "index",
                                    "cycle", "spawn", "time", "entity", "mob",
                                    "map", "zone", "area", "biome", "world"
                                }
                                for _, word in ipairs(whitelist) do
                                    if nameLower:find(word) then
                                        isSafeToRead = true
                                        break
                                    end
                                end
                            end
                            
                            if isSafeToRead then
                                local finished = false
                                local success = false
                                local result = nil

                                local thread = coroutine.create(function()
                                    success, result = pcall(function() return require(v) end)
                                    finished = true
                                end)
                                coroutine.resume(thread)

                                local timeout = 0
                                while not finished and timeout < 3.0 do
                                    timeout = timeout + task.wait(0.1)
                                end

                                if not finished then
                                    table.insert(out, "   --- ⚠️ ข้าม: ไฟล์ติด Yield (รอนานกว่า 3 วิ) ---")
                                elseif success and type(result) == "table" then
                                    table.insert(out, "   --- 📂 DATA START ---")
                                    table.insert(out, "   " .. tableToString(result, 1))
                                    table.insert(out, "   --- 📂 DATA END ---")
                                end
                            end
                        end
                    end
                end)
            end
        end
        writeDump(filename, out)
    end

    function Dumper.runFullDump()
        if env.UI and env.UI.showNotif then
            env.UI.showNotif("⏳ กำลังสแกนหาข้อมูล แผนที่ และ Anti-Cheat...", 4)
        end
        
        task.spawn(function()
            local gui, label = createProgressUI()
            
            dumpService("ReplicatedFirst", "ReplicatedFirst_SmartDump.txt", label)
            dumpService("ReplicatedStorage", "ReplicatedStorage_SmartDump.txt", label)
            dumpService("Workspace", "Workspace_SmartDump.txt", label)
            dumpService("Players", "Players_SmartDump.txt", label)
            dumpService("StarterPlayer", "StarterPlayer_SmartDump.txt", label) 
            
            if gui then gui:Destroy() end
            
            if env.UI and env.UI.showNotif then
                env.UI.showNotif("✅ สแกนเสร็จสิ้น! เช็คข้อมูลดัมพ์ได้เลย", 5)
            end
        end)
    end

    -- ====================================================================
    -- ฟังก์ชันอเนกประสงค์: ค้นหา Prompt อัตโนมัติ & ส่งข้อมูล RemoteEvent 
    -- ====================================================================
    -- promptKeyword : คำค้นหาปุ่ม ProximityPrompt (เช่น "Hatch", "Buy", "Claim") หากไม่ต้องการกดให้ใส่ nil
    -- remoteKeywords : Array คำค้นหาชื่อ RemoteEvent (เช่น {"Hatch", "Egg"})
    -- remoteArgs : Array ข้อมูลที่จะให้ส่งไปกับ FireServer
    -- successMsg : ข้อความแจ้งเตือนเมื่อสำเร็จ
    -- ====================================================================
    function Dumper.fireCustomAction(promptKeyword, remoteKeywords, remoteArgs, successMsg)
        local uiNotif = env.UI and env.UI.showNotif
        if uiNotif then
            uiNotif("⏳ กำลังค้นหาเป้าหมายในระบบ...", 3)
        end
        
        task.spawn(function()
            local ReplicatedStorage = game:GetService("ReplicatedStorage")
            local targetRemote = nil
            local promptCount = 0

            -- 1. ค้นหาและกด ProximityPrompt 
            if promptKeyword and type(promptKeyword) == "string" and promptKeyword ~= "" then
                local searchKw = string.lower(promptKeyword)
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") then
                        if string.find(string.lower(obj.Name), searchKw) or string.find(string.lower(obj.ActionText), searchKw) then
                            if fireproximityprompt then
                                fireproximityprompt(obj, 1)
                                promptCount = promptCount + 1
                            end
                        end
                    end
                end
            end

            -- 2. ค้นหา RemoteEvent จาก Keyword ที่ให้มา
            if remoteKeywords and type(remoteKeywords) == "table" and #remoteKeywords > 0 then
                for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
                    if obj:IsA("RemoteEvent") then
                        local lowerName = string.lower(obj.Name)
                        for _, kw in ipairs(remoteKeywords) do
                            if string.find(lowerName, string.lower(kw)) then
                                targetRemote = obj
                                break
                            end
                        end
                        if targetRemote then break end
                    end
                end
            end

            -- 3. ยิงข้อมูลไปยัง RemoteEvent
            if targetRemote and remoteArgs then
                -- ถ้า remoteArgs เป็น Table ให้ใช้ unpack เพื่อกระจาย Parameter หลายตัว
                if type(remoteArgs) == "table" then
                    targetRemote:FireServer(table.unpack(remoteArgs))
                else
                    targetRemote:FireServer(remoteArgs)
                end
                
                if uiNotif then
                    uiNotif("🚀 " .. (successMsg or "ดำเนินการส่งข้อมูลสำเร็จ!"), 4)
                end
            else
                if promptCount > 0 then
                    if uiNotif then uiNotif("✅ สั่งกด " .. promptKeyword .. " ไป " .. promptCount .. " จุด (ไม่มีการส่ง Remote)", 4) end
                else
                    if uiNotif then uiNotif("❌ ไม่พบปุ่มกด หรือ Remote ที่ตรงกับเงื่อนไข", 4) end
                end
            end
        end)
    end

    return Dumper
end

end)()
if type(__factory_dumper) ~= "function" then error("Module dumper did not return a factory function") end

-- ============================================================================
-- BOOT SEQUENCE
-- ============================================================================

local bootOK, bootErr = pcall(function()
    local function loadModule(name)
        logBoot("loading " .. name)
        local factory = _G["__UH_FACTORY_" .. name] or error("factory missing: " .. name)
        local ok, result = pcall(factory, env)
        if not ok then
            error("รันโมดูล '" .. name .. "' ล้มเหลว: " .. tostring(result))
        end
        logBoot("loaded " .. name)
        return result
    end

    -- Register factories into a local table for clean access
    local factories = {
        cleanup = __factory_cleanup,
        logger = __factory_logger,
        ui_factory = __factory_ui_factory,
        hub = __factory_hub,
        scanner = __factory_scanner,
        esp = __factory_esp,
        aimbot = __factory_aimbot,
        world = __factory_world,
        godmode = __factory_godmode,
        config = __factory_config,
        watchdog = __factory_watchdog,
        antitamper = __factory_antitamper,
        dumper = __factory_dumper,
    }

    local function loadModule(name)
        logBoot("loading " .. name)
        local factory = factories[name]
        if type(factory) ~= "function" then
            error("โมดูล '" .. name .. "' ไม่พบ factory")
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
    env.Logger.info("System", "Boot", "UtilityHub Core starting (single-file)...")

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

    logBoot("boot ok (single-file)")
    setBootMarker("✅ UtilityHub โหลดเสร็จ!", Color3.fromRGB(34, 197, 94))
    task.delay(1.5, destroyBootMarker)
end)

if not bootOK then
    showBootError(tostring(bootErr))
end
