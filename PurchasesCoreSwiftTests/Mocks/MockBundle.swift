//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockBundle.swift
//
//  Created by Andrés Boedo on 3/8/21.

import Foundation

class MockBundle: Bundle {
    var mockAppStoreReceiptFileName = "base64encodedreceiptsample1"
    var shouldReturnNilURL = false
    
    var mockAppStoreReceiptURL: URL? {
        guard !shouldReturnNilURL else { return nil }
        
        return Bundle(for: type(of: self))
            .url(forResource: mockAppStoreReceiptFileName, withExtension: "txt")
    }
    
    override var appStoreReceiptURL: URL? {
        return mockAppStoreReceiptURL
    }
    
}
