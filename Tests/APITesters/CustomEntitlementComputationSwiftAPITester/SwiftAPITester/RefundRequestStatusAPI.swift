//
//  RefundRequestStatusAPI.swift
//  SwiftAPITester
//
//  Created by Madeline Beyl on 10/28/21.
//

import Foundation
import RevenueCat_CustomEntitlementComputation

var refundStatus: RefundRequestStatus!
func checkRefundRequestStatusEnum() {
    switch refundStatus! {
    case .userCancelled,
            .success,
            .error:
        print(refundStatus!)

    @unknown default: fatalError()
    }
}
