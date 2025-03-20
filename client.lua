-- FPS Dostu Araç ve NPC Yönetimi
-- Oyuncu ve Oyuncuların Araçlarını Koruyan Geliştirilmiş Versiyon

-- Genel Ayarlar
local VehicleDensityMultiplier, PedDensityMultiplier = 0.1, 0.2 -- Daha düşük yoğunluk
local DisableCops, DisableDispatch = true, true
local lastVehicleDensity, lastPedDensity = -1, -1
local syncedVehicles = {} -- Senkronize edilmiş araçları takip etmek için

-- Spawn Mesafeleri ve Limitler
local vehicleSpawnDistance, pedSpawnDistance = 30.0, 25.0 -- Daha kısa mesafe
local maxVehiclesInArea, maxPedsInArea = 5, 8 -- Daha az NPC ve araç

-- Durağan Oyuncu için Ekstra Ayarlar
local playerStaticThreshold = 5.0 -- Oyuncu bu mesafeden az hareket ettiğinde durağan kabul edilir
local staticPositionMultiplier = 0.5 -- Durağan konumdayken density'i bu kadar azalt
local lastPlayerPosition = vector3(0, 0, 0)
local isPlayerStatic = false
local staticCheckTimer = 0
local STATIC_CHECK_INTERVAL = 2000 -- 2 saniye

-- Önbellek Sistemi
local entityCache = {
    vehicles = {},
    peds = {},
    lastCleanup = 0,
    maxSize = 100 -- Maksimum önbellek boyutu
}

-- Temizleme Zamanlayıcıları
local cleanupTime = 8000 -- 8 saniye (daha hızlı temizleme)
local cacheCleanupInterval = 25000 -- 25 saniye (daha sık önbellek temizleme)
local invisibleVehicleTimers, invisiblePedTimers = {}, {}

-- Performans Optimizasyonu için Sabitler
local THREAD_SLEEP_VEHICLE = 2500 -- Ana döngü bekleme süresi
local THREAD_SLEEP_PED = 3000
local FADE_STEP = 35 -- Daha hızlı fade out
local FADE_WAIT = 30 -- Daha hızlı fade bekleme

-- OYUNCU ARAÇLARI İÇİN GÜVENLİK SİSTEMİ
local protectedVehicles = {} -- Korunacak araçların listesi
local playerVehicleChecksCounter = 0

-- Entity Kontrol Fonksiyonu (Geliştirilmiş)
local function IsEntityValid(entity)
    if entity == nil or entity == 0 or not DoesEntityExist(entity) then 
        return false 
    end
    -- Networked olup olmadığını kontrol et
    return NetworkGetEntityIsNetworked(entity)
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

-- Oyuncu Durağan Durum Tespiti
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

-- FPS ve Durağan Durum Bazlı Yoğunluk Optimizasyonu
local function AdjustDensityBasedOnConditions(playerCoords)
    local fps = 1.0 / GetFrameTime()
    local baseVehicleDensity, basePedDensity
    
    -- FPS bazlı yoğunluk ayarı
    if fps < 30 then
        baseVehicleDensity, basePedDensity = 0.05, 0.1
    elseif fps < 50 then
        baseVehicleDensity, basePedDensity = 0.08, 0.15
    else
        baseVehicleDensity, basePedDensity = 0.1, 0.2
    end
    
    -- Oyuncu durağan mı kontrol et ve ona göre yoğunluğu ayarla
    if CheckPlayerStatic(playerCoords) then
        VehicleDensityMultiplier = baseVehicleDensity * staticPositionMultiplier
        PedDensityMultiplier = basePedDensity * staticPositionMultiplier
    else
        VehicleDensityMultiplier = baseVehicleDensity
        PedDensityMultiplier = basePedDensity
    end
    
    -- Native fonksiyonlarla yoğunluğu ayarla (eğer değer değiştiyse)
    if VehicleDensityMultiplier ~= lastVehicleDensity then
        SetParkedVehicleDensityMultiplier(VehicleDensityMultiplier)
        SetVehicleDensityMultiplier(VehicleDensityMultiplier)
        SetRandomVehicleDensityMultiplier(VehicleDensityMultiplier)
        lastVehicleDensity = VehicleDensityMultiplier
    end
    
    if PedDensityMultiplier ~= lastPedDensity then
        SetPedDensityMultiplier(PedDensityMultiplier)
        SetScenarioPedDensityMultiplier(PedDensityMultiplier, PedDensityMultiplier)
        lastPedDensity = PedDensityMultiplier
    end
end

