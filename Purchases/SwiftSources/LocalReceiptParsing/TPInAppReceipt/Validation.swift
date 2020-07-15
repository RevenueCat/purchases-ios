//
//  InAppReceiptValidator.swift
//  TPInAppReceipt
//
//  Created by Pavel Tikhonenko on 19/01/17.
//  Copyright © 2017-2020 Pavel Tikhonenko. All rights reserved.
//

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import IOKit
import Cocoa
#endif

import CommonCrypto

/// A InAppReceipt extension helps to validate the receipt
extension InAppReceipt
{
    /// Verify In App Receipt
    ///
    /// - throws: An error in the InAppReceipt domain, if verification fails
    func verify() throws
    {
        try verifyHash()
        try verifyBundleIdentifierAndVersion()
        try verifySignature()
    }
    
    /// Verify only hash
    /// Should be equal to `receiptHash` value
    ///
    /// - throws: An error in the InAppReceipt domain, if verification fails
    func verifyHash() throws
    {
        if (computedHashData != receiptHash)
        {
            throw IARError.validationFailed(reason: .hashValidation)
        }
    }
    
    /// Verify that the bundle identifier in the receipt matches a hard-coded constant containing the CFBundleIdentifier value you expect in the Info.plist file. If they do not match, validation fails.
    /// Verify that the version identifier string in the receipt matches a hard-coded constant containing the CFBundleShortVersionString value (for macOS) or the CFBundleVersion value (for iOS) that you expect in the Info.plist file.
    ///
    ///
    /// - throws: An error in the InAppReceipt domain, if verification fails
    func verifyBundleIdentifierAndVersion() throws
    {
        #if targetEnvironment(simulator)
        #else
        guard let bid = Bundle.main.bundleIdentifier, bid == bundleIdentifier else
        {
            throw IARError.validationFailed(reason: .bundleIdentifierVefirication)
        }
        
        #if targetEnvironment(macCatalyst)
        guard let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            v == appVersion else
        {
            throw IARError.validationFailed(reason: .bundleVersionVefirication)
        }
        #elseif os(iOS) || os(watchOS) || os(tvOS)
        guard let v = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
            v == appVersion else
        {
            throw IARError.validationFailed(reason: .bundleVersionVefirication)
        }
        #elseif os(macOS)
        guard let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            v == appVersion else
        {
            throw IARError.validationFailed(reason: .bundleVersionVefirication)
        }
        #endif
        #endif
    }
    
    /// Verify signature inside pkcs7 container
    ///
    /// - throws: An error in the InAppReceipt domain, if verification can't be completed
    func verifySignature() throws
    {
        try checkSignatureExistance()
        try checkAppleRootCertExistence()
        
        // only check certificate chain of trust and signature validity after these version
        if #available(OSX 10.12, iOS 10.0, tvOS 10.0, watchOS 5.0, *)
		{
            try checkChainOfTrust()
            try checkSignatureValidity()
        }
    }
    
    /// Verifies existance of the signature inside pkcs7 container
    ///
    /// - throws: An error in the InAppReceipt domain, if verification can't be completed
    fileprivate func checkSignatureExistance() throws
    {
        guard pkcs7Container.checkContentExistance(by: PKC7.OID.signedData) else
        {
            throw IARError.validationFailed(reason: .signatureValidation(.receiptSignedDataNotFound))
        }
        
        guard pkcs7Container.checkContentExistance(by: PKC7.OID.data) else
        {
            throw IARError.validationFailed(reason: .signatureValidation(.receiptDataNotFound))
        }
    }
    
    /// Verifies existence of Apple Root Certificate in bundle
    ///
    /// - throws: An error in the InAppReceipt domain, if Apple Root Certificate does not exist
    fileprivate func checkAppleRootCertExistence() throws
    {
        guard let certPath = rootCertificatePath, FileManager.default.fileExists(atPath: certPath) else
        {
            throw IARError.validationFailed(reason: .signatureValidation(.appleIncRootCertificateNotFound))
        }
        
    }
    
