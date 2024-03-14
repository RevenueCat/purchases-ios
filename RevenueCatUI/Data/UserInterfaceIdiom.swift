//
//  UserInterfaceIdiom.swift
//  
//
//  Created by Nacho Soto on 8/23/23.
//

#if canImport(SwiftUI)

import SwiftUI

enum UserInterfaceIdiom {

    case phone
    case pad
    case mac
    case watch
    case unknown

}

extension UserInterfaceIdiom {

    #if os(watchOS)
    static let `default`: Self = .watch
    #elseif canImport(UIKit)
    static let `default`: Self = UIDevice.interfaceIdiom
    #elseif os(macOS)
    static let `default`: Self = .mac
    #else
    static let `default`: Self = .unknown
    #endif

}

extension EnvironmentValues {

    var userInterfaceIdiom: UserInterfaceIdiom {
        get { self[UserInterfaceIdiomEnvironmentKey.self] }
        set { self[UserInterfaceIdiomEnvironmentKey.self] = newValue }
    }

    #if DEBUG
    var isRunningSnapshots: Bool {
        get { self[RunningSnapshotsEnvironmentKey.self] }
        set { self[RunningSnapshotsEnvironmentKey.self] = newValue }
    }
    #endif

}

// MARK: -

private struct UserInterfaceIdiomEnvironmentKey: EnvironmentKey {

    static var defaultValue: UserInterfaceIdiom = .default

}

#if DEBUG
private struct RunningSnapshotsEnvironmentKey: EnvironmentKey {

    static var defaultValue: Bool = false

}
#endif

// MARK: - UIKit

#if canImport(UIKit) && !os(watchOS)

private extension UIDevice {

    static var interfaceIdiom: UserInterfaceIdiom {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: return .phone
        case .pad: return .pad
        case .mac: return .mac

        case .tv: return .unknown
        case .carPlay: return .unknown

        #if swift(>=5.9)
        case .vision: return .unknown
        #endif

        case .unspecified: fallthrough
        @unknown default:
            return .unknown
        }
    }

}

#endif

#endif
