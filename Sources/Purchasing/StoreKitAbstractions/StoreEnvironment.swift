//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreEnvironment.swift
//
//  Created by MarkVillacampa on 26/10/23.
//

import Foundation

enum StoreEnvironment: String, Equatable, Codable {
    case production, sandbox, xcode
}
