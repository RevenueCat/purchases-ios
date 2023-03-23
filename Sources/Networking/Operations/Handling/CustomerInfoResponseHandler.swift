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

    typealias CustomerInfoCreator = ([PurchasedSK2Product],
                                     ProductEntitlementMapping,
                                     String) -> CustomerInfo

    private let purchasedProductsFetcher: PurchasedProductsFetcherType
    private let productEntitlementMapping: ProductEntitlementMapping?
    private let customerInfoCreator: CustomerInfoCreator
    private let userID: String

    convenience init(
        purchasedProductsFetcher: PurchasedProductsFetcherType,
        productEntitlementMapping: ProductEntitlementMapping?,
        userID: String
    ) {
        self.init(
            purchasedProductsFetcher: purchasedProductsFetcher,
            productEntitlementMapping: productEntitlementMapping,
            customerInfoCreator: { products, mapping, userID in
                CustomerInfo(from: products, mapping: mapping, userID: userID)
            },
            userID: userID)
    }

    init(
        purchasedProductsFetcher: PurchasedProductsFetcherType,
        productEntitlementMapping: ProductEntitlementMapping?,
        customerInfoCreator: @escaping CustomerInfoCreator,
        userID: String
    ) {
        self.purchasedProductsFetcher = purchasedProductsFetcher
        self.productEntitlementMapping = productEntitlementMapping
        self.customerInfoCreator = customerInfoCreator
        self.userID = userID
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
        guard result.error?.isServerDown == true,
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

private extension CustomerInfoResponseHandler {

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func computeOfflineCustomerInfo() async throws -> CustomerInfo {
        Logger.info(Strings.offlineEntitlements.computing_offline_customer_info)

        let products = try await self.purchasedProductsFetcher.fetchPurchasedProducts()

        if self.productEntitlementMapping == nil {
            Logger.warn(Strings.offlineEntitlements.computing_offline_customer_info_with_no_entitlement_mapping)
        }

        let offlineCustomerInfo = self.customerInfoCreator(
            products,
            self.productEntitlementMapping ?? .empty,
            self.userID
        )

        // TODO: merge with existing one?

        return offlineCustomerInfo
    }

}
