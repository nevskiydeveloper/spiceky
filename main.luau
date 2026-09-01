--full opensource

local Environment = getgenv()
local PreviousRuntime = Environment.ParsaRuntime
if type(PreviousRuntime) == "table" and typeof(PreviousRuntime.Unload) == "function" then
    pcall(PreviousRuntime.Unload)
end
local Runtime = {
    Alive = true,
}
Environment.ParsaRuntime = Runtime
local ReGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/nevskiydeveloper/ReGui/refs/heads/main/ReGui.lua"))()
local PrefabsId = "rbxassetid://" .. 122589944740561
local InsertService = game:GetService("InsertService")
ReGui:Init({
    Prefabs = InsertService:LoadLocalAsset(PrefabsId)
})
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
Environment.ParsaUIBindKey = Environment.ParsaUIBindKey or Enum.KeyCode.Insert
local DefaultSettings = {
    SilentEnabled = false,
    WallCheck = false,
    Wallbang = false,
    HitPart = "Head",
    ShowFov = false,
    FOVRadius = 130,
    FOVColor = Color3.fromRGB(255, 0, 0),
    ESPEnabled = false,
    ESPBoxes = false,
    ESPSkeletons = false,
    ESPNames = false,
    ESPDistance = false,
    ESPMaxDistance = 2500,
    BoxColor = Color3.fromRGB(0, 186, 186),
    OutlineColor = Color3.fromRGB(15, 15, 15),
    NameColor = Color3.fromRGB(255, 255, 255),
    DistanceColor = Color3.fromRGB(179, 179, 179),
    TeamCheck = false,
    PredictionEnabled = true,
    PredictionTime = 0.12,
    TargetLockTime = 0.3,
}
local Settings = type(Environment.ParsaIntegratedSettings) == "table"
    and Environment.ParsaIntegratedSettings
    or {}
for key, value in pairs(DefaultSettings) do
    if Settings[key] == nil then
        Settings[key] = value
    end
end
Environment.ParsaIntegratedSettings = Settings
Environment.ParsaTeamColors = Environment.ParsaTeamColors or {
    ["Terrorists"] = Color3.fromRGB(204, 170, 80),
    ["Counter-Terrorists"] = Color3.fromRGB(100, 149, 200)
}
Environment.ParsaSilentTarget = nil
Environment.ParsaLastTargetTime = 0
Environment.ParsaCurrentTargetPlayer = nil
if type(Environment.ParsaEspInstances) ~= "table" then
    Environment.ParsaEspInstances = {}
end
local espInstances = Environment.ParsaEspInstances
local Window
local UIBind
local renderConnection
local playerRemovingConnection
local FOVCircle
local removeESP
local unloadScript
local currentLocalTeam = nil
local function destroyWindow()
    if UIBind and UIBind.Connection then
        UIBind.Connection:Disconnect()
        UIBind.Connection = nil
    end
    UIBind = nil
    if Window then
        pcall(function()
            Window:SetVisible(false)
            Window:Remove()
        end)
        Window = nil
    end
end
local function get_player_team(player)
    if not player then return nil end
    local ok, teamName = pcall(function() return player.Team and player.Team.Name or nil end)
    if ok and (teamName == "Terrorists" or teamName == "Counter-Terrorists") then return teamName end
    local character = player.Character
    if character then
        local attr = character:GetAttribute("Team")
        if attr == "Terrorists" or attr == "Counter-Terrorists" then return attr end
        local parentName = character.Parent and character.Parent.Name
        if parentName == "Terrorists" or parentName == "Counter-Terrorists" then return parentName end
    end
    return nil
