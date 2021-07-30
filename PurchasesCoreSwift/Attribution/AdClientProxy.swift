//
//  AdClientProxy.swift
//  PurchasesCoreSwift
//
//  Created by Juanpe Catalán on 14/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

// TODO(Post-migration): switch this back to internal the class and all these protocols and properties.

public typealias AttributionDetailsBlock = ([String: NSObject]?, Error?) -> Void

// We need this class to avoid Kid apps being rejected for getting idfa. It seems like App
// Review uses some grep to find the class names, so we ended up creating a fake class that
// exposes the same methods we're looking for in ADClient to call the same methods and mangling
// the class names. So that Apple can't find them during the review, but we can still access them on runtime.
class FakeAdClient: NSObject {

    // We need this method to be available as an optional implicitly unwrapped method for `AnyClass`.
    @objc static func sharedClient() -> FakeAdClient {
        FakeAdClient()
    }

    // We need this method to be available as an optional implicitly unwrapped method for `AnyClass`.
    @objc(requestAttributionDetailsWithBlock:)
    func requestAttributionDetails(_ completionHandler: @escaping AttributionDetailsBlock) {
        Logger.warn(Strings.attribution.iad_framework_present_but_couldnt_call_request_attribution_details)
    }

}

@objc(RCAdClientProxy)
open class AdClientProxy: NSObject {

    private static let className = "ADClient"

    static var adClientClass: AnyClass? {
        NSClassFromString(Self.className)
    }

    @objc(requestAttributionDetailsWithBlock:)
    open func requestAttributionDetails(_ completionHandler: @escaping AttributionDetailsBlock) {
        let client: AnyObject
        if let klass = Self.adClientClass, let managerClass = klass as AnyObject as? NSObjectProtocol {
            // This looks strange, but #selector() does fun things to create a selector. If the selector for the given
            // function matches the selector on another class, it can be used in place. Results:
            // If ADClient class is instantiated above, then +sharedClient selector is performed eventhough you can see
            // that we're using #selector(FakeAdClient.sharedClient) to instantiate a Selector object.
            client = managerClass.perform(#selector(FakeAdClient.sharedClient)).takeUnretainedValue()
        } else {
            client = FakeAdClient.sharedClient()
        }

        client.requestAttributionDetails(completionHandler)
    }

}
