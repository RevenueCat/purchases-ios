//
//  RCPackage.m
//  Purchases
//
//  Created by RevenueCat.
//  Copyright © 2019 RevenueCat. All rights reserved.
//

#import "RCPackage+Protected.h"
#import <StoreKit/StoreKit.h>

@interface RCPackage ()

@property (readwrite) NSString *identifier;
@property (readwrite) RCPackageType packageType;
@property (readwrite) SKProduct *product;
@property (readwrite) NSString *offeringIdentifier;

@end

@implementation RCPackage

+ (nullable NSString *)stringFromPackageType:(RCPackageType)packageType
{
    if (packageType > PACKAGE_TYPE_STRINGS.count) {
        return nil;
    }
    return PACKAGE_TYPE_STRINGS[packageType];
}

+ (RCPackageType)packageTypeFromString:(NSString *)string
{
    NSInteger index = [PACKAGE_TYPE_STRINGS indexOfObject:string];
    if (NSNotFound == index) {
        if ([string hasPrefix:@"$rc_"]) {
            return RCPackageTypeUnknown;
        } else {
            return RCPackageTypeCustom;
        }
    }
    return (RCPackageType)(index);
}


- (instancetype)initWithIdentifier:(NSString *)identifier packageType:(RCPackageType)packageType product:(SKProduct *)product offeringIdentifier:(NSString *)offeringIdentifier
{
    self = [super init];
    if (self) {
        self.identifier = identifier;
        self.packageType = packageType;
        self.product = product;
        self.offeringIdentifier = offeringIdentifier;
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
    if (@available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *)) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.locale = self.product.priceLocale;

        return [formatter stringFromNumber:self.product.introductoryPrice.price];
    } else {
        return @"";
    }
}

@end
