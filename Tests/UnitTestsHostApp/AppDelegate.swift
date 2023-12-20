//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppDelegate.swift
//
//  Created by Andrés Boedo on 9/13/21.

import SwiftUI

#if os(watchOS) || os(tvOS) || os(macOS)

@main
struct TestApp: App {

    var body: some Scene {
        WindowGroup {
            Text("Hello World")
        }
    }

}

#else

// Scene isn't available until iOS 14.0, so this is for backwards compatibility.

@main
class AppDelegate: UIResponder, UIApplicationDelegate {}

#endif
