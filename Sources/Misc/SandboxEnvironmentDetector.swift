//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SandboxEnvironmentDetector.swift
//
//  Created by Nacho Soto on 6/2/22.

import Foundation

/// A type that can determine if the current environment is sandbox.
protocol SandboxEnvironmentDetector: Sendable {

    var isSandbox: Bool { get }

}

/// ``SandboxEnvironmentDetector`` that uses a `Bundle` to detect the environment
final class BundleSandboxEnvironmentDetector: SandboxEnvironmentDetector {

    private let bundle: Bundle
    private let isRunningInSimulator: Bool

    init(bundle: Bundle = .main, isRunningInSimulator: Bool = SystemInfo.isRunningInSimulator) {
        self.bundle = bundle
        self.isRunningInSimulator = isRunningInSimulator
    }

    var isSandbox: Bool {
        guard !isRunningInSimulator else {
            return true
        }
        
        guard let path = self.bundle.appStoreReceiptURL?.path else {
            return false
        }

        // `true` for either `macOS` or `Catalyst`
        let isMASReceipt = path.contains("MASReceipt/receipt")
        if isMASReceipt {
            return path.contains("Xcode/DerivedData")
        } else {
            return path.contains("sandboxReceipt")
        }
    }

    #if DEBUG
    // Mutable in tests so it can be overriden
    static var `default`: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector()
    #else
    static let `default`: SandboxEnvironmentDetector = BundleSandboxEnvironmentDetector()
    #endif

}

#if swift(<5.8)
// `Bundle` is not `Sendable` as of Swift 5.7, but this class performs no mutations.
extension BundleSandboxEnvironmentDetector: @unchecked Sendable {}
#endif
