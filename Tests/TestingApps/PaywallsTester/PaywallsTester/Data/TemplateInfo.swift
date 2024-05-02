//
//  TemplateInfo.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-05-02.
//

import Foundation

enum TemplateInfo: Int, CustomStringConvertible {

    case template1 = 1
    case template2
    case template3
    case template4
    case template5

    var description: String {
        switch self {
        case .template1:
            "Jaguar"
        case .template2:
            "Sphynx"
        case .template3:
            "Leopard"
        case .template4:
            "Persian"
        case .template5:
            "Bengal"
        }
    }

}
