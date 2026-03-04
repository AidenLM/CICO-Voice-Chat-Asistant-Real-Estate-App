//
//  DesignSystem.swift
//  RealEstateApp
//
//  Design system with colors, typography, and spacing
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Scandinavian minimal luxury palette
    static let appBackground = Color(hex: "FAF9F7")
    static let cardBackground = Color.white
    static let textPrimary = Color(hex: "1D1D1F")
    static let textSecondary = Color(hex: "6E6E73")
    static let textTertiary = Color(hex: "86868B")
    static let accentBeige = Color(hex: "F5F3F0")
    static let accentSand = Color(hex: "E8E6E1")
    static let accentWarmGray = Color(hex: "D2D0CC")
    static let priceAccent = Color(hex: "1D1D1F")
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

// MARK: - Typography
extension Font {
    static let headingLarge = Font.system(size: 28, weight: .semibold, design: .default)
    static let headingMedium = Font.system(size: 22, weight: .semibold, design: .default)
    static let headingSmall = Font.system(size: 18, weight: .semibold, design: .default)
    static let bodyRegular = Font.system(size: 16, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .default)
    static let caption = Font.system(size: 12, weight: .light, design: .default)
    static let price = Font.system(size: 20, weight: .bold, design: .default)
}

// MARK: - Spacing (8-point grid)
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
}

// MARK: - Corner Radius
struct CornerRadius {
    static let card: CGFloat = 18
    static let pill: CGFloat = 20
    static let button: CGFloat = 12
    static let searchBar: CGFloat = 12
}

// MARK: - Shadows
extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    
    func softShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    func glassShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 8)
    }
}

