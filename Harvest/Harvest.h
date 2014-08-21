//
//  Harvest.h
//  Harvest
//
//  Created by Sean McGary on 8/20/14.
//  Copyright (c) 2014 Sean McGary. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

typedef void (^PreTrackBlock)(NSString *, NSDictionary *, void(^cb)(NSString *, NSDictionary *));

@interface Harvest : NSObject

@property (strong, nonatomic) NSString *apiToken;
@property (strong, nonatomic) NSDictionary *includeData;
@property (strong, nonatomic) NSString *hostname;
@property (strong, nonatomic) PreTrackBlock pretrack;
@property (strong, nonatomic) dispatch_queue_t dispatchQueue;


// static methods
+(id) sharedManager;

+(void) trackEvent:(NSString *) event withData:(NSDictionary * )data;
+(void) identifyUser: (NSString *) idToReplace;
+(void) setApiToken:(NSString *) apiToken andHostname: (NSString *) hostname;
+(void) includeData: (NSDictionary *) data;
+(void) setPretrackHandler: (PreTrackBlock) preTrack;
+(NSString *) generateUUID;


// instance methods
-(void) track: (NSString *)event withData:(NSDictionary *) data;
-(void) identify:(NSString *) idToReplace;
-(void) alwaysInclude: (NSDictionary *) data;
-(void) setPretrackBlock: (PreTrackBlock) block;

-(void) setUserCookie: (NSDictionary *) data;
-(NSDictionary *) getUserCookie;
-(NSDictionary *) generateCookieData;
-(NSNumber *) getTimestamp;

@end
