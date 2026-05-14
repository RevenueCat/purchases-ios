//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//

import Foundation

#if !os(tvOS)

/// Identifies a single runtime paywall instance for reactive state isolation.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@_spi(Internal) public struct PaywallStateScope: Hashable, Sendable {

    @_spi(Internal) public let instanceID: UUID
    @_spi(Internal) public let paywallID: String?
    @_spi(Internal) public let offeringIdentifier: String
    @_spi(Internal) public let paywallRevision: Int?
    @_spi(Internal) public let workflowPageID: String?

    @_spi(Internal)
    public init(
        instanceID: UUID = UUID(),
        paywallID: String?,
        offeringIdentifier: String,
        paywallRevision: Int?,
        workflowPageID: String?
    ) {
        self.instanceID = instanceID
        self.paywallID = paywallID
        self.offeringIdentifier = offeringIdentifier
        self.paywallRevision = paywallRevision
        self.workflowPageID = workflowPageID
    }

}

#endif
