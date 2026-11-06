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
| Space | Zıpla (Jump.fbx animasyonuyla) |
| Sol tık | Seçili eşyayı kullan: balta keser, kazma kazar, kamp ateşi kurar |
| 1–6 | Hızlı seçim çubuğundan eşya seç |
| Tab | Envanter ve üretim penceresi |
| H | Kontroller yardımı |
| F3 | Hata ayıklama bilgisi (karakter, animasyon, FPS) |
| R | Öldükten sonra kampta yeniden doğ |
| E | Yerdeki parçayı topla / eğrelti otundan lif topla |
| Esc | Fareyi serbest bırak / yakala |
| T | Saati 1 saat ileri sar |
| F11 | Tam ekran / pencere |

## Şu anda çalışan sistemler

- Char1 Mixamo karakteri: Idle, gerçek Walk, Run, Jump, Death ve özel `AxeChop` savurma animasyonu
- Üçüncü şahıs takip kamerası ve yakınlaştırma, koşma dayanıklılığı
- **Aletler:** Meshy el baltası ve kazması sağ el kemiğine bağlı; `1`/`2` ile değiştirilir
- **Ağaç kesme:** 4 Meshy ağaç türünden 24 ağaç, 3 darbede devrilir, yerine Meshy kütüğü kalır, 3 odun düşer
- **Madencilik:** kazmayla kırılan taş kayalar (3 darbe), yosunlu kayalar (3), bakır cevheri (4), demir cevheri (5); kırılınca parçalar düşer
- **Toplama:** düşen parçalar `E` ile toplanır; HUD'da ODUN / TAŞ / BAKIR / DEMİR sayaçları ve seçili alet
- **Dekor:** 36 eğrelti otu (gölgesiz, 40 m sonra gizlenir) ve 5 eski kütük
- Tam ekranda okunabilir, ekran köşelerine bağlı HUD

- **Envanter ve üretim:** 24 yuva, 6 hızlı seçim yuvası ve 9 tarif. Bakır kazmayla demir çıkarılabilir. Meşale elde taşınır, kamp ateşi uygun zemine kurulabilir.
- **Otomatik kayıt:** Eşya değişikliklerinde, tamamlanan hasatta, 30 saniyede bir ve normal pencere kapanışında kaydedilir. Sonraki açılışta aynı konum, çanta, saat, kamp ateşleri, tüketilmiş ağaç/kayalar, yerde kalan parçalar ve liflerin büyüme süreleri geri yüklenir.
- Envanter açıkken hareket, zıplama ve dünya etkileşimleri durur. Oyuncu arazinin kenarında durur, zeminin altına düşerse başlangıç noktasına döner.

## İlk gece

Oyun 08:30’da başlar. 17:00’den sonra hava serinler, 19:30’da gece başlar. Şafak 05:30’da gelir. Meşale keşif için ışık sağlar. Isınmak için yanan bir ateşin 5 metre yakınına gel, alevin içine basmaktan kaçın. Vücut sıcaklığı gece sıfıra inerse can azalır.

Kamp ateşi 150 saniyelik yakıtla başlar. Yaklaş ve **E** ile 1 odun ekle. Her odun 75 saniye yanar. Sönen ateşi aynı şekilde yeniden yakabilirsin. Geceyi hayatta tamamladığında şafakta bildirim görünür. Yakıt, vücut sıcaklığı ve ilk gece ilerlemesi otomatik kayda dahildir.

## İkinci gün · Terk edilmiş maden

İlk geceyi atlattığında kampın kuzeyindeki ahşap kaldırma kulesini ara. Girişteki üç bakır damarını taş kazmayla kırıp düşen parçaları **E** ile topla. Beş bakırla kampa dön. **Tab** menüsünde 5 bakır, 3 odun ve 1 ipten bakır kazma üret. Meşale kapalı galeriyi aydınlatır. Kazmaya geçip arka galerideki demiri kır ve en az bir parça topla. Seferin hangi aşamasında kaldığın kayıtla korunur.

## Henüz bulunmayan sistemler

Savaş, düşman yapay zekâsı, açlık ve susuzluk.

