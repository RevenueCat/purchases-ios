//
//  ReceiptParserIntegrationApp.swift
//  ReceiptParserIntegration
//
//  Created by Nacho Soto on 11/29/22.
//

import SwiftUI

import ReceiptParser

@main
struct ReceiptParserIntegrationApp: App {

    init() {
        let parser = PurchasesReceiptParser.default
        let _: AppleReceipt? = try? parser.parse(from: Data())
    }

    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
    }

}
