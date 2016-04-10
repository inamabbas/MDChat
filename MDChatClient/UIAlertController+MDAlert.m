//
//  UIAlertController+MDAlert.m
//  MDChatClient
//
//  Created by Inam Abbas on 4/10/16.
//  Copyright © 2016 Inam Abbas. All rights reserved.
//

#import "UIAlertController+MDAlert.h"

@implementation UIAlertController (MDAlert)

+ (instancetype)alertWithMessage:(NSString *)message handler:(void(^)(UIAlertAction *action))handler
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message preferredStyle:UIAlertControllerStyleAlert
                                ];
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", @"OK action")
                               style:UIAlertActionStyleDefault
                               handler:handler];
    [alert addAction:okAction];
    
    return alert;
}
@end
