
-- Players Vehicles Protection Enhanced Version  

-- General Settings
local VehicleDensityMultiplier = Config.VehicleDensityMultiplier
local PedDensityMultiplier = Config.PedDensityMultiplier
local DisableCops = Config.DisableCops
local DisableDispatch = Config.DisableDispatch
local lastVehicleDensity, lastPedDensity = -1, -1
local syncedVehicles = {} -- For tracking synced vehicles

-- Spawn Distances and Limits
local vehicleSpawnDistance = Config.VehicleSpawnDistance
local pedSpawnDistance = Config.PedSpawnDistance
local maxVehiclesInArea = Config.MaxVehiclesInArea
local maxPedsInArea = Config.MaxPedsInArea

-- Extra Settings for Static Player
local playerStaticThreshold = Config.PlayerStaticThreshold
local staticPositionMultiplier = Config.StaticPositionMultiplier
local lastPlayerPosition = vector3(0, 0, 0)
local isPlayerStatic = false
local staticCheckTimer = 0
local STATIC_CHECK_INTERVAL = Config.StaticCheckInterval

-- Cache System
local entityCache = {
    vehicles = {},
    peds = {},
    lastCleanup = 0,
    maxSize = Config.MaxCacheSize
}

-- Cleanup Timers
local cleanupTime = Config.CleanupTime
local cacheCleanupInterval = Config.CacheCleanupInterval
local invisibleVehicleTimers, invisiblePedTimers = {}, {}

-- Constants for Performance Optimization
local THREAD_SLEEP_VEHICLE = Config.ThreadSleepVehicle
local THREAD_SLEEP_PED = Config.ThreadSleepPed
local FADE_STEP = Config.FadeStep
local FADE_WAIT = Config.FadeWait

-- Player Vehicles Security System
local protectedVehicles = {} -- List of protected vehicles
local playerVehicleChecksCounter = 0

-- Debug Variables
local debugMode = Config.DebugMode
local debugLogLevel = Config.DebugLogLevel

-- Debug Log Function
local function DebugLog(message, level)
    if not debugMode then return end
    if level > debugLogLevel then return end
    print(string.format("^2[Artew-NPC-Control] ^7%s", message))
end

-- Entity Control Function (Enhanced)
local function IsEntityValid(entity)
    if entity == nil or entity == 0 or not DoesEntityExist(entity) then 
        return false 
    end
    -- Check if networked
    return NetworkGetEntityIsNetworked(entity)
end

-- Cache Management
local function UpdateEntityCache(entityType, entityId, data)
    if not Config.EnableCache then return end
    
    if not entityCache[entityType] then
        entityCache[entityType] = {}
    end
    
    -- Cache size check
    local cacheSize = 0
    for _ in pairs(entityCache[entityType]) do
        cacheSize = cacheSize + 1
    end
    
    if cacheSize >= entityCache.maxSize then
        -- Delete oldest entry
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
        collectgarbage("collect") -- Garbage collection
    end
end

-- Player Static State Detection
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

-- FPS and Static State Based Density Optimization
local function AdjustDensityBasedOnConditions(playerCoords)
    if not Config.EnableDensityAdjustment then return end
    
    -- Manual density settings are used
    local currentVehicleDensity = VehicleDensityMultiplier
    local currentPedDensity = PedDensityMultiplier
    
    -- Check if player is stationary and adjust density accordingly
    if Config.EnableStaticCheck and CheckPlayerStatic(playerCoords) then
        currentVehicleDensity = currentVehicleDensity * staticPositionMultiplier
        currentPedDensity = currentPedDensity * staticPositionMultiplier
    end
    
    -- Adjust density using native functions
    SetParkedVehicleDensityMultiplierThisFrame(currentVehicleDensity)
    SetVehicleDensityMultiplierThisFrame(currentVehicleDensity)
    SetRandomVehicleDensityMultiplierThisFrame(currentVehicleDensity)
    SetPedDensityMultiplierThisFrame(currentPedDensity)
    SetScenarioPedDensityMultiplierThisFrame(currentPedDensity, currentPedDensity)
    
    -- Additional density checks
    SetAmbientVehicleRangeMultiplierThisFrame(currentVehicleDensity)
    SetAmbientPedRangeMultiplierThisFrame(currentPedDensity)
    
    -- Check traffic density
    SetVehicleModelIsSuppressed(GetHashKey("taco"), currentVehicleDensity == 0)
    SetVehicleModelIsSuppressed(GetHashKey("biff"), currentVehicleDensity == 0)
    SetVehicleModelIsSuppressed(GetHashKey("hauler"), currentVehicleDensity == 0)
    SetVehicleModelIsSuppressed(GetHashKey("phantom"), currentVehicleDensity == 0)
    SetVehicleModelIsSuppressed(GetHashKey("pounder"), currentVehicleDensity == 0)
    
    -- NPC spawn check
    if currentPedDensity == 0 then
        SetPedPopulationBudget(0)
    else
        SetPedPopulationBudget(3)
    end
    
    -- Vehicle spawn check
    if currentVehicleDensity == 0 then
        SetVehiclePopulationBudget(0)
    else
        SetVehiclePopulationBudget(3)
    end
