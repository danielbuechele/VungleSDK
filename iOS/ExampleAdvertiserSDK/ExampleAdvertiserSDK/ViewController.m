//
//  ViewController.m
//  ExampleAdvertiserSDK
//
//  Created by Harsh Jariwala on 6/25/12.
//

#import "ViewController.h"
#import "VGAnalytics.h"

@interface ViewController ()

@end

static  VGAnalytics *ana;

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ana = [[VGAnalytics alloc] initWithAppId:@"HelloWorld!"];
    
    ana.delegate = self;
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)VGAnalytics:(VGAnalytics *)tool didUploadActions:(NSArray *)Actions
{
    NSLog(@"here");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
