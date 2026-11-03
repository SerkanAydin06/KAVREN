# Ashvale — 3D Survival RPG Prototipi

Godot **4.7.x** (önerilen: 4.7.2) ile oluşturulmuş, üçüncü şahıs keşif ve kaynak toplama prototipi.

## Kurulum ve çalıştırma

1. Godot 4.7.x ile bu klasördeki `project.godot` dosyasını içeri aktarın.
2. Meshy karakterinin GLB içe aktarmasının tamamlanmasını bekleyin.
3. **F5** ile ana sahneyi çalıştırın.

## Ekran

- Tasarım çözünürlüğü: **1920 × 1080 (16:9)**.
- Başlangıç modu: **Exclusive Fullscreen** (ekranın doğal çözünürlüğüne uyarlanır).
- **F11** ile tam ekran ve 1280 × 720 pencere modu arasında geçiş yapılır.
- `canvas_items` + `expand` sayesinde HUD diğer ekran oranlarına da uyum sağlar.
- Godot ekran kartının fiziksel çözünürlüğünü zorla 1920 × 1080'e çevirmiyor; 1920 × 1080 oyun arayüzünün tasarım boyutudur.

## Kontroller

| Tuş | İşlev |
| --- | --- |
| WASD | Hareket |
| Fare | Kamera |
| Fare tekerleği | Kamera uzaklığı |
| Shift | Koş (dayanıklılık tüketir) |
| Space | Zıpla |
| E | Yakındaki odun veya taşı topla |
| Esc | Fareyi serbest bırak / yakala |
| F11 | Tam ekran / pencere |

## Şu anda çalışan sistemler

- Meshy GLB karakteri, mevcut animasyonlardan Running ve varsa Idle seçimi
- Karakter boyuna göre ilk ölçek düzeltmesi; kapsül çarpışma
- Üçüncü şahıs takip kamerası ve yakınlaştırma
- Basit ağaç/taş kaynakları, kaynak toplama ve kaynak sayaçları
- Koşma dayanıklılığı ve yenilenmesi
- Ağaç gövdesi ile taşların çarpışmaları
- Tam ekranda okunabilir, ekran köşelerine bağlı HUD

## Henüz bulunmayan sistemler

Envanter, eşya üretimi, savaş, düşman yapay zekâsı, açlık/susuzluk, kayıt/yükleme sistemi. Mevcut Meshy karakterinin skinning/rig sorunları motor koduyla tamamen giderilemez; doğru rig ve ayrı Idle/Walk/Run klipleri önerilir.

## Bakım ve doğrulama

- Ana sahne `main.tscn`, kullanılan ana script `scripts/main.gd`.
- Godot'un `.godot/` klasörü yerel olarak oluşturulur, Git'e eklenmez.
- GitHub Actions iş akışı Godot 4.7.2 ile headless import ve kısa sahne açılış kontrolü yapar.
- Gerçek oyun görüntüsünü, karakter eklemlerini ve tam ekran davranışını Windows üzerinde F5 ile ayrıca kontrol edin.

Proje bağlamı: [PROJECT_MEMORY.md](PROJECT_MEMORY.md).
