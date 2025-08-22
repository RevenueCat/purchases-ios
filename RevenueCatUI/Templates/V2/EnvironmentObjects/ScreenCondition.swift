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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

class ScreenCondition: ObservableObject {

    static let defaultScreenSizes: [UIConfig.ScreenSize] = [
        .init(name: "mobile", width: 375),
        .init(name: "tablet", width: 700),
        .init(name: "desktop", width: 1024)
    ]

    static let `default` = ScreenCondition(screenSizes: ScreenCondition.defaultScreenSizes)
    static let medium = ScreenCondition(screenSizes: ScreenCondition.defaultScreenSizes)

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

    // MARK: - Platform/idiom helpers
    private var isPhone: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone
        #else
        return false
        #endif
    }

    /// Treat iPhone landscape as “use landscape layout”.
    /// tvOS/macOS/watchOS handled explicitly.
    private var shouldUseLandscapeLayout: Bool {
        #if os(tvOS)
        // tvOS never reports .compact; we want wide/horizontal layouts.
        return true
        #elseif os(macOS)
        return false
        #elseif os(watchOS)
        return false
        #else
        // On iPhone this is `.compact` in landscape. On iPad it’s often `.regular`.
        return self.verticalSizeClass == .compact
        #endif
    }

    init(screenSizes: [UIConfig.ScreenSize] = []) {
        self.screenSizes = screenSizes
    }

    private func recalc() {
        guard let size = paywallSize, size.width > 0, size.height > 0 else {
            self.orientation = .unknown
            self.screenSize  = nil
            return
        }

        // 1) Derive current orientation from the actual rendered size
        if size.width > size.height {
            self.orientation = .landscape
        } else if size.height > size.width {
            self.orientation = .portrait
        } else {
            self.orientation = .portrait // square -> treat as portrait
        }

        // 2) Choose bucketing policy
        // - iPhone portrait -> short side (stable)
        // - iPhone landscape -> actual width (let it “grow”)
        // - Everyone else -> short side (stable across rotation / windowing)
        let useActualWidth: Bool = {
            #if os(iOS)
            if isPhone {
                // Prefer size class when available (most reliable on iPhone),
                // fall back to inferred orientation from geometry.
                return shouldUseLandscapeLayout || orientation == .landscape
            }
            #endif
            return false
        }()

        // 3) Compute effective width according to policy
        let effectiveWidth: CGFloat = useActualWidth ? size.width : min(size.width, size.height)

        let screenSizeWithDefault = self.screenSizes.isEmpty ? ScreenCondition.defaultScreenSizes : self.screenSizes

        // 4) Treat class.width as a MIN breakpoint
        self.screenSize = screenSizeWithDefault.last(where: {
            CGFloat($0.width) <= effectiveWidth
        }) ?? self.screenSizes.first

        print("effectiveWidth: \(effectiveWidth)")
        print("JOSH: screenSize: \(String(describing: self.screenSize))")
    }

}

struct ScreenConditionKey: EnvironmentKey {
    static let defaultValue = ScreenCondition()
}

extension EnvironmentValues {

    var screenCondition: ScreenCondition {
        get { self[ScreenConditionKey.self] }
        set { self[ScreenConditionKey.self] = newValue }
    }

}

#endif
