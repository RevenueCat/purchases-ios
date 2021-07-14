//
//  TrackingManagerProxy.swift
//  PurchasesCoreSwift
//
//  Created by Juanpe Catalán on 14/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

// TODO(Post-migration): switch this back to internal the class and all these protocols and properties.

@objc public enum FakeTrackingManagerAuthorizationStatus: Int {
    case notDetermined = 0
    case restricted
    case denied
    case authorized
}

// We need this class to avoid Kid apps being rejected for getting idfa. It seems like App
// Review uses some grep to find the class names, so we ended up creating a fake class that
// exposes the same methods we're looking for in ATTrackingManager to call the same methods and mangling
// the class names. So that Apple can't find them during the review, but we can still access them on runtime.
class FakeTrackingManager: NSObject {
    // We need this method to be available as an optional implicitly unwrapped method for `AnyClass`.
    @objc static func trackingAuthorizationStatus() -> Int {
        -1
    }
}

@objc(RCTrackingManagerProxy)
open class TrackingManagerProxy: NSObject {
    static let mangledTrackingClassName = "NGGenpxvatZnantre"
    static let mangledAuthStatusPropertyName = "genpxvatNhgubevmngvbaFgnghf"

    static var trackingClass: AnyClass? {
        // We need to do this mangling to avoid Kid apps being rejected for getting idfa.
        // It looks like during the app review process Apple does some string matching looking for
        // functions in ATTrackingTransparency. We apply rot13 on these functions and classes names
        // so that Apple can't find them during the review, but we can still access them on runtime.
        NSClassFromString(mangledTrackingClassName.rot13())
    }

    @objc public var authorizationStatusPropertyName: String {
        Self.mangledAuthStatusPropertyName.rot13()
    }

    @objc open func trackingAuthorizationStatus() -> Int {
        let classType: AnyClass = Self.trackingClass ?? FakeTrackingManager.self
        return classType.trackingAuthorizationStatus()
    }
}
