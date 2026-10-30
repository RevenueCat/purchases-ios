//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowOfferings.swift

import Foundation
@_spi(Internal) import RevenueCat

#if !os(tvOS)

/// The offerings a workflow resolves its steps against. Wraps the fetched bundle together with the
/// developer-supplied offering (e.g. `PaywallView(offering:)`) so every lookup, including exit offers,
/// returns the developer's instance for its identifier instead of the fetched copy.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct WorkflowOfferings {

    let offerings: Offerings
    let developerProvidedOffering: Offering?

    init(offerings: Offerings, developerProvidedOffering: Offering?) {
        self.offerings = offerings
        self.developerProvidedOffering = developerProvidedOffering
    }

    func offering(identifier: String) -> Offering? {
        if let developerProvidedOffering, developerProvidedOffering.identifier == identifier {
            return developerProvidedOffering
        }
        return self.offerings.offering(identifier: identifier)
    }

}

#endif
