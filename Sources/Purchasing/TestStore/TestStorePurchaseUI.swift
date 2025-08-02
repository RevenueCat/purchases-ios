//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TestStorePurchaseUI.swift
//
//  Created by Antonio Pallares on 1/8/25.

import Foundation
#if os(iOS) || os(tvOS) || VISION_OS || targetEnvironment(macCatalyst)
import UIKit
#elseif os(watchOS)
import UIKit
import WatchKit
#elseif os(macOS)
import AppKit
#endif

enum TestStorePurchaseUIResult: Sendable {
    case cancel
    case simulateFailure
    case simulateSuccess
    case error(PurchasesError)
}

protocol TestStorePurchaseUI: Sendable {

    /// Presents the purchase UI for the given product.
    ///
    /// - Parameters:
    ///   - product: The product to be purchased.
    /// - Returns: A result indicating the selected outcome of the purchase UI interaction.
    func presentPurchaseUI(for product: TestStoreProduct) async -> TestStorePurchaseUIResult

}

struct DefaultTestStorePurchaseUI: TestStorePurchaseUI {

    private let systemInfo: SystemInfo

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

    func presentPurchaseUI(for product: TestStoreProduct) async -> TestStorePurchaseUIResult {
        await Task { @MainActor in
            return await withUnsafeContinuation { (continuation: UnsafeContinuation<TestStorePurchaseUIResult, Never>) in

                let completion: (TestStorePurchaseUIResult) -> Void = { result in
                    continuation.resume(returning: result)
                }

                #if os(iOS) || os(tvOS) || VISION_OS || targetEnvironment(macCatalyst)
                self.purchaseWithUIKit(product: product, completion: completion)
                #elseif os(watchOS)
                self.purchaseWithWatchKit(product: product, completion: completion)
                #elseif os(macOS)
                self.purchaseWithAppKit(product: product, completion: completion)
                #endif
            }
        }.value
    }

    #if os(iOS) || os(tvOS) || VISION_OS || targetEnvironment(macCatalyst)
    @MainActor
    func purchaseWithUIKit(
        product: TestStoreProduct, completion: @escaping @MainActor (TestStorePurchaseUIResult) -> Void
    ) {
        guard let viewController = self.findTopViewController() else {
            Logger.warn(Strings.purchase.unable_to_find_root_view_controller_for_test_purchase)
            completion(.error(ErrorUtils.unknownError(
                message: Strings.purchase.unable_to_find_root_view_controller_for_test_purchase.description
            )))
            return
        }

        let alertController = UIAlertController(title: Self.purchaseAlertTitle,
                                                message: product.purchaseAlertMessage,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: Self.failureActionTitle, style: .destructive) { _ in
            completion(.simulateFailure)
        })

        alertController.addAction(UIAlertAction(title: Self.cancelActionTitle, style: .cancel) { _ in
            completion(.cancel)
        })

        alertController.addAction(UIAlertAction(title: Self.purchaseActionTitle, style: .default) { _ in
            completion(.simulateSuccess)
        })

