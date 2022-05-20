/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The scene delegate.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        LocationService.shared.errorPresentationTarget = scene.keyWindow?.rootViewController
        LocationService.shared.requestLocation()
    }
}
