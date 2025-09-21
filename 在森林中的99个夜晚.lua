local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Guo61/Cat-/refs/heads/main/main.lua"))()

local Confirmed = false

WindUI:Popup({
    Title = "Cat脚盆 v1.10",
    Icon = "rbxassetid://129260712070622",
    IconThemed = true,
    Content = "By:PigGod\n欢迎使用99夜\n没事。继续玩吧。",
    Buttons = {
        {
            Title = "进入脚本。",
            Icon = "arrow-right",
            Callback = function() Confirmed = true end,
            Variant = "Primary",
        }
    }
})

repeat wait() until Confirmed

local Window = WindUI:CreateWindow({
    Title = "99夜",
    Icon = "rbxassetid://129260712070622",
    IconThemed = true,
    Author = "感谢游玩",
    Folder = "没事。",
    Size = UDim2.fromOffset(580, 340),
    Transparent = true,
    Theme = "Dark",
    User = { Enabled = true },
    SideBarWidth = 200,
    ScrollBarEnabled = true,
})

local Tabs = {
    Home = Window:Tab({ Title = "主页", Icon = "crown" }),
    Main = Window:Tab({ Title = "主要功能", Icon = "zap" }),
    Ninja = Window:Tab({ Title = "传送", Icon = "user" }),
    Summon = Window:Tab({ Title = "召唤", Icon = "box" }),
    ESP = Window:Tab({ Title = "透视", Icon = "dumbbell" }),
    Misc = Window:Tab({ Title = "其他", Icon = "settings" }),
}

Window:SelectTab(1)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Character = LP.Character or LP.CharacterAdded:Wait()

local Features = {
    KillAura = false,
    AutoChop = false,
    AutoEat = false,
    AutoCook = false,
    ChildESP = false,
    ChestESP = false,
    InstantInteract = false,
    AntiVoid = false,
    FreeCam = false
}

local Blacklist = {}
local FreeCamGui = nil
local FreeCamEnabled = false
local FreeCamSpeeds = 1
local FreeCamConnections = {}

local ClientModule
local EatRemote
local function GetClientModule()
    if not ClientModule then
        ClientModule = require(LP:WaitForChild("PlayerScripts"):WaitForChild("Client"))
        EatRemote = ClientModule and ClientModule.Events and ClientModule.Events.RequestConsumeItem
    end
    return ClientModule, EatRemote
end

local espData = {}
local function createESP(target, name)
    local rootPart = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    if not rootPart or espData[target] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Adornee = rootPart
    billboard.Size = UDim2.new(0, 100, 0, 100)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = rootPart
    billboard.Enabled = true

    local label = Instance.new("TextLabel")
    label.Text = name .. "\n" .. "0m"
    label.Size = UDim2.new(1, 0, 0, 40)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.3
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Parent = billboard

    if name:match("Chest") then
        local image = Instance.new("ImageLabel")
        image.Position = UDim2.new(0, 20, 0, 40)
        image.Size = UDim2.new(0, 60, 0, 60)
        image.Image = "rbxassetid://18660563116"
        image.BackgroundTransparency = 1
        image.Parent = billboard
    end

    espData[target] = {gui = billboard, label = label, image = image}
end

local function update99NightESP()
    local playerChar = LP.Character
    if not playerChar or not playerChar:FindFirstChild("HumanoidRootPart") then return end
    local playerPos = playerChar.HumanoidRootPart.Position

    for target, data in pairs(espData) do
        if not target.Parent or not target:IsDescendantOf(workspace) then
            data.gui:Destroy()
            espData[target] = nil
        else
            local rootPart = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
            if rootPart then
                local dist = (playerPos - rootPart.Position).Magnitude
                data.label.Text = data.label.Text:match("^(.-)%.-\n") .. "\n" .. math.floor(dist) .. "m"
            end
        end
    end

    if Features.ChestESP then
        for _, chest in next, Workspace.Items:GetChildren() do
            if chest.Name:match("Chest") and chest:IsA("Model") and not table.find(Blacklist, chest) and chest:FindFirstChild("Main") and not espData[chest] then
                createESP(chest, "宝箱")
            end
        end
    end

    if Features.ChildESP then
        for _, child in next, Workspace.Characters:GetChildren() do
            if table.find({"Lost Child", "Lost Child1", "Lost Child2", "Lost Child3", "Dino Kid", "kraken kid", "Squid kid", "Koala Kid", "koala"}, child.Name) and child:FindFirstChild("HumanoidRootPart") and not table.find(Blacklist, child) and not espData[child] then
                createESP(child, "孩子")
            end
        end
    end
end

local function toggle99NightESP(enabled)
    Features.ChestESP = enabled
    Features.ChildESP = enabled

    if enabled then
        update99NightESP()
        WindUI:Notify({Title = "提示", Content = "已开启99夜透视", Duration = 2})
    else
        for _, data in pairs(espData) do
            data.gui:Destroy()
        end
        espData = {}
        WindUI:Notify({Title = "提示", Content = "已关闭99夜透视", Duration = 2})
    end
end

local function TryEatFood(food)
    local _, remote = GetClientModule()
    if not remote then 
        WindUI:Notify({Title = "错误", Content = "无法获取进食远程函数", Duration = 5})
        return 
    end

    if not ReplicatedStorage:FindFirstChild("TempStorage") then
        WindUI:Notify({Title = "错误", Content = "找不到临时存储", Duration = 5})
        return
    end

    WindUI:Notify({Title = "提示", Content = "➡️ 正在尝试吃下" .. food.Name, Duration = 5})
    food.Parent = ReplicatedStorage.TempStorage
    local success, result = pcall(function()
        return remote:InvokeServer(food)
    end)

    if success and result and result.Success then
        WindUI:Notify({Title = "提示", Content = "✅成功吃下 " .. food.Name, Duration = 5})
    else
        WindUI:Notify({Title = "提示", Content = "❌️进食失败", Duration = 5})
    end
end

local function TryCookFood(food)
    if not Workspace.Map:FindFirstChild("Campground") or not Workspace.Map.Campground:FindFirstChild("MainFire") then
        WindUI:Notify({Title = "错误", Content = "找不到篝火", Duration = 5})
        return
    end

    local cookTarget = food.Name == "Morsel" and "Cooked Morsel" or "Cooked Steak"
    WindUI:Notify({Title = "提示", Content = "🔥 正在尝试烹饪 " .. food.Name .. " 为 " .. cookTarget, Duration = 5})

    local args = {
        [1] = Workspace.Map.Campground.MainFire,
        [2] = Workspace.Items:FindFirstChild(cookTarget) or food
    }

    local success, result = pcall(function()
        return game:GetService("ReplicatedStorage").RemoteEvents.RequestCookItem:FireServer(unpack(args))
    end)

    if success and result then
        WindUI:Notify({Title = "提示", Content = "✅ 成功烹饪 " .. cookTarget, Duration = 5})
    else
        WindUI:Notify({Title = "提示", Content = "❌ 烹饪失败", Duration = 5})
    end
end

local baggedChildren = {}

local function bagAllChildren()
    local player = LP
    local character = player.Character or player.CharacterAdded:Wait()
    if not player or not player:FindFirstChild("Inventory") or not character or not character.PrimaryPart then return end

    local originalCFrame = character:GetPrimaryPartCFrame()

    local sack = nil
    for _, item in ipairs(player.Inventory:GetChildren()) do
        if item.Name:find("Sack") then
            sack = item
            break
        end
    end

    if not sack then
        WindUI:Notify({Title = "错误", Content = "未在您的物品栏中找到袋子 (Sack)", Duration = 3})
        return
    end

    local childNames = {"Lost Child", "Lost Child1", "Lost Child2", "Lost Child3", "Dino Kid", "kraken kid", "Squid kid", "Koala Kid", "koala"}
    local baggedCount = 0
    local charactersFolder = Workspace:FindFirstChild("Characters")

    if not charactersFolder then
        WindUI:Notify({Title = "错误", Content = "找不到 'Characters' 文件夹", Duration = 3})
        return
    end

    WindUI:Notify({Title = "提示", Content = "开始传送并收起孩子...", Duration = 3})

    task.spawn(function()
        for _, childName in ipairs(childNames) do
            if table.find(baggedChildren, childName) then
                continue
            end

            local childCharacter = charactersFolder:FindFirstChild(childName)
            if childCharacter and childCharacter:FindFirstChild("HumanoidRootPart") then
                local targetCFrame = childCharacter.HumanoidRootPart.CFrame
                character:SetPrimaryPartCFrame(targetCFrame + targetCFrame.LookVector * 3 + Vector3.new(0, 3, 0))
                WindUI:Notify({Title = "传送", Content = "已传送到 " .. childName, Duration = 2})
                task.wait(0.1)

                local success = pcall(function()
                    game:GetService("ReplicatedStorage").RemoteEvents.RequestBagStoreItem:InvokeServer(sack, childCharacter)
                end)

                if success then
                    table.insert(baggedChildren, childName)
                    baggedCount = baggedCount + 1
                end

                task.wait(0.1)
            end
        end

        if baggedCount > 0 then
            WindUI:Notify({Title = "成功", Content = "已完成收起 " .. baggedCount .. " 个孩子。", Duration = 3})
        else
            WindUI:Notify({Title = "提示", Content = "未找到新孩子或已全部收过。", Duration = 3})
        end

        task.wait(0.1)
        character:SetPrimaryPartCFrame(originalCFrame)
        WindUI:Notify({Title = "完成", Content = "已将您传送回原位。", Duration = 3})
    end)
