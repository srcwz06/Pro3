-- ============================================================
-- 🥚 EGG LITE — ระบบเก็บไข่ (v1 : ไข่ธรรมดา)
-- ไฟล์ใหม่แยกจาก VIP — ไม่ได้แก้ไขไฟล์เดิมแม้แต่บรรทัดเดียว
--
-- ✅ ทำใน v1
--    สแกนไข่ตามที่ติ๊ก → บินไปยืนข้างไข่ → เก็บเข้ามือ (นับรอบ 15 วิ)
--    → ตรวจว่าเข้ามือจริง → บินกลับแปลง → วางไข่ → วนลูป
--
-- ❌ ยังไม่ทำใน v1 (ตามที่ตกลงไว้)
--    · Volcanic : ทัวร์ประตู / บัฟ Scorching / เส้นทางออกถ้ำ 32 จุด
--    · ดรอปลาวา (20 เข็ม) / ระบบแจ้งเตือน / ระบบเซฟไฟล์
--
-- ⛔ ไม่ยิง remote "TeleportToPlot" เด็ดขาด
--    (ตามคำสั่ง — กันอาการ "Can't Teleport While Carrying Eggs")
--    ขากลับจึงใช้ "บิน" ล้วน ๆ แล้วค่อยยิง EggPlaced + BasketDrop
--
-- ⚠️ ไฟล์นี้ไม่มีตัวบล็อก Ban/Kick (คนละเรื่องกับลอจิกเก็บไข่)
--    ถ้าจะรันเดี่ยว ๆ ไม่พึ่ง VIP บอกได้ แล้วผมเพิ่มให้
-- ============================================================

local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player       = Players.LocalPlayer

-- ---------- Safe GUI Parent (เหมือนของเดิม) ----------
local function getSafeGuiParent()
    if gethui then return gethui() end
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return player:WaitForChild("PlayerGui", 5) or player.PlayerGui
end
local parentGui = getSafeGuiParent()
if parentGui:FindFirstChild("EggLiteUI") then parentGui.EggLiteUI:Destroy() end

-- ---------- Factory ----------
local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

-- ---------- ค่าตั้ง (ปรับได้ที่นี่ที่เดียว) ----------
local CFG = {
    FLY_SPEED = 1000,   -- ความเร็วบิน (stud / วินาที)
    GRAB_TIME = 15,     -- เวลาพยายามเก็บต่อหนึ่งไข่ (วินาที)
    LOOP_WAIT = 0.4,    -- หน่วงเวลาเช็กไข่ในแมพ (วินาที)
    ARRIVE    = 3,      -- ถือว่าถึงจุดหมายเมื่อห่างไม่เกินนี้ (stud)
    -- 🛡️ ระบบกัน remote (hook __namecall + Analytics + FPS ปลอม)
    --    ⚠️ ถ้า Roblox เด้งปิดแอป → ตั้งเป็น false แล้วรันใหม่ 1 รอบ
    --       · หาย = ตัว hook __namecall คือตัวการ (จุดเสี่ยง #1 ของ client crash)
    --       · ยังหลุด = ไม่ใช่ตรงนี้ → ไปเช็กตัวรัน/งานต่อเฟรมต่อ
    SHIELD    = true,
}

-- ---------- Remote (ยืนยันจาก ReplicatedStorage_Dump) ----------
local remotesFolder = RS:WaitForChild("Remotes", 5)
local gameRemotes   = remotesFolder and remotesFolder:FindFirstChild("Game")
local eggPickupRemote  = gameRemotes and gameRemotes:FindFirstChild("EggPickup")   -- Game.EggPickup
local basketDropRemote = gameRemotes and gameRemotes:FindFirstChild("BasketDrop")  -- Game.BasketDrop
local eggPlacedRemote  = gameRemotes and gameRemotes:FindFirstChild("EggPlaced")   -- Game.EggPlaced
-- ⛔ TeleportToPlot: จงใจไม่โหลด / ไม่ยิง (คำสั่งผู้ใช้)
local remoteOk = (eggPickupRemote ~= nil and basketDropRemote ~= nil and eggPlacedRemote ~= nil)

-- ============================================================
-- 🛡️ ระบบกัน (Anti-Detect)
--    1) hook __namecall ตัด remote อันตราย (Ban/Kick/...)
--    2) บล็อก Analytics / FastFlags ที่เอาไว้ตรวจจับ
-- ============================================================
local blockedRemotesCount = 0
local blockedRemoteNames = {
    ["Ban"] = true, ["Kick"] = true, ["GameWarning"] = true,
    ["Error"] = true, ["PlayerActivity"] = true, ["Teleporting"] = true,
    ["ServerMessage"] = true,
}

-- 🔌 ตัด FireServer/InvokeServer ของ remote ในบัญชีทิ้ง (ฟังก์ชันเดิมของ VIP)
pcall(function()
    if CFG.SHIELD and hookmetamethod then
        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if (method == "FireServer" or method == "InvokeServer") and self then
                if blockedRemoteNames[self.Name] then
                    blockedRemotesCount = blockedRemotesCount + 1
                    return nil
                end
            end
            return oldNamecall(self, ...)
        end)
    end
end)

-- 📈 บล็อก RemoteEvent ฝั่ง Analytics + ไฟล์ FastFlags update
local analyticsBlocked = false
local function blockAnalytics()
    if analyticsBlocked then return end
    analyticsBlocked = true
    pcall(function()
        local userGen = RS:FindFirstChild("UserGenerated")
        if not userGen then return end
        local analytics = userGen:FindFirstChild("Analytics")
        if analytics then
            local clientKit = analytics:FindFirstChild("ClientKit")
            if clientKit then
                for _, child in pairs(clientKit:GetChildren()) do
                    if child:IsA("RemoteEvent") or child:IsA("UnreliableRemoteEvent") then
                        child.FireServer = function(...) return end
                    end
                end
            end
        end
        local fastFlags = userGen:FindFirstChild("FastFlags")
        if fastFlags then
            local sharedFlags = fastFlags:FindFirstChild("SharedFastFlags")
            if sharedFlags then
                local updateRemote = sharedFlags:FindFirstChild("Update")
                if updateRemote and updateRemote:IsA("RemoteEvent") then
                    updateRemote.FireServer = function(...) return end
                end
            end
        end
    end)
end
if CFG.SHIELD then blockAnalytics() end

-- 🎭 ส่ง FPS ปลอม (55-65) แทนค่าจริง กันฝั่งเซิร์ฟอ่านพฤติกรรม
--    ⚠️ ปิดได้ด้วย CFG.SHIELD = false (ไว้เช็กว่าคือตัวทำให้ Roblox เด้งปิดแอป)
if CFG.SHIELD then pcall(function()
    local userGen = RS:FindFirstChild("UserGenerated")
    local analytics = userGen and userGen:FindFirstChild("Analytics")
    local clientKit = analytics and analytics:FindFirstChild("ClientKit")
    local fpsRemote = clientKit and clientKit:FindFirstChild("Fps")
    if fpsRemote and fpsRemote:IsA("RemoteEvent") then
        fpsRemote.FireServer = function(self, fps)
            fpsRemote.FireServer = function(self, realFps) return end
            return nil
        end
    end
end) end

-- ---------- สี ----------
local C = {
    Bg     = Color3.fromRGB(30, 30, 32),   -- เทาดำ (ไม่อมน้ำเงิน) — ใช้คู่ BackgroundTransparency
    BgDark = Color3.fromRGB(14, 14, 16),   -- แถบชื่อ/ตาราง — ดำกว่าพื้นหลัก
    Card   = Color3.fromRGB(45, 54, 72),
    Stroke = Color3.fromRGB(61, 71, 89),
    Log    = Color3.fromRGB(13, 17, 23),
    Text   = Color3.fromRGB(230, 237, 243),
    Sub    = Color3.fromRGB(195, 204, 221),
    Muted  = Color3.fromRGB(120, 133, 155),
    Accent = Color3.fromRGB(59, 130, 246),
    Green  = Color3.fromRGB(16, 185, 129),
    Red    = Color3.fromRGB(239, 68, 68),
    Amber  = Color3.fromRGB(245, 158, 11),
}
local RARITY_COLOR = {
    ["Secret"]    = Color3.fromRGB(234, 179, 8),
    ["Volcanic"]  = Color3.fromRGB(239, 68, 68),
    ["Ethereal"]  = Color3.fromRGB(192, 132, 252),
    ["Divine"]    = Color3.fromRGB(236, 72, 153),
    ["Mythic"]    = Color3.fromRGB(251, 146, 60),
    ["Legendary"] = Color3.fromRGB(56, 189, 248),
    ["Epic"]      = Color3.fromRGB(168, 85, 247),
    ["Rare"]      = Color3.fromRGB(34, 197, 94),
    ["Common"]    = Color3.fromRGB(156, 163, 175),
}

-- 🎨 ไอคอนสำรอง — ใช้ตอน "ยังไม่มีรูป" (รอสแกนจากโมเดลในแมพมาเติมให้ทีหลัง)
--    อยู่คนละชั้นกับชื่อย่อใต้รูป → ไม่เห็นชื่อซ้ำกัน 2 ครั้ง
local FALLBACK_GLYPH = {
    ["Secret"]    = "👑",
    ["Volcanic"]  = "🌋",
    ["Ethereal"]  = "✨",
    ["Divine"]    = "🌟",
    ["Mythic"]    = "🔮",
    ["Legendary"] = "🏆",
    ["Epic"]      = "💎",
    ["Rare"]      = "🍀",
    ["Common"]    = "🥚",
}

-- ---------- ไข่ทั้ง 32 ตัว เรียงตามระดับความหายาก (เหมือน table.sort ของเดิม) ----------
-- { ชื่อเต็ม, ระดับ, assetId (ว่าง = ไม่มีรูป), ชื่อย่อ }
local EGG_DATA = {
    { "Admin Egg",       "Secret",    "",                 "Admin" },
    { "Volcanic Egg",    "Volcanic",  "",                 "Volcanic" },
    { "Solaris Egg",     "Ethereal",  "131016816558781",  "Solaris" },
    { "Cherub Egg",      "Ethereal",  "78949206711037",   "Cherub" },
    { "Blackhole Egg",   "Ethereal",  "133246489138606",  "Blackhole" },
    { "Dragon Egg",      "Ethereal",  "",                 "Dragon" },
    { "Galaxy Egg",      "Divine",    "124675079216303",  "Galaxy" },
    { "Aurora Egg",      "Divine",    "104054291691153",  "Aurora" },
    { "Giant Egg",       "Divine",    "",                 "Giant" },
    { "Bloom Egg",       "Divine",    "",                 "Bloom" },
    { "Soul Egg",        "Mythic",    "120412681051430",  "Soul" },
    { "Sinister Egg",    "Mythic",    "103306547790688",  "Sinister" },
    { "Flaming Egg",     "Mythic",    "132736734146055",  "Flaming" },
    { "Dominus Egg",     "Mythic",    "79223819657960",   "Dominus" },
    { "Asteroid Egg",    "Mythic",    "73970285282697",   "Asteroid" },
    { "Skull Egg",       "Mythic",    "82409969049724",   "Skull" },
    { "Crystal Egg",     "Mythic",    "115371319949206",  "Crystal" },
    { "Diamond Egg",     "Mythic",    "133543115652338",  "Diamond" },
    { "Tidal Egg",       "Mythic",    "",                 "Tidal" },
    { "Devil Fruit Egg", "Mythic",    "",                 "DevilFruit" },
    { "Golden Egg",      "Legendary", "106524193083708",  "Golden" },
    { "Glass Egg",       "Legendary", "128678801950944",  "Glass" },
    { "Ice Egg",         "Epic",      "75603581085211",   "Ice" },
    { "Slime Egg",       "Epic",      "83864412478531",   "Slime" },
    { "Flower Egg",      "Epic",      "72458885548445",   "Flower" },
    { "Mushroom Egg",    "Epic",      "139402409078907",  "Mushroom" },
    { "Leaf Egg",        "Rare",      "135299344009434",  "Leaf" },
    { "Stone Egg",       "Rare",      "121421205914213",  "Stone" },
    { "Easter Egg",      "Rare",      "72008656262680",   "Easter" },
    { "Cracked Egg",     "Rare",      "77040464450184",   "Cracked" },
    { "Brown Egg",       "Common",    "125046526765012",  "Brown" },
    { "White Egg",       "Common",    "112885858949987",  "White" },
}

-- ---------- State ----------
local selectedEggs = {}      -- ลำดับในตาราง = ลำดับความสำคัญตอนสแกน
local isFarming   = false
local isGrabbing  = false
local homeCFrame  = nil
local dipEnabled  = false    -- 🌋 สวิตช์ดรอปลาวา (กดปุ่มบนหน้าต่าง)
local dipRunning  = false    -- กันรันซ้อนระหว่างรอบดรอป

-- ============================================================
-- ส่วนที่ 1 : หน้าต่าง
-- ============================================================
local sg = mk("ScreenGui", {
    Name = "EggLiteUI", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, parentGui)

local W, H = 340, 558   -- สูงขึ้น 16px = ให้ "2 แถวแรกของตารางไข่" โชว์เต็มใบ (เดิม 542 ตัดแถวล่าง)
local minimized = false          -- ประกาศไว้ตรงนี้ (ระบบ fit จอต้องใช้)
local win = mk("Frame", {
    Size = UDim2.new(0, W, 0, H), Position = UDim2.new(0, 44, 0, 130),
    -- 🪟 พื้นหลัง "เทาดำ มองทะลุ" เห็นฉากเกมด้านหลัง (ยิ่งน้อยยิ่งใส)
    BackgroundColor3 = C.Bg, BackgroundTransparency = 0.30,
    BorderSizePixel = 0, ClipsDescendants = true,
}, sg)
mk("UICorner", { CornerRadius = UDim.new(0, 12) }, win)
mk("UIStroke", { Color = C.Stroke, Thickness = 1.3, Transparency = 0.25 }, win)

-- ============================================================
-- 📱 รองรับมือถือ : ย่อ/ขยายหน้าต่างให้พอดีจอ + กันลากออกนอกจอ
-- ============================================================
local uiScale = mk("UIScale", { Scale = 1 }, win)

-- กันหน้าต่างหลุดออกนอกจอ (เรียกหลังลาก หรือหลังเปลี่ยนขนาดจอ)
local function clampPos()
    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vs = cam.ViewportSize
        if vs.X <= 0 or vs.Y <= 0 then return end
        local s = uiScale.Scale
        local w = W * s
        local h = (minimized and 32 or H) * s
        local p = win.Position
        local x = math.clamp(p.X.Offset, 4, math.max(4, vs.X - w - 4))
        local y = math.clamp(p.Y.Offset, 4, math.max(4, vs.Y - h - 4))
        win.Position = UDim2.new(p.X.Scale, x, p.Y.Scale, y)
    end)
end

-- ย่อหน้าต่างให้พอดีจอมือถือ (จอเล็ก = ย่อ / จอปกติ = ไม่แตะ)
local function fitToScreen()
    pcall(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vs = cam.ViewportSize
        if vs.X <= 0 or vs.Y <= 0 then return end
        uiScale.Scale = math.clamp(math.min((vs.X - 20) / W, (vs.Y - 20) / H), 0.6, 1)
        clampPos()
    end)
end
fitToScreen()
pcall(function()
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToScreen)
end)

-- แถบชื่อ (ใช้ลากหน้าต่าง)
local bar = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.BgDark,
    BackgroundTransparency = 0.18,   -- แถบชื่อทึบกว่าตัวหน้าต่างนิดหน่อย กันข้อความไม่ชัด
    BorderSizePixel = 0, Active = true,
}, win)
mk("TextLabel", {
    Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 11, 0, 0),
    BackgroundTransparency = 1, Text = "🥚 EGG LITE · r16", TextColor3 = C.Text,
    Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, bar)

local minBtn = mk("TextButton", {
    Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -56, 0.5, -12),
    BackgroundColor3 = C.Card, BorderSizePixel = 0, AutoButtonColor = true,
    Text = "—", TextColor3 = C.Sub, Font = Enum.Font.GothamBold, TextSize = 13,
}, bar)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, minBtn)

