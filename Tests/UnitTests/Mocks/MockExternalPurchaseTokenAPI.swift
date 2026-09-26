//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockExternalPurchaseTokenAPI.swift
//
//  Created by Antonio Pallares on 3/9/26.

import Foundation
@testable import RevenueCat

class MockExternalPurchaseTokenAPI: ExternalPurchaseTokenAPI {

    init() {
        super.init(backendConfig: MockBackendConfiguration())
    }

    var invokedPostExternalPurchaseToken = false
    var invokedPostExternalPurchaseTokenCount = 0
    var invokedPostExternalPurchaseTokenParameters: (
        appUserID: String,
        purchaseType: ExternalPurchaseTokenType,
        tokenID: String,
        token: String?
    )?

    /// Every identifier posted, in the order it was posted.
    var postedTokenIDs: [String] = []

    var stubbedPostExternalPurchaseTokenError: BackendError?
    var postExternalPurchaseTokenCallback: (() -> Void)?

    override func postExternalPurchaseToken(
        appUserID: String,
        purchaseType: ExternalPurchaseTokenType,
        tokenID: String,
        token: String?,
        completion: @escaping ExternalPurchaseTokenAPI.SimpleResponseHandler
    ) {
        self.invokedPostExternalPurchaseToken = true
        self.invokedPostExternalPurchaseTokenCount += 1
        self.invokedPostExternalPurchaseTokenParameters = (appUserID, purchaseType, tokenID, token)
        self.postedTokenIDs.append(tokenID)

        self.postExternalPurchaseTokenCallback?()
        completion(self.stubbedPostExternalPurchaseTokenError)
    }

}
