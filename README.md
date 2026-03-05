# Roblox Çöp Toplama Simülatörü (Prototype v2)

Bu repo, Roblox Studio içinde hızlıca kurulabilecek geliştirilmiş bir **çöp toplama simülatörü** sunar.

## İçerik

- `src/ReplicatedStorage/Config.lua`
  - Çöp değerleri
  - Çanta upgrade seviyeleri
  - Araç upgrade seviyeleri (hız)
  - Pet seçenekleri (para + hız bonusu)
  - Çöp respawn süresi ve Golden Bag event ayarları
- `src/ServerScriptService/GameServer.server.lua`
  - Toplama / satma / upgrade akışları
  - Leaderboard (`Money`, `TotalTrash`)
  - Oyuncu attribute'ları (envanter ve ilerleme)
  - Çöpün başarılı toplanınca yok olup sonra respawn olması
  - Golden bag event

## Roblox Studio Kurulum

1. `Config.lua` dosyasını **ModuleScript** olarak `ReplicatedStorage` altına ve adını tam `Config` olacak şekilde ekleyin.
2. `GameServer.server.lua` dosyasını `ServerScriptService` içine ekleyin.
3. Workspace içinde şu parçaları oluşturun (hepsinde `ProximityPrompt` olmalı):
   - `SellPoint`
   - `BagUpgradePoint`
   - `VehicleUpgradePoint`
   - `PetShopPoint`
   - `GoldenBagSpawn` (spawn konumu için prompt gerekmez)
4. Toplanabilir her çöp objesini `Trash` tag'i ile etiketleyin.
5. Her çöp objesine bir `ProximityPrompt` koyun.
6. Çöp objelerine `TrashType` attribute verin. Örnekler:
   - `PlasticBottle`
   - `Can`
   - `Cardboard`
   - `TrashBag`
   - `ElectronicWaste`
   - `Laptop`
   - `Phone`

## Hızlı Test (Otomatik Kurulum)

- `Config.AutoSetup.Enabled = true` ise script ilk çalışmada test için gerekli noktaları otomatik oluşturur:
  - `SellPoint`, `BagUpgradePoint`, `VehicleUpgradePoint`, `PetShopPoint`, `GoldenBagSpawn`
- `Config.AutoSetup.SpawnSampleTrash = true` ise örnek çöp objeleri de üretir ve `Trash` tag'i verir.
- Kendi haritanı kurmaya başladığında bu modu kapatabilirsin:
  - `Config.AutoSetup.Enabled = false`

## Oyun Döngüsü

Topla -> Envantere al -> SellPoint'te sat -> Para kazan -> Bag/Vehicle/Pet upgrade al -> daha hızlı ve kârlı farm.

## Notlar

- Envanter doluysa çöp **silinmez** (oyuncu önce satmak zorunda).
- Başarıyla toplanan çöp, `TrashRespawnSeconds` sonunda geri gelir.
- Respawn olan çöp objeleri tekrar toplanabilir.
- Araç + pet kombinasyonu oyuncu yürüyüş hızını etkiler.

- Eğer log'da `Config ModuleScript not found` görürsen, dosya adı/konumu yanlıştır.
