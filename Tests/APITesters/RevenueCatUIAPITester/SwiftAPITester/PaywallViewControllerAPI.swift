//
//  PaywallViewControllerAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 8/1/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
func paywallViewControllerAPI(_ delegate: Delegate, _ offering: Offering?) {
    let controller = PaywallViewController()
    controller.delegate = delegate

    let _: UIViewController = PaywallViewController(offering: offering)
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
final class Delegate: PaywallViewControllerDelegate {

    func paywallViewController(_ controller: PaywallViewController,
                               didFinishPurchasingWith customerInfo: CustomerInfo) {}

}