## Klasör yapısı ve dosya adları

Tüm Meshy objeleri tek bir düzene göre adlandırılır: **klasör adı = model adı**, dokular `<ad>_<kanal>.png`.

```
assets/
├── characters/            Char1 (Mixamo) ve yedek karakter
├── ground/                Zemin dokusu ve shader
├── environment/
│   ├── trees/             ancient_oak, emerald_pine, silverleaf_birch, twisted_elder
│   ├── rocks/             stone_boulder, mossy_boulder
│   ├── ores/              copper_ore, iron_ore
│   ├── plants/            fern
│   └── props/             tree_stump
└── tools/                 hand_axe, pickaxe
```

Örnek: `assets/environment/ores/iron_ore/` içinde `iron_ore.fbx`, `iron_ore_albedo.png`, `iron_ore_normal.png`, `iron_ore_roughness.png`, `iron_ore_metallic.png`.

| Eski Meshy adı | Yeni ad | Oyundaki kullanım |
| --- | --- | --- |
| `Meshy_AI_Ancient_Oak_Canopy_…` | `trees/ancient_oak` | Kesilebilir meşe |
| `Meshy_AI_Emerald_Sentinel_…` | `trees/emerald_pine` | Kesilebilir çam |
| `Meshy_AI_Silverleaf_Birch_…` | `trees/silverleaf_birch` | Kesilebilir huş |
| `Meshy_AI_Twisted_Elder_…` | `trees/twisted_elder` | Kesilebilir yaşlı ağaç |
| `…survival_RPG_20261105…` | `rocks/stone_boulder` | Kazılabilir taş kaya |
| `…survival_RPG_mossy…` | `rocks/mossy_boulder` | Kazılabilir yosunlu kaya |
| `…survival_RPG_copper_ore…` | `ores/copper_ore` | Bakır cevheri |
| `…survival_RPG_iron_ore…` | `ores/iron_ore` | Demir cevheri |
| `…survival_RPG_forest…` | `plants/fern` | Dekor eğrelti otu |
| `…survival_RPG_freshly…` | `props/tree_stump` | Kesilen ağacın kütüğü + dekor |
| `…survival_RPG_one_handed…` | `tools/hand_axe` | Eldeki balta |
| `…survival_RPG_iron…` | `tools/pickaxe` | Eldeki kazma |

### Yeni Meshy objesi ekleme

1. Meshy'den FBX'i indirin, uygun kategoride `<ad>/` klasörü açın.
2. Dosyaları `<ad>.fbx`, `<ad>_albedo.png` (+ varsa `_normal`, `_roughness`, `_metallic`) olarak adlandırın.
3. `scripts/model_library.gd` içindeki `MODELS` sözlüğüne `"<ad>": "res://assets/…/<ad>"` satırını ekleyin.
4. Koddan `MODEL_LIBRARY.instantiate("<ad>", yukseklik_metre)` ile çağırın: model y=0'a oturur, ölçeklenir ve PBR malzemesi otomatik bağlanır.

FBX'e gömülü dokular içe aktarmada atılır (`fbx/embedded_image_handling=0`); dokular her zaman yanındaki PNG'lerden gelir. 4096 px dokular VRAM için 2048 px'e sınırlanır ve mipmap'lenir (`.import` dosyalarında `process/size_limit=2048`).

**Performans ölçümü:** Kamp ve ormanda aynı yöne bakarken FPS panelindeki kare süresi ve son tepe değerlerini karşılaştır.

## Git LFS

Depoda `.fbx`, `.glb`, `.png`, `.webp`, ses vb. ikili dosyalar **Git LFS** ile saklanır (`.gitattributes`). İlk kurulum, her bilgisayarda bir kez:

```bash
git lfs install
git clone https://github.com/SerkanAydin06/ashvale-survival-rpg.git
# zaten klonlanmışsa:
git lfs pull
```