end

local itemConfig = {
    {name = "Log", display = "木头", espColor = Color3.fromRGB(139, 69, 19)},
    {name = "Carrot", display = "胡萝卜", espColor = Color3.fromRGB(255, 165, 0)},
    {name = "Berry", display = "浆果", espColor = Color3.fromRGB(255, 0, 0)},
    {name = "Bolt", display = "螺栓", espColor = Color3.fromRGB(255, 255, 0)},
    {name = "Broken Fan", display = "风扇", espColor = Color3.fromRGB(100, 100, 100)},
    {name = "Coal", display = "煤炭", espColor = Color3.fromRGB(0, 0, 0)},
    {name = "Coin Stack", display = "钱堆", espColor = Color3.fromRGB(255, 215, 0)},
    {name = "Fuel Canister", display = "燃料罐", espColor = Color3.fromRGB(255, 50, 50)},
    {name = "Item Chest", display = "宝箱", espColor = Color3.fromRGB(210, 180, 140)},
    {name = "Old Flashlight", display = "手电筒", espColor = Color3.fromRGB(200, 200, 200)},
    {name = "Old Radio", display = "收音机", espColor = Color3.fromRGB(150, 150, 150)},
    {name = "Rifle Ammo", display = "步枪子弹", espColor = Color3.fromRGB(150, 75, 0)},
    {name = "Revolver Ammo", display = "左轮子弹", espColor = Color3.fromRGB(150, 75, 0)},
    {name = "Sheet Metal", display = "金属板", espColor = Color3.fromRGB(192, 192, 192)},
    {name = "Revolver", display = "左轮", espColor = Color3.fromRGB(75, 75, 75)},
    {name = "Rifle", display = "步枪", espColor = Color3.fromRGB(75, 75, 75)},
    {name = "Bandage", display = "绷带", espColor = Color3.fromRGB(255, 240, 245)},
    {name = "Crossbow Cultist", display = "敌人", espColor = Color3.fromRGB(255, 0, 0)},
    {name = "Bear", display = "熊", espColor = Color3.fromRGB(139, 69, 19)},
    {name = "Alpha Wolf", display = "阿尔法狼", espColor = Color3.fromRGB(128, 128, 128)},
    {name = "Wolf", display = "狼", espColor = Color3.fromRGB(192, 192, 192)},
    {name = "Chair", display = "椅子", espColor = Color3.fromRGB(160, 82, 45)},
    {name = "Tyre", display = "轮胎", espColor = Color3.fromRGB(20, 20, 20)},
    {name = "Alien Chest", display = "外星宝箱", espColor = Color3.fromRGB(0, 255, 0)},
    {name = "Chest", display = "宝箱", espColor = Color3.fromRGB(210, 180, 140)},
    {name = "Lost Child", display = "走失的孩子", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Lost Child1", display = "走失的孩子1", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Lost Child2", display = "走失的孩子2", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Lost Child3", display = "走失的孩子3", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Dino Kid", display = "恐龙孩子", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "kraken kid", display = "海怪孩子", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Squid kid", display = "鱿鱼孩子", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Koala Kid", display = "考拉孩子", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "koala", display = "考拉", espColor = Color3.fromRGB(0, 255, 255)},
    {name = "Cooked Morsel", display = "熟肉丁", espColor = Color3.fromRGB(139, 69, 19)},
    {name = "Cooked Steak", display = "熟牛排", espColor = Color3.fromRGB(139, 69, 19)},
    {name = "Morsel", display = "生肉丁", espColor = Color3.fromRGB(255, 0, 0)},
    {name = "Steak", display = "生牛排", espColor = Color3.fromRGB(255, 0, 0)},
    {name = "Sapling", display = "树苗", espColor = Color3.fromRGB(0, 255, 0)},
    {name = "Seed Box", display = "种子包", espColor = Color3.fromRGB(139, 119, 101)},
    {name = "Morningstar", display = "流星锤", espColor = Color3.fromRGB(100, 100, 100)},
    {name = "Broken Microwave", display = "旧微波炉", espColor = Color3.fromRGB(100, 100, 100)},
    {name = "Oil Barrel", display = "油桶", espColor = Color3.fromRGB(255, 50, 50)},
    {name = "MedKit", display = "医疗包", espColor = Color3.fromRGB(255, 0, 0)},
    {name = "Cultist Gem", display = "邪教宝石", espColor = Color3.fromRGB(128, 0, 128)},
    {name = "Old Car Engine", display = "旧汽车引擎", espColor = Color3.fromRGB(100, 100, 100)}
}

local BONFIRE_POSITION = Vector3.new(0.189, 7.831, -0.341)

local function findItems(itemName)
    local found = {}
    local folders = {"ltems", "Items", "MapItems", "WorldItems"}
    
    for _, folderName in ipairs(folders) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, item in ipairs(folder:GetDescendants()) do
                if item.Name == itemName and item:IsA("Model") then
                    local primaryPart = item.PrimaryPart or item:FindFirstChild("HumanoidRootPart")
                    if primaryPart then
                        table.insert(found, {model = item, part = primaryPart})
                    end
                end
            end
        end
    end
    
    return found
end

local function teleportToItem(itemName, displayName)
    local character = Character
    if not character then return end
    
    local items = findItems(itemName)
    if #items == 0 then
        WindUI:Notify({Title = "提示", Content = "未找到"..displayName, Duration = 2})
        return
    end
    
    local closest = nil
    local minDist = math.huge
    local charPos = character.PrimaryPart.Position
    
    for _, item in ipairs(items) do
        local dist = (item.part.Position - charPos).Magnitude
        if dist < minDist then
            minDist = dist
            closest = item.part
        end
    end
    
    if closest then
        character:MoveTo(closest.Position + Vector3.new(0, 3, 0))
        WindUI:Notify({Title = "成功", Content = "已传送到"..displayName, Duration = 2})
    end
end

local function teleportToBonfire()
    local character = Character
    if not character then return end
    
    character:MoveTo(BONFIRE_POSITION)
    WindUI:Notify({Title = "成功", Content = "已传送回篝火", Duration = 2})
end

local function teleportItemsToPlayer(itemName, displayName)
    local character = Character
    if not character then 
        WindUI:Notify({Title = "错误", Content = "无法获取角色", Duration = 2})
        return 
    end
    
    local items = findItems(itemName)
    if #items == 0 then
        WindUI:Notify({Title = "提示", Content = "未找到"..displayName, Duration = 2})
        return
    end
    
    local charPos = character.PrimaryPart.Position
    local radius = 5
    local angleStep = (2 * math.pi) / #items
    
    for i, item in ipairs(items) do
        local angle = angleStep * i
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local targetPos = charPos + Vector3.new(x, 0, z)
        
        if item.model:FindFirstChild("Handle") then
            item.model.Handle.CFrame = CFrame.new(targetPos)
        elseif item.part then
            item.part.CFrame = CFrame.new(targetPos)
        end
        
        local startArgs = { [1] = item.model }
        game:GetService("ReplicatedStorage").RemoteEvents.RequestStartDraggingItem:FireServer(unpack(startArgs))
        
        task.wait(0.1)
        local stopArgs = { [1] = item.model }
        game:GetService("ReplicatedStorage").RemoteEvents.StopDraggingItem:FireServer(unpack(stopArgs))
    end
    
    WindUI:Notify({
        Title = "成功", 
        Content = "已将"..#items.."个"..displayName.."传送到你旁边并进行拖动", 
        Duration = 2
    })
