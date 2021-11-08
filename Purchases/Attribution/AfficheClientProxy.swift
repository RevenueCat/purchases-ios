//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AfficheClientProxy.swift
//
//  Created by Juanpe Catalán on 14/7/21.
//

import Foundation

typealias AttributionDetailsBlock = ([String: NSObject]?, Error?) -> Void

// We need this class to avoid Kid apps being rejected for getting idfa. It seems like App
// Review uses some grep to find the class names, so we ended up creating a fake class that
// exposes the same methods we're looking for in ADClient to call the same methods and mangling
// the class names. So that Apple can't find them during the review, but we can still access them on runtime.
// You can see the class here: https://rev.cat/fake-affiche-client
class FakeAfficheClient: NSObject {

    // We need this method to be available as an optional implicitly unwrapped method for `AnyClass`.
    @objc static func sharedClient() -> FakeAfficheClient {
        FakeAfficheClient()
    }

    // We need this method to be available as an optional implicitly unwrapped method for `AnyClass`.
    @objc(requestAttributionDetailsWithBlock:)
    func requestAttributionDetails(_ completionHandler: @escaping AttributionDetailsBlock) {
        Logger.warn(Strings.attribution.apple_affiche_framework_present_but_couldnt_call_request_attribution_details)
    }

}

class AfficheClientProxy {

    private static let mangledClassName = "NQPyvrag"

    static var afficheClientClass: AnyClass? {
        NSClassFromString(Self.mangledClassName.rot13())
    }

    func requestAttributionDetails(_ completionHandler: @escaping AttributionDetailsBlock) {
        let client: AnyObject
        if let klass = Self.afficheClientClass, let clientClass = klass as AnyObject as? NSObjectProtocol {
            // This looks strange, but #selector() does fun things to create a selector. If the selector for the given
            // function matches the selector on another class, it can be used in place. Results:
            // If ADClient class is instantiated above, then +sharedClient selector is performed even though you can see
            // that we're using #selector(FakeAfficheClient.sharedClient) to instantiate a Selector object.
            client = clientClass.perform(#selector(FakeAfficheClient.sharedClient)).takeUnretainedValue()
        } else {
            client = FakeAfficheClient.sharedClient()
        }

        client.requestAttributionDetails(completionHandler)
    }

}
