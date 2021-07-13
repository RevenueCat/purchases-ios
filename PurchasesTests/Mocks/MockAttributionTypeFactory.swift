//
// Created by Andrés Boedo on 2/25/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
import AppTrackingTransparency

class MockAdClientProxy: AdClientProxy {
    static var mockAttributionDetails: [String: NSObject] = [
        "Version3.1":
            [
                "iad-campaign-id": 15292426,
                "iad-attribution": true
            ] as NSObject
    ]
    static var mockError: Error?
    static var requestAttributionDetailsCallCount = 0

    override func requestAttributionDetails(_ completionHandler: ([String : Any]?, Error?) -> Void) {
        Self.requestAttributionDetailsCallCount += 1
        completionHandler(Self.mockAttributionDetails, Self.mockError)
    }
}

@available(iOS 14, macOS 11, tvOS 14, *)
class MockTrackingManagerProxy: TrackingManagerProxy {
    static var mockAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .authorized
    
    override func trackingAuthorizationStatus() -> Int {
        Int(Self.mockAuthorizationStatus.rawValue)
    }
}

class MockAttributionTypeFactory: AttributionTypeFactory {
    static var shouldReturnAdClientProxy = true

    override func adClientProxy() -> AdClientProxy? {
        Self.shouldReturnAdClientProxy ? MockAdClientProxy() : nil
    }

    static var shouldReturnTrackingManagerProxy = true

    override func atTrackingProxy() -> TrackingManagerProxy? {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            return Self.shouldReturnTrackingManagerProxy ? MockTrackingManagerProxy() : nil
        } else {
            return nil
        }
    }
}
