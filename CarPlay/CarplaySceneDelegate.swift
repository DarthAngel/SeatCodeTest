//
//  CarPlaySceneDelegate.swift
//  SeatCodeTest
//
//   Created by Angel Docampo on 04/01/2026.
//

internal import CarPlay
import UIKit

@MainActor
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    
    var interfaceController: CPInterfaceController?
    let carPlayManager = CarPlayManager()
    
    // MARK: - CPTemplateApplicationSceneDelegate
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didConnect interfaceController: CPInterfaceController) {
        print("CarPlay scene did connect")
        self.interfaceController = interfaceController
        carPlayManager.interfaceController = interfaceController
        
        // Set up the initial template
        setupInitialTemplate()
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        print("CarPlay scene did disconnect interface controller")
        self.interfaceController = nil
        carPlayManager.interfaceController = nil
    }
    
    // MARK: - UISceneDelegate Lifecycle Methods
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("CarPlay scene will connect to session")
        // Additional setup can be done here if needed
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("CarPlay scene did become active")
        // Called when the scene has moved from an inactive state to an active state.
        // This may occur due to the user selecting the scene or when a session is 
        // resumed from the background.
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        print("CarPlay scene will resign active")
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("CarPlay scene did enter background")
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough 
        // scene-specific state information to restore the scene back to its current state.
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("CarPlay scene will enter foreground")
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        
        // Refresh data when returning to foreground
        if let rootTemplate = interfaceController?.rootTemplate as? CPTabBarTemplate {
            // Trigger data refresh on the active template
            setupInitialTemplate()
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        print("CarPlay scene did disconnect")
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its 
        // session is discarded. Release any resources associated with this scene 
        // that can be re-created the next time the scene connects.
        self.interfaceController = nil
        carPlayManager.interfaceController = nil
    }
    
    // MARK: - Private Methods
    
    private func setupInitialTemplate() {
        guard let interfaceController = self.interfaceController else {
            print("Warning: Interface controller is nil when setting up initial template")
            return
        }
        
        let rootTemplate = carPlayManager.createRootTabBarTemplate()
        interfaceController.setRootTemplate(rootTemplate, animated: true) { success, error in
            if let error = error {
                print("Error setting root template: \(error)")
            } else {
                print("Successfully set root template")
            }
        }
    }
}
