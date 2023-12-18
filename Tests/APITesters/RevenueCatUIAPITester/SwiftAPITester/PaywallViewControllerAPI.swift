//
//  PaywallViewControllerAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 8/1/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
func paywallViewControllerAPI(_ delegate: Delegate, _ offering: Offering?) {
    let controller = PaywallViewController()
    controller.delegate = delegate

    let _: UIViewController = PaywallViewController(offering: offering)
    let _: UIViewController = PaywallViewController(displayCloseButton: true)
    let _: UIViewController = PaywallViewController(offering: offering, displayCloseButton: true)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
final class Delegate: PaywallViewControllerDelegate {

    func paywallViewController(_ controller: PaywallViewController,
                               didFinishPurchasingWith customerInfo: CustomerInfo) {}

    func paywallViewController(_ controller: PaywallViewController,
                               didFinishPurchasingWith customerInfo: CustomerInfo,
                               transaction: StoreTransaction?) {}

    func paywallViewController(_ controller: PaywallViewController,
                               didFinishRestoringWith customerInfo: CustomerInfo) {}

    func paywallViewControllerWasDismissed(_ controller: PaywallViewController) {}

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
final class DelegateWithNoImplementations: PaywallViewControllerDelegate {}
