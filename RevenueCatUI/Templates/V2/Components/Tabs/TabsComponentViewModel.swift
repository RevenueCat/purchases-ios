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

#if !os(tvOS) // For Paywalls V2

typealias PresentedTabsPartial = PaywallComponent.PartialTabsComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TabsComponentViewModel {

    private let component: PaywallComponent.TabsComponent
    let uiConfigProvider: UIConfigProvider
    private let presentedOverrides: PresentedOverrides<PresentedTabsPartial>?

    let controlStackViewModel: StackComponentViewModel
    let tabViewModels: [String: TabViewModel]
    let tabIds: [String]
    let defaultTabId: String?

    init(
        component: PaywallComponent.TabsComponent,
        controlStackViewModel: StackComponentViewModel,
        tabViewModels: [TabViewModel],
        uiConfigProvider: UIConfigProvider
    ) {
        self.component = component
        self.controlStackViewModel = controlStackViewModel
        self.tabViewModels = Dictionary(uniqueKeysWithValues: tabViewModels.map { tabViewModel in
            return (tabViewModel.tab.id, tabViewModel)
        })
        self.tabIds = tabViewModels.map(\.tab.id)
        self.defaultTabId = component.defaultTabId
        self.uiConfigProvider = uiConfigProvider

        self.presentedOverrides = self.component.overrides?.toPresentedOverrides { $0 }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TabViewModel {

    let tab: PaywallComponent.TabsComponent.Tab
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
        let background = other?.background ?? base?.background
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
            background: background,
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
        shadow: PaywallComponent.Shadow?,
        colorScheme: ColorScheme
    ) {
        self.visible = visible
        self.size = size
        self.backgroundStyle = backgroundColor?.asDisplayable(uiConfigProvider: uiConfigProvider).backgroundStyle
        self.padding = padding.edgeInsets
        self.margin = margin.edgeInsets
        self.shape = shape?.shape
        self.border = border?.border(uiConfigProvider: uiConfigProvider)
        self.shadow = shadow?.shadow(uiConfigProvider: uiConfigProvider, colorScheme: colorScheme)
    }

}

#endif