-- Yavaşça Silme Fonksiyonu
local function FadeOutEntity(entity)
    if IsEntityValid(entity) then
        -- Son bir kez daha oyuncu aracı kontrolü
        if entity ~= nil and GetEntityType(entity) == 2 then -- Araç türü
            local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or 0
            if netId == 0 then return false end
            
            local plate = GetVehicleNumberPlateText(entity) or "unknown"
            
            -- Eğer korunan bir araç ise silme işlemini iptal et
            if protectedVehicles[netId] or protectedVehicles[plate] then
                return false
            end
            
            -- Araçta oyuncu var mı kontrol et
            local maxPassengers = GetVehicleMaxNumberOfPassengers(entity)
            for seat = -1, maxPassengers do
                local ped = GetPedInVehicleSeat(entity, seat)
                if DoesEntityExist(ped) and IsPedAPlayer(ped) then
                    -- Araçta oyuncu varsa korumaya al ve silme
                    protectedVehicles[netId] = true
                    protectedVehicles[plate] = true
                    return false
                end
            end
            
            -- Son kontrol: Araç sahiplenilmiş mi?
            if NetworkGetEntityOwner(entity) ~= nil and GetEntityPopulationType(entity) ~= 7 then
                -- Bu bir oyuncu aracı, korumaya al ve silme
                protectedVehicles[netId] = true
                protectedVehicles[plate] = true
                return false
            end
        end
        
        -- Orijinal silme işlemi
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

-- Araç Oyuncu Kontrolü (Gelişmiş)
local function IsPlayerOwnedVehicle(vehicle)
    if not IsEntityValid(vehicle) then return false end
    
    -- Netid ve plaka kontrolü
    local netId = NetworkGetEntityIsNetworked(vehicle) and NetworkGetNetworkIdFromEntity(vehicle) or 0
    if netId == 0 then return false end
    
    local plate = GetVehicleNumberPlateText(vehicle) or "unknown"
    
    -- Eğer daha önce korunan araç olarak işaretlendiyse
    if protectedVehicles[netId] or protectedVehicles[plate] then
        return true
    end
    
    -- Entity sahibi kontrolü
    local owner = NetworkGetEntityOwner(vehicle)
    if owner ~= nil then
        -- PopType 7 = Random/NPC aracı, diğerleri genellikle oyuncu/script araçları
        if GetEntityPopulationType(vehicle) ~= 7 then
            -- Oyuncu aracı olarak işaretle
            protectedVehicles[netId] = true
            protectedVehicles[plate] = true
            return true
        end
    end
    
    -- Araçta oyuncu var mı kontrol et
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    for seat = -1, maxPassengers do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if DoesEntityExist(ped) and IsPedAPlayer(ped) then
            -- Oyuncu aracı olarak işaretle
            protectedVehicles[netId] = true
            protectedVehicles[plate] = true
            return true
        end
    end
    
    -- Model tipine göre kontrol (bazı araç modelleri her zaman korunabilir)
    local vehModel = GetEntityModel(vehicle)
    local vehClass = GetVehicleClass(vehicle)
    
    -- Özel araçlar, acil durum araçları veya nadir araçlar her zaman korunur
    if vehClass == 18 or vehClass == 19 or vehClass == 15 then -- Acil durum, polis, vb.
        protectedVehicles[netId] = true
        protectedVehicles[plate] = true
        return true
    end
    
    return false
end

-- Araç Spawn Kontrolü
local function ShouldSpawnVehicle()
    local chance = isPlayerStatic and 0.3 or 0.7
    return math.random() < chance
end

