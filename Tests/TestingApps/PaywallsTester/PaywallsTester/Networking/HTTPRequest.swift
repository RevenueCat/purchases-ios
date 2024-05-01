//
//  HTTPRequest.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

public struct HTTPRequest: Sendable {

    var method: HTTPMethod
    var endpoint: HTTPEndpoint

}
