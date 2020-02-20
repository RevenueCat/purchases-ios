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
@property (nonatomic, copy, readonly) NSString *appID;
@property (nonatomic, readonly, nullable) NSDate *syncStartedTime;
@property (nonatomic, readonly) NSDate *setTime;
@property (nonatomic, assign, readonly) BOOL isSynced;

- (instancetype)initWithKey:(NSString *)key
                      value:(NSString *)value
                  appUserID:(NSString *)appUserID
                      appID:(NSString *)appID;

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSObject *> *)dict;

- (instancetype)init NS_UNAVAILABLE;

- (NSDictionary <NSString *, NSObject *> *)asDictionary;

- (NSString *)asJSON;

@end


NS_ASSUME_NONNULL_END