local closeBtn = mk("TextButton", {
    Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -28, 0.5, -12),
    BackgroundColor3 = C.Red, BorderSizePixel = 0, AutoButtonColor = true,
    Text = "X", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 11,
}, bar)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, closeBtn)

-- เนื้อหา
local body = mk("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -32), Position = UDim2.new(0, 0, 0, 32),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.Stroke, AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0),
}, win)
mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, body)
mk("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
                  PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) }, body)

-- ============================================================
-- 🎨 UX/UI ใหม่ : status strip → actions → หัวข้อ(พับได้) → grid → ล็อก → footer
-- ============================================================

-- 1) แถบสถานะ : LED + ข้อความ + badge
local statusBox = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.BgDark,
    BackgroundTransparency = 0.35, BorderSizePixel = 0, LayoutOrder = 1,
}, body)
mk("UICorner", { CornerRadius = UDim.new(0, 9) }, statusBox)

local statusDot = mk("Frame", {
    Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 11, 0.5, -4),
    BackgroundColor3 = C.Muted, BorderSizePixel = 0,
}, statusBox)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, statusDot)

local statusLbl = mk("TextLabel", {
    Size = UDim2.new(1, -88, 1, 0), Position = UDim2.new(0, 26, 0, 0),
    BackgroundTransparency = 1, Text = "หยุดอยู่", TextColor3 = C.Sub,
    Font = Enum.Font.Gotham, TextSize = 11.5,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, statusBox)

local statusBadge = mk("TextLabel", {
    Size = UDim2.new(0, 56, 0, 18), Position = UDim2.new(1, -62, 0.5, -9),
    BackgroundColor3 = Color3.fromRGB(30, 58, 95), BorderSizePixel = 0,
    Text = "0 ใบ", TextColor3 = Color3.fromRGB(125, 211, 252),
    Font = Enum.Font.GothamBold, TextSize = 10,
}, statusBox)
mk("UICorner", { CornerRadius = UDim.new(1, 0) }, statusBadge)

-- 2) แถวปุ่ม : ปุ่มหลักเต็มกว้าง + ปุ่มรองเป็นไอคอน 44px (นิ้วแตะพอดี)
local actions = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, LayoutOrder = 2,
}, body)
mk("UIListLayout", { Padding = UDim.new(0, 7), FillDirection = Enum.FillDirection.Horizontal }, actions)

local startBtn = mk("TextButton", {
    Size = UDim2.new(1, -102, 1, 0), BackgroundColor3 = C.Green, BorderSizePixel = 0,
    AutoButtonColor = true, Text = "⚡ เริ่มฟาร์ม", TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold, TextSize = 13,
}, actions)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, startBtn)

local dipBtn = mk("TextButton", {
    Size = UDim2.new(0, 44, 1, 0), BackgroundColor3 = Color3.fromRGB(107, 114, 128),
    BorderSizePixel = 0, AutoButtonColor = true, Text = "🌋",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 17,
}, actions)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, dipBtn)

local previewBtn = mk("TextButton", {
    Size = UDim2.new(0, 44, 1, 0), BackgroundColor3 = Color3.fromRGB(168, 85, 247),
    BorderSizePixel = 0, AutoButtonColor = true, Text = "👀",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 17,
}, actions)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, previewBtn)

-- 3) หัวข้อ "ไข่" (พับได้) — ยุบ 3 label เดิมไว้ในนี้
local eggHead = mk("TextButton", {
    Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, LayoutOrder = 3,
    AutoButtonColor = false, Text = "",
}, body)
local eggChev = mk("TextLabel", {
    Size = UDim2.new(0, 14, 0, 38), BackgroundTransparency = 1, Text = "▼",
    TextColor3 = C.Muted, Font = Enum.Font.GothamBold, TextSize = 9,
}, eggHead)
local metaLbl = mk("TextLabel", {
    Size = UDim2.new(1, -18, 0, 20), Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1, Text = "🥚 เลือก 0/0 · ยังไม่เลือก",
    TextColor3 = C.Sub, Font = Enum.Font.GothamBold, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, eggHead)
local spawnLbl = mk("TextLabel", {
    Size = UDim2.new(1, -18, 0, 17), Position = UDim2.new(0, 16, 0, 20),
    BackgroundTransparency = 1, Text = "กำลังสแกนไข่ในแมพ ...",
    TextColor3 = C.Amber, Font = Enum.Font.Gotham, TextSize = 10.5,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, eggHead)

-- 4) ตารางไข่ — 5 คอลัมน์แบบยืดตามความกว้าง (มือถือไม่เพี้ยน)
--    📐 สูง 166 = padding 8 + แถว 72 + ช่อง 6 + แถว 72 + padding 8 → 2 แถวแรกเห็นเต็ม ๆ ไม่โดนตัด
local grid = mk("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 166), BackgroundColor3 = C.BgDark,
    BackgroundTransparency = 0.35, BorderSizePixel = 0, ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.Stroke, AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0), LayoutOrder = 4,
}, body)
mk("UICorner", { CornerRadius = UDim.new(0, 10) }, grid)
mk("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
                  PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, grid)
mk("UIGridLayout", {
    CellSize = UDim2.new(0.2, -6, 0, 72), CellPadding = UDim2.new(0, 6, 0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, grid)

-- 5) หัวข้อ "ล็อก" (พับได้)
local logHead = mk("TextButton", {
    Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = 5,
    AutoButtonColor = false, Text = "",
}, body)
local logChev = mk("TextLabel", {
    Size = UDim2.new(0, 14, 0, 22), BackgroundTransparency = 1, Text = "▼",
    TextColor3 = C.Muted, Font = Enum.Font.GothamBold, TextSize = 9,
}, logHead)
mk("TextLabel", {
    Size = UDim2.new(1, -60, 0, 22), Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1, Text = "📋 ล็อก", TextColor3 = C.Sub,
    Font = Enum.Font.GothamBold, TextSize = 11.5,
    TextXAlignment = Enum.TextXAlignment.Left,
}, logHead)
local logClear = mk("TextButton", {
    Size = UDim2.new(0, 44, 0, 20), Position = UDim2.new(1, -46, 0, 1),
    BackgroundColor3 = C.Card, BorderSizePixel = 0, AutoButtonColor = true,
    Text = "ล้าง", TextColor3 = C.Sub, Font = Enum.Font.Gotham, TextSize = 10,
}, logHead)
mk("UICorner", { CornerRadius = UDim.new(0, 6) }, logClear)

-- 6) ล็อก : 120px (เดิม 64px) — อ่านได้ ~9 บรรทัด
local logBox = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = C.Log,
    BackgroundTransparency = 0.15, BorderSizePixel = 0, LayoutOrder = 6,
}, body)
mk("UICorner", { CornerRadius = UDim.new(0, 8) }, logBox)
local logLbl = mk("TextLabel", {
    Size = UDim2.new(1, -14, 1, -10), Position = UDim2.new(0, 7, 0, 5),
    BackgroundTransparency = 1, Text = "", TextColor3 = C.Muted,
    Font = Enum.Font.Code, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
}, logBox)

-- 7) footer : ตัวนับ + ปุ่มทำลาย (แยกห่างจากปุ่มหลัก กันคลิกพลาด)
local foot = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.BgDark,
    BackgroundTransparency = 0.35, BorderSizePixel = 0, LayoutOrder = 7,
}, body)
mk("UICorner", { CornerRadius = UDim.new(0, 9) }, foot)
local countLbl = mk("TextLabel", {
    Size = UDim2.new(1, -104, 1, 0), Position = UDim2.new(0, 11, 0, 0),
    BackgroundTransparency = 1, Text = "เก็บแล้ว 0 ใบ", TextColor3 = C.Sub,
    Font = Enum.Font.Gotham, TextSize = 11.5,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, foot)
local rejoinBtn = mk("TextButton", {
    Size = UDim2.new(0, 86, 1, -8), Position = UDim2.new(1, -92, 0, 4),
    BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = true,
    Text = "🔁 รีจอย", TextColor3 = Color3.fromRGB(248, 113, 113),
    Font = Enum.Font.GothamBold, TextSize = 11.5,
}, foot)
mk("UICorner", { CornerRadius = UDim.new(0, 8) }, rejoinBtn)
mk("UIStroke", { Color = Color3.fromRGB(239, 68, 68), Thickness = 1.2, Transparency = 0.25 }, rejoinBtn)

-- 🔽 พับ/กางหัวข้อ (progressive disclosure — ระบบใหม่ไม่ทำให้หน้ายาวขึ้น)
eggHead.Activated:Connect(function()
    grid.Visible = not grid.Visible
    eggChev.Text = grid.Visible and "▼" or "▶"
end)
logHead.Activated:Connect(function()
    logBox.Visible = not logBox.Visible
    logChev.Text = logBox.Visible and "▼" or "▶"
end)

-- ---------- ผู้ช่วยฝั่ง UI ----------
-- 🎞️ "UI อัปเดตทุกเฟรม" : setter ทุกตัวเขียนลง "แคช U" อย่างเดียว (ไม่แตะ Instance เลย)
--     แล้ว RenderStepped (60 fps) ค่อยเทค่าไปเขียน Label จริง รอบเดียวต่อเฟรม
--     → logLine ถูกเรียก 20 ครั้งใน 1 เฟรม = layout แค่ 1 ครั้ง (ไม่กระตุก)
local U = {
    log         = "",
    statusMsg   = "หยุดอยู่",
    statusColor = C.Sub,
    badge       = "0 ใบ",
    dot         = false,
    count       = "เก็บแล้ว 0 ใบ",
    meta        = "🥚 เลือก 0/" .. #EGG_DATA .. " · ยังไม่เลือก · 👁️ ESP",
    spawn       = "กำลังสแกนไข่ในแมพ ...",
    spawnColor  = C.Amber,
}
local ap = {}   -- ค่าที่ "เขียนลง Instance จริง" ไปแล้ว (ไว้เทียบ กันเขียนซ้ำเปล่า ๆ)

local logLines = {}
local function logLine(msg)
    table.insert(logLines, os.date("%H:%M:%S") .. "  " .. msg)
    while #logLines > 10 do table.remove(logLines, 1) end   -- กล่องล็อกสูง 120px → อ่านได้ ~10 บรรทัด
    U.log = table.concat(logLines, "\n")
end
local function setStatus(msg, color)
    U.statusMsg = msg
    U.statusColor = color or C.Sub
end

-- 🔽 ปุ่ม "ล้าง" ในหัวข้อล็อก
logClear.Activated:Connect(function()
    for i = #logLines, 1, -1 do logLines[i] = nil end
    U.log = ""
end)

-- 💠 badge ในแถบสถานะ (ใช้โชว์ "N ใบ" หรือ "1.24 เท่า")
local function setBadge(t) U.badge = t end

-- 💡 LED ในแถบสถานะ (เขียว = ฟาร์มอยู่)
local function setDot(on) U.dot = on end

-- 🧮 ตัวนับ "เก็บแล้ว" ที่ footer
local collectedTotal = 0
local function setCollected(n)
    collectedTotal = n
    U.count = "เก็บแล้ว " .. n .. " ใบ"
end
local function bumpCollected() setCollected(collectedTotal + 1) end

if not remoteOk then logLine("[!] โหลด remote ไม่ครบ") end

-- ============================================================
-- ส่วนที่ 2 : ตารางเลือกไข่
-- ============================================================
local tileByEgg = {}

-- 🎞️ ตัววาด UI "ทุกเฟรม" — ที่นี่ที่เดียวที่เขียน Instance จริง
--     (setter ทุกตัวเขียนลงแคช U / t.* ไว้ก่อนแล้ว → เทียบแล้วเขียนเฉพาะที่เปลี่ยน)
--     ติดกับ RenderStepped = จอ 60 fps → UI ขยับตาม 60 fps ทันทีที่ค่าเปลี่ยน
local function applyUI()
    if ap.log ~= U.log then ap.log = U.log; logLbl.Text = U.log end
    if ap.statusMsg ~= U.statusMsg then ap.statusMsg = U.statusMsg; statusLbl.Text = U.statusMsg end
    if ap.statusColor ~= U.statusColor then ap.statusColor = U.statusColor; statusLbl.TextColor3 = U.statusColor end
    if ap.badge ~= U.badge then ap.badge = U.badge; statusBadge.Text = U.badge end
    if ap.count ~= U.count then ap.count = U.count; countLbl.Text = U.count end
    if ap.meta ~= U.meta then ap.meta = U.meta; metaLbl.Text = U.meta end
    if ap.spawn ~= U.spawn then ap.spawn = U.spawn; spawnLbl.Text = U.spawn end
    if ap.spawnColor ~= U.spawnColor then ap.spawnColor = U.spawnColor; spawnLbl.TextColor3 = U.spawnColor end
    if ap.dot ~= U.dot then ap.dot = U.dot; statusDot.BackgroundColor3 = U.dot and C.Green or C.Muted end

    for _, t in pairs(tileByEgg) do
        local a = t.ap
        if not a then a = {}; t.ap = a end
        if a.sel ~= t.sel then                          -- 🎯 สถานะเลือก (แตะ / กดค้าง)
            a.sel = t.sel
            local idx, mode = t.selIdx, t.selMode
            if idx then
                t.badge.Visible = true
                t.q.Text = (mode == "auto") and "∞" or tostring(idx)
                t.tile.BackgroundColor3 = (mode == "auto")
                    and Color3.fromRGB(18, 51, 36)      -- 🟩 เขียว = ออโต้
                    or  Color3.fromRGB(21, 40, 68)      -- 🟦 น้ำเงิน = ใบเดียว
                t.stroke.Thickness = 2.4
            else
                t.badge.Visible = false
                t.tile.BackgroundColor3 = C.Card
                t.stroke.Thickness = 1.4
            end
        end
        if a.spawn ~= t.spawnNow then                   -- 🟡 จุด "ไข่ตัวนี้เกิดอยู่ในแมพตอนนี้"
            a.spawn = t.spawnNow
            t.dot.Visible = t.spawnNow
        end
    end
end

local uiPaintConn
uiPaintConn = RunService.RenderStepped:Connect(function()
    if not sg.Parent then uiPaintConn:Disconnect(); return end  -- ปิดหน้าต่างแล้วหยุดวาด
    applyUI()
end)

-- ============================================================
-- 🎯 2 โหมดเลือกไข่ :
--    👆 แตะ         = เลือก "ใบเดียว"  (ใบใหม่แทนที่ใบเก่า) → ⚡ ฟาร์มจนหมดในแมพแล้วหยุดเอง
--    👆 กดค้าง 3 วิ  = เลือกแบบ "ออโต้" (เพิ่มได้หลายใบ)     → ⚡ ฟาร์มยาว ๆ ไม่หยุด
-- ============================================================
local eggMode = {}   -- eggMode[name] = "once" | "auto"

local function hasAutoMode()
    for _, n in ipairs(selectedEggs) do
        if eggMode[n] == "auto" then return true end
    end
    return false
end

local function refreshSelection()
    -- ⚠️ ไม่เขียน Label ตรง ๆ — ให้เขียน "สถานะ" ลง t.* แล้วรอ applyUI() วาดทุกเฟรมแทน
    for name, t in pairs(tileByEgg) do
        local idx, mode = nil, nil
        for k, n in ipairs(selectedEggs) do
            if n == name then idx = k; mode = eggMode[name] or "once"; break end
        end
        t.selIdx, t.selMode = idx, mode
        t.sel = idx and ((mode or "once") .. ":" .. idx) or ""
    end
    local n = #selectedEggs
    local auto = hasAutoMode()
    -- 👁️ ต่อท้ายเสมอ : ให้เห็นว่า ESP เปิด/ปิดอยู่ (เปิด = ใบเดียว · ปิด = กดค้างออโต้)
    local espTxt = auto and " · 👁️ ปิด" or " · 👁️ ESP"
    if n > 0 then
        U.meta = "🥚 เลือก " .. n .. "/" .. #EGG_DATA .. " · "
            .. (auto and "โหมด ออโต้ ∞" or "โหมด ใบเดียว") .. espTxt
        setBadge(auto and (n .. " ใบ") or "1 ใบ")
    else
        U.meta = "🥚 เลือก 0/" .. #EGG_DATA .. " · ยังไม่เลือก" .. espTxt
        setBadge("0 ใบ")
    end
end

-- 👆 "แตะ" = เลือกใบเดียว (ใบใหม่แทนที่ใบเก่าทั้งหมด)
local function selectOnce(name)
    for i = #selectedEggs, 1, -1 do selectedEggs[i] = nil end
    eggMode = {}
    table.insert(selectedEggs, name)
    eggMode[name] = "once"
    refreshSelection()
    logLine("[👆] แตะ " .. name .. " → ใบเดียว (เสร็จแล้วหยุดเอง)")
end

-- 👆 "กดค้าง" = เพิ่มแบบออโต้ (ฟาร์มยาว ๆ) — ถ้ามีอยู่แล้ว = เอาออก
local function toggleAuto(name)
    local found = false
    for _, n in ipairs(selectedEggs) do
        if n == name then found = true; break end
    end
    if found and eggMode[name] == "auto" then
        for k, n in ipairs(selectedEggs) do
            if n == name then table.remove(selectedEggs, k); break end
        end
        eggMode[name] = nil
        logLine("[👆] เอา " .. name .. " ออกจากคิว")
    else
        if not found then table.insert(selectedEggs, name) end
        eggMode[name] = "auto"
        logLine("[👆] กดค้าง " .. name .. " → ออโต้ ∞ (ฟาร์มยาว)")
    end
    refreshSelection()
end

-- ⏱️ ระบบกดค้าง 3 วิ — ใช้ได้ทั้งเมาส์และนิ้ว (มือถือ)
local holdName, holdProg, holdTween, holdSeq = nil, nil, nil, 0
local function cancelHold(fire)
    holdSeq = holdSeq + 1                      -- ยกเลิก timer เก่าที่ค้างอยู่
    local n = holdName
    if holdTween then pcall(function() holdTween:Cancel() end); holdTween = nil end
    if holdProg then holdProg.Visible = false; holdProg = nil end
    holdName = nil
    if not n then return end
    if fire then toggleAuto(n) else selectOnce(n) end
end

for i, row in ipairs(EGG_DATA) do
    local fullName, rarity, image, short = row[1], row[2], row[3], row[4]
    local col = RARITY_COLOR[rarity] or C.Sub

    local tile = mk("ImageButton", {
        Size = UDim2.new(0, 64, 0, 74), BackgroundColor3 = C.Card,
        BorderSizePixel = 0, AutoButtonColor = true, LayoutOrder = i, Image = "",
    }, grid)
    mk("UICorner", { CornerRadius = UDim.new(0, 9) }, tile)
    local stroke = mk("UIStroke", { Color = col, Thickness = 1.4 }, tile)

    -- 🖼️ รูปไข่ : มี asset ในตาราง → ใช้เลย / ยังไม่มี → รอสแกน "โมเดลในแมพ" มาเติมทีหลัง
    --    (ระหว่างรอโชว์ emoji สำรอง ไม่เอาชื่อซ้ำกับแถบชื่อด้านล่าง)
    local img = mk("ImageLabel", {
        Size = UDim2.new(1, -8, 1, -26), Position = UDim2.new(0, 4, 0, 3),
        BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
        Image = (image ~= "") and ("rbxassetid://" .. image) or "",
        Visible = (image ~= ""), ZIndex = 2,
    }, tile)
    local fbLbl = mk("TextLabel", {
        Size = UDim2.new(1, -8, 1, -26), Position = UDim2.new(0, 4, 0, 3),
        BackgroundTransparency = 1, Text = (image ~= "") and "" or (FALLBACK_GLYPH[rarity] or "🥚"),
        TextColor3 = col, Font = Enum.Font.GothamBold, TextSize = 26,
        TextWrapped = true, Visible = (image == ""), ZIndex = 2,
    }, tile)

    mk("TextLabel", {
        Size = UDim2.new(1, -4, 0, 15), Position = UDim2.new(0, 2, 1, -17),
        BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45,
        Text = short, TextColor3 = col, Font = Enum.Font.GothamBold, TextSize = 8,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, tile)

    local badge = mk("Frame", {
        Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -19, 0, 3),
        BackgroundColor3 = C.Green, BorderSizePixel = 0, Visible = false, ZIndex = 5,
    }, tile)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)
    local qTxt = mk("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 6,
        Text = "1", TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold, TextSize = 9,
    }, badge)

    -- 🟡 จุดมุมซ้ายบน = "ไข่ตัวนี้เกิดอยู่ในแมพตอนนี้"
    --    (คนละมุมกับเลขคิวที่อยู่มุมขวาบน ไม่ชนกัน)
    local spawnDot = mk("Frame", {
        Size = UDim2.new(0, 9, 0, 9), Position = UDim2.new(0, 4, 0, 4),
        BackgroundColor3 = C.Amber, BorderSizePixel = 0, Visible = false, ZIndex = 5,
    }, tile)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, spawnDot)

    -- 🟣 แถบความคืบหน้า 3 วิ — feedback ให้เห็นว่า "กำลังกดค้าง"
    local prog = mk("Frame", {
        Size = UDim2.new(0, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3),
        BackgroundColor3 = Color3.fromRGB(168, 85, 247), BorderSizePixel = 0,
        Visible = false, ZIndex = 7,
    }, tile)

    tileByEgg[fullName] = {
        tile = tile, badge = badge, q = qTxt, stroke = stroke, dot = spawnDot,
        img = img, fb = fbLbl, hasImg = (image ~= ""), tries = 0,   -- สำหรับสแกนรูปจากโมเดล
        ap = {}, sel = "", selIdx = nil, selMode = nil, spawnNow = false,  -- สำหรับตัววาดทุกเฟรม
    }

    tile.InputBegan:Connect(function(io)
        if io.UserInputType ~= Enum.UserInputType.MouseButton1
        and io.UserInputType ~= Enum.UserInputType.Touch then return end
        local seq = holdSeq + 1
        holdSeq = seq
        holdName, holdProg = fullName, prog
        prog.Size = UDim2.new(0, 0, 0, 3)
        prog.Visible = true
        holdTween = TweenService:Create(prog, TweenInfo.new(3, Enum.EasingStyle.Linear),
                                        { Size = UDim2.new(1, 0, 0, 3) })
        holdTween:Play()
        task.delay(3, function()                  -- ครบ 3 วิ = เลือกแบบออโต้
            if holdSeq == seq then cancelHold(true) end
        end)
    end)
