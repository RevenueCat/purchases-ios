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
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct AutoAdvanceSlides: PaywallComponentBase {

        public let msTimePerSlide: Int
        public let msTransitionTime: Int

        public init(msTimePerSlide: Int, msTransitionTime: Int) {
            self.msTimePerSlide = msTimePerSlide
            self.msTransitionTime = msTransitionTime
        }

    }

    final class CarouselComponent: PaywallComponentBase {

        let type: ComponentType
        public let alignment: VerticalAlignment
        public let size: Size
        public let spacing: CGFloat?
        public let padding: Padding
        public let margin: Padding
        public let shape: Shape?
        public let border: Border?
        public let shadow: Shadow?

        public let slides: [StackComponent]
        public let loop: Bool
        public let autoAdvance: AutoAdvanceSlides?

        public init(
            alignment: PaywallComponent.VerticalAlignment = .center,
            size: PaywallComponent.Size = .init(width: .fit, height: .fit),
            spacing: CGFloat? = nil,
            padding: PaywallComponent.Padding = .zero,
            margin: PaywallComponent.Padding = .zero,
            shape: PaywallComponent.Shape? = nil,
            border: PaywallComponent.Border? = nil,
            shadow: PaywallComponent.Shadow? = nil,
            slides: [PaywallComponent.StackComponent],
            loop: Bool = false,
            autoAdvance: PaywallComponent.AutoAdvanceSlides? = nil
        ) {
            self.type = .carousel
            self.alignment = alignment
            self.size = size
            self.spacing = spacing
            self.padding = padding
            self.margin = margin
            self.shape = shape
            self.border = border
            self.shadow = shadow
            self.slides = slides
            self.loop = loop
            self.autoAdvance = autoAdvance
        }

        // MARK: - Equatable
        public static func == (lhs: CarouselComponent, rhs: CarouselComponent) -> Bool {
            return lhs.type == rhs.type
                && lhs.alignment == rhs.alignment
                && lhs.size == rhs.size
                && lhs.spacing == rhs.spacing
                && lhs.padding == rhs.padding
                && lhs.margin == rhs.margin
                && lhs.shape == rhs.shape
                && lhs.border == rhs.border
                && lhs.shadow == rhs.shadow
                && lhs.slides == rhs.slides
                && lhs.loop == rhs.loop
                && lhs.autoAdvance == rhs.autoAdvance
        }

        // MARK: - Hashable
        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(alignment)
            hasher.combine(size)
            hasher.combine(spacing)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(shape)
            hasher.combine(border)
            hasher.combine(shadow)
            hasher.combine(slides)
            hasher.combine(loop)
            hasher.combine(autoAdvance)
        }

    }

}

#endif
