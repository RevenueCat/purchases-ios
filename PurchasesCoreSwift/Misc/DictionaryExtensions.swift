//
//  DictionaryExtensions.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 7/21/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

extension Dictionary {

    func removingNSNullValues() -> Dictionary {
        self.filter { !($0.value is NSNull) }
    }

}
