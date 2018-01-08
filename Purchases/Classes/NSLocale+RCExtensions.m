//
//  NSLocale+RCExtensions.m
//  Purchases
//
//  Created by Jacob Eiting on 1/8/18.
//  Copyright © 2018 Purchases. All rights reserved.
//

#import "NSLocale+RCExtensions.h"

@implementation NSLocale (RCExtensions)

- (nullable NSString *)rc_currencyCode {
    if(@available(iOS 10.0, *)) {
        return self.currencyCode;
    } else {
        return [self objectForKey:NSLocaleCurrencyCode];
    }
}

@end
