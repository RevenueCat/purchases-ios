//
//  SubscriberAttributesView.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 2/3/22.
//

import Foundation
import SwiftUI
import RevenueCat

struct SubscriberAttributesView: View {
   

    enum RevenueCatKind: String, CaseIterable, Identifiable {
        var id: String {
            return self.rawValue
        }
        
        case setAd
        case setEmail
        case setDisplayName
        case setKeyword
        case setCampaign
        case setCreative
        case setAdGroup
        case setPushToken
        case setMediaSource
        case setPhoneNumber
    }
    
    enum ThirdPartyKind: String, CaseIterable, Identifiable {
        var id: String {
            return self.rawValue
        }
        
        case setAdjustID
        case setAppsflyerID
        case setAirshipChannelID
        case setCleverTapID
        case setMparticleID
        case setOnesignalID
        case setFBAnonymousID
    }
    
    let customerInfo: RevenueCat.CustomerInfo
    
    @State private var showAttributesAlert = false
    @State private var attributeKey: String = ""
    @State private var attributeValue: String = ""
    
    @State private var showOtherAlert = false
    @State private var otherValue: String = ""
    
    // This is a bad way of storing this
    @State private var revenueCatKind: RevenueCatKind? = nil
    @State private var thirdPartyKind: ThirdPartyKind? = nil
    
    var body: some View {
        List {
            Section("Customer") {
                Button {
                    self.attributeKey = ""
                    self.attributeValue = ""
                    self.showAttributesAlert = true
                } label: {
                    Text("setAttributes")
                }
            }
            
            Section("RevenueCat") {
                ForEach(RevenueCatKind.allCases) { kind in
                    Button {
                        self.otherValue = ""
                        self.revenueCatKind = kind
                        self.thirdPartyKind = nil
                        self.showOtherAlert = true
                    } label: {
                        Text(kind.rawValue)
                    }
                }
            }
            
            Section("Third Party") {
                ForEach(ThirdPartyKind.allCases) { kind in
                    Button {
                        self.otherValue = ""
                        self.revenueCatKind = nil
                        self.thirdPartyKind = kind
                        self.showOtherAlert = true
                    } label: {
                        Text(kind.rawValue)
                    }
                }
            }
        }
        .textFieldAlert(isShowing: self.$showAttributesAlert, title: "Attribute", fields: [
            ("Key", "Key name", self.$attributeKey),
            ("Value", "Value", self.$attributeValue)
        ]) {
            Purchases.shared.setAttributes([self.attributeKey:  self.attributeValue])
        }
        .textFieldAlert(isShowing: self.$showOtherAlert, title: self.revenueCatKind?.rawValue ?? self.thirdPartyKind?.rawValue ?? "<ERROR>", fields: [
            ("Value", "Value", self.$otherValue),
        ]) {
            if let kind = self.revenueCatKind {
                switch kind {
                case .setAd:
                    Purchases.shared.setAd(self.otherValue)
                case .setEmail:
                    Purchases.shared.setEmail(self.otherValue)
                case .setDisplayName:
                    Purchases.shared.setDisplayName(self.otherValue)
                case .setKeyword:
                    Purchases.shared.setKeyword(self.otherValue)
                case .setCampaign:
                    Purchases.shared.setCampaign(self.otherValue)
                case .setCreative:
                    Purchases.shared.setCreative(self.otherValue)
                case .setAdGroup:
                    Purchases.shared.setAdGroup(self.otherValue)
                case .setPushToken:
                    if let token = self.otherValue.data(using: .utf8) {
                        Purchases.shared.setPushToken(token)
                    }
                case .setMediaSource:
                    Purchases.shared.setMediaSource(self.otherValue)
                case .setPhoneNumber:
                    Purchases.shared.setPhoneNumber(self.otherValue)
                }
            }
            
            if let kind = self.thirdPartyKind {
                switch kind {
                case .setAdjustID:
                    Purchases.shared.setAdjustID(self.otherValue)
                case .setAppsflyerID:
                    Purchases.shared.setAppsflyerID(self.otherValue)
                case .setAirshipChannelID:
                    Purchases.shared.setAirshipChannelID(self.otherValue)
                case .setCleverTapID:
                    Purchases.shared.setCleverTapID(self.otherValue)
                case .setMparticleID:
                    Purchases.shared.setMparticleID(self.otherValue)
                case .setOnesignalID:
                    Purchases.shared.setOnesignalID(self.otherValue)
                case .setFBAnonymousID:
                    Purchases.shared.setFBAnonymousID(self.otherValue)
                }
            }
        }
    }
}
