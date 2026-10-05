//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PlatformPasteboard.swift
//
//  Created by Asier G. Morato on 14/9/26.

import Foundation

#if canImport(UIKit) && !os(watchOS) && !os(tvOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// The system pasteboard behind one call, so views do not branch on UIKit versus AppKit.
enum PlatformPasteboard {

    /// Replaces the general pasteboard's contents with `string`.
    static func copy(_ string: String) {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        UIPasteboard.general.string = string
        #elseif canImport(AppKit)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
        #endif
    }

}
