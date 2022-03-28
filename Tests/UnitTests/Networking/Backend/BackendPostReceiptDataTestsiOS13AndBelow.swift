//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostReceiptDataTestsiOS13AndBelow.swift
//
//  Created by Joshua Liebowitz on 3/28/22.

import Foundation
import XCTest

@testable import RevenueCat

final class BackendPostReceiptDataTestsiOS13AndBelow: BaseBackendPostReceiptDataTestClass {

    override func invokeTest() {
        guard #available(iOS 14.0.0, tvOS 14.0.0, macOS 11.0.0, watchOS 7.0, *) else {
            return super.invokeTest()
        }
        print("Skipping test because it's iOS 12 to 13.x only.")
    }

    override func createClient() -> MockHTTPClient {
        return self.createClient(#file)
    }

}
