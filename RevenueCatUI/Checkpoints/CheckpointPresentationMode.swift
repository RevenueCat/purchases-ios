//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPresentationMode.swift
//
//  Created by Rick van der Linden.
//

#if canImport(UIKit)
import UIKit
#endif

/// How the SDK presents the flow a checkpoint resolves to over the current app content.
///
/// App-owned paywall presenters receive the resolved mode in ``PaywallPresentationParams/presentationMode`` and
/// are responsible for applying it to their own UI.
@_spi(InviteOnlyCheckpointsApi)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct CheckpointPresentationMode: Hashable, CustomStringConvertible, Sendable {

    private let name: String

    private init(name: String) {
        self.name = name
    }

    /// The SDK chooses the presentation. Currently, this is ``sheet``.
    public static let `default` = Self(name: "default")

    /// The flow covers the whole screen.
    public static let fullScreen = Self(name: "fullScreen")

    /// The flow is a modal sheet over the app's content.
    public static let sheet = Self(name: "sheet")

    /// A textual representation of this presentation mode.
    public var description: String {
        return self.name
    }

}

#if canImport(UIKit)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CheckpointPresentationMode {

    var modalPresentationStyle: UIModalPresentationStyle {
#if os(tvOS)
        return .fullScreen
#else
        switch self {
        case .fullScreen: return .fullScreen
        case .default, .sheet: return .pageSheet
        default: return .pageSheet
        }
#endif
    }

}
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension CheckpointPresentationMode {

    var resolved: Self {
        return self == .default ? .sheet : self
    }

}
