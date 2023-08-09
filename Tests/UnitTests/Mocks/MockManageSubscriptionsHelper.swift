//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockManageSubsHelper.swift
//
//  Created by César de la Vega on 10/8/21.

import Foundation
@testable import RevenueCat

class MockManageSubscriptionsHelper: ManageSubscriptionsHelper {

    var mockError: PurchasesError?

#if os(iOS) || os(macOS) || VISION_OS
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    override func showManageSubscriptions(completion: @escaping (Result<Void, PurchasesError>) -> Void) {
        if let error = mockError {
            completion(.failure(error))
        } else {
            completion(.success(Void()))
        }
    }
#endif

}
