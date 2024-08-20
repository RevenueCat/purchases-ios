//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OpenAppStoreViewController.swift
//
//  Created by JayShortway on 19/08/2024.

#if CUSTOMER_CENTER_ENABLED

import Foundation
import StoreKit
import UIKit

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
class OpenAppStoreViewController: UIViewController, SKStoreProductViewControllerDelegate {
    let onDismiss: (SKStoreProductViewController) -> Void

    init(
        onDismiss: @escaping (SKStoreProductViewController) -> Void = { viewController in
            viewController.dismiss(animated: true)
        }
    ) {
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Opens the App Store for the provided productId in-app using SKStoreProductViewController. Falls back to
    /// redirecting to the App Store if this fails.
    func openAppStore(productId: UInt) {
        let storeProductViewController = SKStoreProductViewController()
        storeProductViewController.delegate = self
        let parameters = [SKStoreProductParameterITunesItemIdentifier: productId]

        storeProductViewController.loadProduct(withParameters: parameters) { _, error in
            guard error == nil,
                  let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                // productId is a positive integer, so it is safe to construct a URL from it.
                let appStoreUrl = URL(string: "https://itunes.apple.com/app/id\(productId)")!
                UIApplication.shared.open(appStoreUrl)
                return
            }

            rootViewController.present(storeProductViewController, animated: true, completion: nil)
        }
    }

    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        onDismiss(viewController)
    }
}

#endif
