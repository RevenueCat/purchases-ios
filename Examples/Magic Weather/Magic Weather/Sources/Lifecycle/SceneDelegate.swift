//
//  SceneDelegate.swift
//  Magic Weather
//
//  Created by Cody Kerns on 12/14/20.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        /// - This sample app uses the dark interface style by default
        scene.windows.forEach { (window) in
            window.overrideUserInterfaceStyle = .dark
        }
    }
    
}
