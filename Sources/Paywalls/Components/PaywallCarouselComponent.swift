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

#if PAYWALL_COMPONENTS

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
            public let backgroundColor: ColorScheme?
            public let shape: Shape?
            public let border: Border?
            public let shadow: Shadow?

            public let active: PageControlIndicator
            public let `default`: PageControlIndicator

            public init(
                position: Position,
                backgroundColor: ColorScheme?,
                shape: Shape?,
                border: Border?,
                shadow: Shadow?,
                active: PageControlIndicator,
                default: PageControlIndicator
            ) {
                self.position = position
                self.backgroundColor = backgroundColor
                self.shape = shape
                self.border = border
                self.shadow = shadow
                self.active = active
                self.default = `default`
            }

        }

        public struct PageControlIndicator: PaywallComponentBase {

            public let width: Int
            public let height: Int
            public let margin: Padding?
            public let color: ColorScheme

            public init(width: Int, height: Int, margin: Padding? = nil, color: ColorScheme) {
                self.width = width
                self.height = height
                self.margin = margin
                self.color = color
            }

        }

        let type: ComponentType

        public let size: Size
        public let padding: Padding
        public let margin: Padding
        public let shape: Shape?
        public let border: Border?
        public let shadow: Shadow?

        public let pages: [StackComponent]
        public let pageAlignment: VerticalAlignment
        public let pageSpacing: Int
        public let pagePeek: Double
        public let startPageIndex: Int
        public let loop: Bool
        public let autoAdvance: AutoAdvanceSlides?

        public let pageControl: PageControl

        public init(
            size: PaywallComponent.Size = .init(width: .fit, height: .fit),
            padding: PaywallComponent.Padding = .zero,
            margin: PaywallComponent.Padding = .zero,
            shape: PaywallComponent.Shape? = nil,
            border: PaywallComponent.Border? = nil,
            shadow: PaywallComponent.Shadow? = nil,
            pages: [PaywallComponent.StackComponent],
            pageAlignment: PaywallComponent.VerticalAlignment = .center,
            pageSpacing: Int = 0,
            pagePeek: Double = 0.2,
            startPageIndex: Int = 0,
            loop: Bool = false,
            autoAdvance: PaywallComponent.CarouselComponent.AutoAdvanceSlides? = nil,
            pageControl: PageControl
        ) {
            self.type = .carousel

            self.size = size
            self.padding = padding
            self.margin = margin
            self.shape = shape
            self.border = border
            self.shadow = shadow
            self.pages = pages
            self.pageAlignment = pageAlignment
            self.pageSpacing = pageSpacing
            self.pagePeek = pagePeek
            self.startPageIndex = startPageIndex
            self.loop = loop
            self.autoAdvance = autoAdvance
            self.pageControl = pageControl
        }

        public static func == (lhs: CarouselComponent, rhs: CarouselComponent) -> Bool {
            return lhs.type == rhs.type &&
                lhs.size == rhs.size &&
                lhs.padding == rhs.padding &&
                lhs.margin == rhs.margin &&
                lhs.shape == rhs.shape &&
                lhs.border == rhs.border &&
                lhs.shadow == rhs.shadow &&
                lhs.pages == rhs.pages &&
                lhs.pageAlignment == rhs.pageAlignment &&
                lhs.pageSpacing == rhs.pageSpacing &&
                lhs.pagePeek == rhs.pagePeek &&
                lhs.startPageIndex == rhs.startPageIndex &&
                lhs.loop == rhs.loop &&
                lhs.autoAdvance == rhs.autoAdvance &&
                lhs.pageControl == rhs.pageControl
        }

        // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(size)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(shape)
            hasher.combine(border)
            hasher.combine(shadow)
            hasher.combine(pages)
            hasher.combine(pageAlignment)
            hasher.combine(pageSpacing)
            hasher.combine(pagePeek)
            hasher.combine(startPageIndex)
            hasher.combine(loop)
            hasher.combine(autoAdvance)
            hasher.combine(pageControl)
        }

    }

}

#endif
