-- Rayfield Interface Setup
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Interface/CustomFIeld/main/RayField.lua'))()

local Window = Rayfield:CreateWindow({
    Name = "Rayfield UI",
    LoadingTitle = "Rayfield Interface",
    LoadingSubtitle = "by Sirius",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = nil,
        FileName = "RayfieldConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

-- Tab setup
local MainTab = Window:CreateTab("Main")
local ESPTab = Window:CreateTab("ESP")
local VisualsTab = Window:CreateTab("Visuals")

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

-- Variables
local espEnabled = false
local espBoxes = {}
local espConnections = {}
local fovValue = 70
local fpsBoostEnabled = false

-- ESP System
local function createESP(player)
    if not player.Character then return end
    
    local character = player.Character
    local highlight = Instance.new("Highlight")
    highlight.Name = "RayfieldESP"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    
    espBoxes[player] = highlight
    
    -- Track character changes (respawning)
    local connection
    connection = player.CharacterAdded:Connect(function(newChar)
        if espBoxes[player] then
            espBoxes[player]:Destroy()
        end
        
        wait(1) -- Wait for character to fully load
        
        local newHighlight = Instance.new("Highlight")
        newHighlight.Name = "RayfieldESP"
        newHighlight.Adornee = newChar
        newHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        newHighlight.FillColor = Color3.new(1, 1, 1)
        newHighlight.FillTransparency = 0.5
        newHighlight.OutlineColor = Color3.new(1, 1, 1)
        newHighlight.OutlineTransparency = 0
        newHighlight.Parent = newChar
        
        espBoxes[player] = newHighlight
    end)
    
    espConnections[player] = connection
end

local function removeESP(player)
    if espBoxes[player] then
        espBoxes[player]:Destroy()
        espBoxes[player] = nil
    end
    if espConnections[player] then
        espConnections[player]:Disconnect()
        espConnections[player] = nil
    end
end

local function toggleESP(state)
    espEnabled = state
    
    if state then
        -- Add ESP to existing players
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer then
                createESP(player)
            end
        end
        
        -- Listen for new players
        espConnections.newPlayer = Players.PlayerAdded:Connect(function(player)
            createESP(player)
        end)
    else
        -- Remove ESP from all players
        for _, player in ipairs(Players:GetPlayers()) do
            removeESP(player)
        end
        
        -- Clean up connections
        if espConnections.newPlayer then
            espConnections.newPlayer:Disconnect()
            espConnections.newPlayer = nil
        end
    end
end

-- FOV Slider
local Camera = Workspace.CurrentCamera
MainTab:CreateSlider({
    Name = "FOV Slider",
    Range = {0, 120},
    Increment = 5,
    Suffix = "°",
    CurrentValue = 70,
    Flag = "FOVSlider",
    Callback = function(value)
        fovValue = value
        if Camera then
            Camera.FieldOfView = value
        end
    end,
})

-- FPS Boost Function
local function applyFPSBoost()
    if fpsBoostEnabled then return end
    
    fpsBoostEnabled = true
    
    -- Set Lighting to default values
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
    Lighting.Brightness = 2
    Lighting.OutdoorAmbient = Color3.new(0.5, 0.5, 0.5)
    
    -- Remove all lighting effects
    for _, instance in ipairs(Lighting:GetChildren()) do
        if instance:IsA("BloomEffect") or 
           instance:IsA("BlurEffect") or 
           instance:IsA("ColorCorrectionEffect") or
           instance:IsA("SunRaysEffect") or
           instance:IsA("Atmosphere") then
            instance:Destroy()
        end
    end
    
    -- Remove textures and decals from workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            -- Change material to SmoothPlastic
            obj.Material = Enum.Material.SmoothPlastic
            
            -- Remove decals/textures
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Decal") or child:IsA("Texture") then
                    child:Destroy()
                end
            end
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            -- Remove standalone decals/textures
            obj:Destroy()
        end
    end
    
    Rayfield:Notify({
        Title = "FPS Boost",
        Content = "FPS Boost has been applied!",
        Duration = 5,
        Image = 4483362458,
    })
end

local function revertFPSBoost()
    if not fpsBoostEnabled then return end
    
    fpsBoostEnabled = false
    
    -- Reset lighting to default
    Lighting.GlobalShadows = true
    Lighting.FogEnd = 1000000
    Lighting.Brightness = 1
    Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
    
    Rayfield:Notify({
        Title = "FPS Boost",
        Content = "Game needs to be rejoined to fully revert changes.",
        Duration = 5,
        Image = 4483362458,
    })
end

-- ESP Toggle
ESPTab:CreateToggle({
    Name = "ESP",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(value)
        toggleESP(value)
    end,
})

-- FPS Boost Toggle
VisualsTab:CreateToggle({
    Name = "FPS Boost",
    CurrentValue = false,
    Flag = "FPSBoostToggle",
    Callback = function(value)
        if value then
            applyFPSBoost()
        else
            revertFPSBoost()
        end
    end,
})

-- Watermark (Optional)
Rayfield:LoadConfiguration()

-- Cleanup when script is stopped
local function cleanup()
    toggleESP(false)
    if Camera and fovValue ~= 70 then
        Camera.FieldOfView = 70
    end
end

game:GetService("Players").LocalPlayer:GetPropertyChangedSignal("Parent"):Connect(function()
    if not Players.LocalPlayer.Parent then
        cleanup()
    end
end)