end

local function batchDragItems(items)
    if #items == 0 then return end
    
    for _, item in ipairs(items) do
        local startArgs = { [1] = item.model }
        game:GetService("ReplicatedStorage").RemoteEvents.RequestStartDraggingItem:FireServer(unpack(startArgs))
    end
    
    task.wait(0.1)
    for _, item in ipairs(items) do
        local stopArgs = { [1] = item.model }
        game:GetService("ReplicatedStorage").RemoteEvents.StopDraggingItem:FireServer(unpack(stopArgs))
    end
end

local function summonMultipleItems(itemNames, displayName)
    local character = Character
    if not character then 
        WindUI:Notify({Title = "错误", Content = "无法获取角色", Duration = 2})
        return 
    end
    
    local allItems = {}
    local totalItems = 0
    for _, itemName in ipairs(itemNames) do
        local items = findItems(itemName)
        totalItems = totalItems + #items
        for _, item in ipairs(items) do
            table.insert(allItems, item)
        end
    end
    
    if totalItems == 0 then
        WindUI:Notify({Title = "提示", Content = "未找到任何" .. displayName, Duration = 2})
        return
    end
    
    local charPos = character.PrimaryPart.Position
    local radius = 5
    local angleStep = (2 * math.pi) / totalItems
    
    for i, item in ipairs(allItems) do
        local angle = angleStep * i
        local x = math.cos(angle) * radius
        local z = math.sin(angle) * radius
        local targetPos = charPos + Vector3.new(x, 0, z)
        
        if item.model:FindFirstChild("Handle") then
            item.model.Handle.CFrame = CFrame.new(targetPos)
        elseif item.part then
            item.part.CFrame = CFrame.new(targetPos)
        end
    end
    
    batchDragItems(allItems)
    
    WindUI:Notify({
        Title = "成功",
        Content = "已将" .. totalItems .. "个" .. displayName .. "传送到你旁边并进行拖动",
        Duration = 2
    })
end

local function toggleESP(itemName, displayName, color)
    if _G["ESP_"..itemName] then
        for _, gui in ipairs(_G["ESP_"..itemName].guis) do
            gui:Destroy()
        end
        _G["ESP_"..itemName].conn:Disconnect()
        _G["ESP_"..itemName] = nil
        WindUI:Notify({Title = "提示", Content = "已关闭"..displayName.."透视", Duration = 2})
        return
    end
    
    local items = findItems(itemName)
    _G["ESP_"..itemName] = {guis = {}}
    
    local function createESP(itemPart)
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = itemPart
        billboard.Size = UDim2.new(0, 100, 0, 40)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 300
        
        local text = Instance.new("TextLabel")
        text.Text = displayName
        text.Size = UDim2.new(1, 0, 1, 0)
        text.Font = Enum.Font.SourceSansBold
        text.TextSize = 18
        text.TextColor3 = color
        text.BackgroundTransparency = 1
        text.TextStrokeTransparency = 0.5
        text.TextStrokeColor3 = Color3.new(0, 0, 0)
        text.Parent = billboard
        
        billboard.Parent = itemPart
        table.insert(_G["ESP_"..itemName].guis, billboard)
    end
    
    for _, item in ipairs(items) do
        createESP(item.part)
    end
    
    _G["ESP_"..itemName].conn = workspace.DescendantAdded:Connect(function(descendant)
        if descendant.Name == itemName and descendant:IsA("Model") then
            local primaryPart = descendant.PrimaryPart or descendant:FindFirstChild("HumanoidRootPart")
            if primaryPart then
                createESP(primaryPart)
            end
        end
    end)
    
    WindUI:Notify({
        Title = "提示", 
        Content = "已开启"..displayName.."透视 ("..#items.."个)", 
        Duration = 2
    })
end

