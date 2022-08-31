//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreKit2StorefrontListener.swift
//
//  Created by Juanpe Catalán on 5/5/22.

import Foundation
import StoreKit

protocol StoreKit2StorefrontListenerDelegate: AnyObject, Sendable {

    func storefrontDidUpdate()

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class StoreKit2StorefrontListener {

    private(set) var taskHandle: Task<Void, Never>? {
        didSet {
            if self.taskHandle != oldValue {
                oldValue?.cancel()
            }
        }
    }

    weak var delegate: StoreKit2StorefrontListenerDelegate?

    init(delegate: StoreKit2StorefrontListenerDelegate?) {
        self.delegate = delegate
    }

    func listenForStorefrontChanges() {
        self.taskHandle = Task { [weak self] in
            for await _ in StoreKit.Storefront.updates {
                guard let delegate = self?.delegate else { break }
                await MainActor.run { @Sendable in
                    delegate.storefrontDidUpdate()
                }
            }
        }
    }

    deinit {
        taskHandle?.cancel()
        taskHandle = nil
    }

}
