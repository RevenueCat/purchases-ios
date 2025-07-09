//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallValidationTesterView.swift
//
//  Created by Chris Vasselli on 2025/07/09.

import SwiftUI
import RevenueCat
@testable import RevenueCatUI

struct PaywallValidationTesterView: View {
    var offeringId: String? = nil
    @State var offerings:[Offering] = []

    var body: some View {
        TabView {
            ForEach(offerings, id: \.self) { offering in
                if offering.id == offeringId || offeringId == nil {
                    PaywallView(
                        configuration: .init(
                            offering: offering,
                            customerInfo: TestData.customerInfo,
                            mode: .default,
                            fonts: DefaultPaywallFontProvider(),
                            introEligibility: .producing(eligibility: .eligible),
                            purchaseHandler: .mock(preferredLocaleOverride: nil)
                        )
                    )
                }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea()
        .onAppear {
            guard let resourcesFolderURL = Bundle.main.url(
                forResource: "paywall-preview-resources", withExtension: nil
            ) else {
                return
            }

            let baseResourcesURL = resourcesFolderURL
                .appendingPathComponent("resources")

            do {
                let loader = try PaywallPreviewResourcesLoader(baseResourcesURL: baseResourcesURL)
                offerings = loader.allOfferings
            }
            catch {
                print(error)
            }
        }
    }
    
}

#Preview {
    PaywallValidationTesterView(offeringId: "app_51612306-paywall_pwbcb8845a57024e7d")
}
