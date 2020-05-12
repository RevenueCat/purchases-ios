//
// Created by Andrés Boedo on 2/24/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSError (RCExtensions)

- (BOOL)successfullySynced;
- (nullable NSDictionary *)subscriberAttributesErrors;

@end


NS_ASSUME_NONNULL_END
