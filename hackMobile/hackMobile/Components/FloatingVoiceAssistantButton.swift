//
//  FloatingVoiceAssistantButton.swift
//  hackMobile
//
//  Voice Assistant button - Sol tarafta mikrofon butonu
//

import SwiftUI

struct FloatingVoiceAssistantButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.accent.opacity(0.3),
                                AppTheme.Colors.accent.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .blur(radius: 8)
                
                // Glassmorphism background
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.5),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .overlay(
                        // Soft inner glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        .white.opacity(0.3),
                                        .clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 10,
                                    endRadius: 30
                                )
                            )
                    )
                
                // Microphone Icon
                Image(systemName: "mic.fill")
                    .font(.system(size: 24, weight: .medium))
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
        .floatingShadow()
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background
            .ignoresSafeArea()
        FloatingVoiceAssistantButton {
            print("Voice Assistant tapped")
        }
    }
}








