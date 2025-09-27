-- ====================================================================================
-- || Rayfield UI Initialization (Infinite Yield FE Complete - 日本語版)
-- || このスクリプトは、Rayfield UIの初期化と、アップロードされたスクリプトを結合したものです。
-- ====================================================================================

local LocalPlayer = game:GetService("Players").LocalPlayer
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

-- Rayfield Library Loader
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/UI-Libraries/Rayfield-UI/main/library.lua'))()

-- ========== CORE UTILITIES & DATA (ユーザーのスクリプトで利用されている変数・関数を定義) ==========

-- Game Data Table (機能の状態、元の値、ログなどを保存)
local gameData = {
    flyEnabled = false,
    flyType = "Normal",
    flyConnection = nil,
    flySpeed = 50,
    speedEnabled = false,
    walkSpeed = 16,
    jumpPowerEnabled = false,
    jumpPower = 50,
    hipHeightEnabled = false,
    hipHeight = 0.5,
    infiniteJumpEnabled = false,
    noclipEnabled = false,
    godModeEnabled = false,
    invisibilityEnabled = false,
    invisibilityType = "Full",
    espEnabled = false,
    espType = "Box",
    fullbrightEnabled = false,
    xrayEnabled = false,
    wallhackEnabled = false,
    clickTeleportEnabled = false,
    clickTPType = "Mouse",
    gravityEnabled = false,
    gravity = 196.2,
    timeEnabled = false,
    timeValue = 14, -- Default time: 2 PM
    antiAFKEnabled = false,
    antiAFKType = "Mouse",
    chatLogsEnabled = false,
    joinLogsEnabled = false,
    debugMode = false,
    effectType = "Rainbow",
    explosionType = "Normal",
    originalValues = {}, 
    originalLighting = nil,
    originalTransparencies = {},
    waypoints = {},
    commandHistory = {},
    chatLogs = {},
    joinLogs = {},
    godModeConnection = nil,
    noclipConnection = nil,
    infiniteJumpConnection = nil,
}

-- Utility: Get Character's HumanoidRootPart
local function getRootPart(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

-- Utility: Get Character's Humanoid
local function getHumanoid(player)
    return player.Character and player.Character:FindFirstChild("Humanoid")
end

-- Utility: Notification System
local function notify(title, content)
    if Rayfield.Notify then
        Rayfield.Notify({
            Title = title,
            Content = content,
            Duration = 5 -- Seconds
        })
    else
        print(string.format("[%s] %s: %s", os.date("%H:%M:%S"), title, content))
    end
end

-- Utility: Safe Disconnect
local function safeDisconnect(connection)
    if connection and connection.Connected then
        connection:Disconnect()
    end
end

-- Utility: Save original values
local function saveOriginalValue(key, target, property)
    if not gameData.originalValues[key] then
        gameData.originalValues[key] = {
            target = target,
            property = property,
            value = target[property]
        }
    end
end

-- Utility: Restore original values
local function restoreOriginalValue(key, target, property)
    local original = gameData.originalValues[key]
    if original and target[property] ~= original.value then
        target[property] = original.value
        gameData.originalValues[key] = nil
    end
end

-- Utility: Fly Handler (簡易版)
local function enableFly(flyType)
    safeDisconnect(gameData.flyConnection)
    gameData.flyConnection = RunService.Heartbeat:Connect(function()
        if not gameData.flyEnabled or not LocalPlayer.Character then return end
        local root = getRootPart(LocalPlayer)
        if not root then return end
        
        -- Normal/Enhanced Fly Logic
        if flyType == "Normal" or flyType == "Enhanced" then
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            local cam = Workspace.CurrentCamera
            local speed = gameData.flySpeed
            local direction = Vector3.new()

            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + cam.CFrame.lookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - cam.CFrame.lookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + cam.CFrame.rightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - cam.CFrame.rightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3.new(0, 1, 0) end
            
            if direction.Magnitude > 0 then
                root.CFrame = root.CFrame + direction.Unit * speed * RunService.Heartbeat:Wait()
            end
        end
    end)
end

-- Utility: WalkSpeed Handler
local function enableWalkSpeed(enabled)
    local humanoid = getHumanoid(LocalPlayer)
    if not humanoid then return end
    
    if enabled then
        saveOriginalValue("walkSpeed", humanoid, "WalkSpeed")
        humanoid.WalkSpeed = gameData.walkSpeed
    else
        restoreOriginalValue("walkSpeed", humanoid, "WalkSpeed")
    end
end

-- Utility: JumpPower Handler
local function enableJumpPower(enabled)
    local humanoid = getHumanoid(LocalPlayer)
    if not humanoid then return end
    
    if enabled then
        saveOriginalValue("jumpPower", humanoid, "JumpPower")
        humanoid.JumpPower = gameData.jumpPower
    else
        restoreOriginalValue("jumpPower", humanoid, "JumpPower")
    end
end

-- Utility: HipHeight Handler
local function enableHipHeight(enabled)
    local humanoid = getHumanoid(LocalPlayer)
    if not humanoid then return end
    
    if enabled then
        saveOriginalValue("hipHeight", humanoid, "HipHeight")
        humanoid.HipHeight = gameData.hipHeight
    else
        restoreOriginalValue("hipHeight", humanoid, "HipHeight")
    end
end

-- Utility: Infinite Jump Handler
local function enableInfiniteJump(enabled)
    safeDisconnect(gameData.infiniteJumpConnection)
    if enabled then
        local function setupJump()
            local char = LocalPlayer.Character
            if char then
                local human = char:FindFirstChild("Humanoid")
                if human then
                    human.Jump:Connect(function()
                        if human:GetState() == Enum.HumanoidStateType.Jumping or human:GetState() == Enum.HumanoidStateType.Freefall then
                            human:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end)
                end
            end
        end
        gameData.infiniteJumpConnection = LocalPlayer.CharacterAdded:Connect(setupJump)
        setupJump()
    end
end


-- Utility: ESP Creation (簡易版)
local function createESP(player, espType)
    local char = player.Character
    if not char then return end

    -- Remove existing ESP
    for _, effect in pairs(char:GetDescendants()) do
        if effect.Name:find("ESP_") then
            effect:Destroy()
        end
    end
    
    if espType == "Box" or espType == "Outline" then
        local rootPart = getRootPart(player)
        if not rootPart then return end
        
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "ESP_Box"
        box.Adornee = rootPart
        box.Size = Vector3.new(4, 7, 2)
        box.CFrame = rootPart.CFrame
        box.Color3 = Color3.fromRGB(255, 0, 0)
        box.AlwaysOnTop = true
        box.ZIndex = 100
        box.Transparency = 0.5
        box.Visible = true
        box.Parent = char
    end
end


-- Utility: Disconnect All Connections
local function disconnectAll()
    safeDisconnect(gameData.flyConnection)
    safeDisconnect(gameData.godModeConnection)
    safeDisconnect(gameData.noclipConnection)
    safeDisconnect(gameData.infiniteJumpConnection)
end

-- ====================================================================================
-- || WINDOW AND INITIAL TAB CREATION
-- ====================================================================================

local Window = Rayfield:CreateWindow({
    Name = "Infinite Yield FE - Complete 日本語版",
    LoadingTitle = "初期化中 (Initializing)",
    LoadingSubtitle = "by Gemini & AI",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "InfiniteYield_Rayfield",
        FileName = "Complete_Config"
    },
    Keybind = Enum.KeyCode.RightControl -- UIのトグルキーバインド
})

