//
//  TestStorePurchaseHandler.swift
//  RevenueCat
//
//  Created by Antonio Pallares on 16/7/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import Foundation
import UIKit

/// The object that handles purchases in the Test Store.
///
/// This class is used to handle purchases when using a Test Store API key.
class TestStorePurchaseHandler {

    private let systemInfo: SystemInfo

    init(systemInfo: SystemInfo) {
        self.systemInfo = systemInfo
    }

    @MainActor
    func purchase(product: TestStoreProduct, confirmIn windowScene: some UIWindowScene) {
        var window: UIWindow?
        if #available(iOS 15.0, macCatalyst 15.0, tvOS 15.0, *) {
            window = windowScene.keyWindow
        } else {
            window = windowScene.windows.first(where: { $0.isKeyWindow } )
        }

        guard let viewController = window?.rootViewController else {
            Logger.warn(Strings.purchase.unable_to_find_root_view_controller_for_test_purchase)
            return
        }

        let alertController = UIAlertController(title: "Test Purchase",
                                                message: product.purchaseAlertMessage,
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Test Purchase", style: .default) { _ in

        })
        viewController.present(alertController, animated: true)
    }
}

// MARK: - Building the Purchase alert

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
