//
//  Keys.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-05-13.
//

import Foundation


protocol AvailableKeys {
    static var api: String { get }
}

// CI system adds keys here
extension AvailableKeys {
    static var api: String { "" }
}

struct Keys: AvailableKeys {

}
