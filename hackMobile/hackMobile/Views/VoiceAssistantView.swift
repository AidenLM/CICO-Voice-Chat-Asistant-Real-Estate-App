//
//  VoiceAssistantView.swift
//  hackMobile
//
//  Voice-only assistant - Konuş, dinle, cevapla, sesli oku
//

import SwiftUI
import AVFoundation

struct VoiceAssistantView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool
    @State private var messages: [ViewChatMessage] = []
    @State private var isLoading: Bool = false
    @State private var isInitializing: Bool = true
    @State private var isRecording: Bool = false
    @State private var hasStarted: Bool = false
    @StateObject private var ollamaService = OllamaService()
    @StateObject private var ttsService = TTSService()
    @StateObject private var speechService = SpeechRecognitionService()
    
    var body: some View {
        ZStack {
            // Blur background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()
                
                // Start Butonu - İlk başlatma için
                if !hasStarted {
                    Button(action: {
                        startAssistant()
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppTheme.Colors.primary,
                                            AppTheme.Colors.accent
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.3), lineWidth: 3)
                                )
                                .shadow(color: AppTheme.Colors.accent.opacity(0.5), radius: 20)
                            
                            VStack(spacing: AppTheme.Spacing.xs) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                                Text("START")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .scaleEffect(isInitializing ? 1.0 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hasStarted)
                } else {
                    // Mikrofon Butonu - Aç/Kapa (Toggle) modu
                    Button(action: {
                        if isRecording {
                            stopRecordingAndSend()
                        } else {
                            startRecording()
                        }
                    }) {
                    ZStack {
                        // Pulsing animation when recording
                        if isRecording {
                            Circle()
                                .fill(AppTheme.Colors.accent.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .scaleEffect(isRecording ? 1.2 : 1.0)
                                .opacity(isRecording ? 0.0 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 1.0)
                                        .repeatForever(autoreverses: false),
                                    value: isRecording
                                )
                        }
                        
                        // Main circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isRecording ? [
                                        AppTheme.Colors.accent,
                                        AppTheme.Colors.accent.opacity(0.8)
                                    ] : [
                                        AppTheme.Colors.surface,
                                        AppTheme.Colors.surface.opacity(0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Circle()
                                    .stroke(
                                        isRecording ? AppTheme.Colors.accent : AppTheme.Colors.tertiary.opacity(0.3),
                                        lineWidth: isRecording ? 3 : 2
                                    )
                            )
                            .shadow(color: isRecording ? AppTheme.Colors.accent.opacity(0.5) : Color.black.opacity(0.1), radius: isRecording ? 20 : 10)
                        
                        // Microphone icon
                        Image(systemName: isRecording ? "mic.fill" : "mic")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(isRecording ? .white : AppTheme.Colors.textPrimary)
                    }
                    }
                    .scaleEffect(isRecording ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
                }
                
                // Status text
                VStack(spacing: AppTheme.Spacing.sm) {
                    if isRecording {
                        Text(speechService.recognizedText.isEmpty ? "🎤 Konuşun..." : speechService.recognizedText)
                            .font(AppTheme.Typography.title3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .frame(minHeight: 60)
                            .onChange(of: speechService.recognizedText) { oldValue, newValue in
                                // Real-time text güncellemesi
                            }
                    } else if isLoading {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Düşünüyor...")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    } else if let lastMessage = messages.last, !lastMessage.isUser {
                        // Son AI yanıtını göster
                        Text(lastMessage.text)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .frame(minHeight: 60)
                    } else if !hasStarted {
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("🎤 CICO Sesli Asistan")
                                .font(AppTheme.Typography.title2)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Text("Başlamak için START butonuna tıklayın")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    } else {
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text("🎤 CICO Sesli Asistan")
                                .font(AppTheme.Typography.title2)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            
                            Text(isRecording ? "Konuşun..." : "Mikrofon butonuna tıklayarak konuşun")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    }
                }
                
                Spacer()
                
                // Close button
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.7))
                }
                .padding(.bottom, AppTheme.Spacing.xl)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
    
    private func startAssistant() {
        hasStarted = true
        
        // İlk sesi çal (ref_cico.wav)
        playWelcomeSound()
        
        // Sonra CICO'yu başlat
        initializeChat()
    }
    
    private func startRecording() {
        guard !isRecording && !isLoading else { return }
        
        Task { @MainActor in
            isRecording = true
        }
        
        Task {
            do {
                let locale = languageManager.currentLanguage == .turkish 
                    ? Locale(identifier: "tr-TR") 
                    : Locale(identifier: "en-US")
                
                // Real-time recognition başlat
                _ = try await speechService.startListening(locale: locale)
            } catch {
                await MainActor.run {
                    isRecording = false
                    print("Speech Recognition Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func stopRecordingAndSend() {
        speechService.stopListening()
        
        Task { @MainActor in
            isRecording = false
            
            // Tanınan text'i al
            let recognizedText = speechService.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Eğer text varsa otomatik gönder
            if !recognizedText.isEmpty {
                sendMessage(text: recognizedText)
            }
        }
    }
    
    // ref_cico.wav başlangıç sesini çal
    private func playWelcomeSound() {
        // ref_cico 2.wav dosyasını bundle'dan yükle (dosya adında boşluk var)
        if let soundURL = Bundle.main.url(forResource: "ref_cico 2", withExtension: "wav") {
            Task {
                do {
                    let player = try AVAudioPlayer(contentsOf: soundURL)
                    player.play()
                    // Ses bitene kadar bekle
                    try? await Task.sleep(nanoseconds: UInt64(player.duration * 1_000_000_000))
                } catch {
                    print("Welcome sound error: \(error.localizedDescription)")
                }
            }
        } else {
            // Dosya bulunamazsa log yaz
            print("ref_cico 2.wav not found in bundle")
        }
    }
    
    private func initializeChat() {
        isInitializing = true
        
        Task {
            do {
                let welcomeMessage = try await ollamaService.sendInitialMessage()
                await MainActor.run {
                    messages.append(ViewChatMessage(text: welcomeMessage, isUser: false))
                    isInitializing = false
                    
                    // Welcome mesajını sesli oku (CICO TTS ile)
                    Task {
                        do {
                            try await ttsService.speak(
                                text: welcomeMessage,
                                language: languageManager.currentLanguage
                            )
                        } catch {
                            print("TTS Error: \(error.localizedDescription)")
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    let fallbackMessage = "Welcome to Cyprus Constructions.\n\nI am CICO, your dedicated Real Estate Sales Assistant.\n\nI officially support English and Turkish.\n\nWhich language would you like me to use for our conversation?"
                    messages.append(ViewChatMessage(text: fallbackMessage, isUser: false))
                    isInitializing = false
                    
                    // Fallback mesajını da sesli oku
                    Task {
                        do {
                            try await ttsService.speak(
                                text: fallbackMessage,
                                language: languageManager.currentLanguage
                            )
                        } catch {
                            print("TTS Error: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    private func sendMessage(text: String) {
        guard !text.isEmpty, !isLoading else { return }
        
        // Add user message
        let userMessage = ViewChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        isLoading = true
        
        // AI mesajını boş olarak ekle (streaming ile dolduracağız)
        let aiMessageId = UUID()
        var aiMessage = ViewChatMessage(text: "", isUser: false)
        aiMessage.id = aiMessageId
        messages.append(aiMessage)
        
        // Streaming ile mesaj gönder
        Task {
            do {
                var accumulatedText = ""
                var buffer = ""
                let bufferSize = 20
                
                let conversationHistory = messages.filter { $0.id != userMessage.id && $0.id != aiMessageId }
                
                try await ollamaService.sendMessageStreaming(
                    userMessage: text,
                    conversationHistory: conversationHistory
                ) { chunk in
                    buffer += chunk
                    accumulatedText += chunk
                    
                    if buffer.count >= bufferSize || chunk.contains(" ") || chunk.contains(".") || chunk.contains(",") || chunk.contains("\n") {
                        if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                            messages[index].text = accumulatedText
                        }
                        buffer = ""
                    }
                }
                
                if !buffer.isEmpty {
                    if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                        messages[index].text = accumulatedText
                    }
                }
                
                // AI yanıtı tamamlandı - otomatik olarak sesli oku
                if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                    let finalText = messages[index].text
                    if !finalText.isEmpty {
                        Task {
                            do {
                                try await ttsService.speak(
                                    text: finalText,
                                    language: languageManager.currentLanguage
                                )
                            } catch {
                                print("TTS Error: \(error.localizedDescription)")
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = String(format: "error_occurred".localized, error.localizedDescription)
                    if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                        messages[index].text = errorMessage
                    } else {
                        messages.append(ViewChatMessage(text: errorMessage, isUser: false))
                    }
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    VoiceAssistantView(isPresented: .constant(true))
        .environmentObject(LanguageManager.shared)
}

