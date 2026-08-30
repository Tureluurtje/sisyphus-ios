//
//  sisyphusApp.swift
//  sisyphus
//
//  Created by Arthur Kwak on 06/05/2026.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct sisyphusApp: App {

    @StateObject private var errorManager = ErrorManager()

    init() {
        ErrorMonitoring.shared.configure()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(errorManager)
        }
        .modelContainer(for: [WordList.self, WordResult.self])
    }
}