-- NPC Araç Senkronizasyon Kontrolü
local function CheckVehicleSync(vehicle)
    if not IsEntityValid(vehicle) then return false end
    
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then return false end
    
    -- Eğer araç zaten senkronize edilmişse
    if syncedVehicles[netId] then
        return true
    end
    
    -- Araç başka bir oyuncuya yakınsa
    local vehicleCoords = GetEntityCoords(vehicle)
    local found = false
    
    -- Tüm oyuncuları kontrol et
    for i = 0, 32 do
        if NetworkIsPlayerActive(i) then
            local ped = GetPlayerPed(i)
            if DoesEntityExist(ped) and ped ~= PlayerPedId() then
                local playerCoords = GetEntityCoords(ped)
                local dist = #(vehicleCoords - playerCoords)
                
                -- Eğer araç başka bir oyuncuya yakınsa (50.0 birim)
                if dist < 50.0 then
                    found = true
                    break
                end
            end
        end
    end
    
    -- Eğer araç başka oyunculara yakınsa, senkronize et
    if found then
        syncedVehicles[netId] = true
        NetworkRequestControlOfEntity(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        return true
    end
    
    return false
end

-- Araç Yönetimi Fonksiyonu (Oyuncu Korumalı)
local function ManageVehicle(vehicle, playerCoords, playerVehicle, vehicleCount)
    -- Araç geçerli değilse işlem yapma
    if not IsEntityValid(vehicle) then
        return vehicleCount
    end
    
    -- Oyuncunun kendi aracı kontrolü
    if vehicle == playerVehicle then
        if NetworkGetEntityIsNetworked(vehicle) then
            local netId = NetworkGetNetworkIdFromEntity(vehicle)
            local plate = GetVehicleNumberPlateText(vehicle) or "unknown"
            protectedVehicles[netId] = true
            protectedVehicles[plate] = true
        end
        return vehicleCount
    end
    
    -- Senkronizasyon kontrolü
    if CheckVehicleSync(vehicle) then
        return vehicleCount -- Senkronize edilmiş aracı yönetme
    end
    
    -- Gelişmiş oyuncu aracı kontrolü
    if IsPlayerOwnedVehicle(vehicle) then
        return vehicleCount  -- Oyuncu aracı ise işlem yapma
    end

    -- Buradan sonrası NPC araçları için işlemler
    local vehHandle = NetworkGetEntityIsNetworked(vehicle) and NetworkGetNetworkIdFromEntity(vehicle) or 0
    if vehHandle == 0 then
        return vehicleCount -- Geçersiz network ID, bu aracı atla
    end
    
    local cachedVehicle = GetCachedEntity("vehicles", vehHandle)
    local vehCoords = cachedVehicle and cachedVehicle.coords or GetEntityCoords(vehicle)
    local distance = #(vehCoords - playerCoords)
    
    if distance < vehicleSpawnDistance then
        vehicleCount = vehicleCount + 1
        
        -- Oyuncu durağan durumdaysa veya araç limiti aşıldıysa
        if (isPlayerStatic and vehicleCount > maxVehiclesInArea * staticPositionMultiplier) or 
           vehicleCount > maxVehiclesInArea then
            -- Araçtaki tüm NPC'leri kontrol et ve araçla birlikte sil
            local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
            for seat = -1, maxPassengers do -- -1 sürücü koltuğu
                local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                if DoesEntityExist(pedInSeat) and not IsPedAPlayer(pedInSeat) then
                    -- Araçtaki NPC'yi araçla birlikte sil
                    FadeOutEntity(pedInSeat)
                end
            end
            
            -- Son bir kez daha kontrol
            if not IsPlayerOwnedVehicle(vehicle) then
                -- Sonra aracı sil
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

        -- Araç ekranda görünmüyorsa ve oyuncu durağansa daha hızlı sil
        local invisibleTimeout = isPlayerStatic and (cleanupTime * 0.6) or cleanupTime
        
        if not IsEntityOnScreen(vehicle) then
            if not invisibleVehicleTimers[vehPlate] then
                invisibleVehicleTimers[vehPlate] = currentTime
            elseif currentTime - invisibleVehicleTimers[vehPlate] > invisibleTimeout then
                -- Son bir kez daha oyuncu aracı kontrolü
                if not IsPlayerOwnedVehicle(vehicle) then
                    -- Araçla birlikte içindeki NPC'leri de sil
                    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
                    for seat = -1, maxPassengers do -- -1 sürücü koltuğu
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

-- NPC Yönetimi Fonksiyonu (Güncellenmiş)
local function ManagePed(ped, playerCoords, pedCount)
    if not IsEntityValid(ped) or IsPedAPlayer(ped) then
        return pedCount
    end

    -- Eğer NPC bir araçtaysa, aracı yönetme işlemlerine bırak
    local pedVehicle = GetVehiclePedIsIn(ped, false)
    if pedVehicle ~= 0 then
        -- Eğer oyuncu aracındaysa kesinlikle dokunma
        if IsPlayerOwnedVehicle(pedVehicle) then
            return pedCount
        end
        -- NPC bir araçta, bu NPC'yi atlayarak araç yönetim fonksiyonuna bırakıyoruz
        return pedCount
    end

    local pedHandle = NetworkGetEntityIsNetworked(ped) and NetworkGetNetworkIdFromEntity(ped) or 0
    if pedHandle == 0 then
        return pedCount -- Geçersiz network ID, bu NPC'yi atla
    end
    
    local cachedPed = GetCachedEntity("peds", pedHandle)
    local pedCoords = cachedPed and cachedPed.coords or GetEntityCoords(ped)
    local distance = #(pedCoords - playerCoords)
    
    -- Oyuncu durağansa NPC mesafesini daha da kısalt
    local activeSpawnDistance = isPlayerStatic and (pedSpawnDistance * 0.7) or pedSpawnDistance
    
    if distance < activeSpawnDistance then
        pedCount = pedCount + 1
        
        -- Oyuncu durağan durumdaysa veya NPC limiti aşıldıysa
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

        -- NPC ekranda görünmüyorsa ve oyuncu durağansa daha hızlı sil
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

-- Oyuncu Araçlarını Tarama ve Koruma Fonksiyonu
local function ScanAndProtectPlayerVehicles()
    local playerCount = GetNumberOfPlayers()
    
    -- Tüm oyuncuları tara
    for i = 0, playerCount - 1 do
        local ped = GetPlayerPed(i)
        if DoesEntityExist(ped) then
            -- Oyuncunun mevcut aracını kontrol et
            local vehicle = GetVehiclePedIsIn(ped, false)
            if DoesEntityExist(vehicle) and NetworkGetEntityIsNetworked(vehicle) then
                local netId = NetworkGetNetworkIdFromEntity(vehicle)
                local plate = GetVehicleNumberPlateText(vehicle) or "unknown"
                protectedVehicles[netId] = true
                protectedVehicles[plate] = true
            end
        end
    end
    
    -- Tüm araçları tara ve oyuncu sahibi olanları işaretle
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            -- Araçta oyuncu var mı kontrolü
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
            
            -- Entity sahibi oyuncu mu?
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

-- Ana Araç Yönetim Döngüsü
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if DoesEntityExist(playerPed) then
            local playerCoords = GetEntityCoords(playerPed)
            AdjustDensityBasedOnConditions(playerCoords)
            CleanupCache()
            
            -- Düzenli olarak oyuncu araçlarını tara
            playerVehicleChecksCounter = playerVehicleChecksCounter + 1
            if playerVehicleChecksCounter >= 10 then
                ScanAndProtectPlayerVehicles()
                playerVehicleChecksCounter = 0
            end
            
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)
            if DoesEntityExist(playerVehicle) and NetworkGetEntityIsNetworked(playerVehicle) then
                -- Oyuncunun aracını her zaman korumaya al
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