end
getgenv().ParsaGetTeam = get_player_team
Window = ReGui:TabsWindow({
    Title = "spiceky.su",
    Size = UDim2.fromOffset(370, 470),
    Position = UDim2.new(0.5, 0, 0, 70),
    Visible = true,
}):Center()
local MainTab = Window:CreateTab({ Name = "Main" })
MainTab:Checkbox({
    Label = "Silent Aim",
    Value = Settings.SilentEnabled,
    Callback = function(self, Value) Settings.SilentEnabled = Value end,
})
MainTab:Checkbox({
    Label = "Wallbang",
    Value = Settings.Wallbang,
    Callback = function(self, Value) Settings.Wallbang = Value end,
})
MainTab:Combo({
    Label = "Target Hitpart",
    Selected = Settings.HitPart,
    Items = {"Head", "UpperTorso", "LowerTorso"},
    Callback = function(_, Value) Settings.HitPart = Value end,
})
MainTab:Checkbox({
    Label = "Team Check",
    Value = Settings.TeamCheck,
    Callback = function(_, Value) Settings.TeamCheck = Value end,
})
MainTab:Checkbox({
    Label = "Show Fov",
    Value = Settings.ShowFov,
    Callback = function(self, Value) Settings.ShowFov = Value end,
})
MainTab:SliderInt({
    Label = "FOV Radius",
    Value = Settings.FOVRadius,
    Minimum = 10,
    Maximum = 500,
    Callback = function(self, Value) Settings.FOVRadius = Value end,
})
MainTab:Checkbox({
    Label = "Prediction",
    Value = Settings.PredictionEnabled,
    Callback = function(self, Value) Settings.PredictionEnabled = Value end,
})
MainTab:SliderFloat({
    Label = "Prediction Time",
    Value = Settings.PredictionTime,
    Minimum = 0,
    Maximum = 0.5,
    Format = "%.2f s",
    Callback = function(self, Value) Settings.PredictionTime = Value end,
})
local VisualsTab = Window:CreateTab({ Name = "Visuals" })
VisualsTab:Checkbox({
    Label = "ESP",
    Value = Settings.ESPEnabled,
    Callback = function(self, Value) Settings.ESPEnabled = Value end,
})
VisualsTab:Checkbox({
    Label = "Draw Boxes",
    Value = Settings.ESPBoxes,
    Callback = function(self, Value) Settings.ESPBoxes = Value end,
})
VisualsTab:Checkbox({
    Label = "Draw Skeletons",
    Value = Settings.ESPSkeletons,
    Callback = function(self, Value) Settings.ESPSkeletons = Value end,
})
VisualsTab:Checkbox({
    Label = "Display Names",
    Value = Settings.ESPNames,
    Callback = function(self, Value) Settings.ESPNames = Value end,
})
VisualsTab:Checkbox({
    Label = "Display Distance",
    Value = Settings.ESPDistance,
    Callback = function(self, Value) Settings.ESPDistance = Value end,
})
VisualsTab:SliderInt({
    Label = "Max Render Distance",
    Value = Settings.ESPMaxDistance,
    Minimum = 100,
    Maximum = 5000,
    Callback = function(self, Value) Settings.ESPMaxDistance = Value end,
})
local SettingsTab = Window:CreateTab({ Name = "Settings" })
UIBind = SettingsTab:Keybind({
    Label = "UI bind",
    Value = Environment.ParsaUIBindKey,
    IgnoreGameProcessed = true,
    Callback = function()
        if Window then
            Window:ToggleVisibility()
        end
    end,
    OnKeybindSet = function(_, keyCode)
        Environment.ParsaUIBindKey = keyCode
    end,
})
SettingsTab:Button({
    Text = "Unload Script",
    Callback = function()
        unloadScript()
    end,
})
local BONE_MAP_R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}
local BONE_MAP_R6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
}
local function hideESPObject(obj)
    if not obj then return end
    pcall(function() obj.Visible = false end)
end
local function destroyObject(obj)
    if not obj then return end
    pcall(function()
        obj.Visible = false
        if typeof(obj.Remove) == "function" then
            obj:Remove()
        elseif typeof(obj.Destroy) == "function" then
            obj:Destroy()
        end
    end)
end
local function createESP(player)
    if not player or espInstances[player] then return end
    local objects = {
        BoxOutline = Drawing.new("Square"),
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Bones = {}
    }
    objects.BoxOutline.Thickness = 2
    objects.BoxOutline.Filled = false
    objects.BoxOutline.Transparency = 0.5
    objects.BoxOutline.Color = Settings.OutlineColor
    objects.BoxOutline.Visible = false
    objects.Box.Thickness = 1
    objects.Box.Filled = false
    objects.Box.Transparency = 1
    objects.Box.Visible = false
    objects.Name.Center = true
    objects.Name.Outline = true
    objects.Name.Font = 1
    objects.Name.Size = 13
    objects.Name.Color = Settings.NameColor
    objects.Name.Visible = false
    objects.Distance.Center = true
    objects.Distance.Outline = true
    objects.Distance.Font = 1
    objects.Distance.Size = 12
    objects.Distance.Color = Settings.DistanceColor
    objects.Distance.Visible = false
    for i = 1, 15 do
        local boneLine = Drawing.new("Line")
        boneLine.Thickness = 1
        boneLine.Transparency = 1
        boneLine.Visible = false
        table.insert(objects.Bones, boneLine)
    end
    espInstances[player] = objects
