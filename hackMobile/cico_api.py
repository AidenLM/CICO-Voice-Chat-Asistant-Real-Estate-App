"""
CICO Flask REST API
Ollama + Whisper STT + Edge TTS entegrasyonu
iOS uygulamasından erişim için REST API
"""

import os
import asyncio
import threading
import queue
import time
try:
    from faster_whisper import WhisperModel
    WHISPER_AVAILABLE = True
except ImportError:
    WHISPER_AVAILABLE = False
    print("⚠️ faster_whisper not available - STT endpoint will be disabled")
import ollama
import edge_tts
try:
    import pygame
    PYGAME_AVAILABLE = True
except ImportError:
    PYGAME_AVAILABLE = False
import sys
try:
    import pyaudio
    import wave
    PYAUDIO_AVAILABLE = True
except ImportError:
    PYAUDIO_AVAILABLE = False
from langdetect import detect, DetectorFactory
import re
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import tempfile
import io

# Dil tespiti sabitlensin
DetectorFactory.seed = 0

# Dosya yolları için güvenli çalışma dizini
if not os.path.exists("temp_audio"):
    os.makedirs("temp_audio")

sys.stdout.reconfigure(encoding='utf-8')

# Flask app
app = Flask(__name__)
CORS(app)  # iOS uygulamasından erişim için

