//
//  UIAlertController+MDAlert.h
//  MDChatClient
//
//  Created by Inam Abbas on 4/10/16.
//  Copyright © 2016 Inam Abbas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertController (MDAlert)

+ (instancetype)alertWithMessage:(NSString *)message handler:(void(^)(UIAlertAction *action))handler;

@end
