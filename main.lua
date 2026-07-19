local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local groupId = 209672907

-- VERIFICACIÓN DE SEGURIDAD
if not Players.LocalPlayer:IsInGroup(groupId) then
    for i = 1, 3 do -- Reducido para evitar spam innecesario
        StarterGui:SetCore("SendNotification", {
            Title = "Acceso Denegado",
            Text = "No estás en el grupo.",
            Duration = 5
        })
    end
    return -- Termina la ejecución limpiamente en vez de colgar el hilo con un while true
end

-- VARIABLES GLOBALES
getgenv().Prediction = 0.150   
getgenv().AutoPrediction = true
getgenv().JumpPrediction = 0.35  
getgenv().FallPrediction = 0.35  
getgenv().FOV = 80   
getgenv().AimKey = "q"

-- CONFIGURACIÓN DEL REACH
getgenv().ReachEnabled = true
getgenv().ReachValue = 5.5
local MAX_HEIGHT_DIFF = 5 

getgenv().EspEnabled = false
local pingHistory = {}         
local SilentAim = true
local VisualsEnabled = false 

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local FILE_NAME = "PremiumMultiHack_WL.json"

getgenv().DontShootThesePeople = {}

-- CARGAR Y GUARDAR WHITELIST
local function LoadWhitelist()
    local success, result = pcall(function()
        if isfile and isfile(FILE_NAME) then
            return HttpService:JSONDecode(readfile(FILE_NAME))
        end
    end)
    if success and type(result) == "table" then
        getgenv().DontShootThesePeople = result
    else
        getgenv().DontShootThesePeople = {"plojugg028", "itsbrygodx"}
    end
end

local function SaveWhitelist()
    if writefile then
        pcall(function()
            writefile(FILE_NAME, HttpService:JSONEncode(getgenv().DontShootThesePeople))
        end)
    end
end

LoadWhitelist()

local function GetNormalMousePosition()
    local mouseLocation = UserInputService:GetMouseLocation()
    local unitRay = Camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    if LocalPlayer.Character then
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    end
    
    local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
    return raycastResult and raycastResult.Position or (unitRay.Origin + (unitRay.Direction * 1000))
end

------------------------------------------------------------------------
-- INTERFAZ GRÁFICA (Simplificada la inicialización)
------------------------------------------------------------------------
if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("PremiumMenu") then
    LocalPlayer.PlayerGui.PremiumMenu:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PremiumMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 340) 
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 8)
MainCorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "PREMIUM MULTI-HACK // [Ctrl + K]"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local TabPanel = Instance.new("Frame")
TabPanel.Size = UDim2.new(0, 125, 1, -35)
TabPanel.Position = UDim2.new(0, 0, 0, 35)
TabPanel.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
TabPanel.BorderSizePixel = 0
TabPanel.Parent = MainFrame

local TabList = Instance.new("UIListLayout")
TabList.Parent = TabPanel
TabList.Padding = UDim.new(0, 2)

local ContentPage = Instance.new("Frame")
ContentPage.Size = UDim2.new(1, -135, 1, -45)
ContentPage.Position = UDim2.new(0, 130, 0, 40)
ContentPage.BackgroundTransparency = 1
ContentPage.Parent = MainFrame

local function CreatePage()
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 4
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.Parent = ContentPage
    
    local List = Instance.new("UIListLayout")
    List.Parent = Page
    List.Padding = UDim.new(0, 6)
    
    return Page, List
end

local PageAimbot, ListAimbot = CreatePage()
local PageReach, ListReach = CreatePage()
local PageVisuals, ListVisuals = CreatePage()
local PageWhitelist, ListWhitelist = CreatePage()

local allPages = {PageAimbot, PageReach, PageVisuals, PageWhitelist}

local function OpenPage(pageToShow)
    for _, page in ipairs(allPages) do page.Visible = false end
    pageToShow.Visible = true
end

local function CreateTabButton(name, targetPage)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 32)
    Btn.BackgroundColor3 = Color3.fromRGB(24, 24, 29)
    Btn.BorderSizePixel = 0
    Btn.Text = "  " .. name
    Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 11
    Btn.TextXAlignment = Enum.TextXAlignment.Left
    Btn.Parent = TabPanel
    Btn.MouseButton1Click:Connect(function() OpenPage(targetPage) end)
end

CreateTabButton("Silent Aim", PageAimbot)
CreateTabButton("Melee Reach", PageReach)
CreateTabButton("Visuals / ESP", PageVisuals)
CreateTabButton("Whitelist", PageWhitelist)
OpenPage(PageAimbot)

local function CreateSectionLabel(parent, text)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -5, 0, 20)
    Label.BackgroundTransparency = 1
    Label.Text = "—— " .. text:upper() .. " ——"
    Label.TextColor3 = Color3.fromRGB(120, 120, 140)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 10
    Label.TextXAlignment = Enum.TextXAlignment.Center
    Label.Parent = parent
end