end

-- 🖐 ปล่อยก่อนครบ 3 วิ = "แตะปกติ" (เลือกใบเดียว)
UIS.InputEnded:Connect(function(io)
    if io.UserInputType ~= Enum.UserInputType.MouseButton1
    and io.UserInputType ~= Enum.UserInputType.Touch then return end
    if holdName then cancelHold(false) end
end)

refreshSelection()

-- ============================================================
-- ส่วนที่ 3 : ลอจิกเก็บไข่
-- ============================================================

-- ไข่ที่ "หลุดอยู่ในแมพ" จริง (ไม่ใช่ไข่ในแปลง/รัง/ของตัวละคร)
local function isWildEgg(item)
    local curr = item
    while curr and curr ~= workspace do
        -- 🥚 "EGG_PREVIEW" = โคลนตัวอย่างที่ระบบ 👀 ดึงมาวางหน้า ไม่ใช่ไข่จริง
        if curr.Name == "EGG_PREVIEW" then return false end
        if curr:IsA("Camera") then return false end
        local n = string.lower(curr.Name)
        if n:find("plot", 1, true) or n:find("nest", 1, true) or n:find("base", 1, true)
           or curr:FindFirstChild("Humanoid") then
            return false
        end
        curr = curr.Parent
    end
    return true
end

local function eggPart(egg)
    return egg:FindFirstChild("Handle") or egg:FindFirstChild("EggBase")
        or egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")
end

-- นับไข่ชื่อนี้ที่เรามี (ตัวละคร + เป้) พร้อมบอกว่า "ถืออยู่ในมือ" ไหม
local function countOwnedEggs(eggName)
    local count, inHand = 0, false
    local low = string.lower(eggName)
    local char = player.Character
    if char then
        for _, v in ipairs(char:GetChildren()) do
            if (v:IsA("Tool") or v:IsA("Model")) and string.find(string.lower(v.Name), low, 1, true) then
                count = count + 1; inHand = true
            end
        end
    end
    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, v in ipairs(bp:GetChildren()) do
            if (v:IsA("Tool") or v:IsA("Model")) and string.find(string.lower(v.Name), low, 1, true) then
                count = count + 1
            end
        end
    end
    return count, inHand
end

local function ensureEggInHand(eggName)
    local char = player.Character
    if not char then return false end
    local low = string.lower(eggName)
    for _, v in ipairs(char:GetChildren()) do
        if (v:IsA("Tool") or v:IsA("Model")) and string.find(string.lower(v.Name), low, 1, true) then
            return true
        end
    end
    local bp = player:FindFirstChild("Backpack")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if bp and hum then
        for _, v in ipairs(bp:GetChildren()) do
            if v:IsA("Tool") and string.find(string.lower(v.Name), low, 1, true) then
                pcall(function() hum:EquipTool(v) end)
                return true
            end
        end
    end
    return false
end

local function unequipAll()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum:UnequipTools() end) end
end

-- ✋ "บังคับถือมือเปล่า" : ถอดทุก Tool แล้ววนตรวจซ้ำจนกว่าตัวละครจะว่างจริง
local function forceBareHands()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return false end
    local t0 = os.clock()
    while os.clock() - t0 < 3 do
        pcall(function() hum:UnequipTools() end)
        local holding = false
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") then holding = true break end
        end
        if not holding then return true end
        task.wait(0.15)
    end
    return false -- ครบ 3 วิ ยังถืออยู่ → รอบฟาร์มถัดไปจะลองใหม่
end

-- 🏠 หา "แปลง" ของผู้เล่น (วิธีเดียวกับของเดิม — แก้บั๊กบ้านไม่ย้ายตามแปลง)
local function getPlotCFrame()
    local ok1, anchor = pcall(function()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil end
        for _, plot in ipairs(plots:GetChildren()) do
            if plot:IsA("Model") then
                local data = plot:FindFirstChild("Data")
                local owner = data and data:FindFirstChild("Owner")
                local v = owner and owner.Value
                if v == player or (v ~= nil and tostring(v) == player.Name) then
                    local s = plot:FindFirstChild("Spawn") or plot:FindFirstChild("SpawnLocation")
                        or plot:FindFirstChild("Baseplate")
                    if s then return s.CFrame + Vector3.new(0, 3, 0) end
                    return plot:GetPivot() + Vector3.new(0, 3, 0)
                end
            end
        end
        return nil
    end)
    if ok1 and anchor then return anchor end

    local ok2, a2 = pcall(function()
        local pn = player.Name
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Text:find(pn, 1, true) then
                local mp = obj:FindFirstAncestorWhichIsA("Model")
                if mp then
                    local s = mp:FindFirstChild("Spawn") or mp:FindFirstChild("SpawnLocation")
                        or mp:FindFirstChild("Baseplate")
                    if s then return s.CFrame + Vector3.new(0, 3, 0) end
                    return mp:GetPivot() + Vector3.new(0, 3, 0)
                end
            end
        end
        return nil
    end)
    if ok2 and a2 then return a2 end
    return nil
end

-- 📡 สแกนไข่ทั้งหมดในแมพ → คืนตาราง { "Solaris Egg" = {egg, egg, ...}, ... }
--    ใช้ร่วมกัน 2 ทาง : ลูปฟาร์ม (หาเป้าหมาย) และป้ายบอกไข่ที่เกิดอยู่
local function scanAll()
    local byName = {}
    for _, item in ipairs(workspace:GetDescendants()) do
        if (item:IsA("Model") or item:IsA("Tool")) and isWildEgg(item) then
            local lowItem = string.lower(item.Name)
            for _, row in ipairs(EGG_DATA) do
                local en = row[1]
                if string.find(lowItem, string.lower(en), 1, true) then
                    local arr = byName[en]
                    if not arr then arr = {}; byName[en] = arr end
                    table.insert(arr, item)
                    break
                end
            end
        end
    end
    return byName
end

-- เคารพ "ลำดับที่ติ๊ก" (ติ๊กก่อน = เจอ = ไปก่อน)
local function scanQueue()
    local byName = scanAll()
    for _, name in ipairs(selectedEggs) do
        local arr = byName[name]
        if arr and #arr > 0 then return arr[1] end
    end
    return nil
end

-- ✈️ noclip แบบจำตำแหน่งเดิม แล้วคืนค่าตอนหยุด (ไม่ใช่ตั้งค่า true ทั้งตัวเหมือนของเดิม)
--    ⚡ ลดงานต่อเฟรม : เดิมเรียก char:GetDescendants() + เขียน CanCollide "ทุกเฟรม"
--       (60 ครั้ง/วิ × ทุกชิ้นส่วน = สร้างตาราง + GC ไม่หยุดตลอดช่วงบิน)
--       ตอนนี้ = หา BasePart ใหม่ทุก 0.3 วิ + เขียน CanCollide "เฉพาะตอนยังเป็น true"
--       ผลลัพธ์เหมือนเดิมทุกประการ แต่ภาระต่อเฟรมลดลงมาก
local function startNoClip()
    local saved, conn = {}, nil
    local parts, nextScan = {}, 0
    conn = RunService.Stepped:Connect(function()
        local now = os.clock()
        if now >= nextScan then
            nextScan = now + 0.3                       -- หาชิ้นส่วนใหม่ทุก 0.3 วิ
            local char = player.Character
            if char then
                local n = 0
                for _, q in ipairs(char:GetDescendants()) do
                    if q:IsA("BasePart") then n = n + 1; parts[n] = q end
                end
                for i = #parts, n + 1, -1 do parts[i] = nil end
            end
        end
        for i = 1, #parts do
            local p = parts[i]
            if p.Parent and p.CanCollide then          -- เขียนเฉพาะตอนยังเป็น true
                if saved[p] == nil then saved[p] = p.CanCollide end
                p.CanCollide = false
            end
        end
    end)
    return function()
        if conn then conn:Disconnect(); conn = nil end
        for p, v in pairs(saved) do
            if p.Parent then p.CanCollide = v end
        end
        for k in pairs(saved) do saved[k] = nil end
        for i = #parts, 1, -1 do parts[i] = nil end
    end
end

-- ⚡ วาร์ป (CFrame ล้วน — ไม่ยิง remote ใด ๆ)
--    ระยะไกลมาก → กระโดดผ่านจุดกลางก่อน กันเซิร์ฟเวอร์ดีดตำแหน่งกลับ (rollback)
local function teleportTo(targetCF)
    local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not h then return false end
    if (targetCF.Position - h.Position).Magnitude > 500 then
        h.CFrame = CFrame.new(h.Position:Lerp(targetCF.Position, 0.5))
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.05)
    end
    h.CFrame = targetCF
    h.AssemblyLinearVelocity = Vector3.zero
    h.AssemblyAngularVelocity = Vector3.zero
    return true
end

-- ============================================================
-- 🌋 ระบบดรอปลาวา (DROP IN VOLCANO)
-- ============================================================

-- จุดไต่ 1 → 4 (คัดจาก VIP.txt ไม่แตะของเดิม)
local DIP_WP = {
    Vector3.new(-4889.14, 41279.30, -3741.22), -- 1 เริ่มไต่ในเขา
    Vector3.new(-4977.07, 41687.00, -3623.26), -- 2 ไต่สูงสุด
    Vector3.new(-5078.04, 41580.33, -3447.32), -- 3 ลงมาชานปล่อง
    Vector3.new(-5115.66, 41466.20, -3441.70), -- 4 จุดดรอป (ยืนกด "ทิ้งในภูเขาไฟ")
}