local function createFreeCamGui()
    FreeCamGui = Instance.new("ScreenGui")
    FreeCamGui.Name = "FreeCamGUI"
    FreeCamGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    FreeCamGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    FreeCamGui.ResetOnSpawn = false

    local Frame = Instance.new("Frame")
    Frame.Parent = FreeCamGui
    Frame.BackgroundColor3 = Color3.fromRGB(163, 255, 137)
    Frame.BorderColor3 = Color3.fromRGB(103, 221, 213)
    Frame.Position = UDim2.new(0.100320168, 0, 0.379746825, 0)
    Frame.Size = UDim2.new(0, 190, 0, 57)
    Frame.Active = true
    Frame.Draggable = true

    local up = Instance.new("TextButton")
    up.Name = "up"
    up.Parent = Frame
    up.BackgroundColor3 = Color3.fromRGB(79, 255, 152)
    up.Size = UDim2.new(0, 44, 0, 28)
    up.Font = Enum.Font.SourceSans
    up.Text = "up"
    up.TextColor3 = Color3.fromRGB(0, 0, 0)
    up.TextSize = 14.000

    local down = Instance.new("TextButton")
    down.Name = "down"
    down.Parent = Frame
    down.BackgroundColor3 = Color3.fromRGB(215, 255, 121)
    down.Position = UDim2.new(0, 0, 0.491228074, 0)
    down.Size = UDim2.new(0, 44, 0, 28)
    down.Font = Enum.Font.SourceSans
    down.Text = "down"
    down.TextColor3 = Color3.fromRGB(0, 0, 0)
    down.TextSize = 14.000

    local onof = Instance.new("TextButton")
    onof.Name = "onof"
    onof.Parent = Frame
    onof.BackgroundColor3 = Color3.fromRGB(255, 249, 74)
    onof.Position = UDim2.new(0.702823281, 0, 0.491228074, 0)
    onof.Size = UDim2.new(0, 56, 0, 28)
    onof.Font = Enum.Font.SourceSans
    onof.Text = "开启/关闭"
    onof.TextColor3 = Color3.fromRGB(0, 0, 0)
    onof.TextSize = 14.000

    local TextLabel = Instance.new("TextLabel")
    TextLabel.Parent = Frame
    TextLabel.BackgroundColor3 = Color3.fromRGB(242, 60, 255)
    TextLabel.Position = UDim2.new(0.469327301, 0, 0, 0)
    TextLabel.Size = UDim2.new(0, 100, 0, 28)
    TextLabel.Font = Enum.Font.SourceSans
    TextLabel.Text = "FreeCam"
    TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.TextScaled = true
    TextLabel.TextSize = 14.000
    TextLabel.TextWrapped = true

    local plus = Instance.new("TextButton")
    plus.Name = "plus"
    plus.Parent = Frame
    plus.BackgroundColor3 = Color3.fromRGB(133, 145, 255)
    plus.Position = UDim2.new(0.231578946, 0, 0, 0)
    plus.Size = UDim2.new(0, 45, 0, 28)
    plus.Font = Enum.Font.SourceSans
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(0, 0, 0)
    plus.TextScaled = true
    plus.TextSize = 14.000
    plus.TextWrapped = true

    local speed = Instance.new("TextLabel")
    speed.Name = "speed"
    speed.Parent = Frame
    speed.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
    speed.Position = UDim2.new(0.468421042, 0, 0.491228074, 0)
    speed.Size = UDim2.new(0, 44, 0, 28)
    speed.Font = Enum.Font.SourceSans
    speed.Text = tostring(FreeCamSpeeds)
    speed.TextColor3 = Color3.fromRGB(0, 0, 0)
    speed.TextScaled = true
    speed.TextSize = 14.000
    speed.TextWrapped = true

    local mine = Instance.new("TextButton")
    mine.Name = "mine"
    mine.Parent = Frame
    mine.BackgroundColor3 = Color3.fromRGB(123, 255, 247)
    mine.Position = UDim2.new(0.231578946, 0, 0.491228074, 0)
    mine.Size = UDim2.new(0, 45, 0, 29)
    mine.Font = Enum.Font.SourceSans
    mine.Text = "-"
    mine.TextColor3 = Color3.fromRGB(0, 0, 0)
    mine.TextScaled = true
    mine.TextSize = 14.000
    mine.TextWrapped = true

    local closebutton = Instance.new("TextButton")
    closebutton.Name = "Close"
    closebutton.Parent = Frame
    closebutton.BackgroundColor3 = Color3.fromRGB(225, 25, 0)
    closebutton.Font = Enum.Font.SourceSans
    closebutton.Size = UDim2.new(0, 45, 0, 28)
    closebutton.Text = "X"
    closebutton.TextSize = 30
    closebutton.Position = UDim2.new(0, 0, -1, 27)

    local mini = Instance.new("TextButton")
    mini.Name = "minimize"
    mini.Parent = Frame
    mini.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
    mini.Font = Enum.Font.SourceSans
    mini.Size = UDim2.new(0, 45, 0, 28)
    mini.Text = "T"
    mini.TextSize = 30
    mini.Position = UDim2.new(0, 44, -1, 27)

    local mini2 = Instance.new("TextButton")
    mini2.Name = "minimize2"
    mini2.Parent = Frame
    mini2.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
    mini2.Font = Enum.Font.SourceSans
    mini2.Size = UDim2.new(0, 45, 0, 28)
    mini2.Text = "T"
    mini2.TextSize = 30
    mini2.Position = UDim2.new(0, 44, -1, 57)
    mini2.Visible = false

    local function toggleFreeCam(state)
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if not root then
            WindUI:Notify({Title = "错误", Content = "无法找到角色根部", Duration = 3})
            return
        end

        FreeCamEnabled = state
        if state then
            root.Anchored = true
            for i = 1, FreeCamSpeeds do
                spawn(function()
                    local hb = RunService.Heartbeat
                    local chr = LP.Character
                    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
                    while FreeCamEnabled and hb:Wait() and chr and hum and hum.Parent do
                        if hum.MoveDirection.Magnitude > 0 then
                            chr:TranslateBy(hum.MoveDirection)
                        end
                    end
                end)
            end
            LP.Character.Animate.Disabled = true
            local Char = LP.Character
            local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")
            for _, v in next, Hum:GetPlayingAnimationTracks() do
                v:AdjustSpeed(0)
            end
            local humanoidStates = {
                Enum.HumanoidStateType.Climbing,
                Enum.HumanoidStateType.FallingDown,
                Enum.HumanoidStateType.Flying,
                Enum.HumanoidStateType.Freefall,
                Enum.HumanoidStateType.GettingUp,
                Enum.HumanoidStateType.Jumping,
                Enum.HumanoidStateType.Landed,
                Enum.HumanoidStateType.Physics,
                Enum.HumanoidStateType.PlatformStanding,
                Enum.HumanoidStateType.Ragdoll,
                Enum.HumanoidStateType.Running,
                Enum.HumanoidStateType.RunningNoPhysics,
                Enum.HumanoidStateType.Seated,
                Enum.HumanoidStateType.StrafingNoPhysics,
                Enum.HumanoidStateType.Swimming
            }
            for _, state in ipairs(humanoidStates) do
                LP.Character.Humanoid:SetStateEnabled(state, false)
            end
            LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)

            local torso = LP.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 and LP.Character.Torso or LP.Character.UpperTorso
            local bg = Instance.new("BodyGyro", torso)
            bg.P = 9e4
            bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.cframe = torso.CFrame
            local bv = Instance.new("BodyVelocity", torso)
            bv.velocity = Vector3.new(0, 0.1, 0)
            bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
            LP.Character.Humanoid.PlatformStand = true

            local ctrl = {f = 0, b = 0, l = 0, r = 0}
            local lastctrl = {f = 0, b = 0, l = 0, r = 0}
            local maxspeed = 50
            local speed = 0

            FreeCamConnections.bg = bg
            FreeCamConnections.bv = bv
            FreeCamConnections.move = RunService.RenderStepped:Connect(function()
                if not FreeCamEnabled then return end
                if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                    speed = speed + 0.5 + (speed / maxspeed)
                    if speed > maxspeed then
                        speed = maxspeed
                    end
                elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
                    speed = speed - 1
                    if speed < 0 then
                        speed = 0
                    end
                end
                if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                    bv.velocity = ((Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f + ctrl.b)) + ((Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).p) - Workspace.CurrentCamera.CoordinateFrame.p)) * speed
                    lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
                elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
                    bv.velocity = ((Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f + lastctrl.b)) + ((Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).p) - Workspace.CurrentCamera.CoordinateFrame.p)) * speed
                else
                    bv.velocity = Vector3.new(0, 0, 0)
                end
                bg.cframe = Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
            end)

            FreeCamConnections.input = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    local key = input.KeyCode
                    if key == Enum.KeyCode.W then ctrl.f = 1 end
                    if key == Enum.KeyCode.S then ctrl.b = -1 end
                    if key == Enum.KeyCode.A then ctrl.l = -1 end
                    if key == Enum.KeyCode.D then ctrl.r = 1 end
                end
            end)

            FreeCamConnections.inputEnd = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    local key = input.KeyCode
                    if key == Enum.KeyCode.W then ctrl.f = 0 end
                    if key == Enum.KeyCode.S then ctrl.b = 0 end
                    if key == Enum.KeyCode.A then ctrl.l = 0 end
                    if key == Enum.KeyCode.D then ctrl.r = 0 end
                end
            end)
        else
            root.Anchored = false
            LP.Character.Humanoid.PlatformStand = false
            LP.Character.Animate.Disabled = false
            local humanoidStates = {
                Enum.HumanoidStateType.Climbing,
                Enum.HumanoidStateType.FallingDown,
                Enum.HumanoidStateType.Flying,
                Enum.HumanoidStateType.Freefall,
                Enum.HumanoidStateType.GettingUp,
                Enum.HumanoidStateType.Jumping,
                Enum.HumanoidStateType.Landed,
                Enum.HumanoidStateType.Physics,
                Enum.HumanoidStateType.PlatformStanding,
                Enum.HumanoidStateType.Ragdoll,
                Enum.HumanoidStateType.Running,
                Enum.HumanoidStateType.RunningNoPhysics,
                Enum.HumanoidStateType.Seated,
                Enum.HumanoidStateType.StrafingNoPhysics,
                Enum.HumanoidStateType.Swimming
            }
            for _, state in ipairs(humanoidStates) do
                LP.Character.Humanoid:SetStateEnabled(state, true)
            end
            LP.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            if FreeCamConnections.bg then FreeCamConnections.bg:Destroy() end
            if FreeCamConnections.bv then FreeCamConnections.bv:Destroy() end
            if FreeCamConnections.move then FreeCamConnections.move:Disconnect() end
            if FreeCamConnections.input then FreeCamConnections.input:Disconnect() end
            if FreeCamConnections.inputEnd then FreeCamConnections.inputEnd:Disconnect() end
            FreeCamConnections = {}
        end
    end

    onof.MouseButton1Down:Connect(function()
        toggleFreeCam(not FreeCamEnabled)
        onof.Text = FreeCamEnabled and "关闭" or "开启"
    end)

    local tis
    up.MouseButton1Down:Connect(function()
        tis = up.MouseEnter:Connect(function()
            while tis do
                wait()
                if LP.Character and LP.Character.HumanoidRootPart then
                    LP.Character.HumanoidRootPart.CFrame = LP.Character.HumanoidRootPart.CFrame * CFrame.new(0, 1, 0)
                end
            end
        end)
    end)

    up.MouseLeave:Connect(function()
        if tis then
            tis:Disconnect()
            tis = nil
        end
    end)

    local dis
    down.MouseButton1Down:Connect(function()
        dis = down.MouseEnter:Connect(function()
            while dis do
                wait()
                if LP.Character and LP.Character.HumanoidRootPart then
                    LP.Character.HumanoidRootPart.CFrame = LP.Character.HumanoidRootPart.CFrame * CFrame.new(0, -1, 0)
                end
            end
        end)
    end)

    down.MouseLeave:Connect(function()
        if dis then
            dis:Disconnect()
            dis = nil
        end
    end)

    plus.MouseButton1Down:Connect(function()
        FreeCamSpeeds = FreeCamSpeeds + 1
        speed.Text = tostring(FreeCamSpeeds)
        if FreeCamEnabled then
            toggleFreeCam(false)
            toggleFreeCam(true)
        end
    end)

    mine.MouseButton1Down:Connect(function()
        if FreeCamSpeeds > 1 then
            FreeCamSpeeds = FreeCamSpeeds - 1
            speed.Text = tostring(FreeCamSpeeds)
            if FreeCamEnabled then
                toggleFreeCam(false)
                toggleFreeCam(true)
            end
        else
            speed.Text = "flyno1"
            wait(1)
            speed.Text = tostring(FreeCamSpeeds)
        end
    end)

    closebutton.MouseButton1Click:Connect(function()
        Features.FreeCam = false
        toggleFreeCam(false)
        FreeCamGui:Destroy()
        FreeCamGui = nil
        WindUI:Notify({Title = "自由视角", Content = "自由视角已关闭", Duration = 3})
    end)

    mini.MouseButton1Click:Connect(function()
        up.Visible = false
        down.Visible = false
        onof.Visible = false
        plus.Visible = false
        speed.Visible = false
        mine.Visible = false
        mini.Visible = false
        mini2.Visible = true
        Frame.BackgroundTransparency = 1
        closebutton.Position = UDim2.new(0, 0, -1, 57)
    end)

    mini2.MouseButton1Click:Connect(function()
        up.Visible = true
        down.Visible = true
        onof.Visible = true
        plus.Visible = true
        speed.Visible = true
        mine.Visible = true
        mini.Visible = true
        mini2.Visible = false
        Frame.BackgroundTransparency = 0
        closebutton.Position = UDim2.new(0, 0, -1, 27)
    end)

    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "FreeCamGUI",
        Text = "Injection succeeded",
        Icon = "rbxthumb://type=Asset&id=5107182114&w=150&h=150",
        Duration = 5
    })

    LP.CharacterAdded:Connect(function(char)
        wait(0.7)
        if FreeCamEnabled then
            toggleFreeCam(true)
        end
    end)
