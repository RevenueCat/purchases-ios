//
//  Fakes.swift
//
//  Created by RevenueCat.
//

import XCTest

#if os(iOS) && canImport(PrebidMobile)
import RevenueCat
@_spi(Experimental) @testable import RevenueCatAds
import UIKit

/// Local base class for RevenueCatAds unit tests.
typealias TestCase = XCTestCase

func makeURL(_ string: String) -> URL {
    guard let url = URL(string: string) else { fatalError("Invalid URL \(string)") }
    return url
}

#endif
