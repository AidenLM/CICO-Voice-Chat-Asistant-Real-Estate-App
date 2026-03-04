import os
import asyncio
import threading
import queue
import time
from faster_whisper import WhisperModel
import ollama
import edge_tts
import pygame
import sys
import pyaudio
import wave
import keyboard
from langdetect import detect, DetectorFactory
import re

# Dil tespiti sabitlensin
DetectorFactory.seed = 0

# Dosya yolları için güvenli çalışma dizini
if not os.path.exists("temp_audio"):
    os.makedirs("temp_audio")

sys.stdout.reconfigure(encoding='utf-8')

# --- AYARLAR ---
OLLAMA_MODEL = "satis-danismani-ozel"
# 🚨 KRİTİK REVİZYON: Modelfile'daki TAM PROMPT'U BURAYA YAPIŞTIRIN!
# Modelfile doğru yüklenemiyorsa, Python üzerinden zorla gönderiyoruz.
# Aksi takdirde model genel cevap vermeye devam eder.
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

print("\n" + "="*50)
print("🚀 CICO AI (AHMET BEY MODU) BAŞLATILIYOR...")
print("="*50)

# 1. WHISPER (KULAK) - CPU
print("👂 Whisper (Kulak) hazırlanıyor (CPU)...")
try:
    stt_model = WhisperModel("base", device="cpu", compute_type="int8")
    print("✅ Kulak hazır!")
except Exception as e:
    print(f"❌ Whisper Hatası: {e}")
    exit()

# 2. SES KAYIT AYARLARI
CHUNK = 1024
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 44100

# 3. SES ÇALMA KUYRUĞU
audio_queue = queue.Queue()
is_ai_speaking = False
pygame.mixer.init()

# Dil Algılama ve Hata Yönetimi
def get_voice_by_lang(text):
    global last_detected_lang
    if not text or len(text.strip()) < 2: return SESLER[last_detected_lang]

    # Modeliniz kısıtlı cevap verdiğinde dil tespiti için daha uzun metin gerekebilir.
    # 5 kelimeden azsa son dili koru.
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
        # Dil tespiti başarısız olursa son kullanılan dili kullan
        return SESLER[last_detected_lang]

def play_audio_from_queue():
    global is_ai_speaking
    while True:
        file_path = audio_queue.get()
        if file_path is None: break
        try:
            is_ai_speaking = True
            pygame.mixer.music.load(file_path)
            pygame.mixer.music.play()
            while pygame.mixer.music.get_busy():
                pygame.time.Clock().tick(10)
            pygame.mixer.music.unload()
            time.sleep(0.1)
            try: os.remove(file_path)
            except: pass
        except Exception as e:
            print(f"Hata (Ses Çalma): {e}")
        finally:
            # Sadece kuyruk tamamen boşaldığında konuşmanın bittiğini işaretle
            if audio_queue.empty() and not pygame.mixer.music.get_busy():
                 is_ai_speaking = False
        audio_queue.task_done()

threading.Thread(target=play_audio_from_queue, daemon=True).start()

async def text_to_speech(text):
    global is_ai_speaking
    if not text or len(text) < 2: return
    
    secilen_ses = get_voice_by_lang(text)

    # Geçici ses dosyalarını daha güvenli bir klasöre kaydetme
    filename = os.path.join("temp_audio", f"temp_{int(time.time()*1000)}.mp3")
    
    try:
        communicate = edge_tts.Communicate(text, secilen_ses)
        await communicate.save(filename)
        audio_queue.put(filename)
    except Exception as e:
        print(f"⚠️ TTS Hatası ({secilen_ses}): {e}")
        # Hata olursa, her zaman İngilizce yedek ses ile dene
        if secilen_ses != YEDEK_SES:
             try:
                print(f"Yedek TTS deneniyor: {YEDEK_SES}")
                communicate = edge_tts.Communicate(text, YEDEK_SES)
                await communicate.save(filename)
                audio_queue.put(filename)
             except Exception as e_yedek:
                print(f"❌ Yedek TTS de başarısız oldu: {e_yedek}")

def wait_for_ai_to_finish():
    while is_ai_speaking or not audio_queue.empty() or pygame.mixer.music.get_busy():
        time.sleep(0.1)

def record_audio_manual():
    wait_for_ai_to_finish()
    
    print("\n" + "-"*40)
    print("🎤 KONUŞMAK İÇİN [ENTER] TUŞUNA BASILI TUTUN...")
    print("🔴 (Konuşmanız bitince tuşu bırakın)")
    print("-" * 40)
    
    keyboard.wait('enter')
    
    p = pyaudio.PyAudio()
    stream = p.open(format=FORMAT, channels=CHANNELS, rate=RATE, input=True, frames_per_buffer=CHUNK)
    frames = []

    while keyboard.is_pressed('enter'):
        try:
            data = stream.read(CHUNK)
            frames.append(data)
        except:
            break

    print("✅ Kayıt Alındı. İşleniyor...")
    stream.stop_stream()
    stream.close()
    p.terminate()

    wf = wave.open("temp_input.wav", 'wb')
    wf.setnchannels(CHANNELS)
    wf.setsampwidth(p.get_sample_size(FORMAT))
    wf.setframerate(RATE)
    wf.writeframes(b''.join(frames))
    wf.close()

    try:
        segments, _ = stt_model.transcribe("temp_input.wav", beam_size=5)
        text = "".join([segment.text for segment in segments]).strip()
        if text:
            print(f"👤 SİZ: {text}")
            return text
        return None
    except Exception as e:
        print(f"Hata: {e}")
        return None
    
