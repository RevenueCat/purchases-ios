//
// Created by RevenueCat on 2/17/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttribute : NSObject

@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, copy, readonly) NSString *value;
@property (nonatomic, readonly) NSDate *setTime;
@property (nonatomic, assign) BOOL isSynced;

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value;

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSObject *> *)dict;

- (instancetype)init NS_UNAVAILABLE;

- (NSDictionary <NSString *, NSObject *> *)asDictionary;

- (NSDictionary <NSString *, NSObject *> *)asBackendDictionary;

- (BOOL)isEqual:(nullable RCSubscriberAttribute *)attribute;

@end

typedef NSMutableDictionary<NSString *, RCSubscriberAttribute *> *RCSubscriberAttributeMutableDict;
typedef NSDictionary<NSString *, RCSubscriberAttribute *> *RCSubscriberAttributeDict;

NS_ASSUME_NONNULL_END
