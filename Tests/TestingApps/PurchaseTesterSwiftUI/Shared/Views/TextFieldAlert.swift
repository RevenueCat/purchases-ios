//
//  TextFieldAlert.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 2/2/22.
//

import Foundation
import SwiftUI

struct TextFieldAlert<Presenting>: View where Presenting: View {
    @Environment(\.colorScheme) var colorScheme
    
    typealias Completion = () -> ()

    @Binding var isShowing: Bool
    let presenting: Presenting
    let title: String
    let fields: [(String, String, Binding<String>)]
    let completion: Completion

    var body: some View {
        GeometryReader { (deviceSize: GeometryProxy) in
            ZStack {
                self.presenting
                    .disabled(isShowing)
                VStack {
                    
                    Text(self.title).bold()
                    
                    VStack(alignment: .leading) {
                        ForEach(self.fields, id: \.self.0) { fieldData in
                            Text(fieldData.0)
                            TextField(fieldData.1, text: fieldData.2)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                            Divider()
                        }
                    }
                    
                    HStack {
                        Button(action: {
                            withAnimation {
                                self.completion()
                                self.isShowing.toggle()
                            }
                        }) {
                            Text("Dismiss")
                        }
                    }
                }
                .padding()
                .background(colorScheme == .dark ? .black : .white)
                .frame(
                    width: deviceSize.size.width*0.7,
                    height: deviceSize.size.height*0.7
                )
                .shadow(radius: 5)
                .opacity(self.isShowing ? 1 : 0)
            }
        }
    }

}

extension View {
    func textFieldAlert(isShowing: Binding<Bool>,
                        title: String,
                        fields: [(String, String, Binding<String>)],
                        completion: @escaping TextFieldAlert.Completion) -> some View {
        TextFieldAlert(isShowing: isShowing,
                       presenting: self,
                       title: title,
                       fields: fields,
                       completion: completion)
    }

}
