//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TimeInterval+Extensions.swift
//
//  Created by Will Taylor on 7/12/24.

import Foundation

extension TimeInterval {

    init(milliseconds: Double) {
        self = milliseconds / 1000.0
    }

}