-- 🎲 delay สุ่มให้การขยับดูไม่แข็งทื่อ
local function getNaturalDelay()
    return math.random(50, 150) / 1000
end

-- 📡 จับข้อความปฏิเสธจากเกม
--    ตัวอย่างจริงที่ขึ้นในจอ: "Every Egg You Carry Has Already Been In The Volcano"
--    (ไข่ที่เกมดีดตกลาวาเอง = เคยอยู่ในลาวาแล้ว → ดรอปซ้ำไม่ได้)
--    ถ้าเจอ → ยกเลิกดรอปรอบนั้นทันที ไม่ยืนรอ 10 วิ เปล่า ๆ กลางลาวา
local dipRejection = nil   -- nil = ยังไม่เจอ / string = ข้อความที่เกมตอบกลับ

local function noteRejection(msg)
    local s = tostring(msg or "")
    if s == "" then return end
    local low = string.lower(s)
    if (string.find(low, "already", 1, true) and string.find(low, "volcano", 1, true))
        or string.find(low, "been in the volcano", 1, true) then
        dipRejection = s
    end
end

-- 🔌 เสียบตัวฟังครั้งเดียวตอนเปิดไฟล์ (ไม่ต่อซ้ำทุกรอบ)
local function wireDipWatcher()
    pcall(function()
        local rem = RS:FindFirstChild("Remotes") and RS.Remotes:FindFirstChild("Reusable")
        if rem then
            for _, n in ipairs({ "GameMessage", "GlobalMessage", "ServerMessage", "GameWarning" }) do
                local r = rem:FindFirstChild(n)
                if r and r:IsA("RemoteEvent") then
                    r.OnClientEvent:Connect(function(...)
                        for i = 1, select("#", ...) do
                            local v = select(i, ...)
                            if type(v) == "string" then noteRejection(v) end
                        end
                    end)
                end
            end
        end
        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            local gw = pg:FindFirstChild("Reusable") and pg.Reusable:FindFirstChild("GameWarning")
            if gw and gw:IsA("TextLabel") then
                gw:GetPropertyChangedSignal("Text"):Connect(function() noteRejection(gw.Text) end)
            end
            local main = pg:FindFirstChild("Main")
            local tw = main and main:FindFirstChild("Typewriter")
            if tw and tw:IsA("TextLabel") then
                tw:GetPropertyChangedSignal("Text"):Connect(function() noteRejection(tw.Text) end)
            end
        end
    end)
end
wireDipWatcher()

-- 👀 อ่านข้อความบนจอโดยตรง (สำรอง เผื่อเกมไม่ได้ส่งผ่าน remote)
local function screenTexts()
    local a, b = "", ""
    pcall(function()
        local pg = player:FindFirstChild("PlayerGui")
        if pg then
            local gw = pg:FindFirstChild("Reusable") and pg.Reusable:FindFirstChild("GameWarning")
            if gw then a = tostring(gw.Text or "") end
            local main = pg:FindFirstChild("Main")
            local tw = main and main:FindFirstChild("Typewriter")
            if tw then b = tostring(tw.Text or "") end
        end
    end)
    return a, b
end

-- 🌋 หนึ่งรอบดรอป : ไต่ 1→4 → กด "ทิ้งในภูเขาไฟ" → รอ 10 วิ เต็ม → ไข่กลับเข้าตัว
--    ⏱️ นับ 10 วิ เต็ม ๆ ห้ามออกก่อน — ยกเว้นถูกเกมปฏิเสธ / ตัวละครหาย (ต้องออกทันที)
local function runVolcanoDip()
    if dipRunning then return end
    dipRunning = true
    pcall(function()
        local netFolder = RS:FindFirstChild("packages") and RS.packages:FindFirstChild("Net")
        local volcDipRemote = netFolder and netFolder:FindFirstChild("RE/VolcanoDip")

        local function heldEggName()
            local ch = player.Character
            if ch then
                for _, v in ipairs(ch:GetChildren()) do
                    if (v:IsA("Tool") or v:IsA("Model"))
                        and string.find(string.lower(v.Name), "egg", 1, true) then
                        return v.Name
                    end
                end
            end
            return nil
        end

        local char0 = player.Character   -- เผื่อตาย / respawn ระหว่างทาง
        dipRejection = nil               -- 🔁 ล้างค่าเก่าก่อนยิงรอบใหม่
        -- เก็บข้อความ "เดิม" ไว้เทียบ — กันเผลอเอาข้อความค้างจากกก่อนหน้ามาตัดสิน
        local baseA, baseB = screenTexts()
        logLine("[🌋] ไต่จุดดรอป 1 -> 4")
        for i = 1, 4 do
            local ch = player.Character
            if ch ~= char0 then
                logLine("[🌋] ตัวละครเปลี่ยนระหว่างไต่ -> ยกเลิก")
                return
            end
            local h = ch and ch:FindFirstChild("HumanoidRootPart")
            if not h then
                logLine("[🌋] ไม่มี HRP ระหว่างไต่ -> ยกเลิก")
                return
            end
            teleportTo(CFrame.new(DIP_WP[i]))
            task.wait(getNaturalDelay())
        end

        -- กด "ทิ้งในภูเขาไฟ" : remote ก่อน → เว้น 1 วิ → ค่อยกดปุ่ม UI
        pcall(function()
            if volcDipRemote then volcDipRemote:FireServer() end
        end)
        task.wait(1)
        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            local main = pg and pg:FindFirstChild("Main")
            local holder = main and main:FindFirstChild("ActionsHolder")
            local btn = holder and holder:FindFirstChild("DropEggVolcanoButton")
            if btn and firesignal then firesignal(btn.Activated) end
        end)
        -- ถ้าเกมเด้งหน้า Confirmation ขึ้นมา ยืนยันด้วย
        pcall(function()
            local pg = player:FindFirstChild("PlayerGui")
            local main = pg and pg:FindFirstChild("Main")
            local confirm = main and main:FindFirstChild("Confirmation")
            local confirmBtn = confirm and confirm:FindFirstChild("Confirm")
            if confirmBtn and confirmBtn.Visible and firesignal then
                firesignal(confirmBtn.Activated)
            end
        end)

        -- ⏱️ นับ 10 วิ เต็ม ๆ ห้ามออกก่อน
        --    ยกเว้น 3 เงื่อนไขนี้ที่ "ต้อง" ออกทันที (ไม่งั้นยืนแช่กลางลาวาเปล่า ๆ):
        --    ① เกมปฏิเสธ — "ไข่ที่ถือเคยอยู่ในลาวาแล้ว"
        --    ② ตัวละครตาย / respawn
        --    ③ HumanoidRootPart หาย
        logLine("[🌋] กดทิ้งแล้ว - นับ 10 วิ (ออกทันทีถ้าถูกปฏิเสธ)")
        local t0 = os.clock()
        while os.clock() - t0 < 10 do
            if dipRejection then
                logLine("[🌋] เกมปฏิเสธ -> " .. string.sub(dipRejection, 1, 46))
                return
            end
            -- อ่านจอทุก 0.1 วิ — ถ้าข้อความ "เปลี่ยน" ไปจากตอนเริ่มรอบ ค่อยเอามาตรวจ
            local a, b = screenTexts()
            if a ~= baseA then noteRejection(a) end
            if b ~= baseB then noteRejection(b) end
            if dipRejection then
                logLine("[🌋] เกมปฏิเสธ -> " .. string.sub(dipRejection, 1, 46))
                return
            end
            local ch = player.Character
            if ch ~= char0 or not (ch and ch:FindFirstChild("HumanoidRootPart")) then
                logLine("[🌋] ตัวละครหาย/ตาย -> ยกเลิก")
                return
            end
            task.wait(0.1)
        end

        local got = heldEggName()
        if got then ensureEggInHand(got) end
        logLine("[🌋] ครบ 10 วิ - ไข่กลับเข้าตัวแล้ว")
    end)
    dipRunning = false
end

-- ============================================================
-- 🌋 ระบบถ้ำ Volcanic (Lair) — เก็บไข่ Volcanic Egg ในรัง Volkaris
-- ============================================================

-- 🗺️ เส้นทางออกจากรัง 32 จุด (ของเดิม VIP.txt — บันทึกด้วยปุ่ม 📍 28/09)
--    ขาออก = 1 → 32 | ขาเข้า = "กลับด้าน" (จุดใกล้สุด → 1 พื้นรัง)  ← แทนการดำลงไปตรง ๆ
--    ถ้ำคดเคี้ยวจริง: พื้นรัง → ทางตรงยาว → โค้งกลับ → ไต่ขึ้น → ทางโค้งเข้าประตู → ทะลุออกฝั่งนอก
--    ⚠️ จุดถี่ ๆ คือหัวโค้ง — บินตามจุดจะไม่ลัดมุมทะลุกำแพง อย่าลบจุดออก
local LAIR_EXIT_WP = {
    Vector3.new(-5211.01, 40915.91, -3673.82), -- 1 พื้นรังข้างจุดไข่
    Vector3.new(-5177.72, 40918.05, -3676.73), -- 2
    Vector3.new(-5124.70, 40928.25, -3673.93), -- 3
    Vector3.new(-5048.40, 40933.48, -3668.24), -- 4 ทางตรงยาว
    Vector3.new(-4999.60, 40940.99, -3649.39), -- 5
    Vector3.new(-4949.55, 40971.27, -3588.31), -- 6 โค้งขึ้น
    Vector3.new(-4886.67, 40990.46, -3508.63), -- 7
    Vector3.new(-4887.49, 41011.15, -3455.20), -- 8
    Vector3.new(-4921.06, 41048.64, -3402.87), -- 9 หัวโค้งกลับ
    Vector3.new(-4988.36, 41057.11, -3414.99), -- 10
    Vector3.new(-5031.25, 41057.99, -3432.58), -- 11
    Vector3.new(-5080.52, 41045.45, -3475.09), -- 12
    Vector3.new(-5123.11, 41042.11, -3519.22), -- 13
    Vector3.new(-5141.24, 41042.38, -3568.28), -- 14
    Vector3.new(-5211.53, 41037.48, -3655.17), -- 15 โค้งกลับฝั่งรัง
    Vector3.new(-5281.44, 41057.65, -3619.26), -- 16 ไต่ขึ้น
    Vector3.new(-5266.24, 41058.47, -3586.96), -- 17
    Vector3.new(-5264.86, 41132.23, -3580.96), -- 18 ขึ้นชั้นบน
    Vector3.new(-5262.67, 41147.85, -3579.27), -- 19
    Vector3.new(-5205.82, 41158.38, -3570.01), -- 20
    Vector3.new(-5203.89, 41158.34, -3533.01), -- 21
    Vector3.new(-5209.18, 41167.03, -3450.63), -- 22
    Vector3.new(-5187.23, 41176.93, -3361.70), -- 23
    Vector3.new(-4971.69, 41203.84, -3298.94), -- 24 ปลายทางไกล
    Vector3.new(-4921.61, 41216.80, -3353.61), -- 25 หัวโค้งกลับบน
    Vector3.new(-5007.15, 41236.02, -3418.17), -- 26
    Vector3.new(-5024.15, 41255.32, -3456.48), -- 27
    Vector3.new(-5035.04, 41272.61, -3507.58), -- 28 เข้าทางประตู
    Vector3.new(-5013.81, 41278.73, -3567.32), -- 29
    Vector3.new(-4975.75, 41291.44, -3636.59), -- 30 ใกล้ปากรู
    Vector3.new(-4961.88, 41290.99, -3663.05), -- 31 ปากรู (ช้า!)
    Vector3.new(-4881.39, 41290.24, -3718.06), -- 32 ทะลุออกประตูฝั่งนอกแล้ว
}

-- ✈️ บินลื่น ๆ noclip ตามจุด (ใช้เฉพาะเส้นทางถ้ำ — noclip คุมโดยผู้เรียก)
-- maxWait = วินาทีสูงสุดต่อหนึ่งจุด (ค่าเริ่ม 10 วิ) — ช่วง "ออกถ้ำ" ส่งค่า 2.5
--    กันยืนค้างจุดเดียวนาน ๆ ตอนถือไข่ (โดนเกมล็อกตัวละคร → 30 จุด x 10 วิ = 5 นาที = ดูเหมือนไม่บินออก)
local function volcFlyTo(targetPos, speed, maxWait)
    local startT, lastStep = os.clock(), os.clock()
    local limit = maxWait or 10
    while os.clock() - startT < limit do
        local ch = player.Character
        local h = ch and ch:FindFirstChild("HumanoidRootPart")
        if not h then break end
        local diff = targetPos - h.Position
        local dist = diff.Magnitude
        if dist <= 3 then break end
        local now = os.clock()
        local dt = math.clamp(now - lastStep, 0.005, 0.1)
        lastStep = now
        -- 🎲 สุ่ม 990-1000 แต่ไม่เกินความเร็วที่กำหนดของแต่ละช่วง
        local spd = math.min(math.random(990, 1000) + math.random() * 0.9, speed)
        local step = math.min(dist, spd * dt)
        h.CFrame = CFrame.new(h.Position + diff.Unit * step)
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
        RunService.Heartbeat:Wait()
    end
end

-- 🔥 บัฟ Scorching = เกมยอมรับว่าเรา "อยู่ในภูเขาไฟ" แล้ว (PlayerGui.Main.ActiveWeathers.Scorching)
local function hasScorching()
    local pg = player:FindFirstChild("PlayerGui")
    local main = pg and pg:FindFirstChild("Main")
    local aw = main and main:FindFirstChild("ActiveWeathers")
    return aw ~= nil and aw:FindFirstChild("Scorching") ~= nil
end

-- ============================================================
-- 🌋 เส้นทาง Volcanic บันทึกจากเกมจริง (30/09/2026) — ใช้ "เฉพาะไข่ Volcanic"
--    ขาเข้า : วาร์ป 1 → วาร์ป 2 → ลอยลง 3 → ลอยเข้า 4 (ทะลุประตู)
--              → เช็คบัฟ Scorching → บินลง 28 จุด ถึงรัง
--    ขาออก : ย้อน 28 จุด → 4 → 3 (หยุดที่จุดกลับออก) → ระบบลาวา 1 → 4
--    ⛔ ไม่ต้องหา VolcanoEntrance เองแล้ว (ของเดิมพังเพราะ streaming ยังไม่โหลด)
-- ============================================================

-- 🚪 4 จุดแรก = { ตำแหน่ง, ทิศหน้า }
local VOLC_GATE = {
    { Vector3.new(-4855.61, 40989.21, -3786.33), Vector3.new( 0.70, 0.00, -0.71) }, -- 1 วาร์ปไปจุดตั้งต้น
    { Vector3.new(-4917.39, 41342.01, -3692.59), Vector3.new(-0.84, 0.00,  0.54) }, -- 2 วาร์ปขึ้นด้านบน (รอ streaming โหลดประตู)
    { Vector3.new(-4919.37, 41294.62, -3702.98), Vector3.new(-0.71, 0.00,  0.71) }, -- 3 ลอยลง (จุดนี้เอง = จุดกลับออก)
    { Vector3.new(-4970.84, 41288.42, -3645.76), Vector3.new(-0.50, 0.00,  0.87) }, -- 4 ลอยเข้า = ทะลุประตู (เส้น 3->4 ตัดกลางประตูจริง)
}

