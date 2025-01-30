//
//  ConfigItem.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-05-13.
//

import Foundation

protocol AvailableConfigItems {
    static var apiKey: String { get }
    static var proxyURL: String? { get }
}

// CI system adds keys here
extension AvailableConfigItems {
    static var apiKey: String { "appl_SYkbbYptqjDadVkQeBUtXxVxCcw" }
    static var proxyURL: String? { nil }
}

struct ConfigItem: AvailableConfigItems {

}
