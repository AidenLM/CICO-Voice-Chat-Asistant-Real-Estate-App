# Localization Dosyalarını Xcode Projesine Ekleme Rehberi

## 📋 Adım Adım Talimatlar

### 1. Xcode'da Projeyi Açın
- Xcode'u açın
- `hackMobile.xcodeproj` dosyasını açın

### 2. Localization Klasörlerini Projeye Ekleyin

#### Yöntem A: Drag & Drop (En Kolay)
1. Finder'da şu klasörlere gidin:
   - `/Users/mac/Desktop/hackathonMobile/hackMobile/hackMobile/tr.lproj`
   - `/Users/mac/Desktop/hackathonMobile/hackMobile/hackMobile/en.lproj`

2. Xcode'da sol taraftaki Project Navigator'da `hackMobile` klasörüne sağ tıklayın
3. "Add Files to 'hackMobile'..." seçeneğini seçin
4. Her iki klasörü (`tr.lproj` ve `en.lproj`) seçin
5. **ÖNEMLİ:** Şu ayarları kontrol edin:
   - ✅ "Copy items if needed" işaretli OLMAMALI (dosyalar zaten doğru yerde)
   - ✅ "Create groups" seçili olmalı
   - ✅ "Add to targets: hackMobile" işaretli olmalı
6. "Add" butonuna tıklayın

#### Yöntem B: File > Add Files to...
1. Xcode menüsünden `File > Add Files to "hackMobile"...` seçin
2. `hackMobile` klasörüne gidin
3. `tr.lproj` ve `en.lproj` klasörlerini seçin
4. Aynı ayarları kontrol edin (Yöntem A'daki gibi)
5. "Add" butonuna tıklayın

### 3. Localization Ayarlarını Kontrol Edin

#### Her bir `.lproj` klasörü için:
1. Project Navigator'da `tr.lproj` klasörünü seçin
2. Sağ taraftaki File Inspector'ı açın (⌥⌘1 veya View > Inspectors > File)
3. "Localization" bölümünde:
   - ✅ "Localize..." butonuna tıklayın (eğer görünüyorsa)
   - ✅ "Turkish" seçili olmalı
   - ✅ "English" seçili olmalı (her iki dil için)

4. Aynı işlemi `en.lproj` klasörü için tekrarlayın:
   - ✅ "English" seçili olmalı
   - ✅ "Turkish" seçili olmalı

### 4. Localizable.strings Dosyalarını Kontrol Edin

1. `tr.lproj/Localizable.strings` dosyasını seçin
2. File Inspector'da:
   - ✅ "Localization" bölümünde "Turkish" ve "English" seçili olmalı
   - Eğer sadece bir dil görünüyorsa, "+" butonuna tıklayıp diğer dili ekleyin

3. `en.lproj/Localizable.strings` dosyası için aynı kontrolü yapın

### 5. Proje Ayarlarını Kontrol Edin

1. Project Navigator'da en üstteki mavi proje ikonuna tıklayın
2. "PROJECT" altındaki `hackMobile` seçili olmalı
3. "Info" sekmesine gidin
4. "Localizations" bölümünde şunlar olmalı:
   - ✅ Turkish (tr)
   - ✅ English (en)

Eğer yoksa:
- "+" butonuna tıklayın
- "Turkish" ve "English" ekleyin

### 6. Build ve Test Edin

1. Projeyi build edin (⌘B)
2. Simulator'da çalıştırın (⌘R)
3. HomeView'da sağ üstteki TR/EN butonuna tıklayın
4. Tüm metinlerin dil değiştiğini kontrol edin

## 🔍 Sorun Giderme

### Eğer localization çalışmıyorsa:

1. **Dosyaların konumunu kontrol edin:**
   ```bash
   ls -la /Users/mac/Desktop/hackathonMobile/hackMobile/hackMobile/tr.lproj/
   ls -la /Users/mac/Desktop/hackathonMobile/hackMobile/hackMobile/en.lproj/
   ```

2. **Clean Build Folder:**
   - Xcode menüsünden: `Product > Clean Build Folder` (⇧⌘K)

3. **Derived Data'yı temizleyin:**
   - Xcode menüsünden: `Xcode > Settings > Locations`
   - Derived Data'yı silin veya farklı bir yere taşıyın

4. **Projeyi yeniden build edin**

### Dosyalar görünmüyorsa:

1. Project Navigator'da sağ tıklayın
2. "Show in Finder" seçin
3. Dosyaların orada olduğunu kontrol edin
4. Xcode'da "Refresh" yapın (⌘R veya sağ tık > Refresh)

## ✅ Başarı Kontrolü

Localization başarıyla eklendiyse:
- ✅ Project Navigator'da `tr.lproj` ve `en.lproj` klasörleri görünür
- ✅ Her klasörün içinde `Localizable.strings` dosyası var
- ✅ File Inspector'da her iki dil seçili
- ✅ Uygulama çalıştığında TR/EN butonu dil değiştiriyor

## 📝 Notlar

- Localization dosyaları `.lproj` uzantılı klasörlerde olmalı
- `Localizable.strings` dosyası her `.lproj` klasöründe olmalı
- Xcode otomatik olarak doğru dil dosyasını seçer
- LanguageManager runtime'da dil değiştirmeyi yönetir








