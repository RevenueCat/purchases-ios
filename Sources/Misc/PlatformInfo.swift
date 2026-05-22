//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PlatformInfo.swift
//
//  Created by Josh Holtz on 2/17/22.

import Foundation

// swiftlint:disable missing_docs
extension Purchases {

    @objc(RCPlatformInfo)
    public final class PlatformInfo: NSObject {

        // swiftlint:disable:next nesting
        internal struct Storage: Hashable {
            let flavor: String
            let version: String
        }

        internal let storage: Storage

        var flavor: String { self.storage.flavor }
        var version: String { self.storage.version }

        @objc public init(flavor: String, version: String) {
            self.storage = Storage(flavor: flavor, version: version)
        }

        public override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? PlatformInfo else { return false }
            return self.storage == other.storage
        }

        public override var hash: Int { self.storage.hashValue }
    }

    @objc public static var platformInfo: PlatformInfo?

}
