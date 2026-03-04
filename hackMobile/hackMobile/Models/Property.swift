//
//  Property.swift
//  hackMobile
//
//  Created for premium real estate app
//

import Foundation
import SwiftUI

enum PropertyStatus: String, Codable {
    case available = "Available"
    case sold = "SOLD"
}

struct Property: Identifiable, Hashable {
    let id: UUID
    let title: String
    let price: Int // Ortalama fiyat (backward compatibility için)
    let minPrice: Int? // Minimum fiyat (opsiyonel)
    let maxPrice: Int? // Maksimum fiyat (opsiyonel)
    let status: PropertyStatus // Available veya SOLD
    let location: String
    let bedrooms: Int
    let bathrooms: Int
    let squareFeet: Int
    let imageURL: String
    let images: [String] // Dosya yolları
    let logoURL: String? // Proje logosu (opsiyonel)
    let amenities: [String]
    let description: String
    let isFavorite: Bool
    let projectFolderName: String? // Hangi proje klasöründen geldiği
    
    init(
        id: UUID = UUID(),
        title: String,
        price: Int,
        minPrice: Int? = nil,
        maxPrice: Int? = nil,
        status: PropertyStatus = .available,
        location: String,
        bedrooms: Int,
        bathrooms: Int,
        squareFeet: Int,
        imageURL: String,
        images: [String] = [],
        logoURL: String? = nil,
        amenities: [String] = [],
        description: String = "",
        isFavorite: Bool = false,
        projectFolderName: String? = nil
    ) {
        self.id = id
        self.title = title
        self.price = price
        self.minPrice = minPrice
        self.maxPrice = maxPrice
        self.status = status
        self.location = location
        self.bedrooms = bedrooms
        self.bathrooms = bathrooms
        self.squareFeet = squareFeet
        self.imageURL = imageURL
        self.images = images.isEmpty ? [imageURL] : images
        self.logoURL = logoURL
        self.amenities = amenities
        self.description = description
        self.isFavorite = isFavorite
        self.projectFolderName = projectFolderName
    }
    
    var formattedPrice: String {
        // Eğer SOLD ise durumu göster
        if status == .sold {
            return "SOLD"
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_GB") // £ için GBP locale
        formatter.currencyCode = "GBP"
        
        // Fiyat aralığı varsa göster
        if let min = minPrice, let max = maxPrice, min != max {
            let minFormatted = formatter.string(from: NSNumber(value: min)) ?? "£\(min)"
            let maxFormatted = formatter.string(from: NSNumber(value: max)) ?? "£\(max)"
            return "\(minFormatted)–\(maxFormatted)"
        }
        
        // Tek fiyat varsa göster
        if let min = minPrice {
            return formatter.string(from: NSNumber(value: min)) ?? "£\(min)"
        }
        
        // Fallback: price kullan
        return formatter.string(from: NSNumber(value: price)) ?? "£\(price)"
    }
    
    var hasPriceRange: Bool {
        guard let min = minPrice, let max = maxPrice else { return false }
        return min != max
    }
}

// Sample data
extension Property {
    static let sampleProperties: [Property] = [
        Property(
            title: "Modern Minimalist Villa",
            price: 1_250_000,
            minPrice: 1_200_000,
            maxPrice: 1_300_000,
            status: .available,
            location: "Malibu, CA",
            bedrooms: 4,
            bathrooms: 3,
            squareFeet: 3200,
            imageURL: "house.fill",
            images: ["house.fill", "building.2.fill", "house.lodge.fill"],
            amenities: ["Ocean View", "Pool", "Garage", "Garden"],
            description: "Stunning modern villa with panoramic ocean views. Features open-plan living, premium finishes, and seamless indoor-outdoor flow."
        ),
        Property(
            title: "Scandinavian Loft",
            price: 850_000,
            status: .available,
            location: "Brooklyn, NY",
            bedrooms: 2,
            bathrooms: 2,
            squareFeet: 1800,
            imageURL: "building.2.fill",
            images: ["building.2.fill", "house.fill"],
            amenities: ["High Ceilings", "Exposed Brick", "Rooftop Access"],
            description: "Beautifully renovated loft with Scandinavian design influences. Bright, airy spaces with premium materials throughout."
        ),
        Property(
            title: "Luxury Penthouse",
            price: 2_500_000,
            status: .sold,
            location: "Manhattan, NY",
            bedrooms: 3,
            bathrooms: 2,
            squareFeet: 2400,
            imageURL: "house.lodge.fill",
            images: ["house.lodge.fill", "building.2.fill", "house.fill"],
            amenities: ["City Views", "Concierge", "Gym", "Rooftop"],
            description: "Sophisticated penthouse with breathtaking city views. Features designer finishes, smart home technology, and exclusive amenities."
        ),
        Property(
            title: "Coastal Retreat",
            price: 950_000,
            status: .available,
            location: "Santa Barbara, CA",
            bedrooms: 3,
            bathrooms: 2,
            squareFeet: 2100,
            imageURL: "house.fill",
            images: ["house.fill"],
            amenities: ["Beach Access", "Deck", "Fireplace"],
            description: "Charming coastal home steps from the beach. Perfect blend of comfort and style with outdoor living spaces."
        ),
        Property(
            title: "Urban Studio",
            price: 425_000,
            status: .available,
            location: "Seattle, WA",
            bedrooms: 1,
            bathrooms: 1,
            squareFeet: 750,
            imageURL: "building.2.fill",
            images: ["building.2.fill"],
            amenities: ["Modern Kitchen", "City Views", "Walkable"],
            description: "Stylish urban studio in the heart of the city. Efficient design maximizes space with premium finishes."
        ),
        Property(
            title: "Mountain Lodge",
            price: 1_800_000,
            minPrice: 1_750_000,
            maxPrice: 1_850_000,
            status: .available,
            location: "Aspen, CO",
            bedrooms: 5,
            bathrooms: 4,
            squareFeet: 4500,
            imageURL: "house.lodge.fill",
            images: ["house.lodge.fill", "house.fill"],
            amenities: ["Ski Access", "Hot Tub", "Fireplace", "Garage"],
            description: "Magnificent mountain lodge with ski-in/ski-out access. Rustic luxury meets modern comfort in this stunning retreat."
        )
    ]
}

