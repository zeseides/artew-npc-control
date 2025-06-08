-- 玩家載具保護增強版

-- 一般設定
local VehicleDensityMultiplier = Config.VehicleDensityMultiplier
local PedDensityMultiplier = Config.PedDensityMultiplier
local DisableCops = Config.DisableCops
local DisableDispatch = Config.DisableDispatch
local lastVehicleDensity, lastPedDensity = -1, -1
local syncedVehicles = {} -- 用於追蹤已同步的載具

-- 生成距離和限制
local vehicleSpawnDistance = Config.VehicleSpawnDistance
local pedSpawnDistance = Config.PedSpawnDistance
local maxVehiclesInArea = Config.MaxVehiclesInArea
local maxPedsInArea = Config.MaxPedsInArea

-- 靜止玩家的額外設定
local playerStaticThreshold = Config.PlayerStaticThreshold
local staticPositionMultiplier = Config.StaticPositionMultiplier
local lastPlayerPosition = vector3(0, 0, 0)
local isPlayerStatic = false
local staticCheckTimer = 0
local STATIC_CHECK_INTERVAL = Config.StaticCheckInterval

-- 快取系統
local entityCache = {
    vehicles = {},
    peds = {},
    lastCleanup = 0,
    maxSize = Config.MaxCacheSize
}

-- 清理計時器
local cleanupTime = Config.CleanupTime
local cacheCleanupInterval = Config.CacheCleanupInterval
local invisibleVehicleTimers, invisiblePedTimers = {}, {}

-- 效能優化常數
local THREAD_SLEEP_VEHICLE = Config.ThreadSleepVehicle
local THREAD_SLEEP_PED = Config.ThreadSleepPed
local FADE_STEP = Config.FadeStep
local FADE_WAIT = Config.FadeWait

-- 玩家載具安全系統
local protectedVehicles = {} -- 受保護載具列表
local playerVehicleChecksCounter = 0

-- 除錯變數
local debugMode = Config.DebugMode
local debugLogLevel = Config.DebugLogLevel

-- 除錯日誌函數
local function DebugLog(message, level)
    if not debugMode then return end
    if level > debugLogLevel then return end
    print(string.format("^2[Artew-NPC-Control] ^7%s", message))
end

-- 實體控制函數（增強版）
local function IsEntityValid(entity)
    if entity == nil or entity == 0 or not DoesEntityExist(entity) then 
        return false 
    end
    -- 檢查是否為網路實體
    return NetworkGetEntityIsNetworked(entity)
end

-- 快取管理
local function UpdateEntityCache(entityType, entityId, data)
    if not Config.EnableCache then return end
    
    if not entityCache[entityType] then
        entityCache[entityType] = {}
    end
    
    -- 快取大小檢查
    local cacheSize = 0
    for _ in pairs(entityCache[entityType]) do
        cacheSize = cacheSize + 1
    end
    
    if cacheSize >= entityCache.maxSize then
        -- 刪除最舊的條目
        local oldestTime = GetGameTimer()
        local oldestId = nil
        for id, entry in pairs(entityCache[entityType]) do
            if entry.lastUpdate < oldestTime then
                oldestTime = entry.lastUpdate
                oldestId = id
            end
        end
        if oldestId then
            entityCache[entityType][oldestId] = nil
        end
    end
    
    entityCache[entityType][entityId] = {
        data = data,
        lastUpdate = GetGameTimer()
    }
end

local function GetCachedEntity(entityType, entityId)
    if entityCache[entityType] and entityCache[entityType][entityId] then
        return entityCache[entityType][entityId].data
    end
    return nil
end

local function CleanupCache()
    local currentTime = GetGameTimer()
    if currentTime - entityCache.lastCleanup > cacheCleanupInterval then
        for entityType, entities in pairs(entityCache) do
            if type(entities) == "table" then
                for entityId, data in pairs(entities) do
                    if currentTime - data.lastUpdate > cacheCleanupInterval then
                        entityCache[entityType][entityId] = nil
                    end
                end
            end
        end
        entityCache.lastCleanup = currentTime
        collectgarbage("collect") -- 垃圾回收
    end
end