end

-- Slow Fade Out Function
local function FadeOutEntity(entity)
    if not Config.EnableFadeEffect then
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
        return true
    end
    
    if IsEntityValid(entity) then
        -- Check again if player vehicle
        if entity ~= nil and GetEntityType(entity) == 2 then -- Vehicle type
            local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or 0
            if netId == 0 then return false end
            
            local plate = GetVehicleNumberPlateText(entity) or "unknown"
            
            -- If protected vehicle, cancel deletion
            if Config.ProtectPlayerVehicles and (protectedVehicles[netId] or protectedVehicles[plate]) then
                return false
            end
            
            -- Vehicle class check
            local vehClass = GetVehicleClass(entity)
            if Config.ProtectedVehicleClasses[vehClass] then
                return false
            end
            
            -- Check if there is a player in the vehicle
            local maxPassengers = GetVehicleMaxNumberOfPassengers(entity)
            for seat = -1, maxPassengers do
                local ped = GetPedInVehicleSeat(entity, seat)
                if DoesEntityExist(ped) and IsPedAPlayer(ped) then
                    -- If player in vehicle, protect and cancel deletion
                    protectedVehicles[netId] = true
                    protectedVehicles[plate] = true
                    return false
                end
            end
            
            -- Final check: Is the vehicle owned?
            if NetworkGetEntityOwner(entity) ~= nil and GetEntityPopulationType(entity) ~= 7 then
                -- This is a player vehicle, protect and cancel deletion
                protectedVehicles[netId] = true
                protectedVehicles[plate] = true
                return false
            end
        end
        
        -- NPC check
        if Config.ProtectPlayerPeds and IsPedAPlayer(entity) then
            return false
        end
        
        -- NPC type check
        local pedType = GetPedType(entity)
        if Config.ProtectedPedTypes[pedType] then
            return false
        end
        
        -- Original deletion process
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

-- Vehicle Player Check (Enhanced)
local function IsPlayerOwnedVehicle(vehicle)
    if not IsEntityValid(vehicle) then return false end
    
    -- Netid and plate check
    local netId = NetworkGetEntityIsNetworked(vehicle) and NetworkGetNetworkIdFromEntity(vehicle) or 0
    if netId == 0 then return false end
    
    local plate = GetVehicleNumberPlateText(vehicle) or "unknown"
    
    -- If previously protected as a vehicle
    if protectedVehicles[netId] or protectedVehicles[plate] then
        return true
    end
    
    -- Entity owner check
    local owner = NetworkGetEntityOwner(vehicle)
    if owner ~= nil then
        -- PopType 7 = Random/NPC vehicle, others are usually player/script vehicles
        if GetEntityPopulationType(vehicle) ~= 7 then
            -- Mark as player vehicle
            protectedVehicles[netId] = true
            protectedVehicles[plate] = true
            return true
        end
    end
    
    -- Check if there is a player in the vehicle
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    for seat = -1, maxPassengers do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if DoesEntityExist(ped) and IsPedAPlayer(ped) then
            -- Mark as player vehicle
            protectedVehicles[netId] = true
            protectedVehicles[plate] = true
            return true
        end
    end
    
    -- Check by model type (some vehicles are always protected)
    local vehModel = GetEntityModel(vehicle)
    local vehClass = GetVehicleClass(vehicle)
    
    -- Special vehicles, emergency vehicles, or rare vehicles are always protected
    if vehClass == 18 or vehClass == 19 or vehClass == 15 then -- Emergency, police, etc.
        protectedVehicles[netId] = true
        protectedVehicles[plate] = true
        return true
    end
    
    return false
end

-- Vehicle Spawn Check
local function ShouldSpawnVehicle()
    local chance = isPlayerStatic and 0.3 or 0.7
    return math.random() < chance
end

