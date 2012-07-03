//
//  ViewController.m
//  ExampleAdvertiserSDK
//
//  Created by Harsh Jariwala on 6/25/12.
//  Copyright (c) 2012 Carnegie Mellon University. All rights reserved.
//

#import "ViewController.h"
#import "VGAnalytics.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    VGAnalytics *ana = [[VGAnalytics alloc] initWithAppId:@"HelloWorld!"];
    
    NSLog(@"reachability: %@ ", [ana findReachability]);
    [ana sendData];
//    NSMutableArray *dict = [[NSMutableArray alloc] init];
//    NSDictionary *x;
//    NSData *data = nil;
//    for(int i = 0;i<20;i++)
//    {
//        x = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:i], @"color", nil];
//        [dict addObject:x];
//        
//    }
//    
//    NSLog(@"%@",dict);
//    
//    data = [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
//    NSString *postBody = [NSString stringWithFormat:@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
//    
//    NSLog(@"POST BODAYYYYEEEE %@",postBody);
//    NSLog(@"%@",dict);
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
