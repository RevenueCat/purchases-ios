//
//  Constants.swift
//  testCustomEntitlementsComputation
//
//  Created by Andrés Boedo on 4/21/23.
//

import Foundation

enum Constants {

    static let apiKey: String = {
           // return "your-api-key"
           guard let key = Bundle.main.object(forInfoDictionaryKey: "EXAMPLE_APP_API_KEY") as? String, !key.isEmpty else {
               fatalError("Modify this property to reflect your app's API key")
           }
           return key
       }()

    static let defaultAppUserID = "testAppUserID"

}
