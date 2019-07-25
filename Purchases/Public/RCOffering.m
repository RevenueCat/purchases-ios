//
//  RCOffering.m
//  Purchases
//
//  Created by Jacob Eiting on 6/2/18.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCOffering.h"
#import "RCPackage.h"
#import <StoreKit/StoreKit.h>

@interface RCOffering ()

@property (readwrite, nonatomic) NSString *activeProductIdentifier;
@property (readwrite, nonatomic) SKProduct *activeProduct;

@end

@implementation RCOffering

- (RCPackage * _Nullable)packageWithIdentifier:(NSString * _Nullable)identifier
{
    return nil;
}

- (NSString *)localizedPriceString {
    if (!self.activeProduct) return @"";
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = self.activeProduct.priceLocale;
    
    return [formatter stringFromNumber:self.activeProduct.price];
}

- (NSString *)localizedIntroductoryPriceString {
    if (!self.activeProduct) return @"";
    
    if (@available(iOS 11.2, macOS 10.13.2, *)) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.locale = self.activeProduct.priceLocale;
        
        return [formatter stringFromNumber:self.activeProduct.introductoryPrice.price];
    } else {
        return @"";
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Offering activeProductIdentifier: %@, activeProduct: %@>", self.activeProductIdentifier, self.activeProductIdentifier];
}

@end
