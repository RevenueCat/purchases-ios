//
//  PaywallViewMode+Extensions.swift
//  PaywallsTester
//
//  Created by Andrés Boedo on 9/27/23.
//

import Foundation
import RevenueCat

enum PaywallTesterViewMode {
    case fullScreen
    case sheet
    case footer
    case condensedFooter
}

internal extension PaywallTesterViewMode {

    static let `default`: Self = .sheet

    static var allCases: [PaywallTesterViewMode] {
        #if os(watchOS)
        return [.fullScreen]
        #else
        return [
            .fullScreen,
            .sheet,
            .footer,
            .condensedFooter
        ]
        #endif
    }

    var mode: PaywallViewMode {
        switch self {
        case .fullScreen: return .fullScreen
        case .sheet: return .fullScreen
        case .footer: return .footer
        case .condensedFooter: return .condensedFooter
        }
    }

    var icon: String {
        switch self {
        case .fullScreen: return "iphone"
        case .sheet: return "iphone"
        case .footer: return "lanyardcard"
        case .condensedFooter: return "ruler"
        }
    }

    var name: String {
        switch self {
        case .fullScreen:
            return "Fullscreen"
        case .sheet:
            return "Sheet"
        case .footer:
            return "Footer"
        case .condensedFooter:
            return "Condensed Footer"
        }
    }

}
