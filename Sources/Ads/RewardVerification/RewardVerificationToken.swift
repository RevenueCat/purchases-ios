//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RewardVerificationToken.swift
//

import Foundation

@_spi(Experimental) public struct RewardVerificationToken: Sendable, Equatable {

    public let customData: String

    public let clientTransactionID: String

    public let appUserID: String

    @_spi(Experimental) public init(
        customData: String,
        clientTransactionID: String,
        appUserID: String
    ) {
        self.customData = customData
        self.clientTransactionID = clientTransactionID
        self.appUserID = appUserID
    }
}
