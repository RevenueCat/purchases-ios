//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManager.swift
//
//  Created by Andrés Boedo on 7/14/20.
//

import Foundation
import StoreKit

class ProductsManager: NSObject {

    let productsFetcherSK1: ProductsFetcherSK1
    var requestTimeout: TimeInterval {
        return productsFetcherSK1.requestTimeout
    }

    private let systemInfo: SystemInfo

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private(set) lazy var productsFetcherSK2 = ProductsFetcherSK2()

    init(
        productsRequestFactory: ProductsRequestFactory = ProductsRequestFactory(),
        systemInfo: SystemInfo,
        requestTimeout: TimeInterval
    ) {
        self.productsFetcherSK1 = ProductsFetcherSK1(productsRequestFactory: productsRequestFactory,
                                                     requestTimeout: requestTimeout)
        self.systemInfo = systemInfo
    }

    func products(withIdentifiers identifiers: Set<String>,
                  completion: @escaping (Result<Set<StoreProduct>, Error>) -> Void) {
        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *),
           self.systemInfo.storeKit2Setting == .enabledForCompatibleDevices {
            self.sk2Products(withIdentifiers: identifiers) { result in
                completion(result.map { Set($0.map(StoreProduct.from(product:))) })
            }
        } else {
            self.sk1Products(withIdentifiers: identifiers) { result in
                completion(result.map { Set($0.map(StoreProduct.init(sk1Product:))) })
            }
        }
    }

    @available(iOS 13.0, tvOS 13.0, watchOS 6.2, macOS 10.15, *)
    func products(withIdentifiers identifiers: Set<String>) async throws -> Set<StoreProduct> {
        return try await withCheckedThrowingContinuation { continuation in
            self.products(withIdentifiers: identifiers) { result in
                continuation.resume(with: result)
            }
        }
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func sk2StoreProducts(withIdentifiers identifiers: Set<String>) async throws -> Set<SK2StoreProduct> {
        let products = try await productsFetcherSK2.products(identifiers: identifiers)

        return Set(products)
    }

    func cacheProduct(_ product: SK1Product) {
        productsFetcherSK1.cacheProduct(product)
    }

    private func sk1Products(withIdentifiers identifiers: Set<String>,
                             completion: @escaping (Result<Set<SK1Product>, Error>) -> Void) {
        return productsFetcherSK1.sk1Products(withIdentifiers: identifiers, completion: completion)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    private func sk2Products(withIdentifiers identifiers: Set<String>,
                             completion: @escaping (Result<Set<SK2StoreProduct>, Error>) -> Void) {
        _ = Task<Void, Never> {
            do {
                let products = try await self.sk2StoreProducts(withIdentifiers: identifiers)
                completion(.success(Set(products)))
            } catch {
                completion(.failure(error))
            }
        }
    }

}
