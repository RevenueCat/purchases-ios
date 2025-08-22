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

typealias PresentedSlotLottiePartial = PaywallComponent.PartialSlotLottieComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class SlotLottieComponentViewModel {

    private let localizationProvider: LocalizationProvider
    let component: PaywallComponent.SlotLottieComponent

    private let presentedOverrides: PresentedOverrides<PresentedSlotLottiePartial>?

    init(
        localizationProvider: LocalizationProvider,
        component: PaywallComponent.SlotLottieComponent
    ) throws {
        self.localizationProvider = localizationProvider
        self.component = component

        self.presentedOverrides = try self.component.overrides?.toPresentedOverrides { $0 }
    }

    var url: URL? {
        switch self.component.value {
        case .url(let url):
            return url
        case .unknown:
            return nil
        }
    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        @ViewBuilder apply: @escaping (SlotLottieComponentStyle) -> some View
    ) -> some View {
        let partial = PresentedSlotLottiePartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: self.presentedOverrides
        )

        let style = SlotLottieComponentStyle(
            visible: partial?.visible ?? self.component.visible ?? true,
            value: partial?.value ?? self.component.value,
            size: partial?.size ?? self.component.size,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin
        )

        apply(style)
    }

}

extension PresentedSlotLottiePartial: PresentedPartial {

    static func combine(
        _ base: PaywallComponent.PartialSlotLottieComponent?,
        with other: PaywallComponent.PartialSlotLottieComponent?
    ) -> Self {

        let visible = other?.visible ?? base?.visible
        let value = other?.value ?? base?.value
        let size = other?.size ?? base?.size
        let padding = other?.padding ?? base?.padding
        let margin = other?.margin ?? base?.margin

        return .init(
            visible: visible,
            value: value,
            size: size,
            padding: padding,
            margin: margin
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct SlotLottieComponentStyle {

    let visible: Bool
    let value: PaywallComponent.SlotLottieComponent.Value
    let size: PaywallComponent.Size
    let explicitWidth: CGFloat?
    let explicitHeight: CGFloat?
    let padding: EdgeInsets
    let margin: EdgeInsets

    init(
        visible: Bool,
        value: PaywallComponent.SlotLottieComponent.Value,
        size: PaywallComponent.Size?,
        padding: PaywallComponent.Padding?,
        margin: PaywallComponent.Padding?
    ) {
        let forSureSize = size ?? .init(width: .fit, height: .fit)

        self.visible = visible
        self.value = value
        self.size = forSureSize
        self.padding = (padding ?? .zero).edgeInsets
        self.margin = (margin ?? .zero).edgeInsets

//        switch forSureSize.width {
//        case .fit, .fill, .relative:
//            self.explicitWidth = nil
//        case .fixed(let value):
//            self.explicitWidth = CGFloat(value)
//        }
//
//        switch forSureSize.height {
//        case .fit, .fill, .relative:
//            self.explicitHeight = nil
//        case .fixed(let value):
//            self.explicitHeight = CGFloat(value)
//        }

        self.explicitWidth = 100
        self.explicitHeight = 100
    }

}

#endif
