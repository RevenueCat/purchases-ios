//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  UIApplicationExtensionsTests.swift
//
//  Created by Rick van der Linden on 10/9/26.

#if os(iOS) || os(tvOS) || VISION_OS

@testable import RevenueCat
import UIKit
import XCTest

final class UIApplicationExtensionsTests: TestCase {

    @MainActor
    func testFirstWindowSceneSkipsNonWindowScenes() throws {
        let scene = try XCTUnwrap(UIScene.mock())
        let windowSceneClass = try XCTUnwrap(NSClassFromString("UIWindowScene") as? NSObject.Type)
        let windowScene = try XCTUnwrap(windowSceneClass.init() as? UIWindowScene)

        let result = UIApplication.firstWindowScene(in: [scene, windowScene])

        XCTAssertTrue(result === windowScene)
    }

}

#endif
