//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  IdentifiableURL.swift
//
//  Created by Facundo Menzella on 12/5/25.

import Foundation

struct IdentifiableURL: Identifiable {

    var id: String {
        return url.absoluteString
    }

    let url: URL
}