end
removeESP = function(player)
    if type(Environment.ParsaEspInstances) ~= "table" then
        Environment.ParsaEspInstances = {}
    end
    local objects = Environment.ParsaEspInstances[player]
    if not objects then return end
    for _, obj in pairs(objects) do
        if type(obj) == "table" then
            for _, bone in pairs(obj) do
                destroyObject(bone)
            end
        else
            destroyObject(obj)
        end
    end
    Environment.ParsaEspInstances[player] = nil
    if espInstances then
        espInstances[player] = nil
    end
end
Environment.ParsaRemoveEsp = removeESP
local function hideESPObjects(objects)
    if not objects then return end
    for _, object in pairs(objects) do
        if type(object) == "table" then
            for _, bone in pairs(object) do
                hideESPObject(bone)
            end
        else
            hideESPObject(object)
        end
    end
end
local function hideAllESP()
    for _, objects in pairs(espInstances) do
        hideESPObjects(objects)
    end
end
local function updateESP()
    local myTeam = currentLocalTeam or get_player_team(LocalPlayer)
    local cameraPosition = Camera.CFrame.Position
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            if espInstances[player] then removeESP(player) end
            continue
        end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character.PrimaryPart)
        local playerTeam = get_player_team(player)
        local alive = character
            and rootPart
            and not character:GetAttribute("Dead")
            and (not humanoid or humanoid.Health > 0)
        local allowed = alive
            and (not Settings.TeamCheck or myTeam == nil or playerTeam ~= myTeam)
            and (cameraPosition - rootPart.Position).Magnitude <= Settings.ESPMaxDistance
        local objects = espInstances[player]
        if not allowed then
            hideESPObjects(objects)
            continue
        end
        if not objects then
            createESP(player)
            objects = espInstances[player]
        end
        if not objects then continue end
        local rootScreen, rootVisible = Camera:WorldToViewportPoint(rootPart.Position)
        if not rootVisible or rootScreen.Z <= 0 then
            hideESPObjects(objects)
            continue
        end
        local targetColor = Environment.ParsaTeamColors[playerTeam] or Settings.BoxColor
        local head = character:FindFirstChild("Head")
        local headScreen = Camera:WorldToViewportPoint(head and head.Position or rootPart.Position + Vector3.new(0, 2, 0))
        local feetScreen = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
        local height = math.max(2, math.abs(headScreen.Y - feetScreen.Y))
        local width = height / 1.6
        local boxPosition = Vector2.new(rootScreen.X - width / 2, headScreen.Y)
        local boxSize = Vector2.new(width, height)
        objects.Box.Visible = Settings.ESPBoxes
        objects.BoxOutline.Visible = Settings.ESPBoxes
        if Settings.ESPBoxes then
            objects.Box.Position = boxPosition
            objects.Box.Size = boxSize
            objects.Box.Color = targetColor
            objects.BoxOutline.Position = boxPosition
            objects.BoxOutline.Size = boxSize
        end
        local boneMap = character:FindFirstChild("UpperTorso") and BONE_MAP_R15 or BONE_MAP_R6
        for index, boneLine in ipairs(objects.Bones) do
            local bonePair = boneMap[index]
            local partA = bonePair and character:FindFirstChild(bonePair[1])
            local partB = bonePair and character:FindFirstChild(bonePair[2])
            if Settings.ESPSkeletons and partA and partB then
                local screenA, visibleA = Camera:WorldToViewportPoint(partA.Position)
                local screenB, visibleB = Camera:WorldToViewportPoint(partB.Position)
                boneLine.Visible = visibleA and visibleB and screenA.Z > 0 and screenB.Z > 0
                if boneLine.Visible then
                    boneLine.From = Vector2.new(screenA.X, screenA.Y)
                    boneLine.To = Vector2.new(screenB.X, screenB.Y)
                    boneLine.Color = targetColor
                end
            else
                boneLine.Visible = false
            end
        end
        objects.Name.Visible = Settings.ESPNames
        if Settings.ESPNames then
            objects.Name.Text = player.Name
            objects.Name.Position = Vector2.new(rootScreen.X, boxPosition.Y - 15)
        end
        objects.Distance.Visible = Settings.ESPDistance
        if Settings.ESPDistance then
            objects.Distance.Text = tostring(math.floor((cameraPosition - rootPart.Position).Magnitude)) .. "m"
            objects.Distance.Position = Vector2.new(rootScreen.X, boxPosition.Y + height + 2)
        end
    end
