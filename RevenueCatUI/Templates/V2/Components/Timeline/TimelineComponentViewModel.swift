//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TimelineComponentViewModel.swift
//
//  Created by Mark Villacampa on 15/1/25.

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

typealias PresentedTimelinePartial = PaywallComponent.PartialTimelineComponent

typealias PresentedTimelineItemPartial = PaywallComponent.PartialTimelineItem

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TimelineComponentViewModel {

    private let component: PaywallComponent.TimelineComponent
    let items: [TimelineItemViewModel]
    let uiConfigProvider: UIConfigProvider
    let id = UUID()

    private let presentedOverrides: PresentedOverrides<PresentedTimelinePartial>?

    init(
        component: PaywallComponent.TimelineComponent,
        items: [TimelineItemViewModel],
        uiConfigProvider: UIConfigProvider
    ) {
        self.component = component
        self.items = items
        self.uiConfigProvider = uiConfigProvider

        self.presentedOverrides = self.component.overrides?.toPresentedOverrides { $0 }
    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        @ViewBuilder apply: @escaping (TimelineComponentStyle) -> some View
    ) -> some View {
        let partial = PresentedTimelinePartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: self.presentedOverrides
        )

        let style = TimelineComponentStyle(
            uiConfigProvider: self.uiConfigProvider,
            visible: partial?.visible ?? self.component.visible ?? true,
            iconAlignment: partial?.iconAlignment ?? self.component.iconAlignment,
            itemSpacing: partial?.itemSpacing ?? self.component.itemSpacing,
            textSpacing: partial?.textSpacing ?? self.component.textSpacing,
            columnGutter: partial?.columnGutter ?? self.component.columnGutter,
            size: partial?.size ?? self.component.size,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin
        )

        apply(style)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TimelineItemViewModel {

    let id = UUID()
    let component: PaywallComponent.TimelineComponent.Item
    let title: TextComponentViewModel
    let description: TextComponentViewModel?
    let icon: IconComponentViewModel

    private let presentedOverrides: PresentedOverrides<PresentedTimelineItemPartial>?

    init(component: PaywallComponent.TimelineComponent.Item,
         title: TextComponentViewModel,
         description: TextComponentViewModel?,
         icon: IconComponentViewModel) {
        self.component = component
        self.title = title
        self.description = description
        self.icon = icon
        self.presentedOverrides = component.overrides?.toPresentedOverrides { $0 }
    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        @ViewBuilder apply: @escaping (TimelineItemStyle) -> some View
    ) -> some View {
        let partial = PresentedTimelineItemPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: self.presentedOverrides
        )

        let style = TimelineItemStyle(
            id: self.id,
            visible: partial?.visible ?? true,
            connector: partial?.connector ?? self.component.connector,
            title: self.title,
            description: self.description,
            icon: self.icon
        )

        apply(style)
    }

}

extension PresentedTimelinePartial: PresentedPartial {

    static func combine(
        _ base: PaywallComponent.PartialTimelineComponent?,
        with other: PaywallComponent.PartialTimelineComponent?
    ) -> Self {

        let visible = other?.visible ?? base?.visible
        let iconAlignment = other?.iconAlignment ?? base?.iconAlignment
        let itemSpacing = other?.itemSpacing ?? base?.itemSpacing
        let textSpacing = other?.textSpacing ?? base?.textSpacing
        let columnGutter = other?.columnGutter ?? base?.columnGutter
        let size = other?.size ?? base?.size
        let padding = other?.padding ?? base?.padding
        let margin = other?.margin ?? base?.margin

        return .init(
            visible: visible,
            iconAlignment: iconAlignment,
            itemSpacing: itemSpacing,
            textSpacing: textSpacing,
            columnGutter: columnGutter,
            size: size,
            padding: padding,
            margin: margin
        )
    }

}

extension PresentedTimelineItemPartial: PresentedPartial {

    static func combine(
        _ base: PaywallComponent.PartialTimelineItem?,
        with other: PaywallComponent.PartialTimelineItem?
    ) -> Self {

        let connector = other?.connector ?? base?.connector
        let visible = other?.visible ?? base?.visible

        return .init(
            visible: visible,
            connector: connector
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TimelineComponentStyle {

    let visible: Bool
    let iconAlignment: PaywallComponent.TimelineComponent.IconAlignment?
    let itemSpacing: CGFloat?
    let textSpacing: CGFloat?
    let columnGutter: CGFloat?
    let size: PaywallComponent.Size
    let padding: EdgeInsets
    let margin: EdgeInsets

    init(
        uiConfigProvider: UIConfigProvider,
        visible: Bool,
        iconAlignment: PaywallComponent.TimelineComponent.IconAlignment?,
        itemSpacing: CGFloat?,
        textSpacing: CGFloat?,
        columnGutter: CGFloat?,
        size: PaywallComponent.Size,
        padding: PaywallComponent.Padding,
        margin: PaywallComponent.Padding
    ) {
        self.visible = visible
        self.iconAlignment = iconAlignment
        self.itemSpacing = itemSpacing
        self.textSpacing = textSpacing
        self.columnGutter = columnGutter
        self.size = size
        self.padding = padding.edgeInsets
        self.margin = margin.edgeInsets
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TimelineItemStyle {

    let visible: Bool
    let id: UUID
    let connector: PaywallComponent.TimelineComponent.Connector?
    let title: TextComponentViewModel
    let description: TextComponentViewModel?
    let icon: IconComponentViewModel

    init(
        id: UUID,
        visible: Bool,
        connector: PaywallComponent.TimelineComponent.Connector?,
        title: TextComponentViewModel,
        description: TextComponentViewModel?,
        icon: IconComponentViewModel
    ) {
        self.id = id
        self.visible = visible
        self.connector = connector
        self.title = title
        self.description = description
        self.icon = icon
    }

}

#endif