-- Ana NPC Yönetim Döngüsü
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

-- Yeni Ekstra Trafik Kontrol Mekanizması
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if DoesEntityExist(playerPed) then
            -- Oyuncu durağan ise çevreden araçları agresif bir şekilde temizle
            if isPlayerStatic then
                local playerCoords = GetEntityCoords(playerPed)
                local vehicles = GetGamePool('CVehicle')
                local playerVehicle = GetVehiclePedIsIn(playerPed, false)
                
                for _, vehicle in ipairs(vehicles) do
                    if DoesEntityExist(vehicle) and vehicle ~= playerVehicle and not IsPlayerOwnedVehicle(vehicle) then
                        local vehCoords = GetEntityCoords(vehicle)
                        local dist = #(vehCoords - playerCoords)
                        
                        -- Oyuncu durağan ve araç belli bir mesafede ise rastgele silme olasılığı ekle
                        if dist < 70.0 and dist > vehicleSpawnDistance and math.random() < 0.4 then
                            -- Son bir kez daha oyuncu aracı kontrolü yap
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
        
        -- Durağan durumdayken daha sık çalıştır
        Wait(isPlayerStatic and 2000 or 5000)
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

-- GTA'nın Trafik Spawn Sistemini Ayarla
CreateThread(function()
    while true do
        -- Trafik yoğunluğunu doğrudan kontrol et
        SetRandomBoats(false)
        SetGarbageTrucks(false)
        SetRandomTrains(false)
        SetVehicleModelIsSuppressed(GetHashKey("taco"), true)
        SetVehicleModelIsSuppressed(GetHashKey("biff"), true)
        SetVehicleModelIsSuppressed(GetHashKey("hauler"), true)
        SetVehicleModelIsSuppressed(GetHashKey("phantom"), true)
        SetVehicleModelIsSuppressed(GetHashKey("pounder"), true)
        
        -- Oyuncu durağan durumdaysa ek kısıtlamalar
        if isPlayerStatic then
            -- Durağan durumdayken tüm trafik yoğunluğunu daha da azalt
            SetParkedVehicleDensityMultiplierThisFrame(VehicleDensityMultiplier * 0.5)
            SetVehicleDensityMultiplierThisFrame(VehicleDensityMultiplier * 0.5)
            SetRandomVehicleDensityMultiplierThisFrame(VehicleDensityMultiplier * 0.5)
        end
        
        Wait(1000)
    end
end)

-- Başlangıçta oyuncu araçlarını hemen korumaya al
CreateThread(function()
    Wait(1000) -- Oyun tam yüklensin diye kısa bir bekleme
    ScanAndProtectPlayerVehicles()
end)