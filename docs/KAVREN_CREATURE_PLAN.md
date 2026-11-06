# KAVREN — Yaratık Evreni ve Üretim Planı
> Durum: Taslak v0.1 · 2026-11-07 · Kodlanmış özellik değil, yeni tasarım önerisi.
> Kaynak: main dalındaki README.md, scripts/creatures/companion.gd, scripts/creatures/valley.gd ve project.godot.

## 1. Temel vizyon
KAVREN; stilize, yüksek kaliteli, karanlık ve gizemli yanları olan fantastik bir yaratık ekosistemi. Yaratıkların renk değiştirilmiş kopyalar değil; anatomileri, hareketleri, sesleri, avlanma biçimleri ve çevreyle ilişkileri farklı vahşi canlılar olarak görülmesi hedeflenir. İlk bakışta okunabilir siluet + yakından organik detay. Görsel ton: olgun, sinematik, stilize 3D; aşırı sevimli/oyuncak görünümlerinden, hazır geometrik şekil izleniminden ve sürekli parlayan efektlerden uzak durulacak.

**Oynanış ilkeleri**
- Vahşi yaratıklar kendi habitatlarında yaşar; oyuncuyu sürekli takip eden bir yaratık konvoyu olmaz. Bir yoldaş yalnızca uygun anlarda savaşa/özel çevre etkileşimine çağrılır.
- Her türün görünür bir motivasyonu bulunur: avlanma, sürü koruma, beslenme, yuva savunma, göç, dinlenme veya kaynak bulma.
- Bölgesel tehlikeler ciddidir. Kimi türler kaçarken kimisi pusu kurar; her karşılaşma dostluk veya ele geçirme ile bitmez.
- Savaşlar teknik olarak sıra tabanlı kalabilir ama görsel olarak gerçek dövüş hissi verir: duruş değişimi, saldırı hazırlığı, temasa tepki, zemin izi, kısa kamera hareketi, ses ve çevresel VFX. Çizgi film estetiği savaşların ağırlığını azaltmaz.
- Bazı canlılarla güven bağı kurulur, bazıları yalnızca gözlemlenir; bölge koruyucuları/zirve avcılar otomatik olarak ekip üyesi olmaz.

## 2. Dünyanın iç mantığı — öneri
Kavren coğrafyasının altında, canlıların davranışını ve bazı olağanüstü yeteneklerini etkileyen **Yankı Damarları** bulunur. Bu, tüm canavarları tek bir büyü kaynağına indirgemez: beden, beslenme, doğal seçilim ve iklim önce gelir; Yankı, nadir türlerin uyumunun açıklamasıdır. Bir habitat yok olursa orada yaşayan yaratık popülasyonu ve karşılaşmalar da değişir.

**Yedi uyum:** Kök (bitki/mantar), Akış (su/nem), Kaya (mineral/direnç), Köz (ısı/kül), Fırtına (hava/elektrik), Gölge (gece/gizlenme), Yankı (rezonans, nadir). Bunlar katı tek-yönlü taş-kâğıt-makas çizelgesi değildir. Her tür için bir **ana uyum**, gerektiğinde bir **ikincil davranış** tanımlanır. Savaş rolü ile uyum birbirinden bağımsız tutulur.

**Savaş rolleri:** Avcı (yüksek tek hedef baskısı), Muhafız (dayanıklılık), Tacizci (hız/bozma), Alan denetçisi (zemin/konum), Destekçi (koruma/iyileştirme), Baskıncı (pusu/ani hamle).

**Davranış grupları:** Ürkek, meraklı, sosyal, bölgeci, avcı, zirve tür. Tür bazında gece/gündüz, hava durumu, yalnız/sürü, kaçış eşiği, oyuncu yaklaşımına tepki ve yuva noktasına dönüş belirlenir.

## 3. Altı biyom, 36 tür — uzun vadeli katalog
Her biyomda 6 farklı tür vardır; son tür bölgenin zirve canlısıdır. Bu **36 başlangıç türü** demektir, 36'sının ilk sürümde üretilmesi hedeflenmez. İsimler, mevcut ilk üç hariç, çalışma adıdır.

