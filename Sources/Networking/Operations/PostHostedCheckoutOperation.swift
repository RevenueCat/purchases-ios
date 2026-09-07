//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostHostedCheckoutOperation.swift
//
//  Created by Antonio Pallares on 4/9/26.

import Foundation

/// Creates a checkout session for in-app web checkout, where a payment provider's page is presented
/// inside the app instead of the purchase being handed off to the browser.
///
/// The response carries the page to present and the two return URLs that mark the end of the checkout.
final class PostHostedCheckoutOperation: CacheableNetworkOperation {

    private let configuration: AppUserConfiguration
    private let postData: PostData
    private let hostedCheckoutCallbackCache: CallbackCache<HostedCheckoutCallback>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        hostedCheckoutCallbackCache: CallbackCache<HostedCheckoutCallback>
    ) -> CacheableNetworkOperationFactory<PostHostedCheckoutOperation> {
        let cacheKey = [
            configuration.appUserID,
            postData.packageID,
            postData.presentedOfferingIdentifier,
            postData.externalPurchaseTokenID ?? ""
        ].joined(separator: "\n")

        return CacheableNetworkOperationFactory({ cacheKey in
                    PostHostedCheckoutOperation(
                        configuration: configuration,
                        postData: postData,
                        hostedCheckoutCallbackCache: hostedCheckoutCallbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: cacheKey
        )
    }

    private init(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        hostedCheckoutCallbackCache: CallbackCache<HostedCheckoutCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.postData = postData
        self.hostedCheckoutCallbackCache = hostedCheckoutCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {
        guard self.configuration.appUserID.isNotEmpty else {
            self.handleResult(.failure(.missingAppUserID()))
            completion()
            return
        }

        let request = HTTPRequest(method: .post(self.postData),
                                  path: .postHostedCheckout,
                                  isRetryable: true)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<HostedCheckoutResponse>.Result) in
            let result = response
                .map { $0.body }
                .mapError(BackendError.networkError)

            self.handleResult(result)
            completion()
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostHostedCheckoutOperation: @unchecked Sendable {}

private extension PostHostedCheckoutOperation {

    func handleResult(_ result: Result<HostedCheckoutResponse, BackendError>) {
        self.hostedCheckoutCallbackCache.performOnAllItemsAndRemoveFromCache(
            withCacheable: self
        ) { callback in
            callback.completion(result)
        }
    }

}

extension PostHostedCheckoutOperation {

    struct PostData {

        let appUserID: String
        let packageID: String
        let presentedOfferingIdentifier: String
        let presentedPlacementIdentifier: String?
        let appliedTargetingRule: AppliedTargetingRule?

        /// The paywall the checkout was started from, so that the purchase is attributed to it the same
        /// way a StoreKit purchase from that paywall would be.
        let paywall: Paywall?

        /// Identifies the Apple external purchase token registered for this purchase, so the backend can
        /// tie the checkout session to it. Omitted where no token applies (e.g. Test Store).
        let externalPurchaseTokenID: String?

    }

    struct AppliedTargetingRule {

        let revision: Int
        let ruleID: String

    }

    struct Paywall {

        let paywallID: String
        let sessionID: String

        // Sent at the top level of the body as `presented_workflow_id`/`presented_step_id`, not inside
        // the nested `paywall` object — excluded from Codable via the CodingKeys enum below.
        let workflowID: String?
        let stepID: String?

    }

}

// MARK: - Codable

extension PostHostedCheckoutOperation.PostData: Encodable {

    private enum CodingKeys: String, CodingKey {

        case appUserID = "app_user_id"
        case packageID = "package_id"
        case presentedOfferingIdentifier = "presented_offering_identifier"
        case presentedPlacementIdentifier = "presented_placement_identifier"
        case presentedWorkflowID = "presented_workflow_id"
        case presentedStepID = "presented_step_id"
        case appliedTargetingRule = "applied_targeting_rule"
        case paywall
        case externalPurchaseTokenID = "external_purchase_token_id"

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.appUserID, forKey: .appUserID)
        try container.encode(self.packageID, forKey: .packageID)
        try container.encode(self.presentedOfferingIdentifier, forKey: .presentedOfferingIdentifier)
        try container.encodeIfPresent(self.presentedPlacementIdentifier, forKey: .presentedPlacementIdentifier)
        try container.encodeIfPresent(self.appliedTargetingRule, forKey: .appliedTargetingRule)
        try container.encodeIfPresent(self.paywall, forKey: .paywall)
        try container.encodeIfPresent(self.paywall?.workflowID, forKey: .presentedWorkflowID)
        try container.encodeIfPresent(self.paywall?.stepID, forKey: .presentedStepID)
        try container.encodeIfPresent(self.externalPurchaseTokenID, forKey: .externalPurchaseTokenID)
    }

}

extension PostHostedCheckoutOperation.AppliedTargetingRule: Encodable {

    private enum CodingKeys: String, CodingKey {

        case revision
        case ruleID = "rule_id"

    }

}

extension PostHostedCheckoutOperation.Paywall: Encodable {

    private enum CodingKeys: String, CodingKey {

        case paywallID = "paywall_id"
        case sessionID = "paywall_session_id"

    }

}

// MARK: - HTTPRequestBody

extension PostHostedCheckoutOperation.PostData: HTTPRequestBody {}
