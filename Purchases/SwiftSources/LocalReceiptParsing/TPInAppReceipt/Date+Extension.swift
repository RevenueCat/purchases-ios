//
//  Date+Extension.swift
//  TPInAppReceipt
//
//  Created by Pavel Tikhonenko on 01/10/16.
//  Copyright © 2016-2020 Pavel Tikhonenko. All rights reserved.
//

import Foundation

extension Date
{
    func rfc3339date(fromString string: String) -> Date?
    {
        return string.rfc3339date()
    }
}

extension String
{
    func utcTime() -> Date?
    {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "YYMMDDHHmmss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let date = formatter.date(from: self)
        return date
    }
    
    func rfc3339date() -> Date?
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        let date = formatter.date(from: self)
        return date
    }
}
