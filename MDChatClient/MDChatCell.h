//
//  MDChatCell.h
//  MDChatClient
//
//  Created by Inam Abbas on 4/10/16.
//  Copyright © 2016 Inam Abbas. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RoundedLabel;

@interface MDChatCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet RoundedLabel *messageLabel;


@end
