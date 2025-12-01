//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ScreenCondition.swift
//
//  Created by Josh Holtz on 11/14/24.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

class ScreenCondition: ObservableObject {

    static let `default` = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)
    static let medium = ScreenCondition(screenSizes: UIConfig.ScreenSize.Defaults.all)

    enum Orientation: String {
        case portrait
        case landscape
        case unknown
    }

    let screenSizes: [UIConfig.ScreenSize]

    @Published var paywallSize: CGSize? {
        didSet { recalc() }
    }

    @Published var verticalSizeClass: UserInterfaceSizeClass? {
        didSet { recalc() }
    }

    @Published private(set) var orientation: Orientation = .unknown
    @Published private(set) var screenSize: UIConfig.ScreenSize?

    // MARK: - helpers

    init(screenSizes: [UIConfig.ScreenSize] = []) {
        self.screenSizes = screenSizes
    }

    private func recalc() {
        guard let size = paywallSize, size.width > 0, size.height > 0 else {
            self.orientation = .unknown
            self.screenSize  = nil
            return
        }

        // Derive current orientation from the actual rendered size
        if size.width > size.height {
            self.orientation = .landscape
        } else {
            self.orientation = .portrait
        }

        // Compute effective width according to policy
        let effectiveWidth: CGFloat = min(size.width, size.height)

        let screenSizeWithDefault = self.screenSizes.isEmpty ? UIConfig.ScreenSize.Defaults.all : self.screenSizes

        // Treat class.width as a MIN breakpoint
        self.screenSize = screenSizeWithDefault.last(where: {
            CGFloat($0.width) <= effectiveWidth
        }) ?? self.screenSizes.first
    }
}

#endif
