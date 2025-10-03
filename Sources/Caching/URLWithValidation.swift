//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  URLWithValidation.swift
//
//  Created by Jacob Zivan Rakidzich on 10/3/25.

import Foundation

struct URLWithValidation: Hashable {
    let url: URL
    let checksum: Checksum?
}
