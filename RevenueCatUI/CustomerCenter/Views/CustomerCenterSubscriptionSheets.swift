//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterSubscriptionSheets.swift
//
//  Created by Monika on 6/10/2026.

import SwiftUI

#if os(iOS)
@available(iOS 15.0, *)
struct CustomerCenterSubscriptionSheets: ViewModifier {
    let provider: CustomerCenterPurchasesType
    @Binding var manage: Bool
    @Binding var plans: Bool
    let currentProductID: String?
    let groupID: String?
    let productIDs: [String]

    @ViewBuilder func body(content: Content) -> some View {
        if let preview = provider as? CustomerCenterPreviewProvider {
            content
                .modifier(CustomerCenterPreviewActionModifier(
                    provider: preview, isPresented: $manage, action: .manageSubscriptions
                ))
                .modifier(CustomerCenterPreviewActionModifier(
                    provider: preview, isPresented: $plans,
                    action: .changePlans(currentProductID: currentProductID,
                                         productIDs: productIDs, subscriptionGroupID: groupID)
                ))
        } else {
            content
                .modifier(provider.manageSubscriptionsSheetViewModifier(
                    isPresented: $manage, subscriptionGroupID: groupID
                ))
                .modifier(provider.changePlansSheetViewModifier(
                    isPresented: $plans, subscriptionGroupID: groupID, productIDs: productIDs
                ))
        }
    }
}
#endif