- Windows için Git LFS, "Git for Windows" ile birlikte gelir; `git lfs version` ile kontrol edin.
- Yeni model/doku eklerken ekstra bir şey yapmanız gerekmez: `git add` uzantıya göre dosyayı LFS'e koyar. `git lfs ls-files` ile görebilirsiniz.
- Godot'nun ürettiği `.import` ve `.uid` dosyaları normal Git'te kalır ve commit edilmelidir.
- Model dosyası Godot'ta açılmıyorsa ve dosya ~130 bayt ise LFS içeriği indirilmemiştir: `git lfs pull` çalıştırın.
- GitHub ücretsiz LFS depolama/bant genişliği kotası sınırlıdır. CI, LFS nesnelerini önbelleğe alarak her çalışmada yeniden indirmez.
- Not: LFS'e geçiş önceki commit'leri yeniden yazmadı; eski geçmişteki büyük dosyalar `.git` boyutunda kalmaya devam eder. Geçmişi küçültmek için `git lfs migrate import` gerekir; bu force-push gerektirdiği için ayrıca karar verilmeli.

## Bakım ve doğrulama

- Ana sahne `main.tscn`, kullanılan ana script `scripts/main.gd`.
- Godot'un `.godot/` klasörü yerel olarak oluşturulur, Git'e eklenmez.
- GitHub Actions iş akışı Godot 4.7.2 ile LFS dosyalarını çeker, headless import yapar, sahneyi açar ve `tests/` altındaki 8 tanılama testini çalıştırır (yeni: `tests/resource_props_diagnostics.gd` — tüm Meshy objeleri, kazma ile madencilik ve toplama).
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

`assets/environment/trees` altinda (eskiden `assets/obje`) 4 tur kullaniliyor: Ancient Oak Canopy (mese), Emerald Sentinel (cam), Silverleaf Birch (hus) ve Twisted Elder (yasli kuru agac). Her birinin kendi FBX ve ayni klasorde PNG kaplamasi var.

- `scripts/main.gd` `TREE_MODEL_PATHS` ve `TREE_TEXTURE_PATHS` sabitleri 4 varligi baglar.
- 24 agac, sabit tohumlu dogal dagilimla 160m zemine yerlestirilir; her agacin boyu ve donusu degisir.
- Agaclar bir kez `PackedScene` olarak yuklenip instance edilir: ayni turdekiler mesh/texture kaynagini paylasir.
- Ağaçların kökleri zemine oturur: import edilen mesh için AABB hesaplanır, yükseklik ayarlanır ve modelin tabanı y=0 olur.
- Govedeki yaklasik `StaticBody3D` silindiri karakter carpisma saglar; `E` odun toplama etkisi korunur.
- Model FBX'ten dokusuz gelirse yanindaki Meshy PNG'si eksik malzemeye otomatik atanir.
- FBX yoksa gecici basit agac fallback'i olur; CI modeli bulamadiginda basarisiz sayar.
- `tests/tree_diagnostics.gd` Godot headless importu, dort turun geometrisi, sahne ornekleri, carpisma ve kaplama varligini kontrol eder. Ayrintili ucgen sayilari test logunda gosterilir.
- FBX'ler agir cikar ve orman binlerce agaca buyutulurse LOD veya MultiMesh kullanilmali. Bu 24 agaclik prototip icin baslangic entegrasyonudur.

## Stylized Fantasy Survival gorunus denemesi (Kasım 2026)

Oyun basladiginda `scripts/stylized_asset_preview.gd` Godot'ta mat/az-poly stilinde bir mese ve fasetli bir kaya olusturur. Ornek sahne `ArtDirectionShowcase`, oyuncunun onunde (-4.5, -8.5) ve (4.5, -8.5) konumundadir. 24 adet Meshy agaci hala eskisi gibi yuklenir. Etiketler sanat karsilastirmasi icindir; ornekler odun/tas toplama kaynaklarina dahil edilmedi, asil oyun odun/tas toplama akisi degismedi.

Dusuk geometri, siluet ve ayni renk paleti hedeflendi. Bu modeller Godot kodundan uretilmis hizli stil prototipleridir, Meshy GLB modelleri degildir. `tests/stylized_preview_diagnostics.gd` tarafindan sahne/mesh/carpisma dogrulanir.

## Balta, agac kesme, devrilme ve odun parcalari (Kasım 2026)

