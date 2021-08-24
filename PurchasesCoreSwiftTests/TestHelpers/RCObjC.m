//
//  RCObjC.m
//  Purchases
//
//  Created by Joshua Liebowitz on 6/10/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

#import "RCObjC.h"

@implementation RCObjC

+ (BOOL)catchExceptionFromBlock:(void(^)(void))block error:(__autoreleasing NSError **)error {
    @try {
        block();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

@end
