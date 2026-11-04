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

## char1 karakterini çalıştırma

1. Yeni rigli modeli Godot projesinin içine, tercihen `assets/characters/char1.glb` olarak koyun. Dosya `.gltf`, `.fbx` veya `char1.tscn` olabilir.
2. Godot'un modeli içe aktarmasını bekleyin ve **F5** ile çalıştırın.
3. Oyun `char1` adlı dosyaları (alt klasördekiler dahil) önce dener; bulamazsa önceki `base_adventurer_running.glb` modelini kullanır.
4. Özel bir dosya ismi kullanacaksanız `main.tscn` kök düğümünde, Inspector'daki `character_file` alanından model yolunu seçin.
5. Model geriye bakıyorsa `character_facing_offset` değerini 180 olarak değiştirin.

Animasyon sırası: mevcut Idle, Walk, Run, Jump, Fall klipleri adlarına göre algılanır; klip yok ama `Skeleton3D` varsa basit prosedürel yürüyüş/koşu hareketi kullanılır. **T-pose tek başına rig değildir**: `Skeleton3D` bulunmuyorsa karakterin konumu WASD ile değişir ancak uzuvları hareket ettirmek için önce Meshy/Blender'da riglenmesi gerekir. HUD'da seçilen model ve animasyon durumu gösterilir. Gerçekçi yürüyüş için ayrı Idle/Walk/Run animasyonlarını modele eklemek hâlâ önerilir.

## Char1 için gerçek model ve animasyonlar (3 Kasım 2026)

Depoda `assets/characters/Char1/` içinde dört Mixamo FBX dosyası bulunuyor:
- `Walking.fbx`: **oyuncu için birincil model ve yürüyüş klibi**. 28 MB olması gömülü model/doku içeriğine işaret ediyor; Godot içinde görünüşünü ayrıca kontrol edin.
- `Idle.fbx`: bekleme animasyonu.
- `Running.fbx`: koşma animasyonu.
- `Standing Melee Attack Downward.fbx`: sol tıklamayla saldırı animasyonu (şimdilik hasar sistemi yok).

Başlangıçta `Walking.fbx` yüklenir; diğer FBX dosyalarının iskelet kanalları aynı Skeleton3D'ye eşlenip animasyon kütüphanesine eklenir. Animasyon aktarımı başarısız olursa eski karaktere veya prosedürel hareketlere otomatik düşebilir; Godot çıktısındaki `Ashvale animation imported` kayıtlarını kontrol edin.

**Önemli:** FBX dosyaları Mixamo standardı 67 kemik içeriyor; animasyonların vücuda doğru uygulanması için Godot tarafında gerçek görüntü kontrolü şarttır. Hatalı bir animasyon varsa 3D görünüm, iskelet adları veya klip yolu üzerinden düzeltin.

## 2026-11-03 — Walking.fbx animasyon sorunu ve geçici çözüm

Godot kemik tanılama testinde `Idle.fbx` (11), `Running.fbx` (40) ve saldırı FBX'i (37) kemik hareketi üretiyor. Mevcut **`Walking.fbx` sadece bir sabit poz içeriyor** (birer anahtar kare, hareket eden kemik sıfır). Bu dosya karakter modelini ve dokuları taşımaya devam ediyor; ancak geçerli bir yürüyüş klibi olarak kullanılmıyor.

Oyuncu şimdi:
- Dururken **Idle**, Shift'le koşarken **Run**, sol tıkta **Attack** kullanıyor.
- Normal hareket ederken geçerli Walk yoksa **Run klibini 0.65 hızında** oynatıyor. Bu geçici bir animasyon; gerçek yürüyüş adımları için Mixamo'dan hareket içeren **Walking.fbx** yeniden dışa aktarılmalı. Kaydedildiğinde animasyon otomatik algılanır.
- Karakterin yerinde koşup modelin öne kaymasını engellemek için pelvis/hips yatay kök hareketi temizleniyor.
- HUD'un `ANİMASYON` satırında şu an seçili hareket görülebilir.

