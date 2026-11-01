-- FY STORE | FPS Boost, Anti Lag, Shadow Off, Only Day, FPS & Ping
-- Semua perubahan hanya lokal (di layarmu), dan bisa dikembalikan lewat toggle.

-- ====== PENGATURAN LOGO (isi salah satu) ======
local LOGO_ID = 0      -- contoh: 123456789 (ID gambar dari Roblox, paling stabil)
local LOGO_URL = "https://cdn.discordapp.com/attachments/1550813417315766292/1551215113573503068/BackgroundEraser_20260920_215203936.png?ex=6ae88827&is=6ae736a7&hm=3dfe80cf78bedef5866c30fc4245e10cfbc4790163387334c496957d62c8d1b8&"
-- ===============================================

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local Terrain = workspace:FindFirstChildOfClass("Terrain")

local palette = {
    {"Hijau neon", Color3.fromRGB(57, 255, 20)},
    {"Ungu", Color3.fromRGB(178, 102, 255)},
    {"Biru", Color3.fromRGB(30, 144, 255)},
    {"Merah", Color3.fromRGB(255, 59, 107)},
}
local colorIndex = 1
local accent = palette[1][2]
local OFF_COLOR = Color3.fromRGB(46, 58, 48)

------------------------------------------------------------
-- Fitur
------------------------------------------------------------
local function newFeature(def)
    local f = {on = false, conns = {}, token = 0}
    f.saved = setmetatable({}, {__mode = "k"})

    function f.set(inst, prop, val)
        local s = f.saved[inst]
        if not s then
            s = {}
            f.saved[inst] = s
        end
        if s[prop] == nil then
            local ok, old = pcall(function() return inst[prop] end)
            if not ok then return end
            s[prop] = old
        end
        pcall(function() inst[prop] = val end)
    end

    function f.enable()
        if f.on then return end
        f.on = true
        f.token += 1
        local my = f.token

        if def.global then pcall(def.global, f) end

        if def.inst then
            for _, root in ipairs({workspace, Lighting}) do
                table.insert(f.conns, root.DescendantAdded:Connect(function(v)
                    pcall(def.inst, f, v)
                end))
                task.spawn(function()
                    local n = 0
                    for _, v in ipairs(root:GetDescendants()) do
                        if f.token ~= my then return end
                        pcall(def.inst, f, v)
                        n += 1
                        if n % 300 == 0 then task.wait() end
                    end
                end)
            end
        end
    end

    function f.disable()
        if not f.on then return end
        f.on = false
        f.token += 1
        for _, c in ipairs(f.conns) do c:Disconnect() end
        f.conns = {}
        for inst, props in pairs(f.saved) do
            for p, v in pairs(props) do
                pcall(function() inst[p] = v end)
            end
        end
        f.saved = setmetatable({}, {__mode = "k"})
        if def.restore then pcall(def.restore, f) end
    end

    return f
end

local fpsBoost = newFeature({
    global = function(f)
        pcall(function()
            f.oldQuality = settings().Rendering.QualityLevel
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        f.set(Lighting, "FogEnd", 9e9)
        f.set(Lighting, "Brightness", 3)
        f.set(Lighting, "Ambient", Color3.fromRGB(190, 190, 190))
        f.set(Lighting, "OutdoorAmbient", Color3.fromRGB(190, 190, 190))
        if Terrain then
            f.set(Terrain, "WaterWaveSize", 0)
            f.set(Terrain, "WaterWaveSpeed", 0)
            f.set(Terrain, "WaterReflectance", 0)
        end
    end,
    inst = function(f, v)
        if v:IsA("BasePart") and not v:IsA("Terrain") then
            f.set(v, "Material", Enum.Material.SmoothPlastic)
            f.set(v, "Reflectance", 0)
        elseif v:IsA("PostEffect") then
            f.set(v, "Enabled", false)
        elseif v:IsA("Atmosphere") then
            f.set(v, "Density", 0)
        end
    end,
    restore = function(f)
        if f.oldQuality then
            settings().Rendering.QualityLevel = f.oldQuality
        end
    end,
})

local antiLag = newFeature({
    inst = function(f, v)
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam")
            or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
            f.set(v, "Enabled", false)
        end
    end,
})

local shadowOff = newFeature({
    global = function(f)
        f.set(Lighting, "GlobalShadows", false)
    end,
    inst = function(f, v)
        if v:IsA("BasePart") then
            f.set(v, "CastShadow", false)
        end
    end,
})

local DAY_TIME = 14
local onlyDay = newFeature({
    global = function(f)
        f.set(Lighting, "ClockTime", DAY_TIME)
        table.insert(f.conns, Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
            if math.abs(Lighting.ClockTime - DAY_TIME) > 0.01 then
                Lighting.ClockTime = DAY_TIME
            end
        end))
    end,
})