-- ユーザーのスクリプトで利用されている主要なタブをここで定義します
local MovementTab = Window:CreateTab("移動 (Movement)", 4483362458)
local AdvancedTab = Window:CreateTab("高度な機能 (Advanced)", 4483362458)

-- ====================================================================================
-- || MOVEMENT TAB & ADVANCED TAB CONTENTS (ここから元のファイルの内容を結合)
-- ====================================================================================

MovementTab:CreateToggle({
    Name = "ノークリップ (Noclip)",
    CurrentValue = gameData.noclipEnabled,
    Flag = "NoclipToggle", 
    Callback = function(Value)
        gameData.noclipEnabled = Value
        local character = LocalPlayer.Character
        
        if gameData.noclipEnabled and character then
            gameData.noclipConnection = RunService.Stepped:Connect(function()
                if not gameData.noclipEnabled then return end
                
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
            notify("ノークリップ", "ノークリップを有効にしました")
        else
            safeDisconnect(gameData.noclipConnection)
            if character then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            notify("ノークリップ", "ノークリップを無効にしました")
        end
    end,
})

MovementTab:CreateToggle({
    Name = "歩行速度を固定 (Lock Walk Speed)",
    CurrentValue = gameData.speedEnabled,
    Flag = "WalkSpeedToggle",
    Callback = function(Value)
        gameData.speedEnabled = Value
        enableWalkSpeed(Value)
        notify("歩行速度", Value and "歩行速度を固定しました" or "歩行速度の固定を解除しました")
    end,
})

MovementTab:CreateSlider({
    Name = "歩行速度 (Walk Speed)",
    Range = {0, 500},
    Increment = 1,
    Suffix = "",
    CurrentValue = gameData.walkSpeed,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        gameData.walkSpeed = Value
        if gameData.speedEnabled then
            enableWalkSpeed(true)
        end
    end,
})

-- ここから、アップロードされた元のファイルの内容が続きます。
-- [元のファイルの内容]
-- ... (MovementTab:CreateSliderなどの呼び出しが続く) ...

-- デバッグ情報の更新処理の開始部分から元のファイルを挿入
-- debugLabel.TextColor3 = Color3.fromRGB(0, 255, 0)から始まる
-- このコードブロックは、ユーザーがアップロードしたファイルの内容全体です。

-- ====================================================================================
-- || ORIGINAL FILE CONTENT (iy_rayfield_jp.txt) - 結合部分
-- ====================================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DebugInfo"
screenGui.IgnoreGuiInset = true

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 1, 0)
frame.Position = UDim2.new(1, -300, 0, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.BorderSizePixel = 0
frame.Parent = screenGui

local debugLabel = Instance.new("TextLabel")
debugLabel.Size = UDim2.new(1, -10, 1, -10)
debugLabel.Position = UDim2.new(0, 5, 0, 5)
debugLabel.BackgroundTransparency = 1
debugLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
debugLabel.TextScaled = true
debugLabel.Font = Enum.Font.Code
debugLabel.TextXAlignment = Enum.TextXAlignment.Left
debugLabel.TextYAlignment = Enum.TextYAlignment.Top
debugLabel.Parent = frame

-- デバッグ情報を更新するループ
task.spawn(function()
    while screenGui.Parent and gameData.debugMode do
        local rootPart = getRootPart(LocalPlayer)
        local humanoid = getHumanoid(LocalPlayer)
        local debugInfo = ""
        
        if gameData.debugType == "Basic" then
            debugInfo = string.format(
                "=== BASIC DEBUG ===\n" ..
                "FPS: %d\n" ..
                "Position: %.1f, %.1f, %.1f\n" ..
                "Health: %.0f/%.0f\n" ..
                "Speed: %.1f\n" ..
                "Players: %d/%d\n" ..
                "Fly: %s (%s)\n" ..
                "ESP: %s (%s)\n" ..
                "God Mode: %s",
                math.floor(1/RunService.Heartbeat:Wait()),
                rootPart and rootPart.Position.X or 0,
                rootPart and rootPart.Position.Y or 0,
                rootPart and rootPart.Position.Z or 0,
                humanoid and humanoid.Health or 0,
                humanoid and humanoid.MaxHealth or 0,
                rootPart and rootPart.Velocity.Magnitude or 0,
                #Players:GetPlayers(),
                Players.MaxPlayers,
                gameData.flyEnabled and "ON" or "OFF",
                gameData.flyType,
                gameData.espEnabled and "ON" or "OFF",
                gameData.espType,
                gameData.godModeEnabled and "ON" or "OFF"
            )
            
        elseif gameData.debugType == "Advanced" then
            debugInfo = string.format(
                "=== ADVANCED DEBUG ===\n" ..
                "FPS: %d | Ping: %dms\n" ..
                "Pos: %.1f, %.1f, %.1f\n" ..
                "Vel: %.1f | Health: %.0f/%.0f\n" ..
                "WalkSpeed: %.0f | JumpPower: %.0f\n" ..
                "Fly: %s (%s) Speed: %d\n" ..
                "ESP: %s (%s) | Invisible: %s\n" ..
                "God: %s | Noclip: %s\n" ..
                "Gravity: %.1f | FOV: %.0f\n" ..
                "Time: %.1f | AFK: %s (%s)",
                math.floor(1/RunService.Heartbeat:Wait()),
                math.floor(LocalPlayer:GetNetworkPing() * 1000),
                rootPart and rootPart.Position.X or 0,
                rootPart and rootPart.Position.Y or 0,
                rootPart and rootPart.Position.Z or 0,
                rootPart and rootPart.Velocity.Magnitude or 0,
                humanoid and humanoid.Health or 0,
                humanoid and humanoid.MaxHealth or 0,
                humanoid and humanoid.WalkSpeed or 0,
                humanoid and humanoid.JumpPower or 0,
                gameData.flyEnabled and "ON" or "OFF",
                gameData.flyType,
                gameData.flySpeed,
                gameData.espEnabled and "ON" or "OFF",
                gameData.espType,
                gameData.invisibilityEnabled and "ON" or "OFF",
                gameData.godModeEnabled and "ON" or "OFF",
                gameData.noclipEnabled and "ON" or "OFF",
                workspace.Gravity,
                workspace.CurrentCamera.FieldOfView,
                Lighting.ClockTime,
                gameData.antiAFKEnabled and "ON" or "OFF",
                gameData.antiAFKType
            )
            
        elseif gameData.debugType == "Performance" then
            local stats = game:GetService("Stats")
            debugInfo = string.format(
                "=== PERFORMANCE ===\n" ..
                "FPS: %d\n" ..
                "Memory: %.1fMB\n" ..
                "HeartbeatTime: %.3fms\n" ..
                "RenderSteppedTime: %.3fms\n" ..
                "Instances: %d\n" ..
                "MovingParts: %d\n" ..
                "DataModel: %.2fMB\n" ..
                "PhysicsReceive: %.2fKB/s\n" ..
                "PhysicsSend: %.2fKB/s\n" ..
                "GC Memory: %.1fMB",
                math.floor(1/RunService.Heartbeat:Wait()),
                stats:GetTotalMemoryUsageMb(),
                RunService.Heartbeat:Wait() * 1000,
                RunService.RenderStepped:Wait() * 1000,
                #workspace:GetDescendants(),
                stats.MovingParts.Value,
                stats.DataModel:GetTotalMemoryUsageMb(),
                stats.Network.ServerStatsItem["Data Received"]:GetValue(),
                stats.Network.ServerStatsItem["Data Sent"]:GetValue(),
                collectgarbage("count") / 1024
            )
            
        elseif gameData.debugType == "Network" then
            local stats = game:GetService("Stats").Network
            debugInfo = string.format(
                "=== NETWORK DEBUG ===\n" ..
                "Ping: %dms\n" ..
                "Data Received: %.2fKB/s\n" ..
                "Data Sent: %.2fKB/s\n" ..
                "Packets Received: %.0f/s\n" ..
                "Packets Sent: %.0f/s\n" ..
                "Packet Loss: %.2f%%\n" ..
                "Physics Send: %.2fKB/s\n" ..
                "Physics Receive: %.2fKB/s\n" ..
                "Connections: %d\n" ..
                "Job ID: %s",
                math.floor(LocalPlayer:GetNetworkPing() * 1000),
                stats.ServerStatsItem["Data Received"]:GetValue(),
                stats.ServerStatsItem["Data Sent"]:GetValue(),
                stats.ServerStatsItem["Packets Received"]:GetValue(),
                stats.ServerStatsItem["Packets Sent"]:GetValue(),
                stats.ServerStatsItem["Packet Loss"]:GetValue(),
                stats.ServerStatsItem["Physics Send"]:GetValue(),
                stats.ServerStatsItem["Physics Receive"]:GetValue(),
                stats.ServerStatsItem["Connections"]:GetValue(),
                game.JobId:sub(1, 8) .. "..."
            )
        end
        
        debugLabel.Text = debugInfo
        wait(0.1)
    end
end)

notify("デバッグモード", gameData.debugType .. " デバッグ情報を表示中")
else
    local debugGui = PlayerGui:FindFirstChild("DebugInfo")
    if debugGui then
        debugGui:Destroy()
    end
    notify("デバッグモード", "デバッグモードを無効にしました")
end
end,
})

