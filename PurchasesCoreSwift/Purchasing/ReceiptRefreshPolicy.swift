//
//  ReceiptRefreshPolicy.swift
//  PurchasesCoreSwift
//
//  Created by Juanpe Catalán on 7/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

// TODO(Post-migration): switch this back to internal
@objc(RCReceiptRefreshPolicy) public enum ReceiptRefreshPolicy: Int {

    case always = 0
    case onlyIfEmpty
    case never

}