# --- AYARLAR ---
OLLAMA_MODEL = "satis-danismani"
SYSTEM_PROMPT = """
SYSTEM IDENTITY AND ROLE
You are CICO, the Senior Investment Sales Executive for Cyprus Constructions.
Location: All projects are exclusively in NORTH CYPRUS.
Style: Professional, Plain Text, Concise.

CRITICAL BEHAVIORAL RULES
1. PLAIN TEXT ONLY: Do NOT use asterisks, bold text, hashtags, or markdown formatting. Write clean, plain text.
2. ENGLISH NAMES ONLY: Never translate project names. Always use: Bahamas Homes, Pearl Island, Idyll Homes, Mykonos Homes, Hawaii Homes, Aloha Beach Resort, Phuket Health & Wellness Resort, Edremit Villas, Maldives Homes.
3. SHORT ANSWERS: Answer ONLY what is asked. Maximum 2 to 3 sentences.
4. NO LISTS: Do not list projects until the user answers the strategy question.

MANDATORY INITIAL OUTPUT
Display this exactly once at the start:

Welcome to Cyprus Constructions.

I am CICO. Which language would you like me to use? (English, Turkish, Russian)

STRATEGY HANDSHAKE (THE SECOND STEP)
Once the user selects a language, you MUST ask the investment strategy question immediately. Do not say anything else.

If Turkish:
  Harika. Size Turkce yardimci olacagim. Kisa vadeli yatirim mi (Al-Sat), uzun vadeli yatirim mi (Kira Getirisi), yoksa oturum amacli mi dusunuyorsunuz?

If English:
  Great. I will assist you in English. Are you looking for short-term investment (Flip), long-term investment (Rental Yield), or a home to live in?

If Russian:
  Otlichno. Ya pomogu vam na russkom. Vas interesuyut kratkosrochnye investitsii (pereprodazha), dolgosrochnye (arenda) ili zhilye dlya sebya?

INVESTMENT LOGIC MAP (USE THIS TO FILTER)
When the user answers the strategy question, recommend ONLY the projects in that category:

CATEGORY 1: SHORT-TERM INVESTMENT (High Appreciation / Launch Prices)
  Target Projects: Bahamas Homes Phase 3, Phuket Phase 2.

CATEGORY 2: LONG-TERM INVESTMENT (High Rental Yield / Resort Concept)
  Target Projects: Hawaii Homes, Aloha Beach Resort, Bahamas Homes Phase 2.

CATEGORY 3: LIVING & LIFESTYLE (Luxury, Privacy, Ready to Move)
  Target Projects: Edremit Villas, Phuket Phase 3 (Villas), Phuket Phase 1 (Residences), Mykonos Homes, Pearl Island, Idyll Homes, Maldives Homes.

REAL ESTATE KNOWLEDGE BASE (MASTER INVENTORY)

A. BAHAMAS HOMES (PHASE 1, 2, 3)
Phase 3 Studio Garden (Jun 2026):
  Details: 35 m2 Gross plus 8 m2 Terrace equals 43 m2 Total.
  Price: 149,800 GBP to 160,500 GBP.

Phase 3 Studio Penthouse (Jun 2026):
  Details: 35 m2 Gross plus 8 m2 Terrace plus 35 m2 Roof equals 78 m2 Total.
  Price: 187,250 GBP.

Phase 2 Studio (Dec 2025):
  Price: 171,250 GBP (Garden) | 195,000 GBP (Penthouse).

Phase 2 Loft Penthouse (Dec 2025):
  Details: 75 m2 Gross plus 10 m2 Terrace plus 50 m2 Roof equals 135 m2 Total.
  Price: 320,950 GBP to 350,000 GBP.

Phase 1 Residences (Dec 2025):
  3 Bed Garden: 168 m2 Total with Private Pool, 750,000 GBP.
  Beach Villa: 298 m2 Total (Seafront), 2,500,000 GBP.

B. PHUKET HEALTH & WELLNESS RESORT
Phase 2 Investment (Mar 2027):
  Studio Garden: 43 m2 Total, 171,250 GBP to 174,950 GBP.
  Studio Penthouse: 78 m2 Total, 187,250 GBP.
  1+1 Garden: 60 m2 Total, 225,000 GBP.
  2+1 Loft Penthouse: 135 m2 Total, 285,750 GBP.

Phase 1 Residence (Dec 2027):
  2+1 Garden: 134.5 m2 Total, 600,000 GBP.
  2+1 Penthouse: 180.3 m2 Total, 725,000 GBP.
  2+1 Eco House: 278 m2 Total with Private Pool, 925,000 GBP.

Phase 3 Villas (Jan 2028):
  3+1 Villa Type B: 242 m2 Total with Private Pool, 1,072,500 GBP.
  6+1 Villa Type A: 334 m2 Total with Private Pool, 1,402,500 GBP.

C. HAWAII HOMES (DEC 2025)
Studio Garden: 43 m2 Total, 185,000 GBP.
Studio Penthouse: 78 m2 Total, 195,000 GBP to 210,000 GBP.
1+1 Garden: 60 m2 Total, 250,000 GBP.
2+1 Penthouse: 135 m2 Total, 350,000 GBP.
Villa Type C: 365 m2 Total, 1,500,000 GBP.

D. ALOHA BEACH RESORT (DEC 2026)
Phase 1:
  1+1 Garden: 43 m2 Total, 211,025 GBP.
  1+1 Penthouse: 78 m2 Total, 222,725 GBP.
  2+1 Garden: 86 m2 Total, 420,050 GBP.

Phase 2 Premium:
  1+1 Garden: 43 m2 Total, 313,225 GBP.
  2+1 Villa: 120 m2 Total, 1,094,225 GBP.
  Grand Villa: 365 m2 Total, 1,950,000 GBP.

E. EDREMIT VILLAS (JAN 2028)
Villa 2 (3+1): 285 m2 Int plus Plot, 1,450,000 GBP.
Villa 5 (3+1): 250 m2 Int plus Pool, 1,750,000 GBP.
Villa 12 (3+1): 209 m2 Int, 2,350,000 GBP.

F. READY UNITS (IMMEDIATE DELIVERY)
Maldives Homes: 2+1 Garden (104 m2), 475,000 GBP.
Pearl Island: Studio Furnished (43 m2), 194,995 GBP.
Idyll Homes: 1+1 Garden (85 m2), 270,000 GBP | 2+1 Loft (110 m2), 325,000 GBP.
Mykonos Homes: 2+1 Garden (116 m2), 495,000 GBP | 5+1 Villa (685 m2), 2,500,000 GBP.

CLOSING PROTOCOL
End with a specific question.
Example: Which unit type shall I calculate a payment plan for?
"""

# --- GÜNCELLENMİŞ SES LİSTESİ ---
SESLER = {
    "tr": "tr-TR-AhmetNeural",
    "en": "en-US-AriaNeural",
    "ru": "ru-RU-DmitryNeural"
}

