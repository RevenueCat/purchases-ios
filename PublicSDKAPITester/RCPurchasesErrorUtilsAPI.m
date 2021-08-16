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
@import PurchasesCoreSwift;

#import "RCPurchasesErrorUtilsAPI.h"

@implementation RCPurchasesErrorUtilsAPI

+ (void)checkAPI {
    
    NSError* underlying = [[NSError alloc] initWithDomain:@"NetworkErrorDomain" code:28 userInfo:@{@"key": @"value"}];
    [RCPurchasesErrorUtils networkErrorWithUnderlyingError:underlying];
    [RCPurchasesErrorUtils backendErrorWithBackendCode:@12345 backendMessage:@"un mensaje"];
    [RCPurchasesErrorUtils backendErrorWithBackendCode:@12345 backendMessage:@"un mensaje" finishable:YES];
    [RCPurchasesErrorUtils unexpectedBackendResponseError];
    [RCPurchasesErrorUtils missingReceiptFileError];
    [RCPurchasesErrorUtils missingAppUserIDError];
    [RCPurchasesErrorUtils logOutAnonymousUserError];
    [RCPurchasesErrorUtils paymentDeferredError];
    [RCPurchasesErrorUtils unknownError];
    NSError* underlyingSKError = [[NSError alloc] initWithDomain:SKErrorDomain code:SKErrorUnknown userInfo:@{@"key": @"value"}];
    [RCPurchasesErrorUtils purchasesErrorWithSKError:underlyingSKError];

}

@end
