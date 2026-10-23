//
//  Fakes.swift
//
//  Created by RevenueCat.
//

import XCTest

@_spi(Experimental) @testable import RevenueCatAds

/// Local base class for RevenueCatAds unit tests.
typealias TestCase = XCTestCase

func makeURL(_ string: String) -> URL {
    guard let url = URL(string: string) else { fatalError("Invalid URL \(string)") }
    return url
}

