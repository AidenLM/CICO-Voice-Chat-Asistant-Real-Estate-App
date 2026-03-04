# 🏠 hackMobile - AI-Powered Real Estate Mobile App

Modern, AI destekli emlak listeleme ve yönetim uygulaması. Ollama entegrasyonu ile akıllı asistan ve sesli asistan özellikleri sunar.

## ✨ Özellikler

### 🏘️ Emlak Listeleme
- **Pinterest tarzı grid layout** ile modern görsel deneyim
- **Filtreleme sistemi**: Tümü, Müsait, Satıldı, Lüks, Yeni
- **Arama özelliği**: Emlak adı, konum ve açıklama bazlı arama
- **Detaylı görüntüleme**: Her emlak için detaylı bilgi ve görsel galeri
- **Çoklu dil desteği**: Türkçe ve İngilizce

### 🤖 AI Asistan
- **Metin tabanlı chat**: Ollama entegrasyonu ile akıllı sohbet
- **Sesli asistan (CICO)**: Konuşarak etkileşim kurma
  - Speech-to-Text: Mikrofon ile konuşma tanıma
  - Text-to-Speech: AI yanıtlarını sesli dinleme
  - Hoş geldin sesi: Başlangıçta özel ses efekti

### 🎨 Modern UI/UX
- **Premium tasarım**: Light mode odaklı modern arayüz
- **Floating action buttons**: Hızlı erişim için yüzen butonlar
- **Async image loading**: Optimize edilmiş görsel yükleme
- **Responsive layout**: Tüm cihaz boyutlarına uyumlu

## 🛠️ Teknolojiler

### iOS (SwiftUI)
- **SwiftUI**: Modern UI framework
- **Core Data**: Yerel veri saklama
- **Speech Framework**: Native iOS speech recognition
- **AVFoundation**: Ses çalma ve kayıt
- **Combine**: Reactive programming

### Backend
- **Ollama**: Yerel AI modeli (`satis-danismani`)
- **Flask**: Python REST API (`cico_api.py`)
- **Edge TTS**: Text-to-Speech servisi
- **faster-whisper**: Speech-to-Text (opsiyonel)

## 📋 Gereksinimler

### iOS Geliştirme
- Xcode 14.0+
- iOS 16.0+
- macOS 13.0+ (geliştirme için)

### Python Backend
- Python 3.8+
- Flask
- Ollama (yerel kurulum)

## 🚀 Kurulum

### 1. Projeyi Klonlayın

```bash
git clone <repository-url>
cd hackMobile
```

### 2. Ollama Kurulumu

Detaylı kurulum için: [OLLAMA_SETUP.md](./OLLAMA_SETUP.md)

```bash
# Ollama'yı indirin ve kurun
# https://ollama.ai

# Modeli oluşturun
ollama create satis-danismani -f promt.txt

# Ollama'yı network'ten erişilebilir şekilde başlatın
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

**Önemli**: Gerçek cihazdan erişim için Ollama'yı `0.0.0.0:11434` adresinde başlatmanız gerekiyor.

### 3. Python Backend Kurulumu

Detaylı kurulum için: [CICO_API_SETUP.md](./CICO_API_SETUP.md)

```bash
# Python paketlerini yükleyin
pip install flask flask-cors ollama edge-tts pygame pyaudio langdetect

# Opsiyonel: faster-whisper (STT için, iOS native STT kullanılıyor)
pip install faster-whisper
```

### 4. CICO API'yi Başlatın

```bash
# Terminal'de proje dizininde
python3 cico_api.py
```

API `http://0.0.0.0:5001` adresinde çalışacaktır.

### 5. iOS Uygulamasını Yapılandırın

#### IP Adresi Ayarları

Gerçek cihazda test etmek için Mac'inizin IP adresini bulun:

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

Bulduğunuz IP adresini (örn: `192.168.0.104`) şu dosyalarda güncelleyin:

- `hackMobile/Services/OllamaService.swift`
- `hackMobile/Services/TTSService.swift`

**Not**: Simulator için otomatik olarak `localhost` kullanılır. Gerçek cihaz için IP adresi gereklidir.

#### Info.plist İzinleri

Uygulama şu izinleri gerektirir (zaten yapılandırılmış):
- `NSMicrophoneUsageDescription`: Mikrofon kullanımı için
- `NSSpeechRecognitionUsageDescription`: Konuşma tanıma için

### 6. Xcode'da Projeyi Açın

```bash
open hackMobile.xcodeproj
```

Xcode'da:
1. Target'ı seçin
2. Signing & Capabilities'den team'inizi seçin
3. Build ve Run (⌘R)

## 📱 Kullanım

### Ana Ekran
- **Arama**: Üst kısımdaki arama çubuğundan emlak arayın
- **Filtreleme**: Alt kısımdaki filtre butonlarıyla filtreleyin
- **Detay**: Bir emlak kartına tıklayarak detayları görüntüleyin

### AI Chat (Sağ Alt)
- Sağ alt köşedeki AI butonuna tıklayın
- Metin tabanlı sohbet başlatın
- Ollama modeli ile akıllı yanıtlar alın

