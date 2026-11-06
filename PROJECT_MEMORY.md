# ashvale-survival-rpg — Proje Hafızası

## Proje özeti
Godot 4 Meshy karakterli üçüncü şahıs 3D survival RPG prototipi.

## Önceki bağlam / dikkat noktaları
README'ye göre dövüş, loot, crafting ve save henüz kapsamda değil; yeni görev verilmeden tamamlanmış varsayma.

## Kalıcı çalışma protokolü
- Kaynak: Bu deponun güncel kodu ve belgeleri. Sohbet hafızası eksik veya eski olabilir.
- Başlangıç: GitHub bağlantısını ve depo erişimini kontrol et. Kullanıcıyı yeniden bağlantı kurmaya yönlendirmeden önce mevcut GitHub araçlarını dene.
- İşe başlamadan önce bu dosyayı, README.md ve varsa AGENTS.md / CLAUDE.md / başka proje kurallarını incele.
- Kodda bir değişiklik yapmadan önce en son durumu incele; kullanıcıdan gelmeyen ayrıntıları karar gibi sunma.
- İstenen değişiklikleri, mümkün ve yetkili olduğunda doğrudan GitHub'da uygula; commit/PR bağlantısı ile sonuç bildir.
- Her önemli görevden sonra bu dosyanın "Çalışma günlüğü" bölümünü yeni karar, değişen dosyalar, test sonucu, commit bağlantısı ve bekleyen işlerle güncelle.
- Eski tercihlerin uygulanmış olduğunu sadece bu dosyadan çıkarsama: kod ile doğrula.
- Yanıt dili Türkçe; kısa, net, gereksiz anlatımdan uzak.
- Var olan AGENTS.md ve depo yönergeleri öncelikle korunur; bu dosya onları geçersiz kılmaz.

## Çalışma günlüğü
- 2026-10-30: Süreklilik için PROJECT_MEMORY.md başlatıldı. Bu dosya kod değişikliği veya geçmişte tamamlanmış işlerin doğrulaması değildir.
- Son tamamlanan teknik görev: Henüz bu dosyaya işlenmedi.
- Son doğrulanan commit: Henüz kaydedilmedi.
- Bekleyen işler: Yeni kullanıcı görevinde belirlenecek.

## 2026-11-03 — 1920×1080 ve prototip bakım düzenlemesi
- 1920×1080 tasarım çözünürlüğü, exclusive fullscreen başlangıç, adaptif HUD ve F11 geçişi eklendi.
- Kullanılmayan kök `main.gd` ve `main.gd.uid` kaldırıldı; gerçek giriş scripti `scripts/main.gd` olarak korundu.
- Ağaç ve taşlara fiziksel çarpışma, Meshy modeline yükseklik normalizasyonu, koşma klibi adını daha sağlam arama eklendi.
- Yanlış isimli `download` yerine `.gitignore` eklendi ve `.godot` önbelleği Git takibinden çıkarıldı.
- README yeniden yazıldı; Godot 4.7.2 için GitHub Actions smoke testi tanımlandı.
- Test: Kaynak metin bütünlüğü ve depoda referans kontrolleri; yerel Godot çalıştırma testi bu ortamda yapılamadı. CI sonucu GitHub Actions'tan görülmeli.
- Değişikliklerin geçmişi: https://github.com/SerkanAydin06/ashvale-survival-rpg/commits/main
- Bekleyen geliştirmeler: Gerçek Idle/Walk/Run animasyonları, rig düzeltmesi, envanter/crafting/savaş, oyun içi menü ve Windows ekran testi.

## 2026-11-03 — char1 oyuncu yükleyicisi
- Kullanıcı Meshy'den T-pose temel karakteri `char1` adıyla hazırladığını belirtti.
- Bu değişiklik sırasında GitHub `main` dalında `char1` dosyası yoktu. Dosya yüklenmiş gibi varsayılmadı.
- `scripts/main.gd` güncellendi: `char1.glb/.gltf/.fbx/.tscn` önceliklendirmesi, alt klasör araması, Inspector'da manuel `character_file` yolu ve modelin bakış yönü ayarı.
- Var olan animasyon klipleri (Idle/Walk/Run/Jump/Fall) seçilir; hareket animasyonu yoksa ve `Skeleton3D` mevcutsa basit kol-bacak hareketi denenir; iskeletsiz modelde gerçek animasyon mümkün değildir.
- Model yüklenemezse önceki GLB korunup kullanılır. Oyuncu HUD'unda seçilen model ve rig durumu gösterilir.
- Doğrulama: kod kaynağı denetimi ve GitHub Actions headless import/smoke testi; gerçek `char1` modeli depoda olmadığından onun rig/animasyonları ayrıca doğrulanmalıdır.
- Commitler: https://github.com/SerkanAydin06/ashvale-survival-rpg/commits/main

