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
    @available(watchOS, unavailable)
    case footer
    @available(watchOS, unavailable)
    case condensedFooter
    case presentIfNeeded
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
            .condensedFooter,
            .presentIfNeeded
        ]
        #endif
    }
    
    var isAvailableOnExamples: Bool {
        return self != .presentIfNeeded
    }

    var mode: PaywallViewMode {
        switch self {
        case .fullScreen: return .fullScreen
        case .sheet: return .fullScreen
        #if !os(watchOS)
        case .footer: return .footer
        case .condensedFooter: return .condensedFooter
        case .presentIfNeeded: return .fullScreen
        #endif
        }
    }

    var icon: String {
        switch self {
        case .fullScreen: return "iphone"
        case .sheet: return "iphone"
        #if !os(watchOS)
        case .footer: return "lanyardcard"
        case .condensedFooter: return "ruler"
        case .presentIfNeeded: return "signpost.right.and.left"
        #endif
        }
    }

    var name: String {
        switch self {
        case .fullScreen:
            return "Fullscreen"
        case .sheet:
            return "Sheet"
        #if !os(watchOS)
        case .footer:
            return "Footer"
        case .condensedFooter:
            return "Condensed Footer"
        case .presentIfNeeded:
            return "Present If Needed"
        #endif
        }
    }

}
