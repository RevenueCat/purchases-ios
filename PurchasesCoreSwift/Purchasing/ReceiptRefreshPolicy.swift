//
//  ReceiptRefreshPolicy.swift
//  PurchasesCoreSwift
//
//  Created by Juanpe Catalán on 7/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

enum ReceiptRefreshPolicy: Int {

    case always = 0
    case onlyIfEmpty
    case never

}
