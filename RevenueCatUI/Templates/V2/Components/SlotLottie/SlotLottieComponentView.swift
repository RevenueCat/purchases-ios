//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SlotComponentView.swift
//
//  Created by Josh Holtz on 8/15/25.

import Foundation
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SlotLottieComponentView: View {

    @EnvironmentObject
    private var packageContext: PackageContext

    @EnvironmentObject
    private var introOfferEligibilityContext: IntroOfferEligibilityContext

    @EnvironmentObject
    private var paywallPromoOfferCache: PaywallPromoOfferCache

    @Environment(\.componentViewState)
    private var componentViewState

    @Environment(\.screenCondition)
    private var screenCondition

    @EnvironmentObject
    private var viewRegistry: ViewRegistry

    let viewModel: SlotLottieComponentViewModel

    var body: some View {
        self.viewModel.styles(
            state: self.componentViewState,
            condition: self.screenCondition,
            isEligibleForIntroOffer: self.introOfferEligibilityContext.isEligible(
                package: self.packageContext.package
            ),
            isEligibleForPromoOffer: self.paywallPromoOfferCache.isMostLikelyEligible(
                for: self.packageContext.package
            )
        ) { style in
            self.viewRegistry.makeView(
                component: .slotLottie(viewModel.component)
            )
            // Style the carousel
            .size(style.size)
            .padding(style.padding)
            .padding(style.margin)
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SlotLottieComponentView_Previews: PreviewProvider {

    static let viewRegistry: ViewRegistry = {
        let viewRegister = ViewRegistry()
        viewRegister.register(type: .slotLottie) { _ in
            Text("Lottie goes here")
        }
        return viewRegister
    }()

    // Need to wrap in VStack otherwise preview rerenders and images won't show
    static var previews: some View {

        // Default
        VStack {
            SlotLottieComponentView(
                // swiftlint:disable:next force_try
                viewModel: try! .init(
                    localizationProvider: .init(
                        locale: Locale.current,
                        localizedStrings: [:]
                    ),
                    component: .init(
                        identifier: "",
                        value: .url(URL(string: "https://something.com")!)
                    )
                )
            )
        }
        .environmentObject(viewRegistry)
        .previewRequiredPaywallsV2Properties()
        .previewLayout(.fixed(width: 100, height: 100))
        .previewDisplayName("Default")

    }
}

#endif

#endif
