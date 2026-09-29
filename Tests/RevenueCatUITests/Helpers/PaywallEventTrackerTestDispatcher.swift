//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Created by Monika Mateska on 09/04/2026.

import Foundation
@testable import RevenueCat
@testable import RevenueCatUI

/// Executes test events in submission order, including when an event suspends.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
enum PaywallEventTrackerTestDispatcher {

    static var value: PaywallEventTracker.EventDispatcher {
        let tail: Atomic<Task<Void, Never>?> = .init(nil)
        return { work in
            tail.modify { task in
                let previous = task
                task = Task {
                    await previous?.value
                    await work()
                }
            }
        }
    }

}