    @available(OSX 10.12, iOS 10.0, tvOS 10.0, watchOS 5.0, *)
    func checkChainOfTrust() throws
    {
        // Validate chain of trust of certificate
        // Ensure the iTunes certificate included in the receipt is indeed signed by Apple root cert
        // https://developer.apple.com/documentation/security/certificate_key_and_trust_services/trust/creating_a_trust_object
        
        // root cert data is loaded from the bundled Apple Root Certificate
        guard let path = rootCertificatePath, let rootCertData = try? Data(contentsOf: URL(fileURLWithPath: path)) else
        {
            throw IARError.validationFailed(reason: .signatureValidation(.unableToLoadAppleIncRootCertificate))
        }
        
        guard let iTunesCertData = pkcs7Container.extractiTunesCertContainer() else
        {
           throw IARError.validationFailed(reason: .signatureValidation(.unableToLoadiTunesCertificate))
        }
        
        guard let worldwideDeveloperCertData = pkcs7Container.extractWorldwideDeveloperCertContainer() else {
            throw IARError.validationFailed(reason: .signatureValidation(.unableToLoadWorldwideDeveloperCertificate))
        }
        
        guard let rootCertSec = SecCertificateCreateWithData(nil, rootCertData as CFData) else {
            throw IARError.validationFailed(reason: .signatureValidation(.unableToLoadAppleIncRootCertificate))
        }
        
        guard let iTunesCertSec =  SecCertificateCreateWithData(nil, iTunesCertData as CFData) else {
           throw IARError.validationFailed(reason: .signatureValidation(.unableToLoadiTunesCertificate))
        }
        
        guard let worldwideDevCertSec = SecCertificateCreateWithData(nil, worldwideDeveloperCertData as CFData) else {
           throw IARError.validationFailed(reason: .signatureValidation(.unableToLoadWorldwideDeveloperCertificate))
        }
        
        let policy = SecPolicyCreateBasicX509()
        
        var wwdcTrust: SecTrust?
        var iTunesTrust: SecTrust?
        
        // verify worldwide developer cert in the receipt is signed by Apple Root Cert
        let worldwideDevCertVerifystatus = SecTrustCreateWithCertificates([worldwideDevCertSec, rootCertSec] as AnyObject,
                                                                            policy,
                                                                            &wwdcTrust)
        
        guard worldwideDevCertVerifystatus == errSecSuccess && wwdcTrust != nil  else {
            throw IARError.validationFailed(reason: .signatureValidation(.invalidCertificateChainOfTrust))
        }
        
        // verify iTunes cert in the receipt is signed by worldwide developer cert, which is signed by Apple Root Cert
        let iTunesCertVerifystatus = SecTrustCreateWithCertificates([iTunesCertSec, worldwideDevCertSec ,rootCertSec] as AnyObject,
                                                                    policy,
                                                                    &iTunesTrust)
        
        guard iTunesCertVerifystatus == errSecSuccess && iTunesTrust != nil else {
            throw IARError.validationFailed(reason: .signatureValidation(.invalidCertificateChainOfTrust))
        }
        
        var secTrustResult: SecTrustResultType = SecTrustResultType.unspecified
        
        if #available(OSX 10.14, iOS 12.0, tvOS 12.0, *)
        {
            var error: CFError?
            guard SecTrustEvaluateWithError(wwdcTrust!, &error) else {
                throw IARError.validationFailed(reason: .signatureValidation(.invalidCertificateChainOfTrust))
            }
        } else {
            guard SecTrustEvaluate(wwdcTrust!, &secTrustResult) == errSecSuccess else {
                throw IARError.validationFailed(reason: .signatureValidation(.invalidCertificateChainOfTrust))
            }
        }
        
        if #available(OSX 10.14, iOS 12.0, tvOS 12.0, *)
        {
            var error: CFError?
            guard SecTrustEvaluateWithError(iTunesTrust!, &error) else {
                throw IARError.validationFailed(reason: .signatureValidation(.invalidCertificateChainOfTrust))
            }
        } else {
            guard SecTrustEvaluate(iTunesTrust!, &secTrustResult) == errSecSuccess else {
                throw IARError.validationFailed(reason: .signatureValidation(.invalidCertificateChainOfTrust))
            }
        }
    }
    
