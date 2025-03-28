# 🏃 Artew NPC Control[TR]

Bu script, FiveM için optimize edilmiş bir **araç ve yaya yönetim** sistemidir. **FPS dostu** yapısıyla sunucularda gereksiz araç ve yayaları temizleyerek daha akıcı bir oyun deneyimi sunar.

## 📌 Özellikler

- **FPS bazlı optimizasyon** – FPS değerine göre araç ve yaya yoğunluklarını otomatik olarak ayarlar.
- **Görünmeyen araç/yaya temizleme** – Uzun süre ekranda görünmeyen varlıkları belirli bir süre sonunda temizler.
- **Araç ve yaya sınırı** – Belirlenen sınırdan fazla araç/yaya oluşturulmasını önler.
- **Yavaş silme efekti** – Araç ve yayalar aniden kaybolmaz, yerine yavaşça silinir.
- **Polis ve acil servis kapatma** – İsteğe bağlı olarak polis ve ambulans spawn olmasını engeller.
- **FPS Bazlı Yoğunluk Optimizasyonu** - Eğerki fpste düşüş olursa otomatik olarak fps değerine göre yoğunluklar artar veya azalır.
- **Daha akıllı spawn mesafeleri** → NPC ve araçlar, oyuncuların görüş açısına uygun mesafelerde oluşturulur ve gereksiz işlem yükü engellenir.
- **Trafik Spawn Kontrolü** → İstediğiniz araçların spawn kontrolünü yapabilirsiniz.
- **Oyuncu Durağan Durum Özellikleri** → Oyuncu 5 birim altında hareket ederse durağan kabul ediliyor Durağan durumdayken yoğunluk %50 azaltılıyor Her 2 saniyede bir durağan durum kontrolü Durağan durumdayken daha agresif temizleme
- **Akıllı Spawn Sistemi** → Durağan durumdayken %30 spawn şansı Hareket halindeyken %70 spawn şansı Mesafe bazlı spawn kontrolü FPS bazlı spawn optimizasyonu.


## 🔧 Kurulum

1. Dosyaları indir ve `artew-npc-control` adlı bir klasöre yerleştir.
2. `server.cfg` dosyanı aç ve şu satırı ekle:
   ```cfg
   ensure artew-npc-control
   ```
3. Sunucunu yeniden başlat.

## ⚙️ Yapılandırma

Scripti ihtiyaçlarınıza göre özelleştirmek için `config.lua` dosyasını düzenleyebilirsiniz.

### Önemli Değişkenler  
- `VehicleDensityMultiplier`: Araç yoğunluğunu belirler. (0.0 - 1.0 arası)  
- `PedDensityMultiplier`: Yaya yoğunluğunu belirler. (0.0 - 1.0 arası)
- `PlayerStaticThreshold`: Oyuncu bu mesafeden az hareket ettiğinde durağan kabul edilir
- `StaticPositionMultiplier`: Durağan konumdayken density'i bu kadar azalt
- `DisableCops`ve`DisableDispatch`: Polis ve acil durum birimlerini devre dışı bırakmasını sağlar.
- `vehicleSpawnDistance`ve `pedSpawnDistance`: Araç ve yaya spawn mesafesi   
- `maxVehiclesInArea`: Maksimum araç sayısını sınırlar.  
- `maxPedsInArea`: Maksimum yaya sayısını sınırlar.  
- `cleanupTime`: Görünmeyen varlıkları temizleme süresi (ms cinsinden).
- `EnableFadeEffect`: Fade efektini aktif/pasif yap
- `ProtectPlayerVehicles`: Oyuncu araçlarını koru
- `ProtectPlayerPeds`: Oyuncu NPC'lerini koru
- `EnableStaticCheck`: Durağan durum kontrolünü aktif/pasif yap
- `EnableDensityAdjustment`: Yoğunluk ayarlamalarını aktif/pasif yap
- `DebugMode`: Debug modunu aktif/pasif yap
- `DebugLogLevel`: Debug log seviyesi (1: Sadece hatalar, 2: Tüm loglar)

    
## 🔧 Resmon Değerleri
![Resmon](https://github.com/user-attachments/assets/7d49fe0d-7dbc-4501-9454-bb88d0a757da)

Resmon değeri 0.0-0.2 maximum bu kadar olacaktır.


# 🏃 Artew NPC Control [EN]

This script is an optimized **vehicle and pedestrian management** system for FiveM. With its **FPS-friendly** structure, it removes unnecessary vehicles and pedestrians from servers, providing a smoother gaming experience.

## 📌 Features

- **FPS-based optimization** – Automatically adjusts vehicle and pedestrian densities based on FPS values.
- **Invisible vehicle/pedestrian cleanup** – Removes entities that have not been visible on the screen for a certain period.
- **Vehicle and pedestrian limits** – Prevents the creation of more vehicles/pedestrians than the specified limit.
- **Slow deletion effect** – Vehicles and pedestrians do not disappear suddenly; instead, they fade out gradually.
- **Police and emergency service disable** – Optionally prevents police and ambulances from spawning.
- **FPS-Based Density Optimization** – If FPS drops, densities automatically increase or decrease based on FPS values.
- **Smarter spawn distances** → NPCs and vehicles are spawned at distances suitable for the players' line of sight, preventing unnecessary processing load.
- **Traffic Spawn Control** → You can control the spawn of the vehicles you want.
- **Player Steady State Features** → Player is considered to be stationary if they move under 5 units Intensity is reduced by 50% while in steady state Steady state check every 2 seconds More aggressive clearing while in steady state
- **Smart Spawn System** → 30% chance to spawn when stationary 70% chance to spawn when moving Distance based spawn control FPS based spawn optimisation.

## 🔧 Installation

1. Download the files and place them in a folder named `artew-npc-control`.
2. Open your `server.cfg` file and add the following line:
   ```cfg
   ensure artew-npc-control
   ```
3. Restart your server.

## ⚙️ Configuration

You can customize the script according to your needs by editing the `config.lua` file.

### Important Variables  
- `VehicleDensityMultiplier`: Determines the vehicle density (between 0.0 and 1.0)  
- `PedDensityMultiplier`: Determines the pedestrian density (between 0.0 and 1.0).
- `PlayerStaticThreshold`: The player is considered static when moving less than this distance
- `StaticPositionMultiplier`: Reduce density by this much in static position
- `DisableCops` and `DisableDispatch`: Allows to disable police and emergency units.
- `vehicleSpawnDistance` and `pedSpawnDistance`: Vehicle and pedestrian spawn distance   
- `maxVehiclesInArea`: Limits the maximum number of vehicles.  
- `maxPedsInArea`: Limits the maximum number of pedestrians.  
- `cleanupTime`: Time (in ms) to clear invisible entities.
- `EnableFadeEffect`: Enable/disable the fade effect
- `ProtectPlayerVehicles`: Protect player vehicles
- `ProtectPlayerPeds`: Protect player NPCs
- `EnableStaticCheck`: Enable/disable static check
- `EnableDensityAdjustment`: Enable/disable density adjustments
- `DebugMode`: Enable/disable debug mode
- `DebugLogLevel`: Debug log level (1: Errors only, 2: All logs)

## 🔧 Resmon Values
![Resmon](https://github.com/user-attachments/assets/7d49fe0d-7dbc-4501-9454-bb88d0a757da)

The Resmon value will be between 0.0-0.2 at maximum.
