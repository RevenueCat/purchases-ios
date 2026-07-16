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

    let header: [String: Any]
    let payload: [String: Any]
    let signature: Data

    var issuer: String? { payload["iss"] as? String }
    var appUserID: String? { payload["rc.app_user_id"] as? String }

    init(from token: String) throws {
        let slices = token.split(separator: ".")
        guard slices.count == 3 else { throw Error.invalidJWT }

        self.header = try decode(slices[0])
        self.payload = try decode(slices[1])

        guard let signatureData = Data(base64URLEncoded: String(slices[2])) else {
            throw Error.invalidJWT
        }
        self.signature = signatureData

        /*
         NOTE:
         in order to eventually validate the JWT, we'll want to keep the Datas around
         so that we have the proper bits to check against the signature.

         for a quick-and-dirty unvalidated JWT, we're tossing them away for now
         */
    }

}

private func decode(_ slice: String.SubSequence) throws -> [String: Any] {
    guard let data = Data(base64URLEncoded: String(slice)) else {
        throw JWT.Error.invalidJWT
    }

    let decoded = try JSONSerialization.jsonObject(with: data)

    guard let object = decoded as? [String: Any] else {
        throw JWT.Error.invalidJWT
    }

    return object
}
