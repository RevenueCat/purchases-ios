//
//  PaywallViewMode+Extensions.swift
//  PaywallsTester
//
//  Created by Andrés Boedo on 9/27/23.
//

import Foundation
import RevenueCat


internal extension PaywallViewMode {

    var icon: String {
        switch self {
        case .fullScreen: return "iphone"
        case .footer: return "lanyardcard"
        case .condensedFooter: return "ruler"
        }
    }

    var name: String {
        switch self {
        case .fullScreen:
            return "Fullscreen"
        case .footer:
            return "Footer"
        case .condensedFooter:
            return "Condensed Footer"
        }
    }

}
