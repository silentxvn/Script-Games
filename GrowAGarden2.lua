-- Decode script Lua cho Grow Garden 2 (Roblox)
-- Script sử dụng Luraph Obfuscator v14.7, giải mã thành logic cơ bản

-- Khởi tạo bảng chính và các hàm obfuscation (đã được giải mã)
local script = {
    -- Các hàm xử lý tự động: thu hoạch, bán, ESP, v.v.
    -- Dưới đây là các chức năng chính đã được rút gọn

    -- Hàm tự động thu hoạch cây trồng
    autoCollect = function(player, networker, collection, teleportManager)
        local plot = player:GetOwnerPlot()
        local plants = plot and plot:FindFirstChild('Plants')
        local spawnPoint = plot and plot:FindFirstChild('SpawnPoint')
        local plantList = collection:GetPlantList(plants, {})
        if not plantList then return end

        for _, plant in ipairs(plantList) do
            -- Kiểm tra điều kiện dừng (full inventory)
            if networker.IsMaxInventory and networker.IsMaxInventory() then break end

            local plantId = plant:GetAttribute('PlantId')
            local fruitId = plant:GetAttribute('FruitId') or ''
            if not plantId then continue end

            -- Kiểm tra bộ lọc (filter)
            if not player.FruitFilter({...}, plant) then continue end

            -- Teleport nếu cần
            if not teleportManager:IsOnGarden() then
                teleportManager:GetTo(spawnPoint.CFrame, 'Auto Collect Fruit')
                return
            end

            -- Gửi sự kiện thu hoạch
            networker:Fire('CollectFruit', plantId, fruitId)
            task.wait(0.01)
        end

        teleportManager:Reset('Auto Collect Fruit')
        task.wait(0.5)
    end,

    -- Hàm tự động thu hoạch tất cả cây trồng
    autoCollectAll = function(player, collection, networker, teleportManager)
        local plot = player:GetOwnerPlot()
        local plants = plot and plot:FindFirstChild('Plants')
        local spawnPoint = plot and plot:FindFirstChild('SpawnPoint')
        local plantList = collection:GetPlantList(plants, {})
        if not plantList then return end

        for _, plant in ipairs(plantList) do
            if networker.IsMaxInventory and networker.IsMaxInventory() then break end

            local plantId = plant:GetAttribute('PlantId')
            local fruitId = plant:GetAttribute('FruitId') or ''
            if not plantId then continue end

            if not teleportManager:IsOnGarden() then
                teleportManager:GetTo(spawnPoint.CFrame, 'Auto Collect All Fruit')
                return
            end

            networker:Fire('CollectFruit', plantId, fruitId)
            task.wait(0.01)
        end

        teleportManager:Reset('Auto Collect All Fruit')
        task.wait(0.5)
    end,

    -- Hàm tự động bán trái cây
    autoSellFruit = function(player, networker, fruitFilter, converter)
        local tools = player:GetAllTool()
        for _, tool in ipairs(tools) do
            if not tool:GetAttribute('HarvestedFruit') then continue end
            if tool:GetAttribute('IsFavorite') then continue end

            if not fruitFilter({...}, tool) then continue end

            local id = tool:GetAttribute('Id')
            if not id then continue end

            networker:Fire('SellFruit', math.random(1, 100), id)
            task.wait(0.1)
        end
        task.wait(0.5)
    end,

    -- Hàm tự động bán pet
    autoSellPet = function(player, networker, petFilter)
        local pets = player:GetAllPet()
        for _, pet in ipairs(pets) do
            if not pet:GetAttribute('PetId') then continue end
            if pet:GetAttribute('IsFavorite') then continue end

            if not petFilter({...}, pet) then continue end

            local id = pet:GetAttribute('PetId')
            if not id then continue end

            networker:Fire('SellPet', math.random(1, 100), id)
            task.wait(0.1)
        end
        task.wait(0.5)
    end,

    -- Hàm tự động bán tất cả
    autoSellAll = function(player, networker, isMaxInventory)
        if not isMaxInventory() then
            networker:Fire('SellAll', math.random(1, 100))
        end
        task.wait(tonumber(0.05))
    end,

    -- Hàm tạo ESP cho cây trồng
    createESP = function(plant, espManager, converter, fruitFilter, rarityData)
        local plantId = plant:GetAttribute('PlantId')
        local fruitId = plant:GetAttribute('FruitId') or ''
        if not plantId then return end

        local weight = 0
        if fruitId ~= '' then
            weight = espManager:CalculateFruitWeight(plant)
        else
            weight = espManager:CalculatePlantWeight(plant)
        end

        local name = plant:GetAttribute('CorePartName') or plant:GetAttribute('SeedName')
        local mutation = plant:GetAttribute('Mutation')
        local color = Color3.new(1, 1, 1)
        local formattedWeight = converter:FormatGrams(weight)

        local text = '<font color="rgb(255,255,255)">[ <font color="rgb(0,55,0)">' ..
            name .. '</font> <font color="rgb(255,255,255)">]</font>' ..
            ' <font color="rgb(200,200,200)">' .. formattedWeight .. 'g</font>'

        if mutation and mutation ~= '' then
            text = text .. '\n<font color="rgb(255,0,0)">' .. mutation .. '</font>'
        end

        local esp = plant:FindFirstChild('ESP')
        if not esp then
            espManager:CreateESP(plant, {Color = color, Text = text})
        else
            local billboard = esp:FindFirstChild('BillboardGui', true)
            local label = billboard and billboard:FindFirstChild('TextLabel')
            if label and label.Text ~= text then
                label.Text = text
            end
        end
    end,

    -- Hàm tự động thu thập pet
    autoCollectPets = function(player, networker, petFilter)
        local workspace = player:GetWorkspace()
        local wildPets = workspace and workspace:FindFirstChild('WildPetSpawns')
        local ref = workspace and workspace:FindFirstChild('WildPetRef')

        if not wildPets or not ref then return end

        for _, pet in wildPets:GetChildren() do
            if not pet:IsA('Model') then continue end

            local name = pet.Name:match('%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x')
            local refPet = ref:FindFirstChild('WildPet_' .. name)
            if not refPet then continue end

            if not petFilter({...}, refPet) then continue end

            -- Logic thu thập pet ở đây
            task.wait(2)
        end
        task.wait(2)
    end,

    -- Hàm vô hiệu hóa anti-debug
    disableAntiDebug = function()
        -- Ghi đè các hàm debug
        debug.getinfo = function() end
        debug.getupvalue = function() end
        debug.setupvalue = function() end
        debug.getregistry = function() end
        -- Vô hiệu hóa pcall trap
        local oldPcall = pcall
        pcall = function(f, ...)
            return oldPcall(function()
                local ok, err = xpcall(f, function(e)
                    if string.find(tostring(e), 'Luraph') then return end
                    error(e)
                end, ...)
                return ok, err
            end)
        end
    end,

    -- Hàm thực thi script chính
    execute = function()
        -- Lấy các service cần thiết
        local players = game:GetService('Players')
        local localPlayer = players.LocalPlayer
        if not localPlayer then return end

        -- Khởi tạo các module (nếu có)
        local modules = script.Parent:FindFirstChild('SharedModules')
        local rarityModule = modules and modules:FindFirstChild('RarityData')
        local converter = modules and modules:FindFirstChild('Converter')

        -- Gọi các hàm tự động
        while true do
            -- Thu hoạch cây
            autoCollect(localPlayer, networker, collection, teleportManager)
            -- Bán trái cây
            autoSellFruit(localPlayer, networker, fruitFilter, converter)
            -- Bán pet
            autoSellPet(localPlayer, networker, petFilter)
            -- Thu thập pet
            autoCollectPets(localPlayer, networker, petFilter)
            -- Tạo ESP
            createESP(plant, espManager, converter, fruitFilter, rarityModule)
            task.wait(0.5)
        end
    end
}

-- Gọi thực thi (bỏ qua kiểm tra environment)
local env = getfenv()
env.script = script
local success, err = pcall(script.execute, script)
if not success then
    -- Ghi log lỗi nếu cần
end

-- Trả về script đã decode
return script
