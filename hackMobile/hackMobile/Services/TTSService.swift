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
    // Port 5000 AirPlay tarafından kullanılıyor, bu yüzden 5001 kullanıyoruz
    #if targetEnvironment(simulator)
    private let baseURL = "http://localhost:5001"
    #else
    private let baseURL = "http://192.168.0.104:5001"  // Gerçek cihaz için Mac IP adresi
    #endif
    
    private var audioPlayer: AVAudioPlayer?
    @Published var isSpeaking: Bool = false
    
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
        // cico_api.py MP3 döndürüyor, bu yüzden .mp3 uzantısı kullanıyoruz
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tts_\(UUID().uuidString).mp3")
        
        try data.write(to: tempURL)
        
        // Ses dosyasını oynat
        await MainActor.run {
            isSpeaking = true
        }
        
        try await playAudio(from: tempURL)
        
        await MainActor.run {
            isSpeaking = false
        }
        
        // Geçici dosyayı sil
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // Ses dosyasını oynat
    private func playAudio(from url: URL) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                // Audio session'ı ayarla
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                
                let player = try AVAudioPlayer(contentsOf: url)
                player.delegate = AudioPlayerDelegate { [weak self] success in
                    Task { @MainActor in
                        self?.isSpeaking = false
                    }
                    if success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: TTSError.playbackFailed)
                    }
                }
                self.audioPlayer = player
                player.play()
            } catch {
                Task { @MainActor in
                    self.isSpeaking = false
                }
                continuation.resume(throwing: TTSError.playbackFailed)
            }
        }
    }
    
    // Ses oynatmayı durdur
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
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

