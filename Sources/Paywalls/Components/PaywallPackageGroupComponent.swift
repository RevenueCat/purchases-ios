//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallPackageGroupComponent.swift
//
//  Created by Josh Holtz on 9/27/24.

import Foundation

// swiftlint:disable missing_docs

#if PAYWALL_COMPONENTS

public extension PaywallComponent {

    struct PackageGroupComponent: PaywallComponentBase, StackableComponent {

        let type: ComponentType
        public let defaultSelectedPackageID: String

        // Most containers will accept an array of `PaywallComponent`s
        // Package group specifically accepts `PackageComponent` for
        // validation that packages exist
        public let packages: [PaywallComponent.PackageComponent]
        public let width: WidthSize?
        public let spacing: CGFloat?
        public let backgroundColor: ColorInfo?
        public let dimension: Dimension
        public let padding: Padding
        public let margin: Padding
        public let cornerRadiuses: CornerRadiuses?
        public let border: Border?

        public init(defaultSelectedPackageID: String,
                    packages: [PaywallComponent.PackageComponent],
                    dimension: Dimension = .vertical(.center),
                    width: WidthSize? = nil,
                    spacing: CGFloat? = 0,
                    backgroundColor: ColorInfo? = nil,
                    padding: Padding = .zero,
                    margin: Padding = .zero,
                    cornerRadiuses: CornerRadiuses? = nil,
                    border: Border? = nil
        ) {
            self.type = .packageGroup
            self.defaultSelectedPackageID = defaultSelectedPackageID
            self.packages = packages
            self.width = width
            self.spacing = spacing
            self.backgroundColor = backgroundColor
            self.dimension = dimension
            self.padding = padding
            self.margin = margin
            self.cornerRadiuses = cornerRadiuses
            self.border = border
        }
    }

}

#endif
