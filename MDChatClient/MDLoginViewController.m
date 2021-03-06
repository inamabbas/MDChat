//
//  MDLoginViewController.m
//  MDChatClient
//
//  Created by Inam Abbas on 4/10/16.
//  Copyright © 2016 Inam Abbas. All rights reserved.
//

#import "MDLoginViewController.h"
#import "MDConstants.h"
#import "UIAlertController+MDAlert.h"

@interface MDLoginViewController () <UITableViewDelegate>

@property (nonatomic) IBOutlet UITextField *usernameTextField;

- (void)enterChat;

@end

@implementation MDLoginViewController

- (BOOL)isValidUsername:(NSString *)username {
    NSCharacterSet * characterSetFromTextField = [NSCharacterSet
                                                  characterSetWithCharactersInString:username];
    if([[NSCharacterSet alphanumericCharacterSet] isSupersetOfSet: characterSetFromTextField] == NO || username.length == 0)
        return NO;
    
    return YES;
    
}
- (void)enterChat;
{
    NSString *username = self.usernameTextField.text;
    if (![self isValidUsername:username]) {
        
        [self presentViewController:[UIAlertController alertWithMessage:NSLocalizedString(@"Please enter valid username", @"") handler:nil] animated:YES completion:nil];
        return;
    }
    
    //Save username
    [[NSUserDefaults standardUserDefaults] setValue:username forKey:kMDChatUsernameKey];
    
    //Go to chatview
    [self performSegueWithIdentifier:@"showChat" sender:nil];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1)
        [self enterChat];
}

@end
