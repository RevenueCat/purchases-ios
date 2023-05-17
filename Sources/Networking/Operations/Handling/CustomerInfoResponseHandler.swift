//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerInfoResponseHandler.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

class CustomerInfoResponseHandler {

    private let purchasedProductsFetcher: PurchasedProductsFetcherType
    private let productEntitlementMapping: ProductEntitlementMapping?
    private let customerInfoCreator: CustomerInfo.OfflineCreator
    private let userID: String
    // Allows temporarily disabling the feature until it's fully ready
    private let offlineEntitlementsEnabled: Bool

    convenience init(
        purchasedProductsFetcher: PurchasedProductsFetcherType,
        productEntitlementMapping: ProductEntitlementMapping?,
        userID: String,
        offlineEntitlementsEnabled: Bool = false
    ) {
        self.init(
            purchasedProductsFetcher: purchasedProductsFetcher,
            productEntitlementMapping: productEntitlementMapping,
            customerInfoCreator: { products, mapping, userID in
                CustomerInfo(from: products, mapping: mapping, userID: userID)
            },
            userID: userID,
            offlineEntitlementsEnabled: offlineEntitlementsEnabled
        )
    }

    init(
        purchasedProductsFetcher: PurchasedProductsFetcherType,
        productEntitlementMapping: ProductEntitlementMapping?,
        customerInfoCreator: @escaping CustomerInfo.OfflineCreator,
        userID: String,
        offlineEntitlementsEnabled: Bool = false
    ) {
        self.purchasedProductsFetcher = purchasedProductsFetcher
        self.productEntitlementMapping = productEntitlementMapping
        self.customerInfoCreator = customerInfoCreator
        self.userID = userID
        self.offlineEntitlementsEnabled = offlineEntitlementsEnabled
    }

    func handle(customerInfoResponse response: HTTPResponse<Response>.Result,
                completion: @escaping CustomerAPI.CustomerInfoResponseHandler) {
        let result: Result<CustomerInfo, BackendError> = response
            .map { response in
                // If the response was successful we always want to return the `CustomerInfo`.
                if !response.body.errorResponse.attributeErrors.isEmpty {
                    // If there are any, log attribute errors.
                    // Creating the error implicitly logs it.
                    _ = response.body.errorResponse.asBackendError(with: response.statusCode)
                }

                return response.body.customerInfo.copy(with: response.verificationResult)
            }
            .mapError(BackendError.networkError)

        self.handle(result: result, completion: completion)
    }

    private func handle(
        result: Result<CustomerInfo, BackendError>,
        completion: @escaping CustomerAPI.CustomerInfoResponseHandler
    ) {
        guard self.offlineEntitlementsEnabled,
              result.error?.isServerDown == true,
              #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) else {
            completion(result)
            return
        }

        _ = Task<Void, Never> {
            do {
                completion(.success(try await self.computeOfflineCustomerInfo()))
            } catch {
                Logger.error(Strings.offlineEntitlements.computing_offline_customer_info_failed(error))
                completion(result)
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private func computeOfflineCustomerInfo() async throws -> CustomerInfo {
        return try await CustomerInfo.createOffline(
            with: self.productEntitlementMapping,
            fetcher: self.purchasedProductsFetcher,
            creator: self.customerInfoCreator,
            userID: self.userID
        )
    }

}

extension CustomerInfoResponseHandler {

    struct Response: HTTPResponseBody {

        var customerInfo: CustomerInfo
        var errorResponse: ErrorResponse

        static func create(with data: Data) throws -> Self {
            return .init(customerInfo: try CustomerInfo.create(with: data),
                         errorResponse: ErrorResponse.from(data))
        }

        func copy(with newRequestDate: Date) -> Self {
            var copy = self
            copy.customerInfo = copy.customerInfo.copy(with: newRequestDate)

            return copy
        }

    }

}
