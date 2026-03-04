//
//  LanguageManager.swift
//  hackMobile
//
//  Manages app language switching between Turkish and English
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable {
    case turkish = "tr"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .turkish:
            return "TR"
        case .english:
            return "EN"
        }
    }
}

class LanguageManager: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
            // Bundle'ı güncelle
            setLanguage(currentLanguage)
        }
    }
    
    static let shared = LanguageManager()
    
    private var currentBundle: Bundle?
    
    private init() {
        // UserDefaults'tan kaydedilmiş dili oku
        if let savedLanguage = UserDefaults.standard.string(forKey: "app_language"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Varsayılan dil: Türkçe
            self.currentLanguage = .turkish
        }
        setLanguage(currentLanguage)
    }
    
    func toggleLanguage() {
        DispatchQueue.main.async {
            self.currentLanguage = self.currentLanguage == .turkish ? .english : .turkish
        }
    }
    
    private func setLanguage(_ language: AppLanguage) {
        // Bundle'ı güncelle
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.currentBundle = bundle
            print("✅ LanguageManager: Bundle bulundu - \(language.rawValue) -> \(path)")
        } else {
            // Fallback: Manuel olarak bundle path'i oluştur
            let bundlePath = Bundle.main.bundlePath
            let lprojPath = (bundlePath as NSString).appendingPathComponent("\(language.rawValue).lproj")
            
            if FileManager.default.fileExists(atPath: lprojPath),
               let bundle = Bundle(path: lprojPath) {
                self.currentBundle = bundle
                print("✅ LanguageManager: Bundle bulundu (manuel) - \(language.rawValue) -> \(lprojPath)")
            } else {
                // Son çare: Development için absolute path
                let devPath = "/Users/mac/Desktop/hackathonMobile/hackMobile/hackMobile/\(language.rawValue).lproj"
                if FileManager.default.fileExists(atPath: devPath),
                   let bundle = Bundle(path: devPath) {
                    self.currentBundle = bundle
                    print("✅ LanguageManager: Bundle bulundu (dev path) - \(language.rawValue) -> \(devPath)")
                } else {
                    // Fallback to main bundle
                    self.currentBundle = Bundle.main
                    print("⚠️ LanguageManager: Bundle bulunamadı, main bundle kullanılıyor - \(language.rawValue)")
                }
            }
        }
    }
    
    func localizedString(_ key: String, comment: String = "") -> String {
        if let bundle = currentBundle {
            let localized = NSLocalizedString(key, bundle: bundle, comment: comment)
            // Eğer key ile aynı dönerse, bundle'da bulunamadı demektir
            if localized == key && bundle != Bundle.main {
                // Main bundle'dan dene
                return NSLocalizedString(key, comment: comment)
            }
            return localized
        }
        return NSLocalizedString(key, comment: comment)
    }
}

// Extension for easy access
extension String {
    var localized: String {
        return LanguageManager.shared.localizedString(self)
    }
}

