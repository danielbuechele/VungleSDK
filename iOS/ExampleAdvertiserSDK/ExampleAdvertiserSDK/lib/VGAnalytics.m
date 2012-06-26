//
//  VGAnalytics.m
//  ExampleAdvertiserSDK
//
//  Created by Harsh Jariwala on 6/25/12.
//  Copyright (c) 2012 Carnegie Mellon University. All rights reserved.
//

#import "VGAnalytics.h"


@interface VGAnalytics ()
@property(nonatomic,retain) NSString *appId;
@property(nonatomic,retain) NSString* analyticsURL;
@property(nonatomic,assign) BOOL sendOnBackground;
@property(nonatomic,assign) NSUInteger uploadInterval;
@property(nonatomic,retain) NSMutableDictionary *userProperties;
@property(nonatomic,retain) NSArray *actions;
@property(nonatomic,retain) NSMutableArray *allActions;
@property(nonatomic,retain) NSURLConnection *connection;
@property(nonatomic,retain) NSMutableData *responseData;
@property(nonatomic,retain) id<VGAnalyticsDelegate> delegate;

-(void)sendData;
-(NSString*)filePath;
-(void)readSavedData;
-(void)saveData;
-(void)applicationWillTerminate:(NSNotification *)notification;
-(void)applicationWillEnterForeground:(NSNotificationCenter *)notification;
-(void)applicationDidEnterBackground:(NSNotificationCenter *)notification;
@end

@implementation VGAnalytics
@synthesize appId, sendOnBackground, userProperties, connection, delegate;
@synthesize analyticsURL, responseData, uploadInterval, actions, allActions;

static VGAnalytics *sharedInstance = nil;

-(NSString*)getVersion
{
    return @"0.1";
}

-(NSString*)getiOSVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

- (id)initWithAppId:(NSString *)AppId
{
    if ((self = [self init])) {
        self.appId = AppId;
        //[self start];
    }
    return  self;
}
- (id)init
{
   if ((self = [super init])) {
        actions = [[NSMutableArray alloc] init];
        userProperties = [[NSMutableDictionary alloc] init];
        sendOnBackground = YES;
        analyticsURL = @"blahblah";
        uploadInterval = kVGInterval;
        [self.userProperties setObject:@"iOS" forKey:@"platform"];
    }
    
    return self;
}

+(id)sharedTool
{
    return sharedInstance;
}

- (NSString*) filePath 
{
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"VGAnalytics.plist"];
}

-(void)sendData
{
    if ([self.allActions count] == 0 || self.connection != nil) { // No events or already pushing data.
		return;
	} else if ([self.allActions count] > 50) {
		self.actions = [self.allActions subarrayWithRange:NSMakeRange(0, 50)];
	} else {
		self.actions = [NSArray arrayWithArray:self.allActions];
	}
    
	NSLog(@"%@",[allActions valueForKey:@"dictionaryValue"]);
	NSData *data = [NSJSONSerialization dataWithJSONObject:actions options:nil error:nil];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	NSString *postBody = [NSString stringWithFormat:@"%@", data];
    
    NSLog(@"%@",postBody);
    
	//NSURL *url = [NSURL URLWithString:[self serverURL]];
	//NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	//[request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];  
	//[request setHTTPMethod:@"POST"];
	//[request setHTTPBody:[postBody dataUsingEncoding:NSUTF8StringEncoding]];
	//self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
	//[request release];
}
-(void)readSavedData
{
    self.allActions = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filePath]];
	if (!self.allActions) {
		self.allActions = [NSMutableArray array];
	}
}
-(void)saveData
{
    if (![NSKeyedArchiver archiveRootObject:[self allActions] toFile:[self filePath]]) {
		NSLog(@"Unable to archive data!!!");
	}
}

#pragma mark -
#pragma mark NSURLConnection Callbacks
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	if ([response statusCode] != 200) {
		NSLog(@"fail %@", [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]]);
	} else {
		self.responseData = [NSMutableData data];
	}
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
	[self.responseData appendData:data];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
	NSLog(@"error, clean up %@", error);
    if ([self.delegate respondsToSelector:@selector(VGAnalytics:didFailToUploadActions:withError:)]) {
        [self.delegate VGAnalytics:self didFailToUploadActions:self.actions withError:error];
    }
	self.actions = nil;
	self.responseData = nil;
	self.connection = nil;
    [self saveData];
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	if (&UIBackgroundTaskInvalid && [[UIApplication sharedApplication] respondsToSelector:@selector(endBackgroundTask:)] && taskId != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:taskId];
        taskId = UIBackgroundTaskInvalid;
	}
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    if ([self.delegate respondsToSelector:@selector(VGAnalytics:didUploadActions:)]) {
        [self.delegate VGAnalytics:self didUploadActions:self.actions];
        
    }
	//NSString *response = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
	//NSInteger result = [response intValue];
    
    [self.allActions removeObjectsInArray:self.actions];
	
    //if (result == 0) {
	//	NSLog(@"failed %@", response);
	//}
    
	[self saveData];
	self.actions = nil;
	self.responseData = nil;
	self.connection = nil;
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	if (&UIBackgroundTaskInvalid && [[UIApplication sharedApplication] respondsToSelector:@selector(endBackgroundTask:)] && taskId != UIBackgroundTaskInvalid) {
		[[UIApplication sharedApplication] endBackgroundTask:taskId];
        taskId = UIBackgroundTaskInvalid;
	}
}

-(void)applicationWillTerminate:(NSNotification *)notification
{}
-(void)applicationWillEnterForeground:(NSNotificationCenter *)notification
{}
-(void)applicationDidEnterBackground:(NSNotificationCenter *)notification
{}

@end
