-- FPS Dostu Araç ve NPC Yönetimi

-- Genel Ayarlar
local VehicleDensityMultiplier, PedDensityMultiplier = 0.15, 0.3 -- Daha düşük yoğunluk
local DisableCops, DisableDispatch = true, true
local lastVehicleDensity, lastPedDensity = -1, -1

-- Spawn Mesafeleri ve Limitler
local vehicleSpawnDistance, pedSpawnDistance = 40.0, 35.0 -- Daha kısa mesafe
local maxVehiclesInArea, maxPedsInArea = 8, 12 -- Daha az NPC ve araç

-- Önbellek Sistemi
local entityCache = {
    vehicles = {},
    peds = {},
    lastCleanup = 0,
    maxSize = 100 -- Maksimum önbellek boyutu
}

-- Temizleme Zamanlayıcıları
local cleanupTime = 10000 -- 10 saniye (daha hızlı temizleme)
local cacheCleanupInterval = 30000 -- 30 saniye (daha sık önbellek temizleme)
local invisibleVehicleTimers, invisiblePedTimers = {}, {}

-- Performans Optimizasyonu için Sabitler
local THREAD_SLEEP_VEHICLE = 3000 -- Ana döngü bekleme süresi
local THREAD_SLEEP_PED = 4000
local FADE_STEP = 35 -- Daha hızlı fade out
local FADE_WAIT = 30 -- Daha hızlı fade bekleme

-- Entity Kontrol Fonksiyonu
local function IsEntityValid(entity)
    return entity ~= nil and DoesEntityExist(entity) and NetworkGetEntityIsNetworked(entity)
end

-- Önbellek Yönetimi
local function UpdateEntityCache(entityType, entityId, data)
    if not entityCache[entityType] then
        entityCache[entityType] = {}
    end
    
    -- Önbellek boyutu kontrolü
    local cacheSize = 0
    for _ in pairs(entityCache[entityType]) do
        cacheSize = cacheSize + 1
    end
    
    if cacheSize >= entityCache.maxSize then
        -- En eski girdiyi sil
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
        collectgarbage("collect") -- Çöp toplama
    end
end

-- FPS Bazlı Yoğunluk Optimizasyonu
local function AdjustDensityBasedOnFPS()
    local fps = 1.0 / GetFrameTime()
    if fps < 30 then
        VehicleDensityMultiplier, PedDensityMultiplier = 0.05, 0.1
    elseif fps < 50 then
        VehicleDensityMultiplier, PedDensityMultiplier = 0.1, 0.2
    else
        VehicleDensityMultiplier, PedDensityMultiplier = 0.15, 0.3
    end
end

-- Yavaşça Silme Fonksiyonu
local function FadeOutEntity(entity)
    if IsEntityValid(entity) then
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
    end
end

-- Araç Yönetimi Fonksiyonu
local function ManageVehicle(vehicle, playerCoords, playerVehicle, vehicleCount)
    if not IsEntityValid(vehicle) or vehicle == playerVehicle then
        return vehicleCount
    end

    local vehHandle = NetworkGetNetworkIdFromEntity(vehicle)
    local cachedVehicle = GetCachedEntity("vehicles", vehHandle)
    local vehCoords = cachedVehicle and cachedVehicle.coords or GetEntityCoords(vehicle)
    local distance = #(vehCoords - playerCoords)
    
    if distance < vehicleSpawnDistance then
        vehicleCount = vehicleCount + 1
        
        if vehicleCount > maxVehiclesInArea then
            FadeOutEntity(vehicle)
            return vehicleCount
        end

        local vehPlate = GetVehicleNumberPlateText(vehicle) or "unknown"
        local currentTime = GetGameTimer()
        
        UpdateEntityCache("vehicles", vehHandle, {
            coords = vehCoords,
            plate = vehPlate,
            lastSeen = currentTime
        })

        if not IsEntityOnScreen(vehicle) then
            if not invisibleVehicleTimers[vehPlate] then
                invisibleVehicleTimers[vehPlate] = currentTime
            elseif currentTime - invisibleVehicleTimers[vehPlate] > cleanupTime then
                FadeOutEntity(vehicle)
                invisibleVehicleTimers[vehPlate] = nil
            end
        else 
            invisibleVehicleTimers[vehPlate] = nil
        end
    end
    
    return vehicleCount
end

-- NPC Yönetimi Fonksiyonu
local function ManagePed(ped, playerCoords, pedCount)
    if not IsEntityValid(ped) or IsPedAPlayer(ped) then
        return pedCount
    end

    local pedHandle = NetworkGetNetworkIdFromEntity(ped)
    local cachedPed = GetCachedEntity("peds", pedHandle)
    local pedCoords = cachedPed and cachedPed.coords or GetEntityCoords(ped)
    local distance = #(pedCoords - playerCoords)
    
    if distance < pedSpawnDistance then
        pedCount = pedCount + 1
        
        if pedCount > maxPedsInArea then
            FadeOutEntity(ped)
            return pedCount
        end

        local currentTime = GetGameTimer()
        
        UpdateEntityCache("peds", pedHandle, {
            coords = pedCoords,
            lastSeen = currentTime
        })

        if not IsEntityOnScreen(ped) then
            if not invisiblePedTimers[pedHandle] then
                invisiblePedTimers[pedHandle] = currentTime
            elseif currentTime - invisiblePedTimers[pedHandle] > cleanupTime then
                FadeOutEntity(ped)
                invisiblePedTimers[pedHandle] = nil
            end
        else
            invisiblePedTimers[pedHandle] = nil
        end
    end
    
    return pedCount
end

-- Ana Araç Yönetim Döngüsü
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if DoesEntityExist(playerPed) then
            AdjustDensityBasedOnFPS()
            CleanupCache()
            
            local playerCoords = GetEntityCoords(playerPed)
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)
            local vehicles = GetGamePool('CVehicle')
            local vehicleCount = 0
            
            for _, vehicle in ipairs(vehicles) do
                vehicleCount = ManageVehicle(vehicle, playerCoords, playerVehicle, vehicleCount)
            end
        end
        
        Wait(THREAD_SLEEP_VEHICLE)
    end
end)

-- Ana NPC Yönetim Döngüsü
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if DoesEntityExist(playerPed) then
            AdjustDensityBasedOnFPS()
            CleanupCache()
            
            local playerCoords = GetEntityCoords(playerPed)
            local peds = GetGamePool('CPed')
            local pedCount = 0
            
            for _, ped in ipairs(peds) do
                pedCount = ManagePed(ped, playerCoords, pedCount)
            end
        end
        
        Wait(THREAD_SLEEP_PED)
    end
end)

-- Polis ve Dispatch Kontrolü
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