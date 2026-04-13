//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PreviewImageHelpers.swift
//
//  Created by RevenueCat.

#if !os(tvOS) // For Paywalls V2

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
func makeLocalPreviewImageURL(filename: String, base64: String) -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

    if !FileManager.default.fileExists(atPath: url.path) {
        guard let data = Data(base64Encoded: base64) else {
            fatalError("Invalid base64 preview image: \(filename)")
        }

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            fatalError("Failed to write preview image \(filename): \(error)")
        }
    }

    return url
}

#endif

#endif
