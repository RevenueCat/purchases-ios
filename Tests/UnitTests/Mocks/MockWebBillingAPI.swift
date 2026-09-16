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

    struct PostHostedCheckoutParameters {

        let appUserID: String
        let packageID: String
        let presentedOfferingContext: PresentedOfferingContext
        let paywall: PostHostedCheckoutOperation.Paywall?
        let externalPurchaseTokenID: String?

    }

    var invokedPostHostedCheckout = false
    var invokedPostHostedCheckoutCount = 0
    var invokedPostHostedCheckoutParameters: PostHostedCheckoutParameters?
    var stubbedPostHostedCheckoutCompletionResult: Result<HostedCheckoutResponse, BackendError>?

    override func postHostedCheckout(
        appUserID: String,
        packageID: String,
        presentedOfferingContext: PresentedOfferingContext,
        paywall: PostHostedCheckoutOperation.Paywall?,
        externalPurchaseTokenID: String?,
        completion: @escaping HostedCheckoutResponseHandler
    ) {
        self.invokedPostHostedCheckout = true
        self.invokedPostHostedCheckoutCount += 1
        self.invokedPostHostedCheckoutParameters = .init(appUserID: appUserID,
                                                         packageID: packageID,
                                                         presentedOfferingContext: presentedOfferingContext,
                                                         paywall: paywall,
                                                         externalPurchaseTokenID: externalPurchaseTokenID)

        if let result = self.stubbedPostHostedCheckoutCompletionResult {
            completion(result)
        }
    }

}

extension MockWebBillingAPI: @unchecked Sendable {}