local function CreateToggle(parent, text, defaultState, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(1, -5, 0, 35)
    Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent
    
    local Corner = Instance.new("UICorner") Target = part
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    
                                    return Target
                                end
                                
                                local function GetDirectionModifier(rootPart, velocity)
                                    if velocity.Magnitude < 1 then return 1 end
                                    local lookDir = rootPart.CFrame.LookVector
                                    local moveDir = velocity.Unit
                                    return math.abs(lookDir:Dot(moveDir)) < 0.3 and 0.5 or 1
                                end
                                
                                local function CalculatePredictedPosition(targetPart)
                                    if not targetPart then return nil end
                                    local rootPart = targetPart.Parent:FindFirstChild("HumanoidRootPart")
                                    local velocity = rootPart and rootPart.AssemblyLinearVelocity or Vector3.new(0,0,0)
                                    local currentPrediction = getgenv().Prediction
                                    
                                    if getgenv().AutoPrediction then
                                        local rawPing = stats():FindFirstChild("Network") 
                                            and stats().Network:FindFirstChild("ServerStatsItem") 
                                            and stats().Network.ServerStatsItem:FindFirstChild("Data Ping") 
                                            and stats().Network.ServerStatsItem["Data Ping"]:GetValue() or 70
                                            
                                        table.insert(pingHistory, rawPing)
                                        if #pingHistory > 8 then table.remove(pingHistory, 1) end
                                        
                                        local pingSum = 0
                                        for i = 1, #pingHistory do pingSum = pingSum + pingHistory[i] end
                                        local steppedPing = math.clamp(math.round((pingSum / #pingHistory) / 5) * 5, 0, 220)
                                        currentPrediction = (steppedPing * 0.00135) + 0.052
                                    end
                                    
                                    local verticalVelocity = velocity.Y
                                    if verticalVelocity > 3 then 
                                        verticalVelocity = verticalVelocity * getgenv().JumpPrediction 
                                    elseif verticalVelocity < -5 then 
                                        verticalVelocity = verticalVelocity * getgenv().FallPrediction 
                                    end
                                
                                    local directionMod = GetDirectionModifier(rootPart, velocity)
                                    local stabilizedVelocity = Vector3.new(velocity.X * directionMod, verticalVelocity, velocity.Z * directionMod)
                                    return targetPart.Position + (stabilizedVelocity * currentPrediction) + Vector3.new(0, -0.5, 0)
                                end
                                
                                ------------------------------------------------------------------------
                                -- LOOPS DE RENDIMIENTO OPTIMIZADOS
                                ------------------------------------------------------------------------
                                
                                -- 1. Loop de simulación física pesada (Reach/Hitbox) corrido a intervalos fijos controlados fuera del Render
                                task.spawn(function()
                                    local raycastParams = RaycastParams.new()
                                    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                    raycastParams.IgnoreWater = true
                                
                                    while true do
                                        task.wait(0.05) -- Cambiado a 20Hz. Suficiente para chequear hitboxes sin ahorcar la CPU.
                                        
                                        pcall(function()
                                            local character = LocalPlayer.Character
                                            local hrp = character and character:FindFirstChild("HumanoidRootPart")
                                            local sword = character and character:FindFirstChildOfClass("Tool")
                                            local hasSword = hrp and sword and sword:FindFirstChild("Handle")
                                
                                            for _, v in ipairs(Players:GetPlayers()) do
                                                if v ~= LocalPlayer and v.Character and not table.find(getgenv().DontShootThesePeople, v.Name) then
                                                    local targetChar = v.Character
                                                    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                                                    local torso = targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso")
                                                    
                                                    if targetHRP and torso then
                                                        local realLeg = targetChar:FindFirstChild("Right Leg")
                                                        local hitboxLeg = targetChar:FindFirstChild("RightLeg_Hitbox")
                                                        
                                                        -- Optimización clave: Solo mutar el árbol físico una vez, no re-crearlo en cada iteración
                                                        if realLeg and not hitboxLeg then
                                                            realLeg.Name = "RightLeg_Hitbox"
                                                            realLeg.Transparency = 1
                                                            realLeg.CanCollide = false
                                                            
                                                            local visualLeg = Instance.new("Part")
                                                            visualLeg.Name = "Right Leg"
                                                            visualLeg.Size = Vector3.new(1, 2, 1)
                                                            visualLeg.CanCollide = false
                                                            visualLeg.BrickColor = realLeg.BrickColor
                                                            visualLeg.Material = realLeg.Material
                                                            visualLeg.Parent = targetChar
                                                            
                                                            local originalHip = torso:FindFirstChild("Right Hip")
                                                            if originalHip then originalHip.Part1 = visualLeg end
                                                            
                                                            local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
                                                            if humanoid then
                                                                humanoid:BuildRigFromAttachments()
                                                                humanoid.Died:Connect(function()
                                                                    if visualLeg then visualLeg:Destroy() end
                                                                end)
                                                            end
                                                            hitboxLeg = realLeg
                                                        end
                                                        
                                                        if hitboxLeg then
                                                            hitboxLeg.CanCollide = false
                                                            
                                                            if getgenv().ReachEnabled and hasSword then
                                                                local minHeight = hrp.Position.Y - 0.5
                                                                local maxHeight = hrp.Position.Y + MAX_HEIGHT_DIFF
                                                                
                                                                if targetHRP.Position.Y >= minHeight and targetHRP.Position.Y <= maxHeight then
                                                                    local direction = targetHRP.Position - hrp.Position
                                                                    if direction.Magnitude <= getgenv().ReachValue then
                                                                        raycastParams.FilterDescendantsInstances = {character, targetChar}
                                                                        if not workspace:Raycast(hrp.Position, direction, raycastParams) then
                                                                            hitboxLeg.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
                                                                            continue
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                            hitboxLeg.CFrame = targetHRP.CFrame * CFrame.new(0, -15, 0)
                                                        end
                                                    end
                                                end
                                            end
                                        end)
                                    end
                                end)
                                
                                -- 2. Unificación de renderizado en un único RenderStepped global para evitar sobrecarga de callbacks
                                RunService.RenderStepped:Connect(function()
                                    local MouseLocation = UserInputService:GetMouseLocation()
                                    
                                    -- FOV y Predicción visual
                                    if VisualsEnabled then
                                        FOV_CIRCLE.Position = Vector2.new(MouseLocation.X, MouseLocation.Y)
                                        FOV_CIRCLE.Radius = getgenv().FOV
                                        FOV_CIRCLE.Visible = true
                                        
                                        local target = SilentAim and GetClosestPlayerToMouse() or nil
                                        local predictedPos3D = target and CalculatePredictedPosition(target)
                                        if predictedPos3D then
                                            local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos3D)
                                            if onScreen then
                                                PREDICTION_DOT.Position = Vector2.new(screenPos.X, screenPos.Y)
                                                PREDICTION_DOT.Visible = true
                                            else
                                                PREDICTION_DOT.Visible = false
                                            end
                                        else
                                            PREDICTION_DOT.Visible = false
                                        end
                                    else
                                        FOV_CIRCLE.Visible = false
                                        PREDICTION_DOT.Visible = false
                                    end
                                    
                                    -- Renderizado de ESP unificado en la misma señal de refresco de pantalla
                                    for player, items in pairs(ESP_Storage) do
                                        local char = player.Character
                                        local root = char and char:FindFirstChild("HumanoidRootPart")
                                        local hum = char and char:FindFirstChild("Humanoid")
                                        
                                        if getgenv().EspEnabled and root and hum and hum.Health > 0 and not table.find(getgenv().DontShootThesePeople, player.Name) then
                                            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                                            if onScreen then
                                                local scale = 1 / (rootPos.Z * math.tan(math.rad(Camera.FieldOfView / 2))) * 1000
                                                local width, height = scale * 2.3, scale * 3.9
                                                
                                                items.Box.Size = Vector2.new(width, height)
                                                items.Box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                                                items.Box.Visible = true
                                                
                                                items.Name.Text = player.Name .. " [" .. math.floor(hum.Health) .. " HP]"
                                                items.Name.Position = Vector2.new(rootPos.X, rootPos.Y - (height / 2) - 15)
                                                items.Name.Visible = true
                                                continue
                                            end
                                        end
                                        items.Box.Visible = false
                                        items.Name.Visible = false
                                    end
                                end)
                                
                                -- 3. Heartbeat optimizado para interceptar la herramienta sin asignaciones de memoria excesivas
                                RunService.Heartbeat:Connect(function()
                                    if not SilentAim or not LocalPlayer.Character then return end
                                    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                                    if tool then
                                        local clientControl = tool:FindFirstChild("ClientControl")
                                        if clientControl and clientControl:IsA("RemoteFunction") then
                                            clientControl.OnClientInvoke = function()
                                                local target = GetClosestPlayerToMouse()
                                                return target and CalculatePredictedPosition(target) or GetNormalMousePosition()
                                            end
                                        end
                                    end
                                end)
                                
                                ------------------------------------------------------------------------
                                -- INPUTS / CONTROLES
                                ------------------------------------------------------------------------
                                UserInputService.InputBegan:Connect(function(input, gameProcessed)
                                    if input.KeyCode == Enum.KeyCode.K and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
                                        MainFrame.Visible = not MainFrame.Visible
                                        if MainFrame.Visible then UpdateWhitelistMenu() end
                                        return
                                    end
                                
                                    if gameProcessed then return end 
                                    
                                    if input.KeyCode == Enum.KeyCode[getgenv().AimKey:upper()] and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
                                        SilentAim = not SilentAim
                                        FOV_CIRCLE.Color = SilentAim and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                                    elseif input.KeyCode == Enum.KeyCode.Equals then
                                        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
                                    end
                                end)