- `SOL TIK`: Mevcut Char1 saldiri animasyonu ile stilize balta hareketi. Karakterin sag el kemigine dusuk polygonlu balta baglandi; iskelet yoksa sabit elde yedek.
- Agaca yakin ve ona dogru bakarken her saldiri 0.23 saniye sonra baltanin darbesini uygular (3.4m yakinlik); spam korumasi mevcut saldiri suresinde.
- Her 3 darbede once govdede acik renk kesik izi, kucuk odun kiymiklari, sallanma; son darbede agac 0.95 saniyede yana devrilir.
- Govde yere dogru doner, orijinal FBX mesh'i gecici olarak animasyonda korunur; ardindan sahneden cikar, kucuk bir kutuk kalir ve 3 odun parcasi uretilir.
- Yerdeki odun parcalarini `E` ile tek tek topla; agaca `E` basip aninda yok etmek artik mumkun degil. Tas toplama `E` ile eskisi gibi suruyor.
- Test alani `ArtDirectionShowcase/StylizedOak` modeli de kesilebilir; diger 24 Meshy agaci ayni sistemi kullanir.
- Kontrol dosyalari: `scripts/choppable_tree.gd`, `scripts/stylized_axe.gd`, `tests/chopping_diagnostics.gd`.
- Bu, fizik tabanli runtime kirilma degil, kontrollu hafif yikim ve odun ganimeti yaklasimidir.

## Görünür balta düzeltmesi (2026-11-05)

Char1 FBX iskelet/modeli genellikle santimetre ölçeğiyle geliyor. Oyuncu modelini 1,8 metreye küçültürken sağ el kemiğine eklenen ilk balta da aynı küçültmeye uğruyordu. Balta mesh'i artık parent node'un global ölçeğiyle **ters orantılı** ayarlanıyor; böylece gerçek boyutu yaklaşık 0,8 metre kalıyor. Yerel pozisyon ofseti de aynı şekilde dönüştürülüyor. `AxeRightHand` iskelet kemiği takip ediliyor, model görünür ve daha okunaklı kama biçimli bir balta başlığı kullanıyor. `tests/weapon_equipment_diagnostics.gd` el bağlantısı, dünya ölçeği, parça sayısı ve mesafe için otomatik test içeriyor.

## Ayrı balta savurma animasyonu — 2026-11-05

`scripts/axe_chop_animation.gd` gerçek Char1 Mixamo iskeletine, Idle pozundan türetilmiş, 2.28 saniyelik keyframe tabanlı `Ashvale/AxeChop` animasyonu kaydeder. Oyun klibi 3x hızda oynatarak 0.76 saniyelik bir balta savurma hareketi üretir. Gövde, kalça, sağ omuz, sağ üst/alt kol ve bilek ile sol kolun karşı hareketi ayrı rotasyon kanallarıyla animasyonlanır. Animasyonun 0.75 saniyelik iç zamanında (gerçekte 0.25 s) balta ağaca vurur. Önceki `Standing Melee Attack Downward.fbx` yedek olarak saklanır ama normal Char1 baltasında kullanılmaz. `tests/axe_swing_diagnostics.gd` özel klip, hareketli bilek kanalları, darbe zamanlaması ve ekipman varlığı testlerini yapar. Görsel ince ayar için oyun içi video/ekran görüntüsü hâlâ değerlidir.

## Meshy objeleri, kazma ve madencilik — 2026-11-06

- `assets/obje` içindeki karışık adlı tüm Meshy dosyaları kategorili klasörlere ve okunur adlara taşındı (yukarıdaki tabloya bakın); Godot'nun çıkardığı `_texture_0.png` kopyaları silindi.
- `scripts/model_library.gd`: model kataloğu, ölçekleme, zemine oturtma ve PBR (albedo/normal/roughness/metallic) malzeme bağlama.
- `scripts/mineable_rock.gd`: kazmayla kırılan kaya/cevher; sarsılma, taş kıymıkları, son darbede yere toplanabilir parçalar.
- Eski 12 basit küre kaya kaldırıldı; yerine 10 Meshy kayası (taş + yosunlu), 4 bakır ve 3 demir cevheri geldi.
- Prosedürel balta yerine Meshy `hand_axe` kullanılıyor (model yüklenemezse eski prosedürel balta yedek). Meshy `pickaxe` aynı ele bağlı, `2` ile seçiliyor.
- Kesilen ağaçların yerinde Meshy `tree_stump` kalıyor; ayrıca 36 eğrelti otu ve 5 dekor kütük eklendi.

