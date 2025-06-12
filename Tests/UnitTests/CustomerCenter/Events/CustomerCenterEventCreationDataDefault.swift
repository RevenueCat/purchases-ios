//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterEventCreationDataDefault.swift
//
//  Created by Facundo Menzella on 29/1/25.

import Foundation
@_spi(Internal) @testable import RevenueCat
import SnapshotTesting

extension CustomerCenterEventCreationData {
    static var `default`: CustomerCenterEventCreationData {
        CustomerCenterEventCreationData(
            id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
            date: .init(timeIntervalSince1970: 1694029328)
        )
    }
}
