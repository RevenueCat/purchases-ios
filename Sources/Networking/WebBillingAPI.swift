//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBillingAPI.swift
//
//  Created by Antonio Pallares on 7/29/25.

import Foundation

class WebBillingAPI {

    typealias WebBillingProductsResponseHandler = Backend.ResponseHandler<WebBillingProductsResponse>
    typealias StartWebCheckoutResponseHandler = Backend.ResponseHandler<StartWebCheckoutResponse>
    typealias WebCheckoutStatusResponseHandler = Backend.ResponseHandler<WebCheckoutStatusResponse>

    private let webBillingProductsCallbackCache: CallbackCache<WebBillingProductsCallback>
    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
        self.webBillingProductsCallbackCache = .init()
    }

    func getWebBillingProducts(
        appUserID: String, productIds: Set<String>, completion: @escaping WebBillingProductsResponseHandler
    ) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)
        let factory = GetWebBillingProductsOperation.createFactory(
            configuration: config,
            webBillingProductsCallbackCache: self.webBillingProductsCallbackCache,
            productIds: productIds
        )

        let webProductsCallback = WebBillingProductsCallback(cacheKey: factory.cacheKey, completion: completion)
        let cacheStatus = self.webBillingProductsCallbackCache.add(webProductsCallback)

        self.backendConfig.addCacheableOperation(
            with: factory,
            delay: .none,
            cacheStatus: cacheStatus
        )
    }

    func startCheckout(
        appUserID: String,
        packageID: String,
        offeringIdentifier: String,
        email: String?,
        completion: @escaping StartWebCheckoutResponseHandler
    ) {
        _ = email
        let configuration = NetworkOperation.UserSpecificConfiguration(
            httpClient: self.backendConfig.httpClient,
            appUserID: appUserID
        )
        let operation = StartWebCheckoutOperation(
            configuration: configuration,
            postData: .init(
                appUserID: appUserID,
                packageID: packageID,
                presentedOfferingIdentifier: offeringIdentifier
            ),
            responseHandler: completion
        )
        self.backendConfig.operationQueue.addOperation(operation)
    }

    func getCheckoutStatus(
        operationSessionID: String,
        appUserID: String,
        completion: @escaping WebCheckoutStatusResponseHandler
    ) {
        let configuration = NetworkOperation.UserSpecificConfiguration(
            httpClient: self.backendConfig.httpClient,
            appUserID: appUserID
        )
        let operation = GetWebCheckoutStatusOperation(
            configuration: configuration,
            operationSessionID: operationSessionID,
            responseHandler: completion
        )
        self.backendConfig.operationQueue.addOperation(operation)
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension WebBillingAPI: @unchecked Sendable {}

// MARK: - Responses

struct StartWebCheckoutResponse {

    let operationSessionID: String
    let checkoutURL: String

    var hostedCheckoutURL: URL? {
        return URL(string: self.checkoutURL)
    }

}

extension StartWebCheckoutResponse: Codable, Equatable {

    private enum CodingKeys: String, CodingKey {
        case operationSessionID = "operationSessionId"
        case checkoutURL = "checkoutUrl"
    }

}

extension StartWebCheckoutResponse: HTTPResponseBody {}

struct WebCheckoutStatusResponse {

    enum Status: String {
        case started
        case inProgress = "in_progress"
        case succeeded
        case failed
        case unknown
    }

    struct RedemptionInfo {
        let redeemURL: String?
    }

    struct Operation {
        let status: Status
        let isExpired: Bool
        let redemptionInfo: RedemptionInfo?
    }

    let operation: Operation

}

extension WebCheckoutStatusResponse.RedemptionInfo: Codable, Equatable {

    private enum CodingKeys: String, CodingKey {
        case redeemURL = "redeemUrl"
    }

}

extension WebCheckoutStatusResponse.Operation: Codable, Equatable {}
extension WebCheckoutStatusResponse: Codable, Equatable {}
extension WebCheckoutStatusResponse: HTTPResponseBody {}

extension WebCheckoutStatusResponse.Status: Codable, Equatable {

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = WebCheckoutStatusResponse.Status(rawValue: rawValue) ?? .unknown
    }

}

// MARK: - Operations

private final class StartWebCheckoutOperation: NetworkOperation {

    struct PostData: Encodable, HTTPRequestBody {
        let appUserID: String
        let packageID: String
        let presentedOfferingIdentifier: String

        init(
            appUserID: String,
            packageID: String,
            presentedOfferingIdentifier: String
        ) {
            self.appUserID = appUserID
            self.packageID = packageID
            self.presentedOfferingIdentifier = presentedOfferingIdentifier
        }

        private enum CodingKeys: String, CodingKey {
            case appUserID = "app_user_id"
            case packageID = "package_id"
            case presentedOfferingIdentifier = "presented_offering_identifier"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.appUserID, forKey: .appUserID)
            try container.encode(self.packageID, forKey: .packageID)
            try container.encode(self.presentedOfferingIdentifier, forKey: .presentedOfferingIdentifier)
        }
    }

    private let configuration: UserSpecificConfiguration
    private let postData: PostData
    private let responseHandler: WebBillingAPI.StartWebCheckoutResponseHandler

    init(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        responseHandler: @escaping WebBillingAPI.StartWebCheckoutResponseHandler
    ) {
        self.configuration = configuration
        self.postData = postData
        self.responseHandler = responseHandler
        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .post(self.postData), path: .startCheckout)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<StartWebCheckoutResponse>.Result) in
            defer { completion() }
            self.responseHandler(
                response.map(\.body).mapError(BackendError.networkError)
            )
        }
    }

}

extension StartWebCheckoutOperation: @unchecked Sendable {}

private final class GetWebCheckoutStatusOperation: NetworkOperation {

    private let configuration: UserSpecificConfiguration
    private let operationSessionID: String
    private let responseHandler: WebBillingAPI.WebCheckoutStatusResponseHandler

    init(
        configuration: UserSpecificConfiguration,
        operationSessionID: String,
        responseHandler: @escaping WebBillingAPI.WebCheckoutStatusResponseHandler
    ) {
        self.configuration = configuration
        self.operationSessionID = operationSessionID
        self.responseHandler = responseHandler
        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        let request = HTTPRequest(
            method: .get,
            path: .getCheckoutStatus(operationSessionID: self.operationSessionID)
        )

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<WebCheckoutStatusResponse>.Result) in
            defer { completion() }
            self.responseHandler(
                response.map(\.body).mapError(BackendError.networkError)
            )
        }
    }

}

extension GetWebCheckoutStatusOperation: @unchecked Sendable {}
