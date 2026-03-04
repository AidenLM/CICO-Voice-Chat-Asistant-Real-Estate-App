//
//  AIChatView.swift
//  hackMobile
//
//  AI chat overlay sliding up with blur background
//

import SwiftUI

struct AIChatView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Binding var isPresented: Bool
    @State private var messages: [ViewChatMessage] = []
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var isInitializing: Bool = true
    @FocusState private var isInputFocused: Bool
    @StateObject private var ollamaService = OllamaService()
    @StateObject private var ttsService = TTSService()
    
    var body: some View {
        ZStack {
            // Blur background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.05)
                
                // Chat Container
                VStack(spacing: 0) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppTheme.Colors.tertiary.opacity(0.4))
                        .frame(width: 40, height: 4)
                        .padding(.top, AppTheme.Spacing.md)
                    
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("ai_assistant".localized)
                                .font(AppTheme.Typography.title3)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text("ask_me_anything".localized)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        Spacer()
                        Button(action: { isPresented = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.sm)
                    
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: AppTheme.Spacing.md) {
                                if isInitializing {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                        Text("cico_connecting".localized)
                                            .font(AppTheme.Typography.caption)
                                            .foregroundColor(AppTheme.Colors.textTertiary)
                                    }
                                    .padding()
                                }
                                
                                ForEach(messages) { message in
                                    ChatBubble(
                                        message: message,
                                        ttsService: ttsService,
                                        language: languageManager.currentLanguage
                                    )
                                    .id(message.id)
                                }
                                
                                // Loading indicator - yanıt beklenirken göster (sadece mesaj boşsa)
                                if isLoading {
                                    // Eğer son mesaj boşsa (henüz yanıt gelmediyse) loading göster
                                    if let lastMessage = messages.last, lastMessage.text.isEmpty && !lastMessage.isUser {
                                        HStack {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                            Text("responding".localized)
                                                .font(AppTheme.Typography.caption)
                                                .foregroundColor(AppTheme.Colors.textTertiary)
                                        }
                                        .padding()
                                        .id("loading-indicator")
                                    }
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.md)
                        }
                        .onChange(of: messages.count) { oldValue, newValue in
                            if let lastMessage = messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: isLoading) { oldValue, newValue in
                            if newValue {
                                // Loading başladığında scroll'u en alta kaydır
                                withAnimation {
                                    proxy.scrollTo("loading-indicator", anchor: .bottom)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.65)
                    
                    // Input Area
                    HStack(spacing: AppTheme.Spacing.sm) {
                        TextField("ask_about_properties".localized, text: $inputText, axis: .vertical)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.searchBar)
                                    .fill(AppTheme.Colors.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.Radius.searchBar)
                                            .stroke(AppTheme.Colors.tertiary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .focused($isInputFocused)
                            .lineLimit(1...4)
                        
                        Button(action: sendMessage) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.surface))
                                    .frame(width: 32, height: 32)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                AppTheme.Colors.primary,
                                                AppTheme.Colors.accent
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        .opacity((inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading) ? 0.5 : 1.0)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.md)
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.card, style: .continuous)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.sm)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
        .onAppear {
            // CICO'nun otomatik karşılama mesajını tetikle
            if messages.isEmpty {
                initializeChat()
            }
        }
    }
    
    private func initializeChat() {
        isInitializing = true
        // Boş bir mesaj göndererek CICO'nun otomatik karşılama mesajını tetikle
        Task {
            do {
                // İlk mesaj olarak boş bir string gönder, CICO otomatik karşılama mesajını gönderecek
                let welcomeMessage = try await ollamaService.sendInitialMessage()
                await MainActor.run {
                    messages.append(ViewChatMessage(text: welcomeMessage, isUser: false))
                    isInitializing = false
                }
            } catch {
                await MainActor.run {
                    // Hata durumunda fallback mesaj
                    messages.append(ViewChatMessage(
                        text: "Welcome to Cyprus Constructions.\n\nI am CICO, your dedicated Real Estate Sales Assistant.\n\nI officially support English and Turkish.\n\nWhich language would you like me to use for our conversation?",
                        isUser: false
                    ))
                    isInitializing = false
                }
            }
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        
        // Add user message
        let userMessage = ViewChatMessage(text: text, isUser: true)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        
        // AI mesajını boş olarak ekle (streaming ile dolduracağız)
        let aiMessageId = UUID()
        var aiMessage = ViewChatMessage(text: "", isUser: false)
        aiMessage.id = aiMessageId
        messages.append(aiMessage)
        
        // Streaming ile mesaj gönder
        Task {
            do {
                // Accumulated text'i Task içinde tut (her chunk için aynı instance)
                var accumulatedText = ""
                var buffer = "" // Buffer: küçük chunk'ları biriktir
                let bufferSize = 20 // Buffer 20 karaktere ulaştığında güncelle
                
                // Konuşma geçmişini hazırla (yeni eklenen AI mesajını hariç tut)
                let conversationHistory = messages.filter { $0.id != userMessage.id && $0.id != aiMessageId }
                
                try await ollamaService.sendMessageStreaming(
                    userMessage: text,
                    conversationHistory: conversationHistory
                ) { chunk in
                    // Ollama streaming'de her chunk sadece yeni karakterleri içerir (delta)
                    // Chunk'ı buffer'a ekle
                    buffer += chunk
                    accumulatedText += chunk
                    
                    // Buffer belirli bir boyuta ulaştığında veya boşluk/noktalama varsa güncelle
                    if buffer.count >= bufferSize || chunk.contains(" ") || chunk.contains(".") || chunk.contains(",") || chunk.contains("\n") {
                        // Mesajı güncelle
                        if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                            messages[index].text = accumulatedText
                        }
                        buffer = "" // Buffer'ı temizle
                    }
                }
                
                // Son kalan buffer'ı da ekle
                if !buffer.isEmpty {
                    if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                        messages[index].text = accumulatedText
                    }
                }
                
                // AI yanıtı tamamlandı - otomatik olarak sesli oku
                if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                    let finalText = messages[index].text
                    if !finalText.isEmpty {
                        // TTS ile otomatik oku
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
                    // Hata durumunda mesajı güncelle
                    let errorMessage = String(format: "error_occurred".localized, error.localizedDescription)
                    if let index = messages.firstIndex(where: { $0.id == aiMessageId }) {
                        messages[index].text = errorMessage
                    } else {
                        // Eğer mesaj bulunamazsa yeni ekle
                        messages.append(ViewChatMessage(
                            text: errorMessage,
                            isUser: false
                        ))
                    }
                    isLoading = false
                }
            }
        }
    }
}


