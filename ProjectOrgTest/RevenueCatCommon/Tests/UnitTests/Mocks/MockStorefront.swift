//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockStorefront.swift
//
//  Created by Nacho Soto on 4/13/22.

@testable import RevenueCat

final class MockStorefront: StorefrontType {

    init(countryCode: String) {
        self.identifier = countryCode
        self.countryCode = countryCode
    }

    let identifier: String
    let countryCode: String

}
