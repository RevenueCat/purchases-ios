//
//  RedeemWebPurchasesAPI.swift
//  RevenueCatUISwiftAPITester
//
//  Created by Toni Rico on 11/07/24.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
struct RedeemWebPurchases: View {

    private var completion: (WebPurchaseRedemptionResult) -> Void = { _ in }

    var body: some View {
        self.content
    }

    // Note: `body` is implicitly `MainActor`, but this is not on purpose
    // to ensure that these constructors can be called outside of `@MainActor`.
    @ViewBuilder
    var content: some View {
        Text("")
            .onWebPurchaseRedemptionAttempt(perform: completion)
            .onWebPurchaseRedemptionAttempt { _ in }
    }
}
