//
//  PropertyLoader.swift
//  hackMobile
//
//  Loads properties from evler folder and matches them with images
//

import Foundation
import SwiftUI

class PropertyLoader {
    static let shared = PropertyLoader()
    
    private let evlerPath: String
    
    init() {
        // Evler klasörünün yolunu bul - önce absolute path dene (development için)
        let homePath = NSHomeDirectory()
        let absolutePath = "/Users/mac/Desktop/hackathonMobile/hackMobile/hackMobile/evler"
        
        // Önce absolute path'i kontrol et (development için)
        if FileManager.default.fileExists(atPath: absolutePath) {
            self.evlerPath = absolutePath
            print("✅ PropertyLoader: Evler klasörü bulundu (absolute path): \(absolutePath)")
            return
        }
        
        // Sonra Bundle içinde ara
        if let bundlePath = Bundle.main.resourcePath {
            let bundleEvlerPath = bundlePath + "/evler"
            if FileManager.default.fileExists(atPath: bundleEvlerPath) {
                self.evlerPath = bundleEvlerPath
                print("✅ PropertyLoader: Evler klasörü bulundu (bundle resource): \(bundleEvlerPath)")
                return
            }
        }
        
        // Bundle path'i kontrol et
        let bundlePath = Bundle.main.bundlePath
        let bundleEvlerPath = bundlePath + "/evler"
        if FileManager.default.fileExists(atPath: bundleEvlerPath) {
            self.evlerPath = bundleEvlerPath
            print("✅ PropertyLoader: Evler klasörü bulundu (bundle path): \(bundleEvlerPath)")
            return
        }
        
        // Fallback: Diğer olası path'ler
        let possiblePaths = [
            "/Users/mac/Desktop/hackathonMobile/hackMobile/evler", // Eski path (backward compatibility)
            homePath + "/Desktop/hackathonMobile/hackMobile/hackMobile/evler",
            homePath + "/Desktop/hackathonMobile/hackMobile/evler",
            homePath + "/Documents/hackathonMobile/hackMobile/evler",
            "/Users/\(ProcessInfo.processInfo.environment["USER"] ?? "mac")/Desktop/hackathonMobile/hackMobile/hackMobile/evler",
            "/Users/\(ProcessInfo.processInfo.environment["USER"] ?? "mac")/Desktop/hackathonMobile/hackMobile/evler"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                self.evlerPath = path
                print("✅ PropertyLoader: Evler klasörü bulundu (fallback): \(path)")
                return
            }
        }
        