## 2026-11-03 — Char1 model ve FBX animasyon birleştirmesi
- `8805f82...` güncellemesinde `assets/characters/Char1/Walking.fbx`, `Idle.fbx`, `Running.fbx`, `Standing Melee Attack Downward.fbx` eklendiği doğrulandı.
- FBX ikili meta verisi incelendi: `Idle.fbx` ve `Running.fbx` 67 Mixamo kemik modeli ve animasyon eğrileri içeriyor, ancak Geometry içermiyor; bu nedenle karakter mesh'i olarak uygun değiller. `Walking.fbx` 28 MB ve mesh/doku taşıması muhtemel.
- `scripts/main.gd` Char1 için `Walking.fbx` modelini önceliklendiriyor, ayrı animasyon kaynaklarının iskelet track yollarını yüklenen modelin Skeleton3D yoluna eşliyor; sol tık saldırı klibini oynatıyor.
- GitHub Actions headless import/smoke test sonucu ve Windows görsel animasyon doğrulaması bu commit sonrasında incelenmeli. Vücut/kol pozları gözle kontrol edilmedikçe kusursuz retarget varsayılmamalı.

- 2026-11-03 (ek doğrulama): GitHub Actions Godot 4.7.2 logunda `Walking.fbx` oyuncu olarak seçildi, `Skeleton3D` bulundu, Idle/Run/Attack sırasıyla 53/43/53 iskelet track'i ile içe aktarıldı. Kütüphane ilk erişiminde oluşan zararsız motor hata satırını engellemek için `has_animation_library` ön kontrolü eklendi; CI artık tüm `ERROR:` satırlarını yakalıyor.

## 2026-11-03 — GDScript isim gölgeleme uyarısı
- Kullanıcının bildirimi: `scripts/main.gd:353` satırındaki `for name` döngüsü `Node.name` alanını gölgeliyordu (`SHADOWED_VARIABLE_BASE_CLASS`).
- `name` iteratörü `animation_name` olarak değiştirildi; animasyon seçme davranışı korunuyor.
- GitHub Actions hata denetimine `SHADOWED_VARIABLE_BASE_CLASS` uyarı kontrolü eklendi.
- Test: GitHub Actions Godot 4.7.2 headless import/smoke sonucu kontrol edilmeli.

## 2026-11-03 — GDScript parametre gölgeleme uyarısı
- `scripts/main.gd:514`: `_apply_procedural_bone(name: String,...)` parametresi `Node.name` ile çakıştığı için `SHADOWED_VARIABLE_BASE_CLASS` uyarısı veriyordu.
- Parametre `bone_key` olarak güncellendi ve `bone_map.get` kullanımı eşlendi; tüm scriptte kalan `name` adlı parametre/döngü değişkenleri tarandı.
- Godot Actions doğrulaması commit sonrasında kontrol edilmeli.

## 2026-11-03 — Animasyon oynatma doğrulaması
- Godot 4.7.2 gerçek iskelet testleri: Idle 11 hareketli kemik, Running 40, Attack 37, Walking **0**. `Walking.fbx` Godot'ta `Take 001` adıyla 1 saniyelik sabit poz; hips pozisyonu ve rotasyonunda tek anahtar kare var.
- `scripts/main.gd` yürüyüşün statik klip olmasını rotasyon anahtarlarından algılıyor; varsa dinamik gerçek Walk kullanıyor, yoksa yavaşlatılmış Run animasyonuna geçiyor.
- FBX animasyonunun gövdeyi kaydırmasını önlemek için hips yatay root motion sıfırlanıyor. Mevcut Walk dinamikse LOOP_LINEAR yapılıyor.
- HUD gerçek animasyon durumunu gösteriyor. `tests/character_animation_diagnostics.gd` testine kemik hareketi ve Idle/Walk/Run/Attack durum geçişi kontrolleri eklendi.
- Gereken sanat varlığı: Mixamo'dan gerçek hareketli Walking.fbx yeniden export edilmeli; statik dosyadan gerçek yürüyüş üretilemez.

