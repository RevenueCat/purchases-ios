//
//  RefundRequestStatusAPI.swift
//  SwiftAPITester
//
//  Created by Madeline Beyl on 10/28/21.
//

import Foundation
import RevenueCat

var refundStatus: RefundRequestStatus!
func testEnums() {
    switch refundStatus {
    case .userCancelled:
    case .success:
    case .error:
        print(refundStatus)
    }
}
