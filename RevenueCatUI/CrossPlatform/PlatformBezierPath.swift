//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PlatformBezierPath.swift
//
//  Created by Chris Vasselli on 2025/07/31.

#if canImport(UIKit)
import UIKit
typealias PlatformBezierPath = UIBezierPath
#elseif canImport(AppKit)
import AppKit
typealias PlatformBezierPath = NSBezierPath
#endif

#if !canImport(UIKit) && canImport(AppKit)
extension NSBezierPath {
    func reversing() -> NSBezierPath {
        self.reversed
    }
}
#endif
