# Text-to-Speech (TTS) Entegrasyon Rehberi

## 🎯 Genel Yaklaşım

Python TTS script'inizi Swift iOS uygulamasına entegre etmek için **REST API** yaklaşımını kullanacağız. Bu, Ollama entegrasyonuna benzer bir yapı.

## 📋 Adım 1: Python Script'inizi REST API'ye Dönüştürün

### Flask ile Basit TTS API Örneği

Eğer Python script'iniz yoksa, örnek bir Flask API oluşturun:

```python
# tts_server.py
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import pyttsx3
import io
import os

app = Flask(__name__)
CORS(app)  # iOS uygulamasından erişim için

# TTS Engine'i başlat
engine = pyttsx3.init()

# Türkçe ve İngilizce ses ayarları
def setup_voice(language='tr'):
    voices = engine.getProperty('voices')
    if language == 'tr':
        # Türkçe ses bul (eğer varsa)
        for voice in voices:
            if 'turkish' in voice.name.lower() or 'tr' in voice.id.lower():
                engine.setProperty('voice', voice.id)
                break
    else:
        # İngilizce ses
        for voice in voices:
            if 'english' in voice.name.lower() or 'en' in voice.id.lower():
                engine.setProperty('voice', voice.id)
                break
    
    # Hız ve ses tonu ayarları
    engine.setProperty('rate', 150)  # Konuşma hızı
    engine.setProperty('volume', 0.9)  # Ses seviyesi

@app.route('/tts', methods=['POST'])
def text_to_speech():
    try:
        data = request.json
        text = data.get('text', '')
        language = data.get('language', 'tr')  # 'tr' veya 'en'
        
        if not text:
            return jsonify({'error': 'Text is required'}), 400
        
        # Ses ayarlarını yap
        setup_voice(language)
        
        # Ses dosyasını oluştur
        audio_file = f'/tmp/tts_output_{language}.wav'
        engine.save_to_file(text, audio_file)
        engine.runAndWait()
        
        # Ses dosyasını gönder
        return send_file(
            audio_file,
            mimetype='audio/wav',
            as_attachment=False
        )
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    print("🎤 TTS Server başlatılıyor...")
    print("📍 Endpoint: http://localhost:5000/tts")
    app.run(host='0.0.0.0', port=5000, debug=True)
```

### Alternatif: gTTS (Google Text-to-Speech) Kullanıyorsanız

```python
# tts_server_gtts.py
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from gtts import gTTS
import io
import os

app = Flask(__name__)
CORS(app)

@app.route('/tts', methods=['POST'])
def text_to_speech():
    try:
        data = request.json
        text = data.get('text', '')
        language = data.get('language', 'tr')  # 'tr' veya 'en'
        
        if not text:
            return jsonify({'error': 'Text is required'}), 400
        
        # gTTS ile ses oluştur
        tts = gTTS(text=text, lang=language, slow=False)
        
        # Ses dosyasını memory'de sakla
        audio_buffer = io.BytesIO()
        tts.write_to_fp(audio_buffer)
        audio_buffer.seek(0)
        
        # Ses dosyasını gönder
        return send_file(
            audio_buffer,
            mimetype='audio/mpeg',
            as_attachment=False
        )
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

### Kurulum

```bash
# Flask ve gerekli paketleri yükleyin
pip install flask flask-cors pyttsx3

# veya gTTS kullanıyorsanız
pip install flask flask-cors gtts
```

## 📋 Adım 2: TTS Server'ı Çalıştırın

```bash
# Terminal'de Python script'inizi çalıştırın
python tts_server.py

# Server şu adreste çalışacak:
# http://localhost:5000
```

## 📋 Adım 3: Swift'te TTS Service Oluşturun

`hackMobile/Services/TTSService.swift` dosyası oluşturun:

```swift
//
//  TTSService.swift
//  hackMobile
//
//  Text-to-Speech service using Python TTS API
//

import Foundation
import AVFoundation

class TTSService: ObservableObject {
    // Simulator için localhost, gerçek cihaz için Mac'inizin IP adresini kullanın
    private let baseURL = "http://localhost:5000"
    
    private var audioPlayer: AVAudioPlayer?
    
