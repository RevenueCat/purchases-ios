//
//  CustomerCenterViewAPI.swift
//  AllAPITests
//
//  Created by Will Taylor on 12/6/24.
//

import RevenueCat
import RevenueCatUI


#if canImport(UIKit) && os(iOS)
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
func checkCustomerCenterViewControllerAPI(
    customerCenterActionHandler: CustomerCenterActionHandler? = nil
) {
    let _ = CustomerCenterViewController()
    let _ = CustomerCenterViewController(customerCenterActionHandler: customerCenterActionHandler)
}
#endif
