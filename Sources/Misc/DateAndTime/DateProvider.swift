//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DateProvider.swift
//
//  Created by Josh Holtz on 6/28/21.
//

import Foundation

class DateProvider {

    func now() -> Date {
        return Date()
    }

}

// @unchecked because:
// - Class is not `final` (it's mocked). This implicitly makes subclasses `Sendable` even if they're not thread-safe.
extension DateProvider: @unchecked Sendable {}