struct ChatBubble: View {
    let message: ViewChatMessage
    let ttsService: TTSService
    let language: AppLanguage
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            HStack(alignment: .top, spacing: AppTheme.Spacing.xs) {
                Text(message.text)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(message.isUser ? AppTheme.Colors.surface : AppTheme.Colors.textPrimary)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.searchBar)
                            .fill(message.isUser ?
                                  LinearGradient(
                                    colors: [AppTheme.Colors.primary, AppTheme.Colors.primary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  ) :
                                  LinearGradient(
                                    colors: [AppTheme.Colors.surface, AppTheme.Colors.surface],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.searchBar)
                                    .stroke(
                                        message.isUser ? Color.clear : AppTheme.Colors.tertiary.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .cardShadow()
                
                // TTS butonu - sadece AI mesajları için
                if !message.isUser && !message.text.isEmpty {
                    Button(action: {
                        Task {
                            do {
                                try await ttsService.speak(
                                    text: message.text,
                                    language: language
                                )
                            } catch {
                                print("TTS Error: \(error.localizedDescription)")
                            }
                        }
                    }) {
                        Image(systemName: ttsService.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ttsService.isSpeaking ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
                            .frame(width: 24, height: 24)
                    }
                    .padding(.top, AppTheme.Spacing.sm)
                }
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    AIChatView(isPresented: .constant(true))
        .environmentObject(LanguageManager.shared)
}

