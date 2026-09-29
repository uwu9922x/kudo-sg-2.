local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

--// Referências
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--// ===============================
--// 0. ANTI-KICK & ANTI-BAN SHIELD
--// ===============================
pcall(function()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        
        if self == player and (method:lower() == "kick" or method:lower() == "shutdown") then
            warn("🛡️ Anti-Kick Shield: Blocked a kick/ban attempt successfully!")
            return
        end
        
        return oldNamecall(self, ...)
    end)
end)

pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    
    local oldIndex = mt.__index
    mt.__index = newcclosure(function(self, k)
        if tostring(self) == "CoreGui" and (k == "GetChildren" or k == "FindFirstChild") then
            return {}
        end
        return oldIndex(self, k)
    end)
    setreadonly(mt, true)
end)

--// ===============================
--// 1. SPEED BOOST (PULO) CONFIG
--// ===============================
local function getHumanoid(char)
    return char:WaitForChild("Humanoid")
end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = getHumanoid(character)

local baseWalkSpeed = humanoid.WalkSpeed
local speedBoost = 224
local speedSistemaAtivo = false

--// ===============================
--// 2. IMPULSO (MOVIMENTO) CONFIG
--// ===============================
local boostPower = 55
local cooldown = 0
local lastTick = 0
local impulsoAtivo = true

--// ===============================
--// 3. DYNAMIC FLICK CONFIG (زر Z) - مفعل مسبقاً
--// ===============================
local flickEnabled = true

--// ===============================
--// 4. FIXED FLICK CONFIG (سرعة 167 - زر B) - مفعل مسبقاً
--// ===============================
local fixedFlickEnabled = true

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.Z then
        flickEnabled = not flickEnabled
        if flickEnabled then
            print("⚡ Dynamic Speed Flick Script: [ ON ] 🟢 (Key: Z)")
        else
            print("⚡ Dynamic Speed Flick Script: [ OFF ] 🔴")
        end
    elseif input.KeyCode == Enum.KeyCode.B then
        fixedFlickEnabled = not fixedFlickEnabled
        if fixedFlickEnabled then
            print("⚡ Fixed Flick Script (167): [ ON ] 🟢 (Key: B)")
        else
            print("⚡ Fixed Flick Script (167): [ OFF ] 🔴")
        end
    end
end)

--// ===============================
--// UI Setup (Besty & Camera Buttons)
--// ===============================

-- Tela
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnifiedGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Speed System Button (Besty)
local speedButton = Instance.new("TextButton")
speedButton.Size = UDim2.new(0, 140, 0, 50)
speedButton.Position = UDim2.new(0.05, 0, 0.1, 0)
speedButton.BackgroundColor3 = Color3.fromRGB(255, 105, 180) -- Rosa
speedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
speedButton.Font = Enum.Font.SourceSansBold
speedButton.TextSize = 18
speedButton.Text = "Besty: OFF"
speedButton.Parent = screenGui
speedButton.Active = true
speedButton.Draggable = true

local uiCornerSpeed = Instance.new("UICorner")
uiCornerSpeed.CornerRadius = UDim.new(0, 8)
uiCornerSpeed.Parent = speedButton

-- Impulso Button (Camera ❤️)
local impulsoButton = Instance.new("TextButton")
impulsoButton.Name = "ImpulsoButton"
impulsoButton.Parent = screenGui
impulsoButton.Size = UDim2.new(0, 140, 0, 50)
impulsoButton.Position = UDim2.new(0.05, 0, 0.22, 0)
impulsoButton.BackgroundColor3 = Color3.fromRGB(255, 105, 180) -- Rosa
impulsoButton.Text = "Camera ❤️: ON"
impulsoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
impulsoButton.Font = Enum.Font.SourceSansBold
impulsoButton.TextSize = 18
impulsoButton.Active = true
impulsoButton.Draggable = true

local uiCornerImpulso = Instance.new("UICorner")
uiCornerImpulso.CornerRadius = UDim.new(0, 8)
uiCornerImpulso.Parent = impulsoButton

--// ===============================
--// Funções de Atualização UI
--// ===============================

local function actualizarSpeedButton()
    if speedSistemaAtivo then
        speedButton.Text = "Besty: ON"
        speedButton.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
    else
        speedButton.Text = "Besty: OFF"
        speedButton.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
    end
end

local function actualizarImpulsoButton()
    if impulsoAtivo then
        impulsoButton.Text = "Camera ❤️: ON"
        impulsoButton.BackgroundColor3 = Color3.fromRGB(255, 20, 147)
    else
        impulsoButton.Text = "Camera ❤️: OFF"
        impulsoButton.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
    end
end

--// ===============================
--// Toggle Systems & Keybinds
--// ===============================

local function toggleSpeedSistema()
    speedSistemaAtivo = not speedSistemaAtivo
    actualizarSpeedButton()

    if not speedSistemaAtivo then
        humanoid.WalkSpeed = baseWalkSpeed
    end
