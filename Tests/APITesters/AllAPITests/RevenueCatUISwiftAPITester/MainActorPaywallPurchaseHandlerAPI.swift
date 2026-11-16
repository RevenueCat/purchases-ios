//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation
import RevenueCat
import RevenueCatUI

#if canImport(UIKit) && !os(tvOS) && !os(watchOS)

@available(iOS 15.0, *)
@MainActor
private final class MainActorPaywallPurchaseHandler: NSObject, PaywallPurchaseHandlerWithContext {

    func performPurchase(
        with context: PaywallPurchaseContext,
        completion: @escaping (Bool, Error?) -> Void
    ) {
        let _: Package = context.package
        let _: PromotionalOffer? = context.promotionalOffer
        completion(false, nil)
    }

    func performRestore(completion: @escaping (Bool, Error?) -> Void) {
        completion(true, nil)
    }

}

@available(iOS 15.0, *)
@MainActor
func checkMainActorPaywallPurchaseHandlerAPI() {
    let handler = MainActorPaywallPurchaseHandler()
    let _ = PaywallViewController(purchaseHandlerWithContext: handler)
    let _ = PaywallFooterViewController(purchaseHandlerWithContext: handler)
}

#endif