- Yeni animasyon ithalatı: `assets/characters/Char1/Walking_Animated.fbx` (Mixamo, FBX Without Skin, In Place) isteğe bağlıdır. Bu dosya mevcut mesh'i koruyarak gerçek yürüyüş klibi ekler. Dosya yoksa koşunun yavaş yedeği kullanılır. Godot CI ile doğrulanacak.

## 2026-11-03 — Uyarı temizliği ve hızlı saldırı
- `main.gd:404` satırındaki `var position` Node3D'nin aynı isimli özelliğini gölgeliyordu; `hip_key_position` olarak güncellendi.
- `Walking.fbx` statik poz (gerçek Walk yok) beklenen durum; `push_warning` yerine yalnızca açıklayıcı `print` kaydı bırakıldı. Mevcut 0,65× Run yürüyüş yedeği korundu.
- `ATTACK_PLAYBACK_SPEED = 3.0` ile saldırı yaklaşık 2,27 saniyeden 0,76 saniyeye indirildi, `attack_remaining` süre hesabı gerçek playback hızına eşitlendi ve geçiş blend'i 0,05 saniyeye kısaltıldı.
- `tests/character_animation_diagnostics.gd` içerisine saldırı playback hızı ve süresi için otomatik doğrulama eklendi; GitHub Actions ve Windows görsel test sonucu ayrıca incelenmeli.

## 2026-11-03 — Profesyonel dikişsiz zemin
- Önceki üretilen toprak/çimen üstten görünüşü 1024px kare dikişsiz şekilde hazırlandı ve WebP q78 (150 KB) olarak `assets/ground/ashvale_soil_grass_1024.webp` dosyasına eklendi.
- `scripts/main.gd`: eski tek renkli 80m kutu yerine 160m PlaneMesh ve aynı alanı kaplayan gizli statik fizik şekli; ShaderMaterial ile 4m/materyal tekrar.
- `assets/ground/ashvale_ground.gdshader`: dünya koordinatlı seamless UV, mipmap/anisotropic tekrar, makro gürültü ile tekrar deseninin yumuşatılması, dokudan türetilen hafif normal/roughness.
- `tests/ground_diagnostics.gd` ve CI: texture, mesh boyutu, shader ve çarpışma kontrolü. Son GitHub Actions sonucu ayrıca doğrulanmalı.

## 2026-11-04 — Meshy orman FBX modelleri
- Kullanici 4 adet FBX agac + PNG textures yükledi: `assets/obje/Meshy_AI_Ancient_Oak_Canopy_20261104_texture_fbx`, `Meshy_AI_Emerald_Sentinel_20261104_texture_fbx`, `Meshy_AI_Silverleaf_Birch_1104184945_texture_fbx`, `Meshy_AI_Twisted_Elder_20261104_texture_fbx`.
- `scripts/main.gd` `_make_camp` agaclarini 24 Meshy FBX instance ile degistirdi; boyut AABB'den normalize edildi; doku aktarimi eksikse PNG atlas fallback uygulaniyor.
- Agac kesme/toplama `resource_type=wood` sistemi ve silindir govde carpisma korunuyor. Eksik FBX icin basit primitive fallback var ama CI hatayi bildiriyor.
- Otomatik Godot test: `tests/tree_diagnostics.gd` ile import, geometri, 4 tur, kaynak ve carpisma testleri.
- Performans ve UV/alpha (yaprak) gorunumu, Godot'ta 3D ekran goruntusunden de incelenmeli; FBX polygon sayilarini CI logu raporlayacak.

## 2026-11-05 — Dusuk-poly stil denemesi
- Sanat hedefi: Stylized Fantasy Survival, orta/dusuk polygon, mat boyali yuzey, okunakli siluet, agac parcalanmasi icin kontrollu parcalar.
- Meshy CLI kurulumunun bu ortamda tamamlanamamasi nedeniyle ucretli Meshy gorevi baslatilmadi. Bunun yerine `scripts/stylized_asset_preview.gd` sahnede kendi geometrisini yaratan Godot stil karsilastirmasi oldu.
- `scripts/main.gd` onceki 24 Mesy agacini koruyarak oyuncunun onune `ArtDirectionShowcase` icerisinde bir STILIZE MESE ve STILIZE KAYA ornegi yerlestiriyor.
- Konumlar (-4.5,0,-8.5) ve (4.5,0,-8.5); etiket, basit carpisma, mat renk paleti var.
- `tests/stylized_preview_diagnostics.gd` geometri, uclu boyut butcesi, iki collider ve 24 eski agacin durumu icin CI testi.
- Bu stil denemesi Meshy uretimi degil ve yakin incelemede son sanat eseri sayilmaz. Uygun bulunursa asil FBX/GLB assetleri ayni tasarim kurallariyla uretilecek.