-- 🧗 28 จุด ลงจากรูถ้ำจนถึงรัง (บันทึกตามจริง 06:30:22 -> 06:32:30)
local VOLC_DOWN = {
    Vector3.new(-5006.72, 41283.70, -3581.18), -- 1
    Vector3.new(-5027.67, 41267.25, -3478.05), -- 2
    Vector3.new(-4983.23, 41224.29, -3398.26), -- 3
    Vector3.new(-4928.70, 41210.12, -3365.37), -- 4
    Vector3.new(-4940.67, 41212.91, -3334.66), -- 5
    Vector3.new(-4964.73, 41200.26, -3305.07), -- 6
    Vector3.new(-5013.47, 41185.72, -3296.89), -- 7
    Vector3.new(-5057.71, 41176.39, -3303.30), -- 8
    Vector3.new(-5102.59, 41173.56, -3314.16), -- 9
    Vector3.new(-5145.71, 41170.49, -3291.70), -- 10
    Vector3.new(-5098.11, 41158.79, -3242.00), -- 11
    Vector3.new(-5054.11, 41135.78, -3223.38), -- 12
    Vector3.new(-5058.97, 41105.52, -3225.39), -- 13
    Vector3.new(-5010.38, 41093.11, -3215.74), -- 14
    Vector3.new(-5000.58, 41092.74, -3257.18), -- 15
    Vector3.new(-4994.71, 41089.67, -3297.52), -- 16
    Vector3.new(-5012.31, 41053.88, -3417.47), -- 17
    Vector3.new(-4982.14, 41055.60, -3405.97), -- 18
    Vector3.new(-4929.73, 41038.82, -3415.16), -- 19
    Vector3.new(-4896.31, 41017.68, -3445.22), -- 20
    Vector3.new(-4902.55, 40982.41, -3521.83), -- 21
    Vector3.new(-4951.21, 40968.73, -3584.84), -- 22
    Vector3.new(-5009.51, 40937.39, -3652.54), -- 23
    Vector3.new(-5046.27, 40928.49, -3674.11), -- 24
    Vector3.new(-5148.84, 40918.90, -3677.69), -- 25
    Vector3.new(-5220.38, 40911.31, -3660.60), -- 26
    Vector3.new(-5258.96, 40910.55, -3636.96), -- 27
    Vector3.new(-5312.98, 40911.09, -3599.50), -- 28 (ถึงรัง)
}

-- 🚶 บินตามลำดับจุดในตาราง · slowTail = ทำ 2 ช่วงสุดท้ายช้า (ตอนทะลุประตู)
local function flyPath(list, slowTail)
    local prev, ok, stuck = nil, true, 0
    for i = 1, #list do
        local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not h then ok = false break end
        local wp = list[i]
        local seg = prev and (wp - prev).Magnitude or 0
        local spd = 300
        if slowTail and i >= #list - 1 then
            spd = 90                                        -- ช่วงผ่านประตู : ทริกเกอร์ต้องยิงทัน
        elseif seg > 0 and seg < 40 then
            spd = 200
        elseif seg >= 90 then
            spd = 400
        end

        -- 🪂 กันค้าง : ให้บินได้สูงสุด 2.5 วิ/จุด (จากเดิม 10 วิ)
        volcFlyTo(wp, spd, 2.5)
        local h2 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if h2 and (wp - h2.Position).Magnitude > 6 then
            -- ยังไม่ถึงจุด → เทเลพอร์ตตามจุดเลย (ยังคง "ย้อนทางเดิม" เหมือนเดิม ไม่ใช่คนละเส้นทาง)
            stuck = stuck + 1
            teleportTo(CFrame.new(wp))
            task.wait(getNaturalDelay())
        end
        prev = wp
    end
    if stuck > 0 then logLine("[!] ไปไม่ถึง " .. stuck .. " จุด -> เทเลพอร์ตตามจุดแทน") end
    return ok
end

