//
//  AttributionTypeFactory.swift
//  PurchasesCoreSwift
//
//  Created by Juanpe Catalán on 9/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

// TODO(Post-migration): switch this back to internal the class and all these protocols and properties.

@objc(RCAttributionTypeFactory)
open class AttributionTypeFactory: NSObject {
    @objc open func adClientProxy() -> AdClientProxy? {
        guard AdClientProxy.adClientClass != nil else { return nil }
        return AdClientProxy()
    }

    @objc open func atTrackingProxy() -> TrackingManagerProxy? {
        guard TrackingManagerProxy.trackingClass != nil else { return nil }
        return TrackingManagerProxy()
    }

    @objc open func asIdentifierProxy() -> ASIdentifierManagerProxy? {
        guard ASIdentifierManagerProxy.identifierClass != nil else { return nil }
        return ASIdentifierManagerProxy()
    }
}
