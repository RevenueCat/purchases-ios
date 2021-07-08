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

    @objc public let data: NSDictionary
    @objc public let network: AttributionNetwork
    @objc public let networkUserId: String?

    @objc public init(data: NSDictionary, fromNetwork network: AttributionNetwork, forNetworkUserId networkUserId: String?) {
        self.data = data
        self.network = network
        self.networkUserId = networkUserId
    }
}
