//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SimulatedStorePurchaseUI.swift
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

enum SimulatedStorePurchaseUIResult: Sendable {
    case cancel
    case simulateFailure
    case simulateSuccess
    case error(PurchasesError)
}

protocol SimulatedStorePurchaseUI: Sendable {

    /// Presents the purchase UI for the given product.
    ///
    /// - Parameters:
    ///   - product: The product to be purchased.
    /// - Returns: A result indicating the selected outcome of the purchase UI interaction.
    func presentPurchaseUI(for product: SimulatedStoreProduct) async -> SimulatedStorePurchaseUIResult

}

/// Contains the logic to present a system alert for the confirmation of Simulated Store products purchases.
struct DefaultSimulatedStorePurchaseUI: SimulatedStorePurchaseUI {

    private let systemInfo: SystemInfo

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

    func presentPurchaseUI(for product: SimulatedStoreProduct) async -> SimulatedStorePurchaseUIResult {
        await Task { @MainActor in
            return await withUnsafeContinuation { continuation in

                let completion: (SimulatedStorePurchaseUIResult) -> Void = { result in
                    continuation.resume(returning: result)
                }

                let alert = Alert(
                    title: Self.purchaseAlertTitle,
                    message: product.purchaseAlertMessage,
                    actions: [
                        .init(title: Self.purchaseActionTitle,
                              callback: { _ in completion(.simulateSuccess) },
                              style: .default),
                        .init(title: Self.failureActionTitle,
                              callback: { _ in completion(.simulateFailure) },
                              style: .destructive),
                        .init(title: Self.cancelActionTitle,
                              callback: { _ in completion(.cancel) },
                              style: .cancel)
                    ], dismissCallback: {
                        completion(.cancel)
                    }
                )

                self.showAlert(alert) { (error: PurchasesError) in
                    completion(.error(error))
                }
            }
        }.value
    }

    #if !DEBUG

    /// Calling this method will show an alert indicating that a Test Store API key
    /// is being used in a release build, which is not supported.
    func showTestKeyInReleaseAlert(redactedApiKey: String) async {
        await Task { @MainActor in
            return await withUnsafeContinuation { continuation in

                let completion: () -> Void = continuation.resume

                let alert = Alert(
                    title: TestKeyInReleaseAlert.title,
                    message: TestKeyInReleaseAlert.message(redactedApiKey: redactedApiKey),
                    actions: [
                        .init(title: TestKeyInReleaseAlert.actionTitle,
                              callback: { _ in completion() },
                              style: .cancel)
                    ], dismissCallback: {
                        completion()
                    }
                )

                self.showAlert(alert) { _ in
                    completion()
                }
            }
        }.value
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

private extension DefaultSimulatedStorePurchaseUI {

    static let purchaseAlertTitle = "Test Purchase"
    static let purchaseActionTitle = "Test valid purchase"
    static let cancelActionTitle = "Cancel"
    static let failureActionTitle = "Test failed purchase"

}

private enum TestKeyInReleaseAlert {

    static let title = "Wrong API Key"
    static func message(redactedApiKey: String) -> String {
        return "This app is using a test API key: \(redactedApiKey)\n\n" +
        "To prepare for release, update your RevenueCat settings to use a production key.\n\n" +
        "For more info, visit the RevenueCat dashboard.\n\n" +
        "The app will close now to protect the security of test purchases."
    }

    static let actionTitle = "OK"
}

private extension SimulatedStoreProduct {

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

private extension StoreProductDiscount {

    var testPurchaseDescription: String {
        return "\(self.type.testPurchaseTitle): \(self.localizedPriceString) for " +
        "\(self.numberOfPeriods * self.subscriptionPeriod.value) \(self.subscriptionPeriod.unit.debugDescription)(s)"
    }
}

private extension StoreProductDiscount.DiscountType {

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

// MARK: - Generic Alert Model

private extension DefaultSimulatedStorePurchaseUI {

    struct Action {

        // swiftlint:disable:next nesting
        enum Style {
            case destructive
            case cancel
            case `default`
        }

        let title: String
        let callback: @MainActor (String) -> Void
        let style: Style
    }

    struct Alert {
        let title: String
        let message: String

        /// Only up to 3 actions are supported on macOS.
        let actions: [Action]
        let dismissCallback: @MainActor () -> Void
    }

}

private extension DefaultSimulatedStorePurchaseUI {

    @MainActor
    func showAlert(_ alert: Alert, onError: (PurchasesError) -> Void) {

        #if os(iOS) || os(tvOS) || VISION_OS || targetEnvironment(macCatalyst)
        guard let viewController = self.findTopViewController() else {
            Logger.warn(Strings.purchase.unable_to_find_root_view_controller_for_simulated_purchase)
            onError(ErrorUtils.unknownError(
                message: Strings.purchase.unable_to_find_root_view_controller_for_simulated_purchase.description
            ))
            return
        }

        let alertController = UIAlertController(title: alert.title,
                                                message: alert.message,
                                                preferredStyle: .alert)

        alert.actions.forEach { action in
            let alertAction = UIAlertAction(title: action.title, style: action.style.alertActionStyle) { _ in
                action.callback(action.title)
            }
            alertController.addAction(alertAction)
        }

        viewController.present(alertController, animated: true)

        #elseif os(watchOS)

        let actions: [WKAlertAction] = alert.actions.map { action in
            WKAlertAction(title: action.title, style: action.style.alertActionStyle) {
                action.callback(action.title)
            }

        }

        WKInterfaceDevice.current().play(.click)

        let controller = WKExtension.shared().rootInterfaceController
        controller?.presentAlert(withTitle: alert.title,
                                 message: alert.message,
                                 preferredStyle: .alert,
                                 actions: actions)

        #elseif os(macOS)

        let nsAlert = NSAlert()
        nsAlert.messageText = alert.title
        nsAlert.informativeText = alert.message
        nsAlert.alertStyle = .informational

        // Only up to 3 actions are supported on macOS. Keep a local array of the ones we actually show.
        let displayedActions = Array(alert.actions.prefix(3))
        displayedActions.forEach { action in
            nsAlert.addButton(withTitle: action.title)
        }

        let response = nsAlert.runModal()

        // Map the modal response to the button index (0-based).
        let indexMap: [NSApplication.ModalResponse: Int] = [
            .alertFirstButtonReturn: 0,
            .alertSecondButtonReturn: 1,
            .alertThirdButtonReturn: 2
        ]
        let selectedIndex = indexMap[response] ?? 0
        let selectedAction = displayedActions[safe: selectedIndex]
        selectedAction?.callback(selectedAction?.title ?? "")

        #endif

    }
}

extension DefaultSimulatedStorePurchaseUI.Action.Style {

    #if os(iOS) || os(tvOS) || VISION_OS || targetEnvironment(macCatalyst)

    var alertActionStyle: UIAlertAction.Style {
        switch self {
        case .destructive:
            return .destructive
        case .cancel:
            return .cancel
        case .default:
            return .default
        }
    }

    #elseif os(watchOS)

    var alertActionStyle: WKAlertActionStyle {
        switch self {
        case .destructive:
            return .destructive
        case .cancel:
            return .cancel
        case .default:
            return .default
        }
    }

    #endif
}

// MARK: - Helper

#if os(iOS) || os(tvOS) || VISION_OS || targetEnvironment(macCatalyst)

fileprivate extension DefaultSimulatedStorePurchaseUI {

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

}

#endif
