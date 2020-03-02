//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockSKProduct: SKProduct {

    var mockIdentifier: String?
    override var productIdentifier: String {
        get {
            return mockIdentifier!
        }
    }

    init(mockIdentifier: String?) {
        self.mockIdentifier = mockIdentifier
        super.init()
    }
}
