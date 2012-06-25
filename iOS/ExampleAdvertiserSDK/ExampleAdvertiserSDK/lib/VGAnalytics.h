//
//  VGAnalytics.h
//  ExampleAdvertiserSDK
//
//  Created by Harsh Jariwala on 6/25/12.
//  Copyright (c) 2012 Carnegie Mellon University. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VGAnalytics : NSObject

@end


@protocol VGAnalyticsDelegate <NSObject>
@optional

/*  
 Notifies the delegate that the Actions have been uploaded
 */
- (void)VGAnalytics:(VGAnalytics *) VGAnalytics didUploadActions:(NSArray *) Actions;

/*
 Notifies the delegate that there was an error while uploading the Actions
*/
- (void)VGAnalytics:(VGAnalytics *) VGAnalytics didFailToUploadActions:(NSArray *) Actions withError:(NSError *) error;

@end