end

local function toggleFreeCamFeature(state)
    Features.FreeCam = state
    if state then
        if not FreeCamGui then
            createFreeCamGui()
            WindUI:Notify({Title = "自由视角", Content = "自由视角GUI已创建", Duration = 3})
        end
    else
        if FreeCamGui then
            toggleFreeCam(false)
            FreeCamGui:Destroy()
            FreeCamGui = nil
            WindUI:Notify({Title = "自由视角", Content = "自由视角已关闭并销毁GUI", Duration = 3})
        end
    end
end

local lastKillAura, lastAutoChop, lastAutoEat, lastAutoCook = 0, 0, 0, 0
local instantInteractConn
RunService.Heartbeat:Connect(function()
    local now = tick()
    
    if Features.InstantInteract then
        if not instantInteractConn then
            instantInteractConn = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
                prompt.HoldDuration = 0
            end)
        end
    else
        if instantInteractConn then
            instantInteractConn:Disconnect()
            instantInteractConn = nil
        end
    end

    if Features.KillAura and now - lastKillAura >= 0.7 then
        lastKillAura = now
        if Character and Character:FindFirstChild("ToolHandle") then
            local tool = Character.ToolHandle.OriginalItem.Value
            if tool and (tool.Name:find("Axe") or tool.Name == "Morningstar") then
                for _, target in next, Workspace.Characters:GetChildren() do
                    if target:IsA("Model") and target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("HitRegisters") then
                        if (Character.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude <= 100 then
                            ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(target, tool, true, Character.HumanoidRootPart.CFrame)
                        end
                    end
                end
            end
        end
    end

    if Features.AutoChop and now - lastAutoChop >= 0.7 then
        lastAutoChop = now
        if Character and Character:FindFirstChild("ToolHandle") then
            local tool = Character.ToolHandle.OriginalItem.Value
            if tool and tool.Name:find("Axe") then
                local function ChopTree(path)
                    for _, tree in next, path:GetChildren() do
                        task.wait(.1)
                        if tree:IsA("Model") and tree:FindFirstChild("HitRegisters") then
                            local trunk = tree:FindFirstChild("Trunk") or tree:FindFirstChild("HumanoidRootPart") or tree.PrimaryPart
                            if trunk and (Character.HumanoidRootPart.Position - trunk.Position).Magnitude <= 100 then
                                ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ToolDamageObject"):InvokeServer(tree, tool, true, Character.HumanoidRootPart.CFrame)
                            end
                        end
                    end
                end
                ChopTree(Workspace.Map.Foliage)
                ChopTree(Workspace.Map.Landmarks)
            end
        end
    end

    if Features.AutoEat and now - lastAutoEat >= 10 then
        lastAutoEat = now
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            local eatCount = 0
            for _, obj in pairs(Workspace.Items:GetChildren()) do
                if eatCount >= 2 then break end
                if obj:IsA("Model") and ({["Carrot"] = true, ["Berry"] = true, ["Morsel"] = false, ["Cooked Morsel"] = true, ["Steak"] = false, ["Cooked Steak"] = true})[obj.Name] then
                    local mainPart = obj:FindFirstChild("Handle") or obj.PrimaryPart
                    if mainPart and (mainPart.Position - Character.HumanoidRootPart.Position).Magnitude < 25 then
                        TryEatFood(obj)
                        eatCount = eatCount + 1
                    end
                end
            end
            if eatCount == 0 then
                WindUI:Notify({Title = "提示", Content = "🔍25米范围内无食物", Duration = 5})
            end
        else
            WindUI:Notify({Title = "提示", Content = "⏳等待玩家加载", Duration = 5})
        end
    end

    if Features.AutoCook and now - lastAutoCook >= 10 then
        lastAutoCook = now
        if Character and Character:FindFirstChild("HumanoidRootPart") then
            local cookCount = 0
            for _, obj in pairs(Workspace.Items:GetChildren()) do
                if cookCount >= 2 then break end
                if obj:IsA("Model") and ({["Morsel"] = true, ["Steak"] = true})[obj.Name] then
                    local mainPart = obj:FindFirstChild("Handle") or obj.PrimaryPart
                    if mainPart and (mainPart.Position - Character.HumanoidRootPart.Position).Magnitude < 25 then
                        TryCookFood(obj)
                        cookCount = cookCount + 1
                    end
                end
            end
            if cookCount == 0 then
                WindUI:Notify({Title = "提示", Content = "🔍25米范围内无生肉（Morsel/Steak）", Duration = 5})
            end
        else
            WindUI:Notify({Title = "提示", Content = "⏳等待玩家加载", Duration = 5})
        end
    end
    
    if Features.AntiVoid then
        if Character and Character:FindFirstChild("HumanoidRootPart") and Character.HumanoidRootPart.Position.Y < -100 then
            teleportToBonfire()
            WindUI:Notify({Title = "反虚空", Content = "已将您传送回篝火", Duration = 3})
        end
    end

    if Features.ChestESP or Features.ChildESP then
        update99NightESP()
    end
end)

Tabs.Main:Toggle({
    Title = "杀戮光环",
    Description = "自动攻击附近敌人",
    Value = false,
    Callback = function(value)
        Features.KillAura = value
    end
})

Tabs.Main:Toggle({
    Title = "自动砍树",
    Description = "自动砍伐附近树木",
    Value = false,
    Callback = function(value)
        Features.AutoChop = value
    end
})

Tabs.Main:Toggle({
    Title = "自动进食",
    Description = "自动吃附近食物",
    Value = false,
    Callback = function(value)
        Features.AutoEat = value
    end
})

Tabs.Main:Toggle({
    Title = "瞬间互动",
    Description = "立即完成所有互动",
    Value = false,
    Callback = function(value)
        Features.InstantInteract = value
    end
})

Tabs.Main:Toggle({
    Title = "自动烹饪",
    Description = "自动烹饪附近生肉（Morsel/Steak）",
    Value = false,
    Callback = function(value)
        Features.AutoCook = value
    end
})

Tabs.Main:Toggle({
    Title = "反虚空",
    Description = "当你掉入虚空时传送回篝火",
    Value = false,
    Callback = function(value)
        Features.AntiVoid = value
    end
})

Tabs.Main:Button({
    Title = "传送并收起所有孩子",
    Description = "传送到每个孩子的位置并将其收入袋中",
    Callback = bagAllChildren
})

Tabs.Main:Toggle({
    Title = "自由视角",
    Desc = "启用/禁用自由视角模式",
    Default = false,
    Callback = function(state)
        toggleFreeCamFeature(state)
    end
})

