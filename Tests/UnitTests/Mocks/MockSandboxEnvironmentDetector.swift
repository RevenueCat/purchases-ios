//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockSandboxEnvironmentDetector.swift
//
//  Created by Nacho Soto on 6/2/22.

@testable import RevenueCat

final class MockSandboxEnvironmentDetector: SandboxEnvironmentDetector {

    init(isSandbox: Bool = true) {
        self.isSandbox = isSandbox
    }

    let isSandbox: Bool

}
