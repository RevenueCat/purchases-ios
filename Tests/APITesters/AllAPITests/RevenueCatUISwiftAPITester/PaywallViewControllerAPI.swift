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
    let _: UIViewController = PaywallFooterViewController(offeringIdentifier: "offering", fontName: "Papyrus")

    controller.update(with: offering!)
    controller.update(with: "offering_identifier")
    controller.updateFont(with: "Papyrus")
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
func paywallFooterViewControllerAPI(_ delegate: Delegate,
                                    _ offering: Offering?,
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
