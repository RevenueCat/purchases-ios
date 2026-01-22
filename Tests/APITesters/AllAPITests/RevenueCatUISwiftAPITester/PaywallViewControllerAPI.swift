//
//  PaywallViewControllerAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 8/1/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
func paywallViewControllerAPI(_ delegate: Delegate,
                              _ offering: Offering?,
                              _ performPurchase: PerformPurchase?,
                              _ performRestore: PerformRestore?,
                              _ dismissRequestedHandler: ((_ controller: PaywallViewController) -> Void)?) {
    let fontProvider: PaywallFontProvider = CustomPaywallFontProvider(fontName: "test")

    let controller = PaywallViewController()
    controller.delegate = delegate

    let _: UIViewController = PaywallViewController(fonts: fontProvider)
    let _: UIViewController = PaywallViewController(offering: offering)
    let _: UIViewController = PaywallViewController(offeringIdentifier: "offering")
    let _: UIViewController = PaywallViewController(displayCloseButton: true)
    let _: UIViewController = PaywallViewController(fonts: fontProvider)
    let _: UIViewController = PaywallViewController(offering: offering,
                                                    displayCloseButton: true,
                                                    dismissRequestedHandler: dismissRequestedHandler)
    let _: UIViewController = PaywallViewController(offering: offering,
                                                    displayCloseButton: true,
                                                    shouldBlockTouchEvents: true,
                                                    dismissRequestedHandler: dismissRequestedHandler)
    let _: UIViewController = PaywallViewController(offering: offering, fonts: fontProvider)
    let _: UIViewController = PaywallViewController(offering: offering, fonts: fontProvider)
    let _: UIViewController = PaywallViewController(offering: offering,
                                                    fonts: fontProvider,
                                                    displayCloseButton: true)
    let _: UIViewController = PaywallViewController(offering: offering,
                                                    fonts: fontProvider,
                                                    displayCloseButton: true,
                                                    dismissRequestedHandler: dismissRequestedHandler)
    let _: UIViewController = PaywallViewController(offering: offering,
                                                    fonts: fontProvider,
                                                    displayCloseButton: true,
                                                    shouldBlockTouchEvents: true,
                                                    dismissRequestedHandler: dismissRequestedHandler)
    let _: UIViewController = PaywallViewController(offeringIdentifier: "offering", displayCloseButton: true)
    let _: UIViewController = PaywallViewController(offeringIdentifier: "offering", fonts: fontProvider)
    let _: UIViewController = PaywallViewController(offeringIdentifier: "offering",
                                                    fonts: fontProvider,
                                                    displayCloseButton: true)
    let _: UIViewController = PaywallViewController(offeringIdentifier: "offering",
                                                    fonts: fontProvider,
                                                    displayCloseButton: true,
                                                    dismissRequestedHandler: dismissRequestedHandler)
    let _: UIViewController = PaywallViewController(offeringIdentifier: "offering",
                                                    fonts: fontProvider,
                                                    displayCloseButton: true,
                                                    shouldBlockTouchEvents: true,
                                                    dismissRequestedHandler: dismissRequestedHandler)
    let _: UIViewController = PaywallViewController(fonts: fontProvider,
                                                    performPurchase: performPurchase,
                                                    performRestore: performRestore)
    let _: UIViewController = PaywallViewController(offering: offering,
                                                    fonts: fontProvider,
                                                    performPurchase: performPurchase,
                                                    performRestore: performRestore)
    let _: UIViewController = PaywallViewController(fonts: fontProvider,
                                                    performPurchase: performPurchase,
                                                    performRestore: performRestore,
                                                    dismissRequestedHandler: dismissRequestedHandler)
    let _: UIViewController = PaywallViewController(offering: offering,
                                                    fonts: fontProvider,
                                                    displayCloseButton: true,
                                                    performPurchase: performPurchase,
                                                    performRestore: performRestore)
    let _: UIViewController = PaywallViewController(offering: offering,
                                                    fonts: fontProvider,
                                                    shouldBlockTouchEvents: true,
                                                    performPurchase: performPurchase,
                                                    performRestore: performRestore)
    let _: UIViewController = PaywallViewController(offering: offering,
                                                    fonts: fontProvider,
                                                    shouldBlockTouchEvents: true,
                                                    performPurchase: performPurchase,
                                                    performRestore: performRestore,
                                                    dismissRequestedHandler: dismissRequestedHandler)

    controller.update(with: offering!)
    controller.update(with: "offering_identifier")
    controller.updateFont(with: "Papyrus")

    // Custom Variables API
    let customVars: [String: CustomVariableValue] = [
        "player_name": .string("John"),
        "max_health": .number(100),
        "is_premium": .bool(true)
    ]
    controller.customVariables = customVars

    // Objective-C compatible methods
    controller.setCustomVariable("Jane", forKey: "player_name")
    controller.setCustomVariableNumber(200, forKey: "max_health")
    controller.setCustomVariableBool(false, forKey: "is_premium")
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
func customVariableValueAPI() {
    // CustomVariableValue type and static constructors
    let _: CustomVariableValue = .string("test")
    let _: CustomVariableValue = .number(42)
    let _: CustomVariableValue = .number(3.14)
    let _: CustomVariableValue = .bool(true)

    // Accessing underlying value
    let stringValue: CustomVariableValue = .string("hello")
    let _: String = stringValue.stringValue

    let numberValue: CustomVariableValue = .number(100)
    let _: Double = numberValue.doubleValue

    let boolValue: CustomVariableValue = .bool(true)
    let _: Bool = boolValue.boolValue
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
func paywallFooterViewControllerAPI(_ delegate: Delegate,
                                    _ offering: Offering?,
                                    _ performPurchase: PerformPurchase?,
                                    _ performRestore: PerformRestore?,
                                    _ dismissRequestedHandler: ((_ controller: PaywallViewController) -> Void)?) {
    let controller = PaywallFooterViewController()
    controller.delegate = delegate

    let _: UIViewController = PaywallFooterViewController(offering: offering)
    let _: UIViewController = PaywallFooterViewController(offering: offering,
                                                          dismissRequestedHandler: dismissRequestedHandler)
    let _: UIViewController = PaywallFooterViewController(offeringIdentifier: "offering")
    let _: UIViewController = PaywallFooterViewController(offeringIdentifier: "offering",
                                                          dismissRequestedHandler: dismissRequestedHandler)
    let _: UIViewController = PaywallFooterViewController(offeringIdentifier: "offering",
                                                          fontName: "Papyrus",
                                                          dismissRequestedHandler: dismissRequestedHandler)

    let _: UIViewController = PaywallFooterViewController(performPurchase: performPurchase!,
                                                          performRestore: performRestore!)
    let _: UIViewController = PaywallFooterViewController(offering: offering,
                                                          performPurchase: performPurchase!,
                                                          performRestore: performRestore!)
    let _: UIViewController = PaywallFooterViewController(performPurchase: performPurchase!,
                                                          performRestore: performRestore!,
                                                          dismissRequestedHandler: dismissRequestedHandler)
    let _: UIViewController = PaywallFooterViewController(offering: offering,
                                                          performPurchase: performPurchase!,
                                                          performRestore: performRestore!,
                                                          dismissRequestedHandler: dismissRequestedHandler)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
final class Delegate: PaywallViewControllerDelegate {

    func paywallViewControllerDidStartPurchase(_ controller: PaywallViewController) {}

    func paywallViewController(_ controller: PaywallViewController,
                               didFinishPurchasingWith customerInfo: CustomerInfo) {}

    func paywallViewController(_ controller: PaywallViewController,
                               didFinishPurchasingWith customerInfo: CustomerInfo,
                               transaction: StoreTransaction?) {}

    func paywallViewControllerDidCancelPurchase(_ controller: PaywallViewController) {}

    func paywallViewController(_ controller: PaywallViewController,
                               didFailPurchasingWith error: NSError) {}

    func paywallViewControllerDidStartRestore(_ controller: PaywallViewController) {}

    func paywallViewController(_ controller: PaywallViewController,
                               didFinishRestoringWith customerInfo: CustomerInfo) {}

    func paywallViewController(_ controller: PaywallViewController,
                               didFailRestoringWith error: NSError) {}

    func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {}

    func paywallViewController(_ controller: PaywallViewController,
                               didChangeSizeTo size: CGSize) {}

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
final class DelegateWithNoImplementations: PaywallViewControllerDelegate {}

#endif