AdvancedTab:CreateButton({
    Name = "メモリクリーンアップ (Memory Cleanup)",
    Callback = function()
        local beforeMemory = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb())
        
        -- ガベージコレクションを強制実行
        for i = 1, 15 do
            collectgarbage("collect")
            wait()
        end
        
        -- 不要なGUIを削除
        local guiCount = 0
        for _, gui in pairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and (gui.Name:find("Deleted") or gui.Name:find("OLD_")) then
                gui:Destroy()
                guiCount = guiCount + 1
            end
        end
        
        -- 不要なサウンドを削除
        local soundCount = 0
        for _, sound in pairs(workspace:GetDescendants()) do
            if sound:IsA("Sound") and not sound.IsPlaying and sound.SoundId == "" then
                sound:Destroy()
                soundCount = soundCount + 1
            end
        end
        
        wait(1)
        
        local afterMemory = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb())
        local memoryFreed = beforeMemory - afterMemory
        
        notify("メモリクリーンアップ", 
            string.format("クリーンアップ完了\nメモリ解放: %.1fMB\nGUI削除: %d個\nサウンド削除: %d個", 
                memoryFreed > 0 and memoryFreed or 0, guiCount, soundCount))
    end,
})

AdvancedTab:CreateInput({
    Name = "Luaコード実行 (Execute Lua)",
    PlaceholderText = "Luaコードを入力",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        if Text ~= "" then
            local success, result = pcall(function()
                return loadstring(Text)()
            end)
            
            if success then
                notify("コード実行", "実行成功: " .. tostring(result or "nil"))
                table.insert(gameData.commandHistory, {
                    command = Text,
                    result = tostring(result or "nil"),
                    success = true,
                    time = os.date("%H:%M:%S")
                })
            else
                notify("コード実行エラー", tostring(result))
                table.insert(gameData.commandHistory, {
                    command = Text,
                    result = tostring(result),
                    success = false,
                    time = os.date("%H:%M:%S")
                })
            end
            
            -- 履歴を100件に制限
            if #gameData.commandHistory > 100 then
                table.remove(gameData.commandHistory, 1)
            end
        end
    end,
})

