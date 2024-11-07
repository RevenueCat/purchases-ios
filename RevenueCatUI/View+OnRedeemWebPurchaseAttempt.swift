//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+OnRedeemWebPurchaseAttempt.swift
//
//  Created by Antonio Rico Diez on 7/11/24.

import SwiftUI
import RevenueCat

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
extension View {

    public func onWebPurchaseRedemptionAttempt(
        perform completion: @escaping @Sendable (WebPurchaseRedemptionResult) -> Void
    ) -> some View {
        return self.modifier(PresentingPaywallModifier(completion: completion))
    }
}

@available(iOS 14.0, macOS 11.0, tvOS 14.0, watchOS 7.0, *)
private struct PresentingPaywallModifier: ViewModifier {

    var completion: (WebPurchaseRedemptionResult) -> Void

    init(completion: @escaping @Sendable (WebPurchaseRedemptionResult) -> Void) {
        self.completion = completion
    }

    func body(content: Content) -> some View {
        content.onOpenURL { url in
            if let webPurchaseRedemption = Purchases.parseAsWebPurchaseRedemption(url),
                Purchases.isConfigured {
                Task {
                    let result = await Purchases.shared.redeemWebPurchase(webPurchaseRedemption)
                    completion(result)
                }
            }
        }
    }
}
