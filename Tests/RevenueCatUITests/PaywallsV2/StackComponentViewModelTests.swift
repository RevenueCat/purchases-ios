//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Nimble
@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI
import XCTest

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class StackComponentViewModelTests: TestCase {

    @MainActor
    func testStylesDefaultNilSpacingToZero() {
        let viewModel = StackComponentViewModel(
            component: PaywallComponent.StackComponent(components: []),
            viewModels: [],
            badgeViewModels: [],
            uiConfigProvider: UIConfigProvider(uiConfig: PreviewUIConfig.make())
        )

        let style = viewModel.styles(
            state: .default,
            condition: .compact,
            isEligibleForIntroOffer: false,
            isEligibleForPromoOffer: false,
            selectedPackageId: nil,
            customVariables: [:],
            colorScheme: .light
        )

        expect(style.spacing).to(equal(0))
    }

}

#endif
