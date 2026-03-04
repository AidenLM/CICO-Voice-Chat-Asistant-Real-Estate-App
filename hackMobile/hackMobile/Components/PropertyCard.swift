//
//  PropertyCard.swift
//  hackMobile
//
//  Premium property card with soft shadows and elegant design
//

import SwiftUI

struct PropertyCard: View {
    @EnvironmentObject var languageManager: LanguageManager
    let property: Property
    let onTap: () -> Void
    let onFavoriteToggle: () -> Void
    
    // Ekran boyutuna göre dinamik görsel yüksekliği hesaplama
    private var imageHeight: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        // Padding'leri çıkar (her iki tarafta md spacing)
        let availableWidth = screenWidth - (AppTheme.Spacing.md * 2)
        // Ekran genişliğine göre dinamik yükseklik: genişliğin %55-60'ı
        let baseHeight = availableWidth * 0.58
        let minHeight: CGFloat = 200
        let maxHeight: CGFloat = 380
        
        // Ekran boyutuna göre sınırlandır
        var calculatedHeight = max(minHeight, min(maxHeight, baseHeight))
        
        // Küçük ekranlar için ekstra optimizasyon
        if screenWidth < 375 { // iPhone SE, iPhone 8 gibi
            calculatedHeight = calculatedHeight * 0.88
        } else if screenWidth < 414 { // iPhone 11, iPhone 12 gibi
            calculatedHeight = calculatedHeight * 0.95
        }
        
        return calculatedHeight
    }
    
    var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Image Section - Full width with dynamic height
                ZStack(alignment: .topTrailing) {
                    // Property Image - Async optimized loading with screen-adaptive height
                    AsyncImageLoader(
                        imagePath: property.imageURL,
                        placeholder: "photo",
                        height: imageHeight
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: imageHeight)
                    .clipped()
                    .clipShape(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    )
                    .overlay(
                        // SOLD overlay
                        Group {
                            if property.status == .sold {
                                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                    .fill(Color.black.opacity(0.4))
                                    .overlay(
                                        VStack(spacing: AppTheme.Spacing.xs) {
                                            Text("sold".localized)
                                                .font(AppTheme.Typography.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, AppTheme.Spacing.lg)
                                                .padding(.vertical, AppTheme.Spacing.sm)
                                                .background(
                                                    Capsule()
                                                        .fill(Color.red)
                                                )
                                        }
                                    )
                            }
                        }
                    )
                    
                    // Favorite Button - Sağ üst
                    Button(action: onFavoriteToggle) {
                        Image(systemName: property.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(property.isFavorite ? .red : .white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        Circle()
                                            .stroke(.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(AppTheme.Spacing.md)
                }
            
            // Content Section
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                // Price - Bold with status badge
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                    Text(property.formattedPrice)
                        .font(AppTheme.Typography.title3)
                        .fontWeight(.bold)
                        .foregroundColor(property.status == .sold ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                    
                    // Status badge
                    if property.status == .sold {
                        Text("sold".localized)
                            .font(AppTheme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.red)
                            )
                    } else if property.hasPriceRange {
                        Text("from".localized)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                }
                
                // Location - Regular
                Text(property.location)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                
                // Property Details - Light gray
                HStack(spacing: AppTheme.Spacing.md) {
                    Label("\(property.bedrooms)", systemImage: "bed.double.fill")
                    Label("\(property.bathrooms)", systemImage: "shower.fill")
                    Label("\(property.squareFeet)", systemImage: "square.grid.2x2.fill")
                    
                    Spacer()
                }
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
                
                // Amenities - Light gray, minimal
                if !property.amenities.isEmpty {
                    HStack {
                        Text(property.amenities.prefix(2).joined(separator: " • "))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(
                // Logo - Sağ alt köşe (içerik bölümünde)
                Group {
                    if let logoPath = property.logoURL, FileManager.default.fileExists(atPath: logoPath) {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                // Logo görseli - büyütülmüş ve curve yapılmış
                                if let logoImage = UIImage(contentsOfFile: logoPath) {
                                    Image(uiImage: logoImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxWidth: 110, maxHeight: 55)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .padding(.trailing, AppTheme.Spacing.md)
                                        .padding(.bottom, AppTheme.Spacing.md)
                                }
                            }
                        }
                    }
                },
                alignment: .bottomTrailing
            )
        }
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.Radius.card)
        .cardShadow()
        .frame(maxWidth: .infinity) // Ekran genişliğini aşmaması için
        .opacity(property.status == .sold ? 0.75 : 1.0) // SOLD olanları biraz soluklaştır
    }
}

#Preview {
    PropertyCard(
        property: Property.sampleProperties[0],
        onTap: {},
        onFavoriteToggle: {}
    )
    .padding()
    .background(AppTheme.Colors.background)
    .environmentObject(LanguageManager.shared)
}

