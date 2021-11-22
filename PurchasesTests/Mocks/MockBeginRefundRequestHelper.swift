//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockBeginRefundRequestHelper.swift
//
//  Created by Madeline Beyl on 10/15/21.

import Foundation
@testable import RevenueCat

class MockBeginRefundRequestHelper: BeginRefundRequestHelper {

    var maybeMockError: Error?
    var maybeMockRefundRequestStatus: RefundRequestStatus?

#if os(iOS) || targetEnvironment(macCatalyst)
    @available(iOS 15.0, macCatalyst 15, *)
    @available(watchOS, unavailable)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    override func beginRefundRequest(productID: String,
                                     completion: @escaping (Result<RefundRequestStatus, Error>) -> Void) {
        if let error = maybeMockError {
            completion(.failure(error))
        } else {
            completion(.success(maybeMockRefundRequestStatus ?? RefundRequestStatus.success))
        }
    }
#endif

}
