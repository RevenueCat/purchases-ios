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

    /// Package-selection sheet became visible: `component_value` is `open`.
    /// `current*` reflects the root paywall selection.
    static func paywallPackageSelectionSheetOpen(
        sheetComponentName: String?,
        rootSelectedPackage: Package?
    ) -> Self {
        return .init(
            componentType: .packageSelectionSheet,
            componentName: sheetComponentName,
            componentValue: "open",
            currentPackageIdentifier: rootSelectedPackage?.identifier,
            currentProductIdentifier: rootSelectedPackage?.storeProduct.productIdentifier
        )
    }

    /// Package-selection sheet dismissed: `component_value` is `close`.
    /// `current*` reflects the sheet selection before dismiss; `resulting*` reflects the root paywall after dismiss
    /// (e.g. revert to default).
    static func paywallPackageSelectionSheetClose(
        sheetComponentName: String?,
        sheetSelectedPackage: Package?,
        resultingRootPackage: Package?
    ) -> Self {
        return .init(
            componentType: .packageSelectionSheet,
            componentName: sheetComponentName,
            componentValue: "close",
            currentPackageIdentifier: sheetSelectedPackage?.identifier,
            resultingPackageIdentifier: resultingRootPackage?.identifier,
            currentProductIdentifier: sheetSelectedPackage?.storeProduct.productIdentifier,
            resultingProductIdentifier: resultingRootPackage?.storeProduct.productIdentifier
        )
    }

    static func paywallPackageRowSelection(
        componentName: String? = nil,
        destination: Package,
        origin: Package?,
        defaultPackage: Package? = nil
    ) -> Self {
        return .init(
            componentType: .package,
            componentName: componentName,
            componentValue: destination.identifier,
            originPackageIdentifier: origin?.identifier,
            destinationPackageIdentifier: destination.identifier,
            defaultPackageIdentifier: defaultPackage?.identifier,
            originProductIdentifier: origin?.storeProduct.productIdentifier,
            destinationProductIdentifier: destination.storeProduct.productIdentifier,
            defaultProductIdentifier: defaultPackage?.storeProduct.productIdentifier
        )
    }

    static func paywallTierSelection(
        tierDisplayName: String,
        componentName: String? = nil,
        originPackage: Package?,
        destinationPackage: Package?
    ) -> Self {
        return .init(
            componentType: .tab,
            componentName: componentName,
            componentValue: tierDisplayName,
            originPackageIdentifier: originPackage?.identifier,
            destinationPackageIdentifier: destinationPackage?.identifier,
            originProductIdentifier: originPackage?.storeProduct.productIdentifier,
            destinationProductIdentifier: destinationPackage?.storeProduct.productIdentifier
        )
    }

}
