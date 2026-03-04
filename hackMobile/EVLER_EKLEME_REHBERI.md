# Evler Klasörünü Xcode Projesine Ekleme Rehberi

## Sorun
"Evler klasörü bulunamadı" hatası alıyorsunuz. Bu, evler klasörünün Xcode projesine düzgün eklenmediği anlamına gelir.

## Çözüm: Evler Klasörünü Xcode'a Ekleyin

### Adım 1: Xcode'da Projeyi Açın

### Adım 2: Evler Klasörünü Projeye Ekleyin

1. **Xcode'da sol panelde** (Project Navigator) projenizin **root klasörüne** sağ tıklayın
   - "hackMobile" (mavi ikon) üzerine sağ tıklayın

2. **"Add Files to hackMobile..."** seçin

3. **Dosya seçici penceresinde:**
   - `/Users/mac/Desktop/hackathonMobile/hackMobile/evler` klasörüne gidin
   - **`evler` klasörünü seçin** (klasörün içine girmeyin, klasörün kendisini seçin)

4. **ÖNEMLİ:** Şu seçenekleri kontrol edin:
   - ✅ **"Create groups"** seçili olmalı (Create folder references DEĞİL)
   - ✅ **"Copy items if needed"** işaretli olmalı
   - ✅ **"Add to targets: hackMobile"** işaretli olmalı

5. **"Add"** butonuna tıklayın

### Adım 3: Build Phases Kontrolü

1. Sol üstte **projenizi seçin** (mavi ikon)
2. **TARGETS > hackMobile** seçin
3. **"Build Phases"** sekmesine gidin
4. **"Copy Bundle Resources"** bölümünü açın (üzerine tıklayın)
5. **`evler` klasörünün** listede olduğundan emin olun
   - Eğer yoksa, **"+"** butonuna tıklayın
   - `evler` klasörünü seçin ve ekleyin

### Adım 4: Clean ve Build

1. **Product > Clean Build Folder** (Shift + Cmd + K)
2. **Product > Build** (Cmd + B)

### Adım 5: Test

Uygulamayı çalıştırın ve console'da şu mesajı görmelisiniz:
```
✅ PropertyLoader: Evler klasörü bulundu (bundle resource): ...
```

## Alternatif: Absolute Path Kullanımı (Geçici Çözüm)

Eğer yukarıdaki adımlar işe yaramazsa, PropertyLoader zaten absolute path'i kontrol ediyor:
- `/Users/mac/Desktop/hackathonMobile/hackMobile/evler`

Bu path development için çalışır ama production'da çalışmaz. Bu yüzden yukarıdaki adımları uygulamanız önerilir.

## Sorun Giderme

### Hala "bulunamadı" diyorsa:

1. Console'da hangi path'lerin kontrol edildiğini görün
2. Evler klasörünün gerçekten `/Users/mac/Desktop/hackathonMobile/hackMobile/evler` konumunda olduğundan emin olun
3. Terminal'de kontrol edin:
   ```bash
   ls -la /Users/mac/Desktop/hackathonMobile/hackMobile/evler
   ```

### "Multiple commands produce" hatası alıyorsanız:

- Build Phases > Copy Bundle Resources'ta
- Evler klasörü içindeki **tek tek dosyaları** kaldırın
- Sadece **`evler` klasörünün** kendisi kalmalı












