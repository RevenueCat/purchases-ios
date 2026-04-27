//
//  RequestSizeCalculation.swift
//  RevenueCat
//
//  Created by Jacob Zivan Rakidzich on 4/24/26.
//

import SwiftUI

#if !os(tvOS) // For Paywalls V2

struct RequestSizeCalculationIdKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {

    var requestSizeCalculation: Bool {
        get { self[RequestSizeCalculationIdKey.self] }
        set { self[RequestSizeCalculationIdKey.self] = newValue }
    }

}

#endif
