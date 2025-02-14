//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallCarouselComponent.swift
//
//  Created by Josh Holtz on 1/26/25.
// swiftlint:disable missing_docs nesting

import Foundation

public extension PaywallComponent {

    final class CarouselComponent: PaywallComponentBase {

        public struct AutoAdvanceSlides: PaywallComponentBase {

            public let msTimePerPage: Int
            public let msTransitionTime: Int

            public init(msTimePerPage: Int, msTransitionTime: Int) {
                self.msTimePerPage = msTimePerPage
                self.msTransitionTime = msTransitionTime
            }

        }

        public struct PageControl: PaywallComponentBase {

            public enum Position: String, Codable, Sendable, Hashable, Equatable {
                case top
                case bottom
            }

            public let position: Position
            public let padding: Padding?
            public let margin: Padding?
            public let backgroundColor: ColorScheme?
            public let shape: Shape?
            public let border: Border?
            public let shadow: Shadow?

            public let spacing: Int
            public let `default`: PageControlIndicator
            public let active: PageControlIndicator

            public init(
                position: Position,
                padding: Padding?,
                margin: Padding?,
                backgroundColor: ColorScheme?,
                shape: Shape?,
                border: Border?,
                shadow: Shadow?,
                spacing: Int,
                default: PageControlIndicator,
                active: PageControlIndicator
            ) {
                self.position = position
                self.padding = padding
                self.margin = margin
                self.backgroundColor = backgroundColor
                self.shape = shape
                self.border = border
                self.shadow = shadow
                self.spacing = spacing
                self.default = `default`
                self.active = active
            }

        }

        public struct PageControlIndicator: PaywallComponentBase {

            public let width: Int
            public let height: Int
            public let color: ColorScheme

            public init(width: Int, height: Int, color: ColorScheme) {
                self.width = width
                self.height = height
                self.color = color
            }

        }

        let type: ComponentType

        public let visible: Bool?
        public let size: Size?
        public let padding: Padding?
        public let margin: Padding?
        public let background: Background?
        public let shape: Shape?
        public let border: Border?
        public let shadow: Shadow?

        public let pages: [StackComponent]
        public let pageAlignment: VerticalAlignment
        public let pageSpacing: Int
        public let pagePeek: Int
        public let initialPageIndex: Int
        public let loop: Bool
        public let autoAdvance: AutoAdvanceSlides?

        public let pageControl: PageControl?

        public let overrides: ComponentOverrides<PartialCarouselComponent>?

        public init(
            visible: Bool? = nil,
            size: PaywallComponent.Size? = nil,
            padding: PaywallComponent.Padding? = .zero,
            margin: PaywallComponent.Padding? = .zero,
            background: PaywallComponent.Background? = nil,
            shape: PaywallComponent.Shape? = nil,
            border: PaywallComponent.Border? = nil,
            shadow: PaywallComponent.Shadow? = nil,
            pages: [PaywallComponent.StackComponent],
            pageAlignment: PaywallComponent.VerticalAlignment = .center,
            pageSpacing: Int = 0,
            pagePeek: Int = 20,
            initialPageIndex: Int = 0,
            loop: Bool = false,
            autoAdvance: PaywallComponent.CarouselComponent.AutoAdvanceSlides? = nil,
            pageControl: PageControl? = nil,
            overrides: ComponentOverrides<PartialCarouselComponent>? = nil
        ) {
            self.type = .carousel

            self.visible = visible
            self.size = size
            self.padding = padding
            self.margin = margin
            self.background = background
            self.shape = shape
            self.border = border
            self.shadow = shadow
            self.pages = pages
            self.pageAlignment = pageAlignment
            self.pageSpacing = pageSpacing
            self.pagePeek = pagePeek
            self.initialPageIndex = initialPageIndex
            self.loop = loop
            self.autoAdvance = autoAdvance
            self.pageControl = pageControl
            self.overrides = overrides
        }