YEDEK_SES = SESLER["en"]
last_detected_lang = "en"

# Global state
stt_model = None
conversation_history = {}  # Her client için ayrı conversation history

print("\n" + "="*50)
print("🚀 CICO Flask API Başlatılıyor...")
print("="*50)

# 1. WHISPER (KULAK) - CPU (Opsiyonel - iOS native STT kullanıyoruz)
stt_model = None
if WHISPER_AVAILABLE:
    print("👂 Whisper (Kulak) hazırlanıyor (CPU)...")
    try:
        stt_model = WhisperModel("base", device="cpu", compute_type="int8")
        print("✅ Kulak hazır!")
    except Exception as e:
        print(f"❌ Whisper Hatası: {e}")
        print("⚠️ STT özelliği çalışmayacak!")
        stt_model = None
else:
    print("⚠️ faster_whisper yüklü değil - STT endpoint devre dışı")

# 2. SES ÇALMA KUYRUĞU (Opsiyonel)
if PYGAME_AVAILABLE:
    pygame.mixer.init()
else:
    print("⚠️ pygame yüklü değil - ses çalma kuyruğu devre dışı")

# Dil Algılama ve Hata Yönetimi
def get_voice_by_lang(text):
    global last_detected_lang
    if not text or len(text.strip()) < 2: 
        return SESLER[last_detected_lang]

    if len(text.split()) < 5: 
        return SESLER[last_detected_lang]

    try:
        lang_code = detect(text)
        if lang_code == 'tr':
            last_detected_lang = "tr"
            return SESLER["tr"]
        elif lang_code == 'ru':
            last_detected_lang = "ru"
            return SESLER["ru"]
        else:
            last_detected_lang = "en"
            return SESLER["en"]
    except:
        return SESLER[last_detected_lang]

async def text_to_speech_async(text):
    """TTS fonksiyonu - async"""
    if not text or len(text) < 2: 
        return None
    
    secilen_ses = get_voice_by_lang(text)
    filename = os.path.join("temp_audio", f"temp_{int(time.time()*1000)}.mp3")
    
    try:
        communicate = edge_tts.Communicate(text, secilen_ses)
        await communicate.save(filename)
        return filename
    except Exception as e:
        print(f"⚠️ TTS Hatası ({secilen_ses}): {e}")
        if secilen_ses != YEDEK_SES:
            try:
                communicate = edge_tts.Communicate(text, YEDEK_SES)
                await communicate.save(filename)
                return filename
            except:
                return None
        return None

# --- FLASK ROUTES ---

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'ollama_model': OLLAMA_MODEL,
        'whisper_ready': stt_model is not None
    })

