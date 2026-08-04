//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointStrings.swift
//
//  Created by Rick van der Linden.
//

import Foundation

enum CheckpointStrings {

    case invalidCustomProperty(key: String, type: String)

}

extension CheckpointStrings: LogMessage {

    var description: String {
        switch self {
        case let .invalidCustomProperty(key, type):
            return "Dropping invalid checkpoint custom property '\(key)': \(type)"
        }
    }

    var category: String { return "checkpoints" }

}
