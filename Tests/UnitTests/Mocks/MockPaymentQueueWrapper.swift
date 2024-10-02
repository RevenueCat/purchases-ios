//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockPaymentQueueWrapper.swift
//
//  Created by Nacho Soto on 9/12/22.

@testable import RevenueCat

import StoreKit

class MockPaymentQueueWrapper: PaymentQueueWrapper {

    weak var mockDelegate: PaymentQueueWrapperDelegate?
    override var delegate: PaymentQueueWrapperDelegate? {
        get { return self.mockDelegate }
        set { self.mockDelegate = newValue }
    }

}

extension MockPaymentQueueWrapper: @unchecked Sendable {}
