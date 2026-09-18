//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RequestLane.swift
//
//  Created by Antonio Pallares on 18/9/26.

import Foundation

/// A request lane with its own serial `OperationQueue` and `HTTPClient`.
///
/// Lanes bypass two independent serializations in the backend stack: the shared
/// `OperationQueue` (`maxConcurrentOperationCount = 1`) and the per-client request
/// queue inside `HTTPClient` (`httpMaximumConnectionsPerHost = 1`). A lane needs
/// both so its requests can run in parallel with unrelated work on other lanes.
struct RequestLane: Hashable {

    let name: String
    let qualityOfService: QualityOfService

}

extension RequestLane {

    /// The default lane for most backend traffic.
    static let `default` = RequestLane(name: "Backend", qualityOfService: .default)

    /// Remote config fetches run here so `/config` is not blocked by offerings, receipts, or other backend work.
    static let remoteConfig = RequestLane(name: "Remote Config", qualityOfService: .default)

    /// Checkout tap-path requests run here at user-initiated QoS so token registration and hosted-checkout
    /// creation are not delayed while the customer waits on the purchase button.
    static let checkout = RequestLane(name: "Checkout", qualityOfService: .userInitiated)

}
