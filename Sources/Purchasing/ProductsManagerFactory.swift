//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductsManagerFactory.swift
//
//  Created by Antonio Pallares on 25/7/25.

import Foundation

enum ProductsManagerFactory {

    static func createManager(apiKeyValidationResult: Configuration.APIKeyValidationResult,
                              diagnosticsTracker: DiagnosticsTrackerType?,
                              systemInfo: SystemInfo,
                              backend: Backend,
                              deviceCache: DeviceCache,
                              requestTimeout: TimeInterval) -> ProductsManagerType {
            #if TEST_STORE
            if apiKeyValidationResult == .testStore {
                return TestStoreProductsManager(backend: backend,
                                                deviceCache: deviceCache,
                                                requestTimeout: requestTimeout)
            }
            #endif // TEST_STORE

            return ProductsManager(productsRequestFactory: ProductsRequestFactory(),
                                   diagnosticsTracker: diagnosticsTracker,
                                   systemInfo: systemInfo,
                                   requestTimeout: requestTimeout)
    }

}
