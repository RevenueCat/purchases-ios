//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  URL+Extensions.swift
//

import Foundation

extension URL {

    var isHTTPSWithHost: Bool {
        self.scheme?.lowercased() == "https" && self.host?.isEmpty == false
    }

}