-- 玩家靜止狀態檢測
local function CheckPlayerStatic(playerCoords)
    local currentTime = GetGameTimer()
    if currentTime - staticCheckTimer > STATIC_CHECK_INTERVAL then
        local distance = #(playerCoords - lastPlayerPosition)
        isPlayerStatic = distance < playerStaticThreshold
        lastPlayerPosition = playerCoords
        staticCheckTimer = currentTime
    end
    return isPlayerStatic
end

-- 基於 FPS 和靜止狀態的密度優化
local function AdjustDensityBasedOnConditions(playerCoords)
    if not Config.EnableDensityAdjustment then return end
    
    -- 使用手動密度設定
    local currentVehicleDensity = VehicleDensityMultiplier
    local currentPedDensity = PedDensityMultiplier
    
    -- 檢查玩家是否靜止並相應調整密度
    if Config.EnableStaticCheck and CheckPlayerStatic(playerCoords) then
        currentVehicleDensity = currentVehicleDensity * staticPositionMultiplier
        currentPedDensity = currentPedDensity * staticPositionMultiplier
    end
    
    -- 使用原生函數調整密度
    SetParkedVehicleDensityMultiplierThisFrame(currentVehicleDensity)
    SetVehicleDensityMultiplierThisFrame(currentVehicleDensity)
    SetRandomVehicleDensityMultiplierThisFrame(currentVehicleDensity)
    SetPedDensityMultiplierThisFrame(currentPedDensity)
    SetScenarioPedDensityMultiplierThisFrame(currentPedDensity, currentPedDensity)
    
    -- 額外的密度檢查
    SetAmbientVehicleRangeMultiplierThisFrame(currentVehicleDensity)
    SetAmbientPedRangeMultiplierThisFrame(currentPedDensity)
    
    -- 檢查交通密度
    SetVehicleModelIsSuppressed(GetHashKey("taco"), currentVehicleDensity == 0)
    SetVehicleModelIsSuppressed(GetHashKey("biff"), currentVehicleDensity == 0)
    SetVehicleModelIsSuppressed(GetHashKey("hauler"), currentVehicleDensity == 0)
    SetVehicleModelIsSuppressed(GetHashKey("phantom"), currentVehicleDensity == 0)
    SetVehicleModelIsSuppressed(GetHashKey("pounder"), currentVehicleDensity == 0)
    
    -- NPC 生成檢查
    if currentPedDensity == 0 then
        SetPedPopulationBudget(0)
    else
        SetPedPopulationBudget(3)
    end
    
    -- 載具生成檢查
    if currentVehicleDensity == 0 then
        SetVehiclePopulationBudget(0)
    else
        SetVehiclePopulationBudget(3)
    end
end

-- 慢速淡出函數
local function FadeOutEntity(entity)
    if not Config.EnableFadeEffect then
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
        return true
    end
    
    if IsEntityValid(entity) then
        -- 再次檢查是否為玩家載具
        if entity ~= nil and GetEntityType(entity) == 2 then -- 載具類型
            local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or 0
            if netId == 0 then return false end
            
            local plate = GetVehicleNumberPlateText(entity) or "unknown"
            
            -- 如果是受保護的載具，取消刪除
            if Config.ProtectPlayerVehicles and (protectedVehicles[netId] or protectedVehicles[plate]) then
                return false
            end
            
            -- 載具類別檢查
            local vehClass = GetVehicleClass(entity)
            if Config.ProtectedVehicleClasses[vehClass] then
                return false
            end
            
            -- 檢查載具內是否有玩家
            local maxPassengers = GetVehicleMaxNumberOfPassengers(entity)
            for seat = -1, maxPassengers do
                local ped = GetPedInVehicleSeat(entity, seat)
                if DoesEntityExist(ped) and IsPedAPlayer(ped) then
                    -- 如果載具內有玩家，保護並取消刪除
                    protectedVehicles[netId] = true
                    protectedVehicles[plate] = true
                    return false
                end
            end
            
            -- 最終檢查：載具是否被擁有？
            if NetworkGetEntityOwner(entity) ~= nil and GetEntityPopulationType(entity) ~= 7 then
                -- 這是玩家載具，保護並取消刪除
                protectedVehicles[netId] = true
                protectedVehicles[plate] = true
                return false
            end
        end
        
        -- NPC 檢查
        if Config.ProtectPlayerPeds and IsPedAPlayer(entity) then
            return false
        end
        
        -- NPC 類型檢查
        local pedType = GetPedType(entity)
        if Config.ProtectedPedTypes[pedType] then
            return false
        end
        
        -- 原始刪除程序
        local startAlpha = GetEntityAlpha(entity)
        for alpha = startAlpha, 0, -FADE_STEP do
            if DoesEntityExist(entity) then
                SetEntityAlpha(entity, alpha, false)
                Wait(FADE_WAIT)
            else
                break
            end
        end
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
        return true
    end
    return false