    @available(OSX 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
    func checkSignatureValidity() throws
    {
        guard let signature = signature else
        {
            throw IARError.validationFailed(reason: .signatureValidation(.signatureNotFound))
        }
        
        guard let iTunesPublicKeyContainer = pkcs7Container.extractiTunesPublicKeyContrainer() else {
            throw IARError.validationFailed(reason: .signatureValidation(.unableToLoadiTunesPublicKey))
        }
        
        let keyDict: [String:Any] =
        [
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048,
        ]

        guard let iTunesPublicKeySec = SecKeyCreateWithData(iTunesPublicKeyContainer as CFData, keyDict as CFDictionary, nil) else {
            throw IARError.validationFailed(reason: .signatureValidation(.unableToLoadAppleIncPublicSecKey))
        }
        
        var umErrorCF: Unmanaged<CFError>? = nil
        guard SecKeyVerifySignature(iTunesPublicKeySec, .rsaSignatureMessagePKCS1v15SHA1, pkcs7Container.extractInAppPayload()! as CFData, signature as CFData, &umErrorCF) else {
            /*
            let error = umErrorCF?.takeRetainedValue() as Error? as NSError?
            print("error is \(error)")
             */
            throw IARError.validationFailed(reason: .signatureValidation(.invalidSignature))
        }
        
    }
    
    /// Computed SHA-1 hash, used to validate the receipt.
    internal var computedHashData: Data
    {
        let uuidData = guid()
        let opaqueData = opaqueValue
        let bundleIdData = bundleIdentifierData
        
        var hash = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        var ctx = CC_SHA1_CTX()
        CC_SHA1_Init(&ctx)
        CC_SHA1_Update(&ctx, uuidData.bytes, CC_LONG(uuidData.count))
        CC_SHA1_Update(&ctx, opaqueData.bytes, CC_LONG(opaqueData.count))
        CC_SHA1_Update(&ctx, bundleIdData.bytes, CC_LONG(bundleIdData.count))
        CC_SHA1_Final(&hash, &ctx)
        
        return Data(hash)
    }
}

fileprivate func guid() -> Data
{
    
#if !targetEnvironment(macCatalyst) && targetEnvironment(simulator) // Debug purpose only
    var uuidBytes = UUID(uuidString: "22C105F3-61B5-4FE4-8CB2-30AD9723D345")!.uuid
    return Data(bytes: &uuidBytes, count: MemoryLayout.size(ofValue: uuidBytes))
#elseif !targetEnvironment(macCatalyst) && (os(iOS) || os(watchOS) || os(tvOS))
    var uuidBytes = UIDevice.current.identifierForVendor!.uuid
    return Data(bytes: &uuidBytes, count: MemoryLayout.size(ofValue: uuidBytes))
#elseif targetEnvironment(macCatalyst) || os(macOS)
    
    var masterPort = mach_port_t()
    var kernResult: kern_return_t = IOMasterPort(mach_port_t(MACH_PORT_NULL), &masterPort)
    if (kernResult != KERN_SUCCESS)
    {
        assertionFailure("Failed to initialize master port")
    }
    
    let matchingDict = IOBSDNameMatching(masterPort, 0, "en0")
    if (matchingDict == nil)
    {
        assertionFailure("Failed to retrieve guid")
    }
    
    var iterator = io_iterator_t()
    kernResult = IOServiceGetMatchingServices(masterPort, matchingDict, &iterator)
    if (kernResult != KERN_SUCCESS)
    {
        assertionFailure("Failed to retrieve guid")
    }
    
    var guidData: Data?
    var service = IOIteratorNext(iterator)
    var parentService = io_object_t()
    
    defer
    {
        IOObjectRelease(iterator)
    }
    
    while(service != 0)
    {
        kernResult = IORegistryEntryGetParentEntry(service, kIOServicePlane, &parentService)
        
        if (kernResult == KERN_SUCCESS)
        {
            guidData = IORegistryEntryCreateCFProperty(parentService, "IOMACAddress" as CFString, nil, 0).takeRetainedValue() as? Data
            
            IOObjectRelease(parentService)
        }
        IOObjectRelease(service)
        
        if  guidData != nil {
            break
        }else{
            service = IOIteratorNext(iterator)
        }
    }
    
    if guidData == nil
    {
        assertionFailure("Failed to retrieve guid")
    }
    
    return guidData!    
#endif
}
