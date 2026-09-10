//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  KeyWindowFocusResigner.swift
//

#if os(macOS)
import AppKit
#endif

protocol KeyWindowFocusResigning {

    @MainActor
    func resignFirstResponder()

}

struct KeyWindowFocusResigner: KeyWindowFocusResigning {

    @MainActor
    func resignFirstResponder() {
        #if os(macOS)
        NSApplication.shared.keyWindow?.makeFirstResponder(nil)
        #endif
    }

}
