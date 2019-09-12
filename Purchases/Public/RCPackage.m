//
//  RCPackage.m
//  Purchases
//
//  Created by Jacob Eiting on 7/22/19.
//  Copyright © 2019 Purchases. All rights reserved.
//

#import "RCPackage+Protected.h"
#import <StoreKit/StoreKit.h>

@interface RCPackage ()

@property (readwrite) NSString *identifier;
@property (readwrite) RCPackageType packageType;
@property (readwrite) SKProduct *product;

@end

@implementation RCPackage

+ (nullable NSString *)getStringFromPackageType:(RCPackageType)packageType
{
    NSArray *arrayOfStrings = @[@"$rc_lifetime", @"$rc_annual", @"$rc_six_month", @"$rc_three_month", @"$rc_two_month", @"$rc_monthly", @"$rc_weekly"];
    if (packageType > arrayOfStrings.count) {
        return nil;
    }
    return arrayOfStrings[packageType];
}

+ (RCPackageType)getPackageTypeFromString:(NSString *)string
{
    NSInteger index = [@[@"$rc_lifetime", @"$rc_annual", @"$rc_six_month", @"$rc_three_month", @"$rc_two_month", @"$rc_monthly", @"$rc_weekly"] indexOfObject:string];
    if(NSNotFound == index) {
        return RCPackageTypeCustom;
    }
    return (RCPackageType)(index);
}


- (instancetype)initWithIdentifier:(NSString *)identifier packageType:(RCPackageType)packageType product:(SKProduct *)product
{
    self = [super init];
    if (self) {
        self.identifier = identifier;
        self.packageType = packageType;
        self.product = product;
    }

    return self;
}

- (NSString *)localizedPriceString {
    if (!self.product) return @"";

    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = self.product.priceLocale;

    return [formatter stringFromNumber:self.product.price];
}

- (NSString *)localizedIntroductoryPriceString {
    if (@available(iOS 11.2, macOS 10.13.2, *)) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.locale = self.product.priceLocale;

        return [formatter stringFromNumber:self.product.introductoryPrice.price];
    } else {
        return @"";
    }
}

@end