### A. Yoldaşlar Vadisi — başlangıç bölgesi
Hafif orman, çayır, dere ve taşlı kıyı. Önce keşif, davranış gözleme, ilk tehlikeler.

| Tür | Uyum / rol | Benzersiz siluet ve doğal davranış |
|---|---|---|
| **Filizik** (mevcut) | Kök / çevik avcı | Yaprak kulaklı, alçak gövdeli orman izcisi; ağaç diplerinde saklanır, kısa sıçramalar |
| **Damlup** (mevcut) | Akış / alan denetçisi | Kanat-yüzgeçli dere süzülücüsü; su kenarından uzaklaşmaz, sıçrayarak döner |
| **Çakılcık** (mevcut) | Kaya / muhafız | Katmanlı sırt zırhı olan dört ayaklı; kayalıkta hareketsiz bekler, sonra omuz atar |
| **Yelren** | Fırtına / tacizci | Uzun kuyruk tüyleri ve geriye dönük kanatları olan ince yırtıcı kuş; ani alçalış |
| **Morkin** | Gölge / baskıncı | Yarıkta saklanan altı ayaklı gece memelisi; ses duyunca geri çekilir, köşeye sıkışırsa saldırır |
| **Varkon** (zirve) | Kaya–Kök / avcı | Geyiksi dallanan boynuzlu, iri kaslı alfa yaratık; bölgeyi dolaşır, yavrulara yaklaşılmasını engeller |

### B. Sarmal Orman — sık bitki örtüsü, düşey hareket
| Tür | Uyum / rol | Benzersiz siluet ve doğal davranış |
|---|---|---|
| **Sarvek** | Kök / avcı | Kabuğumsu omuzlu ağaç kedisi; gövdeler arasında sıçrayarak avlanır |
| **Koruza** | Kök / destekçi | Gövdesinde yosun bahçesi taşıyan narin boynuzlu otçul; yaralı sürü üyelerine yaklaşır |
| **Mirvan** | Gölge–Kök / alan denetçisi | Mantar başlıklı altı bacaklı; tehlikede spor bulutu bırakır |
| **Türel** | Fırtına / tacizci | Geniş deri zarları olan ağaç süzülücüsü; rüzgâra göre ağaç değiştirir |
| **Kıskor** | Köz / baskıncı | Kanatlarında köz lekeleri olan gece kelebeği; ışık ve ateş çekimine tepki verir |
| **Thornak** (zirve) | Kök / muhafız | Dev kök boynuzlu orman boğası; alanını çiğner, toprağı köklerle kabartır |

### C. Yitik Bataklık — pus, sazlık ve pusular
| Tür | Uyum / rol | Benzersiz siluet ve doğal davranış |
|---|---|---|
| **Veskil** | Akış / tacizci | Saz kamuflajlı uzun boyunlu kertenkele; suya dalar |
| **Nolya** | Gölge–Akış / baskıncı | İki yüzgeçli yılanbalığı formu; su altından anlık hamle |
| **Sulkar** | Kaya–Akış / muhafız | Çamur kabuklu ağır amfibi; sığ göletleri savunur |
| **Zevran** | Gölge / alan denetçisi | Keskin gagalı, uzun bacaklı karanlık balıkçıl; toksik sazları dağıtır |
| **İrvel** | Yankı / destekçi | Boğaz kesesinde titreşen zarlar olan amfibi; çağrısıyla sürüyü uyarır |
| **Morvek** (zirve) | Gölge–Akış / avcı | Bataklık sırtı ve dikenli timsah gövdesi; su/karada iki fazlı takip |

### D. Kül Sırtları — volkanik taş ve sıcak akıntılar
| Tür | Uyum / rol | Benzersiz siluet ve doğal davranış |
|---|---|---|
| **Korsa** | Köz / tacizci | Çatlak derisinde kızıl ısı görülen kertenkele; sıcak kaya arar |
| **Brakar** | Kaya / muhafız | Segmentli bazalt zırhlı top gibi kapanabilen canlı; eğimde yuvarlanır |
| **Dervin** | Köz–Fırtına / baskıncı | Geniş kulaklı kül yarasası; duman perdesinden çıkar |
| **Garkil** | Kaya / alan denetçisi | Büyük ön pençeli yer kazıcısı; savaş alanında taş sırtı yükseltir |
| **Ferak** | Fırtına / avcı | Kül fırtınasında uçan keskin kanatlı yırtıcı; yüksekten dalar |
| **Korvash** (zirve) | Köz / avcı | Kanatsız volkan ejderi; ağır vücut, kısa ısı patlamaları ve yıkıcı kuyruk |