async def main_loop():
    # 🚨 REVİZYON: Tüm SYSTEM PROMPT'u ilk mesaj olarak gönderiyoruz.
    messages = [{'role': 'system', 'content': SYSTEM_PROMPT}]
    
    # 🚨 REVİZYON: Welcome mesajını koddan değil, Ollama'dan alıyoruz.
    # Bu, modelin kuralı uygulamasını (Dil Sorusu) zorlar.
    
    print("🧠 Başlangıç mesajı alınıyor...", end="", flush=True)

    full_response = ""
    current_sentence = ""
    
    try:
        # Modelden ilk cevabı (Welcome ve Dil Sorusu) stream olarak al
        stream = ollama.chat(model=OLLAMA_MODEL, messages=messages, stream=True)
        print("\r🏢 CICO: ", end="")
        
        for chunk in stream:
            token = chunk['message']['content']
            print(token, end="", flush=True)
            
            full_response += token
            current_sentence += token
            
            # Akış sırasında konuşma (TTS)
            sentence_enders = r'[.?!:\n]' 
            
            if re.search(sentence_enders, token) or len(current_sentence) > 50:
                
                parts = re.split(sentence_enders, current_sentence)
                
                if not re.search(sentence_enders, token) and parts[-1].strip() != "":
                    to_speak = current_sentence[:-(len(parts[-1]))]
                    current_sentence = parts[-1]
                else:
                    to_speak = current_sentence
                    current_sentence = ""
                
                if to_speak.strip() and len(to_speak.strip()) > 5:
                    await text_to_speech(to_speak)
        
        # Kalan son cümleyi konuş
        if current_sentence.strip():
            await text_to_speech(current_sentence)
            
        messages.append({'role': 'assistant', 'content': full_response})
        print("\n")
        
    except Exception as e:
        print(f"\n❌ Başlangıç Akışı Hatası: {e}")
        # Hata durumunda bile devam etmeye çalış
        pass

    # İlk konuşma (Welcome + Dil Sorusu) bittikten sonra döngü başlar
    wait_for_ai_to_finish()

    while True:
        user_input = record_audio_manual()
        if not user_input:
            print("⚠️ Ses duyulmadı.")
            continue
        
        if "exit" in user_input.lower() or "kapat" in user_input.lower():
            break

        messages.append({'role': 'user', 'content': user_input})
        
        print("🧠 Düşünüyor...", end="", flush=True)
        
        full_response = ""
        current_sentence = ""
        
        try:
            stream = ollama.chat(model=OLLAMA_MODEL, messages=messages, stream=True)
            print("\r🏢 CICO: ", end="")
            
            for chunk in stream:
                token = chunk['message']['content']
                print(token, end="", flush=True)
                
                full_response += token
                current_sentence += token
                
                # Akış sırasında konuşma (TTS)
                sentence_enders = r'[.?!:\n]' 
                
                if re.search(sentence_enders, token) or len(current_sentence) > 50:
                    
                    parts = re.split(sentence_enders, current_sentence)
                    
                    if not re.search(sentence_enders, token) and parts[-1].strip() != "":
                        to_speak = current_sentence[:-(len(parts[-1]))]
                        current_sentence = parts[-1]
                    else:
                        to_speak = current_sentence
                        current_sentence = ""
                    
                    if to_speak.strip() and len(to_speak.strip()) > 5:
                        await text_to_speech(to_speak)
            
            # Yayın bittiğinde geriye kalan metni konuş
            if current_sentence.strip():
                await text_to_speech(current_sentence)
                
            messages.append({'role': 'assistant', 'content': full_response})
            print("\n")
            
        except Exception as e:
            print(f"\n❌ Ollama/Akış Hatası: {e}")

if __name__ == "__main__":
    try:
        # Kod çalışmaya başlamadan önce geçici dosyaları temizle
        if os.path.exists("temp_audio"):
            for f in os.listdir("temp_audio"):
                if f.endswith(".mp3"):
                     try: os.remove(os.path.join("temp_audio", f))
                     except: pass
        
        asyncio.run(main_loop())
    except KeyboardInterrupt:
        print("\nSistem kapatıldı.")
    except Exception as final_e:
        print(f"\nBeklenmedik Ana Hata: {final_e}")
    finally:
         # Çıkışta ses dosylarını temizle
        if os.path.exists("temp_audio"):
            for f in os.listdir("temp_audio"):
                if f.endswith(".mp3"):
                    try:
                        os.remove(os.path.join("temp_audio", f))
                    except:
                        pass
        print("Geçici ses dosyaları temizlendi.")