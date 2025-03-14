//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockUIScene.swift
//
//  Created by Will Taylor on 2/25/25.

import Foundation

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIScene {
    static func mock() -> UIScene? {
        // We can't access or instantiate UIScenes directly, so we need to use reflection to create a mock
        guard let sceneClass = NSClassFromString("UIScene") as? NSObject.Type else { return nil }
        return sceneClass.init() as? UIScene
    }
}
#endif
