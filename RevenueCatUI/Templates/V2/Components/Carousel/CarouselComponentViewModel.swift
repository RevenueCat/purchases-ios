//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CarouselComponentViewModel.swift
//
//  Created by Josh Holtz on 1/27/25.

import Foundation
import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

typealias PresentedCarouselPartial = PaywallComponent.PartialCarouselComponent

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class CarouselComponentViewModel {

    private let localizationProvider: LocalizationProvider
    let uiConfigProvider: UIConfigProvider
    private let component: PaywallComponent.CarouselComponent
    let pageStackViewModels: [StackComponentViewModel]

    private let presentedOverrides: PresentedOverrides<PresentedCarouselPartial>?

    init(
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider,
        component: PaywallComponent.CarouselComponent,
        pageStackViewModels: [StackComponentViewModel]
    ) {
        self.localizationProvider = localizationProvider
        self.uiConfigProvider = uiConfigProvider
        self.component = component
        self.pageStackViewModels = pageStackViewModels

        self.presentedOverrides = self.component.overrides?.toPresentedOverrides { $0 }
    }

    @ViewBuilder
    // swiftlint:disable:next function_parameter_count
    func styles(
        state: ComponentViewState,
        condition: ScreenCondition,
        isEligibleForIntroOffer: Bool,
        isEligibleForPromoOffer: Bool,
        colorScheme: ColorScheme,
        @ViewBuilder apply: @escaping (CarouselComponentStyle) -> some View
    ) -> some View {
        let partial = PresentedCarouselPartial.buildPartial(
            state: state,
            condition: condition,
            isEligibleForIntroOffer: isEligibleForIntroOffer,
            isEligibleForPromoOffer: isEligibleForPromoOffer,
            with: self.presentedOverrides
        )

        let style = CarouselComponentStyle(
            uiConfigProvider: self.uiConfigProvider,
            visible: partial?.visible ?? self.component.visible ?? true,
            size: partial?.size ?? self.component.size,
            padding: partial?.padding ?? self.component.padding,
            margin: partial?.margin ?? self.component.margin,
            background: partial?.background ?? self.component.background,
            shape: partial?.shape ?? self.component.shape,
            border: partial?.border ?? self.component.border,
            shadow: partial?.shadow ?? self.component.shadow,
            pageAlignment: partial?.pageAlignment ?? self.component.pageAlignment,
            pageSpacing: partial?.pageSpacing ?? self.component.pageSpacing,
            pagePeek: partial?.pagePeek ?? self.component.pagePeek,
            initialPageIndex: partial?.initialPageIndex ?? self.component.initialPageIndex,
            loop: partial?.loop ?? self.component.loop,
            autoAdvance: partial?.autoAdvance ?? self.component.autoAdvance,
            pageControl: partial?.pageControl ?? self.component.pageControl,
            colorScheme: colorScheme
        )

        apply(style)
    }

}

extension PresentedCarouselPartial: PresentedPartial {

