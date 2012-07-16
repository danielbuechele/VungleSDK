//
//  VGAnalytics.h
//  ExampleAdvertiserSDK
//
//  Created by Harsh Jariwala on 6/25/12.
//

#import <Foundation/Foundation.h>

@class VGAnalytics;

@protocol VGAnalyticsDelegate <NSObject>
@optional

/*  
 Notifies the delegate that the Actions have been uploaded
 */
- (void)VGAnalytics:(VGAnalytics *)tool didUploadActions:(NSArray *) Actions;

/*
 Notifies the delegate that there was an error while uploading the Actions
*/
- (void)VGAnalytics:(VGAnalytics *)tool didFailToUploadActions:(NSArray *) Actions withError:(NSError *) error;

@end

static const NSUInteger kVGInterval = 30;

@interface VGAnalytics : NSObject {
    NSString *appId;
    NSMutableArray *allActions;
    NSArray *actions;
    NSString* analyticsURL;
    NSMutableDictionary *userProperties;
    BOOL sendOnBackground;
    id<VGAnalyticsDelegate> delegate;
    NSUInteger uploadInterval;
    UIBackgroundTaskIdentifier taskIdentCard;
}

@property(nonatomic,retain) id<VGAnalyticsDelegate> delegate;

+(id)sharedTool;

-(id)initWithAppId:(NSString *)AppId;

-(void)sendData;
-(void)trackAction:(NSString *)act;

-(NSString*)findReachability;
-(NSString*)getVersion;
-(NSString*)getiOSVersion;


@end