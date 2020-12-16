//
//  LogIntent.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/08/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

enum LogIntent: Int {
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
        case .appleError: return Emoji.apple.rawValue + Emoji.doubleExclamation.rawValue
        case .info: return Emoji.info.rawValue
        case .purchase: return Emoji.moneyBag.rawValue
        case .rcError: return Emoji.sadCatEyes.rawValue + Emoji.doubleExclamation.rawValue
        case .rcPurchaseSuccess: return Emoji.heartCatEyes.rawValue + Emoji.moneyBag.rawValue
        case .rcSuccess: return Emoji.heartCatEyes.rawValue
        case .user: return Emoji.person.rawValue
        case .warning: return Emoji.warning.rawValue
        }
    }
}