@app.route('/tts', methods=['POST'])
def text_to_speech():
    """Text-to-Speech endpoint"""
    try:
        data = request.json
        text = data.get('text', '')
        language = data.get('language', 'tr')  # 'tr', 'en', 'ru'
        
        if not text:
            return jsonify({'error': 'Text is required'}), 400
        
        # Async TTS'i sync olarak çalıştır
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        try:
            audio_file = loop.run_until_complete(text_to_speech_async(text))
        finally:
            loop.close()
        
        if not audio_file or not os.path.exists(audio_file):
            return jsonify({'error': 'TTS failed'}), 500
        
        # Ses dosyasını gönder
        # Edge TTS MP3 formatında döndürüyor, ama iOS WAV da oynatabilir
        # MIME type'ı doğru ayarla
        return send_file(
            audio_file,
            mimetype='audio/mpeg',  # MP3 için doğru MIME type
            as_attachment=False
        )
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/stt', methods=['POST'])
def speech_to_text():
    """Speech-to-Text endpoint - audio file gönderilmeli"""
    try:
        if stt_model is None:
            return jsonify({'error': 'Whisper model not initialized'}), 500
        
        if 'audio' not in request.files:
            return jsonify({'error': 'No audio file provided'}), 400
        
        audio_file = request.files['audio']
        if audio_file.filename == '':
            return jsonify({'error': 'Empty audio file'}), 400
        
        # Geçici dosyaya kaydet
        temp_path = os.path.join("temp_audio", f"stt_{int(time.time()*1000)}.wav")
        audio_file.save(temp_path)
        
        try:
            segments, _ = stt_model.transcribe(temp_path, beam_size=5)
            text = "".join([segment.text for segment in segments]).strip()
            
            # Geçici dosyayı sil
            try:
                os.remove(temp_path)
            except:
                pass
            
            if text:
                return jsonify({'text': text})
            else:
                return jsonify({'text': ''})
        except Exception as e:
            return jsonify({'error': f'STT processing failed: {str(e)}'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/chat', methods=['POST'])
def chat():
    """Ollama chat endpoint - streaming destekli"""
    try:
        data = request.json
        user_message = data.get('message', '')
        client_id = data.get('client_id', 'default')
        stream = data.get('stream', False)
        
        if not user_message:
            return jsonify({'error': 'Message is required'}), 400
        
        # Client için conversation history'yi al veya oluştur
        if client_id not in conversation_history:
            conversation_history[client_id] = [
                {'role': 'system', 'content': SYSTEM_PROMPT}
            ]
        
        messages = conversation_history[client_id].copy()
        messages.append({'role': 'user', 'content': user_message})
        
        if stream:
            # Streaming response
            def generate():
                full_response = ""
                try:
                    stream_response = ollama.chat(
                        model=OLLAMA_MODEL, 
                        messages=messages, 
                        stream=True
                    )
                    
                    for chunk in stream_response:
                        token = chunk['message']['content']
                        full_response += token
                        yield f"data: {json.dumps({'content': token, 'done': False})}\n\n"
                    
                    # Conversation history'yi güncelle
                    conversation_history[client_id].append({'role': 'user', 'content': user_message})
                    conversation_history[client_id].append({'role': 'assistant', 'content': full_response})
                    
                    yield f"data: {json.dumps({'content': '', 'done': True})}\n\n"
                except Exception as e:
                    yield f"data: {json.dumps({'error': str(e)})}\n\n"
            
            from flask import Response
            return Response(generate(), mimetype='text/event-stream')
        else:
            # Non-streaming response
            try:
                response = ollama.chat(model=OLLAMA_MODEL, messages=messages)
                assistant_message = response['message']['content']
                
                # Conversation history'yi güncelle
                conversation_history[client_id].append({'role': 'user', 'content': user_message})
                conversation_history[client_id].append({'role': 'assistant', 'content': assistant_message})
                
                return jsonify({'message': assistant_message})
            except Exception as e:
                return jsonify({'error': str(e)}), 500
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/chat/init', methods=['POST'])
def chat_init():
    """İlk karşılama mesajını al"""
    try:
        client_id = request.json.get('client_id', 'default') if request.json else 'default'
        
        # Client için conversation history'yi başlat
        if client_id not in conversation_history:
            conversation_history[client_id] = [
                {'role': 'system', 'content': SYSTEM_PROMPT}
            ]
        
        messages = conversation_history[client_id].copy()
        
        # Boş mesaj göndererek welcome mesajını tetikle
        try:
            response = ollama.chat(model=OLLAMA_MODEL, messages=messages)
            welcome_message = response['message']['content']
            
            # Conversation history'yi güncelle
            conversation_history[client_id].append({'role': 'assistant', 'content': welcome_message})
            
            return jsonify({'message': welcome_message})
        except Exception as e:
            return jsonify({'error': str(e)}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/chat/reset', methods=['POST'])
def chat_reset():
    """Conversation history'yi sıfırla"""
    try:
        client_id = request.json.get('client_id', 'default') if request.json else 'default'
        conversation_history[client_id] = [
            {'role': 'system', 'content': SYSTEM_PROMPT}
        ]
        return jsonify({'status': 'reset'})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == "__main__":
    print("\n" + "="*50)
    print("🌐 CICO Flask API Başlatılıyor...")
    print("📍 Endpoint: http://0.0.0.0:5001")
    print("="*50)
    app.run(host='0.0.0.0', port=5001, debug=True)

