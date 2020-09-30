//
//  NSDictionary+RCExtensions.h
//  Purchases
//
//  Created by Andrés Boedo on 9/29/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSDictionary (RCExtensions)

- (NSDictionary *)removingNSNullValues;

@end


NS_ASSUME_NONNULL_END
