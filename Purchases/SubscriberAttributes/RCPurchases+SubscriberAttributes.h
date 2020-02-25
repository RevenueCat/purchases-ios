//
// Created by Andrés Boedo on 2/21/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RCPurchases.h"
#import "RCSubscriberAttribute.h"

@class RCSubscriberAttribute, RCSubscriberAttributesManager;

@interface RCPurchases ()

@property (nonatomic) RCSubscriberAttributesManager *subscriberAttributesManager;

- (void)configureSubscriberAttributesManager;
- (void)clearSubscriberAttributesCache;
- (RCSubscriberAttributeDict)unsyncedAttributesByKey;

@end