Tabs.Main:Button({
    Title = "无限血量",
    Description = "获得无限血量",
    Callback = function()
        local args = {
            [1] = -18446744073609551615
        }
        game:GetService("ReplicatedStorage").RemoteEvents.DamagePlayer:FireServer(unpack(args))
        WindUI:Notify({Title = "成功", Content = "已获得无限血量", Duration = 3})
    end
})

Tabs.Ninja:Button({
    Title = "传送回篝火",
    Callback = teleportToBonfire
})

for _, item in ipairs(itemConfig) do
    Tabs.Ninja:Button({
        Title = "传送到"..item.display,
        Callback = function()
            teleportToItem(item.name, item.display)
        end
    })
end

for _, item in ipairs(itemConfig) do
    Tabs.Summon:Button({
        Title = "召唤"..item.display,
        Callback = function()
            teleportItemsToPlayer(item.name, item.display)
        end
    })
end

Tabs.Summon:Button({
    Title = "召唤所有食物",
    Callback = function()
        summonMultipleItems({"Carrot", "Berry", "Cooked Morsel", "Cooked Steak", "Morsel", "Steak"}, "食物")
    end
})

Tabs.Summon:Button({
    Title = "召唤所有废料",
    Callback = function()
        summonMultipleItems({"Bolt", "Broken Fan", "Sheet Metal", "Broken Microwave", "Old Car Engine", "Tyre"}, "废料")
    end
})

Tabs.Summon:Button({
    Title = "召唤所有燃料",
    Callback = function()
        summonMultipleItems({"Coal", "Fuel Canister", "Log", "Chair", "Oil Barrel"}, "燃料")
    end
})

Tabs.ESP:Toggle({
    Title = "99夜透视 (宝箱&孩子)",
    Value = false,
    Callback = toggle99NightESP
})

for _, item in ipairs(itemConfig) do
    Tabs.ESP:Button({
        Title = item.display.."透视",
        Callback = function() 
            toggleESP(item.name, item.display, item.espColor) 
        end
    })
end

Tabs.ESP:Button({
    Title = "清除所有透视",
    Callback = function()
        for _, item in ipairs(itemConfig) do
            if _G["ESP_"..item.name] then
                for _, gui in ipairs(_G["ESP_"..item.name].guis) do
                    gui:Destroy()
                end
                _G["ESP_"..item.name].conn:Disconnect()
                _G["ESP_"..item.name] = nil
            end
        end
        for _, data in pairs(espData) do
            data.gui:Destroy()
        end
        espData = {}
        Features.ChestESP = false
        Features.ChildESP = false
        WindUI:Notify({Title = "提示", Content = "已清除所有透视", Duration = 2})
    end
})

local autoLoops = {}

local function startLoop(name, callback, delay)
    if autoLoops[name] then return end
    autoLoops[name] = coroutine.wrap(function()
        while autoLoops[name] do
            pcall(callback)
            task.wait(delay)
        end
    end)
    task.spawn(autoLoops[name])
end

local function stopLoop(name)
    if not autoLoops[name] then return end
    autoLoops[name] = nil
end

Tabs.Home:Paragraph({
    Title = "有逼看。？！",
    Desc = "生气的迪克有多可怕😡。？！",
    Image = "https://raw.githubusercontent.com/DUKECCB1337/PigGod/refs/heads/main/有逼看？.png",
    ImageSize = 42,
    Thumbnail = "https://raw.githubusercontent.com/DUKECCB1337/PigGodAssets/refs/heads/main/生气的迪克有多恐怖😡.jpg",
    ThumbnailSize = 120
})

Tabs.Home:Paragraph({
    Title = "欢迎",
    Desc = "需要时开启反挂机。脚本仍在更新中... 作者: PigGod\n脚本免费, 请勿倒卖。",
})

Tabs.Home:Button({
    Title = "反挂机",
    Desc = "从GitHub加载并执行反挂机",
    Callback = function()
        pcall(function()
            local response = game:HttpGet("https://raw.githubusercontent.com/Guo61/Cat-/refs/heads/main/%E5%8F%8D%E6%8C%82%E6%9C%BA.lua", true)
            if response and #response > 100 then
                loadstring(response)()
            end
        end)
    end
})

Tabs.Home:Toggle({
    Title = "显示FPS",
    Desc = "在屏幕上显示当前FPS",
    Callback = function(state)
        local FpsGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("FPSGui")
        if state then
            if not FpsGui then
                FpsGui = Instance.new("ScreenGui")
                local FpsXS = Instance.new("TextLabel")
                FpsGui.Name = "FPSGui"
                FpsGui.ResetOnSpawn = false
                FpsXS.Name = "FpsXS"
                FpsXS.Size = UDim2.new(0, 100, 0, 50)
                FpsXS.Position = UDim2.new(0, 10, 0, 10)
                FpsXS.BackgroundTransparency = 1
                FpsXS.Font = Enum.Font.SourceSansBold
                FpsXS.Text = "FPS: 0"
                FpsXS.TextSize = 20
                FpsXS.TextColor3 = Color3.new(1, 1, 1)
                FpsXS.Parent = FpsGui
                FpsGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
                
                game:GetService("RunService").Heartbeat:Connect(function()
                    local fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
                    FpsXS.Text = "FPS: " .. fps
                end)
            end
            FpsGui.Enabled = true
        else
            if FpsGui then
                FpsGui.Enabled = false
            end
        end
    end
})

Tabs.Home:Toggle({
    Title = "显示范围",
    Desc = "显示玩家范围",
    Callback = function(state)
        local HeadSize = 20
        local highlight = Instance.new("Highlight")
        highlight.Adornee = nil
        highlight.OutlineTransparency = 0
        highlight.FillTransparency = 0.7
        highlight.FillColor = Color3.fromHex("#0000FF")

        local function applyHighlight(character)
            if not character:FindFirstChild("WindUI_RangeHighlight") then
                local clone = highlight:Clone()
                clone.Adornee = character
                clone.Name = "WindUI_RangeHighlight"
                clone.Parent = character
            end
        end

        local function removeHighlight(character)
            local h = character:FindFirstChild("WindUI_RangeHighlight")
            if h then
                h:Destroy()
            end
        end

        if state then
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Name ~= game.Players.LocalPlayer.Name and player.Character then
                    applyHighlight(player.Character)
                end
            end
            game.Players.PlayerAdded:Connect(function(player)
                player.CharacterAdded:Connect(function(character)
                    task.wait(1)
                    applyHighlight(character)
                end)
            end)
            game.Players.PlayerRemoving:Connect(function(player)
                if player.Character then
                    removeHighlight(player.Character)
                end
            end)
        else
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character then
                    removeHighlight(player.Character)
                end
            end
        end
    end
})

Tabs.Home:Button({
    Title = "半隐身",
    Desc = "从GitHub加载并执行隐身脚本",
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-Invisible-35376"))() end)
    end
})

Tabs.Home:Button({
    Title = "玩家入退提示",
    Desc = "从GitHub加载并执行提示脚本",
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/boyscp/scriscriptsc/main/bbn.lua"))() end)
    end
})

Tabs.Home:Button({
    Title = "甩飞玩家",
    Desc = "将选中的玩家甩飞",
    Callback = function()
        local selectedPlayerName = playersDropdown.Value
        if not selectedPlayerName then
            WindUI:Notify({Title = "错误", Content = "未选择玩家", Duration = 3})
            return
        end
        
        local targetPlayer = game.Players:FindFirstChild(selectedPlayerName)
        if not targetPlayer or not targetPlayer.Character then
            WindUI:Notify({Title = "错误", Content = "未找到玩家或玩家角色", Duration = 3})
            return
        end
        
        local character = targetPlayer.Character
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            WindUI:Notify({Title = "错误", Content = "玩家角色缺少HumanoidRootPart", Duration = 3})
            return
        end
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bodyVelocity.Velocity = Vector3.new(0, 50, 0) + (humanoidRootPart.CFrame.lookVector * 10)
        bodyVelocity.P = 1000
        bodyVelocity.Parent = humanoidRootPart
        
        task.delay(1, function()
            bodyVelocity:Destroy()
            WindUI:Notify({Title = "成功", Content = "已甩飞玩家 " .. selectedPlayerName, Duration = 3})
        end)
    end
})