end

-- 載具玩家檢查（增強版）
local function IsPlayerOwnedVehicle(vehicle)
    if not IsEntityValid(vehicle) then return false end
    
    -- 網路 ID 和車牌檢查
    local netId = NetworkGetEntityIsNetworked(vehicle) and NetworkGetNetworkIdFromEntity(vehicle) or 0
    if netId == 0 then return false end
    
    local plate = GetVehicleNumberPlateText(vehicle) or "unknown"
    
    -- 如果之前被保護為載具
    if protectedVehicles[netId] or protectedVehicles[plate] then
        return true
    end
    
    -- 實體擁有者檢查
    local owner = NetworkGetEntityOwner(vehicle)
    if owner ~= nil then
        -- PopType 7 = 隨機/NPC 載具，其他通常是玩家/腳本載具
        if GetEntityPopulationType(vehicle) ~= 7 then
            -- 標記為玩家載具
            protectedVehicles[netId] = true
            protectedVehicles[plate] = true
            return true
        end
    end
    
    -- 檢查載具內是否有玩家
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    for seat = -1, maxPassengers do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if DoesEntityExist(ped) and IsPedAPlayer(ped) then
            -- 標記為玩家載具
            protectedVehicles[netId] = true
            protectedVehicles[plate] = true
            return true
        end
    end
    
    -- 根據模型類型檢查（某些載具始終受保護）
    local vehModel = GetEntityModel(vehicle)
    local vehClass = GetVehicleClass(vehicle)
    
    -- 特殊載具、緊急載具或稀有載具始終受保護
    if vehClass == 18 or vehClass == 19 or vehClass == 15 then -- 緊急、警察等
        protectedVehicles[netId] = true
        protectedVehicles[plate] = true
        return true
    end
    
    return false
end

-- 載具生成檢查
local function ShouldSpawnVehicle()
    local chance = isPlayerStatic and 0.3 or 0.7
    return math.random() < chance
end

