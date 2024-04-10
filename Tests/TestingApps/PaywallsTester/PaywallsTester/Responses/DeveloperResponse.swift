//
//  DeveloperResponse.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

public struct DeveloperResponse {

    public struct App {
        
        public var id: String
        public var name: String

    }

    public var email: String
    public var name: String
    public var distinctId: String
    public var apps: [App]

}

extension DeveloperResponse.App: Hashable, Decodable {}
extension DeveloperResponse: Hashable, Decodable {}

extension DeveloperResponse.App: Identifiable {}
