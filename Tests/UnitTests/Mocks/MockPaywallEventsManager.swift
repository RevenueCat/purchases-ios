//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockPaywallEventsManager.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation
@testable import RevenueCat

final class MockPaywallEventsManager: PaywallEventsManagerType {

    func track(paywallEvent: PaywallEvent) async {}
    func flushEvents(count: Int) async {}

}
