//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ASN1ObjectIdentifier.swift
//
//  Created by Andrés Boedo on 7/29/20.
//

import Foundation

// http://www.umich.edu/~x509/ssleay/asn1-oids.html
enum ASN1ObjectIdentifier: String {

    case data = "1.2.840.113549.1.7.1"
    case signedData = "1.2.840.113549.1.7.2"
    case envelopedData = "1.2.840.113549.1.7.3"
    case signedAndEnvelopedData = "1.2.840.113549.1.7.4"
    case digestedData = "1.2.840.113549.1.7.5"
    case encryptedData = "1.2.840.113549.1.7.6"

}
