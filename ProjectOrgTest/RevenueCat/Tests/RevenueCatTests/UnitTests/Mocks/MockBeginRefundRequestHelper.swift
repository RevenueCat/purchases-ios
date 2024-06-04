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

    var mockError: Error?
    var mockRefundRequestStatus: RefundRequestStatus?

#if os(iOS) || VISION_OS
    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    override func beginRefundRequest(forProduct productID: String) async throws -> RefundRequestStatus {
        if let error = mockError {
            throw error
        } else {
            return mockRefundRequestStatus ?? RefundRequestStatus.success
        }
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    override func beginRefundRequest(forEntitlement entitlementID: String) async throws -> RefundRequestStatus {
        if let error = mockError {
            throw error
        } else {
            return mockRefundRequestStatus ?? RefundRequestStatus.success
        }
    }

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(tvOS, unavailable)
    override func beginRefundRequestForActiveEntitlement() async throws -> RefundRequestStatus {
        if let error = mockError {
            throw error
        } else {
            return mockRefundRequestStatus ?? RefundRequestStatus.success
        }
    }
#endif

}
