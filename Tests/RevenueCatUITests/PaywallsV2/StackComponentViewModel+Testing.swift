//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

@_spi(Internal) @testable import RevenueCat
@_spi(Internal) @testable import RevenueCatUI

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension StackComponentViewModel {

    /// A stack that isn't on the path to a hero, which is what tests building a stack directly want.
    convenience init(
        component: PaywallComponent.StackComponent,
        viewModels: [PaywallComponentViewModel],
        badgeViewModels: [BadgeContents],
        uiConfigProvider: UIConfigProvider,
        discardRules: Bool = false
    ) {
        self.init(
            component: component,
            viewModels: viewModels,
            badgeViewModels: badgeViewModels,
            uiConfigProvider: uiConfigProvider,
            discardRules: discardRules,
            isOnHeroPath: false
        )
    }

}

#endif
