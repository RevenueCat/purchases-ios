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
        if #available(iOS 15.0, *) {
            detach {
                await self.showSK2ManageSubscriptions()
            }
        } else {
            self.showSK1ManageSubscriptions()
        }
    }
}

public extension Purchases {
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

    func showSK1ManageSubscriptions() {
        self.purchaserInfo { purchaserInfo, error in
            if let error = error {
                print("there was an error getting purchaserInfo: \(error.localizedDescription)")
                return
            }

            if let purchaserInfo = purchaserInfo,
               let managementURL = purchaserInfo.managementURL {
                self.openURL(managementURL)
            } else {
                print("no management URL avaialable, opening support instead")
                let supportURL = URL(string: "https://support.revenuecat.com")!
                self.openURL(supportURL)
            }
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

public class Foo {
    public init() { }

    public func bar() {
        print("totally foobar")
    }
}
