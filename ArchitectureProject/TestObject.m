//
//  TestObject.m
//  ArchitectureProject
//
//  Created by 李义真 on 2016/11/9.
//  Copyright © 2016年 李义真. All rights reserved.
//

#import <objc/runtime.h>
#import "TestObject.h"

@implementation TestObject
- (instancetype)init
{
    if(self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lyz_notificationResponse:) name:@"lyznotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(xyz_notificationResponse) name:@"xyznotification" object:nil];
    }
    return self;
}

- (void)lyz_notificationResponse:(NSNotification*)notification
{
    NSLog(@"TestObject  lyz_notificationResponse Time:%f isMainThread:%d \n",[[NSDate date] timeIntervalSince1970],[NSThread isMainThread]);
}

- (void)xyz_notificationResponse
{
    
//    NSString* testString = @"lyzliii";
//    
//    NSDictionary* dic = (NSDictionary*)testString;
//    
//    [dic objectForKey:@"hf"];
	NSLog(@"TestObject  xyz_notificationResponse Time:%f isMainThread:%d \n",[[NSDate date] timeIntervalSince1970],[NSThread isMainThread]);
}

- (void)dealloc
{
    NSLog(@"TestObject  deallocTime:%f",[[NSDate date] timeIntervalSince1970]);
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
