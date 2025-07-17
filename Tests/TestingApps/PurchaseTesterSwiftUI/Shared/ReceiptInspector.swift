//
//  ContentView.swift
//  ReceiptParser
//
//  Created by Andrés Boedo on 1/25/23.
//

import SwiftUI
import ReceiptParser

#if !os(watchOS)

struct ReceiptInspectorView: View {

    @State private var encodedReceipt: String = ""
    @State private var parsedReceipt: String = ""
    @State private var verifyReceiptResult: String = ""
    @State private var sharedSecret: String = ""

    var body: some View {
        VStack {
            Text("Receipt Parser")
                .font(.title)
                .padding()

            TextField("Enter receipt text here (base64 encoded)", text: $encodedReceipt, onEditingChanged: { isEditing in
                    if !isEditing {
                        Task {
                            await inspectReceipt()
                        }
                    }
                })
                    #if !os(tvOS)
                    .textFieldStyle(.roundedBorder)
                    #endif
                    .padding()

            TextField("Enter shared secret here", text: $sharedSecret, onEditingChanged: { isEditing in
                    if !isEditing {
                        Task {
                            await inspectReceipt()
                        }
                    }
                })
                    #if !os(tvOS)
                    .textFieldStyle(.roundedBorder)
                    #endif
                    .padding()

            Divider()
            Text("Parsed Receipt")
                .font(.title2)
                .padding()

            ScrollView {
                Text(parsedReceipt)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    #if !os(tvOS)
                    .textSelection(.enabled)
                    #endif
            }.frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            Text("Verify Receipt")
                .font(.title2)
                .padding()
            
            ScrollView {
                Text(verifyReceiptResult)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    #if !os(tvOS)
                    .textSelection(.enabled)
                    #endif
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.frame(minWidth: 800, maxWidth: .infinity, minHeight: 1000, maxHeight: .infinity, alignment: .center)
    }

    func inspectReceipt() async {
        do {
            guard !encodedReceipt.isEmpty else { return }
            // in kibana, receipts get encoded with extra `\`s
            let receiptWithoutForwardSlashes = encodedReceipt.replacingOccurrences(of: "\\", with: "")
            // just in case you accidentally copied with extra double-quotations
            let receiptWithoutQuotations = receiptWithoutForwardSlashes.replacingOccurrences(of: "\"", with: "")
            parsedReceipt = try PurchasesReceiptParser.default.parse(base64String: receiptWithoutQuotations).debugDescription
            verifyReceiptResult = await ReceiptVerifier().verifyReceipt(base64Encoded: receiptWithoutQuotations,
                                                                        sharedSecret: sharedSecret)
        } catch {
            parsedReceipt = "Couldn't decode receipt. Error:\n\(error)"
        }
    }
}

struct ReceiptInspectorView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiptInspectorView()
    }
}

#endif
