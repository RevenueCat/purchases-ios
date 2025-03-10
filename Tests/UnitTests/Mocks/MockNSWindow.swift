//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockNSWindow.swift
//
//  Created by Will Taylor on 2/25/25.

import Foundation

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSWindow {
    static func mock() -> NSWindow? {
        // We can't access or instantiate NSWindows directly, so we need to use reflection to create a mock
        guard let nsWindowClass = NSClassFromString("NSWindow") as? NSObject.Type else { return nil }
        return nsWindowClass.init() as? NSWindow
    }
}
#endif
