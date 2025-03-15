# 🏃 Artew NPC Control[TR]

Bu script, FiveM için optimize edilmiş bir **araç ve yaya yönetim** sistemidir. **FPS dostu** yapısıyla sunucularda gereksiz araç ve yayaları temizleyerek daha akıcı bir oyun deneyimi sunar.

## 📌 Özellikler

- **FPS bazlı optimizasyon** – FPS değerine göre araç ve yaya yoğunluklarını otomatik olarak ayarlar.
- **Görünmeyen araç/yaya temizleme** – Uzun süre ekranda görünmeyen varlıkları belirli bir süre sonunda temizler.
- **Araç ve yaya sınırı** – Belirlenen sınırdan fazla araç/yaya oluşturulmasını önler.
- **Yavaş silme efekti** – Araç ve yayalar aniden kaybolmaz, yerine yavaşça silinir.
- **Polis ve acil servis kapatma** – İsteğe bağlı olarak polis ve ambulans spawn olmasını engeller.
- **FPS Bazlı Yoğunluk Optimizasyonu** - Eğerki fpste düşüş olursa otomatik olarak fps değerine göre yoğunluklar artar veya azalır.

## 🔧 Kurulum

1. Dosyaları indir ve `artew-npc-control` adlı bir klasöre yerleştir.
2. `server.cfg` dosyanı aç ve şu satırı ekle:
   ```cfg
   ensure artew-npc-control
   ```
3. Sunucunu yeniden başlat.

## ⚙️ Yapılandırma

Scripti ihtiyaçlarınıza göre özelleştirmek için `client.lua` dosyasını düzenleyebilirsiniz.

### Önemli Değişkenler  
- `VehicleDensityMultiplier`: Araç yoğunluğunu belirler.  
- `PedDensityMultiplier`: Yaya yoğunluğunu belirler.
- `DisableCops`ve`DisableDispatch`: Polis ve acil durum birimlerini devre dışı bırakmasını sağlar.
- `vehicleSpawnDistance`ve `pedSpawnDistance`: Araç ve yaya spawn mesafesi   
- `maxVehiclesInArea`: Maksimum araç sayısını sınırlar.  
- `maxPedsInArea`: Maksimum yaya sayısını sınırlar.  
- `cleanupTime`: Görünmeyen varlıkları temizleme süresi (ms cinsinden).
- `VehicleDensityMultiplier`: fps başına ne kadar yoğunluk olacağını ayarlar.

    
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

## 🔧 Installation

1. Download the files and place them in a folder named `artew-npc-control`.
2. Open your `server.cfg` file and add the following line:
   ```cfg
   ensure artew-npc-control
   ```
3. Restart your server.

## ⚙️ Configuration

You can customize the script according to your needs by editing the `client.lua` file.

### Important Variables  
- `VehicleDensityMultiplier`: Determines vehicle density.  
- `PedDensityMultiplier`: Determines pedestrian density.  
- `DisableCops` and `DisableDispatch`: Disables police and emergency units.  
- `vehicleSpawnDistance` and `pedSpawnDistance`: Defines the spawn distance for vehicles and pedestrians.  
- `maxVehiclesInArea`: Limits the maximum number of vehicles.  
- `maxPedsInArea`: Limits the maximum number of pedestrians.  
- `cleanupTime`: Time interval for removing invisible entities (in ms).  
- `VehicleDensityMultiplier`: Adjusts density per FPS.

## 🔧 Resmon Values
![Resmon](https://github.com/user-attachments/assets/7d49fe0d-7dbc-4501-9454-bb88d0a757da)

The Resmon value will be between 0.0-0.2 at maximum.