-- NPC 載具同步檢查
local function CheckVehicleSync(vehicle)
    if not IsEntityValid(vehicle) then return false end
    
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then return false end
    
    -- 如果載具已經同步
    if syncedVehicles[netId] then
        return true
    end
    
    -- 如果載具接近其他玩家
    local vehicleCoords = GetEntityCoords(vehicle)
    local found = false
    
    -- 檢查所有玩家
    for i = 0, 32 do
        if NetworkIsPlayerActive(i) then
            local ped = GetPlayerPed(i)
            if DoesEntityExist(ped) and ped ~= PlayerPedId() then
                local playerCoords = GetEntityCoords(ped)
                local dist = #(vehicleCoords - playerCoords)
                
                -- 如果載具接近其他玩家（50.0 單位）
                if dist < 50.0 then
                    found = true
                    break
                end
            end
        end
    end
    
    -- 如果載具接近其他玩家，同步它
    if found then
        syncedVehicles[netId] = true
        NetworkRequestControlOfEntity(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        return true
    end
    
    return false
end

-- 載具管理函數（玩家保護）
local function ManageVehicle(vehicle, playerCoords, playerVehicle, vehicleCount)
    -- 如果載具無效，不處理
    if not IsEntityValid(vehicle) then
        return vehicleCount
    end
    
    -- 玩家載具檢查
    if vehicle == playerVehicle then
        if NetworkGetEntityIsNetworked(vehicle) then
            local netId = NetworkGetNetworkIdFromEntity(vehicle)
            local plate = GetVehicleNumberPlateText(vehicle) or "unknown"
            protectedVehicles[netId] = true
            protectedVehicles[plate] = true
        end
        return vehicleCount
    end
    
    -- 同步檢查
    if CheckVehicleSync(vehicle) then
        return vehicleCount -- 已同步的載具
    end
    
    -- 增強的玩家載具檢查
    if IsPlayerOwnedVehicle(vehicle) then
        return vehicleCount  -- 玩家載具，不處理
    end

    -- 從這裡開始，處理 NPC 載具
    local vehHandle = NetworkGetEntityIsNetworked(vehicle) and NetworkGetNetworkIdFromEntity(vehicle) or 0
    if vehHandle == 0 then
        return vehicleCount -- 無效的網路 ID，跳過此載具
    end
    
    local cachedVehicle = GetCachedEntity("vehicles", vehHandle)
    local vehCoords = cachedVehicle and cachedVehicle.coords or GetEntityCoords(vehicle)
    local distance = #(vehCoords - playerCoords)
    
    if distance < vehicleSpawnDistance then
        vehicleCount = vehicleCount + 1
        
        -- 如果玩家靜止或超過載具限制
        if (isPlayerStatic and vehicleCount > maxVehiclesInArea * staticPositionMultiplier) or 
           vehicleCount > maxVehiclesInArea then
            -- 檢查載具內所有 NPC 並隨載具一起刪除
            local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
            for seat = -1, maxPassengers do -- -1 是駕駛座
                local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                if DoesEntityExist(pedInSeat) and not IsPedAPlayer(pedInSeat) then
                    -- 將 NPC 與載具一起刪除
                    FadeOutEntity(pedInSeat)
                end
            end
            
            -- 再次檢查
            if not IsPlayerOwnedVehicle(vehicle) then
                -- 然後刪除載具
                FadeOutEntity(vehicle)
            end
            return vehicleCount
        end

        local vehPlate = GetVehicleNumberPlateText(vehicle) or "unknown"
        local currentTime = GetGameTimer()
        
        UpdateEntityCache("vehicles", vehHandle, {
            coords = vehCoords,
            plate = vehPlate,
            lastSeen = currentTime
        })

        -- 如果載具不在螢幕上且玩家靜止，更快刪除
        local invisibleTimeout = isPlayerStatic and (cleanupTime * 0.6) or cleanupTime
        
        if not IsEntityOnScreen(vehicle) then
            if not invisibleVehicleTimers[vehPlate] then
                invisibleVehicleTimers[vehPlate] = currentTime
            elseif currentTime - invisibleVehicleTimers[vehPlate] > invisibleTimeout then
                    -- 再次檢查是否為玩家載具
                if not IsPlayerOwnedVehicle(vehicle) then
                    -- 將 NPC 與載具一起刪除
                    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
                    for seat = -1, maxPassengers do -- -1 是駕駛座
                        local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                        if DoesEntityExist(pedInSeat) and not IsPedAPlayer(pedInSeat) then
                            FadeOutEntity(pedInSeat)
                        end
                    end
                    
                    FadeOutEntity(vehicle)
                end
                invisibleVehicleTimers[vehPlate] = nil
            end
        else 
            invisibleVehicleTimers[vehPlate] = nil
        end
    end
    
    return vehicleCount
end

-- NPC 管理函數（更新版）
local function ManagePed(ped, playerCoords, pedCount)
    if not IsEntityValid(ped) or IsPedAPlayer(ped) then
        return pedCount
    end

    -- 如果 NPC 在載具內，交給載具管理
    local pedVehicle = GetVehiclePedIsIn(ped, false)
    if pedVehicle ~= 0 then
        -- 如果是玩家載具，絕對不碰
        if IsPlayerOwnedVehicle(pedVehicle) then
            return pedCount
        end
        -- 載具內的 NPC，交給載具管理
        return pedCount
    end

    local pedHandle = NetworkGetEntityIsNetworked(ped) and NetworkGetNetworkIdFromEntity(ped) or 0
    if pedHandle == 0 then
        return pedCount -- 無效的網路 ID，跳過此 NPC
    end
    
    local cachedPed = GetCachedEntity("peds", pedHandle)
    local pedCoords = cachedPed and cachedPed.coords or GetEntityCoords(ped)
    local distance = #(pedCoords - playerCoords)
    
    -- 如果玩家靜止，縮短 NPC 距離
    local activeSpawnDistance = isPlayerStatic and (pedSpawnDistance * 0.7) or pedSpawnDistance
    
    if distance < activeSpawnDistance then
        pedCount = pedCount + 1
        
        -- 如果玩家靜止或超過 NPC 限制
        if (isPlayerStatic and pedCount > maxPedsInArea * staticPositionMultiplier) or 
           pedCount > maxPedsInArea then
            FadeOutEntity(ped)
            return pedCount
        end

        local currentTime = GetGameTimer()
        
        UpdateEntityCache("peds", pedHandle, {
            coords = pedCoords,
            lastSeen = currentTime
        })

        -- 如果 NPC 不在螢幕上且玩家靜止，更快刪除
        local invisibleTimeout = isPlayerStatic and (cleanupTime * 0.6) or cleanupTime
        
        if not IsEntityOnScreen(ped) then
            if not invisiblePedTimers[pedHandle] then
                invisiblePedTimers[pedHandle] = currentTime
            elseif currentTime - invisiblePedTimers[pedHandle] > invisibleTimeout then
                FadeOutEntity(ped)
                invisiblePedTimers[pedHandle] = nil
            end
        else
            invisiblePedTimers[pedHandle] = nil
        end
    end
    
    return pedCount
end

-- 玩家載具掃描和保護函數
local function ScanAndProtectPlayerVehicles()
    local playerCount = GetNumberOfPlayers()
    
    -- 掃描所有玩家
    for i = 0, playerCount - 1 do
        local ped = GetPlayerPed(i)
        if DoesEntityExist(ped) then
            -- 檢查玩家是否有當前載具
            local vehicle = GetVehiclePedIsIn(ped, false)
            if DoesEntityExist(vehicle) and NetworkGetEntityIsNetworked(vehicle) then
                local netId = NetworkGetNetworkIdFromEntity(vehicle)
                local plate = GetVehicleNumberPlateText(vehicle) or "unknown"
                protectedVehicles[netId] = true
                protectedVehicles[plate] = true
            end
        end
    end
    
    -- 掃描所有載具並標記玩家擁有的載具
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            -- 檢查載具內是否有玩家
            local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
            for seat = -1, maxPassengers do
                local ped = GetPedInVehicleSeat(vehicle, seat)
                if DoesEntityExist(ped) and IsPedAPlayer(ped) then
                    if NetworkGetEntityIsNetworked(vehicle) then
                        local netId = NetworkGetNetworkIdFromEntity(vehicle)
                        local plate = GetVehicleNumberPlateText(vehicle) or "unknown"
                        protectedVehicles[netId] = true
                        protectedVehicles[plate] = true
                    end
                    break
                end
            end
            
            -- 實體擁有者是玩家嗎？
            if NetworkGetEntityOwner(vehicle) ~= nil then
                if GetEntityPopulationType(vehicle) ~= 7 then
                    if NetworkGetEntityIsNetworked(vehicle) then
                        local netId = NetworkGetNetworkIdFromEntity(vehicle)
                        local plate = GetVehicleNumberPlateText(vehicle) or "unknown"
                        protectedVehicles[netId] = true
                        protectedVehicles[plate] = true
                    end
                end
            end
        end
    end
end

-- 主要載具管理循環
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if DoesEntityExist(playerPed) then
            local playerCoords = GetEntityCoords(playerPed)
            AdjustDensityBasedOnConditions(playerCoords)
            CleanupCache()
            
            -- 定期掃描玩家載具
            playerVehicleChecksCounter = playerVehicleChecksCounter + 1
            if playerVehicleChecksCounter >= 10 then
                ScanAndProtectPlayerVehicles()
                playerVehicleChecksCounter = 0
            end
            
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)
            if DoesEntityExist(playerVehicle) and NetworkGetEntityIsNetworked(playerVehicle) then
                -- 始終保護玩家載具
                local netId = NetworkGetNetworkIdFromEntity(playerVehicle)
                local plate = GetVehicleNumberPlateText(playerVehicle) or "unknown"
                protectedVehicles[netId] = true
                protectedVehicles[plate] = true
            end
            
            local vehicles = GetGamePool('CVehicle')
            local vehicleCount = 0
            
            for _, vehicle in ipairs(vehicles) do
                vehicleCount = ManageVehicle(vehicle, playerCoords, playerVehicle, vehicleCount)
            end
        end
        
        Wait(THREAD_SLEEP_VEHICLE)
    end
