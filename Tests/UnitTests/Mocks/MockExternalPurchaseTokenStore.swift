//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockExternalPurchaseTokenStore.swift
//
//  Created by Antonio Pallares on 10/9/26.

import Foundation
@testable import RevenueCat

final class MockExternalPurchaseTokenStore: ExternalPurchaseTokenStoreType {

    private let storage: Atomic<[ExternalPurchaseTokenRegistration]> = .init([])

    var storedRegistrations: [ExternalPurchaseTokenRegistration] { return self.storage.value }

    func store(_ registration: ExternalPurchaseTokenRegistration) {
        self.storage.modify { $0.append(registration) }
    }

    func remove(_ registration: ExternalPurchaseTokenRegistration) {
        self.storage.modify { $0.removeAll { $0 == registration } }
    }

}