end

local function toggleImpulsoSistema()
    impulsoAtivo = not impulsoAtivo
    actualizarImpulsoButton()
end

speedButton.MouseButton1Click:Connect(toggleSpeedSistema)
impulsoButton.MouseButton1Click:Connect(toggleImpulsoSistema)

-- Atalhos de Teclado: R (Speed) | Y (Camera)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.R then
        toggleSpeedSistema()
    elseif input.KeyCode == Enum.KeyCode.Y then
        toggleImpulsoSistema()
    end
end)

--// ===============================
--// Speed Boost Logic (Pulo)
--// ===============================

local function conectarHumanoid(hum)
    hum.StateChanged:Connect(function(_, newState)
        if speedSistemaAtivo then
            if newState == Enum.HumanoidStateType.Jumping then
                hum.WalkSpeed = baseWalkSpeed + speedBoost
            elseif newState == Enum.HumanoidStateType.Landed then
                hum.WalkSpeed = baseWalkSpeed
            end
        end
    end)
end

conectarHumanoid(humanoid)

--// ===============================
--// Impulso Movement Logic (A/S/D)
--// ===============================

local function applyBoost(directionVector)
    if not impulsoAtivo then return end

    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local root = char.HumanoidRootPart
        local force = Vector3.new(directionVector.X, 0, directionVector.Z).Unit * boostPower
        root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + force
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not impulsoAtivo then return end
    if tick() - lastTick < cooldown then return end

    local camCF = camera.CFrame

    if input.KeyCode == Enum.KeyCode.A then
        applyBoost(-camCF.RightVector)
        lastTick = tick()
    elseif input.KeyCode == Enum.KeyCode.D then
        applyBoost(camCF.RightVector)
        lastTick = tick()
    elseif input.KeyCode == Enum.KeyCode.S then
        applyBoost(-camCF.LookVector)
        lastTick = tick()
    end
end)

--// ===============================
--// Movement Loops (Dynamic Flick + Fixed Flick 167 + Anti-Ragdoll)
--// ===============================
local lastLookDynamic = camera.CFrame.LookVector
local lastLookFixed = camera.CFrame.LookVector

RunService.RenderStepped:Connect(function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not hum or hum.Health <= 0 or not root then return end

    -- درع Anti-Ragdoll المشترك
    local currentState = hum:GetState()
    if currentState == Enum.HumanoidStateType.Ragdoll or currentState == Enum.HumanoidStateType.FallingDown then
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end

    -- 1. منطق الـ Dynamic Flick (زر Z)
    if flickEnabled then
        local inAir = (currentState == Enum.HumanoidStateType.Freefall or currentState == Enum.HumanoidStateType.Jumping)

        if inAir then
            local currentLook = camera.CFrame.LookVector
            local diff = (currentLook - lastLookDynamic).Magnitude
            local moveDir = hum.MoveDirection

            if moveDir.Magnitude > 0 and diff >= 0.1 then
                local targetDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
                local currentVel = root.AssemblyLinearVelocity

                local dynamicSpeed = math.min(diff * 450, 250)
                if dynamicSpeed < 50 then
                    dynamicSpeed = 50
                end

                root.AssemblyLinearVelocity = Vector3.new(
                    targetDir.X * dynamicSpeed,
                    currentVel.Y,
                    targetDir.Z * dynamicSpeed
                )
            end

            lastLookDynamic = currentLook
        else
            lastLookDynamic = camera.CFrame.LookVector
        end
    end

    -- 2. منطق الـ Fixed Flick بقوة 167 (زر B)
    if fixedFlickEnabled then
        local inAir = (currentState == Enum.HumanoidStateType.Freefall or currentState == Enum.HumanoidStateType.Jumping)

        if inAir then
            local currentLook = camera.CFrame.LookVector
            local diff = (currentLook - lastLookFixed).Magnitude
            local moveDir = hum.MoveDirection

            if diff > 0.1 and moveDir.Magnitude > 0 then
                local targetDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
                local currentVel = root.AssemblyLinearVelocity

                root.AssemblyLinearVelocity = Vector3.new(
                    targetDir.X * 180,
                    currentVel.Y,
                    targetDir.Z * 180
                )
            end

            lastLookFixed = currentLook
        else
            lastLookFixed = camera.CFrame.LookVector
        end
    end
end)

--// Character Respawn Handler
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    task.wait(0.3)
    humanoid = getHumanoid(newChar)
    baseWalkSpeed = humanoid.WalkSpeed
    conectarHumanoid(humanoid)

    if not speedSistemaAtivo then
        humanoid.WalkSpeed = baseWalkSpeed
    end
end)

-- Final UI refresh
actualizarSpeedButton()
actualizarImpulsoButton()

print("🛡️🔥 Ultimate Combined Master Script Loaded Successfully! (Z & B are ON by default) 🚀")
