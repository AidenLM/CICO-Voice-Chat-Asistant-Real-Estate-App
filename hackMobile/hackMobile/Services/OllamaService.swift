//
//  OllamaService.swift
//  hackMobile
//
//  Ollama AI integration service
//

import Foundation
import SwiftUI

// ViewChatMessage struct'ını burada tanımlıyoruz (AIChatView ile paylaşmak için)
struct ViewChatMessage: Identifiable {
    var id = UUID()
    var text: String
    let isUser: Bool
}

class OllamaService: ObservableObject {
    // Simulator için localhost, gerçek cihaz için Mac'inizin IP adresini kullanın
    // Simulator'da localhost çalışır, gerçek cihazda IP adresi gerekir
    #if targetEnvironment(simulator)
    private let baseURL = "http://localhost:11434"
    #else
    private let baseURL = "http://192.168.0.104:11434"  // Gerçek cihaz için Mac IP adresi
    #endif
    private let modelName = "satis-danismani"  // CICO modeli
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let stream: Bool
    }
    
    struct ChatMessage: Codable {
        let role: String // "system", "user", or "assistant"
        let content: String
    }
    
    struct ChatResponse: Codable {
        let message: ChatMessageResponse?
        let done: Bool?
    }
    
    struct ChatMessageResponse: Codable {
        let role: String
        let content: String
    }
    
    // İlk mesajı gönder - CICO'nun otomatik karşılama mesajını tetikler
    func sendInitialMessage() async throws -> String {
        // Boş bir user mesajı göndererek CICO'nun sistem prompt'undaki
        // otomatik karşılama mesajını tetikliyoruz
        let request = ChatRequest(
            model: modelName,
            messages: [
                ChatMessage(role: "user", content: "")
            ],
            stream: false
        )
        
        return try await performRequest(request: request)
    }
    
    func sendMessage(
        userMessage: String,
        conversationHistory: [ViewChatMessage]
    ) async throws -> String {
        // Ollama API formatına dönüştür
        var ollamaMessages: [ChatMessage] = []
        
        // Konuşma geçmişini ekle
        for msg in conversationHistory {
            ollamaMessages.append(ChatMessage(
                role: msg.isUser ? "user" : "assistant",
                content: msg.text
            ))
        }
        
        // Yeni kullanıcı mesajını ekle
        ollamaMessages.append(ChatMessage(role: "user", content: userMessage))
        
        // Request oluştur
        let request = ChatRequest(
            model: modelName,
            messages: ollamaMessages,
            stream: false
        )
        
        return try await performRequest(request: request)
    }
    
    // Streaming mesaj gönderme - karakter karakter yazma
    func sendMessageStreaming(
        userMessage: String,
        conversationHistory: [ViewChatMessage],
        onChunk: @escaping (String) -> Void
    ) async throws {
        // Ollama API formatına dönüştür
        var ollamaMessages: [ChatMessage] = []
        
        // Konuşma geçmişini ekle
        for msg in conversationHistory {
            ollamaMessages.append(ChatMessage(
                role: msg.isUser ? "user" : "assistant",
                content: msg.text
            ))
        }
        
        // Yeni kullanıcı mesajını ekle
        ollamaMessages.append(ChatMessage(role: "user", content: userMessage))
        
        // Request oluştur (streaming aktif)
        let request = ChatRequest(
            model: modelName,
            messages: ollamaMessages,
            stream: true
        )
        
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw OllamaError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 120 // Streaming için daha uzun timeout
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        // Streaming response al
        let (asyncBytes, response) = try await URLSession.shared.bytes(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw OllamaError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Stream'i satır satır oku
        // Ollama streaming'de her chunk sadece yeni karakterleri içerir (delta)
        for try await line in asyncBytes.lines {
            // Her satır bir JSON objesi
            // UTF-8 encoding'i garanti et
            guard let data = line.data(using: .utf8) else {
                // Encoding hatası - bu satırı atla
                continue
            }
            
            do {
                let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                
                // Eğer mesaj içeriği varsa ve boş değilse callback ile gönder
                // Ollama streaming'de her chunk sadece yeni karakterleri içerir
                if let content = chatResponse.message?.content, !content.isEmpty {
                    // Her chunk'ı direkt gönder (birleştirme işlemi callback'te yapılacak)
                    await MainActor.run {
                        onChunk(content)
                    }
                }
                
                // Eğer done ise dur
                if chatResponse.done == true {
                    break
                }
            } catch {
                // JSON parse hatası - debug için logla ama devam et
                // Bazı chunk'lar geçersiz JSON olabilir, bunları atla
                #if DEBUG
                if let error = error as? DecodingError {
                    print("⚠️ JSON Parse Error: \(error)")
                } else {
                    print("⚠️ JSON Parse Error (chunk skipped): \(line.prefix(100))")
                }
                #endif
                continue
            }
        }
    }
    
    private func performRequest(request: ChatRequest) async throws -> String {
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            throw OllamaError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60 // 60 saniye timeout
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        // Request gönder
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorData = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Ollama API Error: \(httpResponse.statusCode) - \(errorData)")
            throw OllamaError.httpError(statusCode: httpResponse.statusCode)
        }
        
        // Response'u parse et
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        
        guard let message = chatResponse.message else {
            throw OllamaError.noMessageInResponse
        }
        
        return message.content
    }
    
    enum OllamaError: LocalizedError {
        case invalidURL
        case invalidResponse
        case httpError(statusCode: Int)
        case noMessageInResponse
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Geçersiz URL"
            case .invalidResponse:
                return "Geçersiz yanıt"
            case .httpError(let statusCode):
                return "HTTP hatası: \(statusCode)"
            case .noMessageInResponse:
                return "Yanıtta mesaj bulunamadı"
            }
        }
    }
}

