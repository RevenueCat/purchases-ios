//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptRefreshPolicy.swift
//
//  Created by Juanpe Catalán on 7/7/21.
//

import Foundation

/// Determines the behavior when fetching receipts with `ReceiptFetcher`.
enum ReceiptRefreshPolicy {

    case always
    case onlyIfEmpty
    case retryUntilProductIsFound(productIdentifier: String,
                                  maximumRetries: Int,
                                  sleepDuration: DispatchTimeInterval = .never)
    case never

}

extension ReceiptRefreshPolicy {

    /// See `ReceiptFetcher`.
    /// `ReceiptRefreshPolicy.always` won't refresh receipts faster than this interval
    /// to avoid StoreKit errors:
    /// "Finished refreshing receipt with error: Error Domain=ASDErrorDomain Code=603 "Request throttled"
    static let alwaysRefreshThrottleDuration: DispatchTimeInterval = .seconds(2)

}

extension ReceiptRefreshPolicy: Equatable {}
