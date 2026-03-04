//
//  AppTheme.swift
//  hackMobile
//
//  Premium Scandinavian minimal luxury design system
//

import SwiftUI

struct AppTheme {
    // Color Palette - Scandinavian Minimal Luxury
    struct Colors {
        static let background = Color(hex: "FAF9F6") // Warm white/beige
        static let surface = Color.white
        static let primary = Color(hex: "2C2C2C") // Warm dark gray
        static let secondary = Color(hex: "8B8B8B") // Medium gray
        static let tertiary = Color(hex: "C4C4C4") // Light gray
        static let accent = Color(hex: "D4AF8C") // Warm sand/beige accent
        static let textPrimary = Color(hex: "1A1A1A")
        static let textSecondary = Color(hex: "6B6B6B")
        static let textTertiary = Color(hex: "9B9B9B")
    }
    
    // Spacing - 8-point grid system
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .semibold, design: .default)
        static let title1 = Font.system(size: 28, weight: .semibold, design: .default)
        static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .light, design: .default)
    }
    
    // Shadows - Soft and subtle
    struct Shadows {
        static let card = Shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        static let cardHover = Shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        static let floating = Shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
    
    // Corner Radius
    struct Radius {
        static let card: CGFloat = 18
        static let pill: CGFloat = 20
        static let button: CGFloat = 12
        static let searchBar: CGFloat = 14
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func cardShadow() -> some View {
        self.shadow(color: AppTheme.Shadows.card.color, radius: AppTheme.Shadows.card.radius, x: AppTheme.Shadows.card.x, y: AppTheme.Shadows.card.y)
    }
    
    func floatingShadow() -> some View {
        self.shadow(color: AppTheme.Shadows.floating.color, radius: AppTheme.Shadows.floating.radius, x: AppTheme.Shadows.floating.x, y: AppTheme.Shadows.floating.y)
    }
}