    static func combine(
        _ base: PaywallComponent.PartialCarouselComponent?,
        with other: PaywallComponent.PartialCarouselComponent?
    ) -> Self {

        let visible = other?.visible ?? base?.visible
        let padding = other?.padding ?? base?.padding
        let margin = other?.margin ?? base?.margin
        let background = other?.background ?? base?.background
        let shape = other?.shape ?? base?.shape
        let border = other?.border ?? base?.border
        let shadow = other?.shadow ?? base?.shadow

        let pageAlignment = other?.pageAlignment ?? base?.pageAlignment
        let pageSpacing = other?.pageSpacing ?? base?.pageSpacing
        let pagePeek = other?.pagePeek ?? base?.pagePeek
        let initialPageIndex = other?.initialPageIndex ?? base?.initialPageIndex
        let loop = other?.loop ?? base?.loop
        let autoAdvance = other?.autoAdvance ?? base?.autoAdvance

        let pageControl = other?.pageControl ?? base?.pageControl

        return .init(
            visible: visible,
            padding: padding,
            margin: margin,
            background: background,
            shape: shape,
            border: border,
            shadow: shadow,
            pageAlignment: pageAlignment,
            pageSpacing: pageSpacing,
            pagePeek: pagePeek,
            initialPageIndex: initialPageIndex,
            loop: loop,
            autoAdvance: autoAdvance,
            pageControl: pageControl
        )
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct CarouselComponentStyle {

    let visible: Bool
    let size: PaywallComponent.Size
    let padding: EdgeInsets
    let margin: EdgeInsets
    let backgroundStyle: BackgroundStyle?
    let shape: ShapeModifier.Shape?
    let border: ShapeModifier.BorderInfo?
    let shadow: ShadowModifier.ShadowInfo?

    let pageAlignment: SwiftUI.VerticalAlignment
    let pageSpacing: CGFloat
    let pagePeek: CGFloat
    let initialPageIndex: Int
    let loop: Bool
    let autoAdvance: PaywallComponent.CarouselComponent.AutoAdvanceSlides?

    let pageControl: DisplayablePageControl?

    init(
        uiConfigProvider: UIConfigProvider,
        visible: Bool,
        size: PaywallComponent.Size?,
        padding: PaywallComponent.Padding?,
        margin: PaywallComponent.Padding?,
        background: PaywallComponent.Background?,
        shape: PaywallComponent.Shape?,
        border: PaywallComponent.Border?,
        shadow: PaywallComponent.Shadow?,
        pageAlignment: PaywallComponent.VerticalAlignment,
        pageSpacing: Int,
        pagePeek: Int,
        initialPageIndex: Int,
        loop: Bool,
        autoAdvance: PaywallComponent.CarouselComponent.AutoAdvanceSlides?,
        pageControl: PaywallComponent.CarouselComponent.PageControl?,
        colorScheme: ColorScheme
    ) {
        self.visible = visible
        self.size = size ?? .init(width: .fit, height: .fit)
        self.padding = (padding ?? .zero).edgeInsets
        self.margin = (margin ?? .zero).edgeInsets
        self.backgroundStyle = background?.asDisplayable(uiConfigProvider: uiConfigProvider)
        self.shape = shape?.shape
        self.border = border?.border(uiConfigProvider: uiConfigProvider)
        self.shadow = shadow?.shadow(uiConfigProvider: uiConfigProvider, colorScheme: colorScheme)
        self.pageAlignment = pageAlignment.stackAlignment
        self.pageSpacing = CGFloat(pageSpacing)
        self.pagePeek = CGFloat(pagePeek)
        self.initialPageIndex = initialPageIndex
        self.loop = loop
        self.autoAdvance = autoAdvance
        self.pageControl = pageControl.flatMap {
            DisplayablePageControl(uiConfigProvider: uiConfigProvider, pageControl: $0, colorScheme: colorScheme)
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DisplayablePageControl {

    let position: PaywallComponent.CarouselComponent.PageControl.Position
    let padding: EdgeInsets
    let margin: EdgeInsets
    let backgroundStyle: BackgroundStyle?
    let shape: ShapeModifier.Shape?
    let border: ShapeModifier.BorderInfo?
    let shadow: ShadowModifier.ShadowInfo?

    let spacing: CGFloat
    let active: DisplayablePageControlIndicator
    let `default`: DisplayablePageControlIndicator

    let uiConfigProvider: UIConfigProvider

    init(
        uiConfigProvider: UIConfigProvider,
        pageControl: PaywallComponent.CarouselComponent.PageControl,
        colorScheme: ColorScheme
    ) {
        self.position = pageControl.position
        self.padding = (pageControl.padding ?? .zero).edgeInsets
        self.margin = (pageControl.margin ?? .zero).edgeInsets
        self.backgroundStyle = pageControl.backgroundColor?.asDisplayable(
            uiConfigProvider: uiConfigProvider
        ).backgroundStyle
        self.shape = pageControl.shape?.shape
        self.border = pageControl.border?.border(uiConfigProvider: uiConfigProvider)
        self.shadow = pageControl.shadow?.shadow(uiConfigProvider: uiConfigProvider, colorScheme: colorScheme)

        self.spacing = CGFloat(pageControl.spacing)
        self.active = .init(
            uiConfigProvider: uiConfigProvider,
            pageControlIndicator: pageControl.active,
            colorScheme: colorScheme
        )
        self.default = .init(
            uiConfigProvider: uiConfigProvider,
            pageControlIndicator: pageControl.default,
            colorScheme: colorScheme
        )

        self.uiConfigProvider = uiConfigProvider
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DisplayablePageControlIndicator {

    let width: CGFloat
    let height: CGFloat
    let color: Color
    let strokeColor: Color
    let strokeWidth: CGFloat

    let uiConfigProvider: UIConfigProvider

    init(
        uiConfigProvider: UIConfigProvider,
        pageControlIndicator: PaywallComponent.CarouselComponent.PageControlIndicator,
        colorScheme: ColorScheme
    ) {
        self.width = CGFloat(pageControlIndicator.width)
        self.height = CGFloat(pageControlIndicator.height)

        let color = pageControlIndicator.color.asDisplayable(uiConfigProvider: uiConfigProvider)
            .toDynamicColor(with: colorScheme)
        self.color = color
        self.strokeColor = pageControlIndicator.strokeColor?
            .asDisplayable(uiConfigProvider: uiConfigProvider).toDynamicColor(with: colorScheme) ?? color
        self.strokeWidth = pageControlIndicator.strokeWidth ?? 0

        self.uiConfigProvider = uiConfigProvider
    }

}

#endif
