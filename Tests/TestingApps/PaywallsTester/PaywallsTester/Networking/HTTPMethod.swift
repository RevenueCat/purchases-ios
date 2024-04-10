//
//  Method.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

public enum HTTPMethod {

    case get
    case post

}

extension HTTPMethod {

    var name: String {
        switch self {
        case .get: return "GET"
        case .post: return "POST"
        }
    }

}
