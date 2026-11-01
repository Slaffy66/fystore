-- FY STORE LOADER (sistem key + masa berlaku)
local MAIN_URL = "https://raw.githubusercontent.com/Slaffy66/fystore/main/fystore.lua"
local KEYS_URL = "https://raw.githubusercontent.com/Slaffy66/fystore/main/keys.txt"
local SALT = "fyStore-Qm7xT2vLp9Ra4Zk"
local SAVE_FILE = "fystore_key.txt"

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function nowTime()
    local ok, t = pcall(function() return workspace:GetServerTimeNow() end)
    if ok and t then return math.floor(t) end
    return os.time()
end

local function fnv(str, seed)
    local h = seed
    for i = 1, #str do
        h = bit32.bxor(h, string.byte(str, i))
        h = (bit32.lshift(h, 24) + h * 403) % 4294967296
    end
    return h
end

local function hashKey(key)
    local s = SALT .. key
    return string.format("%08x%08x", fnv(s, 2166136261), fnv(s .. "#", 3735928559))
end

-- return: true, nil, sisaDetik (nil = lifetime)  |  false, pesan
local function checkKey(key)
    key = key:gsub("%s+", "")
    if key == "" then return false, "Key kosong" end
    local ok, body = pcall(function()
        return game:HttpGet(KEYS_URL .. "?t=" .. os.time())
    end)
    if not ok or type(body) ~= "string" then
        return false, "Gagal memuat daftar key"
    end
    local h = hashKey(key)
    for line in body:gmatch("[^\r\n]+") do
        local hh, exp = line:match("^%s*(%x+)%s*|?%s*([%d%-]*)")
        if hh and hh:lower() == h then
            if exp == "" or exp == "0" then
                return true, nil, nil -- lifetime
            end
            if exp:find("-") then -- format lama: tanggal
                if os.date("!%Y-%m-%d") > exp then
                    return false, "Key sudah kedaluwarsa"
                end
                return true, nil, nil
            end
            local expTs = tonumber(exp)
            if not expTs then return false, "Format key tidak valid" end
            local now = nowTime()
            if now > expTs then return false, "Key sudah kedaluwarsa" end
            return true, nil, expTs - now
        end
    end
    return false, "Key salah"
end

local function fmtRemaining(s)
    if not s then return "Lifetime" end
    local d = math.floor(s / 86400)
    local h = math.floor((s % 86400) / 3600)
    local m = math.floor((s % 3600) / 60)
    if d > 0 then return d .. " hari " .. h .. " jam" end
    if h > 0 then return h .. " jam " .. m .. " menit" end
    return m .. " menit"
end

local function runMain()
    local ok, err = pcall(function()
        loadstring(game:HttpGet(MAIN_URL))()
    end)
    if not ok then warn("FY STORE error: " .. tostring(err)) end
end

-- Key tersimpan: langsung jalan tanpa UI (jika masih berlaku)
if isfile and readfile and pcall(isfile, SAVE_FILE) and isfile(SAVE_FILE) then
    local saved = readfile(SAVE_FILE)
    if checkKey(saved) then
        runMain()
        return
    end
end

-- UI input key
local function getParent()
    local ok, ui = pcall(function() return gethui and gethui() end)
    if ok and ui then return ui end
    ok, ui = pcall(function() return game:GetService("CoreGui") end)
    if ok and ui then return ui end
    return player:WaitForChild("PlayerGui")
end

local parent = getParent()
local old = parent:FindFirstChild("FYKey")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "FYKey"
gui.ResetOnSpawn = false
if not pcall(function() gui.Parent = parent end) then
    gui.Parent = player:WaitForChild("PlayerGui")
end

local ACCENT = Color3.fromRGB(57, 255, 20)

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(250, 160)
frame.Position = UDim2.new(0.5, -125, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(7, 13, 8)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
local stroke = Instance.new("UIStroke")
stroke.Thickness = 1.5
stroke.Color = ACCENT
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "FY STORE | Masukkan Key"
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextColor3 = ACCENT
title.Parent = frame

local box = Instance.new("TextBox")
box.Position = UDim2.fromOffset(14, 40)
box.Size = UDim2.new(1, -28, 0, 34)
box.BackgroundColor3 = Color3.fromRGB(18, 28, 20)
box.BorderSizePixel = 0
box.PlaceholderText = "FY-X-XXXX-XXXX-XXXX"
box.PlaceholderColor3 = Color3.fromRGB(120, 130, 120)
box.Text = ""
box.ClearTextOnFocus = false
box.Font = Enum.Font.Gotham
box.TextSize = 14
box.TextColor3 = Color3.new(1, 1, 1)
box.Parent = frame
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

local btn = Instance.new("TextButton")
btn.Position = UDim2.fromOffset(14, 84)
btn.Size = UDim2.new(1, -28, 0, 34)
btn.BackgroundColor3 = ACCENT
btn.BorderSizePixel = 0
btn.Text = "Verifikasi"
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.TextColor3 = Color3.new(0, 0, 0)
btn.Parent = frame
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Position = UDim2.fromOffset(14, 124)
status.Size = UDim2.new(1, -28, 0, 24)
status.BackgroundTransparency = 1
status.Text = ""
status.Font = Enum.Font.Gotham
status.TextSize = 12
status.TextColor3 = Color3.fromRGB(255, 90, 110)
status.Parent = frame

local busy = false
btn.MouseButton1Click:Connect(function()
    if busy then return end
    busy = true
    status.TextColor3 = Color3.new(1, 1, 1)
    status.Text = "Memeriksa key..."
    local key = box.Text:gsub("%s+", "")
    local ok, msg, remaining = checkKey(key)
    if ok then
        if writefile then pcall(writefile, SAVE_FILE, key) end
        status.TextColor3 = ACCENT
        status.Text = "Berhasil! Sisa: " .. fmtRemaining(remaining)
        task.wait(1.2)
        gui:Destroy()
        runMain()
    else
        status.TextColor3 = Color3.fromRGB(255, 90, 110)
        status.Text = msg or "Key salah"
        busy = false
    end
end)
