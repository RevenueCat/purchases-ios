//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockSubscriberDimensionsStore.swift
//
//  Created by Rick van der Linden on 10/5/26.
//

import Foundation
@testable import RevenueCat

final class MockSubscriberDimensionsStore: SubscriberDimensionsStoreType, @unchecked Sendable {

    let invokedStoreParameters: Atomic<(customerInfo: CustomerInfo, appUserID: String)?> = nil
    let invokedDiscardParameters: Atomic<(appUserID: String, supersededAt: UInt64)?> = nil
    let stubbedDimensions: Atomic<[String: SubscriberDimensions]> = .init([:])

    func store(_ customerInfo: CustomerInfo, appUserID: String) {
        self.invokedStoreParameters.value = (customerInfo, appUserID)
    }

    func dimensions(appUserID: String) -> SubscriberDimensions? {
        return self.stubbedDimensions.value[appUserID]
    }

    func discard(appUserID: String, ifNotNewerThan supersededAt: UInt64) {
        self.invokedDiscardParameters.value = (appUserID, supersededAt)
    }

}