-- NPC Vehicle Sync Check
local function CheckVehicleSync(vehicle)
    if not IsEntityValid(vehicle) then return false end
    
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    if netId == 0 then return false end
    
    -- If vehicle is already synced
    if syncedVehicles[netId] then
        return true
    end
    
    -- If vehicle is close to another player
    local vehicleCoords = GetEntityCoords(vehicle)
    local found = false
    
    -- Check all players
    for i = 0, 32 do
        if NetworkIsPlayerActive(i) then
            local ped = GetPlayerPed(i)
            if DoesEntityExist(ped) and ped ~= PlayerPedId() then
                local playerCoords = GetEntityCoords(ped)
                local dist = #(vehicleCoords - playerCoords)
                
                -- If vehicle is close to another player (50.0 units)
                if dist < 50.0 then
                    found = true
                    break
                end
            end
        end
    end
    
    -- If vehicle is close to other players, sync it
    if found then
        syncedVehicles[netId] = true
        NetworkRequestControlOfEntity(vehicle)
        SetEntityAsMissionEntity(vehicle, true, true)
        return true
    end
    
    return false
end

-- Vehicle Management Function (Player Protected)
local function ManageVehicle(vehicle, playerCoords, playerVehicle, vehicleCount)
    -- If vehicle is invalid, do not process
    if not IsEntityValid(vehicle) then
        return vehicleCount
    end
    
    -- Player vehicle check
    if vehicle == playerVehicle then
        if NetworkGetEntityIsNetworked(vehicle) then
            local netId = NetworkGetNetworkIdFromEntity(vehicle)
            local plate = GetVehicleNumberPlateText(vehicle) or "unknown"
            protectedVehicles[netId] = true
            protectedVehicles[plate] = true
        end
        return vehicleCount
    end
    
    -- Sync check
    if CheckVehicleSync(vehicle) then
        return vehicleCount -- Synced vehicle
    end
    
    -- Enhanced player vehicle check
    if IsPlayerOwnedVehicle(vehicle) then
        return vehicleCount  -- Player vehicle, do not process
    end

    -- From here on, it's for NPC vehicles
    local vehHandle = NetworkGetEntityIsNetworked(vehicle) and NetworkGetNetworkIdFromEntity(vehicle) or 0
    if vehHandle == 0 then
        return vehicleCount -- Invalid network ID, skip this vehicle
    end
    
    local cachedVehicle = GetCachedEntity("vehicles", vehHandle)
    local vehCoords = cachedVehicle and cachedVehicle.coords or GetEntityCoords(vehicle)
    local distance = #(vehCoords - playerCoords)
    
    if distance < vehicleSpawnDistance then
        vehicleCount = vehicleCount + 1
        
        -- If player is stationary or vehicle limit exceeded
        if (isPlayerStatic and vehicleCount > maxVehiclesInArea * staticPositionMultiplier) or 
           vehicleCount > maxVehiclesInArea then
            -- Check all NPCs in the vehicle and delete it with the vehicle
            local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
            for seat = -1, maxPassengers do -- -1 sürücü koltuğu
                local pedInSeat = GetPedInVehicleSeat(vehicle, seat)
                if DoesEntityExist(pedInSeat) and not IsPedAPlayer(pedInSeat) then
                    -- Delete NPC with the vehicle
                    FadeOutEntity(pedInSeat)
                end
            end
            
            -- Check again
            if not IsPlayerOwnedVehicle(vehicle) then
                -- Then delete the vehicle
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

        -- If vehicle is not on screen and player is stationary, delete faster
        local invisibleTimeout = isPlayerStatic and (cleanupTime * 0.6) or cleanupTime
        
        if not IsEntityOnScreen(vehicle) then
            if not invisibleVehicleTimers[vehPlate] then
                invisibleVehicleTimers[vehPlate] = currentTime
            elseif currentTime - invisibleVehicleTimers[vehPlate] > invisibleTimeout then
                    -- Check again if player vehicle
                if not IsPlayerOwnedVehicle(vehicle) then
                    -- Delete NPCs with the vehicle
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

-- NPC Management Function (Updated)
local function ManagePed(ped, playerCoords, pedCount)
    if not IsEntityValid(ped) or IsPedAPlayer(ped) then
        return pedCount
    end

    -- If NPC is in a vehicle, leave it to vehicle management
    local pedVehicle = GetVehiclePedIsIn(ped, false)
    if pedVehicle ~= 0 then
        -- If player vehicle, definitely do not touch
        if IsPlayerOwnedVehicle(pedVehicle) then
            return pedCount
        end
        -- NPC in a vehicle, leave it to vehicle management
        return pedCount
    end

    local pedHandle = NetworkGetEntityIsNetworked(ped) and NetworkGetNetworkIdFromEntity(ped) or 0
    if pedHandle == 0 then
        return pedCount -- Invalid network ID, skip this NPC
    end
    
    local cachedPed = GetCachedEntity("peds", pedHandle)
    local pedCoords = cachedPed and cachedPed.coords or GetEntityCoords(ped)
    local distance = #(pedCoords - playerCoords)
    
    -- If player is stationary, shorten NPC distance
    local activeSpawnDistance = isPlayerStatic and (pedSpawnDistance * 0.7) or pedSpawnDistance
    
    if distance < activeSpawnDistance then
        pedCount = pedCount + 1
        
        -- If player is stationary or NPC limit exceeded
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

        -- If NPC is not on screen and player is stationary, delete faster
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

