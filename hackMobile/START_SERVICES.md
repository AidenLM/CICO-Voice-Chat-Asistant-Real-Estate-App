# 🚀 Servisleri Başlatma Rehberi

Bilgisayar yeniden başladıktan sonra servisleri başlatmak için:

## Hızlı Başlatma

### Terminal'de Tek Komut:
```bash
cd /Users/mac/Desktop/hackathonMobile/hackMobile
./start_cico_api.sh
```

### Veya Manuel:
```bash
cd /Users/mac/Desktop/hackathonMobile/hackMobile
python3 cico_api.py
```

## Otomatik Başlatma (macOS)

### LaunchAgent ile Otomatik Başlatma:

1. LaunchAgent dosyasını oluşturun:
```bash
mkdir -p ~/Library/LaunchAgents
```

2. `com.cico.api.plist` dosyasını oluşturun:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cico.api</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>/Users/mac/Desktop/hackathonMobile/hackMobile/cico_api.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>/Users/mac/Desktop/hackathonMobile/hackMobile</string>
    <key>StandardOutPath</key>
    <string>/tmp/cico_api.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/cico_api_error.log</string>
</dict>
</plist>
```

3. LaunchAgent'ı yükleyin:
```bash
launchctl load ~/Library/LaunchAgents/com.cico.api.plist
```

## Gerekli Servisler

### 1. Ollama (Port 11434)
```bash
OLLAMA_HOST=0.0.0.0:11434 ollama serve
```

### 2. CICO Flask API (Port 5001)
```bash
cd /Users/mac/Desktop/hackathonMobile/hackMobile
python3 cico_api.py
```

## Servis Durumunu Kontrol Etme

### Ollama Kontrolü:
```bash
curl http://localhost:11434/api/tags
```

### Flask API Kontrolü:
```bash
curl http://localhost:5001/health
```

## Sorun Giderme

### Port 5001 kullanımda hatası:
```bash
lsof -ti:5001 | xargs kill -9
```

### Port 11434 kullanımda hatası:
```bash
lsof -ti:11434 | xargs kill -9
```

### Logları kontrol etme:
```bash
tail -f /tmp/cico_api.log
tail -f /tmp/cico_api_error.log
```






