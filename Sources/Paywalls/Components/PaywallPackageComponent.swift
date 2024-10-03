//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPackageComponent.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation

// swiftlint:disable missing_docs

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    final class PackageComponent: PaywallComponentBase, StackableComponent {

        let type: ComponentType

        public let packageID: String
        public let components: [PaywallComponent]
        public let width: WidthSize?
        public let spacing: CGFloat?
        public let backgroundColor: ColorInfo?
        public let dimension: Dimension
        public let padding: Padding
        public let margin: Padding
        public let cornerRadiuses: CornerRadiuses?
        public let border: Border?

        public let selectedState: PackageComponent?

        public init(packageID: String,
                    components: [PaywallComponent],
                    dimension: Dimension = .vertical(.center),
                    width: WidthSize? = nil,
                    spacing: CGFloat? = nil,
                    backgroundColor: ColorInfo? = nil,
                    padding: Padding = .zero,
                    margin: Padding = .zero,
                    cornerRadiuses: CornerRadiuses? = nil,
                    border: Border? = nil,
                    selectedState: PackageComponent? = nil
        ) {
            self.type = .package
            self.packageID = packageID
            self.components = components
            self.width = width
            self.spacing = spacing
            self.backgroundColor = backgroundColor
            self.dimension = dimension
            self.padding = padding
            self.margin = margin
            self.cornerRadiuses = cornerRadiuses
            self.border = border
            self.selectedState = selectedState
        }

        public static func == (lhs: PackageComponent, rhs: PackageComponent) -> Bool {
            return lhs.type == rhs.type &&
                lhs.packageID == rhs.packageID &&
                lhs.components == rhs.components &&
                lhs.width == rhs.width &&
                lhs.spacing == rhs.spacing &&
                lhs.backgroundColor == rhs.backgroundColor &&
                lhs.dimension == rhs.dimension &&
                lhs.padding == rhs.padding &&
                lhs.margin == rhs.margin &&
                lhs.cornerRadiuses == rhs.cornerRadiuses &&
                lhs.border == rhs.border &&
                lhs.selectedState == rhs.selectedState
        }

        // Add this method
        public func hash(into hasher: inout Hasher) {
            hasher.combine(type)
            hasher.combine(packageID)
            hasher.combine(components)
            hasher.combine(width)
            hasher.combine(spacing)
            hasher.combine(backgroundColor)
            hasher.combine(dimension)
            hasher.combine(padding)
            hasher.combine(margin)
            hasher.combine(cornerRadiuses)
            hasher.combine(border)
            hasher.combine(selectedState)
        }
    }
}

#endif
