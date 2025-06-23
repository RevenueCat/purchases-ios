//
//  RCVirtualCurrenciesAPI.m
//  ObjcAPITester
//
//  Created by Will Taylor on 6/10/25.
//

@import RevenueCat;
#import "RCVirtualCurrenciesAPI.h"

@implementation RCVirtualCurrenciesAPI

+ (void)checkAPI {
    RCVirtualCurrencies *virtualCurrencies = nil;
    NSDictionary<NSString *, RCVirtualCurrency *> *all = virtualCurrencies.all;
    RCVirtualCurrency *subscriptTest = virtualCurrencies[@"test"];
}

@end
