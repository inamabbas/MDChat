//
//  RoundedLabel.m
//  MDChatClient
//
//  Created by Inam Abbas on 4/10/16.
//  Copyright © 2016 Inam Abbas. All rights reserved.
//

#import "RoundedLabel.h"

#define PADDING 8.0
#define CORNER_RADIUS 4.0

@implementation RoundedLabel

- (void)drawRect:(CGRect)rect {
    self.layer.masksToBounds = YES;
    self.layer.cornerRadius = CORNER_RADIUS;
    UIEdgeInsets insets = {PADDING, PADDING, PADDING, PADDING};
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}

- (CGSize) intrinsicContentSize {
    CGSize intrinsicSuperViewContentSize = [super intrinsicContentSize] ;
    intrinsicSuperViewContentSize.width += PADDING * 2 ;
    intrinsicSuperViewContentSize.height += PADDING * 2 ;
    return intrinsicSuperViewContentSize ;
}

@end
