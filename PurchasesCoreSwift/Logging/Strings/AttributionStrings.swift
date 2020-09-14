//
//  AttributionStrings.swift
//  PurchasesCoreSwift
//
//  Created by Andrés Boedo on 9/14/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCAttributionStrings) public class AttributionStrings: NSObject {
    @objc public var instance_configured_posting_attribution: String { "There is an instance configured, posting attribution." }
    @objc public var no_instance_configured_caching_attribution: String { "There is no instance configured, caching attribution." }
}
