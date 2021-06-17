//
//  PurchasesSwift.swift
//  PurchasesSwift
//
//  Created by Andrés Boedo on 6/16/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@_exported import Purchases

@objc public extension Purchases {
    func showManageSubscriptionModal() {

        self.purchaserInfo { purchaserInfo, error in
            if let error = error {
                print("there was an error getting purchaserInfo: \(error.localizedDescription)")
                return
            }

            guard let purchaserInfo = purchaserInfo else {
                print("there was no error but purchaserInfo is null!")
                return
            }

            guard let managementURL = purchaserInfo.managementURL else {
                print("managementURL is nil, opening iOS subscription management page")
                self.showAppleManageSubscriptions()
                return
            }

            if managementURL.isAppleSubscription() {
                if #available(iOS 15.0, *) {
                    detach {
                        await self.showSK2ManageSubscriptions()
                    }
                    return
                }
            }

            self.openURL(managementURL)
        }
    }
}

public extension Purchases {

    func showAppleManageSubscriptions() {
        if #available(iOS 15.0, *) {
            detach {
                await self.showSK2ManageSubscriptions()
            }
        } else {
            self.openURL(.appleSubscriptionsURL)
        }
    }

    @MainActor
    @available(iOS 15.0, *)
    func showSK2ManageSubscriptions() async {
        let windowScene = UIApplication.shared
            .connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first

        if let windowScene = windowScene as? UIWindowScene {

            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch let error {
                print("error when trying to show manage subscription: \(error.localizedDescription)")
            }
        } else {
            print("couldn't get window")
        }
    }

    func openURL(_ url: URL) {
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}

private extension URL {
    func isAppleSubscription() -> Bool {
        self.absoluteString.contains("apps.apple.com")
    }

    static let appleSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}
