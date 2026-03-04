# CICO API Kurulum Rehberi

## 🎯 Genel Bakış

CICO API, Ollama + Whisper STT + Edge TTS entegrasyonu ile çalışan bir Flask REST API'dir. iOS uygulamanızdan mikrofon input ve text-to-speech özelliklerini kullanmanızı sağlar.

## 📋 Gereksinimler

### Python Paketleri

```bash
pip install flask flask-cors faster-whisper ollama edge-tts pygame pyaudio langdetect
```

### Ollama Model

CICO API, `satis-danismani-ozel` modelini kullanır. Modelin yüklü olduğundan emin olun:

```bash
ollama list
# Eğer model yoksa:
ollama pull satis-danismani-ozel
```

## 🚀 Çalıştırma

### 1. Ollama'yı Başlatın

```bash
ollama serve
```

### 2. CICO API'yi Başlatın

```bash
cd /Users/mac/Desktop/hackathonMobile/hackMobile
python cico_api.py
```

API şu adreste çalışacak: `http://localhost:5000`

### 3. Gerçek Cihaz İçin IP Adresi

Gerçek iPhone/iPad'de test etmek için Mac'inizin IP adresini bulun:

```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

veya

```bash
ipconfig getifaddr en0
```

Sonra iOS uygulamasındaki servislerde IP adresini güncelleyin:
- `TTSService.swift` → `baseURL = "http://YOUR_IP:5000"`
- `SpeechRecognitionService.swift` → iOS native kullanıyor, IP gerekmez

## 📡 API Endpoints

### Health Check
```
GET /health
```

### Text-to-Speech
```
POST /tts
Content-Type: application/json

{
  "text": "Merhaba, nasılsınız?",
  "language": "tr"  // "tr", "en", "ru"
}
```

Response: Audio file (MP3)

### Speech-to-Text (Whisper)
```
POST /stt
Content-Type: multipart/form-data

audio: [audio file]
```

Response:
```json
{
  "text": "Tanınan metin burada"
}
```

### Chat (Ollama)
```
POST /chat
Content-Type: application/json

{
  "message": "Merhaba",
  "client_id": "unique_client_id",
  "stream": false
}
```

Response:
```json
{
  "message": "AI yanıtı"
}
```

### Chat Init (İlk Karşılama)
```
POST /chat/init
Content-Type: application/json

{
  "client_id": "unique_client_id"
}
```

### Chat Reset
```
POST /chat/reset
Content-Type: application/json

{
  "client_id": "unique_client_id"
}
```

## 🎤 iOS Uygulamasında Kullanım

### Mikrofon Butonu

AIChatView'da mikrofon butonu eklenmiştir:
- Mikrofon butonuna tıklayın
- Konuşun
- Tanınan metin otomatik olarak input alanına yazılır
- Gönder butonuna basarak mesajı gönderin

### TTS (Text-to-Speech)

AI yanıtlarında TTS butonu bulunur:
- Yanıt balonunun yanındaki speaker ikonuna tıklayın
- AI yanıtı sesli olarak okunur

## 🔧 Sorun Giderme

### "Connection refused" hatası
- CICO API'nin çalıştığından emin olun: `python cico_api.py`
- Port 5000'in açık olduğunu kontrol edin
- Mac ve iPhone'un aynı WiFi ağında olduğundan emin olun

### Speech Recognition çalışmıyor
- iOS Settings > Privacy > Speech Recognition iznini kontrol edin
- iOS Settings > Privacy > Microphone iznini kontrol edin
- Uygulamayı yeniden başlatın

### TTS çalışmıyor
- CICO API'nin çalıştığından emin olun
- IP adresinin doğru olduğunu kontrol edin
- `TTSService.swift` dosyasındaki `baseURL`'i kontrol edin

### Whisper STT çalışmıyor
- `faster-whisper` paketinin yüklü olduğundan emin olun
- İlk çalıştırmada model indirilecek (internet bağlantısı gerekli)

## 📝 Notlar

- CICO API Mac'inizde çalışmalı (Ollama gibi)
- Production için API'yi cloud'a deploy edebilirsiniz
- iOS native Speech Recognition kullanılıyor (daha hızlı ve güvenilir)
- TTS için Python API kullanılıyor (Edge TTS ile daha kaliteli ses)

## 🎯 Özellikler

✅ Ollama entegrasyonu  
✅ Whisper STT (Speech-to-Text)  
✅ Edge TTS (Text-to-Speech) - Türkçe, İngilizce, Rusça  
✅ iOS native Speech Recognition  
✅ Mikrofon butonu ile sesli input  
✅ TTS butonu ile sesli output  
✅ Çoklu dil desteği  
✅ Conversation history yönetimi  