### E. Fırtına Yarıkları — kayalık uçurumlar, sert rüzgâr
| Tür | Uyum / rol | Benzersiz siluet ve doğal davranış |
|---|---|---|
| **Veyra** | Fırtına / tacizci | Uzun kavisli kuyruklu küçük uçan avcı; ani yön değiştirir |
| **Tornil** | Kaya / muhafız | Çift kıvrık boynuzlu dağ koşucusu; sürüyle kayalık geçit tutar |
| **Arelis** | Yankı / destekçi | İnce boyunlu, ses keseli hava süzülücüsü; rüzgâr uğultusuyla haberleşir |
| **Kestak** | Kaya / baskıncı | Dört bağımsız tutunma pençeli duvar tırmanıcısı; dik yüzeyden iner |
| **Zinrek** | Fırtına / avcı | Yıldırım izli iki ayaklı yırtıcı kuş; fırtınada saldırganlaşır |
| **Varzun** (zirve) | Fırtına–Yankı / alan denetçisi | Havada süzülen uzun serpantin beden; yıldırım değil rüzgâr girdabı yaratır |

### F. Kristal Taç — kadim anomali ve son keşif
| Tür | Uyum / rol | Benzersiz siluet ve doğal davranış |
|---|---|---|
| **Eryth** | Yankı / tacizci | Kristal kabuklu iri böcek; ışık saçılmasıyla göz yanıltır |
| **Lyskara** | Yankı / avcı | Aynamsı yeleli dört ayaklı; kırık yansımalardan ortaya çıkar |
| **Noctar** | Gölge / baskıncı | Keskin sırt hattı ve ters açılı ön kolları olan gece avcısı; görünmez olmaz, gölgelerde seçilmesi zorlaşır |
| **Orvan** | Kaya–Yankı / muhafız | Kaya/kuvars gövdeli ağır canlı; rezonansla yakın savunma yapar |
| **Velkir** | Köz–Yankı / alan denetçisi | İnce uzun bacaklı ve prizmatik boynuzlu; ısı sapmaları oluşturur |
| **Arkhaz** (zirve) | Yankı / çok fazlı koruyucu | Asimetrik kristal boynuzlu kadim dev; çevresel rezonansla savaş biçimi değişir |

## 4. Yaratık tasarım standardı
Her tür için zorunlu üretim kartı: 
1. **Kimlik:** Kalıcı tür ID, isim, ana uyum, bölge, rol, boyut (S/M/L/XL), yaygınlık.
2. **Anatomi:** Gerçekçi eklem yapısı; önden, yandan ve üç çeyrek açıdan tanınan benzersiz siluet; hareket şekli.
3. **Davranış:** Gezinme alanı, beslenme, tehdit mesafesi, tepki, yalnız/sürü, gün/gece, hava koşulu, kaçış ve bölge savunma.
4. **Savaş:** En az 1 temel vuruş, 1 imza saldırısı, 1 savunma/kaçınma hareketi, 1 zayıflık; rol için anlamlı etkileşim.
5. **Animasyon:** Idle A/B, walk, run, turn, alert, warning, attack A/B, hit, stagger, down, rest, emote. Kanatlı/suda yaşayanlar için özel set.
6. **Ses:** 3 uzak çağrı, uyarı, saldırı, hasar, hareket yüzey sesi; türün ses imzası.
7. **Bağ kurma:** Kabul ediyorsa neden ve hangi davranışla? Kabul etmiyorsa gözlem/kaçınma/özel karşılaşma.
8. **Teknik:** LOD, mesh, collider, rig, texture atlas, VFX, boyut, performans sınırı, test sahnesi.

