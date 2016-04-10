//
//  MDChatCell.m
//  MDChatClient
//
//  Created by Inam Abbas on 4/10/16.
//  Copyright © 2016 Inam Abbas. All rights reserved.
//

#import "MDChatCell.h"

@implementation MDChatCell

- (CGSize)sizeThatFits:(CGSize)size;
{
    CGSize textViewSize = _textView.bounds.size;
    CGSize fitTextViewSize = CGSizeMake(textViewSize.width, size.height);
    CGSize sizeThatFitsSize = [self.textView sizeThatFits:fitTextViewSize];
    
    CGSize superSize = [super sizeThatFits:size];
    
    sizeThatFitsSize.height = MAX(superSize.height, sizeThatFitsSize.height);
    sizeThatFitsSize.width = superSize.width;
    
    return sizeThatFitsSize;
}

@end
