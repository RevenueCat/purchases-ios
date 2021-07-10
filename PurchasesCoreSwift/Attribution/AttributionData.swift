//
//  AttributionData.swift
//  PurchasesCoreSwift
//
//  Created by Madeline Beyl on 7/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

// TODO(post-migration): Make this internal
@objc(RCAttributionData) public class AttributionData: NSObject {

    @objc public var data: [AnyHashable: Any]
    @objc public var network: AttributionNetwork
    @objc public var networkUserId: String?

    @objc public init(data: [AnyHashable: Any], network: AttributionNetwork, networkUserId: String?) {
        self.data = data
        self.network = network
        self.networkUserId = networkUserId
    }
}
