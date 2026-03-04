# Build Hatası Çözümü: "Multiple commands produce"

## Sorun
Aynı dosyalar birden fazla kez "Copy Bundle Resources" build phase'ine eklenmiş.

## Çözüm Adımları

### 1. Xcode'da Build Phases'i Temizle

1. Xcode'da projenizi açın
2. Sol üstte projenizi seçin (mavi ikon)
3. TARGETS > **hackMobile** seçin
4. **Build Phases** sekmesine gidin
5. **Copy Bundle Resources** bölümünü açın (üzerine tıklayın)

### 2. Duplicate Dosyaları Bul ve Kaldır

**ÖNEMLİ:** Evler klasöründeki **TEK TEK DOSYALARI** kaldırın, sadece **KLASÖRÜ** bırakın.

1. "Copy Bundle Resources" listesinde:
   - `evler` klasörünü bulun (eğer varsa)
   - Evler klasörü içindeki **TEK TEK DOSYALARI** (örneğin `1.jpg`, `2.jpg`, vb.) bulun
   - Bu tek tek dosyaları **seçin** ve **"-" (minus)** butonuna tıklayarak **KALDIRIN**

2. Eğer `evler` klasörü yoksa:
   - "+" butonuna tıklayın
   - `evler` klasörünü seçin ve ekleyin
   - **SADECE KLASÖRÜ** ekleyin, içindeki dosyaları tek tek eklemeyin

### 3. Clean Build Folder

1. Xcode menüsünden: **Product > Clean Build Folder** (Shift + Cmd + K)
2. Tekrar build edin: **Product > Build** (Cmd + B)

### 4. Alternatif: Evler Klasörünü Yeniden Ekle

Eğer yukarıdaki adımlar işe yaramazsa:

1. Xcode'da sol panelde `evler` klasörüne sağ tıklayın
2. **Delete** seçin (Remove Reference seçeneğini seçin, Move to Trash DEĞİL)
3. Projeye sağ tıklayın > **Add Files to hackMobile...**
4. `evler` klasörünü seçin
5. **ÖNEMLİ SEÇENEKLER:**
   - ✅ **"Create groups"** (Create folder references DEĞİL)
   - ✅ **"Copy items if needed"**
   - ✅ **"Add to targets: hackMobile"**
6. **Add** butonuna tıklayın

### 5. Build Phases Kontrolü (Tekrar)

1. Build Phases > Copy Bundle Resources'a gidin
2. Sadece **`evler` klasörünün** olduğundan emin olun
3. İçindeki tek tek dosyaların **OLMADIĞINDAN** emin olun

## Hala Çalışmıyorsa

Eğer hala hata alıyorsanız:

1. **DerivedData'yı temizleyin:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/hackMobile-*
   ```

2. Xcode'u kapatıp yeniden açın

3. Clean Build Folder yapın ve tekrar build edin

## Not

Evler klasörünü "Create folder references" olarak eklemek yerine "Create groups" olarak eklemek önemlidir. Bu şekilde klasör içindeki dosyalar otomatik olarak bundle'a kopyalanır ve duplicate sorunu oluşmaz.












