Config = {}

-- NPC ve Araç Yoğunluğu Ayarları
Config.VehicleDensityMultiplier = 0.0 -- Araç yoğunluğu (0.0 - 1.0 arası)
Config.PedDensityMultiplier = 0.0 -- NPC yoğunluğu (0.0 - 1.0 arası)

-- Durağan Durum Ayarları
Config.PlayerStaticThreshold = 5.0 -- Oyuncu bu mesafeden az hareket ettiğinde durağan kabul edilir
Config.StaticPositionMultiplier = 0.5 -- Durağan konumdayken density'i bu kadar azalt

-- Performans Ayarları
Config.ThreadSleepVehicle = 2500 -- Araç yönetimi için bekleme süresi
Config.ThreadSleepPed = 3000 -- NPC yönetimi için bekleme süresi
Config.FadeStep = 35 -- Fade out adımı
Config.FadeWait = 30 -- Fade bekleme süresi

-- Temizleme Ayarları
Config.CleanupTime = 8000 -- 8 saniye (daha hızlı temizleme)
Config.CacheCleanupInterval = 25000 -- 25 saniye (daha sık önbellek temizleme)

-- Spawn Mesafeleri ve Limitler
Config.VehicleSpawnDistance = 30.0 -- Araç spawn mesafesi
Config.PedSpawnDistance = 25.0 -- NPC spawn mesafesi
Config.MaxVehiclesInArea = 5 -- Maksimum araç sayısı
Config.MaxPedsInArea = 8 -- Maksimum NPC sayısı

-- Polis ve Dispatch Ayarları
Config.DisableCops = true -- Polisleri devre dışı bırak
Config.DisableDispatch = true -- Dispatch servislerini devre dışı bırak

-- Önbellek Ayarları
Config.MaxCacheSize = 100 -- Maksimum önbellek boyutu

-- Statik Kontrol Aralığı
Config.StaticCheckInterval = 2000 -- 2 saniye

-- Yeni Eklenen Ayarlar
Config.EnableFadeEffect = true -- Fade efektini aktif/pasif yap
Config.ProtectPlayerVehicles = true -- Oyuncu araçlarını koru
Config.ProtectPlayerPeds = true -- Oyuncu NPC'lerini koru
Config.EnableCache = true -- Önbellek sistemini aktif/pasif yap
Config.EnableStaticCheck = true -- Durağan durum kontrolünü aktif/pasif yap
Config.EnableDensityAdjustment = true -- Yoğunluk ayarlamalarını aktif/pasif yap

-- Araç Sınıfları için Özel Ayarlar
Config.ProtectedVehicleClasses = {
    [18] = true, -- Acil durum araçları
    [19] = true, -- Polis araçları
    [15] = true  -- Ticari araçlar
}

-- NPC Sınıfları için Özel Ayarlar
Config.ProtectedPedTypes = {
    [6] = true, -- Polis
    [7] = true, -- Acil durum personeli
    [8] = true  -- Özel NPC'ler
}

-- Debug Modu
Config.DebugMode = true -- Debug modunu aktif/pasif yap
Config.DebugLogLevel = 1 -- Debug log seviyesi (1: Sadece hatalar, 2: Tüm loglar)

return Config 