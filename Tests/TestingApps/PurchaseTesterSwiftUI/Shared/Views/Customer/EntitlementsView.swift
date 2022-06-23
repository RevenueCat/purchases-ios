//
//  EntitlementsView.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 2/3/22.
//

import Foundation
import SwiftUI
import RevenueCat

struct EntitlementsView: View {
    let customerInfo: RevenueCat.CustomerInfo
    
    let dateFormatter: DateFormatter = {
        var df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df
    }()
    
    var active: [String] {
        return customerInfo.entitlements.all.compactMap { (key, entitlement) -> String? in
            return entitlement.isActive ? key : nil
        }
    }
    
    var inactive: [String] {
        return customerInfo.entitlements.all.compactMap { (key, entitlement) -> String? in
            return !entitlement.isActive ? key : nil
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Section(header: Text("Active Entitlements").bold()) {
                    ForEach(self.active, id: \.self) { id in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text(id)
                                Spacer()
                            }
                        }
                    }
                }
                
                Section(header: Text("Inactive Entitlements").bold()) {
                    ForEach(self.inactive, id: \.self) { id in
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text(id)
                                Spacer()
                            }
                        }
                    }
                }
            }
        }.padding(.horizontal, 20)
    }
}
