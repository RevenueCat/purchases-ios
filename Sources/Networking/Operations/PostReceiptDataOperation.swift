//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostReceiptDataOperation.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

final class PostReceiptDataOperation: CacheableNetworkOperation {

    private let postData: PostData
    private let configuration: AppUserConfiguration
    private let customerInfoResponseHandler: CustomerInfoResponseHandler
    private let customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>

    static func createFactory(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>,
        offlineCustomerInfoCreator: OfflineCustomerInfoCreator?
    ) -> CacheableNetworkOperationFactory<PostReceiptDataOperation> {
        return Self.createFactory(
            configuration: configuration,
            postData: postData,
            customerInfoResponseHandler: .init(
                offlineCreator: offlineCustomerInfoCreator,
                userID: configuration.appUserID
            ),
            customerInfoCallbackCache: customerInfoCallbackCache
        )
    }

    static func createFactory(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        customerInfoResponseHandler: CustomerInfoResponseHandler,
        customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>
    ) -> CacheableNetworkOperationFactory<PostReceiptDataOperation> {
        /// Cache key comprises of the following:
        /// - `appUserID`
        /// - `isRestore`
        /// - Receipt (`hashString` instead of `fetchToken` to avoid big receipts leading to a huge cache key)
        /// - `ProductRequestData.cacheKey`
        /// - `presentedOfferingIdentifier`
        /// - `observerMode`
        /// - `subscriberAttributesByKey`
        let cacheKey =
        """
        \(configuration.appUserID)-\(postData.isRestore)-\(postData.receipt.hash)
        -\(postData.productData?.cacheKey ?? "")
        -\(postData.presentedOfferingIdentifier ?? "")-\(postData.observerMode)
        -\(postData.subscriberAttributesByKey?.debugDescription ?? "")
        """

        return .init({ cacheKey in
                    .init(
                        configuration: configuration,
                        postData: postData,
                        customerInfoResponseHandler: customerInfoResponseHandler,
                        customerInfoCallbackCache: customerInfoCallbackCache,
                        cacheKey: cacheKey
                    )
            },
            individualizedCacheKeyPart: cacheKey
        )
    }

    private init(
        configuration: UserSpecificConfiguration,
        postData: PostData,
        customerInfoResponseHandler: CustomerInfoResponseHandler,
        customerInfoCallbackCache: CallbackCache<CustomerInfoCallback>,
        cacheKey: String
    ) {
        self.customerInfoResponseHandler = customerInfoResponseHandler
        self.customerInfoCallbackCache = customerInfoCallbackCache
        self.postData = postData
        self.configuration = configuration

        super.init(configuration: configuration, cacheKey: cacheKey)
    }

    override func begin(completion: @escaping () -> Void) {
        if Logger.logLevel <= .debug {
            self.printReceiptData()
        }

        self.post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {
        let request = HTTPRequest(method: .post(self.postData), path: .postReceiptData)

        self.httpClient.perform(
            request
        ) { (response: VerifiedHTTPResponse<CustomerInfoResponseHandler.Response>.Result) in
            self.customerInfoResponseHandler.handle(customerInfoResponse: response) { result in
                self.customerInfoCallbackCache.performOnAllItemsAndRemoveFromCache(
                    withCacheable: self
                ) { callbackObject in
                    callbackObject.completion(result)
                }
            }

            completion()
        }
    }

}

extension PostReceiptDataOperation {

    struct PostData {

        let appUserID: String
        let receipt: EncodedAppleReceipt
        let isRestore: Bool
        let productData: ProductRequestData?
        let presentedOfferingIdentifier: String?
        let paywall: Paywall?
        let observerMode: Bool
        let initiationSource: ProductRequestData.InitiationSource
        let subscriberAttributesByKey: SubscriberAttribute.Dictionary?
        let aadAttributionToken: String?
        /// - Note: this is only used for the backend to disambiguate receipts created in `SKTestSession`s.
        let testReceiptIdentifier: String?

    }

    struct Paywall {

        var sessionID: String
        var revision: Int
        var displayMode: PaywallViewMode
        var darkMode: Bool
        var localeIdentifier: String

    }

}

extension PostReceiptDataOperation.PostData {

    init(
        transactionData data: PurchasedTransactionData,
        productData: ProductRequestData?,
        receipt: EncodedAppleReceipt,
        observerMode: Bool,
        testReceiptIdentifier: String?
    ) {
        self.init(
            appUserID: data.appUserID,
            receipt: receipt,
            isRestore: data.source.isRestore,
            productData: productData,
            presentedOfferingIdentifier: data.presentedOfferingID,
            paywall: data.paywall,
            observerMode: observerMode,
            initiationSource: data.source.initiationSource,
            subscriberAttributesByKey: data.unsyncedAttributes,
            aadAttributionToken: data.aadAttributionToken,
            testReceiptIdentifier: testReceiptIdentifier
        )
    }

}

private extension PurchasedTransactionData {

