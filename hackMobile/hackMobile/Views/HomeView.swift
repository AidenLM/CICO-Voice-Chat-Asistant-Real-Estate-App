//
//  HomeView.swift
//  hackMobile
//
//  Premium home screen with Pinterest-style grid layout
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @State private var properties: [Property] = []
    @State private var searchText: String = ""
    @State private var selectedFilter: String? = nil
    @State private var showAIChat: Bool = false
    @State private var showVoiceAssistant: Bool = false
    @State private var isLoadingProperties: Bool = true
    
    private let filterKeys = ["filter_all", "filter_available", "filter_sold", "filter_luxury", "filter_new"]
    
    private var filters: [(key: String, title: String, icon: String?)] {
        // LanguageManager'ı observe etmek için currentLanguage'e erişiyoruz
        let _ = languageManager.currentLanguage
        return [
            (filterKeys[0], languageManager.localizedString(filterKeys[0]), nil),
            (filterKeys[1], languageManager.localizedString(filterKeys[1]), "checkmark.circle.fill"),
            (filterKeys[2], languageManager.localizedString(filterKeys[2]), "xmark.circle.fill"),
            (filterKeys[3], languageManager.localizedString(filterKeys[3]), "sparkles"),
            (filterKeys[4], languageManager.localizedString(filterKeys[4]), "star.fill")
        ]
    }
    
    var filteredProperties: [Property] {
        var filtered = properties
        
        // Search filter - Proje isimlerine göre arama
        if !searchText.isEmpty {
            let searchLower = searchText.lowercased()
            filtered = filtered.filter { property in
                // Title'a göre arama
                if property.title.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                // Location'a göre arama (proje isimleri burada)
                if property.location.localizedCaseInsensitiveContains(searchText) {
                    return true
                }
                
                // Proje klasör ismine göre arama
                if let projectName = property.projectFolderName {
                    // Proje isimlerini normalize et ve karşılaştır
                    let projectLower = projectName.lowercased()
                    
                    // Aloha Beach Resort -> "aloha" ile eşleşsin
                    if projectLower.contains(searchLower) || searchLower.contains(projectLower) {
                        return true
                    }
                    
                    // Özel eşleştirmeler
                    if (searchLower == "aloha" && projectLower.contains("aloha")) ||
                       (searchLower == "edremit" && projectLower.contains("edremit")) ||
                       (searchLower == "pearl" && projectLower.contains("pearl")) ||
                       (searchLower == "phuket" && projectLower.contains("phuket")) {
                        return true
                    }
                }
                
                // Amenities'e göre arama
                for amenity in property.amenities {
                    if amenity.localizedCaseInsensitiveContains(searchText) {
                        return true
                    }
                }
                
                return false
            }
        }
        
        // Status filter - Use filter key to match
        if let filter = selectedFilter {
            if filter == filterKeys[1] { // Available
                filtered = filtered.filter { $0.status == .available }
            } else if filter == filterKeys[2] { // Sold
                filtered = filtered.filter { $0.status == .sold }
            } else if filter == filterKeys[3] { // Luxury
                // Fiyatı 1M'den fazla olanları luxury olarak göster
                filtered = filtered.filter { ($0.minPrice ?? $0.price) >= 1_000_000 }
            } else if filter == filterKeys[4] { // New
                // Yeni eklenenler için (şimdilik tümünü göster)
                // Hiçbir filtreleme yapma, tümünü göster
            }
        }
        
        return filtered
    }
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header with Search
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Title with Logo
                        HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text(languageManager.localizedString("discover"))
                                    .font(AppTheme.Typography.largeTitle)
                                    .foregroundColor(AppTheme.Colors.textPrimary)
                                Text(languageManager.localizedString("your_perfect_home"))
                                    .font(AppTheme.Typography.subheadline)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            // Cyprus Constructions Logo
                            if let logoImage = loadCyprusLogo() {
                                Image(uiImage: logoImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.top, AppTheme.Spacing.md)
                        
                        // Search Bar with Language Toggle
                        HStack(spacing: AppTheme.Spacing.sm) {
                            SearchBar(searchText: $searchText, placeholder: languageManager.localizedString("search_by_project"))
                            
                            // Language Toggle Button
                            Button(action: {
                                withAnimation {
                                    languageManager.toggleLanguage()
                                }
                            }) {
                                Text(languageManager.currentLanguage.displayName)
                                    .font(AppTheme.Typography.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(AppTheme.Colors.primary)
                                    .frame(width: 50, height: 44)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.Radius.searchBar)
                                            .fill(AppTheme.Colors.surface)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: AppTheme.Radius.searchBar)
                                                    .stroke(AppTheme.Colors.tertiary.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        
                        // Filter Pills
                        FilterPills(
                            selectedFilter: $selectedFilter,
                            filters: filters
                        )
                        .padding(.vertical, AppTheme.Spacing.sm)
                    }
                    .padding(.bottom, AppTheme.Spacing.md)
                    
                    // Property Grid - Pinterest style
                    if isLoadingProperties {
                        VStack(spacing: AppTheme.Spacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text(languageManager.localizedString("loading_properties"))
                                .font(AppTheme.Typography.subheadline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.xxl)
                    } else {
                        // Single column wall layout with lazy loading
                        LazyVStack(spacing: AppTheme.Spacing.lg) {
                            ForEach(Array(filteredProperties.enumerated()), id: \.element.id) { index, property in
                                NavigationLink(destination: PropertyDetailView(property: property)) {
                                    PropertyCard(
                                        property: property,
                                        onTap: {},
                                        onFavoriteToggle: {
                                            toggleFavorite(for: property)
                                        }
                                    )
                                    .onAppear {
                                        // İlk 7 property için görselleri preload et
                                        if index < 7 {
                                            preloadImageIfNeeded(for: property)
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, 100) // Space for floating button
                    }
                }
            }
            
            // Floating Buttons
            VStack {
                Spacer()
                HStack {
                    // Sol taraf - Voice Assistant Button
                    FloatingVoiceAssistantButton {
                        showVoiceAssistant = true
                    }
                    .padding(.leading, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xl)
                    
                    Spacer()
                    
                    // Sağ taraf - AI Chat Button
                    FloatingAIAssistantButton {
                        showAIChat = true
                    }
                    .padding(.trailing, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.xl)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAIChat) {
            AIChatView(isPresented: $showAIChat)
        }
        .sheet(isPresented: $showVoiceAssistant) {
            VoiceAssistantView(isPresented: $showVoiceAssistant)
        }
        .onAppear {
            loadProperties()
        }
    }
    
    private func loadProperties() {
        isLoadingProperties = true
        // PropertyLoader ile gerçek property'leri yükle
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedProperties = PropertyLoader.shared.loadProperties()
            DispatchQueue.main.async {
                self.properties = loadedProperties
                self.isLoadingProperties = false
            }
        }
    }
    
    private func toggleFavorite(for property: Property) {
        if let index = properties.firstIndex(where: { $0.id == property.id }) {
            let currentProperty = properties[index]
            let updatedProperty = Property(
                id: currentProperty.id,
                title: currentProperty.title,
                price: currentProperty.price,
                minPrice: currentProperty.minPrice,
                maxPrice: currentProperty.maxPrice,
                status: currentProperty.status,
                location: currentProperty.location,
                bedrooms: currentProperty.bedrooms,
                bathrooms: currentProperty.bathrooms,
                squareFeet: currentProperty.squareFeet,
                imageURL: currentProperty.imageURL,
                images: currentProperty.images,
                logoURL: currentProperty.logoURL,
                amenities: currentProperty.amenities,
                description: currentProperty.description,
                isFavorite: !currentProperty.isFavorite,
                projectFolderName: currentProperty.projectFolderName
            )
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                properties[index] = updatedProperty
            }
        }
    }
    
    // İlk 7 property için görselleri preload et (küçültülmüş versiyon)
    private func preloadImageIfNeeded(for property: Property) {
        guard !property.imageURL.isEmpty else { return }
        
        // Background thread'de preload
        DispatchQueue.global(qos: .utility).async {
            // Cache'de yoksa yükle
            if ImageCache.shared.get(key: property.imageURL) == nil {
                if FileManager.default.fileExists(atPath: property.imageURL) {
                    var image: UIImage?
                    
                    // WebP desteği
                    if property.imageURL.lowercased().hasSuffix(".webp") {
                        if #available(iOS 14.0, *) {
                            image = UIImage(contentsOfFile: property.imageURL)
                        }
                    } else {
                        image = UIImage(contentsOfFile: property.imageURL)
                    }
                    
                    if let originalImage = image {
                        // RAM optimizasyonu: Görseli küçült (max 800px)
                        let resizedImage = resizeImage(originalImage, maxDimension: 800)
                        ImageCache.shared.set(image: resizedImage, key: property.imageURL)
                    }
                }
            }
        }
    }
    
    // Görseli küçültmek için helper fonksiyon
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
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
    
    // Cyprus Constructions logo yükleme
    private func loadCyprusLogo() -> UIImage? {
        // Yeni path'i dene
        let logoPath = "/Users/mac/Desktop/hackathonMobile/hackMobile/hackMobile/evler/cyprusConstructions/3d-Logo-800-V2-768x211.png"
        
        // Önce absolute path'i dene (yeni path)
        if FileManager.default.fileExists(atPath: logoPath) {
            return UIImage(contentsOfFile: logoPath)
        }
        
        // Eski path'i dene (backward compatibility)
        let oldLogoPath = "/Users/mac/Desktop/hackathonMobile/hackMobile/evler/cyprusConstructions/3d-Logo-800-V2-768x211.png"
        if FileManager.default.fileExists(atPath: oldLogoPath) {
            return UIImage(contentsOfFile: oldLogoPath)
        }
        
        // Bundle içinde ara
        if let bundlePath = Bundle.main.resourcePath {
            let bundleLogoPath = bundlePath + "/evler/cyprusConstructions/3d-Logo-800-V2-768x211.png"
            if FileManager.default.fileExists(atPath: bundleLogoPath) {
                return UIImage(contentsOfFile: bundleLogoPath)
            }
        }
        
        return nil
    }
}

#Preview {
    NavigationView {
        HomeView()
            .environmentObject(LanguageManager.shared)
    }
}

