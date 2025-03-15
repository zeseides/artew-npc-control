-- FPS Dostu Araç ve NPC Yönetimi

-- Genel Ayarlar
local VehicleDensityMultiplier, PedDensityMultiplier = 0.2, 0.4
local DisableCops, DisableDispatch = true, true
local lastVehicleDensity, lastPedDensity = -1, -1

-- Spawn Mesafeleri ve Limitler
local vehicleSpawnDistance, pedSpawnDistance = 50.0, 50.0
local maxVehiclesInArea, maxPedsInArea = 10, 15

-- Temizleme Zamanlayıcıları
local cleanupTime = 15000
local invisibleVehicleTimers, invisiblePedTimers = {}, {}

-- FPS Bazlı Yoğunluk Optimizasyonu
local function AdjustDensityBasedOnFPS()
    local fps = 1.0 / GetFrameTime()
    if fps < 30 then
        VehicleDensityMultiplier, PedDensityMultiplier = 0.1, 0.2
    elseif fps < 50 then
        VehicleDensityMultiplier, PedDensityMultiplier = 0.2, 0.3
    else
        VehicleDensityMultiplier, PedDensityMultiplier = 0.2, 0.4
    end
end

-- Ağ hatalarını önlemek için güvenli şekilde network ID alma
local function SafeGetNetworkID(entity)
    if DoesEntityExist(entity) and NetworkGetEntityIsNetworked(entity) then
        return NetworkGetNetworkIdFromEntity(entity)
    else
        return nil
    end
end

-- Yavaşça Silme Fonksiyonu (NPC ve araçları yavaşça kaybettirir)
local function FadeOutEntity(entity)
    if DoesEntityExist(entity) then
        for alpha = 255, 0, -25 do
            SetEntityAlpha(entity, alpha, false)
            Wait(50)
        end
        DeleteEntity(entity)
    end
end

-- Araçları Yönetme Threadi
CreateThread(function()
    while true do
        local sleep = 4000
        AdjustDensityBasedOnFPS()
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerVehicle = GetVehiclePedIsIn(playerPed, false)

        local vehicles = GetGamePool('CVehicle')
        local vehicleCount = 0
        local currentTime = GetGameTimer()

        for _, veh in ipairs(vehicles) do
            if DoesEntityExist(veh) and #(GetEntityCoords(veh) - playerCoords) < vehicleSpawnDistance then
                if veh == playerVehicle then goto continue_vehicle end
                vehicleCount = vehicleCount + 1
                if vehicleCount > maxVehiclesInArea then FadeOutEntity(veh) end
                local vehPlate = GetVehicleNumberPlateText(veh) or "unknown"
                
                if not IsEntityOnScreen(veh) then
                    if not invisibleVehicleTimers[vehPlate] then
                        invisibleVehicleTimers[vehPlate] = currentTime
                    elseif currentTime - invisibleVehicleTimers[vehPlate] > cleanupTime then
                        FadeOutEntity(veh)
                        invisibleVehicleTimers[vehPlate] = nil
                    end
                else
                    invisibleVehicleTimers[vehPlate] = nil
                end
                ::continue_vehicle::
            end
        end
        Wait(sleep)
    end
end)

-- NPC'leri Yönetme Threadi
CreateThread(function()
    while true do
        local sleep = 5000
        AdjustDensityBasedOnFPS()
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        local peds = GetGamePool('CPed')
        local pedCount = 0
        local currentTime = GetGameTimer()

        for _, ped in ipairs(peds) do
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) and #(GetEntityCoords(ped) - playerCoords) < pedSpawnDistance then
                pedCount = pedCount + 1
                if pedCount > maxPedsInArea then FadeOutEntity(ped) end

                -- Güvenli network ID alma
                local pedId = nil
                if NetworkGetEntityIsNetworked(ped) then
                    pedId = PedToNet(ped)
                end
                
                if pedId then
                    if not IsEntityOnScreen(ped) then
                        if not invisiblePedTimers[pedId] then
                            invisiblePedTimers[pedId] = currentTime
                        elseif currentTime - invisiblePedTimers[pedId] > cleanupTime then
                            FadeOutEntity(ped)
                            invisiblePedTimers[pedId] = nil
                        end
                    else
                        invisiblePedTimers[pedId] = nil
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
