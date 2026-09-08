//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockExternalPurchaseCustomLink.swift
//
//  Created by Antonio Pallares on 3/9/26.

import Foundation
@testable import RevenueCat

final class MockExternalPurchaseCustomLink: ExternalPurchaseCustomLinkType {

    var stubbedIsAPIAvailable: Bool = true
    var stubbedCanMakeExternalPurchases: Bool = true
    var stubbedTokenResult: Result<String?, Error> = .success("test-external-purchase-token")
    var stubbedNoticeResult: Result<ExternalPurchaseNoticeResult, Error> = .success(.continued)

    private(set) var invokedCanMakeExternalPurchasesCount: Int = 0
    private(set) var invokedTokenTypes: [ExternalPurchaseTokenType] = []
    private(set) var invokedNoticeTypes: [ExternalPurchaseNoticeType] = []

    var isAPIAvailable: Bool {
        return self.stubbedIsAPIAvailable
    }

    func canMakeExternalPurchases() async -> Bool {
        self.invokedCanMakeExternalPurchasesCount += 1
        return self.stubbedCanMakeExternalPurchases
    }

    func token(for tokenType: ExternalPurchaseTokenType) async throws -> String? {
        self.invokedTokenTypes.append(tokenType)
        return try self.stubbedTokenResult.get()
    }

    func showNotice(type: ExternalPurchaseNoticeType) async throws -> ExternalPurchaseNoticeResult {
        self.invokedNoticeTypes.append(type)
        return try self.stubbedNoticeResult.get()
    }

}

extension MockExternalPurchaseCustomLink: @unchecked Sendable {}