-- Player Vehicles Scan and Protection Function
local function ScanAndProtectPlayerVehicles()
    local playerCount = GetNumberOfPlayers()
    
    -- Scan all players
    for i = 0, playerCount - 1 do
        local ped = GetPlayerPed(i)
        if DoesEntityExist(ped) then
            -- Check if player has a current vehicle
            local vehicle = GetVehiclePedIsIn(ped, false)
            if DoesEntityExist(vehicle) and NetworkGetEntityIsNetworked(vehicle) then
                local netId = NetworkGetNetworkIdFromEntity(vehicle)
                local plate = GetVehicleNumberPlateText(vehicle) or "unknown"
                protectedVehicles[netId] = true
                protectedVehicles[plate] = true
            end
        end
    end
    
    -- Scan all vehicles and mark player-owned vehicles
    local vehicles = GetGamePool('CVehicle')
    for _, vehicle in ipairs(vehicles) do
        if DoesEntityExist(vehicle) then
            -- Check if there is a player in the vehicle
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
            
            -- Is the entity owner a player?
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

-- Main Vehicle Management Loop
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if DoesEntityExist(playerPed) then
            local playerCoords = GetEntityCoords(playerPed)
            AdjustDensityBasedOnConditions(playerCoords)
            CleanupCache()
            
            -- Regularly scan player vehicles
            playerVehicleChecksCounter = playerVehicleChecksCounter + 1
            if playerVehicleChecksCounter >= 10 then
                ScanAndProtectPlayerVehicles()
                playerVehicleChecksCounter = 0
            end
            
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)
            if DoesEntityExist(playerVehicle) and NetworkGetEntityIsNetworked(playerVehicle) then
                -- Always protect player vehicle
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

-- Main NPC Management Loop
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

-- New Extra Traffic Control Mechanism
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        
        if DoesEntityExist(playerPed) then
            -- If player is stationary, clean up surrounding vehicles aggressively
            if isPlayerStatic then
                local playerCoords = GetEntityCoords(playerPed)
                local vehicles = GetGamePool('CVehicle')
                local playerVehicle = GetVehiclePedIsIn(playerPed, false)
                
                for _, vehicle in ipairs(vehicles) do
                    if DoesEntityExist(vehicle) and vehicle ~= playerVehicle and not IsPlayerOwnedVehicle(vehicle) then
                        local vehCoords = GetEntityCoords(vehicle)
                        local dist = #(vehCoords - playerCoords)
                        
                        -- If player is stationary and vehicle is a certain distance away, add a chance to delete randomly
                        if dist < 70.0 and dist > vehicleSpawnDistance and math.random() < 0.4 then
                            -- Check again if player vehicle
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
        
        -- If player is stationary, run more frequently
        Wait(isPlayerStatic and 2000 or 5000)
    end
end)

-- Police and Dispatch Control
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

-- Adjust GTA's Traffic Spawn System
CreateThread(function()
    while true do
        -- Directly control traffic density
        SetRandomBoats(false)
        SetGarbageTrucks(false)
        SetRandomTrains(false)
        SetVehicleModelIsSuppressed(GetHashKey("taco"), true)
        SetVehicleModelIsSuppressed(GetHashKey("biff"), true)
        SetVehicleModelIsSuppressed(GetHashKey("hauler"), true)
        SetVehicleModelIsSuppressed(GetHashKey("phantom"), true)
        SetVehicleModelIsSuppressed(GetHashKey("pounder"), true)
        
        -- If player is stationary, additional restrictions
        if isPlayerStatic then
            -- When player is stationary, reduce traffic density even more
            SetParkedVehicleDensityMultiplierThisFrame(VehicleDensityMultiplier * 0.5)
            SetVehicleDensityMultiplierThisFrame(VehicleDensityMultiplier * 0.5)
            SetRandomVehicleDensityMultiplierThisFrame(VehicleDensityMultiplier * 0.5)
        end
        
        Wait(1000)
    end
end)

-- Immediately protect player vehicles at the start
CreateThread(function()
    Wait(1000) -- Wait for the game to load
    ScanAndProtectPlayerVehicles()
end)