//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SlotComponentViewModel.swift
//
//  Created by Josh Holtz on 8/15/25.

import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

typealias PresentedSlotPartial = PaywallComponent.PartialSlotComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class SlotComponentViewModel {

    private let localizationProvider: LocalizationProvider
    private let component: PaywallComponent.SlotComponent

    private let presentedOverrides: PresentedOverrides<PresentedSlotPartial>?

    init(
        localizationProvider: LocalizationProvider,
        component: PaywallComponent.SlotComponent
    ) throws {
        self.localizationProvider = localizationProvider
        self.component = component

        self.presentedOverrides = try self.component.overrides?.toPresentedOverrides { $0 }
    }

    var identifier: String {
        return component.identifier
    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        @ViewBuilder apply: @escaping (SlotComponentStyle) -> some View
    ) -> some View {
        let partial = PresentedSlotPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: self.presentedOverrides
        )

        let style = SlotComponentStyle(
            visible: partial?.visible ?? self.component.visible ?? true,
            size: partial?.size ?? self.component.size,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin
        )

        apply(style)
    }

}


extension PresentedSlotPartial: PresentedPartial {

    static func combine(
        _ base: PaywallComponent.PartialSlotComponent?,
        with other: PaywallComponent.PartialSlotComponent?
    ) -> Self {

        let visible = other?.visible ?? base?.visible
        let size = other?.size ?? base?.size
        let padding = other?.padding ?? base?.padding
        let margin = other?.margin ?? base?.margin

        return .init(
            visible: visible,
            size: size,
            padding: padding,
            margin: margin
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SlotComponentStyle {

    let visible: Bool
    let size: PaywallComponent.Size
    let padding: EdgeInsets
    let margin: EdgeInsets

    init(
        visible: Bool,
        size: PaywallComponent.Size?,
        padding: PaywallComponent.Padding?,
        margin: PaywallComponent.Padding?,
    ) {
        self.visible = visible
        self.size = size ?? .init(width: .fit, height: .fit)
        self.padding = (padding ?? .zero).edgeInsets
        self.margin = (margin ?? .zero).edgeInsets
    }

}

#endif
