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
    var offeringId: String? = ProcessInfo.processInfo.environment["OFFERING_ID"]
    @State var offerings:[Offering] = []

    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal) {
                LazyHStack {
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
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .navigationTitle(offering.id)
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
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
                    offerings = loader.allOfferings.sorted(by: { a, b in
                        a.identifier < b.identifier
                    })
                }
                catch {
                    print(error)
                }
            }
        }
    }
    
}

#Preview {
    PaywallValidationTesterView(offeringId: "Multi-tier 1")
}
