//
//  Asn1Coder.swift
//  TPInAppReceipt iOS
//
//  Created by Pavel Tikhonenko on 22/06/2019.
//  Copyright © 2019-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

class ASN1Coder
{
    static func decode(from data: Data) throws -> ASN1Object
    {
        var d = data
        
        guard ASN1Object.isDataValid(&d) else
        {
            throw ASN1Error.initializationFailed(reason: .dataIsInvalid)
        }
        
        return ASN1Object(data: d)
    }
}


/// `ASN1Error`
enum ASN1Error: Error
{
    case initializationFailed(reason: InitializationFailureReason)
    case validationFailed(reason: ValidationFailureReason)
    
    
    /// The underlying reason the receipt initialization error occurred.
    ///
    /// - dataIsInvalid:         Provided data don't contain any asn1 object
    enum InitializationFailureReason
    {
        case dataIsInvalid
    }
    
    /// The underlying reason the receipt validation error occurred.
    ///
    /// - hashValidation:          Computed hash doesn't match the hash from the receipt's payload
    /// - signatureValidation:     Error occurs during signature validation. It has several reasons to failure
    enum ValidationFailureReason
    {
        case hashValidation
        case signatureValidation(SignatureValidationFailureReason)
    }
    
    /// The underlying reason the signature validation error occurred.
    ///
    /// - rootCertificateNotFound:          Apple Inc Root Certificate Not Found
    /// - invalidSignature:                 The receipt contains invalid signature
    enum SignatureValidationFailureReason
    {
        case rootCertificateNotFound
        case invalidSignature
    }
}
