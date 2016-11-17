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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationResponse:) name:@"lyznotification" object:nil];
    }
    return self;
}

- (void)notificationResponse:(NSNotification*)notification
{
//    NSString* test = @"ddf3r";
//    [test performSelector:@selector(objectForKey:)];
    NSLog(@"TestObject  notificationResponse Time:%f \n",[[NSDate date] timeIntervalSince1970]);
}

- (void)dealloc
{
    NSLog(@"TestObject  deallocTime:%f",[[NSDate date] timeIntervalSince1970]);
    //[[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
