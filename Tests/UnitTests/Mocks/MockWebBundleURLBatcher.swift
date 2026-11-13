//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockWebBundleURLBatcher.swift
//
//  Created by Jacob Zivan Rakidzich on 8/14/26.

import Foundation
@_spi(Internal) @testable import RevenueCat

final class MockWebBundleURLBatcher: WebBundleURLBatcherType, @unchecked Sendable {

    private let onPublish: (@Sendable () -> Void)?
    private let _invokedPublishCount: Atomic<Int> = .init(0)
    private let _invokedPublishScreenURLBatches: Atomic<[[WebBundleScreenURLBatch]]> = .init([])

    var invokedPublishCount: Int {
        return self._invokedPublishCount.value
    }
    var invokedPublishScreenURLBatches: [[WebBundleScreenURLBatch]] {
        return self._invokedPublishScreenURLBatches.value
    }

    init(onPublish: (@Sendable () -> Void)? = nil) {
        self.onPublish = onPublish
    }

    @available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
    func publish(_ batches: [WebBundleScreenURLBatch]) async {
        self.onPublish?()
        self._invokedPublishCount.modify { $0 += 1 }
        self._invokedPublishScreenURLBatches.modify { $0.append(batches) }
    }

}
