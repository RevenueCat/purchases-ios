//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Outcome.swift
//

import Foundation

internal extension RewardVerification {

    /// Terminal SSV verdict delivered by `Dispatcher`.
    enum Outcome: Sendable {
        case verified(AdReward)
        case failed(FailureReason)
    }

    /// Internal classification of why verification failed.
    enum FailureReason: Sendable, Equatable {
        case timeout
        case backendError
        case unknown
    }
}
