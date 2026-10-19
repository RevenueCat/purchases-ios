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
@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallComponentViewModel {

    case root(RootViewModel)
    case text(TextComponentViewModel)
    case image(ImageComponentViewModel)
    case icon(IconComponentViewModel)
    case stack(StackComponentViewModel)
    case button(ButtonComponentViewModel)
    case package(PackageComponentViewModel)
    case purchaseButton(PurchaseButtonComponentViewModel)
    case stickyFooter(StickyFooterComponentViewModel)
    case timeline(TimelineComponentViewModel)

    case tabs(TabsComponentViewModel)
    case tabControl(TabControlComponentViewModel)
    case tabControlButton(TabControlButtonComponentViewModel)
    case tabControlToggle(TabControlToggleComponentViewModel)

    case carousel(CarouselComponentViewModel)
    case video(VideoComponentViewModel)
    case countdown(CountdownComponentViewModel)
    case webView(WebViewComponentViewModel)
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Array where Element == PaywallComponentViewModel {
    /// Filter original indices so promoting a button preserves every sibling's view identity.
    func indicesExcludingNativeButtons(
        _ hiddenButtons: Set<ObjectIdentifier>, invisibleButtons: Set<ObjectIdentifier>
    ) -> [Int] {
        self.indices.filter { index in
            if case .button(let button) = self[index] {
                return !hiddenButtons.contains(ObjectIdentifier(button))
            }
            if case .stack(let stack) = self[index], let buttons = stack.nativeButtonContainerIdentifiers {
                // Only promotion can remove an authored wrapper. Hidden secondary buttons do not keep it alive.
                return buttons.isDisjoint(with: hiddenButtons)
                    || !buttons.isSubset(of: hiddenButtons.union(invisibleButtons))
            }
            return true
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallComponentViewModel {
    var nativeMediaIdentifier: ObjectIdentifier? {
        switch self {
        case .image(let model): return ObjectIdentifier(model)
        case .video(let model): return ObjectIdentifier(model)
        case .webView(let model): return ObjectIdentifier(model)
        default: return nil
        }
    }

    var firstNativeMediaIdentifier: ObjectIdentifier? {
        if case .stack(let model) = self {
            return model.viewModels.first?.firstNativeMediaIdentifier
        }
        return self.nativeMediaIdentifier
    }
}

#endif
