//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostReceiptDataTestsiOS14AndAbove.swift
//
//  Created by Joshua Liebowitz on 3/28/22.

import Foundation
import XCTest

@testable import RevenueCat

final class BackendPostReceiptDataTestsiOS14AndAbove: BaseBackendPostReceiptDataTestClass {

    override func invokeTest() {
        if #available(iOS 14.0, tvOS 14.0, macOS 11.0, watchOS 6.2, *) {
            return super.invokeTest()
        } else {
            print("Skipping test because it's iOS 14+ only.")
            return
        }
    }

    override func createClient() -> MockHTTPClient {
        return self.createClient(#file)
    }

}
