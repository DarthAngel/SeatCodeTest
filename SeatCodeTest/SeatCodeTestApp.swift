//
//  SeatCodeTestApp.swift
//  SeatCodeTest
//
//  Created by Angel Docampo on 16/12/25.
//

import SwiftUI
internal import CarPlay

@main
struct SeatCodeTestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("Application did finish launching")
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("Configuring scene for role: \(connectingSceneSession.role.rawValue)")
        
        if connectingSceneSession.role == UISceneSession.Role.carTemplateApplication {
            // CarPlay scene configuration
            let config = UISceneConfiguration(name: "CarPlay Configuration", sessionRole: connectingSceneSession.role)
            config.delegateClass = CarPlaySceneDelegate.self
            print("Creating CarPlay scene configuration")
            return config
        } else {
            // Default scene configuration - let SwiftUI handle it
            let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
            // Don't set a custom delegate class for the main app - let SwiftUI handle it
            print("Creating default scene configuration for SwiftUI")
            return config
        }
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        print("Application did discard scene sessions: \(sceneSessions.count)")
    }
}
