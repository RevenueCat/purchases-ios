//
//  TestStorePurchaseHandler.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 16/7/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS) || VISION_OS || targetEnvironment(macCatalyst)
import UIKit
#elseif os(watchOS)
import UIKit
import WatchKit
#elseif os(macOS)
import AppKit
#endif

/// The object that handles purchases in the Test Store.
///
/// This class is used to handle purchases when using a Test Store API key.
class TestStorePurchaseHandler {

    private let systemInfo: SystemInfo

    @MainActor
    private var purchaseInProgress: Bool = false

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

    /// - Throws: an `PurchasesError` if there's an error when trying to make the test purchase (e.g. there's already a purchase in progress).
    @MainActor
    func purchase(product: TestStoreProduct, completion: @escaping (Bool) -> Void) throws {
        guard !self.purchaseInProgress else {
            throw ErrorUtils.operationAlreadyInProgressError()
        }
        self.purchaseInProgress = true
        let completionWrapper: (Bool) -> Void = { @MainActor [weak self] success in
            self?.purchaseInProgress = false
            completion(success)
        }

        #if os(iOS) || os(tvOS) || VISION_OS || targetEnvironment(macCatalyst)
        self.purchaseWithUIKit(product: product, completion: completionWrapper)
        #elseif os(watchOS)
        self.purchaseWithWatchKit(product: product, completion: completionWrapper)
        #elseif os(macOS)
        self.purchaseWithAppKit(product: product, completion: completionWrapper)
        #endif
    }

    #if os(iOS) || os(tvOS) || VISION_OS || targetEnvironment(macCatalyst)
    @MainActor
    private func purchaseWithUIKit(product: TestStoreProduct, completion: @escaping @MainActor (Bool) -> Void) {
        guard let viewController = self.findTopViewController() else {
            Logger.warn(Strings.purchase.unable_to_find_root_view_controller_for_test_purchase)
            completion(false)
            return
        }

        let alertController = UIAlertController(title: Self.purchaseAlertTitle,
                                                message: product.purchaseAlertMessage,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: Self.cancelActionTitle, style: .cancel) { _ in
            completion(false)
        })
        
        alertController.addAction(UIAlertAction(title: Self.purchaseActionTitle, style: .default) { _ in
            completion(true)
        })
        
        viewController.present(alertController, animated: true)
    }

    @MainActor
    private func findTopViewController() -> UIViewController? {
        // Try to get the window scene first (iOS 13+)
        if let windowScene = self.systemInfo.sharedUIApplication?.currentWindowScene {
            return self.findTopViewController(in: windowScene)
        }
        
        // Fallback to legacy approach
        guard let application = self.systemInfo.sharedUIApplication else {
            return nil
        }
        
        // Use the first key window
        let window = application.windows.first(where: { $0.isKeyWindow })
        return window?.rootViewController?.topMostViewController()
    }

    @available(iOS 13.0, macCatalyst 13.1, tvOS 13.0, *)
    @MainActor
    private func findTopViewController(in windowScene: UIWindowScene) -> UIViewController? {
        let window: UIWindow?
        if #available(iOS 15.0, macCatalyst 15.0, tvOS 15.0, *) {
            window = windowScene.keyWindow
        } else {
            window = windowScene.windows.first(where: { $0.isKeyWindow })
        }
        
        return window?.rootViewController?.topMostViewController()
    }
    #endif

    #if os(watchOS)
    @MainActor
    private func purchaseWithWatchKit(product: TestStoreProduct, completion: @escaping @MainActor (Bool) -> Void) {
        let alertAction = WKAlertAction(title: Self.purchaseActionTitle, style: .default) {
            completion(true)
        }
        
        let cancelAction = WKAlertAction(title: Self.cancelActionTitle, style: .cancel) {
            completion(false)
        }
        
        WKInterfaceDevice.current().play(.click)
        
        let controller = WKExtension.shared().rootInterfaceController
        controller?.presentAlert(withTitle: Self.purchaseAlertTitle,
                                message: product.purchaseAlertMessage,
                                preferredStyle: .alert, 
                                actions: [cancelAction, alertAction])
    }
    #endif

    #if os(macOS)
    @MainActor
    private func purchaseWithAppKit(product: TestStoreProduct, completion: @escaping @MainActor (Bool) -> Void) {
        let alert = NSAlert()
        alert.messageText = Self.purchaseAlertTitle
        alert.informativeText = product.purchaseAlertMessage
        alert.alertStyle = .informational
        
        alert.addButton(withTitle: Self.purchaseActionTitle)
        alert.addButton(withTitle: Self.cancelActionTitle)

        let response = alert.runModal()
        let userConfirmed = response == .alertFirstButtonReturn
        completion(userConfirmed)
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

// MARK: - Building the Purchase alert

fileprivate extension TestStorePurchaseHandler {

    static let purchaseAlertTitle = "Test Purchase"
    static let purchaseActionTitle = "Test Purchase"
    static let cancelActionTitle = "Cancel"

}

fileprivate extension TestStoreProduct {

    var purchaseAlertMessage: String {
        var message = "⚠️ This is a test purchase and should be tested with real products using " +
        "an Apple API key from RevenueCat.\n\n"
        message += "Product ID: \(self.productIdentifier)\n"
        message += "Title: \(self.localizedTitle)\n"
        message += "Price: \(self.localizedPriceString)\n"

        if let subscriptionPeriod = self.subscriptionPeriod {
            message += "Period: \(subscriptionPeriod)\n"
        }

        if !self.discounts.isEmpty {
            message += "Offers:\n" + self.discounts.map { $0.testPurchaseDescription }.joined(separator: "\n")
        }

        return message
    }

}

fileprivate extension StoreProductDiscount {

    var testPurchaseDescription: String {
        return "\(self.type.testPurchaseTitle): \(self.localizedPriceString) for \(self.numberOfPeriods * self.subscriptionPeriod.value) \(self.subscriptionPeriod.unit.debugDescription)(s)"
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