end
playerRemovingConnection = Players.PlayerRemoving:Connect(removeESP)
FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64
FOVCircle.Color = Settings.FOVColor
FOVCircle.Visible = false
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
local function isVisible(targetPart, ignoreWalls)
    if ignoreWalls then return true end
    if not targetPart or not targetPart.Parent or not Camera then return false end
    rayParams.FilterDescendantsInstances = LocalPlayer.Character and {LocalPlayer.Character} or {}
    local origin = Camera.CFrame.Position
    local result = Workspace:Raycast(origin, targetPart.Position - origin, rayParams)
    if not result then return true end
    local targetCharacter = targetPart:FindFirstAncestorOfClass("Model")
    return targetCharacter ~= nil and result.Instance:IsDescendantOf(targetCharacter)
end
local function getTargetCandidate(player, hitPartName, fov, teamCheck, wallCheck, maxDistance)
    if not player or player == LocalPlayer then return nil end
    local character = player.Character
    if not character
        or character:GetAttribute("Dead")
        or character:GetAttribute("Invincible")
        or (character.Parent and character.Parent.Name == "Debris") then
        return nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health <= 0 then return nil end
    local myTeam = currentLocalTeam or get_player_team(LocalPlayer)
    local playerTeam = get_player_team(player)
    if teamCheck and myTeam ~= nil and playerTeam == myTeam then return nil end
    local targetPart = character:FindFirstChild(hitPartName)
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
        or character.PrimaryPart
    if not targetPart then return nil end
    if (Camera.CFrame.Position - targetPart.Position).Magnitude > maxDistance then return nil end
    local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
    if not onScreen or screenPoint.Z <= 0 then return nil end
    local screenCenter = Camera.ViewportSize / 2
    local screenPosition = Vector2.new(screenPoint.X, screenPoint.Y)
    local screenDistance = (screenPosition - screenCenter).Magnitude
    if screenDistance > fov then return nil end
    if wallCheck and not isVisible(targetPart, false) then return nil end
    return {
        Player = player,
        Part = targetPart,
        ScreenPosition = screenPosition,
        ScreenDistance = screenDistance,
    }
end
local function findBestTarget(hitPartName, fov, teamCheck, wallCheck, maxDistance, preferredPlayer)
    if preferredPlayer then
        local preferred = getTargetCandidate(preferredPlayer, hitPartName, fov * 1.15, teamCheck, wallCheck, maxDistance)
        if preferred then return preferred end
    end
    local bestTarget = nil
    for _, player in ipairs(Players:GetPlayers()) do
        local candidate = getTargetCandidate(player, hitPartName, fov, teamCheck, wallCheck, maxDistance)
        if candidate and (not bestTarget or candidate.ScreenDistance < bestTarget.ScreenDistance) then
            bestTarget = candidate
        end
    end
    return bestTarget
end
local bulletSpeed = nil
local function getBulletSpeed()
    if bulletSpeed then return bulletSpeed end
    for _, obj in next, getgc(true) do
        if type(obj) == "table" and rawget(obj, "BulletSpeed") ~= nil then
            local speed = rawget(obj, "BulletSpeed")
            if typeof(speed) == "number" and speed > 0 then
                bulletSpeed = speed
                return speed
            end
        end
    end
    return math.huge
end
local silentNextScan = 0
local espWasEnabled = next(espInstances) ~= nil
local function updateSilentTarget(now)
    if not Settings.SilentEnabled or not LocalPlayer.Character then
        Environment.ParsaSilentTarget = nil
        Environment.ParsaCurrentTargetPlayer = nil
        return
    end
    if now < silentNextScan then return end
    silentNextScan = now + 0.04
    local fov = Settings.ShowFov and Settings.FOVRadius or math.huge
    local previousPlayer = Environment.ParsaCurrentTargetPlayer
    local lockActive = previousPlayer
        and now - Environment.ParsaLastTargetTime < Settings.TargetLockTime
    local target = findBestTarget(
        Settings.HitPart,
        fov,
        Settings.TeamCheck,
        not Settings.Wallbang,
        Settings.ESPMaxDistance,
        lockActive and previousPlayer or nil
    )
    Environment.ParsaSilentTarget = target and target.Part or nil
    Environment.ParsaCurrentTargetPlayer = target and target.Player or nil
    if target and (target.Player ~= previousPlayer or not lockActive) then
        Environment.ParsaLastTargetTime = now
    end
