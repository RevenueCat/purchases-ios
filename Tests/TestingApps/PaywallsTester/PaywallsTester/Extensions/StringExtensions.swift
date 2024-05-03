//
//  StringExtensions.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

public extension String {

    /// Returns `nil` if `self` is an empty string.
    var notEmpty: String? {
        return self.isEmpty
        ? nil
        : self
    }
    
    /// Returns `true` if it contains anything other than whitespaces.
    var isNotEmpty: Bool {
        return self.notEmptyOrWhitespaces != nil
    }

    /// Returns `nil` if `self` is an empty string or it only contains whitespaces.
    var notEmptyOrWhitespaces: String? {
        return self.trimmingWhitespacesAndNewLines.isEmpty
        ? nil
        : self
    }

    var trimmingWhitespacesAndNewLines: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var asData: Data {
        return Data(self.utf8)
    }

}