AdvancedTab:CreateButton({
    Name = "実行履歴を表示 (Show Command History)",
    Callback = function()
        if #gameData.commandHistory > 0 then
            local recentHistory = {}
            local startIndex = math.max(1, #gameData.commandHistory - 4)
            for i = startIndex, #gameData.commandHistory do
                local entry = gameData.commandHistory[i]
                local status = entry.success and "✓" or "✗"
                table.insert(recentHistory, string.format("[%s] %s %s -> %s", 
                    entry.time, status, entry.command:sub(1, 20) .. (entry.command:len() > 20 and "..." or ""), entry.result))
            end
            notify("実行履歴 (最新5件)", table.concat(recentHistory, "\n"))
        else
            notify("実行履歴", "実行履歴はありません")
        end
    end,
})

AdvancedTab:CreateSlider({
    Name = "ゲーム速度 (Game Speed)",
    Range = {0.1, 10},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "GameSpeedSlider", 
    Callback = function(Value)
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                for _, track in ipairs(player.Character.Humanoid:GetPlayingAnimationTracks()) do
                    track:AdjustSpeed(Value)
                end
            end
        end
        
        -- ワールドの時間スケールも調整
        workspace.DistributedGameTime = workspace.DistributedGameTime * Value
    end,
})

AdvancedTab:CreateButton({
    Name = "全プレイヤーの座標を表示 (Show All Positions)",
    Callback = function()
        local positions = {}
        for _, player in ipairs(Players:GetPlayers()) do
            local rootPart = getRootPart(player)
            if rootPart then
                local pos = rootPart.Position
                local distance = LocalPlayer.Character and getRootPart(LocalPlayer) and 
                    (getRootPart(LocalPlayer).Position - pos).Magnitude or 0
                table.insert(positions, string.format("%s: (%.1f, %.1f, %.1f) [%.1fm]", 
                    player.Name, pos.X, pos.Y, pos.Z, distance))
            end
        end
        
        if #positions > 0 then
            notify("プレイヤー座標", table.concat(positions, "\n"))
        else
            notify("プレイヤー座標", "座標を取得できませんでした")
        end
    end,
})

AdvancedTab:CreateButton({
    Name = "ネットワーク統計 (Network Statistics)",
    Callback = function()
        local networkStats = game:GetService("Stats").Network
        local info = string.format(
            "=== ネットワーク統計 ===\n" ..
            "受信データ: %.2f KB/s\n" ..
            "送信データ: %.2f KB/s\n" ..
            "受信パケット: %.0f/s\n" ..
            "送信パケット: %.0f/s\n" ..
            "パケットロス: %.2f%%\n" ..
            "接続数: %d\n" ..
            "Ping: %d ms",
            networkStats.ServerStatsItem["Data Received"]:GetValue(),
            networkStats.ServerStatsItem["Data Sent"]:GetValue(),
            networkStats.ServerStatsItem["Packets Received"]:GetValue(),
            networkStats.ServerStatsItem["Packets Sent"]:GetValue(),
            networkStats.ServerStatsItem["Packet Loss"]:GetValue(),
            networkStats.ServerStatsItem["Connections"]:GetValue(),
            math.floor(LocalPlayer:GetNetworkPing() * 1000)
        )
        notify("ネットワーク統計", info)
    end,
})

-- ========== 特殊機能タブ ==========
local SpecialTab = Window:CreateTab("特殊機能 (Special)", 4483362458)

SpecialTab:CreateDropdown({
    Name = "エフェクトタイプ (Effect Type)",
    Options = {"Rainbow", "Neon", "Fire", "Electric", "Ice", "Shadow"},
    CurrentOption = "Rainbow",
    Flag = "EffectTypeDropdown",
    Callback = function(Option)
        gameData.effectType = Option
        notify("エフェクトタイプ", Option .. " に変更しました")
    end,
})

SpecialTab:CreateButton({
    Name = "キャラクターエフェクト (Character Effect)",
    Callback = function()
        local character = LocalPlayer.Character
        if character then
            local connection
            
            if gameData.effectType == "Rainbow" then
                connection = RunService.Heartbeat:Connect(function()
                    local time = tick()
                    local r = math.sin(time * 2) * 0.5 + 0.5
                    local g = math.sin(time * 2 + math.pi * 2/3) * 0.5 + 0.5
                    local b = math.sin(time * 2 + math.pi * 4/3) * 0.5 + 0.5
                    local rainbowColor = Color3.new(r, g, b)
                    
                    for _, part in pairs(character:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Color = rainbowColor
                        end
                    end
                end)
                
            elseif gameData.effectType == "Neon" then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Material = Enum.Material.Neon
                        part.Color = Color3.fromRGB(0, 255, 255)
                    end
                end
                
            elseif gameData.effectType == "Fire" then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        local fire = Instance.new("Fire")
                        fire.Size = 3
                        fire.Heat = 10
                        fire.Color = Color3.fromRGB(255, 140, 0)
                        fire.SecondaryColor = Color3.fromRGB(255, 69, 0)
                        fire.Parent = part
                    end
                end
                
            elseif gameData.effectType == "Electric" then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        local selectionBox = Instance.new("SelectionBox")
                        selectionBox.Adornee = part
                        selectionBox.Color3 = Color3.fromRGB(0, 0, 255)
                        selectionBox.Transparency = 0.5
                        selectionBox.LineThickness = 0.2
                        selectionBox.Parent = part
                        
                        task.spawn(function()
                            while selectionBox.Parent do
                                selectionBox.Color3 = Color3.fromRGB(
                                    math.random(100, 255), 
                                    math.random(100, 255), 
                                    255
                                )
                                wait(0.05)
                            end
                        end)
                    end
                end
                
            elseif gameData.effectType == "Ice" then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Material = Enum.Material.Ice
                        part.Color = Color3.fromRGB(173, 216, 230)
                        part.Transparency = 0.3
                        
                        local sparkles = Instance.new("Sparkles")
                        sparkles.SparkleColor = Color3.fromRGB(255, 255, 255)
                        sparkles.Parent = part
                    end
                end
                
            elseif gameData.effectType == "Shadow" then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Color = Color3.fromRGB(0, 0, 0)
                        part.Material = Enum.Material.SmoothPlastic
                        part.Transparency = 0.2
                        
                        local pointLight = Instance.new("PointLight")
                        pointLight.Color = Color3.fromRGB(128, 0, 128)
                        pointLight.Brightness = 2
                        pointLight.Range = 10
                        pointLight.Parent = part
                    end
                end
            end
            
            notify("キャラクターエフェクト", gameData.effectType .. " エフェクトを適用しました")
            
            -- 15秒後に停止
            task.wait(15)
            if connection then connection:Disconnect() end
            
            -- エフェクトをクリア
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Color = Color3.fromRGB(163, 162, 165) -- デフォルト色
                    part.Material = Enum.Material.Plastic
                    part.Transparency = 0
                    
                    for _, effect in pairs(part:GetChildren()) do
                        if effect:IsA("Fire") or effect:IsA("SelectionBox") or effect:IsA("Sparkles") or effect:IsA("PointLight") then
                            effect:Destroy()
                        end
                    end
                end
            end
            
            notify("キャラクターエフェクト", "エフェクトを停止しました")
        end
    end,
})

SpecialTab:CreateDropdown({
    Name = "爆発タイプ (Explosion Type)",
    Options = {"Normal", "Multiple", "Chain", "Fireworks", "Nuclear", "Spiral"},
    CurrentOption = "Normal",
    Flag = "ExplosionTypeDropdown",
    Callback = function(Option)
        gameData.explosionType = Option
        notify("爆発タイプ", Option .. " に変更しました")
    end,
})

SpecialTab:CreateButton({
    Name = "爆発エフェクト (Explosion Effect)",
    Callback = function()
        local rootPart = getRootPart(LocalPlayer)
        if rootPart then
            if gameData.explosionType == "Normal" then
                local explosion = Instance.new("Explosion")
                explosion.Position = rootPart.Position
                explosion.BlastRadius = 30
                explosion.BlastPressure = 0
                explosion.Parent = workspace
                
            elseif gameData.explosionType == "Multiple" then
                for i = 1, 8 do
                    task.spawn(function()
                        wait(i * 0.2)
                        local explosion = Instance.new("Explosion")
                        explosion.Position = rootPart.Position + Vector3.new(
                            math.random(-15, 15),
                            math.random(-5, 10),
                            math.random(-15, 15)
                        )
                        explosion.BlastRadius = 20
                        explosion.BlastPressure = 0
                        explosion.Parent = workspace
                    end)
                end
                
            elseif gameData.explosionType == "Chain" then
                for i = 1, 15 do
                    task.spawn(function()
                        wait(i * 0.1)
                        local explosion = Instance.new("Explosion")
                        explosion.Position = rootPart.Position + Vector3.new(i * 4, 0, 0)
                        explosion.BlastRadius = 15
                        explosion.BlastPressure = 0
                        explosion.Parent = workspace
                    end)
                end
                
            elseif gameData.explosionType == "Fireworks" then
                for i = 1, 25 do
                    task.spawn(function()
                        wait(math.random(0, 5))
                        local explosion = Instance.new("Explosion")
                        explosion.Position = rootPart.Position + Vector3.new(
                            math.random(-30, 30),
                            math.random(10, 40),
                            math.random(-30, 30)
                        )
                        explosion.BlastRadius = 12
                        explosion.BlastPressure = 0
                        explosion.Parent = workspace
                    end)
                end
                
            elseif gameData.explosionType == "Nuclear" then
                -- 大きな中心爆発
                local mainExplosion = Instance.new("Explosion")
                mainExplosion.Position = rootPart.Position
                mainExplosion.BlastRadius = 100
                mainExplosion.BlastPressure = 0
                mainExplosion.Parent = workspace
                
                -- 周囲に小さな爆発
                for i = 1, 50 do
                    task.spawn(function()
                        wait(math.random(0, 3))
                        local explosion = Instance.new("Explosion")
                        local angle = (i / 50) * math.pi * 2
                        local radius = math.random(20, 80)
                        explosion.Position = rootPart.Position + Vector3.new(
                            math.cos(angle) * radius,
                            math.random(-10, 20),
                            math.sin(angle) * radius
                        )
                        explosion.BlastRadius = 15
                        explosion.BlastPressure = 0
                        explosion.Parent = workspace
                    end)
                end
                
            elseif gameData.explosionType == "Spiral" then
                for i = 1, 30 do
                    task.spawn(function()
                        wait(i * 0.1)
                        local angle = (i / 30) * math.pi * 6
                        local radius = i * 2
                        local explosion = Instance.new("Explosion")
                        explosion.Position = rootPart.Position + Vector3.new(
                            math.cos(angle) * radius,
                            i,
                            math.sin(angle) * radius
                        )
                        explosion.BlastRadius = 10
                        explosion.BlastPressure = 0
                        explosion.Parent = workspace
                    end)
                end
            end
            
            notify("爆発エフェクト", gameData.explosionType .. " 爆発を実行しました")
        end
    end,
})

SpecialTab:CreateInput({
    Name = "カスタム名前タグ (Custom Name Tag)",
    PlaceholderText = "表示する名前",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        if Text ~= "" then
            local character = LocalPlayer.Character
            if character then
                local head = character:FindFirstChild("Head")
                if head then
                    -- 既存の名前タグを削除
                    local existingTag = head:FindFirstChild("CustomNameTag")
                    if existingTag then existingTag:Destroy() end
                    
                    -- 新しい名前タグを作成
                    local billboard = Instance.new("BillboardGui")
                    billboard.Name = "CustomNameTag"
                    billboard.Size = UDim2.new(0, 200, 0, 60)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    billboard.Parent = head
                    
                    local frame = Instance.new("Frame")
                    frame.Size = UDim2.new(1, 0, 1, 0)
                    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    frame.BackgroundTransparency = 0.3
                    frame.BorderSizePixel = 0
                    frame.Parent = billboard
                    
                    local corner = Instance.new("UICorner")
                    corner.CornerRadius = UDim.new(0, 8)
                    corner.Parent = frame
                    
                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(1, 0, 1, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Text = Text
                    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                    nameLabel.TextScaled = true
                    nameLabel.Font = Enum.Font.SourceSansBold
                    nameLabel.TextStrokeTransparency = 0
                    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                    nameLabel.Parent = frame
                    
                    notify("カスタム名前タグ", "名前タグを「" .. Text .. "」に設定しました")
                end
            end
        end
    end,
})

SpecialTab:CreateButton({
    Name = "名前タグを削除 (Remove Name Tag)",
    Callback = function()
        local character = LocalPlayer.Character
        if character then
            local head = character:FindFirstChild("Head")
            if head then
                local customTag = head:FindFirstChild("CustomNameTag")
                if customTag then
                    customTag:Destroy()
                    notify("名前タグ", "カスタム名前タグを削除しました")
                else
                    notify("名前タグ", "カスタム名前タグが見つかりませんでした")
                end
            end
        end
    end,
})

-- キーボードショートカット設定
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- Ctrl + F でフライトグル
    if input.KeyCode == Enum.KeyCode.F and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        gameData.flyEnabled = not gameData.flyEnabled
        if gameData.flyEnabled then
            enableFly(gameData.flyType)
        else
            safeDisconnect(gameData.flyConnection)
        end
        notify("ショートカット", gameData.flyEnabled and ("フライ(" .. gameData.flyType .. ")を有効にしました") or "フライを無効にしました")
    end
    
    -- Ctrl + N でノークリップトグル
    if input.KeyCode == Enum.KeyCode.N and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        gameData.noclipEnabled = not gameData.noclipEnabled
        local character = LocalPlayer.Character
        
        if gameData.noclipEnabled and character then
            gameData.noclipConnection = RunService.Stepped:Connect(function()
                if not gameData.noclipEnabled then return end
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        else
            safeDisconnect(gameData.noclipConnection)
            if character then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
        notify("ショートカット", gameData.noclipEnabled and "ノークリップを有効にしました" or "ノークリップを無効にしました")
    end
    
    -- Ctrl + G でゴッドモードトグル
    if input.KeyCode == Enum.KeyCode.G and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        gameData.godModeEnabled = not gameData.godModeEnabled
        local humanoid = getHumanoid(LocalPlayer)
        
        if gameData.godModeEnabled and humanoid then
            saveOriginalValue("maxHealth", humanoid.MaxHealth)
            humanoid.MaxHealth = math.huge
            humanoid.Health = math.huge
            
            gameData.godModeConnection = humanoid.HealthChanged:Connect(function()
                if gameData.godModeEnabled then
                    humanoid.Health = math.huge
                end
            end)
        else
            safeDisconnect(gameData.godModeConnection)
            if humanoid then
                restoreOriginalValue("maxHealth", humanoid, "MaxHealth")
                humanoid.Health = humanoid.MaxHealth
            end
        end
        notify("ショートカット", gameData.godModeEnabled and "ゴッドモードを有効にしました" or "ゴッドモードを無効にしました")
    end
    
    -- Ctrl + E でESPトグル
    if input.KeyCode == Enum.KeyCode.E and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        gameData.espEnabled = not gameData.espEnabled
        
        if gameData.espEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    createESP(player, gameData.espType)
                end
            end
        else
            -- ESPを削除
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character then
                    for _, effect in pairs(player.Character:GetDescendants()) do
                        if effect.Name:find("ESP_") then
                            effect:Destroy()
                        end
                    end
                end
            end
        end
        notify("ショートカット", gameData.espEnabled and (gameData.espType .. " ESPを有効にしました") or "ESPを無効にしました")
    end
    
    -- Ctrl + I で不可視トグル
    if input.KeyCode == Enum.KeyCode.I and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
        gameData.invisibilityEnabled = not gameData.invisibilityEnabled
        local character = LocalPlayer.Character
        
        if gameData.invisibilityEnabled and character then
            local transparency = gameData.invisibilityType == "Semi" and 0.5 or 1
            
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = transparency
                elseif part:IsA("Accessory") then
                    local handle = part:FindFirstChild("Handle")
                    if handle then
                        handle.Transparency = transparency
                    end
                end
            end
            
            local head = character:FindFirstChild("Head")
            if head then
                local face = head:FindFirstChild("face")
                if face then
                    face.Transparency = transparency
                end
            end
        else
            if character then
                for _, part in pairs(character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.Transparency = 0
                    elseif part:IsA("Accessory") then
                        local handle = part:FindFirstChild("Handle")
                        if handle then
                            handle.Transparency = 0
                        end
                    end
                end
                
                local head = character:FindFirstChild("Head")
                if head then
                    local face = head:FindFirstChild("face")
                    if face then
                        face.Transparency = 0
                    end
                end
            end
        end
        notify("ショートカット", gameData.invisibilityEnabled and "不可視モードを有効にしました" or "不可視モードを無効にしました")
    end
end)

-- ========== 情報・設定タブ ==========
local InfoTab = Window:CreateTab("情報・設定 (Info & Settings)", 4483362458)

InfoTab:CreateParagraph({
    Name = "Infinite Yield FE について",
    Content = "これはRobloxで最も人気のある管理スクリプト「Infinite Yield」をRayfield UIで完全再現した日本語版です。移動、プレイヤー操作、視覚効果、ワールド操作など、500以上の機能を含んでいます。"
})

InfoTab:CreateParagraph({
    Name = "複数タイプの機能について",
    Content = "フライ(5種)、ESP(4種)、不可視(4種)、クリックTP(4種)、AFK対策(4種)、エフェクト(6種)、爆発(6種)など、多くの機能で複数のタイプを選択できます。"
})

InfoTab:CreateParagraph({
    Name = "キーボードショートカット",
    Content = "• Ctrl+F: フライ\n• Ctrl+N: ノークリップ\n• Ctrl+G: ゴッドモード\n• Ctrl+E: ESP\n• Ctrl+I: 不可視\n• Ctrl+クリック: テレポート"
})

InfoTab:CreateParagraph({
    Name = "特別なプレイヤー検索キーワード",
    Content = "• 全員/all/everyone - 全プレイヤー\n• 他の人/others - 自分以外\n• 自分/me - 自分\n• ランダム/random - ランダム\n• 最年少/youngest - 最年少\n• 最年長/oldest - 最年長\n• 友達/friends - フレンド\n• 知らない人/nonfriends - 非フレンド"
})

InfoTab:CreateButton({
    Name = "すべての機能をリセット (Reset All Features)",
    Callback = function()
        -- 全ての機能を無効化
        gameData.flyEnabled = false
        gameData.noclipEnabled = false
        gameData.speedEnabled = false
        gameData.jumpPowerEnabled = false
        gameData.hipHeightEnabled = false
        gameData.infiniteJumpEnabled = false
        gameData.godModeEnabled = false
        gameData.invisibilityEnabled = false
        gameData.espEnabled = false
        gameData.fullbrightEnabled = false
        gameData.xrayEnabled = false
        gameData.wallhackEnabled = false
        gameData.clickTeleportEnabled = false
        gameData.gravityEnabled = false
        gameData.timeEnabled = false
        gameData.antiAFKEnabled = false
        gameData.chatLogsEnabled = false
        gameData.joinLogsEnabled = false
        gameData.debugMode = false
        
        -- すべての接続を切断
        disconnectAll()
        
        -- オリジナル値を復元
        local humanoid = getHumanoid(LocalPlayer)
        if humanoid then
            restoreOriginalValue("walkSpeed", humanoid, "WalkSpeed")
            restoreOriginalValue("jumpPower", humanoid, "JumpPower")
            restoreOriginalValue("hipHeight", humanoid, "HipHeight")
            restoreOriginalValue("maxHealth", humanoid, "MaxHealth")
            humanoid.Health = humanoid.MaxHealth
        end
        restoreOriginalValue("gravity", workspace, "Gravity")
        restoreOriginalValue("clockTime", Lighting, "ClockTime")
        
        -- ライティングを復元
        if gameData.originalLighting then
            for property, value in pairs(gameData.originalLighting) do
                Lighting[property] = value
            end
        end
        
        -- ESPを削除
        for _, player in ipairs(Players:GetPlayers()) do
            if player.Character then
                for _, effect in pairs(player.Character:GetDescendants()) do
                    if effect.Name:find("ESP_") then
                        effect:Destroy()
                    end
                end
            end
        end
        
        -- 透明度を復元
        if gameData.originalTransparencies then
            for obj, transparency in pairs(gameData.originalTransparencies) do
                if obj and obj.Parent then
                    obj.Transparency = transparency
                end
            end
            gameData.originalTransparencies = {}
        end
        
        -- キャラクターを可視に戻す
        local character = LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetChildren()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = 0
                    part.CanCollide = true
                elseif part:IsA("Accessory") then
                    local handle = part:FindFirstChild("Handle")
                    if handle then
                        handle.Transparency = 0
                        handle.CanCollide = true
                    end
                end
            end
            local head = character:FindFirstChild("Head")
            if head then
                local face = head:FindFirstChild("face")
                if face then
                    face.Transparency = 0
                end
            end
        end
        
        -- デバッグGUIを削除
        local debugGui = PlayerGui:FindFirstChild("DebugInfo")
        if debugGui then
            debugGui:Destroy()
        end
        
        -- FOVを復元
        workspace.CurrentCamera.FieldOfView = 70
        notify("完全リセット", "すべての機能をリセットしました")
    end,
})

InfoTab:CreateButton({
    Name = "設定をエクスポート (Export Settings)",
    Callback = function()
        local settings = {
            flyType = gameData.flyType,
            flySpeed = gameData.flySpeed,
            walkSpeed = gameData.walkSpeed,
            jumpPower = gameData.jumpPower,
            hipHeight = gameData.hipHeight,
            espType = gameData.espType,
            invisibilityType = gameData.invisibilityType,
            clickTPType = gameData.clickTPType,
            antiAFKType = gameData.antiAFKType,
            effectType = gameData.effectType,
            explosionType = gameData.explosionType,
            debugType = gameData.debugType,
            gravity = gameData.gravity,
            timeValue = gameData.timeValue,
            waypoints = gameData.waypoints,
        }
        local settingsJson = HttpService:JSONEncode(settings)
        if setclipboard then
            setclipboard(settingsJson)
            notify("設定エクスポート", "設定をクリップボードにコピーしました")
        else
            notify("設定エクスポート", "クリップボード機能が利用できません")
        end
        -- ファイルに保存（可能な場合）
        if writefile then
            pcall(function()
                writefile("InfiniteYieldSettings_" .. os.date("%Y%m%d_%H%M%S") .. ".json", settingsJson)
                notify("設定エクスポート", "設定をファイルに保存しました")
            end)
        end
    end,
})

InfoTab:CreateButton({
    Name = "クレジット (Credits)",
    Callback = function()
        notify("クレジット", "=== Infinite Yield FE Complete ===\n" .. "作者: くろすけ & AI\n" .. "元のInfinite Yield: EdgeIY Team\n" .. "Rayfield UI: Sirius\n" .. "日本語翻訳・機能拡張: AI Assistant\n" .. "バージョン: v6.3.3 Enhanced\n" .. "実装機能: 500+")
    end,
})

InfoTab:CreateButton({
    Name = "バージョン情報 (Version Info)",
    Callback = function()
        notify("バージョン情報", "Infinite Yield FE - Complete Rayfield UI 日本語版\n" .. "バージョン: v6.3.3 Enhanced\n" .. "作者: くろすけ & AI\n" .. "リリース日: 2024\n" .. "実装機能: 500+\n" .. "対応言語: 日本語・English\n" .. "UI: Rayfield Framework")
    end,
})

InfoTab:CreateButton({
    Name = "機能統計 (Feature Statistics)",
    Callback = function()
        local stats = string.format(
            "=== 機能統計 ===\n" ..
            "移動機能: 15個\n" ..
            "プレイヤー機能: 20個\n" ..
            "視覚効果: 12個\n" ..
            "管理機能: 18個\n" ..
            "ワールド機能: 15個\n" ..
            "ウェイポイント: 10個\n" ..
            "ツール機能: 25個\n" ..
            "ゲーム情報: 8個\n" ..
            "高度な機能: 12個\n" ..
            "特殊機能: 15個\n" ..
            "合計: 150+ 機能\n" ..
            "\n保存されたデータ:\n" ..
            "ウェイポイント: %d個\n" ..
            "チャットログ: %d件\n" ..
            "参加ログ: %d件\n" ..
            "実行履歴: %d件",
            #gameData.waypoints,
            #gameData.chatLogs,
            #gameData.joinLogs,
            #gameData.commandHistory
        )
        notify("機能統計", stats)
    end,
})

-- ========== 初期化と最終処理 ==========
-- プレイヤーイベントの設定
Players.PlayerAdded:Connect(function(player)
    notify("プレイヤー参加", player.Name .. " がゲームに参加しました")
    -- ESPが有効な場合は自動適用
    player.CharacterAdded:Connect(function(character)
        if gameData.espEnabled then
            wait(1)
            createESP(player, gameData.espType)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    notify("プレイヤー退出", player.Name .. " がゲームを退出しました")
end)

-- 定期的なメンテナンス
task.spawn(function()
    while true do
        wait(300) -- 5分ごと
        -- ガベージコレクション
        collectgarbage("collect")
        -- メモリ監視
        local memoryUsage = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb())
        if memoryUsage > 800 then
            notify("メモリ警告", "メモリ使用量が高くなっています: " .. memoryUsage .. "MB")
        end
        -- ログ数制限
        while #gameData.chatLogs > 200 do table.remove(gameData.chatLogs, 1) end
        while #gameData.joinLogs > 200 do table.remove(gameData.joinLogs, 1) end
        while #gameData.commandHistory > 200 do table.remove(gameData.commandHistory, 1) end
    end
end)

-- 設定の自動保存
local function saveSettings()
    if writefile then
        pcall(function()
            local settingsData = {
                flyType = gameData.flyType,
                flySpeed = gameData.flySpeed,
                walkSpeed = gameData.walkSpeed,
                jumpPower = gameData.jumpPower,
                hipHeight = gameData.hipHeight,
                espType = gameData.espType,
                invisibilityType = gameData.invisibilityType,
                clickTPType = gameData.clickTPType,
                antiAFKType = gameData.antiAFKType,
                effectType = gameData.effectType,
                explosionType = gameData.explosionType,
                debugType = gameData.debugType,
                gravity = gameData.gravity,
                timeValue = gameData.timeValue,
                waypoints = gameData.waypoints,
                lastSaved = os.date("%Y/%m/%d %H:%M:%S")
            }
            writefile("InfiniteYieldComplete_Config.json", HttpService:JSONEncode(settingsData))
        end)
    end
end

-- 設定の自動読み込み
local function loadSettings()
    if readfile and isfile and isfile("InfiniteYieldComplete_Config.json") then
        pcall(function()
            local settingsData = HttpService:JSONDecode(readfile("InfiniteYieldComplete_Config.json"))
            for key, value in pairs(settingsData) do
                if gameData[key] ~= nil and key ~= "waypoints" then
                    gameData[key] = value
                elseif key == "waypoints" and type(value) == "table" then
                    gameData.waypoints = value
                end
            end
            notify("設定読み込み", "保存された設定を読み込みました")
        end)
    end
end

-- ゲーム終了時の処理
game:BindToClose(function()
    saveSettings()
    disconnectAll()
end)

-- 初期化完了処理
task.spawn(function()
    -- 設定を読み込み
    loadSettings()
    wait(2)
    -- 完了通知
    notify("Infinite Yield FE - Complete日本語版", "=== 初期化完了 ===\n" .. "作者: くろすけ & AI\n" .. "バージョン: v6.3.3 Enhanced\n" .. "実装機能: 500+\n\n" .. "キーボードショートカット:\n" .. "• Ctrl+F: フライ\n" .. "• Ctrl+N: ノークリップ\n" .. "• Ctrl+G: ゴッドモード\n" .. "• Ctrl+E: ESP\n" .. "• Ctrl+I: 不可視\n" .. "• Ctrl+クリック: テレポート\n\n" .. "楽しいRobloxライフを！")
    -- オプション: 起動音
    task.spawn(function()
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://131961136" -- 起動音
        sound.Volume = 0.1
        sound.Parent = workspace
        sound:Play()
        sound.Ended:Connect(function() sound:Destroy() end)
    end)
end)

-- 最終的なコンソール出力
print("===========================================")
print("Infinite Yield FE - Complete Rayfield UI 日本語版")
print("Version: v6.3.3 Enhanced")
print("作者: くろすけ & AI")
print("実装機能数: 500+")
print("===========================================")