        public static func == (lhs: CarouselComponent, rhs: CarouselComponent) -> Bool {
            return lhs.type == rhs.type &&
                lhs.visible == rhs.visible &&
                lhs.size == rhs.size &&
                lhs.padding == rhs.padding &&
                lhs.margin == rhs.margin &&
                lhs.background == rhs.background &&
                lhs.shape == rhs.shape &&
                lhs.border == rhs.border &&
                lhs.shadow == rhs.shadow &&
                lhs.pages == rhs.pages &&
                lhs.pageAlignment == rhs.pageAlignment &&
                lhs.pageSpacing == rhs.pageSpacing &&
                lhs.pagePeek == rhs.pagePeek &&
                lhs.initialPageIndex == rhs.initialPageIndex &&
                lhs.loop == rhs.loop &&
                lhs.autoAdvance == rhs.autoAdvance &&
                lhs.pageControl == rhs.pageControl &&
                lhs.overrides == rhs.overrides
        }

        // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(visible)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(background)
            hasher.combine(shape)
            hasher.combine(border)
            hasher.combine(shadow)
            hasher.combine(pages)
            hasher.combine(pageAlignment)
            hasher.combine(pageSpacing)
            hasher.combine(pagePeek)
            hasher.combine(initialPageIndex)
            hasher.combine(loop)
            hasher.combine(autoAdvance)
            hasher.combine(pageControl)
            hasher.combine(overrides)
        }

    }

    final class PartialCarouselComponent: PaywallPartialComponent {

        public let visible: Bool?
        public let size: Size?
        public let padding: Padding?
        public let margin: Padding?
        public let background: Background?
        public let shape: Shape?
        public let border: Border?
        public let shadow: Shadow?

        public let pageAlignment: VerticalAlignment?
        public let pageSpacing: Int?
        public let pagePeek: Int?
        public let initialPageIndex: Int?
        public let loop: Bool?
        public let autoAdvance: PaywallComponent.CarouselComponent.AutoAdvanceSlides?

        public let pageControl: PaywallComponent.CarouselComponent.PageControl?

        public init(
            visible: Bool? = true,
            size: PaywallComponent.Size? = nil,
            padding: PaywallComponent.Padding? = nil,
            margin: PaywallComponent.Padding? = nil,
            background: PaywallComponent.Background? = nil,
            shape: PaywallComponent.Shape? = nil,
            border: PaywallComponent.Border? = nil,
            shadow: PaywallComponent.Shadow? = nil,
            pageAlignment: PaywallComponent.VerticalAlignment? = nil,
            pageSpacing: Int? = nil,
            pagePeek: Int? = nil,
            initialPageIndex: Int? = nil,
            loop: Bool? = nil,
            autoAdvance: PaywallComponent.CarouselComponent.AutoAdvanceSlides? = nil,
            pageControl: PaywallComponent.CarouselComponent.PageControl? = nil
        ) {
            self.visible = visible
            self.size = size
            self.padding = padding
            self.margin = margin
            self.background = background
            self.shape = shape
            self.border = border
            self.shadow = shadow
            self.pageAlignment = pageAlignment
            self.pageSpacing = pageSpacing
            self.pagePeek = pagePeek
            self.initialPageIndex = initialPageIndex
            self.loop = loop
            self.autoAdvance = autoAdvance
            self.pageControl = pageControl
        }

        public static func == (lhs: PartialCarouselComponent, rhs: PartialCarouselComponent) -> Bool {
            return lhs.visible == rhs.visible &&
                lhs.size == rhs.size &&
                lhs.padding == rhs.padding &&
                lhs.margin == rhs.margin &&
                lhs.background == rhs.background &&
                lhs.shape == rhs.shape &&
                lhs.border == rhs.border &&
                lhs.shadow == rhs.shadow &&
                lhs.pageAlignment == rhs.pageAlignment &&
                lhs.pageSpacing == rhs.pageSpacing &&
                lhs.pagePeek == rhs.pagePeek &&
                lhs.initialPageIndex == rhs.initialPageIndex &&
                lhs.loop == rhs.loop &&
                lhs.autoAdvance == rhs.autoAdvance &&
                lhs.pageControl == rhs.pageControl
        }

        // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(visible)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(background)
            hasher.combine(shape)
            hasher.combine(border)
            hasher.combine(shadow)
            hasher.combine(pageAlignment)
            hasher.combine(pageSpacing)
            hasher.combine(pagePeek)
            hasher.combine(initialPageIndex)
            hasher.combine(loop)
            hasher.combine(autoAdvance)
            hasher.combine(pageControl)
        }

    }

}
