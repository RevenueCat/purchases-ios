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
            Text("Parsed Receipt")
                .font(.title2)
                .padding()

            ScrollView {
                Text(parsedReceipt)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .textSelection(.enabled)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            Text("Verify Receipt")
                .font(.title2)
                .padding()
            
            ScrollView {
                Text(verifyReceiptResult)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .textSelection(.enabled)
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }.frame(minWidth: 800, maxWidth: .infinity, minHeight: 1000, maxHeight: .infinity, alignment: .center)
    }

    func inspectReceipt() async {
        do {
            guard !encodedReceipt.isEmpty else { return }
            parsedReceipt = try PurchasesReceiptParser.default.parse(base64String: encodedReceipt).debugDescription
            verifyReceiptResult = await ReceiptVerifier().verifyReceipt(base64Encoded: encodedReceipt,
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
