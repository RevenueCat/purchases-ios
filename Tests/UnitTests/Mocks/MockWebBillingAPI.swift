//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockWebBillingAPI.swift
//
//  Created by Antonio Pallares on 7/29/25.

import Foundation
@testable import RevenueCat

class MockWebBillingAPI: WebBillingAPI {

    var invokedGetWebBillingProducts = false
    var invokedGetWebBillingProductsCount = 0
    var invokedGetWebBillingProductsParameters: (appUserID: String?,
                                                 productIds: Set<String>?,
                                                 completion: WebBillingProductsResponseHandler?)?
    var invokedGetWebBillingProductsParametersList = [(appUserID: String?,
                                                       productIds: Set<String>?,
                                                       completion: WebBillingProductsResponseHandler?)]()
    var stubbedGetWebBillingProductsCompletionResult: Result<WebBillingProductsResponse, BackendError>?

    override func getWebBillingProducts(
        appUserID: String,
        productIds: Set<String>,
        completion: @escaping WebBillingProductsResponseHandler
    ) {
        self.invokedGetWebBillingProducts = true
        self.invokedGetWebBillingProductsCount += 1
        self.invokedGetWebBillingProductsParameters = (appUserID, productIds, completion)
        self.invokedGetWebBillingProductsParametersList.append((appUserID, productIds, completion))

        if let result = self.stubbedGetWebBillingProductsCompletionResult {
            completion(result)
        }
    }

}

extension MockWebBillingAPI: @unchecked Sendable {}
