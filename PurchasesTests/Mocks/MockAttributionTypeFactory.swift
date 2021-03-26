//
// Created by Andrés Boedo on 2/25/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
import AppTrackingTransparency
import Purchases

class MockAdClient: NSObject, FakeAdClient {
    static func shared() -> Self {
        return sharedInstance as! Self
    }

    static var sharedInstance = MockAdClient()

    static var mockAttributionDetails: [String: NSObject] = [
        "Version3.1":
            [
                "iad-campaign-id": 15292426,
                "iad-attribution": true
            ] as NSObject
    ]
    static var mockError: Error?
    static var requestAttributionDetailsCallCount = 0

    func requestAttributionDetails(_ completionHandler: RCAttributionDetailsBlock) {
        Self.requestAttributionDetailsCallCount += 1
        completionHandler(Self.mockAttributionDetails, Self.mockError)
    }
}

@available(iOS 14, macOS 11, tvOS 14, *)
class MockTrackingManager: NSObject, FakeTrackingManager {
    static var mockAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .authorized

    static func trackingAuthorizationStatus() -> Int {
        return Int(mockAuthorizationStatus.rawValue)
    }
}

class MockAttributionTypeFactory: AttributionTypeFactory {
    static var shouldReturnAdClientClass = true

    override func adClientClass() -> FakeAdClient.Type? {
        return Self.shouldReturnAdClientClass ? MockAdClient.self : nil
    }

    static var shouldReturnTrackingManagerClass = true

    override func atTrackingClass() -> FakeTrackingManager.Type? {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            return Self.shouldReturnTrackingManagerClass ? MockTrackingManager.self : nil
        } else {
            return nil
        }
    }
}
