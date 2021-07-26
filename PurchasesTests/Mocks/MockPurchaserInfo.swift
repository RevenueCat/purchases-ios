//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockPurchaserInfo.swift
//
//  Created by Madeline Beyl on 7/26/21.

import Foundation
@testable import PurchasesCoreSwift

class MockPurchaserInfo: PurchasesCoreSwift.PurchaserInfo {
    
    @objc override public init?(data: [AnyHashable: Any]) {
        
        var validData = data
        validData["request_date"] = validData["request_date"] ?? "2019-08-16T10:30:42Z"
        
        var validSubscriberData: [String: Any] = validData["subscriber"] as? [String: Any] ?? [String: Any]()
                                                                                               
        validSubscriberData["first_seen"] = validSubscriberData["first_seen"] ?? "2019-07-17T00:05:54Z"
        validSubscriberData["original_app_user_id"] = validSubscriberData["original_app_user_id"] ?? "app_user_id"
        
        super.init(data: validData)
        
    }
}
