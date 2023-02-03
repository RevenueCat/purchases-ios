//
//  Extensions.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 10/25/22.
//

import Foundation

extension String {

    var nonEmpty: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmed.isEmpty
            ? nil
            : trimmed
    }

}
