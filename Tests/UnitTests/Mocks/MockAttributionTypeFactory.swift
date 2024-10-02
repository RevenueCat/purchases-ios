//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// Created by Andrés Boedo on 2/25/21.
//

import Foundation
#if canImport(AppTrackingTransparency)
  import AppTrackingTransparency
#endif
@testable import RevenueCat

@available(iOS 14, macOS 11, tvOS 14, *)
class MockTrackingManagerProxy: TrackingManagerProxy {

    #if !os(watchOS)
    @available(iOS 14, macOS 11, tvOS 14, *)
    static var mockAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .authorized
    #endif

    override func trackingAuthorizationStatus() -> Int {
        #if os(watchOS)
        return 0
        #else
        Int(Self.mockAuthorizationStatus.rawValue)
        #endif
    }

}

class MockAttributionTypeFactory: AttributionTypeFactory {

    static var shouldReturnAdClientProxy = true

    static var shouldReturnTrackingManagerProxy = true

    override func atFollowingProxy() -> TrackingManagerProxy? {
        if #available(iOS 14, macOS 11, tvOS 14, *) {
            return Self.shouldReturnTrackingManagerProxy ? MockTrackingManagerProxy() : nil
        } else {
            return nil
        }
    }

}

extension MockAttributionTypeFactory: @unchecked Sendable {}
