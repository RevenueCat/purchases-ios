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
    @objc func showManageSubscriptionModal() {

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

            #if os(iOS)
            if managementURL.isAppleSubscription() {
                if #available(iOS 15.0, *) {
                    detach {
                        await self.showSK2ManageSubscriptions()
                    }
                }
                return
            }
            #endif
            self.openURL(managementURL)
        }
    }
}

public extension Purchases {

    @available(iOS 9.0, *)
    @available(macOS 10.12, *)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showAppleManageSubscriptions() {
#if os(iOS)
        if #available(iOS 15.0, *) {
            detach {
                await self.showSK2ManageSubscriptions()
            }
        } else {
            self.openURL(.appleSubscriptionsURL)
        }
#elseif os(macOS)
        self.openURL(.appleSubscriptionsURL)
#endif
    }

    @MainActor
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    func showSK2ManageSubscriptions() async {
        #if os(iOS)
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
        #endif
    }

    func openURL(_ url: URL) {
#if os(iOS)
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            UIApplication.shared.openURL(url)
        }
#elseif os(macOS)
        NSWorkspace.shared.open(url)
#endif
    }
}

private extension URL {
    func isAppleSubscription() -> Bool {
        self.absoluteString.contains("apps.apple.com")
    }

    static let appleSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
}
