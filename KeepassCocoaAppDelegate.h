//
//  KeepassCocoaAppDelegate.h
//  KeepassCocoa
//
//  Created by Ben Murphy on 06/09/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <KdbLib.h>
@interface KeepassCocoaAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	NSWindow *openWindow;
	NSWindow *editWindow;
	NSTableView *entries;
	NSOutlineView *groups;
	NSTextField *password;
	NSTextField *repeat;
	NSTextField *title;
	NSTextField *username;
	NSTextField *url;
	NSTextField *masterPassword;
	NSTextView *notes;
	id<KdbTree> tree;
	NSString* fileToOpen;
	id<KdbGroup> selectedGroup;
	NSArray* searchResults;
	
}

@property (assign) IBOutlet NSTextView *notes;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *editWindow;
@property (assign) IBOutlet NSWindow *openWindow;
@property (assign) IBOutlet NSTableView *entries;
@property (assign) IBOutlet NSOutlineView *groups;
@property (assign) IBOutlet NSTextField *password;
@property (assign) IBOutlet NSTextField *repeat;
@property (assign) IBOutlet NSTextField *title;
@property (assign) IBOutlet NSTextField *username;
@property (assign) IBOutlet NSTextField *url;
@property (assign) IBOutlet NSTextField *masterPassword;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
@end
