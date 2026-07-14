//
//  JWT.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/14/26.
//

import Foundation

struct JWT {

    enum Error: Swift.Error {
        case invalidJWT
    }

    let header: Dictionary<String, Any>
    let payload: Dictionary<String, Any>
    let signature: String

    var issuer: String? { payload["iss"] as? String }
    var appUserID: String? { payload ["rc.app_user_id"] as? String }

    init(from token: String) throws {
        let slices = token.split(separator: ".")
        guard slices.count == 3 else { throw Error.invalidJWT }

        self.header = try decode(slices[0])
        self.payload = try decode(slices[1])

        guard let signatureData = Data(base64Encoded: String(slices[2])) else {
            throw Error.invalidJWT
        }
        self.signature = String(decoding: signatureData, as: UTF8.self)

        /*
         NOTE:
         in order to eventually validate the JWT, we'll want to keep the Datas around
         so that we have the proper bits to check against the signature.

         for a quick-and-dirty unvalidated JWT, we're tossing them away for now
         */
    }

}

private func decode(_ slice: String.SubSequence) throws -> Dictionary<String, Any> {
    guard let data = Data(base64Encoded: String(slice)) else {
        throw JWT.Error.invalidJWT
    }

    let decoded = try JSONSerialization.jsonObject(with: data)

    guard let object = decoded as? Dictionary<String, Any> else {
        throw JWT.Error.invalidJWT
    }

    return object
}