------------------------------------------------------------
-- GUI
------------------------------------------------------------
local function getParent()
    local ok, ui = pcall(function() return gethui and gethui() end)
    if ok and ui then return ui end
    ok, ui = pcall(function() return game:GetService("CoreGui") end)
    if ok and ui then return ui end
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local parent = getParent()
local old = parent:FindFirstChild("FYStore")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "FYStore"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
if not pcall(function() gui.Parent = parent end) then
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- Panel utama
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(230, 216)
frame.Position = UDim2.new(0.5, -115, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(7, 13, 8)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = accent
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -36, 0, 30)
title.BackgroundTransparency = 1
title.Text = "FY STORE"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = accent
title.Active = true
title.Parent = frame

-- Bulatan logo untuk membuka panel lagi
local bubble = Instance.new("TextButton")
bubble.Size = UDim2.fromOffset(64, 64)
bubble.Position = frame.Position
bubble.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
bubble.BorderSizePixel = 0
bubble.Text = "FY"
bubble.Font = Enum.Font.GothamBold
bubble.TextSize = 16
bubble.TextColor3 = accent
bubble.AutoButtonColor = false
bubble.ClipsDescendants = true
bubble.Visible = false
bubble.Active = true
bubble.Parent = gui
Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 14)
local bubbleStroke = Instance.new("UIStroke")
bubbleStroke.Thickness = 1.5
bubbleStroke.Color = accent
bubbleStroke.Parent = bubble

local logo = Instance.new("ImageLabel")
logo.Size = UDim2.new(1, -6, 1, -6)
logo.Position = UDim2.fromOffset(3, 3)
logo.BackgroundTransparency = 1
logo.ScaleType = Enum.ScaleType.Fit
logo.Visible = false
logo.Parent = bubble

local function download(url)
    local ok, data = pcall(function() return game:HttpGet(url) end)
    if ok and type(data) == "string" and #data > 0 then return data end
    local req = request or http_request or (syn and syn.request)
    if req then
        local ok2, res = pcall(function() return req({Url = url, Method = "GET"}) end)
        if ok2 and res and type(res.Body) == "string" and #res.Body > 0 then
            return res.Body
        end
    end
    return nil
end

local function resolveLogo()
    if LOGO_ID ~= 0 then
        return "rbxassetid://" .. tostring(LOGO_ID)
    end
    if LOGO_URL ~= "" and writefile and getcustomasset then
        local ok, res = pcall(function()
            local data = download(LOGO_URL)
            -- pastikan benar-benar file PNG (link kadaluarsa biasanya mengembalikan teks error)
            if not data or data:sub(2, 4) ~= "PNG" then return nil end
            writefile("fystore_logo.png", data)
            return getcustomasset("fystore_logo.png")
        end)
        if ok and res then return res end
    end
    return nil
end

task.spawn(function()
    local img = resolveLogo()
    if img then
        logo.Image = img
        logo.Visible = true
        bubble.Text = ""
    end
end)

-- Panel FPS & Ping
local statFrame = Instance.new("Frame")
statFrame.Size = UDim2.fromOffset(160, 26)
statFrame.Position = UDim2.new(0.5, -80, 0, 6)
statFrame.BackgroundColor3 = Color3.fromRGB(7, 13, 8)
statFrame.BorderSizePixel = 0
statFrame.Active = true
statFrame.Visible = false
statFrame.Parent = gui
Instance.new("UICorner", statFrame).CornerRadius = UDim.new(0, 8)
local statStroke = Instance.new("UIStroke")
statStroke.Thickness = 1.2
statStroke.Color = accent
statStroke.Parent = statFrame

local statLabel = Instance.new("TextLabel")
statLabel.Size = UDim2.fromScale(1, 1)
statLabel.BackgroundTransparency = 1
statLabel.Text = "FPS: -- | Ping: --"
statLabel.Font = Enum.Font.GothamBold
statLabel.TextSize = 12
statLabel.TextColor3 = accent
statLabel.Active = true
statLabel.Parent = statFrame

local function getPing()
    local ok, v = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and v then return math.floor(v + 0.5) end
    local ok2, p = pcall(function()
        return Players.LocalPlayer:GetNetworkPing() * 2000
    end)
    if ok2 and p then return math.floor(p + 0.5) end
    return 0
end

local statsFeature = {on = false}
local statConn

