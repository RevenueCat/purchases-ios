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

public extension Purchases {
    @inlinable public func showManageSubscriptionModal() {
        if let windowScene = self.view.window?.windowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                // handle error
            }
        }
    }
}

public class Foo {
    public init() { }

    public func bar() {
        print("totally foobar")
    }
}
