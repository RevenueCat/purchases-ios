//
//  ForceSizeCalculation.swift
//  RevenueCat
//
//  Created by Jacob Zivan Rakidzich on 4/24/26.
//

import SwiftUI

#if !os(tvOS) // For Paywalls V2

struct ForceSizeCalculationIdKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {

    var forceSizeCalculation: Bool {
        get { self[ForceSizeCalculationIdKey.self] }
        set { self[ForceSizeCalculationIdKey.self] = newValue }
    }

}

#endif
