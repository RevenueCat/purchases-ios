//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockOfferingsConfigGate.swift
//
//  Created by RevenueCat.

import Foundation
@testable import RevenueCat

final class MockOfferingsConfigGate: OfferingsConfigGate, @unchecked Sendable {

    private(set) var invokedAwaitReadyCount = 0
    /// When `true`, `completion` is captured instead of called so tests control its timing.
    var shouldStoreCompletion = false
    private(set) var capturedCompletion: (() -> Void)?

    func awaitReady(completion: @escaping () -> Void) {
        self.invokedAwaitReadyCount += 1

        if self.shouldStoreCompletion {
            self.capturedCompletion = completion
        } else {
            completion()
        }
    }

    /// Fires (and clears) the captured completion. Requires `shouldStoreCompletion == true`.
    func completeStoredCompletion() {
        let completion = self.capturedCompletion
        self.capturedCompletion = nil
        completion?()
    }

}
