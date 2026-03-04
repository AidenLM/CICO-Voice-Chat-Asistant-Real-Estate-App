# Evler Klasörü Kurulum Rehberi

## Önemli: Evler Klasörünü Xcode Projesine Ekleyin

iOS uygulamasının evler klasöründeki fotoğraflara erişebilmesi için klasörü Xcode projesine eklemeniz gerekiyor.

## Adımlar:

### 1. Xcode'da Projeyi Açın

### 2. Evler Klasörünü Projeye Ekleyin

1. Xcode'da sol panelde projenize sağ tıklayın
2. "Add Files to hackMobile..." seçin
3. `evler` klasörünü seçin
4. **ÖNEMLİ:** Şu seçenekleri işaretleyin:
   - ✅ "Create groups" (Create folder references DEĞİL)
   - ✅ "Copy items if needed" (eğer klasör proje dışındaysa)
   - ✅ "Add to targets: hackMobile"
5. "Add" butonuna tıklayın

### 3. Build Phases Kontrolü

1. Projenizi seçin (sol üstte)
2. TARGETS > hackMobile seçin
3. "Build Phases" sekmesine gidin
4. "Copy Bundle Resources" bölümünü açın
5. `evler` klasörünün orada olduğundan emin olun
6. Yoksa "+" butonuna tıklayıp ekleyin

### 4. Test Edin

Uygulamayı çalıştırın ve property'lerin fotoğraflarının göründüğünü kontrol edin.

## Alternatif: Absolute Path (Development için)

Eğer klasörü eklemek istemiyorsanız, PropertyLoader.swift dosyasındaki `init()` metodunda absolute path kullanabilirsiniz:

```swift
self.evlerPath = "/Users/mac/Desktop/hackathonMobile/hackMobile/evler"
```

Ancak bu sadece development için çalışır, gerçek cihazda çalışmaz.

## Sorun Giderme

### Fotoğraflar görünmüyor
- Console'da "PropertyLoader: Evler path" mesajını kontrol edin
- Path'in doğru olduğundan emin olun
- Evler klasörünün "Copy Bundle Resources" içinde olduğunu kontrol edin

### "Path exists = false" görüyorsanız
- Evler klasörünü Xcode projesine eklediğinizden emin olun
- Build Phases'te "Copy Bundle Resources" içinde olduğunu kontrol edin












