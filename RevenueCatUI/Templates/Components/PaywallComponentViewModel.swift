//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallComponentViewModel.swift
//
//  Created by Josh Holtz on 11/7/24.

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallComponentViewModel {

    case root(RootViewModel)
    case text(TextComponentViewModel)
    case image(ImageComponentViewModel)
    case spacer(SpacerComponentViewModel)
    case stack(StackComponentViewModel)
    case linkButton(LinkButtonComponentViewModel)
    case button(ButtonComponentViewModel)
    case package(PackageComponentViewModel)
    case purchaseButton(PurchaseButtonComponentViewModel)
    case stickyFooter(StickyFooterComponentViewModel)

}

#endif
