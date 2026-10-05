//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PlatformPasteboardTests.swift
//
//  Created by Asier G. Morato on 14/9/26.

import Nimble
@testable import RevenueCatUI
import XCTest

// UIPasteboard.general cannot be read from an unhosted xctest process on iOS; the iOS branch of
// PlatformPasteboard is the pre-existing one-liner and needs a hosted app to be observable.
#if os(macOS)

import AppKit

final class PlatformPasteboardTests: TestCase {

    func testCopyReplacesTheGeneralPasteboardContents() {
        // The general pasteboard is the clipboard of whoever runs the suite: put back what was
        // on it once the test is done.
        let savedItems = Self.copyOfItems(on: .general)
        addTeardownBlock {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects(savedItems)
        }

        PlatformPasteboard.copy("first")
        PlatformPasteboard.copy("second")

        expect(NSPasteboard.general.string(forType: .string)) == "second"
    }

    private static func copyOfItems(on pasteboard: NSPasteboard) -> [NSPasteboardItem] {
        (pasteboard.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        }
    }

}

#endif
