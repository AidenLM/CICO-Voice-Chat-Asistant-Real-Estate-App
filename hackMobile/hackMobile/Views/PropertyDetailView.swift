//
//  PropertyDetailView.swift
//  hackMobile
//
//  Property detail screen with large gallery and CTA buttons
//

import SwiftUI

struct PropertyDetailView: View {
    @EnvironmentObject var languageManager: LanguageManager
    let property: Property
    @State private var selectedImageIndex: Int = 0
    @State private var isFavorite: Bool
    @Environment(\.dismiss) var dismiss
    
    init(property: Property) {
        self.property = property
        _isFavorite = State(initialValue: property.isFavorite)
    }
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    imageGalleryView
                    contentView
                }
            }
            
            ctaButtonsView
        }
        .navigationBarHidden(true)
    }
    
    // Image Gallery - Ayrı computed property
    private var imageGalleryView: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(Array(property.images.enumerated()), id: \.offset) { index, imagePath in
                imageView(for: imagePath)
                    .tag(index)
            }
        }
        .tabViewStyle(.page)
        .frame(height: 400)
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .overlay(galleryOverlayButtons)
    }
    
    // Gallery overlay buttons
    private var galleryOverlayButtons: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.ultraThinMaterial)
                        .background(Circle().fill(.white.opacity(0.3)))
                }
                Spacer()
                Button(action: { isFavorite.toggle() }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isFavorite ? .red : .white)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.md)
            Spacer()
        }
    }
    
    // Single image view helper
    private func imageView(for imagePath: String) -> some View {
        ZStack {
            if FileManager.default.fileExists(atPath: imagePath),
               let uiImage = loadImage(from: imagePath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 400)
                    .clipped()
            } else if FileManager.default.fileExists(atPath: imagePath) {
                placeholderView
            } else {
                errorPlaceholderView
            }
        }
    }
    
    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(AppTheme.Colors.tertiary.opacity(0.3))
            .frame(height: 400)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            )
    }
    
    private var errorPlaceholderView: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.tertiary.opacity(0.3),
                        AppTheme.Colors.tertiary.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(height: 400)
            .overlay(
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "photo")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Text("image_not_found".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            )
    }
    
    // Content Section - Ayrı computed property
    private var contentView: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            headerSection
            propertyDetailsSection
            amenitiesSection
            descriptionSection
            Spacer()
                .frame(height: 100)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.md) {
                Text(property.formattedPrice)
                    .font(AppTheme.Typography.title1)
                    .fontWeight(.bold)
                    .foregroundColor(property.status == .sold ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                
                if property.status == .sold {
                    Text("sold".localized)
                        .font(AppTheme.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.red))
                } else if property.hasPriceRange {
                    Text("price_range".localized)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppTheme.Colors.tertiary.opacity(0.2)))
                }
            }
            
            Text(property.location)
                .font(AppTheme.Typography.headline)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text(property.title)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.lg)
    }
    
    private var propertyDetailsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.xl) {
                DetailItem(icon: "bed.double.fill", value: "\(property.bedrooms)", label: "bedrooms".localized)
                DetailItem(icon: "shower.fill", value: "\(property.bathrooms)", label: "bathrooms".localized)
                DetailItem(icon: "square.grid.2x2.fill", value: "\(property.squareFeet)", label: "sq_ft".localized)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            
            Divider()
                .padding(.horizontal, AppTheme.Spacing.md)
        }
    }
    
    @ViewBuilder
    private var amenitiesSection: some View {
        if !property.amenities.isEmpty {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text("amenities".localized)
                    .font(AppTheme.Typography.title3)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: AppTheme.Spacing.sm
                ) {
                    ForEach(property.amenities, id: \.self) { amenity in
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.accent)
                            Text(amenity)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            
            Divider()
                .padding(.horizontal, AppTheme.Spacing.md)
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("about_this_property".localized)
                .font(AppTheme.Typography.title3)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text(property.description.isEmpty ? "Beautiful property in a prime location. Contact us for more details." : property.description)
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineSpacing(4)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
    }
    
    // CTA Buttons - Ayrı computed property
    private var ctaButtonsView: some View {
        VStack {
            Spacer()
            VStack(spacing: AppTheme.Spacing.sm) {
                primaryCTAButton
                secondaryCTAButton
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.md)
            .background(
                LinearGradient(
                    colors: [
                        AppTheme.Colors.background.opacity(0.95),
                        AppTheme.Colors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private var primaryCTAButton: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: "phone.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("contact_agent".localized)
                    .font(AppTheme.Typography.headline)
            }
            .foregroundColor(AppTheme.Colors.surface)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.primary,
                                AppTheme.Colors.primary.opacity(0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .cardShadow()
    }
    
    private var secondaryCTAButton: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .medium))
                Text("schedule_tour".localized)
                    .font(AppTheme.Typography.headline)
            }
            .foregroundColor(AppTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                    .fill(AppTheme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                            .stroke(AppTheme.Colors.tertiary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .cardShadow()
    }
    
    // Helper function to load image from path - Detay sayfası için tam çözünürlük
    private func loadImage(from imagePath: String) -> UIImage? {
        var image: UIImage?
        
        // WebP desteği iOS 14+ için native
        if imagePath.lowercased().hasSuffix(".webp") {
            if #available(iOS 14.0, *) {
                image = UIImage(contentsOfFile: imagePath)
            } else {
                return nil
            }
        } else {
            // Diğer formatlar için normal yükleme
            image = UIImage(contentsOfFile: imagePath)
        }
        
        // Detay sayfası için görseli biraz küçült (ama karttan daha büyük tut)
        if let originalImage = image {
            return resizeImageForDetail(originalImage, maxDimension: 1200)
        }
        
        return nil
    }
    
    // Detay sayfası için görsel resize (daha büyük ama yine de optimize)
    private func resizeImageForDetail(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // Eğer görsel zaten küçükse, resize etme
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }
        
        // Aspect ratio'yu koruyarak resize et
        let ratio = size.width / size.height
        var newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }
        
        // Resize işlemi
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
}

struct DetailItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppTheme.Colors.accent)
            Text(value)
                .font(AppTheme.Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationView {
        PropertyDetailView(property: Property.sampleProperties[0])
            .environmentObject(LanguageManager.shared)
    }
}

