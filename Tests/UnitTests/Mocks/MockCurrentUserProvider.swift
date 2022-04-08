//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockCurrentUserProvider.swift
//
//  Created by Nacho Soto on 4/6/22.

@testable import RevenueCat

final class MockCurrentUserProvider: CurrentUserProvider {

    var mockIsAnonymous = false
    var mockAppUserID: String

    init(mockAppUserID: String) {
        self.mockAppUserID = mockAppUserID
    }

    var currentAppUserID: String {
        return self.mockIsAnonymous
            ? self.mockAnonymousID
            : self.mockAppUserID
    }

    var currentUserIsAnonymous: Bool {
        return self.mockIsAnonymous
    }

    private let mockAnonymousID = IdentityManager.generateRandomID()

}