**Görsel kurallar:** Harici varlıkla çalışırken kilitli siluet ve ana renk paleti; yüz ifadeleri karakterli olabilir ama aşırı büyük göz/oyuncak oranı kullanılmaz. Gövde ağırlığı, anatomik eklem, pençe, ağız ve vurma yüzeyi inandırıcı olmalı. Büyüsel detaylar yalnızca uzaktan tanınmayı artırdığında kullanılmalı. Her türün en az bir ayırt edici hareket motifi bulunur.

**Önerilen varlık bütçesi (başlangıç hedefi, sahne testiyle ayarlanır):** Küçük/orta yaratıklar görünür LOD0 12–25 bin üçgen, büyükler 25–45 bin, zirve yaratık 45–65 bin; 2K temel doku, yakın çekim zirve canlılarda gerekirse 4K; LOD1/LOD2 eklenir. Bu hedefler Godot 4.7 GL Compatibility ve çoklu sahne varlıklarının maliyeti ölçüldükten sonra kesinleştirilir. 100 binlerce üçgenlik doğrudan Meshy modelini oyuna koymak hedef değildir.

## 5. Yoldaşlık, gelişim, savaş ve ekoloji
- **Karşılaşma:** Görüş/işitme/iz takibi ile başlar. Çoğu yaratık oyuncuya otomatik düşman değildir.
- **Etkileşim:** Biyoma ve türe özel yiyecek, güven, kurtarma veya çatışmadan sonra sakinleştirme yolları. Dövüş kazanıldı diye otomatik yoldaş alınmaz.
- **Savaş:** Başlangıçta 1 aktif yoldaş + sınırlı yedek; 2–4 anlamlı hareket seçimi, okunabilir rakip niyeti, savunma, pozisyon ve enerji yönetimi. Daha sonra durum etkileri, alan kontrolü, çevresel etkileşim. Vuruşlar gerçek temas ve güçlü animasyonlara bağlanır.
- **İlerleme:** Seviye sayısı dışında yetenek ustalığı, bağ seviyesi ve habitatla rezonans. Tüm türler aynı kalıpta üç aşamalı evrim geçirmez.
- **Olgunlaşma / değişim:** Başlangıçtaki üç tür için yetişkin formu değerlendirilebilir. Öneri adları Filizik→Sylvar, Damlup→Neris, Çakılcık→Gravor. **Bu isimler onaylanmadan mevcut isimleri veya save ID'lerini değiştirme.** Diğer türlerin bir kısmında yalnızca boynuz, zırh, tüy veya renk varyasyonu olabilir.
- **Üst düzey türler:** 6 zirve canlısı zorlayıcı dövüş/özel görev odağıdır; varsayılan olarak toplanabilir değildir.
- **Yeniden karşılaşmalar:** Rastgele yaratık yoğunluğu yerine popülasyon bölgeleri, yuvalar ve gözlemlenebilir yaşam döngüsü tercih edilir.

## 6. Öncelikli 12 türlük üretim dalgaları
| Dalga | Kapsam | Tamamlama ölçütü |
|---|---|---|
| **P0 — Temel 3** | Filizik, Damlup, Çakılcık | Üçünün modeli, doğru rig/animasyon, sesleri, vahşi AI durumları, ayrı savaş stilleri ve testleri |
| **P1 — Vadi genişleme** | Yelren, Morkin, Varkon | Gündüz/gece farkı, av/pusu ve bir bölge zirve canlısı ile canlı vadi |
| **P2 — Biyom geçişi** | Sarvek, Koruza, Mirvan | Ormanda düşey gezinme, destek ve alan etkilerinin denenmesi |
| **P3 — Su ve uçuş** | Veskil, Nolya, Veyra | Suya dalış, uçuş, habitat kuralları ve uygun savaş animasyonları |
| **P4 — Uzun vade** | Kalan 24 tür | Bölge bölge, performans ve oynanış kapısından geçerek ekleme |

P0+P1=6 tür; P0–P3=12 tür; katalog hedefi 36 tür. Tüm katalog aynı anda modellenmeyecek.

