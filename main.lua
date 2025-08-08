local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

--// Tạo GUI
local gui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
gui.Name = "NPC_ESP_GUI"
gui.ResetOnSpawn = false

-- Nút thu gọn
local toggleButton = Instance.new("TextButton", gui)
toggleButton.Position = UDim2.new(0, 10, 0.25, 0)
toggleButton.Size = UDim2.new(0, 150, 0, 35)
toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 18
toggleButton.Text = "📦 ESP Pro - Hiện Menu"
toggleButton.ZIndex = 2

-- Frame chính
local mainFrame = Instance.new("Frame", gui)
mainFrame.Position = UDim2.new(0, 10, 0.3, 0)
mainFrame.Size = UDim2.new(0, 250, 0, 400)
mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ZIndex = 2

-- Scrollable list
local scrollingFrame = Instance.new("ScrollingFrame", mainFrame)
scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.BackgroundTransparency = 1
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.ZIndex = 2

local layout = Instance.new("UIListLayout", scrollingFrame)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 5)

-- Danh sách NPC
local npcNames = {
    "Noobini Pizzanini", "Lirili Larila", "Tim Cheese", "FluriFlura", "Talpa Di Fero", "Svinina Bombardino",
    "Pipi Kiwi", "Trippi Troppi", "Tung Tung Tung Sahur", "Gangster Footera", "Bandito Bobritto",
    "Boneca Ambalabu", "Cacto Hipopotamo", "Ta Ta Ta Ta Sahur", "Tric Trac Baraboom",
    "Cappuccino Assassino", "Brr Brr Patapim", "Trulimero Trulicina", "Bambini Crostini", "Bananita Dolphinita",
    "Perochello Lemonchello", "Brri Brri Bicus Dicus Bombicus", "Avocadini Guffo", "Salamino Penguino",
    "Burbaloni Loliloli", "Chimpazini Bananini", "Ballerina Cappuccina", "Chef Crabracadabra",
    "Lionel Cactuseli", "Glorbo Fruttodrillo", "Blueberrini Octopusini", "Strawberelli Flamingelli",
    "Pandaccini Bananini", "Frigo Camelo", "Orangutini Ananassini", "Rhino Toasterino", "Bombardiro Crocodilo",
    "Bombombini Gusini", "Cavallo Virtuso", "Gorillo Watermelondrillo", "Spioniro Golubiro",
    "Zibra Zubra Zibralini", "Tigrilini Watermelini", "Cocofanto Elefanto", "Girafa Celestre",
    "Gattatino Nyanino", "Matteo", "Tralalero Tralala", "Espresso Signora", "Odin Din Din Dun",
    "Statutino Libertino", "Trenostruzzo Turbo 3000", "Ballerino Lololo", "Trigoligre Frutonni",
    "Orcalero Orcala", "Los Crocodillitos", "Piccione Macchina", "La Vacca Staturno Saturnita",
    "Chimpanzini Spiderini", "Los Tralaleritos", "Las Tralaleritas", "Graipuss Medussi",
    "La Grande Combinasion", "Nuclearo Dinossauro", "Garama and Madundung",
    "Tortuginni Dragonfruitini", "Pot Hotspot", "Las Vaquitas Saturnitas", "Chicleteira Bicicleteira"
}

local selectedNPCs = {}
local npcButtons = {}

for _, name in ipairs(npcNames) do
    selectedNPCs[name] = false
    local toggle = Instance.new("TextButton", scrollingFrame)
    toggle.Size = UDim2.new(1, -10, 0, 25)
    toggle.Text = "❌ " .. name
    toggle.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    toggle.TextColor3 = Color3.new(1, 1, 1)
    toggle.Font = Enum.Font.SourceSansBold
    toggle.TextSize = 18
    toggle.ZIndex = 2

    npcButtons[name] = toggle

    toggle.MouseButton1Click:Connect(function()
        selectedNPCs[name] = not selectedNPCs[name]
        toggle.Text = (selectedNPCs[name] and "✅ " or "❌ ") .. name
        checkSelectedNPCs()
    end)
end

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

toggleButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = not mainFrame.Visible
    toggleButton.Text = "📦 ESP Pro - " .. (mainFrame.Visible and "Ẩn Menu" or "Hiện Menu")
    
    if not mainFrame.Visible then
        toggleESP(false) -- Tắt ESP khi ẩn GUI
    else
        checkSelectedNPCs() -- Bật lại nếu có NPC đang chọn
    end
end)

-- ESP logic
local rainbowCache = {}
local espCache = {}
local lastUpdate = 0
local UPDATE_INTERVAL = 0.1
local heartbeatConnection = nil

local function getRainbowColor(speed)
    local t = tick() * (speed or 1)
    return Color3.fromHSV((t % 5) / 5, 1, 1)
end

local function clearAllESP()
    for model in pairs(espCache) do
        local esp = model:FindFirstChild("ESP_Name")
        if esp then
            esp:Destroy()
        end
    end
    table.clear(espCache)
    table.clear(rainbowCache)
end

local function createESP(model)
    if not espCache[model] then
        local head = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
        if head then
            local billboard = Instance.new("BillboardGui", model)
            billboard.Name = "ESP_Name"
            billboard.Size = UDim2.new(0, 200, 0, 50)
            billboard.AlwaysOnTop = true
            billboard.Adornee = head
            billboard.MaxDistance = 500

            local label = Instance.new("TextLabel", billboard)
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextScaled = true
            label.Font = Enum.Font.FredokaOne
            label.Text = model.Name
            label.TextColor3 = getRainbowColor()
            label.TextStrokeTransparency = 0.3

            rainbowCache[billboard] = label
            espCache[model] = true
        end
    end
end

local function updateRainbowColors()
    local currentTime = tick()
    if currentTime - lastUpdate < UPDATE_INTERVAL then return end
    lastUpdate = currentTime

    local rainbowColor = getRainbowColor(2)
    for _, label in pairs(rainbowCache) do
        label.TextColor3 = rainbowColor
    end
end

local function toggleESP(enabled)
    if enabled then
        if heartbeatConnection then return end
        heartbeatConnection = RunService.Heartbeat:Connect(function()
            for _, model in ipairs(workspace:GetDescendants()) do
                if model:IsA("Model") and selectedNPCs[model.Name] then
                    createESP(model)
                end
            end
            updateRainbowColors()
        end)
    else
        if heartbeatConnection then
            heartbeatConnection:Disconnect()
            heartbeatConnection = nil
        end
        clearAllESP()
    end
end

function checkSelectedNPCs()
    local anySelected = false
    for _, selected in pairs(selectedNPCs) do
        if selected then
            anySelected = true
            break
        end
    end
    toggleESP(anySelected)
end
