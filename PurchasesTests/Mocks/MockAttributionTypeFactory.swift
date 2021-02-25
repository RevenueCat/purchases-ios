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

    var mockAttributionDetails: [String: NSObject] = [:]
    var mockError: Error?
    func requestAttributionDetails(_ completionHandler: RCAttributionDetailsBlock) {
        completionHandler(mockAttributionDetails, mockError)
    }
}

@available(iOS 14, macOS 11, tvOS 14, *)
class MockATTrackingManager: NSObject, FakeATTrackingManager {
    static var mockAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .denied
    static func trackingAuthorizationStatus() -> Int {
        return Int(mockAuthorizationStatus.rawValue)
    }
}

class MockAttributionTypeFactory: AttributionTypeFactory {
    override func adClientClass() -> FakeAdClient.Type? {
        return MockAdClient.self
    }

    override func trackingManagerClass() -> FakeATTrackingManager.Type? {
        if #available(iOS 14, *) {
            return MockATTrackingManager.self
        } else {
            return nil
        }
    }
}