end)

-- 主要 NPC 管理循環
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if DoesEntityExist(playerPed) then
            local playerCoords = GetEntityCoords(playerPed)
            AdjustDensityBasedOnConditions(playerCoords)
            CleanupCache()
            
            local peds = GetGamePool('CPed')
            local pedCount = 0
            
            for _, ped in ipairs(peds) do
                pedCount = ManagePed(ped, playerCoords, pedCount)
            end
        end
        
        Wait(THREAD_SLEEP_PED)
    end
end)

-- 新增額外交通控制機制
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if DoesEntityExist(playerPed) then
            -- 如果玩家靜止，積極清理周圍載具
            if isPlayerStatic then
                local playerCoords = GetEntityCoords(playerPed)
                local vehicles = GetGamePool('CVehicle')
                local playerVehicle = GetVehiclePedIsIn(playerPed, false)
                
                for _, vehicle in ipairs(vehicles) do
                    if DoesEntityExist(vehicle) and vehicle ~= playerVehicle and not IsPlayerOwnedVehicle(vehicle) then
                        local vehCoords = GetEntityCoords(vehicle)
                        local dist = #(vehCoords - playerCoords)
                        
                        -- 如果玩家靜止且載具在一定距離內，添加隨機刪除機會
                        if dist < 70.0 and dist > vehicleSpawnDistance and math.random() < 0.4 then
                            -- 再次檢查是否為玩家載具
                            if not IsPlayerOwnedVehicle(vehicle) then
                                local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
                                for seat = -1, maxPassengers do
                                    local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                                    if DoesEntityExist(pedInSeat) and not IsPedAPlayer(pedInSeat) then
                                        FadeOutEntity(pedInSeat)
                                    end
                                end
                                FadeOutEntity(vehicle)
                            end
                        end
                    end
                end
            end
        end
        
        -- 如果玩家靜止，更頻繁執行
        Wait(isPlayerStatic and 2000 or 5000)
    end