## 2026-11-05 — Agac kesme mekanigi
- 3 baltali darbe, Char1 animasyonu ile gecikmeli darbe zamani (0.23 s), 3.4m hedefleme; `_nearest_choppable_tree()` kameranin baktigi agaci secer.
- `scripts/choppable_tree.gd`: Kesik izleri ve kiymik parcaciklari, hafif sarsinti, 0.95s kontrollu devrilme, kütük ve `wood_drop` tipi 3 toplama parcasi.
- `scripts/stylized_axe.gd` basit stilize balta modeli; Mixamo sag el kemigine BoneAttachment3D ile baglanir.
- `resource_type=wood` artik aninda E ile toplanmaz. `resource_type=wood_drop` E ile odun, stone E ile tas olarak toplanir.
- 24 Meshy FBX ve yakin demo stylized oak kesilebilir. `tests/chopping_diagnostics.gd` ile uc darbe, cooldown, kütük, loot ve E testi CI'a eklendi.

## 2026-11-05 — Balta görünmüyor sorunu
- Kullanıcı baltanın oyunda görünmediğini, karakterin yumruk attığını bildirdi.
- Char1 için `_make_player` içinde `character.scale` boy düzeltmesi uygulanıyor. Sağ el kemiğine bağlı baltanın bu scale'i devralması çok küçük görünmesine neden oluyordu.
- `scripts/main.gd` `_make_axe`: Mount dünya ölçeğini ölçüyor; balta ve el kavrama pozisyonunun local ölçeği ters çarpanla düzeltiliyor. `equipped_axe`/`axe_attachment` referansları tanımlı.
- `scripts/stylized_axe.gd` netleştirilmiş metal balta başlığı, kesici kenar ve sap tutamakları içeriyor.
- `tests/weapon_equipment_diagnostics.gd`: Char1 sağ el kemiği, gerçek dünya ölçeği, geometri, montaj mesafesi kontrolü. CI'a eklendi. Gerçek Windows görsel kontrolü halen ayrıca gerekir.

## 2026-11-05 — Ayrı balta animasyonu
- Önceki yumruk animasyonu artık Char1 varsayılan saldırısı değil. `scripts/axe_chop_animation.gd` Mixamo iskeletine Godot Rotation3D track'leriyle özel `Ashvale/AxeChop` ekler.
- 0.76 saniyelik (2.28 / 3) animasyon: anticipation, overhead raise, downward impact, follow-through, recover. Darbe 0.25 s ve `CHOP_IMPACT_DELAY` ile eşleşir.
- Eski saldırı FBX'i import yedeği olarak kalır.
- `tests/axe_swing_diagnostics.gd`: gerçek aktif kemik track'leri, el hareketi, ekipman, darbe senkronizasyonu, klip süresi ve cooldown kontrolü.

## 2026-11-06 — Varlık düzeni, madencilik, Git LFS

- Meshy varlıkları `assets/environment/{trees,rocks,ores,plants,props}/<ad>/` ve `assets/tools/<ad>/` altına taşındı; adlandırma `<ad>.fbx` + `<ad>_albedo|normal|roughness|metallic.png`. Eski `assets/obje` yolu artık yok.
- Model yükleme tek yerden: `scripts/model_library.gd` (`MODELS` sözlüğü). FBX gömülü dokuları atılıyor, malzeme PNG'lerden kuruluyor.
- Oyun: `1` balta / `2` kazma; kazma `scripts/mineable_rock.gd` kaynaklarını kırar (taş, bakır, demir). Kaynak sayaçları: wood, stone, copper, iron.
- Git LFS etkin (`.gitattributes`); CI `git lfs pull` + `.git/lfs` önbelleği kullanıyor. Geçmiş yeniden yazılmadı.
- Yeni Meshy modelleri çok yüksek poligonlu (70 bin – 717 bin üçgen); düşük poligonlu yeniden dışa aktarma önerildi.
