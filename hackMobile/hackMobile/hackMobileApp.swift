//
//  hackMobileApp.swift
//  hackMobile
//
//  Created by Mehmet Akif LM on 6.12.2025.
//

import SwiftUI

@main
struct hackMobileApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var languageManager = LanguageManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationView {
                HomeView()
            }
            .preferredColorScheme(.light) // Force light mode for premium aesthetic
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .environmentObject(languageManager)
        }
    }
}
