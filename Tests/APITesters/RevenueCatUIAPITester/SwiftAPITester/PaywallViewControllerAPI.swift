//
//  PaywallViewControllerAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 8/1/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

func paywallViewControllerAPI(_ delegate: PaywallViewControllerDelegate) {
    let controller: UIViewController = PaywallViewController()
    controller.delegate = delegate
}

private final class Delegate: PaywallViewControllerDelegate {

    func paywallViewController(_ controller: PaywallViewController,
                               didFinishPurchasing with: CustomerInfo) {}

}
