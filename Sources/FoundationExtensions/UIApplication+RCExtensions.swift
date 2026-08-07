//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UIApplication+RCExtensions.swift
//
//  Created by Andrés Boedo on 8/20/21.

#if os(iOS) || os(tvOS) || VISION_OS
import UIKit

extension UIApplication {

    @available(macCatalyst 13.1, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(watchOSApplicationExtension, unavailable)
    @MainActor
    var currentWindowScene: UIWindowScene? {
        var scenes = self
            .connectedScenes
            .filter { $0.activationState == .foregroundActive }

        #if DEBUG && targetEnvironment(simulator)
        // Running StoreKitUnitTests might not always have an active scene
        // Sporadically, the only scene will be `foregroundInactive` or `background`
        if scenes.isEmpty, ProcessInfo.isRunningUnitTests {
            scenes = self.connectedScenes
        }
        #endif

        return scenes.first as? UIWindowScene
    }

    /// The topmost view controller in the current foreground window scene.
    @_spi(Internal)
    @available(macCatalyst 13.1, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(watchOSApplicationExtension, unavailable)
    @MainActor
    public var currentPresentationViewController: UIViewController? {
        guard let windowScene = self.currentWindowScene else { return nil }

        let window: UIWindow?
        if #available(iOS 15.0, macCatalyst 15.0, tvOS 15.0, *) {
            window = windowScene.keyWindow
        } else {
            window = windowScene.windows.first { $0.isKeyWindow }
        }

        return window?.rootViewController?.topMostViewController
    }

}

private extension UIViewController {

    var topMostViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topMostViewController
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController
                ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController
                ?? tabBarController
        }
        if let splitViewController = self as? UISplitViewController,
           let lastViewController = splitViewController.viewControllers.last {
            return lastViewController.topMostViewController
        }
        return self
    }

}

#endif
