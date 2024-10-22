//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackComponent.swift
//
//  Created by James Borthwick on 2024-08-20.
// swiftlint:disable missing_docs

import Foundation

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    // The most common type of stack that can contain any type of PaywallComponent
    typealias StackComponent = GenericStackComponent<PaywallComponent>

    // A specialized stack that can only hold PaywallComponent.PackageComponent
    typealias PackagesStackComponent = GenericStackComponent<PaywallComponent.PackageComponent>

    struct GenericStackComponent<T: StackableComponent>: PaywallComponentBase {

        let type: ComponentType
        public let components: [T]
        public let width: WidthSize?
        public let spacing: CGFloat?
        public let backgroundColor: ColorInfo?
        public let dimension: Dimension
        public let padding: Padding
        public let margin: Padding
        public let cornerRadiuses: CornerRadiuses?
        public let border: Border?

        public init(components: [T],
                    dimension: Dimension = .vertical(.center),
                    width: WidthSize? = nil,
                    spacing: CGFloat? = 0,
                    backgroundColor: ColorInfo? = nil,
                    padding: Padding = .zero,
                    margin: Padding = .zero,
                    cornerRadiuses: CornerRadiuses? = nil,
                    border: Border? = nil
        ) {
            self.components = components
            self.width = width
            self.spacing = spacing
            self.backgroundColor = backgroundColor
            self.type = .stack
            self.dimension = dimension
            self.padding = padding
            self.margin = margin
            self.cornerRadiuses = cornerRadiuses
            self.border = border
        }

    }

}

public extension PaywallComponent {

    // Components that can be contained in a stack
    protocol StackableComponent: PaywallComponentBase {}

}

extension PaywallComponent: PaywallComponent.StackableComponent {}
extension PaywallComponent.PackageComponent: PaywallComponent.StackableComponent {}

#endif
