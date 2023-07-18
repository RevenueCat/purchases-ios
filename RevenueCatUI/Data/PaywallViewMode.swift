//
//  PaywallViewMode.swift
//  
//
//  Created by Nacho Soto on 7/17/23.
//

import RevenueCat

/// The mode for how a paywall is rendered.
public enum PaywallViewMode {

    /// Paywall is displayed full-screen, with as much information as available.
    case fullScreen

    /// Paywall is displayed with a square aspect ratio. It can be embedded inside any other SwiftUI view.
    case square

    /// Paywall is displayed in a condensed format. It can be embedded inside any other SwiftUI view.
    case banner

    /// The default ``PaywallViewMode``: ``PaywallViewMode/fullScreen``.
    public static let `default`: Self = .fullScreen

}

extension PaywallViewMode: CaseIterable {}

extension PaywallViewMode {

    var isFullScreen: Bool {
        switch self {
        case .fullScreen: return true
        case .square, .banner: return false
        }
    }

}
