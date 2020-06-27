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
        .background(Color.revenueCatRed)
    }
}

struct OfferingView: View {
    @State var selected: Bool
    
    var body: some View {
        Button(action: {
            selected.toggle()
        }, label: {
            ZStack(alignment: .top) {
                
                let backgroundColor = selected ? Color.white : Color.black.opacity(0.1)
                let foregroundColor = selected ? Color.black : Color.white.opacity(0.5)
                
                VStack {
                    VStack {
                        Text("1")
                        Text("YEAR")
                    }
                    .padding()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    
                    .background(Color.black.opacity(0.1))
                    
                    VStack {
                        Text("$29.49")
                            .bold()
                        Text("$2.46 / mo")
                            .font(.caption)
                    }
                    .padding()
                }
                .background(backgroundColor)
                .cornerRadius(12)
                .foregroundColor(foregroundColor)
                
                DiscountBadge()
            }
            
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
                .previewDevice("iPad Pro (11-inch) (2nd generation)")
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
            OfferingView(selected: false)
            OfferingView(selected: true)
            OfferingView(selected: false)
        }.padding()
    }
}

struct DiscountBadge: View {
    var body: some View {
        Text("SAVE 98%")
            .bold()
            .padding(.vertical, 3.0)
            .padding(.horizontal, 9.0)
            .foregroundColor(.white)
            .background(Color.discountBadge)
            .font(.caption2)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .offset(x: 0, y: -10)
    }
}
