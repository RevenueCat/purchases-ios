//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LogInOperation.swift
//
//  Created by Joshua Liebowitz on 11/19/21.

import Foundation

final class LogInOperation: CacheableNetworkOperation {

    private let loginCallbackCache: CallbackCache<LogInCallback>
    private let configuration: UserSpecificConfiguration
    private let newAppUserID: String
    private let attributes: SubscriberAttribute.Dictionary
    private let previousUnsyncedAttributes: SubscriberAttribute.Dictionary

    static func createFactory(
        configuration: UserSpecificConfiguration,
        newAppUserID: String,
        attributes: SubscriberAttribute.Dictionary,
        previousUnsyncedAttributes: SubscriberAttribute.Dictionary,
        loginCallbackCache: CallbackCache<LogInCallback>
    ) -> CacheableNetworkOperationFactory<LogInOperation> {
        return .init({
            .init(
                configuration: configuration,
                newAppUserID: newAppUserID,
                attributes: attributes,
                previousUnsyncedAttributes: previousUnsyncedAttributes,
                loginCallbackCache: loginCallbackCache,
                cacheKey: $0
            ) },
                     individualizedCacheKeyPart: configuration.appUserID + newAppUserID
                     + attributes.individualizedCacheKeyPart
                     + previousUnsyncedAttributes.individualizedCacheKeyPart)
    }

    private init(
        configuration: UserSpecificConfiguration,
        newAppUserID: String,
        attributes: SubscriberAttribute.Dictionary,
        previousUnsyncedAttributes: SubscriberAttribute.Dictionary,
        loginCallbackCache: CallbackCache<LogInCallback>,
        cacheKey: String
    ) {
        self.configuration = configuration
        self.newAppUserID = newAppUserID
        self.attributes = attributes
        self.previousUnsyncedAttributes = previousUnsyncedAttributes
        self.loginCallbackCache = loginCallbackCache

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        self.logIn(completion: completion)
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension LogInOperation: @unchecked Sendable {}

private extension LogInOperation {

    func logIn(completion: @escaping () -> Void) {
        guard self.newAppUserID.isNotEmpty else {
            self.loginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callback in
                callback.completion(.failure(.missingAppUserID()))
            }
            completion()

            return
        }

        let body = Body(appUserID: self.configuration.appUserID,
                        newAppUserID: self.newAppUserID,
                        attributes: self.attributes,
                        previousUnsyncedAttributes: self.previousUnsyncedAttributes)
        let request = HTTPRequest(method: .post(body), path: .logIn)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<Response>.Result) in
            self.loginCallbackCache.performOnAllItemsAndRemoveFromCache(withCacheable: self) { callbackObject in
                self.handleLogin(response, completion: callbackObject.completion)
            }

            completion()
        }
    }

    func handleLogin(_ result: VerifiedHTTPResponse<Response>.Result,
                     completion: IdentityAPI.LogInResponseHandler) {
        let result: IdentityAPI.LogInResponse = result
            .map { response in
                (
                    response.body.customerInfo.copy(with: response.verificationResult,
                                                    httpResponseOriginalSource: response.originalSource),
                    created: response.httpStatusCode == .createdSuccess,
                    attributesErrorResponse: response.body.attributesErrorResponse
                )
            }
            .mapError(BackendError.networkError)

        if case .success = result {
            Logger.user(Strings.identity.login_success)
        }

        completion(result)
    }
}

extension LogInOperation {

    struct Body: Encodable {

        // Note: These keys need to be explicitly declared using snake_case
        // because the CodingKeys are also used for request signing via `contentForSignature`.
        // swiftlint:disable:next nesting
        fileprivate enum CodingKeys: String, CodingKey {
            case appUserID = "app_user_id"
            case newAppUserID = "new_app_user_id"
            case attributes = "attributes"
            case previousUnsyncedAttributes = "previous_unsynced_attributes"
        }

        let appUserID: String
        let newAppUserID: String
        let attributes: AnyEncodable?
        let previousUnsyncedAttributes: AnyEncodable?

        init(appUserID: String,
             newAppUserID: String,
             attributes: SubscriberAttribute.Dictionary,
             previousUnsyncedAttributes: SubscriberAttribute.Dictionary) {
            self.appUserID = appUserID
            self.newAppUserID = newAppUserID
            self.attributes = Self.encodedAttributes(attributes)
            self.previousUnsyncedAttributes = Self.encodedAttributes(previousUnsyncedAttributes)
        }

        private static func encodedAttributes(_ attributes: SubscriberAttribute.Dictionary) -> AnyEncodable? {
            guard !attributes.isEmpty else { return nil }

            return AnyEncodable(SubscriberAttribute.map(subscriberAttributes: attributes))
        }

    }

    /// The body of a successful `POST /subscribers/identify` response.
    struct Response: HTTPResponseBody {

        var customerInfo: CustomerInfo
        var attributesErrorResponse: IdentifyAttributesErrorResponse?

        // swiftlint:disable:next nesting
        private struct Wrapper: Decodable {

            let attributesErrorResponse: IdentifyAttributesErrorResponse

        }

        static func create(with data: Data) throws -> Self {
            let wrapper: Wrapper? = try? JSONDecoder.default.decode(jsonData: data, logErrors: false)

            return .init(customerInfo: try CustomerInfo.create(with: data),
                         attributesErrorResponse: wrapper?.attributesErrorResponse)
        }

        func copy(with newRequestDate: Date) -> Self {
            var copy = self
            copy.customerInfo = copy.customerInfo.copy(with: newRequestDate)

            return copy
        }

    }

}

extension LogInOperation.Body: HTTPRequestBody {

    var contentForSignature: [(key: String, value: String?)] {
        // `attributes` and `previous_unsynced_attributes` are deliberately excluded: the backend hashes
        // each declared field with Python's `repr`, which no other language reproduces for nested objects,
        // so declaring them here would produce a permanent mismatch.
        return [
            (Self.CodingKeys.appUserID.stringValue, self.appUserID),
            (Self.CodingKeys.newAppUserID.stringValue, self.newAppUserID)
        ]
    }

}
