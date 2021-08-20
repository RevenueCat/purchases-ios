//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UIApplication+RCExtensions.swift
//
//  Created by Andrés Boedo on 8/20/21.

import Foundation
#if os(iOS)
import UIKit

extension UIApplication {

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    @available(watchOSApplicationExtension, unavailable)
    @available(tvOS, unavailable)
    var currentWindowScene: UIWindowScene? {
        let windowScene = self
            .connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first

        return windowScene as? UIWindowScene
    }

}
#endif