        viewController.present(alertController, animated: true)
    }

    @MainActor
    func findTopViewController() -> UIViewController? {
        guard let application = self.systemInfo.sharedUIApplication else {
            return nil
        }

        let window: UIWindow?

        // Try to get the window from the scene first
        if #available(macCatalyst 13.1, *),
           let windowScene = application.currentWindowScene {
            if #available(iOS 15.0, macCatalyst 15.0, tvOS 15.0, *) {
                window = windowScene.keyWindow
            } else {
                window = windowScene.windows.first(where: { $0.isKeyWindow })
            }
        } else {
            if #available(iOS 15.0, macCatalyst 15.0, *) {
                window = nil
            } else {
                // Fallback to legacy approach on OSs where UIApplication's `windows` property is not deprecated
                window = application.windows.first(where: { $0.isKeyWindow })
            }
        }

        return window?.rootViewController?.topMostViewController()
    }

    #endif

    #if os(watchOS)
    @MainActor
    func purchaseWithWatchKit(
        product: TestStoreProduct, completion: @escaping @MainActor (TestStorePurchaseUIResult) -> Void
    ) {

        let failureAction = WKAlertAction(title: Self.failureActionTitle, style: .destructive) {
            completion(.failure(self.testPurchaseFailureError))
        }

        let purchaseAction = WKAlertAction(title: Self.purchaseActionTitle, style: .default) { [weak self] in
            self?.completePurchase(product: product, completion: completion)
        }

        let cancelAction = WKAlertAction(title: Self.cancelActionTitle, style: .cancel) {
            completion(.cancel)
        }

        WKInterfaceDevice.current().play(.click)

        let controller = WKExtension.shared().rootInterfaceController
        controller?.presentAlert(withTitle: Self.purchaseAlertTitle,
                                 message: product.purchaseAlertMessage,
                                 preferredStyle: .alert,
                                 actions: [failureAction, cancelAction, purchaseAction])
    }
    #endif

    #if os(macOS)
    @MainActor
    func purchaseWithAppKit(
        product: TestStoreProduct, completion: @escaping @MainActor (TestStorePurchaseUIResult) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = Self.purchaseAlertTitle
        alert.informativeText = product.purchaseAlertMessage
        alert.alertStyle = .informational

        alert.addButton(withTitle: Self.purchaseActionTitle)
        alert.addButton(withTitle: Self.cancelActionTitle)
        alert.addButton(withTitle: Self.failureActionTitle)

        let response = alert.runModal()

        Task {

            let testPurchaseResult: TestPurchaseResult

            switch response {
            case .alertFirstButtonReturn:
                testPurchaseResult = await .success(self.createStoreTransaction(product: product))
            case .alertSecondButtonReturn:
                testPurchaseResult = .cancel
            case .alertThirdButtonReturn:
                testPurchaseResult = .failure(self.testPurchaseFailureError)
            default:
                testPurchaseResult = await .success(self.createStoreTransaction(product: product)) // Fallback case
            }

            completion(testPurchaseResult)
        }
    }
    #endif

}



#if os(iOS) || os(tvOS) || VISION_OS || targetEnvironment(macCatalyst)

// MARK: - UIViewController Extensions

private extension UIViewController {

    func topMostViewController() -> UIViewController {
        if let presentedViewController = self.presentedViewController {
            return presentedViewController.topMostViewController()
        }

        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController() ?? navigationController
        }

        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController() ?? tabBarController
        }

        return self
    }
}
#endif

// MARK: - Purchase Alert Details

fileprivate extension DefaultTestStorePurchaseUI {

    static let purchaseAlertTitle = "Test Purchase"
    static let purchaseActionTitle = "Test valid purchase"
    static let cancelActionTitle = "Cancel"
    static let failureActionTitle = "Test failed purchase"

}

fileprivate extension TestStoreProduct {

    var purchaseAlertMessage: String {
        var message = "This is a test purchase and should only be used during development. In production, " +
        "use an Apple API key from RevenueCat.\n\n"
        message += "Product ID: \(self.productIdentifier)\n"
        message += "Title: \(self.localizedTitle)\n"
        message += "Price: \(self.localizedPriceString)\n"

        if let subscriptionPeriod = self.subscriptionPeriod {
            message += subscriptionPeriod.debugDescription + "\n"
        }

        if !self.discounts.isEmpty {
            message += "Offers:\n" + self.discounts.map { $0.testPurchaseDescription }.joined(separator: "\n")
        }

        return message
    }

}

fileprivate extension StoreProductDiscount {

    var testPurchaseDescription: String {
        return "\(self.type.testPurchaseTitle): \(self.localizedPriceString) for " +
        "\(self.numberOfPeriods * self.subscriptionPeriod.value) \(self.subscriptionPeriod.unit.debugDescription)(s)"
    }
}

fileprivate extension StoreProductDiscount.DiscountType {

    var testPurchaseTitle: String {
        switch self {
        case .introductory:
            return "Intro"
        case .promotional:
            return "Promo"
        case .winBack:
            return "WinBack"
        }
    }
}