        // Son çare: boş string
        self.evlerPath = ""
        print("⚠️ PropertyLoader: Evler klasörü bulunamadı!")
        print("   Kontrol edilen path'ler:")
        print("   - \(absolutePath)")
        print("   - Bundle resource: \(Bundle.main.resourcePath ?? "nil")/evler")
        print("   - Bundle path: \(bundlePath)/evler")
        for path in possiblePaths {
            print("   - \(path)")
        }
    }
    
    // Evler klasöründeki dosyaları oku ve property'lere match et
    func loadProperties() -> [Property] {
        var properties: [Property] = []
        
        // Debug: Evler path'ini kontrol et
        print("🔍 PropertyLoader: Evler path = \(evlerPath)")
        print("🔍 PropertyLoader: Path exists = \(FileManager.default.fileExists(atPath: evlerPath))")
        
        // Eğer evler klasörü bulunamazsa sample data döndür
        guard !evlerPath.isEmpty, FileManager.default.fileExists(atPath: evlerPath) else {
            print("⚠️ PropertyLoader: Evler klasörü bulunamadı, sample data kullanılıyor")
            return Property.sampleProperties
        }
        
        // Proje klasörlerini tanımla
        // Format: (folderName, location, [(title, sqft, minPrice, maxPrice, bedrooms, bathrooms, status)])
        let projectFolders: [(String, String, [(String, Int, Int, Int, Int, Int, PropertyStatus)])] = [
            ("Aloha Beach Resort", "Aloha", [
                ("1+1 Garden", 43, 211_025, 259_355, 1, 1, .available),
                ("1+1 Penthouse", 78, 222_725, 310_995, 1, 1, .available),
                ("2+1 Garden", 86, 420_050, 513_525, 2, 1, .available),
                ("2+1 Penthouse", 156, 443_450, 560_075, 2, 1, .available),
                ("5+1 Villa", 365, 1_950_000, 2_500_000, 5, 1, .available)
            ]),
            ("Edremmit Villas", "Edremit", [
                ("Villa 1A", 250, 0, 0, 4, 3, .sold),
                ("Villa 1", 250, 1_650_000, 1_650_000, 4, 3, .available),
                ("Villa 2", 285, 1_450_000, 1_450_000, 4, 3, .available),
                ("Villa 3", 237, 1_650_000, 1_650_000, 4, 3, .available),
                ("Villa 4", 237, 1_650_000, 1_650_000, 4, 3, .available),
                ("Villa 5", 250, 1_750_000, 1_750_000, 4, 3, .available),
                ("Villa 6", 250, 0, 0, 4, 3, .sold),
                ("Villa 7", 250, 0, 0, 4, 3, .sold),
                ("Villa 8", 237, 1_950_000, 1_950_000, 4, 3, .available),
                ("Villa 9", 250, 2_150_000, 2_150_000, 4, 3, .available),
                ("Villa 10", 250, 2_250_000, 2_250_000, 4, 3, .available),
                ("Villa 11", 209, 2_250_000, 2_250_000, 4, 3, .available),
                ("Villa 12", 209, 2_350_000, 2_350_000, 4, 3, .available),
                ("Villa 13", 250, 2_500_000, 2_500_000, 4, 3, .available),
                ("Villa 14", 237, 2_750_000, 2_750_000, 4, 3, .available)
            ]),
            ("Pearl Island Homes", "Pearl Island", [
                ("Studio Garden", 43, 194_995, 194_995, 0, 1, .available)
            ]),
            ("Phuket Health and Wellness resort", "Phuket", [
                ("3+1 Villa", 200, 1_072_500, 1_300_000, 3, 1, .available),
                ("6+1 Villa", 300, 1_402_500, 1_512_500, 6, 1, .available),
                ("2+1 Garden", 100, 600_000, 625_000, 2, 1, .available),
                ("2+1 Penthouse", 125, 725_000, 750_000, 2, 1, .available),
                ("Large Garden", 250, 925_000, 950_000, 3, 1, .available),
                ("Private Villa Type C", 325, 2_250_000, 2_500_000, 4, 1, .available)
            ])
        ]
        
        for (folderName, location, units) in projectFolders {
            let folderPath = evlerPath + "/" + folderName
            
            // Klasördeki tüm görsel dosyalarını bul
            let imageFiles = getImageFiles(from: folderPath)
            
            // Logo dosyasını bul
            let logoPath = findLogoFile(in: folderPath)
            
            // Her unit için property oluştur
            for (index, unit) in units.enumerated() {
                let (title, sqft, minPrice, maxPrice, bedrooms, bathrooms, status) = unit
                
                // Bu unit için görselleri seç (eğer varsa)
                // Her unit için farklı görseller kullanmak için index'i geç
                let unitImages = selectImagesForUnit(
                    title: title,
                    allImages: imageFiles,
                    folderName: folderName,
                    unitIndex: index,
                    totalUnits: units.count
                )
                
                // Ortalama fiyat hesapla (fiyat aralığı varsa)
                let averagePrice = status == .sold ? 0 : (minPrice == maxPrice ? minPrice : (minPrice + maxPrice) / 2)
                
                // Lazy loading için: Tüm görsel path'lerini tut ama yükleme
                // Sadece path'leri tutuyoruz, görseller lazy yüklenecek
                let firstImage = unitImages.first ?? ""
                
                let property = Property(
                    title: title,
                    price: averagePrice,
                    minPrice: status == .sold ? nil : minPrice,
                    maxPrice: status == .sold ? nil : maxPrice,
                    status: status,
                    location: location,
                    bedrooms: bedrooms,
                    bathrooms: bathrooms,
                    squareFeet: sqft,
                    imageURL: firstImage,
                    images: unitImages, // Tüm görsel path'lerini tut (lazy yüklenecek)
                    logoURL: logoPath,
                    amenities: getAmenitiesForProject(folderName),
                    description: getDescriptionForProject(folderName, unit: title),
                    isFavorite: false,
                    projectFolderName: folderName
                )
                
                properties.append(property)
            }
        }
        
        return properties
    }
    
    // Klasördeki görsel dosyalarını bul (Logo klasörünü hariç tut)
    private func getImageFiles(from folderPath: String) -> [String] {
        var images: [String] = []
        
        guard let fileManager = FileManager.default.enumerator(atPath: folderPath) else {
            return images
        }
        
        for case let file as String in fileManager {
            // Logo klasörünü atla
            if file.lowercased().contains("logo") {
                continue
            }
            
            let filePath = folderPath + "/" + file
            let lowercased = file.lowercased()
            
            // Görsel dosya uzantılarını kontrol et (WebP iOS 14+ destekleniyor)
            if lowercased.hasSuffix(".jpg") ||
               lowercased.hasSuffix(".jpeg") ||
               lowercased.hasSuffix(".png") ||
               lowercased.hasSuffix(".heic") ||
               lowercased.hasSuffix(".webp") {
                images.append(filePath)
            }
        }
        
        return images.sorted()
    }
    
    // Logo klasöründeki logo dosyasını bul
    private func findLogoFile(in folderPath: String) -> String? {
        let logoFolderPath = folderPath + "/Logo"
        
        guard FileManager.default.fileExists(atPath: logoFolderPath),
              let logoFiles = try? FileManager.default.contentsOfDirectory(atPath: logoFolderPath) else {
            return nil
        }
        
        // Logo klasöründeki ilk görsel dosyasını bul
        for file in logoFiles {
            let filePath = logoFolderPath + "/" + file
            let lowercased = file.lowercased()
            
            if lowercased.hasSuffix(".jpg") ||
               lowercased.hasSuffix(".jpeg") ||
               lowercased.hasSuffix(".png") ||
               lowercased.hasSuffix(".heic") ||
               lowercased.hasSuffix(".webp") {
                return filePath
            }
        }
        
        return nil
    }
    
    // Unit için uygun görselleri seç - Her unit için farklı görseller kullanır
    private func selectImagesForUnit(
        title: String,
        allImages: [String],
        folderName: String,
        unitIndex: Int,
        totalUnits: Int
    ) -> [String] {
        // Eğer görsel yoksa boş döndür
        if allImages.isEmpty {
            return []
        }
        
        // Title'a göre görselleri filtrele
        let titleLower = title.lowercased()
        var matchedImages: [String] = []
        
        for imagePath in allImages {
            let imageName = (imagePath as NSString).lastPathComponent.lowercased()
            
            // Title'daki anahtar kelimeleri kontrol et
            let hasVilla = titleLower.contains("villa") && imageName.contains("villa")
            let has1Plus1 = titleLower.contains("1+1") && imageName.contains("1+1")
            let has2Plus1 = titleLower.contains("2+1") && imageName.contains("2+1")
            let has3Plus1 = titleLower.contains("3+1") && imageName.contains("3+1")
            let hasGarden = titleLower.contains("garden") && imageName.contains("garden")
            let hasPenthouse = titleLower.contains("penthouse") && imageName.contains("penthouse")
            let hasStudio = titleLower.contains("studio") && imageName.contains("studio")
            
            if hasVilla || has1Plus1 || has2Plus1 || has3Plus1 || hasGarden || hasPenthouse || hasStudio {
                matchedImages.append(imagePath)
            }
        }
        
        // Eşleşen görselleri kullan, yoksa tüm görselleri kullan
        let imagesToDistribute = matchedImages.isEmpty ? allImages : matchedImages
        
        // Her unit için farklı görseller seç - görselleri unit'lere eşit dağıt
        let totalImages = imagesToDistribute.count
        let imagesPerUnit = max(1, totalImages / max(1, totalUnits))
        
        // Bu unit için başlangıç ve bitiş index'lerini hesapla
        let startIndex = unitIndex * imagesPerUnit
        let endIndex = min(startIndex + imagesPerUnit, totalImages)
        
        // Görselleri seç
        if startIndex < totalImages {
            let selected = Array(imagesToDistribute[startIndex..<endIndex])
            // En az 1 görsel döndür
            return selected.isEmpty ? [imagesToDistribute[unitIndex % totalImages]] : selected
        } else {
            // Index aşıldıysa modüler olarak seç
            return [imagesToDistribute[unitIndex % totalImages]]
        }
    }
    
    // Proje için amenities
    private func getAmenitiesForProject(_ projectName: String) -> [String] {
        switch projectName {
        case "Aloha Beach Resort":
            return ["Beach Access", "Pool", "Restaurant", "AC", "Furnished"]
        case "Edremmit Villas":
            return ["Interior", "Terrace", "Dec. Pool", "Main Pool", "AC"]
        case "Pearl Island Homes":
            return ["Garden", "AC", "White Goods", "Fully Furnished"]
        case "Phuket Health and Wellness resort":
            return ["Wellness Center", "Pool", "Garden", "AC", "Parking"]
        default:
            return ["AC", "Parking"]
        }
    }
    
    // Proje için açıklama
    private func getDescriptionForProject(_ projectName: String, unit: String) -> String {
        switch projectName {
        case "Aloha Beach Resort":
            return "Luxury beachfront resort with stunning sea views. \(unit) unit featuring modern design and premium finishes."
        case "Edremmit Villas":
            return "Premium villa development with interior, terrace, decorative pool, and main pool. \(unit) offers spacious living with high-end specifications."
        case "Pearl Island Homes":
            return "Modern studio garden unit (35 + 8 = 43 m²) in prime location. Fully furnished with white goods and AC included."
        case "Phuket Health and Wellness resort":
            return "Wellness-focused resort development. \(unit) combines luxury living with health and wellness amenities."
        default:
            return "Beautiful property in a prime location."
        }
    }
}

// Bundle extension for accessing files outside bundle
extension Bundle {
    var evlerPath: String? {
        // Proje root'unu bul
        if let resourcePath = self.resourcePath {
            let components = resourcePath.components(separatedBy: "/")
            if let hackMobileIndex = components.firstIndex(of: "hackMobile") {
                let projectRoot = components[..<hackMobileIndex].joined(separator: "/")
                return projectRoot + "/evler"
            }
        }
        return nil
    }
}