end)

-- 警察和派遣控制
if DisableCops or DisableDispatch then
    CreateThread(function()
        while true do
            if DisableDispatch then
                for i = 1, 15 do
                    EnableDispatchService(i, false)
                end
            end
            
            if DisableCops then
                SetCreateRandomCops(false)
                SetCreateRandomCopsNotOnScenarios(false)
                SetCreateRandomCopsOnScenarios(false)
            end
            
            Wait(5000)
        end
    end)
end

-- 調整 GTA 的交通生成系統
CreateThread(function()
    while true do
        -- 直接控制交通密度
        SetRandomBoats(false)
        SetGarbageTrucks(false)
        SetRandomTrains(false)
        SetVehicleModelIsSuppressed(GetHashKey("taco"), true)
        SetVehicleModelIsSuppressed(GetHashKey("biff"), true)
        SetVehicleModelIsSuppressed(GetHashKey("hauler"), true)
        SetVehicleModelIsSuppressed(GetHashKey("phantom"), true)
        SetVehicleModelIsSuppressed(GetHashKey("pounder"), true)
        
        -- 如果玩家靜止，額外限制
        if isPlayerStatic then
            -- 當玩家靜止時，更大幅度降低交通密度
            SetParkedVehicleDensityMultiplierThisFrame(VehicleDensityMultiplier * 0.5)
            SetVehicleDensityMultiplierThisFrame(VehicleDensityMultiplier * 0.5)
            SetRandomVehicleDensityMultiplierThisFrame(VehicleDensityMultiplier * 0.5)
        end
        
        Wait(1000)
    end
end)

-- 啟動時立即保護玩家載具
CreateThread(function()
    Wait(1000) -- 等待遊戲載入
    ScanAndProtectPlayerVehicles()
end)
