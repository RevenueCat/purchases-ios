//
//  ContentView.swift
//  ReceiptParser
//
//  Created by Andrés Boedo on 1/25/23.
//

import Foundation
import SwiftUI
import ReceiptParser

#if !os(watchOS)

struct ReceiptInspectorView: View {

    @State private var encodedReceipt: String = ""
    @State private var parsedReceipt: String = "A JSON version of the parsed receipt will show up here."
    @State private var verifyReceiptResult: String = "Results of calling /verifyReceipt will show up here."
    @State private var sharedSecret: String = ""
    
    @State private var sk2AuthToken: String = ""
    @State private var sk2AppConfigID: String = ""
    @State private var sk2TransactionID: String = ""
    @State private var sk2ReceiptResult: String = "Results of calling StoreKit 2 diagnostics will show up here."

    var body: some View {
        VStack {
            HStack {

                VStack {
                    Text("StoreKit 1 Receipt")
                        .font(.title)
                        .padding()

                    InputTextField(placeholder: "Enter receipt text here (base64 encoded)", text: $encodedReceipt) {
                        await processSK1Receipt()
                    }

                    InputTextField(placeholder: "Enter shared secret here", text: $sharedSecret) {
                        await processSK1Receipt()
                    }
                }

                Divider()
                
                VStack {
                    Text("StoreKit 2 Receipt")
                        .font(.title)
                        .padding()

                    InputTextField(placeholder: "Enter auth token here", text: $sk2AuthToken) {
                        await processSK2Receipt()
                    }

                    InputTextField(placeholder: "Enter transaction ID here", text: $sk2TransactionID) {
                        await processSK2Receipt()
                    }
                    
                    InputTextField(placeholder: "Enter app config ID here", text: $sk2AppConfigID) {
                        await processSK2Receipt()
                    }
                }
            }


            Divider()

            ReceiptInformationView(title: "Parsed Receipt", informationText: parsedReceipt)

            Divider()
            HStack {
                ReceiptInformationView(title: "SK1 Verify Receipt", informationText: verifyReceiptResult)

                Divider()
                
                ReceiptInformationView(title: "SK2 Transaction details", informationText: sk2ReceiptResult)
            }

        }
        .frame(minWidth: 1200, maxWidth: .infinity, minHeight: 1000, maxHeight: .infinity, alignment: .center)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))

    }

    func processSK1Receipt() async {
        do {
            guard !encodedReceipt.isEmpty else { return }
            // in kibana, receipts get encoded with extra `\`s
            let receiptWithoutForwardSlashes = encodedReceipt.replacingOccurrences(of: "\\", with: "")
            // just in case you accidentally copied with extra double-quotations
            let receiptWithoutQuotations = receiptWithoutForwardSlashes.replacingOccurrences(of: "\"", with: "")
            parsedReceipt = try PurchasesReceiptParser.default.parse(base64String: receiptWithoutQuotations).prettyPrinted
            verifyReceiptResult = await StoreKit1ReceiptVerifier().verifyReceipt(base64Encoded: receiptWithoutQuotations,
                                                                                 sharedSecret: sharedSecret)
        } catch {
            parsedReceipt = "Couldn't decode receipt. Error:\n\(error)"
            verifyReceiptResult = ""
        }
    }

    func processSK2Receipt() async {
        sk2ReceiptResult = await StoreKit2ReceiptVerifier().fetchSK2Diagnostics(appConfigID: sk2AppConfigID,
                                                                                transactionID: sk2TransactionID,
                                                                                token: sk2AuthToken)
    }
}

struct InputTextField: View {
    var placeholder: String
    @Binding var text: String
    let onEditingChanged: () async -> Void

    var body: some View {
        TextField(placeholder, text: $text, onEditingChanged: { isEditing in
            if !isEditing {
                Task {
                    await onEditingChanged()
                }
            }
        })
        .textFieldStyle(.roundedBorder)
        .padding()
    }
}

struct ReceiptInformationView: View {

    var title: String
    var informationText: String

    var body: some View {
        VStack {
            Text(title)
                .font(.title2)
                .padding()

            ScrollView {
                Text(informationText)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black)
                    .foregroundColor(.white)
                    .textSelection(.enabled)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)

            CopyButton(textToCopy: informationText)
        }
    }

}

struct CopyButton: View {

    var textToCopy: String

    var body: some View {
        Button(action: {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(textToCopy, forType: .string)
        }) {
            Image(systemName: "doc.on.doc")
                .imageScale(.large)
        }
        .padding()
    }

}

struct ReceiptInspectorView_Previews: PreviewProvider {

    static var previews: some View {
        ReceiptInspectorView()
    }

}

#endif