-- 🌋 ขาเข้า : วาร์ป 1 -> วาร์ป 2 -> ลอยลง 3 -> ทะลุประตู 4 -> เช็คบัฟ -> บินลงรัง
local function volcEnterTunnel()
    local h0 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not h0 then return false end

    for i = 1, 2 do
        local g = VOLC_GATE[i]
        teleportTo(CFrame.lookAt(g[1], g[1] + g[2]))
        task.wait(getNaturalDelay())
    end

    volcFlyTo(VOLC_GATE[3][1], 260)   -- ลอยลงมา
    volcFlyTo(VOLC_GATE[4][1], 90)    -- ลอยเข้าลึก = ทะลุประตู (ช้า กันข้าม slab บาง)

    -- 💥 สำรอง : ประตูโหลดมาแล้ว (เราอยู่ห่างแค่ 50 กว่าสตั๊ด) → ยิง touch ซ้ำอีกที
    pcall(function()
        local volc = workspace:FindFirstChild("Volcano")
        local door = volc and volc:FindFirstChild("VolcanoEntrance", true)
        local hh = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if door and hh and door:IsA("BasePart") and firetouchinterest then
            firetouchinterest(hh, door, 0)
            firetouchinterest(hh, door, 1)
            logLine("[🚪] ยิง touch ประตูซ้ำแล้ว")
        end
    end)

    -- 🔥 บัฟ Scorching = เกมยอมรับว่าเราอยู่ในภูเขาไฟแล้ว → ค่อยบินลงรัง
    local okBuff = false
    for _ = 1, 12 do
        if hasScorching() then okBuff = true break end
        task.wait(0.5)
    end
    if not okBuff then
        logLine("[X] ทะลุประตูแล้วแต่บัฟ Scorching ยังไม่ขึ้น")
        return false
    end
    logLine("[🔥] ได้บัฟ Scorching - บินลงรัง " .. #VOLC_DOWN .. " จุด")
    return flyPath(VOLC_DOWN, false)
end

-- 🚪 ขาออก : ย้อน 28 จุด -> 4 -> 3 (หยุดที่จุดกลับออก แล้วเข้าระบบลาวา)
local function volcExitTunnel()
    local rev = {}
    for i = #VOLC_DOWN, 1, -1 do rev[#rev + 1] = VOLC_DOWN[i] end
    rev[#rev + 1] = VOLC_GATE[4][1]   -- ทะลุประตูออก (ช้า)
    rev[#rev + 1] = VOLC_GATE[3][1]   -- ถึงจุดกลับออก
    return flyPath(rev, true)
end

-- ⛔ ต่อจากนี้ findVolcanoDoor / logVolcanoStructure / runLairDoorTour / LAIR_EXIT_WP / runLairRoute
--    ไม่ถูกเรียกแล้ว — เก็บไว้เป็นแผนสำรอง (เส้นทางด้านบนใช้แทนทั้งหมด)

-- 🚪 หาประตูถ้ำ — หาแบบพาธตายตัวอย่างเดียวไม่ได้ (ของเดิมล้มเหลว "ไม่พบ VolcanoEntrance")
--    จึงไล่ 3 ระดับ : แบบของเดิม → ค้นทั้งแมพลึกทุกชั้น → จับชื่อเพี้ยน
--    รองรับ Model/Folder ที่ครอบ Part อยู่ + รอ streaming โหลดเสร็จ
local function findVolcanoDoor(fuzzy)
    local function asPart(o)
        if not o then return nil end
        if o:IsA("BasePart") then return o end
        if o:IsA("Model") or o:IsA("Folder") then
            return o:FindFirstChildWhichIsA("BasePart", true)
        end
        return nil
    end

    -- ① แบบของเดิม : Workspace.Volcano.VolcanoEntrance (ค้นลึกเผื่อซ้อนชั้น)
    local volc = workspace:FindFirstChild("Volcano")
    local d = volc and asPart(volc:FindFirstChild("VolcanoEntrance", true))
    if d then return d end

    -- ② ค้นทั้งแมพ ลึกทุกชั้น
    d = asPart(workspace:FindFirstChild("VolcanoEntrance", true))
    if d then return d end

    if not fuzzy then return nil end

    -- ③ ชื่อเพี้ยน : "entrance" ทั้งแมพ หรือ "door"/"gate" ที่อยู่ใต้ Volcano
    --    (ของเดิมล้มเหลวไปแล้ว → ยิงกว้างหน่อย ดีกว่าจบมือเปล่า)
    for _, o in ipairs(workspace:GetDescendants()) do
        local n = string.lower(o.Name)
        local hit = string.find(n, "entrance", 1, true) ~= nil
        if not hit and (string.find(n, "door", 1, true) or string.find(n, "gate", 1, true)) then
            hit = volc ~= nil and o:IsDescendantOf(volc)
        end
        if hit then
            local p = asPart(o)
            if p then return p end
        end
    end
    return nil
end

-- 📋 พิมพ์โครงสร้างจริง 2 บรรทัด — ใช้ตอนหาไม่เจอ เพื่อจะได้รู้ว่าประตูมันอยู่ตรงไหน
local function logVolcanoStructure()
    -- บรรทัด 1 : Volcano มีลูกอะไร / ถ้าไม่มี → โมเดลไหนใกล้เคียง
    local volc = workspace:FindFirstChild("Volcano")
    if volc then
        local kids = {}
        for _, o in ipairs(volc:GetChildren()) do
            table.insert(kids, o.Name)
            if #kids >= 5 then break end
        end
        logLine("[?] Volcano ลูก: " .. (#kids > 0 and table.concat(kids, ", ") or "ไม่มีเลย"))
    else
        local names = {}
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("Model") or o:IsA("Folder") then
                local n = string.lower(o.Name)
                if string.find(n, "volc", 1, true) or string.find(n, "lair", 1, true)
                    or string.find(n, "cave", 1, true) or string.find(n, "mountain", 1, true) then
                    table.insert(names, o.Name)
                    if #names >= 5 then break end
                end
            end
        end
        logLine("[?] ไม่มี Workspace.Volcano - ใกล้เคียง: "
            .. (#names > 0 and table.concat(names, ", ") or "ไม่มี"))
    end

    -- บรรทัด 2 : path เต็มของ instance แรกที่ชื่อมี entrance/door/gate (ตัดให้ไม่ยาวเกิน)
    local hit = nil
    for _, o in ipairs(workspace:GetDescendants()) do
        local n = string.lower(o.Name)
        if string.find(n, "entrance", 1, true) or string.find(n, "door", 1, true)
            or string.find(n, "gate", 1, true) then
            hit = o:GetFullName()
            break
        end
    end
    if hit then
        if #hit > 78 then hit = string.sub(hit, 1, 78) .. "..." end
        logLine("[?] พบชื่อ entrance/door: " .. hit)
    else
        logLine("[?] ไม่มี instance ชื่อมี entrance/door/gate เลย")
    end
end

-- 🚪 ทัวร์ประตู : วาร์ปหน้าถ้ำ → ลอยขึ้นระดับประตู → ทะลุเข้า → รอจนบัฟขึ้น
--    (ลองฝั่ง -Z / +Z / -Z รวม 3 รอบ แบบของเดิม) — noclip คุมโดยผู้เรียก
local function runLairDoorTour()
    -- ⏳ รอ streaming สักครู่ก่อนสรุปว่าไม่มี (เจอเร็วก็ออกก่อน ไม่เสียเวลา)
    local doorPart = nil
    for try = 1, 6 do
        doorPart = findVolcanoDoor(false) -- แบบเร็ว (ไม่สแกนทั้งแมพ)
        if doorPart then break end
        task.wait(0.5)
    end
    if not doorPart then doorPart = findVolcanoDoor(true) end -- แบบชื่อเพี้ยน (สแกนทั้งแมพ)

    if not doorPart then
        logLine("[X] ไม่พบ VolcanoEntrance")
        -- 🔒 diagnostic ต้องไม่พลาด — ถ้าพังจะไม่มีทางรู้โครงสร้างจริงเลย
        local okDiag, diagErr = pcall(logVolcanoStructure)
        if not okDiag then
            logLine("[?] อ่านโครงสร้างไม่ได้")
            warn("[EGG] diag error: " .. tostring(diagErr))
        end
        return false
    end
    logLine("[🚪] ประตู: " .. doorPart:GetFullName())
    local doorCF = doorPart.CFrame

    for doorTry = 1, 3 do
        if hasScorching() then return true end
        local outSign = (doorTry == 2) and 1 or -1

        local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not h then return false end

        -- 🏔️ วาร์ปลง "พื้นดินโคนเขา" ก่อน (raycast) แล้วลอยขึ้นสู่ระดับประตู
        local basePoint = (doorCF * CFrame.new(0, 0, 40 * outSign)).Position
        local ray = workspace:Raycast(basePoint + Vector3.new(0, 400, 0), Vector3.new(0, -800, 0))
        if ray then
            h.CFrame = CFrame.new(ray.Position + Vector3.new(0, 4, 0))
        else
            h.CFrame = doorCF * CFrame.new(0, -3, 40 * outSign)
        end
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.1)

        volcFlyTo((doorCF * CFrame.new(0, 0, 30 * outSign)).Position, 150) -- ลอยขึ้นสูงระดับประตู
        volcFlyTo((doorCF * CFrame.new(0, 0, 6 * outSign)).Position, 100)  -- ถึงหน้าประตู
        volcFlyTo(doorCF.Position, 90)                                     -- ทะลุกลางประตูช้า ๆ
        pcall(function()
            local hh = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hh and firetouchinterest then
                firetouchinterest(hh, doorPart, 0)
                firetouchinterest(hh, doorPart, 1)
            end
        end)
        volcFlyTo((doorCF * CFrame.new(0, 5, 45 * -outSign)).Position, 90)  -- ลอยเข้าลึกในถ้ำ

        -- ⏳ รอบัฟ 1.5 วิ — ล็อคตำแหน่งไว้กันตกทะลุพื้น (noclip เปิดอยู่)
        local h0 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local holdCF = h0 and h0.CFrame
        local t0 = os.clock()
        while os.clock() - t0 < 1.5 do
            local hh = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if hh and holdCF then
                hh.CFrame = holdCF
                hh.AssemblyLinearVelocity = Vector3.zero
                hh.AssemblyAngularVelocity = Vector3.zero
            end
            if hasScorching() then return true end
            task.wait(0.1)
        end
    end
    if hasScorching() then return true end
    logLine("[X] ทะลุประตูครบ 3 รอบแล้ว - บัฟ Scorching ยังไม่ขึ้น")
    return false
end

-- 🚀 เดินเส้นทางถ้ำ dir = 1 (ออก 1→32) / dir = -1 (เข้า จุดใกล้สุด→1)
local function runLairRoute(dir)
    local hrp0 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp0 then return false end

    local seq = {}
    if dir == 1 then
        for i = 1, #LAIR_EXIT_WP do seq[#seq + 1] = i end
    else
        -- เริ่มจากจุดที่ใกล้ตำแหน่งปัจจุบันที่สุด (เราเพิ่งทะลุประตูเข้ามา)
        -- ไม่รวมจุด 32 (ฝั่งนอกประตู) กันบินย้อนออกไปก่อนแล้วค่อยเข้าใหม่
        local startI, bestD = #LAIR_EXIT_WP - 1, math.huge
        for i = 1, #LAIR_EXIT_WP - 1 do
            local d = (LAIR_EXIT_WP[i] - hrp0.Position).Magnitude
            if d < bestD then startI, bestD = i, d end
        end
        for i = startI, 1, -1 do seq[#seq + 1] = i end
    end

    local prevI, ok = nil, true
    for _, i in ipairs(seq) do
        local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not h then ok = false break end
        local wp = LAIR_EXIT_WP[i]
        local prevWp = prevI and LAIR_EXIT_WP[prevI]
        local segLen = prevWp and (wp - prevWp).Magnitude or 0

        -- 🚀 ตามทางจริงทุกจุด (ไม่ลัดโค้ง) — ปรับเลขได้ตรงนี้
        local spd = 300
        if i >= #LAIR_EXIT_WP - 2 then spd = 110          -- ปากประตู/ทะลุออก: ช้า (ทริกเกอร์ต้องยิงทัน)
        elseif segLen > 0 and segLen < 40 then spd = 200   -- โค้งถี่
        elseif segLen >= 90 then spd = 400 end             -- ทางตรงยาว

        volcFlyTo(wp, spd)
        prevI = i
    end
    return ok
end

-- 🌋 ขาเข้าทั้งรอบ : วาร์ปตามเส้นทางบันทึก -> ทะลุประตู -> ได้บัฟ -> บินลงรัง -> ถึงไข่
local function lairGoToEgg(targetPart)
    local stopClipLair = startNoClip() -- noclip + จำค่าเดิม คืนตอนจบ
    local ok = false
    pcall(function()
        logLine("[🚪] วาร์ปตามเส้นทาง Volcanic -> ทะลุประตู")
        if not volcEnterTunnel() then
            logLine("[X] เข้าถ้ำไม่สำเร็จ - ดูล็อกบรรทัดบน")
            return
        end

        -- กระชับไปที่ตัวไข่ ถ้ายังห่างเกินไป
        local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if h and targetPart and targetPart.Parent then
            if (targetPart.Position - h.Position).Magnitude > 8 then
                volcFlyTo(targetPart.Position + Vector3.new(0, 3, 0), 200)
            end
        end
        ok = true
    end)
    stopClipLair()
    return ok
end

-- ✈️ เก็บไว้เผื่ออยากเปลี่ยนกลับเป็นบิน (ตอนนี้ไม่ได้เรียก — ใช้วาร์ปแทน)
local function flyTo(targetPos, speed, maxTime)
    speed = speed or CFG.FLY_SPEED
    maxTime = maxTime or 25
    local stopClip = startNoClip()
    local startT, lastStep = os.clock(), os.clock()
    while os.clock() - startT < maxTime do
        local char = player.Character
        local h = char and char:FindFirstChild("HumanoidRootPart")
        if not h then break end
        local diff = targetPos - h.Position
        local dist = diff.Magnitude
        if dist <= CFG.ARRIVE then break end
        local now = os.clock()
        local dt = math.clamp(now - lastStep, 0.005, 0.1)
        lastStep = now
        local spd = speed
        if dist < 40 then spd = math.clamp(speed * (dist / 40), 40, speed) end
        local step = math.min(dist, spd * dt)
        h.CFrame = CFrame.new(h.Position + diff.Unit * step)
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
        RunService.Heartbeat:Wait()
    end
    stopClip()
end

-- 📐 จุด "ยืนข้างไข่" ทั้งชุด — ไข่ตัวใหญ่ต้องยืน "นอก" ตัวไข่
--    ไม่งั้นโดน hitbox ดันออก → เก็บไม่ติด (ใช้ร่วมกัน: ฟาร์มจริง + ปุ่มเทส)
local function eggStandOffsets(part)
    local eggRadius = 2.0
    pcall(function()
        local s = part.Size
        if s and s.Magnitude > 0 then eggRadius = math.max(s.X, s.Z) * 0.5 end
    end)
    local off = math.min(eggRadius + 2.5, 8.0)
    return {
        Vector3.new(off, 2.0, 0), Vector3.new(-off, 2.0, 0),
        Vector3.new(0, 2.0, off), Vector3.new(0, 2.0, -off),
        Vector3.new(2.0, 1.5, 0),
        Vector3.new(0, math.min(eggRadius + 3.0, 10.0), 0),
    }
end

-- 🥚 ไข่ที่ถืออยู่ในมือตอนนี้ (Tool หรือ Model ที่ชื่อมี "egg") — ไม่มี = nil
local function heldEggName()
    local char = player.Character
    if not char then return nil end
    for _, v in ipairs(char:GetChildren()) do
        if (v:IsA("Tool") or v:IsA("Model"))
            and string.find(string.lower(v.Name), "egg", 1, true) then
            return v.Name
        end
    end
    return nil
end

-- 🧺 เอาไข่ที่ค้างอยู่ "กลับไปวางที่แปลง" ก่อน — กันวาปไปเก็บใบถัดไปทั้งที่ยังถือ
--    (เป็นที่มาของบัค "ถือไข่แล้ววาปไปเก็บใบอื่น" + error "Can't Teleport While Carrying Eggs")
--    คืน true = มือว่างแล้ว / false = ยังค้างอยู่
local function placeHeldEgg(reason)
    local held = heldEggName()
    if not held then return true end

    logLine("[!] ยังถือ " .. held .. " ค้าง -> " .. reason)

    -- 🏠 ต้องมีพิกัดแปลงก่อน — ไม่งั้นวางมั่วแล้วไม่ติด
    if not homeCFrame then
        local okCF, cf = pcall(getPlotCFrame)
        if okCF and cf then homeCFrame = cf end
    end
    if not homeCFrame then
        logLine("[X] หาแปลงไม่เจอ - ยังวางไม่ได้")
        return false
    end

    setStatus("กลับแปลงวาง " .. held, C.Amber)
    teleportTo(homeCFrame)
    task.wait(0.3)

    for try = 1, 3 do
        pcall(function()
            if basketDropRemote then basketDropRemote:FireServer() end
            if eggPlacedRemote then eggPlacedRemote:FireServer() end
        end)
        task.wait(0.4)
        forceBareHands()
        if not heldEggName() then
            logLine("[OK] วาง " .. held .. " แล้ว (รอบ " .. try .. ")")
            return true
        end
    end

    logLine("[X] วาง " .. held .. " ไม่สำเร็จ - ยังค้างอยู่")
    return false
end

-- 🥚 หนึ่งรอบเก็บ : ไป → เก็บ → ตรวจเข้ามือ → กลับแปลง → วาง
local function grabAndReturn(egg)
    if isGrabbing then return false end
    if not egg or not egg.Parent then return false end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local targetPart = eggPart(egg)
    if not targetPart then return false end

    local eggName = egg.Name
    isGrabbing = true
    setStatus("กำลังไปเก็บ " .. eggName, C.Accent)

    -- จุดยืนข้างไข่ : อิง ProximityPrompt ถ้ามี (จุดที่เกมให้กดเก็บจริง)
    local interactPart = targetPart
    pcall(function()
        local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and prompt.Parent then
            local pp = prompt.Parent
            if pp:IsA("BasePart") then interactPart = pp
            elseif pp:IsA("Attachment") and pp.Parent and pp.Parent:IsA("BasePart") then
                interactPart = pp.Parent
            end
        end
    end)

    -- จุดยืนข้างไข่ (eggStandOffsets) — แยกเป็นฟังก์ชันของตัวเอง เผื่อใช้ซ้ำภายหลัง
    local stands = eggStandOffsets(interactPart)

    local beforeCount, beforeInHand = countOwnedEggs(eggName)

    -- 🌋 แยกทาง : Volcanic ต้องเข้าถ้ำ (ทัวร์ประตู → ได้บัฟ → บินเข้าตามเส้นทางออก "กลับด้าน")
    --    ไข่ปกติ = วาร์ปไปหาไข่ตรง ๆ เหมือนเดิม
    local isVolc = string.find(string.lower(eggName), "volcanic", 1, true) ~= nil

    if isVolc then
        local h0v = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local dToV = h0v and math.floor((interactPart.Position - h0v.Position).Magnitude) or 0
        if not lairGoToEgg(targetPart) then
            isGrabbing = false
            setStatus("เข้าถ้ำไม่สำเร็จ : " .. eggName, C.Red)
            logLine("[X] เข้าถ้ำ Volcanic ไม่สำเร็จ (ไม่ขึ้นบัฟ Scorching)")
            return false
        end
        logLine("[>] เข้าถ้ำถึง " .. eggName .. " (ทางดำตรง ๆ เดิม " .. dToV .. " studs)")
    else
        -- ⚡ วาร์ปไปหาไข่ทันที (มือเปล่า — ยังไม่ถืออะไร)
        do
            local h0 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local dTo = h0 and math.floor((interactPart.Position - h0.Position).Magnitude) or 0
            local base0 = interactPart.Position
            local sp0 = base0 + stands[1]
            local okTP = teleportTo(CFrame.lookAt(sp0, Vector3.new(base0.X, sp0.Y, base0.Z)))
            task.wait(0.2)
            logLine("[>] วาร์ปไป " .. eggName .. " (" .. dTo .. " studs)"
                .. (okTP and "" or " ล้มเหลว"))
        end
    end

    -- ⏳ พยายามเก็บให้ได้ภายในเวลาที่กำหนด
    local stopClip = startNoClip()
    local candIdx, attempt = 1, 0
    local startT = os.clock()
    local got = false

    local function standAtEgg()
        local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local base = interactPart.Parent and interactPart.Position or targetPart.Position
        local sp = base + stands[candIdx]
        h.CFrame = CFrame.lookAt(sp, Vector3.new(base.X, sp.Y, base.Z))
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
    end
    standAtEgg()

    while os.clock() - startT < CFG.GRAB_TIME do
        local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not h then break end
        hrp = h
        if egg and egg.Parent then
            attempt = attempt + 1
            standAtEgg()
            -- หมุนจุดยืนรอบไข่ทุก ๆ 6 ครั้ง หาจุดที่เก็บติด
            if attempt % 6 == 0 then candIdx = (candIdx % #stands) + 1 end

            pcall(function()
                if eggPickupRemote then eggPickupRemote:FireServer(egg) end
                local prompt = egg:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    prompt.HoldDuration = 0
                    prompt.MaxActivationDistance = math.huge
                    if fireproximityprompt then fireproximityprompt(prompt) end
                end
                local cd = egg:FindFirstChildWhichIsA("ClickDetector", true)
                if cd and fireclickdetector then fireclickdetector(cd) end
                if firetouchinterest and hrp then
                    firetouchinterest(hrp, interactPart, 0)
                    firetouchinterest(hrp, interactPart, 1)
                end
            end)
        end

        local nowCount, nowInHand = countOwnedEggs(eggName)
        if nowCount > beforeCount or (nowInHand and not beforeInHand) then
            got = true
            break
        end
        -- 🔒 เผื่อชื่อ Tool ไม่ตรงชื่อไข่เป๊ะ → ถ้ามีอะไรที่ชื่อมี "egg" ติดมืออยู่ = ได้แล้ว
        --    (มือว่างตั้งแต่ก่อนเข้าลูป → ที่เจอตอนนี้คือใบที่เพิ่งเก็บแน่นอน)
        --    ✅ สำคัญ : ไม่ทำตรงนี้ = got ไม่เคยเป็น true → return ไปวนลูปใหม่ → ยืนค้างในถ้ำ "ไม่บินออก"
        if heldEggName() then
            got = true
            logLine("[🔒] ตรวจพบไข่ในมือ -> ถือว่าเก็บได้")
            break
        end

        -- 🔎 ไข่หายจากแมพแล้ว → หยุดวนทันที (ไม่ยืนค้าง 15 วิ ที่ไข่ไม่มีอยู่)
        --    แล้วค่อยดูว่าเข้ามือเราจริงไหม — กันกรณีชื่อ Tool ไม่ตรงชื่อไข่
        --    ทำให้ countOwnedEggs นับจำนวนไม่ขึ้น ทั้งที่เก็บได้จริง
        local eggGone = (not egg or not egg.Parent or not isWildEgg(egg))
        if eggGone and (os.clock() - startT > 1.2) then
            ensureEggInHand(eggName)
            local c2, ih2 = countOwnedEggs(eggName)
            if c2 > beforeCount or (ih2 and not beforeInHand) or heldEggName() then got = true end
            break
        end
        task.wait(0.08)
    end

    -- ⏱️ เก็บได้ → ออกถ้ำ "ภายใน 1.5 วิ" (ตรวจ ≤0.08 + ยืนยัน 0.4 + บล็อกออก = ~0.5-1 วิ)
    --    ห้ามช้า เพราะมังกรจะตีระหว่างยืนยันอยู่ในถ้ำ
    if got then
        logLine("[⏱️] เก็บได้แล้ว -> ออกถ้ำ ภายใน 1.5 วิ")
        local confirmT = os.clock()
        while os.clock() - confirmT < 0.4 do
            ensureEggInHand(eggName)
            local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if h then
                h.AssemblyLinearVelocity = Vector3.zero
                h.AssemblyAngularVelocity = Vector3.zero
            end
            task.wait(0.05)
        end
    end
    stopClip()

    -- 🚪 ตามคำสั่ง : "เก็บตามระบบเสร็จแล้ว บินออกเลย" — ห้ามยืนค้างรอผลตรวจอีก
    --    (เดิม ตรวจไม่เจอ → return false → ลูปฟาร์มบินกลับเข้าถ้ำใหม่ = ไม่บินออกตลอดกาล)
    if not got then
        logLine("[!] ระบบเก็บหมดเวลา " .. CFG.GRAB_TIME .. " วิ -> ยังออกถ้ำ/กลับแปลงตามระบบต่อ")
    end

    -- 🚪 Volcanic : ย้อน "เส้นทางเข้า" กลับออก (28 จุด กลับด้าน → 4 → 3) — ไข่ปกติข้ามข้อนี้
    --    ถึงจุดกลับออกแล้วค่อยตัดสินใจ : ลาวาปิด → วาร์ปกลับบ้านเหมือนไข่ปกติ / ลาวาเปิด → ไต่ 1→4
    if isVolc then
        setStatus("ย้อนออกจากถ้ำ : " .. eggName, C.Amber)
        logLine("[🚪] เริ่มย้อนออก " .. (#VOLC_DOWN + 2) .. " จุด")
        local tExit = os.clock()
        local stopExit = startNoClip()
        local okExit = volcExitTunnel()
        if not okExit then
            logLine("[!] ย้อนออกไม่ครบ - ทำซ้ำ 1 รอบ")
            volcExitTunnel()
        end
        stopExit()
        logLine("[🚪] ถึงจุดกลับออกแล้ว (ใช้ "
            .. string.format("%.1f", os.clock() - tExit)
            .. " วิ) -> ระบบลาวา 1 -> 4")
    end

    -- 🌋 ดรอปลาวา "ทันที" หลังย้อนออกถ้ำ → แล้วค่อยวาร์ปกลับบ้าน
    --    · Volcanic = "ใช้เสมอ" (ห้ามลืม — เลี่ยงไม่ได้แล้วแมสวิตช์ 🌋 จะดับ)
    --    · ไข่ธรรมดา = ยังคงตามสวิตช์ 🌋 เหมือนเดิม
    --    ⚙️ ระบบข้างในเป็นของเดิมทั้งหมด (DIP_WP 1 -> 4 + นับ 10 วิ + กันข้อความปฏิเสธ)
    --       ไม่ได้เขียนใหม่ — แค่ "เรียก" ให้ถูกจังหวะ ต้องถือไข่อยู่ → ทำก่อนวาร์ปกลับบ้าน
    if isVolc or dipEnabled then
        setStatus("ดรอปลาวา : " .. eggName, C.Amber)
        logLine("[🌋] เข้าระบบลาวา 1 -> 4 ทันทีหลังย้อนออก")
        ensureEggInHand(eggName)
        runVolcanoDip()
        ensureEggInHand(eggName)
    else
        logLine("[🌋] ข้ามลาวา (ไม่ใช่ Volcanic + สวิตช์ 🌋 ปิด)")
    end

    -- ⚡ วาร์ปกลับบ้าน (ถือไข่อยู่) — ⛔ ไม่ยิง TeleportToPlot
    setStatus("กลับแปลงพร้อม " .. eggName, C.Amber)
    if not homeCFrame then -- เผื่อตอนกดเริ่มหาแปลงไม่เจอ
        local okH, cfH = pcall(getPlotCFrame)
        if okH and cfH then homeCFrame = cfH end
    end
    if homeCFrame then
        local h1 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local dHome = h1 and math.floor((homeCFrame.Position - h1.Position).Magnitude) or -1
        local okTP = teleportTo(homeCFrame)
        task.wait(0.2)
        -- ถ้าขึ้น "0 studs" = พิกัดบ้านผิด (ชี้ไปที่เดียวกับที่ยืนอยู่)
        logLine("[>] กลับแปลง " .. dHome .. " studs" .. (okTP and "" or " ล้มเหลว"))
    else
        logLine("[X] ไม่มีพิกัดบ้าน - ข้ามการกลับ")
    end

    -- 🧺 วางไข่ — มีแค่ 2 ตัวนี้  ⛔ ห้ามเติม TeleportToPlot
    pcall(function()
        if basketDropRemote then basketDropRemote:FireServer() end
        if eggPlacedRemote then eggPlacedRemote:FireServer() end
    end)
    task.wait(0.1)

    -- ✋ บังคับถือมือเปล่า (วนตรวจจนกว่าตัวละครจะว่างจริง)
    local bare = forceBareHands()
    if not bare then
        -- 🔁 วางไม่ติด → ยิง remote วางซ้ำอีก 1 รอบ ก่อนยอมปล่อย
        --    (ปล่อยทั้งที่ยังถือ = ลูปฟาร์มจะวาปไปเก็บใบถัดไปทันที)
        logLine("[!] วางไม่ติด -> ยิงซ้ำ 1 รอบ")
        pcall(function()
            if basketDropRemote then basketDropRemote:FireServer() end
            if eggPlacedRemote then eggPlacedRemote:FireServer() end
        end)
        task.wait(0.4)
        bare = forceBareHands()
    end
    -- ⏸️ ยืนนิ่งที่แปลงอีก 2 วิ ค่อยปล่อยไปวาร์ปเก็บไข่รอบถัดไป
    task.wait(2)

    isGrabbing = false
    setStatus("วาง " .. eggName .. " แล้ว", C.Green)
    logLine("[OK] เก็บ + วาง " .. eggName
        .. (bare and " · มือเปล่าแล้ว" or " · ยังค้าง → ลูปกลับแปลงวางเอง"))
    pcall(bumpCollected)   -- 🧮 อัปตัวนับ "เก็บแล้ว" ที่ footer
    return true
end

-- ============================================================
-- 👀 โหมด "ดูไข่" : โคลนโมเดลไข่มาวางข้างหน้าตัวเรา
--    • Clone = ของจริงไม่ขยับเลย / ขนาดเท่าที่ดรอปจริงเป๊ะ (ไม่ย่อ ไม่ขยาย)
--    • เทียบกับตัวเราด้วย "ตา" แล้วคนเป็นคนตัดสินใจเอง (จะเอาหรือไม่เอา กดเอง)
--    • กด ⚡ เริ่มฟาร์ม = ยกเลิกการดึงโมเดล (ลบโคลนทิ้ง)
-- ============================================================
local previewClone = nil   -- โคลนที่วางอยู่ตอนนี้ (nil = ไม่ได้เปิดดู)

local PREVIEW_TEXT   = "👀"                            -- ปุ่มเป็นไอคอนในแถบปุ่มใหม่
local PREVIEW_COLOR  = Color3.fromRGB(168, 85, 247)   -- 🟣 ปิดอยู่

-- ยกเลิก/ลบทิ้งโคลนที่วางอยู่ — เรียกได้แม้ไม่มีโคลน (ไม่ฟ้อง)
local function clearPreview(why)
    if not previewClone then return end
    pcall(function() previewClone:Destroy() end)
    previewClone = nil
    previewBtn.Text = PREVIEW_TEXT
    previewBtn.BackgroundColor3 = PREVIEW_COLOR
    logLine("[👀] ยกเลิกการดูไข่" .. (why and (" - " .. why) or ""))
end

local function showEggPreview()
    if previewClone then              -- กดซ้ำ = สลับปิด
        clearPreview("กดซ้ำ")
        return
    end

    -- 🎯 เอาใบที่ "ฟาร์มจะไปเก็บ" — ยังไม่ได้ติ๊กไข่ก็ใช้ใบแรกที่เจอในแมพ
    local target = scanQueue()
    if not target then
        for _, arr in pairs(scanAll()) do
            if arr and #arr > 0 then target = arr[1]; break end
        end
    end
    if not target then
        setStatus("ยังไม่มีไข่เกิดในแมพ", C.Red)
        logLine("[👀] ยังไม่มีไข่ในแมพ - ดึงโมเดลไม่ได้")
        return
    end

    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then logLine("[X] หาตัวละครไม่เจอ"); return end

    -- 🔁 Clone → ของจริงไม่ขยับ / ไม่กระทบเกมเลย
    local okC, clone = pcall(function() return target:Clone() end)
    if not okC or not clone then
        logLine("[X] โคลนโมเดล " .. target.Name .. " ไม่ได้")
        return
    end
    clone.Name = "EGG_PREVIEW"        -- กันระบบสแกนไปนับโคลนเป็นไข่จริง

    local okB, boxCF, boxSize = pcall(function() return clone:GetBoundingBox() end)
    if not okB or not boxCF or not boxSize then
        logLine("[X] " .. target.Name .. " วัดขนาดไม่ได้ (ไม่มี Parts)")
        pcall(function() clone:Destroy() end)
        return
    end

    -- 📏 พื้นจริงใต้เท้า (ray ลง) — ล้มเหลวก็ใช้ระดับเท้า
    local groundY = hrp.Position.Y - 3
    local okR, hit = pcall(function()
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { char, clone }
        return workspace:Raycast(hrp.Position + Vector3.new(0, 10, 0),
                                 Vector3.new(0, -300, 0), params)
    end)
    if okR and hit then groundY = hit.Position.Y end

    -- 📐 วางข้างหน้า 6 studs + วางฐานแตะพื้น
    --    PivotTo = ย้ายทั้งโมเดล → ขนาด "ไม่เปลี่ยน" ตามที่ขอ
    local front = hrp.Position + hrp.CFrame.LookVector * 6
    local newCenter = Vector3.new(front.X, groundY + boxSize.Y / 2, front.Z)
    pcall(function()
        clone:PivotTo(boxCF + (newCenter - boxCF.Position))
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BasePart") then
                d.Anchored = true        -- ยืนนิ่ง (แตะเฉพาะ physics ไม่แตะขนาด)
                d.CanCollide = false     -- กันเดินชนแล้วติด
            end
        end
    end)
    clone.Parent = workspace
    previewClone = clone

    previewBtn.BackgroundColor3 = C.Amber   -- 🟠 เปิดอยู่ (กดอีกครั้งหรือกด ⚡ = ยกเลิก)

    -- 📏 รายงานสัดส่วนเทียบตัวเรา (หน่วย stud) — แต่ "ตา" เป็นคนตัดสินขั้นสุดท้าย
    local myH = 5
    pcall(function() myH = char:GetExtentsSize().Y end)
    if myH <= 0 then myH = 5 end
    local ratio = boxSize.Y / myH
    logLine("[👀] โคลน " .. target.Name .. " วางข้างหน้าแล้ว (กด ⚡ เพื่อยกเลิก)")
    logLine("     ไข่ " .. string.format("%.1f", boxSize.Y) .. " st / เรา "
        .. string.format("%.1f", myH) .. " st = " .. string.format("%.2f", ratio) .. " เท่า")
    setStatus(string.format("ดูไข่ : %.2f เท่าของตัวเรา", ratio), C.Amber)
end

previewBtn.Activated:Connect(function()
    local ok, err = pcall(showEggPreview)
    if not ok then logLine("[ERR] ดูไข่ : " .. tostring(err)) end
end)

-- ============================================================
-- ส่วนที่ 4 : ลูปฟาร์ม + ปุ่ม
-- ============================================================
local noTargetLogAt = 0
local shieldLogged = false
local lastPlaceAt = 0   -- ⏱️ กันยิง "กลับแปลงวาง" ถี่เกินไป
local holdLogAt   = 0   -- ⏱️ กันล็อก "ยังถือไข่ค้าง" รัว
local onceNoTargetAt = 0   -- ⏱️ โหมด "ใบเดียว" : เริ่มจับเวลาตอนไม่มีไข่เหลือ
local ONCE_END_WAIT  = 6    -- วิ ที่ไม่พบไข่เลย = "เก็บหมดในแมพแล้ว" → หยุดเอง

-- ⏹️ หยุดฟาร์ม — ใช้ทั้งกดปุ่ม และกรณี "ฟาร์มใบเดียวเสร็จแล้วหยุดเอง"
local function stopFarming(why)
    if not isFarming then return end
    isFarming = false
    startBtn.Text = "⚡ เริ่มฟาร์ม"
    startBtn.BackgroundColor3 = C.Green
    setDot(false)
    setStatus(why or "หยุดอยู่", why and C.Amber or C.Sub)
    logLine("[||] " .. (why or "หยุดฟาร์ม"))
    task.spawn(forceBareHands)
end

task.spawn(function()
    while true do
        task.wait(CFG.LOOP_WAIT)
        if isFarming and #selectedEggs > 0 then
            local target = scanQueue()
            if target then
                noTargetLogAt = 0
                onceNoTargetAt = 0
                if not isGrabbing then
                    -- 🥚 ยังถือไข่ค้างอยู่? → กลับแปลงวางก่อน "ห้ามวาปไปเก็บใบถัดไป"
                    --    (เป็นที่มาของบัค ถือไข่แล้ววาปทันที + error Can't Teleport While Carrying Eggs)
                    if heldEggName() and os.clock() - lastPlaceAt > 6 then
                        lastPlaceAt = os.clock()
                        placeHeldEgg("ก่อนไปเก็บใบถัดไป")
                    end

                    if heldEggName() then
                        -- ยังวางไม่ได้ → ข้ามรอบนี้ ไม่วาป
                        if os.clock() - holdLogAt > 6 then
                            holdLogAt = os.clock()
                            local h = heldEggName() or "?"
                            setStatus("วาง " .. h .. " ไม่ได้ - รอ", C.Red)
                            logLine("[!] ยังถือ " .. h .. " ค้าง -> ข้ามรอบ ไม่วาปไปเก็บใบถัดไป")
                        end
                    else
                        -- 🔒 กัน "ค้าง" : ถ้า grabAndReturn มี error ต้องปลด isGrabbing เสมอ
                        --    (ไม่งั้นลูปฟาร์มจะหยุดเรียกถาวร → ยืนทิ้งไว้ตรงไข่ ไม่กลับบ้าน)
                        local ok, err = pcall(grabAndReturn, target)
                        isGrabbing = false
                        if not ok then
                            setStatus("ผิดพลาด", C.Red)
                            logLine("[ERR] " .. tostring(err))
                        end
                    end
                end
            else
                -- 🎯 โหมด "ใบเดียว" : ไม่พบไข่เหลือในแมพ → ฟาร์มเสร็จแล้ว "หยุดเอง"
                --    (โหมดออโต้ = ไม่หยุด รอไข่เกิดใหม่ไปเรื่อย ๆ)
                if not isGrabbing and not hasAutoMode() then
                    if onceNoTargetAt == 0 then
                        onceNoTargetAt = os.clock()
                    elseif os.clock() - onceNoTargetAt > ONCE_END_WAIT then
                        onceNoTargetAt = 0
                        stopFarming("ฟาร์มครบแล้ว - ไม่มี " .. (selectedEggs[1] or "ไข่") .. " เหลือในแมพ")
                    end
                end

                if os.clock() - noTargetLogAt > 20 then
                    noTargetLogAt = os.clock()
                    setStatus("รอไข่เกิด ...", C.Amber)
                    logLine("[-] ยังไม่มีไข่ที่เลือกอยู่ในแมพ")
                    unequipAll()
                end
            end
        else
            noTargetLogAt = 0
            onceNoTargetAt = 0
        end
    end
end)

-- 🖼️ ดูด "ที่อยู่รูป" จากโมเดลไข่ที่ลอยอยู่ในแมพ (Decal / Texture / Mesh / ParticleEmitter)
--    ใช้เติมรูปให้ไข่ที่ไม่มี asset ในตาราง : Admin, Volcanic, Dragon, Giant, Bloom, Tidal, DevilFruit
local function eggTextureOf(obj)
    if not obj then return nil end
    local ok, url = pcall(function()
        local function scan(root)
            if not root then return nil end
            if root:IsA("MeshPart") and root.TextureID ~= "" then return root.TextureID end
            for _, d in ipairs(root:GetDescendants()) do
                local t = nil
                if d:IsA("Decal") or d:IsA("Texture") or d:IsA("ParticleEmitter") then
                    t = d.Texture
                elseif d:IsA("SpecialMesh") or d:IsA("FileMesh") then
                    t = d.TextureId
                elseif d:IsA("MeshPart") then
                    t = d.TextureID
                end
                if t and t ~= "" then return t end
            end
            return nil
        end
        return scan(obj) or scan(obj.Parent) or scan(obj.Parent and obj.Parent.Parent)
    end)
    if not ok or not url or url == "" then return nil end
    url = tostring(url)
    if not string.find(url, "://", 1, true) then
        local digits = string.gsub(url, "%D", "")
        if digits == "" then return nil end
        url = "rbxassetid://" .. digits
    end
    return url
end

-- ============================================================
-- 👁️ ESP ไข่ : กล่องสีตามความหายาก + ป้ายชื่อ/ระยะ เหนือไข่ทุกใบในแมพ
--    ⚠️ กติกาตามคำสั่ง : "ใช้ได้เฉพาะระบบ คลิกเลือกไข่แบบปกติ (ใบเดียว)"
--       ถ้ามีไข่ที่ตั้งด้วยการ "กดค้าง 3 วิ = ออโต้ฟาร์ม" → ESP ปิดตัวเองทันที
--    · Highlight อยู่ใน folder ของ workspace (Adornee = โมเดลไข่) → เห็นทะลุกำแพง
--    · BillboardGui เป็น "ลูกของโมเดลไข่" → ถูกล้างอัตโนมัติตอนไข่หาย/ถูกเก็บ
--    · สร้าง/ลบ = ใช้ผลสแกนรอบ 1.2 วิ (ไม่เรียก scanAll ซ้ำ → ไม่เปลืองเพิ่ม)
--    · ข้อความระยะ + 🎯 = อัปเดตทุก 0.5 วิ (เขียนแค่ Text ไม่สแกนแมพ)
-- ============================================================
local espFolderName = "EGG_ESP_LITE"
local espOld = workspace:FindFirstChild(espFolderName)
if espOld then espOld:Destroy() end                 -- กันซ้อนเมื่อรันสคริปต์ซ้ำ
local espFolder = Instance.new("Folder", workspace)
espFolder.Name = espFolderName

local espNodes      = {}     -- [egg] = {hl, bb, nameLbl, distLbl, short, rarity, eggName, sel, txt}
local espLast       = nil     -- ผลสแกนล่าสุดจากลูป 🌤️ (เก็บไว้ใช้ ไม่สแกนซ้ำ)
local espGate       = nil     -- สถานะก่อนหน้า → ใช้ log เมื่อสลับเปิด/ปิด
local espErrLogged  = false
local espCount      = -1      -- จำนวนจุดรอบก่อนหน้า (log เมื่อเปลี่ยนค่า)
local espWarned     = false
local espT0         = os.clock()

-- 🧹 เก็บกวาด ESP ของครั้งก่อน (รันสคริปต์ซ้ำ = ห้ามมีกล่อง/ป้ายค้างในแมพ)
pcall(function()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d.Name == "EspBox" or d.Name == "EspTag" then d:Destroy() end
    end
end)
logLine("[👁️] ระบบ ESP โหลดแล้ว - รอลูป 0.5 วิ")

-- เปิดเฉพาะ "ใบเดียว" — มีไข่ที่เป็นออโต้ (กดค้าง) = ปิด
local function espWanted()
    return not hasAutoMode()
end

local function espPos(egg)
    local p = eggPart(egg)
    if p then return p.Position end
    if egg:IsA("Model") then return egg:GetPivot().Position end
    if egg:IsA("BasePart") then return egg.Position end
    return nil
end

local function espCreate(row, egg)
    local rarity, short, fullName = row[2], row[4], row[1]
    local col = RARITY_COLOR[rarity] or C.Sub

    local hl = Instance.new("Highlight")
    hl.Name = "EspBox"
    hl.Adornee = egg
    hl.FillColor = col
    hl.FillTransparency = 0.45          -- ให้เห็นชัด (เดิม 0.72 จางจนแยกไม่ออก)
    hl.OutlineColor = col
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = espFolder

    local bb = Instance.new("BillboardGui")
    bb.Name = "EspTag"
    bb.Size = UDim2.new(0, 132, 0, 30)
    bb.StudsOffset = UDim2.new(0, 0, 3.4, 0)
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.MaxDistance = 1000000          -- ไม่ตัดระยะ (เห็นข้ามแผนที่)
    bb.ResetOnSpawn = false

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, 0, 0, 15)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextColor3 = col
    nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLbl.TextStrokeTransparency = 0.35
    nameLbl.Text = (FALLBACK_GLYPH[rarity] or "🥚") .. " " .. short
    nameLbl.Parent = bb

    local distLbl = Instance.new("TextLabel")
    distLbl.Size = UDim2.new(1, 0, 0, 14)
    distLbl.Position = UDim2.new(0, 0, 0, 14)
    distLbl.BackgroundTransparency = 1
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 10
    distLbl.TextColor3 = Color3.fromRGB(235, 240, 255)
    distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    distLbl.TextStrokeTransparency = 0.5
    distLbl.Text = "..."
    distLbl.Parent = bb

    bb.Parent = egg        -- ผูกกับโมเดลไข่ → ถูกล้างอัตโนมัติตอนไข่หาย

    espNodes[egg] = {
        hl = hl, bb = bb, nameLbl = nameLbl, distLbl = distLbl,
        short = short, rarity = rarity, eggName = fullName,
        sel = false, txt = nil,
    }
end

local function espDestroy(egg)
    local node = espNodes[egg]
    if not node then return end
    if node.hl then node.hl:Destroy() end
    if node.bb then node.bb:Destroy() end
    espNodes[egg] = nil
end

local function espClear()
    for egg in pairs(espNodes) do espDestroy(egg) end
end

-- ซิงก์ชุด ESP ให้ตรงกับผลสแกน (สร้างของใหม่ / ลบของที่หายจากแมพ)
local function espSync(byName)
    if not byName then return end
    local seen = {}
    for _, row in ipairs(EGG_DATA) do
        local arr = byName[row[1]]
        if arr then
            for i = 1, #arr do
                local egg = arr[i]
                if egg and egg.Parent then
                    seen[egg] = true
                    if not espNodes[egg] then espCreate(row, egg) end
                end
            end
        end
    end
    for egg in pairs(espNodes) do
        if not seen[egg] then espDestroy(egg) end   -- หายจากแมพ / ถูกเก็บไปแล้ว
    end
end

-- อัปเดตป้ายระยะทาง + 🎯 ไข่ที่เลือก (เขียนเฉพาะตอนค่าเปลี่ยน)
local function espTick()
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local sel = {}
    for i = 1, #selectedEggs do sel[selectedEggs[i]] = true end

    for egg, node in pairs(espNodes) do
        if node.bb and node.bb.Parent then
            local pos = espPos(egg)
            if pos then
                local d = math.floor((pos - hrp.Position).Magnitude + 0.5)
                if node.txt ~= d then
                    node.txt = d
                    node.distLbl.Text = d .. " studs"
                end
            end
            local isSel = sel[node.eggName] == true
            if isSel ~= node.sel then
                node.sel = isSel
                node.nameLbl.Text = (isSel and "🎯 " or "")
                    .. (FALLBACK_GLYPH[node.rarity] or "🥚") .. " " .. node.short
                node.hl.FillTransparency = isSel and 0.2 or 0.45
            end
        end
    end
end

-- 🔁 ลูป ESP : ทุก 0.5 วิ — เปิด/ปิดตามโหมดเลือก, ซิงก์จากผลสแกน, อัปเดตป้าย
task.spawn(function()
    while true do
        task.wait(0.5)
        if not sg.Parent then                -- ปิดหน้าต่างแล้ว = เก็บกวาด ESP ทิ้ง
            espClear()
            espFolder:Destroy()
            break
        end
        local on = espWanted()
        if on ~= espGate then
            espGate = on
            logLine(on and "[👁️] ESP ไข่ เปิด (โหมดใบเดียว)"
                or "[👁️] ESP ไข่ ปิด (กดค้างออโต้ฟาร์ม)")
        end
        if on then
            -- 🆘 ถ้าลูปสแกนหลักยังไม่ส่งผลมา (เพิ่งโหลด / พัง) → เองสแกนเอง ไม่พึ่งใคร
            if not espLast and os.clock() - espT0 > 2 then
                local okF, resF = pcall(scanAll)
                if okF and resF then espLast = resF end
            end
            if espLast then
                local okS, errS = pcall(espSync, espLast)
                if not okS and not espErrLogged then
                    espErrLogged = true
                    logLine("[X] ESP ผิดพลาด : " .. tostring(errS))
                end
            end
            pcall(espTick)

            -- 📊 รายงานจำนวนจุดที่สร้างได้ — ใช้ฟันธงว่าติดที่ "สร้าง" หรือที่ "แสดงผล"
            local n = 0
            for _ in pairs(espNodes) do n = n + 1 end
            if n ~= espCount then
                espCount = n
                if n > 0 then logLine("[👁️] ESP สร้าง " .. n .. " จุดบนจอ") end
            end
            if n == 0 and not espWarned and os.clock() - espT0 > 5 then
                espWarned = true
                logLine("[!] ESP สร้างไม่ได้เลย - ผลสแกน"
                    .. (espLast and " มี แต่ไม่พบไข่ในนั้น" or " ยังไม่มา"))
            end
        else
            espClear()
        end
    end
end)

-- 🌤️ บอกว่า "ไข่ตัวไหนเกิดอยู่ในแมพตอนนี้" อัปเดตทุก 1.2 วิ
--    · จุดเหลืองมุมซ้ายบนของรูปไข่ = มีอยู่จริงตอนนี้
--    · บรรทัดใต้ตาราง = สรุปรายชื่อ + จำนวนฟอง
--    ⚠️ ไม่เขียน Label ตรง ๆ — เขียนลง U.* แล้วรอ applyUI() วาดทุกเฟรม
task.spawn(function()
    while true do
        task.wait(1.2)
        if not sg.Parent then break end -- ปิดหน้าต่างแล้วหยุด
        -- 🛡️ รายงานครั้งแรกที่ระบบกันตัด remote อันตรายได้
        if not shieldLogged and blockedRemotesCount > 0 then
            shieldLogged = true
            logLine("[SHIELD] ตัด remote อันตราย " .. blockedRemotesCount .. " ครั้ง")
        end
        local ok, byName = pcall(scanAll)
        if ok and byName then
            espLast = byName                  -- 👁️ เก็บไว้ให้ระบบ ESP (ไม่เรียก scanAll ซ้ำ)
            local parts, shown, total, types = {}, 0, 0, 0
            for _, row in ipairs(EGG_DATA) do
                local nm, short = row[1], row[4]
                local arr = byName[nm]
                local t = tileByEgg[nm]
                local alive = (arr and #arr > 0) and true or false
                if t then
                    t.spawnNow = alive            -- 🟡 จุดมุมซ้ายบน (applyUI วาดทุกเฟรม)

                    -- 🖼️ ยังไม่มีรูป → ลองดูดจากโมเดลในแมพ (ลองสูงสุด 8 รอบ เผื่อ streaming ยังไม่โหลด)
                    if alive and not t.hasImg and t.tries < 8 then
                        t.tries = t.tries + 1
                        local u = eggTextureOf(arr[1])
                        if u then
                            t.hasImg = true
                            t.img.Image = u
                            t.img.Visible = true
                            t.fb.Visible = false
                            logLine("[🖼️] ได้รูป " .. short .. " จากโมเดลในแมพ")
                        elseif t.tries >= 8 then
                            logLine("[!] " .. short .. " หาไม่เจอ -> ใช้ไอคอนสำรอง")
                        end
                    end
                end
                if alive then
                    total = total + #arr
                    types = types + 1
                    if shown < 5 then
                        table.insert(parts, short .. " x" .. #arr)
                        shown = shown + 1
                    end
                end
            end
            if total == 0 then
                U.spawn = "ยังไม่มีไข่เกิดอยู่ในแมพ"
                U.spawnColor = C.Muted
            else
                local extra = (types > shown) and (" +" .. (types - shown) .. " ชนิด") or ""
                U.spawn = "ในแมพ " .. total .. " ฟอง : " .. table.concat(parts, ", ") .. extra
                U.spawnColor = C.Amber
            end
        end
    end
end)

startBtn.Activated:Connect(function()
    -- 👀 ยกเลิกโหมดดูไข่ — กด ⚡ ปุ๊บ = หยุดการดึงโมเดล (ตามคำสั่ง)
    clearPreview("กด ⚡")

    if isFarming then
        stopFarming()               -- ⏹️ ใช้ฟังก์ชันเดียวกับ "ฟาร์มใบเดียวเสร็จแล้วหยุดเอง"
        return
    end

    if #selectedEggs == 0 then
        setStatus("ยังไม่ได้เลือกไข่", C.Red)
        logLine("[X] แตะเลือกไข่ก่อนกดเริ่ม (กดค้าง 3 วิ = โหมดออโต้)")
        return
    end

    -- 🏠 หาแปลงตอนกดเริ่มครั้งเดียว (จำไว้ใช้ทุกรอบ)
    local okCF, cf = pcall(getPlotCFrame)
    if okCF and cf then
        homeCFrame = cf
        logLine("[OK] ตรวจพบแปลงของผู้เล่นแล้ว")
    else
        local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        homeCFrame = h and h.CFrame or nil
        logLine("[!] หาแปลงไม่เจอ - ใช้ตำแหน่งปัจจุบันแทน")
    end

    isFarming = true
    onceNoTargetAt = 0
    startBtn.Text = "⏹ หยุดฟาร์ม"
    startBtn.BackgroundColor3 = C.Red
    setDot(true)
    setStatus("กำลังฟาร์ม ...", C.Green)
    if hasAutoMode() then
        logLine("[>] เริ่มฟาร์ม ออโต้ ∞ - " .. #selectedEggs .. " ไข่ในคิว (ไม่หยุดเอง)")
    else
        logLine("[>] เริ่มฟาร์ม ใบเดียว - " .. (selectedEggs[1] or "?")
            .. " (เก็บหมดในแมพแล้วหยุดเอง)")
    end
end)

-- 🌋 สวิตช์เปิด/ปิดดรอปลาวา (ปุ่มไอคอน — สีเขียว = เปิด)
dipBtn.Activated:Connect(function()
    dipEnabled = not dipEnabled
    if dipEnabled then
        dipBtn.BackgroundColor3 = C.Green
        logLine("[🌋] เปิดดรอปลาวา - จะไต่ 1->4 ก่อนกลับแปลง")
        setStatus("ลาวา : เปิด", C.Amber)
    else
        dipBtn.BackgroundColor3 = Color3.fromRGB(107, 114, 128)
        logLine("[🌋] ปิดดรอปลาวา - เก็บแล้วกลับแปลงเลย")
        setStatus("ลาวา : ปิด")
    end
end)

-- 🔁 รีจอย — ระบบเดิมจาก VIP.txt (คัดมาใช้ตามคำสั่งผู้ใช้)
--    ⛔ ไม่ใช้ SetTeleportGui อีก → ตัวนี้ทำให้ติด error 773 "เทเลพอร์ตไม่สำเร็จ"
rejoinBtn.Activated:Connect(function()
    local placeId, jobId = game.PlaceId, game.JobId

    isFarming = false
    startBtn.Text = "⚡ เริ่มฟาร์ม"
    startBtn.BackgroundColor3 = C.Green
    setDot(false)
    clearPreview("รีจอย")

    local total = #Players:GetPlayers()
    rejoinBtn.Text = "⏳ รีจอย"
    setStatus("กำลังรีจอย ...", C.Amber)
    logLine("[🔁] รีจอย (" .. total .. " คนในห้อง)")

    -- 🙈 ปิด UI เราไม่ให้กะพริบระหว่างย้าย
    pcall(function() sg.Enabled = false end)

    -- ของเดิม: อยู่คนเดียว (≤1) → ออกแล้วเข้าห้องใหม่ / มีคนอื่น → เข้าห้องเดิม (JobId เดิม)
    if total <= 1 then
        pcall(function()
            game:GetService("TeleportService"):Teleport(placeId, player)
        end)
    else
        pcall(function()
            game:GetService("TeleportService"):TeleportToPlaceInstance(placeId, jobId, player)
        end)
    end

    -- ถ้ายังอยู่ที่เดิมหลัง 4 วิ = ย้ายไม่สำเร็จ → เปิด UI กลับ
    task.wait(4)
    if player.Parent then
        pcall(function() sg.Enabled = true end)
        rejoinBtn.Text = "🔁 รีจอย"
        setStatus("รีจอยไม่สำเร็จ", C.Red)
        logLine("[X] รีจอยไม่สำเร็จ - ลองใหม่")
    end
end)

-- ย่อ / ปิด
local fullH = H            -- minimized ประกาศไว้ตอนสร้างหน้าต่างแล้ว
minBtn.Activated:Connect(function()
    minimized = not minimized
    minBtn.Text = minimized and "+" or "—"
    TweenService:Create(win, TweenInfo.new(0.18), {
        Size = UDim2.new(0, W, 0, minimized and 32 or fullH),
    }):Play()
end)
closeBtn.Activated:Connect(function()
    isFarming = false
    sg:Destroy()
end)

-- ลากหน้าต่าง
do
    local dragging, dragStart, startPos
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, win.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            clampPos()   -- 📱 กันลากหน้าต่างออกนอกจอ (มือถือ/จอน้อย)
        end
    end)
end

-- ⏩ พยายามข้ามหน้าโหลดของเกม (PlayerGui.Loading มี "ClickToSkipReminder" = คลิกเพื่อข้าม)
--    ปิดซ้ำ ๆ ตลอด 25 วิแรกหลังเข้าเกม — ถ้าเกมฝืนเปิดกลับเอง ถือว่า "ข้ามไม่ได้" แล้วปล่อยผ่าน
task.spawn(function()
    pcall(function()
        local tEnd = os.clock() + 25
        local logged = false
        while os.clock() < tEnd do
            local pg = player:FindFirstChild("PlayerGui")
            local lg = pg and pg:FindFirstChild("Loading")
            if lg and lg:IsA("ScreenGui") then
                if lg.Enabled then lg.Enabled = false end
                if not logged then
                    logged = true
                    logLine("[⏩] ข้ามหน้าโหลดแล้ว")
                end
            end
            task.wait(0.4)
        end
    end)
end)

-- 🎬 ตัดคัทซีนกล้องหมุน หลังเข้าเกม / รีจอย — ยึดกล้องคืนจากคัทซีนให้เอง
--    ทำงานเฉพาะ 25 วิแรก ถ้าไม่มีคัทซีนคุมกล้องอยู่ก็ไม่ทำอะไรเลย (ไม่กระทบการเล่นปกติ)
task.spawn(function()
    pcall(function()
        local tEnd = os.clock() + 25
        local conn, lastCheck = nil, 0
        conn = game:GetService("RunService").RenderStepped:Connect(function()
            local now = os.clock()
            if now > tEnd then
                conn:Disconnect()
                return
            end
            -- ⚡ ตรวจอีกทุบ 0.25 วิ (เดิม = ทุกเฟรม 60 ครั้ง/วิ) คัทซีนจับได้ทันใน 0.25 วิ เท่ากัน
            if now - lastCheck < 0.25 then return end
            lastCheck = now
            pcall(function()
                local cam = workspace.CurrentCamera
                local char = player.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if not (cam and hum) then return end
                if cam.CameraType == Enum.CameraType.Scriptable or cam.CameraSubject ~= hum then
                    cam.CameraType = Enum.CameraType.Custom
                    cam.CameraSubject = hum
                    -- คืนการควบคุมตัวละคร (คัทซีนมักกด disable ไว้)
                    local ps = player:FindFirstChild("PlayerScripts")
                    local pm = ps and ps:FindFirstChild("PlayerModule")
                    if pm then
                        local m = require(pm)
                        local c = m and m.GetControls and m:GetControls()
                        if c and c.Enable then c:Enable() end
                    end
                end
            end)
        end)
    end)
end)

logLine(CFG.SHIELD and "[OK] ระบบกันเปิดแล้ว - บล็อก Ban/Kick/Analytics/FPS"
    or "[!] ระบบกันปิดอยู่ (CFG.SHIELD = false) - ไว้เช็กสาเหตุแอปหลุด")
logLine("[OK] EGG LITE พร้อม - คลิกเลือกไข่แล้วกดเริ่มฟาร์ม")
print("[EGG LITE] loaded - 32 eggs / teleport mode / no TeleportToPlot")
