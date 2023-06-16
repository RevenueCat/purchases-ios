//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsPostBody.swift
//
//  Created by Nacho Soto on 6/16/23.

import Foundation

typealias DiagnosticsEntries = [String]

/// The body to be sent with requests to
struct DiagnosticsPostBody: Encodable {

    var entries: DiagnosticsEntries

}
