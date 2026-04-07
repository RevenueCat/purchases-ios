//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ComponentInteractionData+PackageSelection.swift
//

import Foundation
@_spi(Internal) import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallEvent.ComponentInteractionData {

    /// `component_value` is the destination package identifier.
    /// - Parameter defaultPackage: Configured default package for the current scope (offering or tab).
    static func paywallPackageRowSelection(
        destination: Package,
        origin: Package?,
        defaultPackage: Package? = nil
    ) -> Self {
        return .init(
            componentType: .package,
            componentName: PaywallComponentInteraction.packageSelectorName,
            componentValue: destination.identifier,
            originPackageIdentifier: origin?.identifier,
            destinationPackageIdentifier: destination.identifier,
            defaultPackageIdentifier: defaultPackage?.identifier,
            originProductIdentifier: origin?.storeProduct.productIdentifier,
            destinationProductIdentifier: destination.storeProduct.productIdentifier,
            defaultProductIdentifier: defaultPackage?.storeProduct.productIdentifier
        )
    }

    /// `component_value` is the tier display name (same as today); includes plan identifiers when available.
    /// - Parameter defaultPackage: Default package for the destination tier (same as the tier’s default selection).
    static func paywallTierSelection(
        tierDisplayName: String,
        originPackage: Package?,
        destinationPackage: Package?,
        defaultPackage: Package? = nil
    ) -> Self {
        return .init(
            componentType: .tab,
            componentName: PaywallComponentInteraction.tierSelectorName,
            componentValue: tierDisplayName,
            originPackageIdentifier: originPackage?.identifier,
            destinationPackageIdentifier: destinationPackage?.identifier,
            defaultPackageIdentifier: defaultPackage?.identifier,
            originProductIdentifier: originPackage?.storeProduct.productIdentifier,
            destinationProductIdentifier: destinationPackage?.storeProduct.productIdentifier,
            defaultProductIdentifier: defaultPackage?.storeProduct.productIdentifier
        )
    }

}
