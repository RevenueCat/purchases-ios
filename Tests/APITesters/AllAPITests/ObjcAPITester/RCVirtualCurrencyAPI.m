//
//  RCVirtualCurrencyAPI.m
//  ObjcAPITester
//
//  Created by Will Taylor on 2/28/25.
//

@import RevenueCat;
#import "RCVirtualCurrencyAPI.h"

@implementation RCVirtualCurrencyAPI

+ (void)checkAPI {
    RCVirtualCurrency *virtualCurrency = nil;
    NSInteger balance = virtualCurrency.balance;
    NSString *name = virtualCurrency.name;
    NSString *code = virtualCurrency.code;
    NSString * _Nullable serverDescription = virtualCurrency.serverDescription;
}

@end
