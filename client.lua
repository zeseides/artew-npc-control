-- FPS Dostu Araç ve NPC Yönetimi

-- Genel Ayarlar
local VehicleDensityMultiplier, PedDensityMultiplier = 0.2, 0.4 -- Araç ve yaya yoğunluğu ayarı
local DisableCops, DisableDispatch = true, true -- Polis ve acil durum birimlerini devre dışı bırak
local lastVehicleDensity, lastPedDensity = -1, -1 -- Son bilinen yoğunluk değerleri

-- Spawn Mesafeleri ve Limitler
local vehicleSpawnDistance, pedSpawnDistance = 50.0, 50.0 -- Araç ve yaya spawn mesafesi
local maxVehiclesInArea, maxPedsInArea = 10, 15 -- Maksimum araç ve yaya limiti

-- Temizleme Zamanlayıcıları
local cleanupTime = 15000 -- 15 saniye sonra görünmeyen araçlar ve yayalar temizlenecek
local invisibleVehicleTimers, invisiblePedTimers = {}, {} -- Görünmeyen araç ve yayalar için zamanlayıcılar

-- FPS Bazlı Yoğunluk Optimizasyonu
local function AdjustDensityBasedOnFPS()
    local fps = 1.0 / GetFrameTime()
    if fps < 30 then
        VehicleDensityMultiplier, PedDensityMultiplier = 0.1, 0.2 -- FPS düşükse yoğunluk azaltılır
    elseif fps < 50 then
        VehicleDensityMultiplier, PedDensityMultiplier = 0.2, 0.3 -- Orta FPS için yoğunluk dengelenir
    else
        VehicleDensityMultiplier, PedDensityMultiplier = 0.2, 0.4 -- FPS yüksekse yoğunluk artırılır
    end
end

-- Yavaşça Silme Fonksiyonu (NPC ve araçları yavaşça kaybettirir)
local function FadeOutEntity(entity)
    if DoesEntityExist(entity) then
        for alpha = 255, 0, -25 do
            SetEntityAlpha(entity, alpha, false) -- Şeffaflığı azalt
            Wait(50) -- Bekleme süresi
        end
        DeleteEntity(entity) -- Tamamen sil
    end
end

-- Araçları Yönetme Threadi
CreateThread(function()
    while true do
        local sleep = 4000 -- Döngü bekleme süresi (4 saniye)
        AdjustDensityBasedOnFPS() -- FPS bazlı yoğunluk kontrolü
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerVehicle = GetVehiclePedIsIn(playerPed, false) -- Oyuncunun aracı
        
        local vehicles = GetGamePool('CVehicle') -- Haritadaki tüm araçları al
        local vehicleCount = 0
        local currentTime = GetGameTimer()

        for _, veh in ipairs(vehicles) do
            local vehCoords = GetEntityCoords(veh) -- Araç koordinatlarını al
            if DoesEntityExist(veh) and #(vehCoords - playerCoords) < vehicleSpawnDistance then
                if veh == playerVehicle then goto continue_vehicle end -- Oyuncunun aracını atla
                vehicleCount = vehicleCount + 1
                if vehicleCount > maxVehiclesInArea then FadeOutEntity(veh) end -- Araç sınırı aşılırsa sil
                local vehPlate = GetVehicleNumberPlateText(veh) or "unknown"
                if not IsEntityOnScreen(veh) then
                    if not invisibleVehicleTimers[vehPlate] then
                        invisibleVehicleTimers[vehPlate] = currentTime -- Zamanlayıcı başlat
                    elseif currentTime - invisibleVehicleTimers[vehPlate] > cleanupTime then
                        FadeOutEntity(veh) -- Araç belirlenen süreden uzun süredir görünmüyorsa sil
                        invisibleVehicleTimers[vehPlate] = nil
                    end
                else invisibleVehicleTimers[vehPlate] = nil end -- Araç tekrar görünürse zamanlayıcı sıfırla
                ::continue_vehicle::
            end
        end
        Wait(sleep) -- Döngü tekrar başlamadan önce bekle
    end
end)

-- NPC'leri Yönetme Threadi
CreateThread(function()
    while true do
        local sleep = 5000 -- Döngü bekleme süresi (5 saniye)
        AdjustDensityBasedOnFPS() -- FPS bazlı yoğunluk kontrolü
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        local peds = GetGamePool('CPed') -- Haritadaki tüm NPC'leri al
        local pedCount = 0
        local currentTime = GetGameTimer()

        for _, ped in ipairs(peds) do
            local pedCoords = GetEntityCoords(ped) -- NPC koordinatlarını al
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) and #(pedCoords - playerCoords) < pedSpawnDistance then
                pedCount = pedCount + 1
                if pedCount > maxPedsInArea then FadeOutEntity(ped) end -- NPC sınırı aşılırsa sil
                local pedId = PedToNet(ped)
                if not IsEntityOnScreen(ped) then
                    if not invisiblePedTimers[pedId] then
                        invisiblePedTimers[pedId] = currentTime -- Zamanlayıcı başlat
                    elseif currentTime - invisiblePedTimers[pedId] > cleanupTime then
                        FadeOutEntity(ped) -- NPC belirlenen süreden uzun süredir görünmüyorsa sil
                        invisiblePedTimers[pedId] = nil
                    end
                else invisiblePedTimers[pedId] = nil end -- NPC tekrar görünürse zamanlayıcı sıfırla
            end
        end
        Wait(sleep) -- Döngü tekrar başlamadan önce bekle
    end
end)