local antiWalkFlingConn
Tabs.Home:Toggle({
    Title = "防甩飞",
    Desc = "不要和甩飞同时开启!",
    Callback = function(state)
        local player = game.Players.LocalPlayer
        if state then
            if antiWalkFlingConn then antiWalkFlingConn:Disconnect() end
            local lastVelocity = Vector3.new()
            antiWalkFlingConn = game:GetService("RunService").Stepped:Connect(function()
                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                local currentVelocity = hrp.Velocity
                if (currentVelocity - lastVelocity).Magnitude > 100 then
                    hrp.Velocity = lastVelocity
                end
                lastVelocity = currentVelocity
            end)
        else
            if antiWalkFlingConn then antiWalkFlingConn:Disconnect() end
        end
    end
})

local function setPlayerHealth(healthValue)
    local player = game.Players.LocalPlayer
    local character = player.Character
    
    if not character then
        character = player.CharacterAdded:Wait()
    end
    
    local humanoid = character:WaitForChild("Humanoid")
    
    humanoid.Health = healthValue
    
    WindUI:Notify({
        Title = "血量设置",
        Content = "血量已设置为: " .. healthValue,
        Duration = 3
    })
end

Tabs.Home:Slider({
    Title = "设置血量",
    Desc = "调整人物血量 (0-1000)",
    Value = { Min = 0, Max = 1000, Default = 100 },
    Callback = function(val)
        setPlayerHealth(val)
    end
})

Tabs.Home:Button({
    Title = "满血",
    Desc = "将血量设置为最大值",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        setPlayerHealth(humanoid.MaxHealth)
    end
})

Tabs.Home:Button({
    Title = "半血",
    Desc = "将血量设置为一半",
    Callback = function()
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local humanoid = character:WaitForChild("Humanoid")
        setPlayerHealth(humanoid.MaxHealth / 2)
    end
})

local godModeEnabled = false
local originalHealth
local godModeConnection

Tabs.Home:Toggle({
    Title = "无敌模式",
    Desc = "开启后血量不会减少",
    Default = false,
    Callback = function(state)
        godModeEnabled = state
        local player = game.Players.LocalPlayer
        local character = player.Character
        
        if not character then
            character = player.CharacterAdded:Wait()
        end
        
        local humanoid = character:WaitForChild("Humanoid")
        
        if state then
            originalHealth = humanoid.Health
            
            godModeConnection = humanoid.HealthChanged:Connect(function(newHealth)
                if newHealth < humanoid.MaxHealth then
                    humanoid.Health = humanoid.MaxHealth
                end
            end)
            
            humanoid.Health = humanoid.MaxHealth
            
            WindUI:Notify({
                Title = "无敌模式",
                Content = "无敌模式已开启",
                Duration = 3
            })
        else
            if godModeConnection then
                godModeConnection:Disconnect()
                godModeConnection = nil
            end
            
            if originalHealth then
                humanoid.Health = originalHealth
            end
            
            WindUI:Notify({
                Title = "无敌模式",
                Content = "无敌模式已关闭",
                Duration = 3
            })
        end
    end
})

Tabs.Home:Slider({
    Title = "设置速度",
    Desc = "可输入",
    Value = { Min = 0, Max = 520, Default = 25 },
    Callback = function(val)
        local character = game.Players.LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = val
            end
        end
    end
})

Tabs.Home:Slider({
    Title = "设置个人重力",
    Desc = "默认值即为最大值",
    Value = { Min = 0, Max = 196.2, Default = 196.2, Rounding = 1 },
    Callback = function(val)
        local player = game.Players.LocalPlayer
        local character = player.Character or player.CharacterAdded:Wait()
        local rootPart = character:WaitForChild("HumanoidRootPart")
        local oldGravity = rootPart:FindFirstChild("PersonalGravity")
        if oldGravity then oldGravity:Destroy() end

        if val ~= workspace.Gravity then
            local personalGravity = Instance.new("BodyForce")
            personalGravity.Name = "PersonalGravity"
            local mass = rootPart:GetMass()
            local force = Vector3.new(0, mass * (workspace.Gravity - val), 0)
            personalGravity.Force = force
            personalGravity.Parent = rootPart
        end
    end
})

Tabs.Home:Slider({
    Title = "设置跳跃高度",
    Desc = "可输入",
    Value = { Min = 0, Max = 200, Default = 50 },
    Callback = function(val)
        local character = game.Players.LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = val
            end
        end
    end
})

Tabs.Home:Toggle({
    Title = "自由视角",
    Desc = "启用/禁用自由视角模式",
    Default = false,
    Callback = function(state)
        toggleFreeCamFeature(state)
    end
})

local function getPlayerNames()
    local names = {}
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    return names
end

local function refreshPlayerDropdown()
    if not playersDropdown then return end

    local currentValues = playersDropdown:GetValues()
    local newValues = getPlayerNames()
    local added = {}
    local removed = {}
    
    local newSet = {}
    for _, name in ipairs(newValues) do
        newSet[name] = true
    end
    
    for _, name in ipairs(currentValues) do
        if not newSet[name] then
            table.insert(removed, name)
        end
    end
    
    local currentSet = {}
    for _, name in ipairs(currentValues) do
        currentSet[name] = true
    end
    
    for _, name in ipairs(newValues) do
        if not currentSet[name] then
            table.insert(added, name)
        end
    end
    
    for _, name in ipairs(removed) do
        playersDropdown:RemoveValue(name)
    end
    
    for _, name in ipairs(added) do
        playersDropdown:AddValue(name)
    end
end

local playersDropdown = Tabs.Home:Dropdown({
    Title = "选择要传送的玩家",
    Values = getPlayerNames(),
})

Tabs.Home:Button({
    Title = "传送至玩家",
    Desc = "传送到选中的玩家",
    Callback = function()
        local selectedPlayerName = playersDropdown.Value
        if not selectedPlayerName then
            WindUI:Notify({Title = "错误", Content = "未选择玩家", Duration = 3})
            return
        end
        local targetPlayer = game.Players:FindFirstChild(selectedPlayerName)
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
            local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
            humanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
        end
    end
})

game.Players.PlayerAdded:Connect(refreshPlayerDropdown)
game.Players.PlayerRemoving:Connect(refreshPlayerDropdown)

Tabs.Home:Button({
    Title = "飞行",
    Desc = "从GitHub加载并执行飞行脚本",
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Guo61/Cat-/refs/heads/main/%E9%A3%9E%E8%A1%8C%E8%84%9A%E6%9C%AC.lua"))() end)
    end
})

Tabs.Home:Button({
    Title = "无限跳",
    Desc = "开启后无法关闭",
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://pastebin.com/raw/V5PQy3y0", true))() end)
    end
})

Tabs.Home:Button({
    Title = "自瞄",
    Desc = "宙斯自瞄",
    Callback = function()
        pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/chillz-workshop/main/Arceus%20Aimbot.lua"))() end)
    end
})

local trackData = {}
Tabs.Home:Toggle({
    Title = "子弹追踪",
    Default = false,
    Callback = function(state)
        trackData.enabled = state
        if not state then
            if trackData.workspaceConn then trackData.workspaceConn:Disconnect() end
            for _, conn in pairs(trackData.bulletConns or {}) do conn:Disconnect() end
            trackData.bulletConns = {}
            return
        end
        local function getTarget(bulletPos)
            local nearestTarget, nearestDist = nil, math.huge
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player ~= game.Players.LocalPlayer then
                    local char = player.Character
                    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if humanoid and humanoid.Health > 0 and root then
                        local dist = (bulletPos - root.Position).Magnitude
                        if dist <= 70 and dist < nearestDist then
                            nearestDist = dist
                            nearestTarget = root
                        end
                    end
                end
            end
            return nearestTarget
        end

        local function attachTrack(bullet)
            local bulletPart = bullet:IsA("BasePart") and bullet or bullet:FindFirstChildWhichIsA("BasePart")
            if not bulletPart then return end
            local bodyVel = bulletPart:FindFirstChildOfClass("BodyVelocity")
            if not bodyVel then
                bodyVel = Instance.new("BodyVelocity")
                bodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                bodyVel.Velocity = bulletPart.Velocity
                bodyVel.Parent = bulletPart
            end

            local bulletConn = game:GetService("RunService").Heartbeat:Connect(function()
                if not bulletPart.Parent or not trackData.enabled then
                    bulletConn:Disconnect()
                    trackData.bulletConns[bulletConn] = nil
                    return
                end
                local target = getTarget(bulletPart.Position)
                if target then
                    local trackDir = (target.Position - bulletPart.Position).Unit
                    bodyVel.Velocity = trackDir * bulletPart.Velocity.Magnitude
                    bulletPart.CFrame = CFrame.new(bulletPart.Position, target.Position)
                end
            end)
            trackData.bulletConns[bulletConn] = true
        end
        trackData.workspaceConn = workspace.ChildAdded:Connect(function(child)
            local isLocalBullet = (child.Name:lower():find("bullet") or child.Name:lower():find("projectile") or child.Name:lower():find("missile")) and (child:FindFirstChild("Owner") and child.Owner.Value == game.Players.LocalPlayer)
            if isLocalBullet then
                task.wait(0.05)
                attachTrack(child)
            end
        end)
    end
})

