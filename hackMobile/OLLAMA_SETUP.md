# Ollama Entegrasyonu Kurulum Rehberi

## Adımlar

### 1. Ollama'nın Çalıştığından Emin Olun
Terminal'de şu komutu çalıştırın:
```bash
ollama serve
```

### 2. Simulator için (Geliştirme)
- Simulator kullanıyorsanız, `OllamaService.swift` dosyasındaki `baseURL` zaten `http://localhost:11434` olarak ayarlı.
- Simulator Mac'inizle aynı network'ü paylaştığı için localhost çalışır.

### 3. Gerçek iPhone/iPad için
Gerçek cihazda test etmek için Mac'inizin IP adresini bulun:

**Mac IP Adresini Bulma:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

veya

```bash
ipconfig getifaddr en0
```

**OllamaService.swift'i Güncelleyin:**
```swift
// Satır 13'ü değiştirin:
private let baseURL = "http://192.168.1.XXX:11434" // Mac'inizin IP adresini yazın
```

### 4. Info.plist Ayarları (HTTP İzinleri)

Xcode'da projenizi açın:
1. Project Navigator'da projenizi seçin
2. TARGETS > hackMobile seçin
3. Info sekmesine gidin
4. "App Transport Security Settings" ekleyin (yoksa + butonuna tıklayın)
5. "Allow Arbitrary Loads" ekleyin ve değerini `YES` yapın

VEYA

`Info.plist` dosyasına şunu ekleyin:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 5. Ollama Modelini Test Edin
Terminal'de:
```bash
ollama run satis-danismani
```

### 6. Uygulamayı Çalıştırın
- Xcode'da projeyi build edin ve çalıştırın
- AI Assistant butonuna tıklayın
- Mesaj gönderin ve Ollama'dan yanıt alın!

## Sorun Giderme

### "Connection refused" hatası
- Ollama'nın çalıştığından emin olun: `ollama serve`
- IP adresinin doğru olduğunu kontrol edin
- Mac ve iPhone'un aynı WiFi ağında olduğundan emin olun

### "HTTP 404" hatası
- Model adının doğru olduğunu kontrol edin: `satis-danismani`
- Modelin yüklü olduğundan emin olun: `ollama list`

### Simulator'da çalışmıyor
- Simulator'ı yeniden başlatın
- Xcode'u yeniden başlatın

## Notlar
- Ollama localhost'ta çalışıyor, bu yüzden Mac'iniz açık ve Ollama çalışıyor olmalı
- Gerçek cihazda kullanmak için Mac ve iPhone aynı WiFi ağında olmalı
- Production için Ollama'yı bir sunucuya deploy etmeniz gerekebilir