Godot Actions testi artık kemik hareketini, geçişleri, klip oynatma hızını ve kök hareketini kontrol eder.

### Gerçek yürüyüş animasyonunu ayrı eklemek

`Walking.fbx` karakterin **mesh/doku kaynağı** olarak kalmalı; değiştirmene gerek yok.

Mixamo'dan hareket eden yürüyüş animasyonunu **FBX Without Skin**, tercihen **In Place** seçili olarak indir ve dosya adını `Walking_Animated.fbx` yaparak `assets/characters/Char1/` klasörüne ekle. Godot animasyonu ayrı yükler ve iskelete aktarır. Dinamik kemik hareketi varsa gerçek `Walk` otomatik kullanılır, yoksa yavaşlatılmış `Run` yedeği aktif kalır.

## 2026-11-03 — Yeni zemin malzemesi

Zemin artık `160 × 160 metre` `PlaneMesh` üzerinde, komple örten `StaticBody3D` çarpışma kutusuyla çalışır. Önceki tek renkli yüzey kaldırıldı. Arazi kaplaması, üretilmiş toprak/çimen görselinin **1024 × 1024 dikişsiz WebP** sürümüdür ve doğrudan GitHub'a eklenmiştir:

- `assets/ground/ashvale_soil_grass_1024.webp` — gerçek zemin dokusu
- `assets/ground/ashvale_ground.gdshader` — dünya koordinatlarına bağlı 4m tekrar, makro renk/görsel varyasyon, anisotropik mipmap filtreleme ve hafif yüzey kabartması
- `tests/ground_diagnostics.gd` — 1024px görsel, shader, döşeme ve çarpışma doğrulaması

Zemin **tek bir 160 metreye gerilmiş resim değildir**; 4m tekrar ile bütün yüzeye kaplanır. Yeniden boyutlandırılabilir. Ayarlamak isterseniz `scripts/main.gd` içindeki `GROUND_SIZE` ve `GROUND_TILE_METERS` sabitlerini değiştirin. Yüksek çözünürlüklü PNG kaynak görseli konuşmadaki indirme bağlantısında da mevcut.

## 4 Meshy agac modelinin entegrasyonu (4 Kasim 2026)

`assets/obje` altinda 4 tur kullaniliyor: Ancient Oak Canopy (mese), Emerald Sentinel (cam), Silverleaf Birch (hus) ve Twisted Elder (yasli kuru agac). Her birinin kendi FBX ve ayni klasorde PNG kaplamasi var.

- `scripts/main.gd` `TREE_MODEL_PATHS` ve `TREE_TEXTURE_PATHS` sabitleri 4 varligi baglar.
- 24 agac, sabit tohumlu dogal dagilimla 160m zemine yerlestirilir; her agacin boyu ve donusu degisir.
- Agaclar bir kez `PackedScene` olarak yuklenip instance edilir: ayni turdekiler mesh/texture kaynagini paylasir.
- Ağaçların kökleri zemine oturur: import edilen mesh için AABB hesaplanır, yükseklik ayarlanır ve modelin tabanı y=0 olur.
- Govedeki yaklasik `StaticBody3D` silindiri karakter carpisma saglar; `E` odun toplama etkisi korunur.
- Model FBX'ten dokusuz gelirse yanindaki Meshy PNG'si eksik malzemeye otomatik atanir.
- FBX yoksa gecici basit agac fallback'i olur; CI modeli bulamadiginda basarisiz sayar.
- `tests/tree_diagnostics.gd` Godot headless importu, dort turun geometrisi, sahne ornekleri, carpisma ve kaplama varligini kontrol eder. Ayrintili ucgen sayilari test logunda gosterilir.
- FBX'ler agir cikar ve orman binlerce agaca buyutulurse LOD veya MultiMesh kullanilmali. Bu 24 agaclik prototip icin baslangic entegrasyonudur.
