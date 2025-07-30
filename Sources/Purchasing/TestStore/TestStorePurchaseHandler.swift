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

enum TestPurchaseResult {
    case cancel
    case failure
    case success
}

protocol TestStorePurchaseHandlerType: AnyObject, Sendable {

    #if TEST_STORE
    /// - Throws: a `PurchasesError` if there's an error when trying to make the test purchase
    /// (e.g. there's already a purchase in progress).
    @MainActor
    func purchase(product: TestStoreProduct) async throws -> TestPurchaseResult
    #endif // TEST_STORE
}

/// The object that handles purchases in the Test Store.
///
/// This class is used to handle purchases when using a Test Store API key.
actor TestStorePurchaseHandler: TestStorePurchaseHandlerType {

    private let systemInfo: SystemInfo

    private var currentPurchaseTask: Task<TestPurchaseResult, Error>?
    private var purchaseInProgress: Bool {
        return self.currentPurchaseTask != nil
    }

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

    #if TEST_STORE

    func purchase(product: TestStoreProduct) async throws -> TestPurchaseResult {
        guard !self.purchaseInProgress else {
            throw ErrorUtils.operationAlreadyInProgressError()
        }

        let newPurchaseTask = Task<TestPurchaseResult, Error> { [weak self] in
            guard let self else {
                throw ErrorUtils.unknownError()
            }

            return await self.presentPurchaseAlert(for: product)
        }

        self.currentPurchaseTask = newPurchaseTask
        let purchaseResult = try await newPurchaseTask.value
        self.currentPurchaseTask = nil

        return purchaseResult
    }

    #endif // TEST_STORE
}

// MARK: - Purchase Alert Presentation

private extension TestStorePurchaseHandler {

    /// Presents a purchase alert for the given product.
    func presentPurchaseAlert(for product: TestStoreProduct) async -> TestPurchaseResult {
        await Task { @MainActor in
            return await withUnsafeContinuation { (continuation: UnsafeContinuation<TestPurchaseResult, Never>) in

                let completion: (TestPurchaseResult) -> Void = { result in
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
        product: TestStoreProduct, completion: @escaping @MainActor (TestPurchaseResult) -> Void
    ) {
        guard let viewController = self.findTopViewController() else {
            Logger.warn(Strings.purchase.unable_to_find_root_view_controller_for_test_purchase)
            completion(.failure)
            return
        }

        let alertController = UIAlertController(title: Self.purchaseAlertTitle,
                                                message: product.purchaseAlertMessage,
                                                preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: Self.failureActionTitle, style: .destructive) { _ in
            completion(.failure)
        })

        alertController.addAction(UIAlertAction(title: Self.cancelActionTitle, style: .cancel) { _ in
            completion(.cancel)
        })

        alertController.addAction(UIAlertAction(title: Self.purchaseActionTitle, style: .default) { _ in
            completion(.success)
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
        product: TestStoreProduct, completion: @escaping @MainActor (TestPurchaseResult) -> Void
    ) {

        let failureAction = WKAlertAction(title: Self.failureActionTitle, style: .destructive) {
            completion(.failure)
        }

        let purchaseAction = WKAlertAction(title: Self.purchaseActionTitle, style: .default) {
            completion(.success)
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
        product: TestStoreProduct, completion: @escaping @MainActor (TestPurchaseResult) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = Self.purchaseAlertTitle
        alert.informativeText = product.purchaseAlertMessage
        alert.alertStyle = .informational

        alert.addButton(withTitle: Self.purchaseActionTitle)
        alert.addButton(withTitle: Self.cancelActionTitle)
        alert.addButton(withTitle: Self.failureActionTitle)

        let response = alert.runModal()

        let testPurchaseResult: TestPurchaseResult

        switch response {
        case .alertFirstButtonReturn:
            testPurchaseResult = .success
        case .alertSecondButtonReturn:
            testPurchaseResult = .cancel
        case .alertThirdButtonReturn:
            testPurchaseResult = .failure
        default:
            testPurchaseResult = .success // Fallback case
        }

        completion(testPurchaseResult)
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

fileprivate extension TestStorePurchaseHandler {

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
