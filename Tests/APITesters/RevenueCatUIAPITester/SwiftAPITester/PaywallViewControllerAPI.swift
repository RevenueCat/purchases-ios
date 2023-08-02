//
//  PaywallViewControllerAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 8/1/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

func paywallViewControllerAPI(_ delegate: PaywallViewControllerDelegate, _ offering: Offering?) {
    let controller: UIViewController = PaywallViewController()
    controller.delegate = delegate

    let _: UIViewController = PaywallViewController(offering: offering)
}

private final class Delegate: PaywallViewControllerDelegate {

    func paywallViewController(_ controller: PaywallViewController,
                               didFinishPurchasingWith customerInfo: CustomerInfo) {}

}
