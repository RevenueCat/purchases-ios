//
//  CustomerInfoView.swift
//  PurchaseTester
//
//  Created by Josh Holtz on 2/3/22.
//

import Foundation
import SwiftUI
import RevenueCat

struct CustomerInfoView: View {
    let customerInfo: RevenueCat.CustomerInfo
    
    let dateFormatter: DateFormatter = {
        var df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return df
    }()
    
    var infos: [(String, String)] {
        print("date: \(customerInfo.firstSeen)")
        
        return [
            ("App User ID", Purchases.shared.appUserID),
            ("Original App User ID", customerInfo.originalAppUserId),
            ("First Seen", date(customerInfo.firstSeen) ?? "-"),
            ("Original Application Version", customerInfo.originalApplicationVersion ?? "-"),
            ("Original Purchase Date", date(customerInfo.originalPurchaseDate) ?? "-"),
            ("Latest Expiration Date", date(customerInfo.latestExpirationDate) ?? "-"),
            ("Request Date", date(customerInfo.requestDate) ?? "-"),
        ]
    }
    
    private func date(_ date: Date?) -> String? {
        guard let date = date else {
            return nil
        }
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(self.infos, id: \.0) { info in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(info.0)
                            .bold()
                        Text(info.1)
                    }
                }
            }
        }.padding(.horizontal, 20)
    }
}