### Sesli Asistan (Sol Alt)
- Sol alt köşedeki mikrofon butonuna tıklayın
- **START** butonuna basarak başlatın (hoş geldin sesi çalar)
- Mikrofon butonuna tıklayarak konuşmaya başlayın
- Konuşmanızı bitirdikten sonra tekrar tıklayarak gönderin
- AI yanıtı otomatik olarak sesli okunur

## 📁 Proje Yapısı

```
hackMobile/
├── hackMobile/                    # iOS uygulama kaynak kodları
│   ├── Components/                # Yeniden kullanılabilir bileşenler
│   │   ├── PropertyCard.swift
│   │   ├── SearchBar.swift
│   │   ├── FilterPills.swift
│   │   ├── FloatingAIAssistantButton.swift
│   │   └── FloatingVoiceAssistantButton.swift
│   ├── Views/                     # Ana görünümler
│   │   ├── HomeView.swift
│   │   ├── PropertyDetailView.swift
│   │   ├── AIChatView.swift
│   │   └── VoiceAssistantView.swift
│   ├── Services/                  # Servisler
│   │   ├── OllamaService.swift    # Ollama entegrasyonu
│   │   ├── TTSService.swift       # Text-to-Speech
│   │   ├── SpeechRecognitionService.swift  # Speech-to-Text
│   │   ├── PropertyLoader.swift   # Emlak verileri
│   │   └── LanguageManager.swift  # Çoklu dil desteği
│   ├── Models/                    # Veri modelleri
│   │   └── Property.swift
│   └── Theme/                     # Tema ve stil
│       └── AppTheme.swift
├── evler/                         # Emlak görselleri ve verileri
│   ├── Aloha Beach Resort/
│   ├── Edremmit Villas/
│   ├── Pearl Island Homes/
│   └── ...
├── cico_api.py                    # Python Flask API
└── README.md                      # Bu dosya
```

## 🔧 Yapılandırma

### Ollama Model Adı
Varsayılan model: `satis-danismani`

Değiştirmek için:
- `hackMobile/Services/OllamaService.swift`: `modelName` değişkeni
- `cico_api.py`: `OLLAMA_MODEL` değişkeni

### API Portları
- **Ollama**: `11434` (varsayılan)
- **CICO API**: `5001` (5000 AirPlay tarafından kullanılıyor)

### Dil Desteği
Desteklenen diller:
- Türkçe (`tr`)
- İngilizce (`en`)

Dil dosyaları:
- `hackMobile/tr.lproj/Localizable.strings`
- `hackMobile/en.lproj/Localizable.strings`

## 🐛 Sorun Giderme

### Ollama Bağlantı Hatası
**Hata**: `Could not connect to the server`

**Çözüm**:
1. Ollama'nın çalıştığından emin olun: `curl http://localhost:11434/api/tags`
2. Gerçek cihaz için Ollama'yı `0.0.0.0:11434` adresinde başlatın:
   ```bash
   OLLAMA_HOST=0.0.0.0:11434 ollama serve
   ```
3. IP adresini kontrol edin ve `OllamaService.swift`'te güncelleyin

### TTS Bağlantı Hatası
**Hata**: `TTS Error: Could not connect to the server`

**Çözüm**:
1. `cico_api.py`'nin çalıştığından emin olun
2. Port 5001'in açık olduğunu kontrol edin: `curl http://localhost:5001/health`
3. IP adresini `TTSService.swift`'te güncelleyin

### Speech Recognition Hatası
**Hata**: `Speech Recognition Error`

**Çözüm**:
1. Info.plist'te mikrofon ve konuşma tanıma izinlerinin olduğundan emin olun
2. Cihaz ayarlarından uygulama izinlerini kontrol edin
3. Simulator'da mikrofon çalışmaz, gerçek cihazda test edin

### Background Thread Publish Hatası
**Hata**: `Publishing changes from background threads is not allowed`

**Çözüm**: Bu hata düzeltildi. Tüm `@Published` property güncellemeleri `@MainActor` ile sarmalandı.

## 📚 Ek Dokümantasyon

- [OLLAMA_SETUP.md](./OLLAMA_SETUP.md) - Ollama kurulum ve yapılandırma
- [CICO_API_SETUP.md](./CICO_API_SETUP.md) - Python Flask API kurulumu
- [TTS_INTEGRATION_GUIDE.md](./TTS_INTEGRATION_GUIDE.md) - TTS entegrasyon detayları
- [LOCALIZATION_SETUP.md](./LOCALIZATION_SETUP.md) - Çoklu dil desteği
- [EVLER_EKLEME_REHBERI.md](./EVLER_EKLEME_REHBERI.md) - Yeni emlak ekleme rehberi

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

## 📝 Lisans

Bu proje hackathon için geliştirilmiştir.

## 👥 Ekip

- Mehmet Akif Elem 
- Emre Gündoğdu
- Yener Er

## 🙏 Teşekkürler

- Ollama ekibine yerel AI desteği için
- Edge TTS projesine ücretsiz TTS servisi için
- SwiftUI topluluğuna harika dokümantasyon için

---

**Not**: Bu uygulama hackathon projesi olarak geliştirilmiştir. Production kullanımı için ek güvenlik ve optimizasyon önlemleri alınmalıdır.
