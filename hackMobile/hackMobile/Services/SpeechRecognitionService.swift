//
//  SpeechRecognitionService.swift
//  hackMobile
//
//  Speech Recognition service for microphone input
//

import Foundation
import Speech
import AVFoundation

class SpeechRecognitionService: ObservableObject {
    @Published var isListening: Bool = false
    @Published var recognizedText: String = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    init() {
        // Türkçe ve İngilizce desteği
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "tr-TR"))
        
        // İzin durumunu kontrol et (init genellikle main thread'de çağrılır)
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        Task { @MainActor in
            authorizationStatus = SFSpeechRecognizer.authorizationStatus()
        }
    }
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    func startListening(locale: Locale = Locale(identifier: "tr-TR")) async throws -> String {
        // İzin kontrolü
        if authorizationStatus != .authorized {
            let authorized = await requestAuthorization()
            if !authorized {
                throw SpeechRecognitionError.notAuthorized
            }
        }
        
        // Önceki recognition'ı durdur
        stopListening()
        
        // Yeni recognizer oluştur (locale'e göre)
        guard let recognizer = SFSpeechRecognizer(locale: locale),
              recognizer.isAvailable else {
            throw SpeechRecognitionError.notAvailable
        }
        
        // Audio session'ı ayarla
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Önce mevcut session'ı deaktif et (eğer aktifse)
            if audioSession.isOtherAudioPlaying {
                try audioSession.setActive(false)
            }
            
            // Category ve mode'u ayarla
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            
            // Session'ı aktif et
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Kısa bir gecikme - audio session'ın tamamen aktif olması için
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 saniye
        } catch {
            print("Audio session setup error: \(error.localizedDescription)")
            throw SpeechRecognitionError.requestCreationFailed
        }
        
        // Recognition request oluştur
        let newRecognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        newRecognitionRequest.shouldReportPartialResults = true
        self.recognitionRequest = newRecognitionRequest
        
        // Audio engine'i ayarla
        // ÖNEMLİ: Audio engine'i önce prepare et - bu format'ı hazırlar
        audioEngine.prepare()
        
        // ÖNEMLİ: Audio engine prepare edildikten SONRA input node'un format'ını al
        let inputNode = audioEngine.inputNode
        var recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Eğer format geçersizse, audio engine'i yeniden başlat
        if recordingFormat.sampleRate == 0 || recordingFormat.channelCount == 0 {
            print("Format invalid after prepare, retrying...")
            
            // Audio engine'i durdur ve yeniden başlat
            if audioEngine.isRunning {
                audioEngine.stop()
            }
            
            // Yeniden prepare et
            audioEngine.prepare()
            
            // Format'ı tekrar al
            recordingFormat = inputNode.outputFormat(forBus: 0)
        }
        
        // Format'ın geçerli olduğunu kontrol et
        if recordingFormat.sampleRate == 0 || recordingFormat.channelCount == 0 {
            print("Invalid recording format after retry: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
            // Son çare: Audio session'ın gerçek sample rate'ini kullan
            let actualSampleRate = audioSession.sampleRate
            if actualSampleRate > 0 {
                print("Trying with audio session sample rate: \(actualSampleRate)")
                // Manuel format oluştur
                guard let manualFormat = AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: actualSampleRate,
                    channels: 1,
                    interleaved: false
                ) else {
                    throw SpeechRecognitionError.requestCreationFailed
                }
                recordingFormat = manualFormat
            } else {
                throw SpeechRecognitionError.requestCreationFailed
            }
        }
        
        print("Using recording format: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
        
        // installTap yap - hardware'in gerçek format'ını kullan
        // recognitionRequest'i capture et
        let requestToUse = newRecognitionRequest
        do {
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                requestToUse.append(buffer)
            }
        } catch {
            print("installTap error: \(error.localizedDescription)")
            throw SpeechRecognitionError.requestCreationFailed
        }
        
        // Audio engine'i başlat
        do {
            try audioEngine.start()
        } catch {
            print("Audio engine start error: \(error.localizedDescription)")
            // installTap'i temizle
            inputNode.removeTap(onBus: 0)
            throw SpeechRecognitionError.requestCreationFailed
        }
        
        await MainActor.run {
            isListening = true
            recognizedText = ""
        }
        
        // Recognition task başlat
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false // Continuation'ın sadece bir kez resume edilmesini garanti et
            
            recognitionTask = recognizer.recognitionTask(with: newRecognitionRequest) { [weak self] result, error in
                guard let self = self, !hasResumed else { return }
                
                // Önce result'ı kontrol et (final result varsa öncelikli)
                if let result = result {
                    let bestString = result.bestTranscription.formattedString
                    
                    Task { @MainActor in
                        self.recognizedText = bestString
                    }
                    
                    // Eğer final result ise, continuation'ı resume et ve çık
                    if result.isFinal {
                        hasResumed = true
                        Task { @MainActor in
                            self.isListening = false
                        }
                        continuation.resume(returning: bestString)
                        return
                    }
                }
                
                // Eğer error varsa ve henüz resume edilmediyse
                if let error = error, !hasResumed {
                    hasResumed = true
                    
                    Task { @MainActor in
                        self.isListening = false
                    }
                    
                    // Cancellation hatası normal (kullanıcı durdurdu)
                    let nsError = error as NSError
                    if nsError.domain == "kSFSpeechRecognizerErrorDomain" && nsError.code == 216 {
                        // Code 216 = SFSpeechRecognizerError.cancelled
                        continuation.resume(returning: self.recognizedText)
                    } else {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func stopListening() {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        try? AVAudioSession.sharedInstance().setActive(false)
        
        // Main thread'de güncelle
        Task { @MainActor in
            isListening = false
        }
    }
    
    // Kısa süreli kayıt ve tanıma (buton basılı tutma için)
    func recordAndRecognize(duration: TimeInterval = 5.0, locale: Locale = Locale(identifier: "tr-TR")) async throws -> String {
        return try await withThrowingTaskGroup(of: String?.self) { group in
            // Recognition başlat
            group.addTask {
                do {
                    return try await self.startListening(locale: locale)
                } catch {
                    return nil
                }
            }
            
            // Timeout ekle
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                self.stopListening()
                let text = await MainActor.run { self.recognizedText }
                return text.isEmpty ? nil : text
            }
            
            // İlk sonucu al
            if let result = try await group.next(), let text = result, !text.isEmpty {
                self.stopListening()
                return text
            }
            
            // Timeout olduysa mevcut text'i döndür
            self.stopListening()
            let finalText = await MainActor.run { self.recognizedText }
            return finalText.isEmpty ? "" : finalText
        }
    }
}

enum SpeechRecognitionError: LocalizedError {
    case notAuthorized
    case notAvailable
    case requestCreationFailed
    case audioEngineFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition izni verilmedi"
        case .notAvailable:
            return "Speech recognition kullanılamıyor"
        case .requestCreationFailed:
            return "Recognition request oluşturulamadı"
        case .audioEngineFailed:
            return "Audio engine başlatılamadı"
        }
    }
}

