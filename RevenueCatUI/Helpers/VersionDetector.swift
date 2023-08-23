//
//  VersionDetector.swift
//  
//
//  Created by Nacho Soto on 8/17/23.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif

// TODO: DeviceDetector

enum VersionDetector {

    static let iOS15: Bool = {
        return Self.isAtLeast(version: 15) && !Self.isAtLeast(version: 16)
    }()

    #if canImport(UIKit)
    static let isIpad: Bool = {
        return UIDevice.current.userInterfaceIdiom == .pad
    }()
    #else
    static let isIpad: Bool = false
    #endif

    private static func isAtLeast(version: Int) -> Bool {
        return ProcessInfo.processInfo.isOperatingSystemAtLeast(.init(majorVersion: version,
                                                                      minorVersion: 0,
                                                                      patchVersion: 0))
    }

}
