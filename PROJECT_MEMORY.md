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
