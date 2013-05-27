//
//  ViewController.m
//  TapsAff
//
//  Created by Sombrero on 27/05/2013.
//  Copyright (c) 2013 Ratus Apparatus. All rights reserved.
//

#import "ViewController.h"
#define TAPS_TEMP 63

@interface ViewController ()
@property IBOutlet UITextView *affText;
@property IBOutlet UITextView *itsCloseText;
@property NSOperationQueue *downloadQueue;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self update];
}

- (void)update
{

    if(!self.downloadQueue)
        self.downloadQueue = [NSOperationQueue new];
    //if there are no downloads in progress
    if(!self.downloadQueue.operationCount)
    {
        //download the json on the background thread
        [self.downloadQueue addOperationWithBlock:
        ^{
            NSData *jsonData = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://www.taps-aff.co.uk/taps.json"]];
            NSError *error = nil;
            __block NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&error];
            //setup ui on main thread
            NSBlockOperation *uiOperation = [NSBlockOperation blockOperationWithBlock:
            ^{
                NSString *taps = [json objectForKey:@"taps"];
                NSNumber *tempF = [json objectForKey:@"temp_f"];
                
                self.affText.text = taps;
                if([taps isEqualToString:@"aff"])
                    self.affText.textColor = [UIColor redColor];
                else
                    self.affText.textColor = [UIColor blueColor];
                
                self.itsCloseText.hidden = ([tempF unsignedIntValue] >= TAPS_TEMP && [tempF unsignedIntValue] <= TAPS_TEMP - 5);
            }];
            [[NSOperationQueue mainQueue] addOperation:uiOperation];
            [uiOperation waitUntilFinished];
            [self scheduleNextUpdate:json];
        }];
    }
    else
        [self scheduleNextUpdate:nil];
}


-(void)scheduleNextUpdate:(NSDictionary *)json
{
    float sinceNow = 0;
    NSTimer *timer = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(update) userInfo:nil repeats:false];
    if(json)
    {
        NSString *dateString = [json objectForKey:@"datetime"];
        NSString *lifeSpan = [json objectForKey:@"lifespan"];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy'-'MM'-'dd HH':'mm':'ss";
        NSDate *date = [dateFormatter dateFromString:dateString];
        
        //fixed lifespan for now
        NSDate *nextDate = [NSDate dateWithTimeInterval:15*60 sinceDate:date];
        sinceNow = [nextDate timeIntervalSinceDate:[NSDate date]];
        if(sinceNow > 0)
            timer = [NSTimer timerWithTimeInterval:sinceNow target:self selector:@selector(update) userInfo:nil repeats:false];
    }
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

@end
