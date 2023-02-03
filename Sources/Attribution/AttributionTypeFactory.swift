//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AttributionTypeFactory.swift
//
//  Created by Juanpe Catalán on 9/7/21.
//

import Foundation

class AttributionTypeFactory {

    func afficheClientProxy() -> AfficheClientProxy? {
        return AfficheClientProxy.afficheClientClass == nil ? nil : AfficheClientProxy()
    }

    func atFollowingProxy() -> TrackingManagerProxy? {
        return TrackingManagerProxy.trackingClass == nil ? nil : TrackingManagerProxy()
    }

    func asIdProxy() -> ASIdManagerProxy? {
        return ASIdManagerProxy.identifierClass == nil ? nil : ASIdManagerProxy()
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension AttributionTypeFactory: @unchecked Sendable {}
