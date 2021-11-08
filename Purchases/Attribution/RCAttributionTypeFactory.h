//
// Created by Andrés Boedo on 2/25/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^RCAttributionDetailsBlock)(NSDictionary<NSString *, NSObject *> *_Nullable, NSError *_Nullable);

typedef NS_ENUM(NSUInteger, FakeTrackingManagerAuthorizationStatus) {
    FakeTrackingManagerAuthorizationStatusNotDetermined = 0,
    FakeTrackingManagerAuthorizationStatusRestricted,
    FakeTrackingManagerAuthorizationStatusDenied,
    FakeTrackingManagerAuthorizationStatusAuthorized
};

// You can see the class here: https://rev.cat/fake-affiche-client
@protocol FakeAfficheClient <NSObject>

+ (instancetype)sharedClient;
- (void)requestAttributionDetailsWithBlock:(RCAttributionDetailsBlock)completionHandler;

@end

// You can see the class here: https://rev.cat/FakeASIdManager
@protocol FakeASIdManager <NSObject>

+ (instancetype)sharedManager;

@end

// You can see the class here: https://rev.cat/FakeFollowingManager
@protocol FakeFollowingManager <NSObject>

+ (NSInteger)trackingAuthorizationStatus;

@end


NS_SWIFT_NAME(AttributionTypeFactory)
@interface RCAttributionTypeFactory : NSObject

- (Class<FakeAfficheClient> _Nullable)afficheClientClass;
- (Class<FakeFollowingManager> _Nullable)atFollowingClass;
- (Class<FakeASIdManager> _Nullable)asIdClass;

- (NSString *)asIdentifierPropertyName;
- (NSString *)authorizationStatusPropertyName;

@property (readonly) NSString *mangledIdentifierClassName;
@property (readonly) NSString *mangledIdentifierPropertyName;
@property (readonly) NSString *mangledTrackingClassName;
@property (readonly) NSString *mangledAuthStatusPropertyName;

@end


NS_ASSUME_NONNULL_END
