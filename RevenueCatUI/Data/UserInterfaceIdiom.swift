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
    case unknown

}

extension UserInterfaceIdiom {

    #if canImport(UIKit)
    static let `default`: Self = UIDevice.interfaceIdiom
    #elseif os(macOS)
    static let `default`: Self = .mac
    #else
    static let `default`: Self = .unknown
    #endif

}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
struct UserInterfaceIdiomEnvironmentKey: EnvironmentKey {

    static var defaultValue: UserInterfaceIdiom = .default

}

@available(iOS 13.0, tvOS 13.0, macOS 10.15, watchOS 6.2, *)
extension EnvironmentValues {

    var userInterfaceIdiom: UserInterfaceIdiom {
        get { self[UserInterfaceIdiomEnvironmentKey.self] }
        set { self[UserInterfaceIdiomEnvironmentKey.self] = newValue }
    }

}

// MARK: - UIKit

#if canImport(UIKit)

private extension UIDevice {

    static var interfaceIdiom: UserInterfaceIdiom {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: return .phone
        case .pad: return .pad
        case .mac: return .mac

        case .tv: return .unknown
        case .carPlay: return .unknown

        case .unspecified: fallthrough
        @unknown default:
            return .unknown
        }
    }

}

#endif

#endif
