#!/bin/bash

# CICO API Otomatik Başlatma Scripti
# Bu script Flask API'yi otomatik olarak başlatır

cd "$(dirname "$0")"

echo "🚀 CICO Flask API başlatılıyor..."
echo "📍 Dizin: $(pwd)"
echo ""

# Python3 ile Flask API'yi başlat
python3 cico_api.py






