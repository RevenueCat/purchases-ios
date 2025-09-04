//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PlatformImage.swift
//
//  Created by Chris Vasselli on 2025/07/15.

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
#endif

import SwiftUI

extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
extension ImageRenderer {
    @MainActor
    var platformImage: PlatformImage? {
        #if canImport(UIKit)
        return uiImage
        #elseif canImport(AppKit)
        return nsImage
        #endif
    }
}

#if canImport(AppKit) && !canImport(UIKit)
extension NSImage {
    func pngData() -> Data? {
        if let tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffRepresentation) {
            return bitmap.representation(using: .png, properties: [:])
        }

        return nil
    }
}
#endif
