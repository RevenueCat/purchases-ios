//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesTestStandIn.swift
//
//  Created by Joshua Liebowitz on 8/20/21.

import Foundation

// This class is used during unit testing on ARM64. We cannot check for fatalError() in tests. Instead of skipping
// testing on that platform for the fatalError() that should occure when we call .sharedPurchases before
// .configure/init, we substitute this class as the return and check for it. If this class is used at all, which
// it shouldn't be due to internal visibility.
@objc class PurchasesTestStandIn: Purchases {

}
