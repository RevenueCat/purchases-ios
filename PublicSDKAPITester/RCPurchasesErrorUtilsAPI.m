//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RCPurchasesErrorUtilsAPI.m
//
//  Created by César de la Vega on 7/21/21.

@import Purchases;
@import StoreKit;

#import "RCPurchasesErrorUtilsAPI.h"

@implementation RCPurchasesErrorUtilsAPI

+ (void)checkAPI {
    NSError *underlying = [[NSError alloc] initWithDomain:@"NetworkErrorDomain" code:28 userInfo:@{@"key": @"value"}];
    NSError *error = [RCPurchasesErrorUtils networkErrorWithUnderlyingError:underlying];
    error = [RCPurchasesErrorUtils backendErrorWithBackendCode:@12345 backendMessage:@"un mensaje"];
    error = [RCPurchasesErrorUtils backendErrorWithBackendCode:@12345 backendMessage:@"un mensaje" finishable:YES];
    error = [RCPurchasesErrorUtils unexpectedBackendResponseError];
    error = [RCPurchasesErrorUtils missingReceiptFileError];
    error = [RCPurchasesErrorUtils missingAppUserIDError];
    error = [RCPurchasesErrorUtils logOutAnonymousUserError];
    error = [RCPurchasesErrorUtils paymentDeferredError];
    error = [RCPurchasesErrorUtils unknownError];
    error = [RCPurchasesErrorUtils unknownErrorWithMessage:@"🎈🐐"];
    NSError* underlyingSKError = [[NSError alloc] initWithDomain:SKErrorDomain code:SKErrorUnknown userInfo:@{@"key": @"value"}];
    error = [RCPurchasesErrorUtils purchasesErrorWithSKError:underlyingSKError];
    NSLog(@"%@", error.localizedDescription);
}

@end