### İlk bitirilmesi gereken örnek: Filizik
İlk üretim standardı Filizik üzerinde ispatlanacak. Mevcut düşük poligon kod modelinin anatomisi referans alınabilir ama son model Meshy/Blender → Godot ile yüksek kaliteli siluet, animasyon ve malzeme olmalı. Örnek davranış: sığınaktan çıkma, ürkme, koklama, iki farklı gezinme, oyuncuya uyarı, saklanma, sıçrayarak saldırı, yara tepkisi. Diğer 35 tür için hazır kopya iskelet değil; **yeniden kullanılabilir üretim şablonu** oluşturulur.

## 7. Mevcut GitHub koduyla farklar (2026-11-07 incelemesi)
- Mevcut türler scripts/creatures/companion.gd içindeki SPECIES dizisinde, 0/1/2 sabit tür indeksleriyle tanımlı; gövde şekilleri prosedürel ve sınırlı uzuv hareketleri var.
- scripts/creatures/valley.gd yalnızca 3 canlı oluşturuyor; tek bir yakınlaşma/karşılaşma düzeni, iki savaş komutu (saldır/savun) ve her üçüncü tur ağır saldırı var.
- Vahşi AI şu an yalnızca yakın devriye/oyuncuya dönme; avlanma, sürü, yuva savunma, gece, farklı saldırı kararı ve habitat geçişi yok.
- Mevcut kayıt biçimi tam 3 türün level/xp/tired alanlarını, tür indekslerini kullanıyor. Dördüncü tür kodlanmadan önce sürümlü kayıt geçişi gerekir.
- title_menu.gd üzerinden ana menü var; creature_valley.tscn geçerli oynanabilir alan. Genel PROJECT_MEMORY.md'nin erken survival notları artık güncel yaratık modunun kanıtı sayılmamalı.

## 8. Teknik uygulanma sırası (henüz uygulanmadı)
1. **Veri temeli:** CreatureDefinition (Resource) veya JSON benzeri veri kayıtları; sabit sayısal index yerine değişmeyen string creature_id. Tür adını değiştirince kayıtlar bozulmamalı.
2. **Save v2:** Mevcut v1 üç yaratık ilerlemesini kaybetmeden ID tabanlı ekibe dönüştüren migration ve yükleme doğrulaması.
3. **Aktör ve animasyon:** Ortak CreatureActor sahnesi, CharacterBody3D/NavMesh, animasyon durum makinesi, geçerli temas/hitbox, ses ve VFX olayları.
4. **Vahşi AI:** Idle → Roam → Sense → Warn → Flee/Attack → Recover → Return; tür profiline göre sürü ve avcı davranışları.
5. **Dövüş:** Veri tabanlı hareketler, niyet gösterimi, cooldown/enerji ve tür rolleri; geçici sıçrama tween'lerinin yerine rig animasyonları.
6. **Ekoloji:** Spawn ve yuva verileri, zaman ve hava koşulu, güvenli ve tehlikeli alanların dünya içinde organik belirlenmesi.
7. **Sanat üretimi:** Önce 2D onaylı model sayfası (ön/yan/arka), sonra Meshy proxy, retopoloji, rig, animasyon, hitbox, ses, entegrasyon, QA.
8. **Ölçüm:** Tür bazında test sahnesi, davranış/savaş kayıt testleri, VRAM/tri/draw call/FPS bütçesi ve gerçek oyun ekran görüntüsü incelemesi.

### Öncelik çerçevesi
**Önce:** görsel stil onayı + ilk 3 türü profesyonelleştirme + veri modeli.  
**Sonra:** yaratık AI ve dövüş hissi + 3 yeni vadi türü.  
**Daha sonra:** ikinci biyom, uçuş/su hareketi ve yeni türler.  

## 9. Onay gerektiren yaratıcı kararlar
- Mevcut Filizik, Damlup, Çakılcık adları korunacak mı, daha olgun adlarla değişecek mi?
- Bir savaşta tek aktif yoldaş mı olacak, daha sonra çoklu takım kombinasyonları mı açılacak?
- Zirve canlılarla yalnızca savaş mı yapılacak, bazıları çok zorlu koşullarla bağ kurabilir mi?
- Yankı Damarları evrenin kalıcı anlatı omurgası olarak kabul edilecek mi?

**Bu belgedeki yeni türler ve lore teklif niteliğindedir; mevcut oyun kodu, isimler ve kayıtlar değiştirilmedi.**
