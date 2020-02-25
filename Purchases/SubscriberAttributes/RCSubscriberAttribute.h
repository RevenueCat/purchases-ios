//
// Created by Andrés Boedo on 2/17/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface RCSubscriberAttribute : NSObject

@property (nonatomic, copy, readonly) NSString *key;
@property (nonatomic, copy, readonly) NSString *value;
@property (nonatomic, copy, readonly) NSString *appUserID;
@property (nonatomic, readonly) NSDate *setTime;
@property (nonatomic, assign) BOOL isSynced;

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value appUserID:(NSString *)appUserID;

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSObject *> *)dict;

- (instancetype)init NS_UNAVAILABLE;

- (NSDictionary <NSString *, NSObject *> *)asDictionary;

- (NSDictionary <NSString *, NSObject *> *)asBackendDictionary;

@end

typedef NSMutableDictionary<NSString *, RCSubscriberAttribute *> *RCSubscriberAttributeMutableDict;
typedef NSDictionary<NSString *, RCSubscriberAttribute *> *RCSubscriberAttributeDict;

NS_ASSUME_NONNULL_END
