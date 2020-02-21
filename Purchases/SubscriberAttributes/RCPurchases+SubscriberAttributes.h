//
// Created by Andrés Boedo on 2/21/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPurchases.h

@class RCSubscriberAttribute;

@interface RCPurchases ()

- (void)configureSubscriberAttributesManager;
- (void)clearSubscriberAttributesCache;
- (NSArray <RCSubscriberAttribute *> *)unsyncedAttributes;

@end
