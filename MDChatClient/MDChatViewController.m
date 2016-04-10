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


@interface MDChatViewController () <SRWebSocketDelegate, UITextViewDelegate, UITableViewDelegate>

@property (nonatomic) IBOutlet UIBarButtonItem *connectBtn;

- (IBAction)connectChat:(id)sender;
- (IBAction)logout:(id)sender;

@end

@implementation MDChatViewController {
    SRWebSocket *_webSocket;
    NSMutableArray *_messages;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _messages = [[NSMutableArray alloc] init];
}

- (void)dealloc {
    [self disconnect];
}

- (IBAction)connectChat:(id)sender
{
    [self connect];
}

- (IBAction)logout:(id)sender
{
    [self disconnect];
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
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
    [self.connectBtn setTitle:NSLocalizedString(@"Disconnect", @"Disconnect")];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
    _webSocket = nil;
    [self.connectBtn setTitle:NSLocalizedString(@"Connect", @"Connect")];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    NSLog(@"Received \"%@\"", message);
    /*[_messages addObject:[[TCMessage alloc] initWithMessage:message fromMe:NO]];
     [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_messages.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
     [self.tableView scrollRectToVisible:self.tableView.tableFooterView.frame animated:YES];*/
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
    self.title = @"Connection Closed! (see logs)";
    _webSocket = nil;
    [self.connectBtn setTitle:NSLocalizedString(@"Connect", @"Connect")];
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload;
{
    NSLog(@"Websocket received pong");
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
    cell.textView.text = message.message;
    cell.nameLabel.text = message.name;
    
    return cell;
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
{
    if ([text rangeOfString:@"\n"].location != NSNotFound) {
        NSString *message = [[textView.text stringByReplacingCharactersInRange:range withString:text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        NSError *error = nil;
        if (![self sendMessage:message error:&error])
            return YES;
        
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:_messages.count - 1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView scrollRectToVisible:self.tableView.tableFooterView.frame animated:YES];
        
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
    return YES;
}

- (NSString *)username
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:kMDChatUsernameKey];
}

@end