## Alet kavrama düzeltmesi — 2026-11-06

- Balta ve kazma artık gerçekten avuçta: kavrama noktası ve yönü sabit sayılarla değil, Char1'in el iskeletinden hesaplanıyor. Sap işaret→serçe parmak doğrultusunda avucun içinden geçiyor, alet başı başparmak tarafında, ağız vuruş yönüne bakıyor.
- Meshy modellerinde sap, sınır kutusunun merkezinde değil (balta başı sapın bir yanına taşıyor). `scripts/main.gd` içindeki `TOOL_GRIPS` her aletin sap kaymasını (`handle_x`), tutuş yüksekliğini (`grip_height`) ve ağız yönünü (`blade_sign`) tutuyor.
- `scripts/hand_grip.gd` (`SkeletonModifier3D`): hangi animasyon oynarsa oynasın sağ eldeki parmakları sapın etrafında yumruk yapar. Kıvrılma açıları dosyanın başındaki tablolardan ayarlanabilir.
- İnce ayar için: kavrama noktası `GRIP_ALONG_PALM` (avuç boyunca) ve `GRIP_PALM_OFFSET` (avuçtan uzaklık, metre) sabitleriyle kaydırılabilir.

## Zıplama ve ölme animasyonları — 2026-11-06

- `Char1/Jump.fbx` → `Ashvale/Jump`. Space'e basınca klip çömelmenin sonundan (0.62 sn) başlar, 0.16 sn sonra fiziksel kalkış olur. Klipteki havada kalma süresi fizikteki uçuş süresine eşitlenir (0.825× hız). Klipteki kalça yükselmesi silinir (yüksekliği fizik verir), çömelme ve iniş dalgası kalır. İnişten sonra hareket edilirse hemen yürüyüşe/koşuya geçilir. Kenardan düşerken zıplama klibinin düşüş pozu kullanılır.
- `Char1/Dying Backwards.fbx` → `Ashvale/Death`. Basit can sistemi eklendi: HUD'da **CAN**. Kamp ateşinin içinde durmak saniyede 34 can yakar; 4 sn hasar almazsan can yavaşça dolar. Can bitince karakter geriye düşerek ölür, kontroller kilitlenir, **R** ile kampta yeniden doğarsın.
- Zıplarken ve ölüyken balta/kazma savrulmaz.
- Test: `tests/movement_diagnostics.gd` (CI'de çalışır).
- Godot editörünün eski `assets/obje` yollarına ürettiği artık dosyalar (253 MB doku kopyası ve `.import`) silindi; klasör `.gitignore`'a eklendi. Bilgisayarındaki Godot'ta bu klasör tekrar oluşursa silebilirsin.

## Yürüme animasyonu, vuruş menzili ve vuruşta durma — 2026-11-06

- `Char1/Walking_Animated.fbx` (Mixamo Walking, Without Skin) eklendi; yavaşlatılmış koşu yedeği artık kullanılmıyor. `Walking.fbx` karakterin model/doku kaynağı olarak kalıyor.
- Animasyon hızı adım uzunluğuna göre otomatik: kliplerin kendi ilerleme hızı ölçülür (yürüme 1.67 m/s, koşu 4.45 m/s) ve oynatma hızı = hareket hızı / klip hızı. Ayaklar yerde kaymaz.
- Hareket hızları buna göre: yürüme **2.5 m/s** (eskiden 4), koşu **6.5 m/s** (eskiden 7). `WALK_SPEED` / `RUN_SPEED` değiştirilirse animasyon hızı kendiliğinden uyar.
- Vuruş menzili artık ağaç gövdesinin / kayanın **yüzeyine** göre: en fazla **1 m** (`MELEE_REACH`) ve karakterin önündeki ~60°'lik koni (`MELEE_FACING_DOT`). Eskiden merkeze 3.4 m'den vurulabiliyordu.
- Balta/kazma savrulurken oyuncu yerinde durur; savurma bitince hareket devam eder.

## Ağaç kökleri ve gerçekçi balta çentiği — 2026-11-06

- Ağaçlar boylarının %4–5.5'i kadar toprağa gömülür (`TREE_ROOT_SINK`); kök uçları artık topraktan çıkıyor, ağaçlar ayaklık üzerinde durmuyor. Çarpışma yarıçapları görünen gövde kalınlığına göre güncellendi (`TREE_TRUNK_RADII`).
- Eski düz kutu "kesik izi" kaldırıldı. Yerine `scripts/chop_notch.gd`:
  - Darbe noktası, oyuncudan gövdeye atılan ışının ağacın **gerçek mesh yüzeyine** çarptığı yer (bel hizası, `CHOP_HEIGHT` = 0.95 m). Mesh verisi olmayan headless testlerde çarpışma silindiri kullanılır.
  - Tek bir V-çentik: alt kesim yatay, üst kesim eğik, uçlara doğru sivrilir ve gövde eğriliğine oturur. Her darbede derinleşir (3. darbede gövde yarıçapının ~%55'i).
  - Kesik yüzeylerinde gövde eksenine göre hesaplanan **yıllık halkalar**, gölgeli dip çizgisi ve ince kırık kabuk kenarı.
  - Projede Compatibility renderer olduğu için decal kullanılamıyor; çentik shader'da kendi görüş ışını boyunca kameraya çekilerek kabuğun önünde çizilir, ekranda oyulmuş gibi görünür.
- Kıymıklar artık darbe noktasından oyuncu tarafına sıçrar, yere düşüp kaybolur (eskiden ağacın dönüşüne göre yanlış taraftan çıkabiliyordu).
- CI düzeltmesi: karakter animasyon testi oyuncuyu zemine oturtmadan durum geçişlerini sınıyordu ve ara sıra düşüş pozunu görüp kırılıyordu.

## Forward+ görüntü kalitesi, gün-gece döngüsü ve kamp ateşi — 2026-11-06

**Renderer:** Compatibility (OpenGL 3) → **Forward+** (Vulkan / DirectX 12). DirectX 12 veya Vulkan destekleyen bir ekran kartı gerekir.

**Performans ayarları:** 2048 px yönlü gölge haritası, iki güneş gölge bölgesi ve 3 piksel model detay eşiği.

**Atmosfer** (`scripts/atmosphere.gd`):
- Kendi gökyüzü shader'ı: saate göre gökyüzü ve ufuk rengi, gün batımında güneş tarafında turuncu ufuk, güneş diski ve halesi, ay, gece yanıp sönen yıldızlar, rüzgârla kayan iki katmanlı prosedürel bulutlar. Bulutluluk birkaç dakikada bir yavaşça değişir.
- Gün-gece döngüsü: 1 oyun günü = 10 gerçek dakika (`day_length_minutes`), oyun 08:30'da başlar. Gün 05:30–19:30. Güneş/ay yönü, ışık rengi ve şiddeti saate göre değişir; HUD'da **SAAT** gösterilir, **T** ile 1 saat ileri sarılır.
- Işık: Gökyüzü ortam ışığı, yönlü güneş ve ay gölgeleri, AgX ton eşleme ve ateş parlaması.
- Hava: mesafe sisi + hava perspektifi,  sabah 04:00–09:30 arası sis yoğunlaşır, öğleye doğru açılır.

**Kamp ateşi** (`scripts/campfire.gd`): taş halka, kül, tipi tarzı kütükler, parlayan közler, titreyen gölgeli turuncu ışık (gece çevreyi aydınlatır), alev, rüzgârla sürüklenen duman ve uçuşan kıvılcım parçacıkları.

**Diğer:**
- Zemin 600 m'ye büyütüldü (ufukta kenar görünmüyor).
- Eski sanat önizlemesi etiketleri kaldırıldı.
- Balta çentiği Forward+'ta doğrusal renk uzayına ve ışık/gölge hesabına uyarlandı; yandan bakınca gövdenin arkasında kalır.
- Decal denendi ama düz ve soluk kaldı; derinlikli geometrik çentik korundu.

**Test:** `tests/atmosphere_diagnostics.gd` (CI'de çalışır).

**Performans notu:** SDFGI, hacimsel sis ve PCSS gölgeler en pahalı ayarlar. Oyun takılırsa sırasıyla `environment.sdfgi_enabled`, `volumetric_fog_enabled` ve `sun.light_angular_distance` (`scripts/atmosphere.gd`) kısılabilir; en büyük kazanç yine Meshy modellerinin düşük poligonlu sürümlerinden gelir.

## Envanter, üretim ve alet ilerlemesi — 2026-11-06

**Envanter** (`scripts/inventory.gd`): 24 yuva. İlk 6 yuva alttaki hızlı seçim çubuğu (1–6).
- Aynı eşyalar üst üste birikir (malzemeler 50'ye kadar).
- `Tab` penceresinde eşyalar sürüklenip bırakılarak düzenlenir; aynı eşyalar birleşir, farklılar yer değiştirir.
- Envanter doluysa yerdeki parça alınmaz, uyarı çıkar.

**Eşyalar ve tarifler** (`scripts/items.gd`):

| Üretilen | Gerekenler | Not |
| --- | --- | --- |
| İp | 3 Bitki Lifi | Alet başlarını bağlar |
| Meşale ×2 | 1 Odun, 2 Lif | Elde ışık verir |
| Kamp Ateşi | 5 Odun, 6 Taş | Yeşil önizlemeyle istenen yere kurulur |
| Taş Balta / Kazma | 3 Odun, 3 Taş, 1 İp | Başlangıç aletleri (yedek) |
| Bakır Balta / Kazma | 3 Odun, 5 Bakır, 1 İp | Bakır kazma demir cevherini açar |
| Demir Balta / Kazma | 3 Odun, 5 Demir, 2 İp | En güçlü aletler |

**İlerleme:**
- Oyuncu Taş Balta ve Taş Kazma ile başlar.
- Alet gücü darbe sayısını belirler: ağaç taş baltayla 3, bakırla 2, demirle 1 darbede devrilir.
- Demir cevheri en az Bakır Kazma ister; taş kazmayla vurulunca uyarı çıkar.
- Aletler aynı Meshy modelini kullanır, seviyeye göre renklenir (taş gri, bakır turuncu, demir çelik).
- Bitki lifi eğrelti otlarından `E` ile toplanır (2 lif); ot 4 dakika sonra yeniden büyür.
- Kurulan kamp ateşleri ışık verir ve yakar (can sistemi tüm ateşleri dikkate alır).

**Arayüz** (`scripts/ui/game_ui.gd`, `inventory_slot.gd`, `item_icon.gd`):
- **Ekranda:** Sol üstte can ve dayanıklılık çubukları, sağ üstte saat (gündüz/gece), altta ikonlu hızlı seçim çubuğu ve seçili eşyanın adı, ortada bağlama göre ipucu (ör. "Ağacı kes (2 darbe)"), sağda toplama bildirimleri.
- **`Tab` penceresi:** Envanter ızgarası; üretilebilenler parlak, üretilemeyenler soluk tarif listesi; malzemeler var/gereken renkli (yeşil/kırmızı); ilerleme çubuklu "ÜRET" butonu. Eşyanın üstüne gelince bilgi kutusu (kategori, açıklama, güç, seviye).
- **İkonlar:** Kod ile çizilen vektör ikonlar, her çözünürlükte keskin.
- **Ek:** `H` kontroller, `F3` hata ayıklama.

**Test:** `tests/inventory_diagnostics.gd` (CI'de çalışır). Kapsadığı konular:
- yığınlama, dolu envanter, sürükle-bırak
- tarifler, bakır baltayla 2 darbe, demir kilidi
- lif toplama, savurma sırasında alet değiştirememe
- meşale, kamp ateşi kurma
