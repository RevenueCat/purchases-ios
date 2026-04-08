//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Offering+DynamicFiltering.swift

@_spi(Internal) import RevenueCat

extension Offering {

    /// Creates a copy of this offering containing only the specified packages.
    ///
    /// All other properties (identifier, description, paywall, paywallComponents, metadata, etc.)
    /// are preserved. The convenience typed accessors (`annual`, `monthly`, etc.) are
    /// re-derived from the filtered package list by `Offering.init`.
    func copyWithFilteredPackages(_ packages: [Package]) -> Offering {
        return Offering(
            identifier: self.identifier,
            serverDescription: self.serverDescription,
            metadata: self.metadata,
            paywall: self.paywall,
            paywallComponents: self.paywallComponents,
            availablePackages: packages,
            webCheckoutUrl: self.webCheckoutUrl
        )
    }

}
