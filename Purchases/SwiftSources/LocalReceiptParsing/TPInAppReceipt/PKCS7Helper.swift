//
//  PKCS7Wrapper.swift
//  TPInAppReceipt
//
//  Created by Pavel Tikhonenko on 19/01/17.
//  Copyright © 2017-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

extension PKCS7Wrapper
{
    func extractInAppPayload() -> Data?
    {
        guard var contentData = extractContent(by: PKC7.OID.data) else
        {
            return nil
        }
        
        do
        {
            let id = try ASN1Object.extractIdentifier(from: &contentData)
            let l = try ASN1Object.extractLenght(from: &contentData)
            
            var cStart = contentData.startIndex + ASN1Object.identifierLenght + l.offset
            let cEnd = contentData.endIndex
            
            if id.encodingType == .constructed, id.type.rawValue == 0
            {
                // Octet string
                var cD = contentData[cStart..<cEnd]
                let l = try ASN1Object.extractLenght(from: &cD)
                
                cStart += ASN1Object.identifierLenght + l.offset
                return Data(contentData[cStart..<cEnd])
            }else{
                return nil
            }
        }catch{
            return nil
        }
    }
    
    func extractSignature() -> Data?
    {
        guard let signedData = extractContent(by: PKC7.OID.signedData) else
        {
            return nil
        }
        
        let asn1signedData = ASN1Object(data: signedData)
        
        let firstBlock = asn1signedData.enumerated().map({ $0 })[0].element
        let secondBlock = firstBlock.enumerated().map({ $0 })[4].element
        let thirdBlock = secondBlock.enumerated().map({ $0 })[0].element
        let signature = thirdBlock.enumerated().map({ $0 })[4].element
    
        if signature.type.rawValue != 4 {
            return nil
        }
        
        return signature.extractValue() as? Data
    }
    
    func extractiTunesCertContainer() -> Data?
    {
        guard let signedData = extractContent(by: PKC7.OID.signedData) else
        {
            return nil
        }
        
        let asn1signedData = ASN1Object(data: signedData)
        
        let firstBlock = asn1signedData.enumerated().map({ $0 })[0].element
        let secondBlock = firstBlock.enumerated().map({ $0 })[3].element
        let iTunesCertContainer = secondBlock.enumerated().map({ $0 })[0].element
        
        return iTunesCertContainer.rawData
    }
    
    func extractiTunesPublicKeyContrainer() -> Data?
    {
        guard let iTunesCertContainer = extractiTunesCertContainer() else
        {
            return nil
        }
            
        let asn1iTunesCertData = ASN1Object(data: iTunesCertContainer)
        let firstBlock = asn1iTunesCertData.enumerated().map({ $0 })[0].element
        let iTunesPublicKeyContainer = firstBlock.enumerated().map({ $0 })[6].element
        
        return iTunesPublicKeyContainer.rawData
    }
    
    func extractWorldwideDeveloperCertContainer() -> Data?
    {
        guard let signedData = extractContent(by: PKC7.OID.signedData) else
        {
            return nil
        }
        
        let asn1signedData = ASN1Object(data: signedData)
        
        let firstBlock = asn1signedData.enumerated().map({ $0 })[0].element
        let secondBlock = firstBlock.enumerated().map({ $0 })[3].element
        let worldwideDeveloperCertContainer = secondBlock.enumerated().map({ $0 })[1].element
        
        return worldwideDeveloperCertContainer.rawData
    }
}
