//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UIConfigProvider.swift
//
//  Created by Josh Holtz on 1/5/25.

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

struct UIConfigProvider {

    private let uiConfig: UIConfig

    init(uiConfig: UIConfig) {
        self.uiConfig = uiConfig
    }

    func getFontFamily(for name: String?) -> String? {
        guard let name, let fontInfo = self.uiConfig.app.fonts[name]?.ios else {
            return nil
        }

        switch fontInfo {
        case .name(let fontFamily):
            return fontFamily
        case .googleFonts:
            // Not supported on this platform (yet)
            return nil
        @unknown default:
            return nil
        }
    }

}

#endif