    // TTS isteği gönder ve sesi oynat
    func speak(text: String, language: AppLanguage = .turkish) async throws {
        guard let url = URL(string: "\(baseURL)/tts") else {
            throw TTSError.invalidURL
        }
        
        // Request body
        let requestBody: [String: Any] = [
            "text": text,
            "language": language.rawValue
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Request gönder
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw TTSError.serverError(httpResponse.statusCode)
        }
        
        // Ses dosyasını geçici olarak kaydet
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tts_\(UUID().uuidString).wav")
        
        try data.write(to: tempURL)
        
        // Ses dosyasını oynat
        try await playAudio(from: tempURL)
        
        // Geçici dosyayı sil
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // Ses dosyasını oynat
    private func playAudio(from url: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.delegate = AudioPlayerDelegate { success in
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: TTSError.playbackFailed)
                    }
                }
                self.audioPlayer = player
                player.play()
            } catch {
                continuation.resume(throwing: TTSError.playbackFailed)
            }
        }
    }
    
    // Ses oynatmayı durdur
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
}

// Audio Player Delegate
private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    let completion: (Bool) -> Void
    
    init(completion: @escaping (Bool) -> Void) {
        self.completion = completion
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        completion(flag)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        completion(false)
    }
}

// TTS Hataları
enum TTSError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Geçersiz yanıt"
        case .serverError(let code):
            return "Sunucu hatası: \(code)"
        case .playbackFailed:
            return "Ses oynatılamadı"
        }
    }
}
```

## 📋 Adım 4: AIChatView'a TTS Butonu Ekleyin

`AIChatView.swift` dosyasını güncelleyin:

```swift
struct AIChatView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var ttsService = TTSService()
    @State private var isSpeaking = false
    // ... diğer state'ler
    
    // AI mesajı için TTS butonu ekleyin
    private func addTTSButton(to message: ViewChatMessage) -> some View {
        Button(action: {
            Task {
                isSpeaking = true
                do {
                    try await ttsService.speak(
                        text: message.text,
                        language: languageManager.currentLanguage
                    )
                } catch {
                    print("TTS Error: \(error.localizedDescription)")
                }
                isSpeaking = false
            }
        }) {
            Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.accent)
        }
    }
}
```

## 📋 Adım 5: Info.plist Ayarları

Xcode'da:
1. Project Navigator'da projenizi seçin
2. TARGETS > hackMobile seçin
3. Info sekmesine gidin
4. "App Transport Security Settings" ekleyin
5. "Allow Arbitrary Loads" = `YES` (zaten Ollama için eklenmiş olmalı)

## 📋 Adım 6: Gerçek Cihaz İçin IP Adresi

Gerçek iPhone/iPad'de test etmek için:

1. Mac'inizin IP adresini bulun:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

2. `TTSService.swift` dosyasında `baseURL`'i güncelleyin:
```swift
private let baseURL = "http://192.168.1.XXX:5000" // Mac'inizin IP adresini yazın
```

## 🎯 Kullanım Örneği

```swift
// AI yanıtını seslendir
Task {
    do {
        try await ttsService.speak(
            text: "Merhaba, size nasıl yardımcı olabilirim?",
            language: .turkish
        )
    } catch {
        print("TTS hatası: \(error)")
    }
}
```

## 🔧 Sorun Giderme

### "Connection refused" hatası
- Python TTS server'ın çalıştığından emin olun
- Port 5000'in açık olduğunu kontrol edin
- Mac ve iPhone'un aynı WiFi ağında olduğundan emin olun

### Ses çalmıyor
- AVAudioPlayer için ses izinlerini kontrol edin
- Simulator'da ses çalışmayabilir, gerçek cihazda test edin

### Python script hatası
- Flask ve gerekli paketlerin yüklü olduğunu kontrol edin
- Python versiyonunun uyumlu olduğunu kontrol edin

## 📝 Notlar

- TTS server Mac'inizde çalışmalı (Ollama gibi)
- Production için TTS server'ı cloud'a deploy edebilirsiniz
- Alternatif: iOS'un native AVSpeechSynthesizer'ını kullanabilirsiniz (daha basit ama daha az özelleştirilebilir)








