//
//  NSLocale+RCExtensions.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "NSLocale+RCExtensions.h"

@implementation NSLocale (RCExtensions)

- (nullable NSString *)rc_currencyCode {
    if(@available(iOS 10.0, macOS 10.12, tvos 10.0, macCatalyst 13.0, *)) {
        return self.currencyCode;
    } else {
        return [self objectForKey:NSLocaleCurrencyCode];
    }
}

@end
