//
//  MDChatViewController.m
//  MDChatClient
//
//  Created by Inam Abbas on 4/10/16.
//  Copyright © 2016 Inam Abbas. All rights reserved.
//

#import "MDChatViewController.h"
#import "MDConstants.h"
#import "MDChatCell.h"
#import "RDRGrowingTextView.h"
#import "RoundedLabel.h"
#import "UIAlertController+MDAlert.h"
#import <SocketRocket/SocketRocket.h>

@interface MDChatMessage : NSObject

/**
 Initializes the message with provided data.
 @param message, The message data received
 @param name, the name of the sender
 @return The newly-initialized message object
 */
- (id)initWithMessage:(NSString *)message name:(NSString *)name;

/*
 Chat message
 */
@property (nonatomic, readonly) NSString *message;

/*
 Name of the sender
 */
@property (nonatomic, readonly) NSString *name;

/*
 Determine if message sent by currently logged in user
 */
@property (nonatomic, readonly)  BOOL fromMe;

@end

@implementation MDChatMessage

- (id)initWithMessage:(NSString *)message name:(NSString *)name
{
    self = [super init];
    if (self) {
        _name = name;
        _message = message;
        if ([[[NSUserDefaults standardUserDefaults] valueForKey:kMDChatUsernameKey] isEqualToString:name])
            _fromMe = YES;
    }
    
    return self;
}

@end

static CGFloat const MaxToolbarHeight = 200.0f; //Toolbar contains the chat input view

@interface MDChatViewController () <SRWebSocketDelegate, UITextViewDelegate, UITableViewDelegate>

@property (nonatomic) IBOutlet UIBarButtonItem *connectBtn;

- (IBAction)connectChat:(id)sender;
- (IBAction)logout:(id)sender;

@end

@implementation MDChatViewController {
    SRWebSocket *_webSocket;
    NSMutableArray *_messages;
    UIToolbar *_toolbar;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _messages = [[NSMutableArray alloc] init];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 78;
    
    [self connect];
}

- (void)dealloc {
    _webSocket.delegate = nil;
    [_webSocket close];
}

- (IBAction)connectChat:(id)sender
{
    if ([self connected]) {
        [self disconnect];
        return;
    }
    
    [self connect];
}

- (IBAction)logout:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (BOOL)connected
{
    return _webSocket.readyState == SR_OPEN;
}

- (void)connect
{
    NSString *username = [[self username] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *queryString = [NSString stringWithFormat:@"?username=%@", username];
    
    _webSocket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", kMDWebSocketUrl, queryString]]]];
    _webSocket.delegate = (id)self;
    
    [_webSocket open];
}

- (void)disconnect
{
    _webSocket.delegate = nil;
    [_webSocket close];
    [self.connectBtn setTitle:NSLocalizedString(@"Connect", @"Connect")];
    [self showMessage:NSLocalizedString(@"Disconnected! Please connect again", @"")];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    [self.connectBtn setTitle:NSLocalizedString(@"Disconnect", @"Disconnect")];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    _webSocket = nil;
    [self.connectBtn setTitle:NSLocalizedString(@"Connect", @"Connect")];
    [self showMessage:NSLocalizedString(@"Failed to connect. Please try again", @"")];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    NSError *jsonError;
    NSData *objectData = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    [_messages addObject:[[MDChatMessage alloc] initWithMessage:json[@"message"] name:json[@"sender"]]];
     [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_messages.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    _webSocket = nil;
    [self.connectBtn setTitle:NSLocalizedString(@"Connect", @"Connect")];
    [self showMessage:NSLocalizedString(@"Disconnected! Please connect again", @"")];
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return _messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    MDChatMessage *message = [_messages objectAtIndex:indexPath.row];
    
    MDChatCell *cell = [self.tableView dequeueReusableCellWithIdentifier:message.fromMe ? @"SentCell" : @"ReceivedCell"];
    cell.messageLabel.text = message.message;
    cell.nameLabel.text = message.name;
    
    return cell;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
    if ([text rangeOfString:@"\n"].location != NSNotFound) {
        
        NSString *message = [[textView.text stringByReplacingCharactersInRange:range withString:text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (![self connected]) {
            [self showMessage:NSLocalizedString(@"Disconnected! Please connect again", @"")];
            return NO;
        }
        
        if ([self isEmptyString:message]) {
            [self showMessage:NSLocalizedString(@"Please enter your message", @"")];
            return NO;
        }
            
        NSError *error = nil;
        if (![self sendMessage:message error:&error])
            return YES;
        
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_messages.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_messages.count-1 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:YES];
        

        
        textView.text = @"";
        return NO;
    }
    return YES;
}

- (BOOL)sendMessage:(NSString *)message error:(NSError **)error
{
    NSString *username = [self username];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"sender": username, @"message": message}
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&*error];
    if (!jsonData)
        return NO;
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    [_webSocket send:jsonString];
    [_messages addObject:[[MDChatMessage alloc] initWithMessage:message name:username]];
    
    return YES;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (UIView *)inputAccessoryView
{
    if (_toolbar) {
        return _toolbar;
    }
    
    _toolbar = [UIToolbar new];
    
    RDRGrowingTextView *textView = [RDRGrowingTextView new];
    textView.delegate = (id)self;
    textView.font = [UIFont systemFontOfSize:17.0f];
    textView.textContainerInset = UIEdgeInsetsMake(4.0f, 3.0f, 3.0f, 3.0f);
    textView.layer.cornerRadius = 4.0f;
    textView.layer.borderColor = [UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:205.0f/255.0f alpha:1.0f].CGColor;
    textView.layer.borderWidth = 1.0f;
    textView.layer.masksToBounds = YES;
    [_toolbar addSubview:textView];
    
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    _toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    
    [_toolbar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[textView]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(textView)]];
    [_toolbar addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[textView]-8-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(textView)]];
    
    [textView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [textView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [_toolbar setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    
    [_toolbar addConstraint:[NSLayoutConstraint constraintWithItem:_toolbar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:MaxToolbarHeight]];
    
    return _toolbar;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
    return YES;
}

- (NSString *)username
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kMDChatUsernameKey];
}

- (BOOL)isEmptyString:(NSString *)string
{
    NSString *copiedStr = [string copy];
    copiedStr = [copiedStr stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    copiedStr = [copiedStr stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    return copiedStr.length == 0;
}

- (void)showMessage:(NSString *)message
{
    [self presentViewController:[UIAlertController alertWithMessage:message
                                                            handler:^(UIAlertAction *action) {
                                                                [self becomeFirstResponder];
                                                            }] animated:YES completion:nil];
}

@end
