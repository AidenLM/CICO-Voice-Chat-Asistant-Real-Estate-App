//
//  AsyncImageLoader.swift
//  hackMobile
//
//  Optimized async image loader with caching
//

import SwiftUI

struct AsyncImageLoader: View {
    let imagePath: String
    let placeholder: String
    let height: CGFloat
    let shouldResize: Bool // Görseli küçültmek için
    
    @State private var loadedImage: UIImage?
    @State private var isLoading: Bool = true
    
    init(imagePath: String, placeholder: String = "photo", height: CGFloat = 240, shouldResize: Bool = true) {
        self.imagePath = imagePath
        self.placeholder = placeholder
        self.height = height
        self.shouldResize = shouldResize
    }
    
    var body: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: height)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else if isLoading {
                // Loading placeholder
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.Colors.tertiary.opacity(0.2),
                                AppTheme.Colors.tertiary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.textTertiary))
                    )
            } else {
                // Error/not found placeholder
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
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
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .overlay(
                        Image(systemName: placeholder)
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard !imagePath.isEmpty else {
            isLoading = false
            return
        }
        
        // Background thread'de yükle
        DispatchQueue.global(qos: .userInitiated).async {
            // Önce cache'den kontrol et
            if let cachedImage = ImageCache.shared.get(key: imagePath) {
                DispatchQueue.main.async {
                    self.loadedImage = cachedImage
                    self.isLoading = false
                }
                return
            }
            
            // Dosyadan yükle
            if FileManager.default.fileExists(atPath: imagePath) {
                var image: UIImage?
                
                // WebP desteği iOS 14+ için native
                if imagePath.lowercased().hasSuffix(".webp") {
                    // iOS 14+ için UIImage native webp desteği var
                    if #available(iOS 14.0, *) {
                        image = UIImage(contentsOfFile: imagePath)
                    } else {
                        // iOS 13 ve altı için fallback (webp desteklenmez)
                        image = nil
                    }
                } else {
                    // Diğer formatlar (jpg, png, heic) için normal yükleme
                    image = UIImage(contentsOfFile: imagePath)
                }
                
                if let originalImage = image {
                    // RAM optimizasyonu: Görseli küçült
                    let resizedImage = shouldResize ? resizeImage(originalImage, maxDimension: 800) : originalImage
                    
                    // Cache'e kaydet (küçültülmüş versiyonu)
                    ImageCache.shared.set(image: resizedImage, key: imagePath)
                    
                    DispatchQueue.main.async {
                        self.loadedImage = resizedImage
                        self.isLoading = false
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
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
}

// Thread-safe image cache - RAM optimizasyonu için küçültülmüş cache
class ImageCache {
    static let shared = ImageCache()
    private var cache: [String: UIImage] = [:]
    private let maxCacheSize = 30 // Max 30 image (RAM tasarrufu için azaltıldı)
    private let queue = DispatchQueue(label: "com.hackmobile.imagecache", attributes: .concurrent)
    
    private init() {}
    
    func get(key: String) -> UIImage? {
        return queue.sync {
            return cache[key]
        }
    }
    
    func set(image: UIImage, key: String) {
        queue.async(flags: .barrier) {
            // Cache size kontrolü
            if self.cache.count >= self.maxCacheSize {
                // En eski entry'yi kaldır (basit LRU)
                if let firstKey = self.cache.keys.first {
                    self.cache.removeValue(forKey: firstKey)
                }
            }
            self.cache[key] = image
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}

