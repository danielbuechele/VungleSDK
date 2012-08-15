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
    
    ana = [[VGAnalytics alloc] initWithAppId:@"vungleTest" andSecretKey:@"replace with secret key"];
    [ana setUsername:@"set username of the user (if available)"];
    
    ana.delegate = self;
    [self.view setBackgroundColor:[UIColor grayColor]];
        
    UIButton *butt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [butt setFrame:CGRectMake(100, 100, 100, 50)];
    [butt setTitle:@"Add Action" forState:UIControlStateNormal];
    [butt addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:butt];
    
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)buttonPressed
{
    NSLog(@"PRESSED");
    [ana trackAction:@"Button Pressed"];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)VGAnalytics:(VGAnalytics *)tool didUploadActions:(NSArray *)Actions
{
    NSLog(@"HERE");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
