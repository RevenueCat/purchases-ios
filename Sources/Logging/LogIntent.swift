//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LogIntent.swift
//
//  Created by Tina Nguyen on 12/08/20.
//

import Foundation

enum LogIntent {

    case verbose
    case info
    case purchase
    case appleWarning
    case appleError
    case rcError
    case rcPurchaseSuccess
    case rcSuccess
    case user
    case warning

    var prefix: String {
        switch self {
        case .verbose: return ""
        case .info: return "ℹ️"
        case .purchase: return "💰"
        case .appleWarning: return "🍎⚠️"
        case .appleError: return "🍎‼️"
        case .rcError: return "😿‼️"
        case .rcPurchaseSuccess: return "😻💰"
        case .rcSuccess: return "😻"
        case .user: return "👤"
        case .warning: return "⚠️"
        }
    }

}