    var paywall: PostReceiptDataOperation.Paywall? {
        guard let paywall = self.presentedPaywall else { return nil }

        return .init(sessionID: paywall.data.sessionIdentifier.uuidString,
                     revision: paywall.data.paywallRevision,
                     displayMode: paywall.data.displayMode,
                     darkMode: paywall.data.darkMode,
                     localeIdentifier: paywall.data.localeIdentifier)
    }

}

// MARK: - Private

private extension PostReceiptDataOperation {

    func printReceiptData() {
        switch self.postData.receipt {
        case .jws(let content):
            self.log(Strings.receipt.posting_jws(
                content,
                initiationSource: self.postData.initiationSource.rawValue
            ))
        case .sk2receipt(let receipt):
            self.log(Strings.receipt.posting_jws(
                (try? receipt.prettyPrintedJSON) ?? "",
                initiationSource: self.postData.initiationSource.rawValue
            ))
        case .receipt(let data):
            do {
                let receipt = try PurchasesReceiptParser.default.parse(from: data)
                self.log(Strings.receipt.posting_receipt(
                    receipt,
                    initiationSource: self.postData.initiationSource.rawValue
                ))

                for purchase in receipt.inAppPurchases where purchase.purchaseDateEqualsExpiration {
                    Logger.appleError(Strings.receipt.receipt_subscription_purchase_equals_expiration(
                        productIdentifier: purchase.productId,
                        purchase: purchase.purchaseDate,
                        expiration: purchase.expiresDate
                    ))
                }

            } catch {
                Logger.appleError(Strings.receipt.parse_receipt_locally_error(error: error))
            }
        }
    }

}

// MARK: - Codable

extension PostReceiptDataOperation.PostData: Encodable {

    private enum CodingKeys: String, CodingKey {

        case fetchToken = "fetch_token"
        case appUserID = "app_user_id"
        case isRestore
        case observerMode
        case initiationSource
        case attributes
        case aadAttributionToken
        case presentedOfferingIdentifier
        case paywall
        case testReceiptIdentifier = "test_receipt_identifier"

    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.fetchToken, forKey: .fetchToken)
        try container.encode(self.appUserID, forKey: .appUserID)
        try container.encode(self.isRestore, forKey: .isRestore)
        try container.encode(self.observerMode, forKey: .observerMode)
        try container.encode(self.initiationSource, forKey: .initiationSource)

        if let productData = self.productData {
            try productData.encode(to: encoder)
        }

        try container.encodeIfPresent(self.presentedOfferingIdentifier, forKey: .presentedOfferingIdentifier)
        try container.encodeIfPresent(self.paywall, forKey: .paywall)

        try container.encodeIfPresent(
            self.subscriberAttributesByKey
                .map(SubscriberAttribute.map)
                .map(AnyEncodable.init),
            forKey: .attributes
        )

        try container.encodeIfPresent(self.aadAttributionToken, forKey: .aadAttributionToken)
        try container.encodeIfPresent(self.testReceiptIdentifier, forKey: .testReceiptIdentifier)
    }

    var fetchToken: String { return self.receipt.serialized() }

}

extension PostReceiptDataOperation.Paywall: Codable {

    private enum CodingKeys: String, CodingKey {

        case sessionID = "sessionId"
        case revision
        case displayMode
        case darkMode
        case localeIdentifier = "locale"

    }

}

// MARK: - HTTPRequestBody

extension PostReceiptDataOperation.PostData: HTTPRequestBody {

    var contentForSignature: [(key: String, value: String)] {
        return [
            (Self.CodingKeys.appUserID.stringValue, self.appUserID),
            (Self.CodingKeys.fetchToken.stringValue, self.fetchToken)
        ]
    }

}

// MARK: - InitiationSource

extension ProductRequestData.InitiationSource: Encodable, RawRepresentable {

    var rawValue: String {
        switch self {
        case .restore: return "restore"
        case .purchase: return "purchase"
        case .queue: return "queue"
        }
    }

    init?(rawValue: String) {
        guard let value = Self.codes[rawValue] else { return nil }

        self = value
    }

    private static let codes: [String: ProductRequestData.InitiationSource] = Self
        .allCases
        .dictionaryWithKeys { $0.rawValue }

}

// MARK: - EncodedAppleReceipt

private extension EncodedAppleReceipt {

    var hash: String {
        switch self {
        case let .jws(content):
            return content.asData.hashString
        case let .receipt(data):
            return data.hashString
        case .sk2receipt(let receipt):
            do {
                return try receipt.jsonEncodedData.hashString
            } catch {
                Logger.warn(Strings.storeKit.sk2_error_encoding_receipt(error))
                return ""
            }
        }
    }

}
