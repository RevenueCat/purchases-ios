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

    @available(iOS 13.0, macCatalyst 13.1, tvOS 13.0, *)
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

    @available(iOS 15.0, tvOS 15.0, *)
    var currentViewController: UIViewController? {
        var rootViewController = currentWindowScene?.keyWindow?.rootViewController

        if rootViewController == nil {
            // Fallback for application extensions where scenes are not supported
            rootViewController = (value(forKey: "keyWindow") as? UIWindow)?.rootViewController
        }

        guard let resolvedRootViewController = rootViewController else {
            return nil
        }

        return getTopViewController(from: resolvedRootViewController)
    }

    private func getTopViewController(from viewController: UIViewController) -> UIViewController? {
        if let presentedViewController = viewController.presentedViewController {
            return getTopViewController(from: presentedViewController)
        } else if let navigationController = viewController as? UINavigationController {
            return navigationController.visibleViewController
        } else if let tabBarController = viewController as? UITabBarController,
                  let selected = tabBarController.selectedViewController {
            return getTopViewController(from: selected)
        }
        return viewController
    }

}

#endif
