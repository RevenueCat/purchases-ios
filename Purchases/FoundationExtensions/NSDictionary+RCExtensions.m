//
//  NSDictionary+RCExtensions.m
//  Purchases
//
//  Created by Andrés Boedo on 9/29/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

#import "NSDictionary+RCExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDictionary (RCExtensions)

- (NSDictionary *)removingNSNullValues {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    
    NSEnumerator *enumerator = [self keyEnumerator];
    id key;
     
    while ((key = enumerator.nextObject)) {
        id value = self[key];
        if (![value isKindOfClass:NSNull.class]) {
            result[key] = value;
        }
    }
    
    return result;
}

NS_ASSUME_NONNULL_END


@end