function statsFeature.enable()
    if statsFeature.on then return end
    statsFeature.on = true
    statFrame.Visible = true
    local frames, last = 0, os.clock()
    statConn = RunService.RenderStepped:Connect(function()
        frames += 1
        local now = os.clock()
        if now - last >= 0.5 then
            local fps = math.floor(frames / (now - last) + 0.5)
            frames = 0
            last = now
            statLabel.Text = string.format("FPS: %d | Ping: %d ms", fps, getPing())
        end
    end)
end

function statsFeature.disable()
    if not statsFeature.on then return end
    statsFeature.on = false
    statFrame.Visible = false
    if statConn then
        statConn:Disconnect()
        statConn = nil
    end
end

-- Baris toggle
local toggles = {}

local function refreshToggle(t)
    local on = t.feature.on
    t.track.BackgroundColor3 = on and accent or OFF_COLOR
    t.knob.Position = on and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2)
end

local function makeRow(text, y, feature)
    local label = Instance.new("TextLabel")
    label.Position = UDim2.fromOffset(14, y)
    label.Size = UDim2.fromOffset(130, 22)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local track = Instance.new("TextButton")
    track.Position = UDim2.new(1, -48, 0, y + 2)
    track.Size = UDim2.fromOffset(34, 18)
    track.Text = ""
    track.AutoButtonColor = false
    track.BorderSizePixel = 0
    track.Parent = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(14, 14)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = track
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local t = {feature = feature, track = track, knob = knob}
    table.insert(toggles, t)

    track.MouseButton1Click:Connect(function()
        if feature.on then feature.disable() else feature.enable() end
        refreshToggle(t)
    end)

    feature.enable()
    refreshToggle(t)
end

makeRow("FPS Boost", 36, fpsBoost)
makeRow("Anti Lag", 64, antiLag)
makeRow("Shadow Off", 92, shadowOff)
makeRow("Only Day", 120, onlyDay)
makeRow("FPS & Ping", 148, statsFeature)

-- Warna
local colorLabel = Instance.new("TextLabel")
colorLabel.Position = UDim2.fromOffset(14, 182)
colorLabel.Size = UDim2.fromOffset(70, 24)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "Warna:"
colorLabel.Font = Enum.Font.Gotham
colorLabel.TextSize = 13
colorLabel.TextColor3 = Color3.new(1, 1, 1)
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.Parent = frame

local colorBtn = Instance.new("TextButton")
colorBtn.Position = UDim2.new(1, -112, 0, 182)
colorBtn.Size = UDim2.fromOffset(98, 24)
colorBtn.BackgroundColor3 = Color3.fromRGB(18, 28, 20)
colorBtn.BorderSizePixel = 0
colorBtn.Text = palette[1][1]
colorBtn.Font = Enum.Font.Gotham
colorBtn.TextSize = 12
colorBtn.TextColor3 = Color3.new(1, 1, 1)
colorBtn.Parent = frame
Instance.new("UICorner", colorBtn).CornerRadius = UDim.new(0, 6)

colorBtn.MouseButton1Click:Connect(function()
    colorIndex = colorIndex % #palette + 1
    accent = palette[colorIndex][2]
    colorBtn.Text = palette[colorIndex][1]
    stroke.Color = accent
    title.TextColor3 = accent
    bubbleStroke.Color = accent
    bubble.TextColor3 = accent
    statStroke.Color = accent
    statLabel.TextColor3 = accent
    for _, t in ipairs(toggles) do refreshToggle(t) end
end)

-- Tombol tutup panel
local minBtn = Instance.new("TextButton")
minBtn.Position = UDim2.new(1, -34, 0, 3)
minBtn.Size = UDim2.fromOffset(28, 24)
minBtn.BackgroundColor3 = Color3.fromRGB(18, 28, 20)
minBtn.BorderSizePixel = 0
minBtn.Text = "-"
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Parent = frame
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

minBtn.MouseButton1Click:Connect(function()
    bubble.Position = frame.Position
    frame.Visible = false
    bubble.Visible = true
end)

------------------------------------------------------------
-- Geser panel / bulatan / panel FPS (tahan lalu geser)
------------------------------------------------------------
local function makeDraggable(handle, target, onTap)
    local dragging, dragStart, startPos, moved = false, nil, nil, false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if onTap and not moved then onTap() end
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            if d.Magnitude > 6 then moved = true end
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

makeDraggable(title, frame)
makeDraggable(statLabel, statFrame)
makeDraggable(bubble, bubble, function()
    frame.Position = bubble.Position
    bubble.Visible = false
    frame.Visible = true
end)
