//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOfferView.swift
//
//
//  Created by Cesar de la Vega on 17/6/24.
//

import RevenueCat
import StoreKit
import SwiftUI

@available(iOS 15.0, *)
struct PromotionalOfferView: View {

    let promotionalOffer: CustomerCenterConfigData.HelpPath.PromotionalOffer

    var body: some View {
        VStack {
            Text("Special Promotional Offer!")
                .font(.largeTitle)
                .padding()

            Button("Redeem Offer") {
                redeemOffer(promotionalOffer)
            }
            .buttonStyle(ManageSubscriptionsButtonStyle())
        }
        .padding()
    }

    private func redeemOffer(_ offer: CustomerCenterConfigData.HelpPath.PromotionalOffer) {

    }

}
