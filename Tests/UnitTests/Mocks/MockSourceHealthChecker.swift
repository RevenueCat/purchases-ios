//
//  MockSourceHealthChecker.swift
//  RevenueCat
//
//  Created by Toni Rico on 27/07/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.

import Foundation
@testable import RevenueCat

/// Completes synchronously with `stubbedIsHealthy`, recording every probed source URL.
final class MockSourceHealthChecker: SourceHealthCheckerType, @unchecked Sendable {

    let stubbedIsHealthy: Atomic<Bool> = .init(true)
    let checkedSourceURLs: Atomic<[URL]> = .init([])

    func checkHealth(ofSourceBaseURL url: URL, completion: @escaping @Sendable (Bool) -> Void) {
        self.checkedSourceURLs.modify { $0.append(url) }
        completion(self.stubbedIsHealthy.value)
    }

}
