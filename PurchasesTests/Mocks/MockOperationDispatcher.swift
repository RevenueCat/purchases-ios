//
// Created by Andrés Boedo on 8/5/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

@testable import PurchasesCoreSwift

class MockOperationDispatcher: OperationDispatcher {
    override func dispatchOnMainThread(_ block: @escaping () -> Void) {
        block()
    }

    override func dispatchOnWorkerThread(_ block: @escaping () -> Void) {
        block()
    }
}