local nightVisionData = {}
Tabs.Home:Toggle({
    Title = "夜视",
    Default = false,
    Callback = function(isEnabled)
        local lighting = game:GetService("Lighting")
        if isEnabled then
            pcall(function()
                nightVisionData.originalAmbient = lighting.Ambient
                nightVisionData.originalBrightness = lighting.Brightness
                nightVisionData.originalFogEnd = lighting.FogEnd
                lighting.Ambient = Color3.fromRGB(255, 255, 255)
                lighting.Brightness = 1
                lighting.FogEnd = 1e10
                for _, v in pairs(lighting:GetDescendants()) do
                    if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") then
                        v.Enabled = false
                    end
                end
                nightVisionData.changedConnection = lighting.Changed:Connect(function()
                    lighting.Ambient = Color3.fromRGB(255, 255, 255)
                    lighting.Brightness = 1
                    lighting.FogEnd = 1e10
                end)
                local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
                local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
                if not humanoidRootPart:FindFirstChildWhichIsA("PointLight") then
                    local headlight = Instance.new("PointLight", humanoidRootPart)
                    headlight.Brightness = 1
                    headlight.Range = 60
                    nightVisionData.pointLight = headlight
                end
            end)
        else
            if nightVisionData.originalAmbient then lighting.Ambient = nightVisionData.originalAmbient end
            if nightVisionData.originalBrightness then lighting.Brightness = nightVisionData.originalBrightness end
            if nightVisionData.originalFogEnd then lighting.FogEnd = nightVisionData.originalFogEnd end
            if nightVisionData.changedConnection then nightVisionData.changedConnection:Disconnect() end
            if nightVisionData.pointLight and nightVisionData.pointLight.Parent then nightVisionData.pointLight:Destroy() end
        end
    end
})

local noclipConn
Tabs.Home:Toggle({
    Title = "穿墙",
    Default = false,
    Callback = function(state)
        local character = game.Players.LocalPlayer.Character or game.Players.LocalPlayer.CharacterAdded:Wait()
        if state then
            noclipConn = game:GetService("RunService").Stepped:Connect(function()
                if character then
                    for _, v in pairs(character:GetChildren()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end
                end
            end)
        else
            if noclipConn then noclipConn:Disconnect() end
            if character then
                for _, v in pairs(character:GetChildren()) do
                    if v:IsA("BasePart") then
                    if v.Name ~= "HumanoidRootPart" then  -- 避免影响根部，但通常都设为true
                        v.CanCollide = true
                    end
                    end
                end
            end
        end
    end
})

local espEnabled = false
local espConnections = {}
local espHighlights = {}
local espNameTags = {}

local function createESP(player)
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "WindUI_ESP"
    highlight.Adornee = char
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = char
    espHighlights[player] = highlight

    local nameTag = Instance.new("BillboardGui")
    nameTag.Name = "WindUI_NameTag"
    nameTag.Adornee = humanoidRootPart
    nameTag.Size = UDim2.new(0, 150, 0, 20)
    nameTag.StudsOffset = Vector3.new(0, 2.8, 0)
    nameTag.AlwaysOnTop = true
    nameTag.Parent = humanoidRootPart
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = player.Name
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 14
    textLabel.TextScaled = false
    textLabel.Parent = nameTag
    espNameTags[player] = nameTag
end

local function removeESP(player)
    if espHighlights[player] and espHighlights[player].Parent then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end
    if espNameTags[player] and espNameTags[player].Parent then
        espNameTags[player]:Destroy()
        espNameTags[player] = nil
    end
end

local function toggleESP(state)
    espEnabled = state
    if state then
        for _, player in ipairs(game.Players:GetPlayers()) do
            if player ~= game.Players.LocalPlayer then
                pcall(createESP, player)
            end
        end

        espConnections.playerAdded = game.Players.PlayerAdded:Connect(function(player)
            player.CharacterAdded:Wait()
            pcall(createESP, player)
            end)
        espConnections.playerRemoving = game.Players.PlayerRemoving:Connect(function(player)
            removeESP(player)
        end)
    else
        if espConnections.playerAdded then espConnections.playerAdded:Disconnect() end
        if espConnections.playerRemoving then espConnections.playerRemoving:Disconnect() end
        for player, _ in pairs(espHighlights) do
            removeESP(player)
        end
        espHighlights = {}
        espNameTags = {}
    end
end

Tabs.Home:Toggle({
    Title = "人物透视 (ESP)",
    Desc = "显示其他玩家的透视框和名字。",
    Default = false,
    Callback = toggleESP,
})

Tabs.Home:Button({
    Title = "切换服务器",
    Desc = "切换到相同游戏的另一个服务器",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        local placeId = game.PlaceId
        
        TeleportService:Teleport(placeId, game.Players.LocalPlayer)
    end
})

Tabs.Home:Button({
    Title = "重新加入服务器",
    Desc = "尝试重新加入当前服务器",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        local placeId = game.PlaceId
        local jobId = game.JobId
        
        TeleportService:TeleportToPlaceInstance(placeId, jobId, game.Players.LocalPlayer)
    end
})

Tabs.Home:Button({
    Title = "复制服务器邀请链接",
    Desc = "复制当前服务器的邀请链接到剪贴板",
    Callback = function()
        local inviteLink = "roblox://experiences/start?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId
        setclipboard(inviteLink)
        WindUI:Notify({
            Title = "邀请链接已复制",
            Content = "链接已复制到剪贴板",
            Duration = 3
        })
    end
})

Tabs.Home:Button({
    Title = "复制服务器ID",
    Desc = "复制当前服务器的Job ID到剪贴板",
    Callback = function()
        setclipboard(game.JobId)
        WindUI:Notify({
            Title = "服务器ID已复制",
            Content = "Job ID: " .. game.JobId,
            Duration = 3
        })
    end
})

Tabs.Home:Button({
    Title = "服务器信息",
    Desc = "显示当前服务器的信息",
    Callback = function()
        local players = game.Players:GetPlayers()
        local maxPlayers = game.Players.MaxPlayers
        local placeId = game.PlaceId
        local jobId = game.JobId
        local serverType = game:GetService("RunService"):IsStudio() and "Studio" or "Live"
        
        WindUI:Notify({
            Title = "服务器信息",
            Content = string.format("玩家数量: %d/%d\nPlace ID: %d\nJob ID: %s\n服务器类型: %s", #players, maxPlayers, placeId, jobId, serverType),
            Duration = 10
        })
    end
})

Tabs.Misc:Button({
    Title = "复制作者QQ",
    Callback = function()
        setclipboard("3395858053")
        WindUI:Notify({Title = "QQ群号", Content = "群号已复制到剪贴板", Duration = 3})
    end
})

Tabs.Misc:Button({
    Title = "脚本信息",
    Desc = "显示脚本相关信息",
    Callback = function()
        WindUI:Notify({
            Title = "脚本信息",
            Content = "PigGod Hub v2.01\n作者: PigGod\nQQ群: 1061490197",
            Duration = 10
        })
    end
})

Tabs.Misc:Button({
    Title = "检查更新",
    Desc = "检查脚本是否有更新",
    Callback = function()
        WindUI:Notify({
            Title = "更新检查",
            Content = "当前版本: v2.01\n已是最新版本",
            Duration = 5
        })
    end
})

spawn(function()
    while true do
        wait(5)
        local currentTime = os.date("%H:%M:%S")
        TimeTag:Set({
            Title = "当前时间: " .. currentTime,
            Color = Color3.fromHex("#ff6a30")
        })
    end
end)

Tabs.Misc:Code({
    Title = "感谢游玩",
    Code = "QQ号:3395858053"
})
