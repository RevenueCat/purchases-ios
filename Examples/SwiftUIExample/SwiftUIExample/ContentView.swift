//
//  ContentView.swift
//  SwiftUIExample
//
//  Created by Andrés Boedo on 6/26/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Group {
                        Spacer()
                        Text("Upsell Screen")
                            .font(.title)
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                        
                        Text("New cats, unlimited cats, personal cat insights and more!")
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    OfferingsView().padding()
                    Spacer()
                    Group {
                        ContinueButtonView()
                            .padding()
                        Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button(action: {}, label: {
                            Text("RESTORE PURCHASES")
                                .foregroundColor(.white)
                                .opacity(0.8)
                        })
                        
                        Spacer()
                        
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height * 1.3, maxHeight: .infinity, alignment: .bottom)
                .background(Color.revenueCatRed)
            }
            .edgesIgnoringSafeArea(.all)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct OfferingView: View {
    var body: some View {
        Button(action: {}, label: {
            VStack {
                VStack {
                    Text("1")
                    Text("YEAR")
                }
                .padding()
                .frame(minWidth: 0, maxWidth: .infinity)
                
                .background(Color.gray.opacity(0.5))
                
                VStack {
                    Text("$29.49")
                        .bold()
                    Text("$2.46 / mo")
                        .font(.caption)
                }
                .padding()
                .background(Color.white)
            }
            .background(Color.white)
            .cornerRadius(16)
            .foregroundColor(Color.black)
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
            ContentView()
                .previewDevice("iPhone SE (2nd generation)")
            ContentView()
        }
    }
}

struct ContinueButtonView: View {
    var body: some View {
        HStack {
            Spacer()
            Button(action: {}, label: {
                HStack {
                    Spacer()
                    Text("Continue")
                        .bold()
                        .foregroundColor(.revenueCatRed)
                        .padding()
                        
                    Spacer()
                }
            })
            .background(Color.white)
            .cornerRadius(50)
            Spacer()
        }
    }
}

struct OfferingsView: View {
    var body: some View {
        HStack {
            OfferingView()
            OfferingView()
            OfferingView()
        }.padding()
    }
}