end
renderConnection = RunService.RenderStepped:Connect(function()
    if not Runtime.Alive then return end
    local now = os.clock()
    Camera = Workspace.CurrentCamera
    currentLocalTeam = get_player_team(LocalPlayer)
    if not Camera then
        FOVCircle.Visible = false
        return
    end
    local screenCenter = Camera.ViewportSize / 2
    FOVCircle.Visible = Settings.ShowFov
    if FOVCircle.Visible then
        FOVCircle.Position = screenCenter
        FOVCircle.Radius = Settings.FOVRadius
        FOVCircle.Color = Settings.FOVColor
    end
    if Settings.ESPEnabled then
        updateESP()
        espWasEnabled = true
    elseif espWasEnabled then
        hideAllESP()
        espWasEnabled = false
    end
    updateSilentTarget(now)
end)
unloadScript = function()
    if not Runtime.Alive then return end
    Runtime.Alive = false
    if renderConnection then
        renderConnection:Disconnect()
        renderConnection = nil
    end
    if playerRemovingConnection then
        playerRemovingConnection:Disconnect()
        playerRemovingConnection = nil
    end
    local playersToRemove = {}
    for player in pairs(espInstances) do
        table.insert(playersToRemove, player)
    end
    for _, player in ipairs(playersToRemove) do
        removeESP(player)
    end
    Environment.ParsaEspInstances = {}
    espInstances = Environment.ParsaEspInstances
    destroyObject(FOVCircle)
    FOVCircle = nil
    Environment.ParsaSilentTarget = nil
    Environment.ParsaCurrentTargetPlayer = nil
    Environment.ParsaLastTargetTime = 0
    Environment.ParsaRemoveEsp = nil
    destroyWindow()
    if Environment.ParsaRuntime == Runtime then
        Environment.ParsaRuntime = nil
    end
end
Runtime.Unload = unloadScript
task.spawn(function()
    if typeof(hookfunction) ~= "function" or typeof(getgc) ~= "function" then
        warn("Silent aim requires hookfunction and getgc")
        return
    end
    local bulletClass = nil
    local attempts = 0
    while Runtime.Alive and attempts < 60 do
        for _, obj in next, getgc(true) do
            if type(obj) == "table" and typeof(rawget(obj, "_performRaycast")) == "function" and rawget(obj, "getTrueSpread") ~= nil then
                bulletClass = obj
                break
            end
        end
        if bulletClass then break end
        task.wait(0.5)
        attempts += 1
    end
    if not Runtime.Alive then return end
    if not bulletClass then
        warn("Bullet class not found")
        return
    end
    bulletSpeed = getBulletSpeed()
    local oldRaycast
    oldRaycast = hookfunction(bulletClass._performRaycast, function(...)
        local returns = table.pack(oldRaycast(...))
        local result = returns[1]
        local SilentTarget = Environment.ParsaSilentTarget
        if Runtime.Alive and Settings.SilentEnabled and SilentTarget and type(result) == "table" then
            pcall(function()
                local hits = rawget(result, "Hits")
                if type(hits) ~= "table" or not SilentTarget.Parent then return end
                local targetPos = SilentTarget.Position
                if Settings.PredictionEnabled then
                    local targetVelocity = SilentTarget.AssemblyLinearVelocity or Vector3.zero
                    local travelTime = 0
                    if bulletSpeed and bulletSpeed < math.huge then
                        local distToTarget = (Camera.CFrame.Position - targetPos).Magnitude
                        travelTime = distToTarget / bulletSpeed
                    end
                    local totalDelay = Settings.PredictionTime + travelTime
                    targetPos = targetPos + targetVelocity * totalDelay
                end
                local lastIndex = nil
                for index, hit in pairs(hits) do
                    if type(hit) == "table" then
                        if lastIndex == nil or index > lastIndex then lastIndex = index end
                    end
                end
                local finalHit = lastIndex and hits[lastIndex]
                if type(finalHit) ~= "table" then return end
                finalHit.Instance = SilentTarget
                finalHit.Position = targetPos
                if finalHit.Exit ~= nil then finalHit.Exit = false end
                local origin = rawget(result, "Origin")
                if typeof(origin) == "Vector3" then
                    local delta = targetPos - origin
                    local length = delta.Magnitude
                    if length > 0.001 then
                        result.Distance = length
                        result.Direction = delta.Unit
                        local unit = delta.Unit
                        for index, hit in pairs(hits) do
                            if index ~= lastIndex and type(hit) == "table" and typeof(hit.Position) == "Vector3" then
                                local along = (hit.Position - origin):Dot(unit)
                                if along > length then
                                    hit.Position = origin + unit * (length * 0.5)
                                end
                            end
                        end
                    end
                end
            end)
        end
        return table.unpack(returns, 1, returns.n)
    end)
end)
