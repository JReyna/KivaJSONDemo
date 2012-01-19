//
//  ViewController.m
//  KivaJSONDemo
//
//  Created by James Reyna on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define kBgQueue dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1
#define kLatestKivaLoansURL [NSURL URLWithString: @"http://api.kivaws.org/v1/loans/search.json?status=fundraising"] //2
#import "ViewController.h"

@interface NSDictionary(JSONCategories) 

+(NSDictionary*)dictionaryWithContentsOfJSONURLString:(NSString*)urlAddress;
-(NSData*)toJSON;
@end

@implementation NSDictionary(JSONCategories) 
+(NSDictionary*)dictionaryWithContentsOfJSONURLString:(NSString*)urlAddress
{
    NSData* data = [NSData dataWithContentsOfURL:
                    [NSURL URLWithString: urlAddress] ];
    __autoreleasing NSError* error = nil;
    id result = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error != nil)
        return nil; 
    return result;
}
-(NSData*)toJSON
{
    NSError* error = nil;
    id result = [NSJSONSerialization dataWithJSONObject:self options:kNilOptions error:&error]; 
    if (error != nil) 
        return nil; 
    return result;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    dispatch_async(kBgQueue, ^{
        NSData* data = [NSData dataWithContentsOfURL:kLatestKivaLoansURL];
        [self performSelectorOnMainThread:@selector(fetchedData:)withObject:data waitUntilDone:YES]; 
    });
}

- (void)fetchedData:(NSData *)responseData { //parse out the json data
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData //1
                          options:kNilOptions error:&error];
    NSArray* latestLoans = [json objectForKey:@"loans"]; //2
    NSLog(@"loans: %@", latestLoans); //3
    
    // 1) Get the latest loan
    NSDictionary* loan = [latestLoans objectAtIndex:0];
    // 2) Get the funded amount and loan amount
    NSNumber* fundedAmount = [loan objectForKey:@"funded_amount"]; 
    NSNumber* loanAmount = [loan objectForKey:@"loan_amount"];
    float outstandingAmount = [loanAmount floatValue] - [fundedAmount floatValue];
    // 3) Set the label appropriately
    humanReadble.text = [NSString stringWithFormat:@"Latest loan: %@ from %@ needs another $%.2f to pursue their entrepreneural dream", 
                         [loan objectForKey:@"name"], 
                         [(NSDictionary*)[loan objectForKey:@"location"] objectForKey:@"country"],
                         outstandingAmount];
    NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys: [loan objectForKey:@"name"],
                          @"who",
                          [(NSDictionary*)[loan objectForKey:@"location"]
                           objectForKey:@"country"],
                          @"where",
                          [NSNumber numberWithFloat: outstandingAmount],
                          @"what", nil];
    
    //convert object to data
    NSData* jsonData = [NSJSONSerialization dataWithJSONObject:info options:NSJSONWritingPrettyPrinted error:&error];
    
    //print out the data contents
    jsonSummary.text = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}
    
@end
