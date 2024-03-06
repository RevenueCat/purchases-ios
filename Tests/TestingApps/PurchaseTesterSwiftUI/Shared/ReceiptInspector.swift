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
            .textFieldStyle(.roundedBorder)
            .padding()

            TextField("Enter shared secret here", text: $sharedSecret, onEditingChanged: { isEditing in
                if !isEditing {
                    Task {
                        await inspectReceipt()
                    }
                }
            })
            .textFieldStyle(.roundedBorder)
            .padding()

            Divider()

            ReceiptInformationView(title: "Parsed Receipt", informationText: parsedReceipt)

            Divider()

            ReceiptInformationView(title: "SK1 Verify Receipt", informationText: verifyReceiptResult)

        }
        .frame(minWidth: 800, maxWidth: .infinity, minHeight: 1000, maxHeight: .infinity, alignment: .center)
        .background(Color(red: 0.1, green: 0.1, blue: 0.1))

    }

    func inspectReceipt() async {
        do {
            guard !encodedReceipt.isEmpty else { return }
            // in kibana, receipts get encoded with extra `\`s
            let receiptWithoutForwardSlashes = encodedReceipt.replacingOccurrences(of: "\\", with: "")
            // just in case you accidentally copied with extra double-quotations
            let receiptWithoutQuotations = receiptWithoutForwardSlashes.replacingOccurrences(of: "\"", with: "")
            parsedReceipt = try PurchasesReceiptParser.default.parse(base64String: receiptWithoutQuotations).prettyPrinted
            verifyReceiptResult = await ReceiptVerifier().verifyReceipt(base64Encoded: receiptWithoutQuotations,
                                                                        sharedSecret: sharedSecret)
        } catch {
            parsedReceipt = "Couldn't decode receipt. Error:\n\(error)"
            verifyReceiptResult = ""
        }
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
