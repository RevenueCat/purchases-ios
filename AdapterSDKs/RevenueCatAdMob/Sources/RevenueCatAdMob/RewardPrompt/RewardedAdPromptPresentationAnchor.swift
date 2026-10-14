//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardedAdPromptPresentationAnchor.swift
//

import Foundation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(SwiftUI)
@_spi(Internal) import RevenueCat
import SwiftUI
import UIKit

@available(iOS 15.0, *)
struct RewardedAdPromptPresentationAnchor: UIViewControllerRepresentable {

    let onResolve: @MainActor (UIViewController) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.isHidden = true
        self.onResolve(viewController)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        self.onResolve(uiViewController)
    }

}

@available(iOS 15.0, *)
@MainActor
extension UIViewController {

    var rewardedAdPromptPresentationViewController: UIViewController? {
        guard let window = self.viewIfLoaded?.window,
              let viewController = window.rootViewController?.topMostViewController,
              viewController.viewIfLoaded?.window === window else { return nil }
        return viewController
    }

}

#endif
