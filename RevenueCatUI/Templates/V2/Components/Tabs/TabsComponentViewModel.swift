//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsComponentViewModel.swift
//
//  Created by Josh Holtz on 1/9/25.

import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

typealias PresentedTabsPartial = PaywallComponent.PartialTabsComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TabsComponentViewModel {

    private let component: PaywallComponent.TabsComponent
    let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedTabsPartial>?

    let controlStackViewModel: StackComponentViewModel
    let tabViewModels: [TabViewModel]

    init(
        component: PaywallComponent.TabsComponent,
        controlStackViewModel: StackComponentViewModel,
        tabViewModels: [TabViewModel],
        uiConfigProvider: UIConfigProvider
    ) throws {
        self.component = component
        self.controlStackViewModel = controlStackViewModel
        self.tabViewModels = tabViewModels
        self.uiConfigProvider = uiConfigProvider

        self.presentedOverrides = try self.component.overrides?.toPresentedOverrides { $0 }
    }

    @ViewBuilder
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        @ViewBuilder apply: @escaping (TabsComponentStyle) -> some View
    ) -> some View {
        let partial = PresentedTabsPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            with: self.presentedOverrides
        )

        let style = TabsComponentStyle(
            uiConfigProvider: self.uiConfigProvider,
            visible: partial?.visible ?? self.component.visible ?? true,
            size: partial?.size ?? self.component.size,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin,
            backgroundColor: partial?.backgroundColor ?? self.component.backgroundColor,
            shape: partial?.shape ?? self.component.shape,
            border: partial?.border ?? self.component.border,
            shadow: partial?.shadow ?? self.component.shadow
        )

        apply(style)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TabViewModel {

    private let tab: PaywallComponent.TabsComponent.Tab
    let uiConfigProvider: UIConfigProvider
    let stackViewModel: StackComponentViewModel
    let defaultSelectedPackage: Package?
    let packages: [Package]

    init(
        tab: PaywallComponent.TabsComponent.Tab,
        stackViewModel: StackComponentViewModel,
        defaultSelectedPackage: Package?,
        packages: [Package],
        uiConfigProvider: UIConfigProvider
    ) throws {
        self.tab = tab
        self.stackViewModel = stackViewModel
        self.defaultSelectedPackage = defaultSelectedPackage
        self.packages = packages
        self.uiConfigProvider = uiConfigProvider
    }

}

extension PresentedTabsPartial: PresentedPartial {

    static func combine(
        _ base: PaywallComponent.PartialTabsComponent?,
        with other: PaywallComponent.PartialTabsComponent?
    ) -> Self {

        let visible = other?.visible ?? base?.visible
        let size = other?.size ?? base?.size
        let backgroundColor = other?.backgroundColor ?? base?.backgroundColor
        let padding = other?.padding ?? base?.padding
        let margin = other?.margin ?? base?.margin
        let shape = other?.shape ?? base?.shape
        let border = other?.border ?? base?.border
        let shadow = other?.shadow ?? base?.shadow

        return .init(
            visible: visible,
            size: size,
            padding: padding,
            margin: margin,
            backgroundColor: backgroundColor,
            shape: shape,
            border: border,
            shadow: shadow
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TabsComponentStyle {

    let visible: Bool
    let size: PaywallComponent.Size
    let backgroundStyle: BackgroundStyle?
    let padding: EdgeInsets
    let margin: EdgeInsets
    let shape: ShapeModifier.Shape?
    let border: ShapeModifier.BorderInfo?
    let shadow: ShadowModifier.ShadowInfo?

    init(
        uiConfigProvider: UIConfigProvider,
        visible: Bool,
        size: PaywallComponent.Size,
        padding: PaywallComponent.Padding,
        margin: PaywallComponent.Padding,
        backgroundColor: PaywallComponent.ColorScheme?,
        shape: PaywallComponent.Shape?,
        border: PaywallComponent.Border?,
        shadow: PaywallComponent.Shadow?
    ) {
        self.visible = visible
        self.size = size
        self.backgroundStyle = backgroundColor?.asDisplayable(uiConfigProvider: uiConfigProvider).backgroundStyle
        self.padding = padding.edgeInsets
        self.margin = margin.edgeInsets
        self.shape = shape?.shape
        self.border = border?.border(uiConfigProvider: uiConfigProvider)
        self.shadow = shadow?.shadow(uiConfigProvider: uiConfigProvider)
    }

}

#endif
