//
//  LogIntent.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/08/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCLogIntent) public enum LogIntent: Int {
    case appleError
    case info
    case purchase
    case rcError
    case rcPurchaseSuccess
    case rcSuccess
    case user
    case warning

    var suffix: String {
        switch self {
        case .appleError: return "🍎‼️"
        case .info: return "ℹ️"
        case .purchase: return "💰"
        case .rcError: return "😿‼️"
        case .rcPurchaseSuccess: return "😻💰"
        case .rcSuccess: return "😻"
        case .user: return "👤"
        case .warning: return "⚠️"
        }
    }
}
