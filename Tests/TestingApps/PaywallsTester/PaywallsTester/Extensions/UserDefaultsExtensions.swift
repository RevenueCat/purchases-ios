//
//  UserDefaults.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

public extension UserDefaults {

    static let revenueCatSuite: UserDefaults = .init(
        suiteName: sharedAppGroup
    )!

    static let sharedAppGroup: String = "group.com.revenuecat"

}
