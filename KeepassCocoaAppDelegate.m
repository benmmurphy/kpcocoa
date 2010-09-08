//
//  KeepassCocoaAppDelegate.m
//  KeepassCocoa
//
//  Created by Ben Murphy on 06/09/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "KeepassCocoaAppDelegate.h"


@implementation KeepassCocoaAppDelegate

@synthesize window;

@synthesize openWindow;
@synthesize editWindow;
@synthesize entries;
@synthesize groups;
@synthesize password;
@synthesize repeat;
@synthesize title;
@synthesize username;
@synthesize url;
@synthesize masterPassword;
@synthesize notes;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if (item == nil) {
		if (tree == nil) {
			return 0;
		} else {
			return [[[tree getRoot] getSubGroups] count];
		}
	} else {
		id<KdbGroup> group = item;
		return [[group getSubGroups] count];
	}
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	if (item == nil) {
		return TRUE;
	}
	
	id<KdbGroup> group = item;
	return [[group getSubGroups] count] > 0;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	if (item == nil) {
		return [[[tree getRoot] getSubGroups] objectAtIndex: index];
	} else {
		id<KdbGroup> group = item;
		return [[group getSubGroups] objectAtIndex: index];
	}
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if (item == nil) {
		return nil;
	} else {
		id<KdbGroup> group = item;
		return [group getGroupName];
	}
}

- (void)open: (id) sender {
	NSOpenPanel* panel = [NSOpenPanel openPanel];
	if (NSOKButton == [panel runModalForDirectory: nil file: nil types:nil]) {
		fileToOpen = [[panel filenames] lastObject];
		[NSApp runModalForWindow: openWindow];
	}
}

- (void)bindValue: (id<KdbEntry>)entry sel: (SEL)sel field: (NSTextField*)field {
	NSString* str = [entry performSelector: sel];
	
	field.stringValue = str;
}

- (void)dumpCustomAttributes: (id<KdbEntry>)entry {
	
	uint number = [entry getNumberOfCustomAttributes];
	for (uint i = 0; i < number; ++i) {
		NSLog(@"Attribute: %s = %s", [entry getCustomAttributeName:i], [entry getCustomAttributeValue: i]);
	}
}

- (void)addEntries: (id<KdbGroup>)group text: (NSString*) textParam target: (NSMutableArray*)t {
	
    for (id<KdbEntry> entry in [group getEntries]) {
		if ([[entry getEntryName] rangeOfString: textParam].location != NSNotFound)	{
			[t addObject: entry];
		}
	}
	
	for (id<KdbGroup> subGroup in [group getSubGroups]) {
		[self addEntries: subGroup text: textParam target: t];
	}
}

- (void)search: (id) sender {
	NSSearchField* searchField = sender;
	NSString* str = [searchField stringValue];
	if ([str length] == 0) {
		[searchResults release];
		searchResults = nil;
		[entries reloadData];
		return;
	}
	
	id<KdbGroup> group = selectedGroup;
	
	if (group == nil) {
		group = [tree getRoot];
	}
	
	NSMutableArray* target = [NSMutableArray new];
	
	[self addEntries: group text: str target: target];
	
	[target sortUsingSelector:@selector(getEntryName)];
	searchResults = target;
	[entries reloadData];
}

- (void)edit: (id) sender {
	int row = [entries selectedRow];
	NSArray* allEntries = [selectedGroup getEntries];
	if (row < 0 || row >= [allEntries count]) {
		return;
	}
	
	id<KdbEntry> entry = [allEntries objectAtIndex: row];
	
	[self bindValue: entry sel: @selector(getEntryName) field: title];
	[self bindValue: entry sel: @selector(getUserName) field: username];
	[self bindValue: entry sel: @selector(getURL) field: url];
	[self bindValue: entry sel: @selector(getPassword) field: password];
	[self bindValue: entry sel: @selector(getPassword) field: repeat];
	
	[notes setString: [entry getComments]];
	[self dumpCustomAttributes: entry];
	[NSApp runModalForWindow: editWindow];
}




- (void)copyEntry: (SEL) field {
	int row = [entries selectedRow];
	NSArray* allEntries = [selectedGroup getEntries];
	if (row < 0 || row >= [allEntries count]) {
		return;
	}
	
	id<KdbEntry> entry = [allEntries objectAtIndex: row];
	NSPasteboard* pasteBoard = [NSPasteboard generalPasteboard];
	[pasteBoard declareTypes: [NSArray arrayWithObject: NSStringPboardType] owner: nil];
	[pasteBoard setString: [entry performSelector: field] forType: NSStringPboardType];
	
}
- (void)copyPassword: (id) sender {
	[self copyEntry: @selector(getPassword)];
}

- (void)copyUsername: (id) sender {
	[self copyEntry: @selector(getUserName)];
}

- (void)cancel: (id) sender {
	[editWindow close];
	[NSApp stopModal];
}

- (void) delloc {
	[tree release];
	[super dealloc];
}

- (void)openDatabase: (id) sender {
	WrapperNSData* data = [[WrapperNSData alloc]initWithContentsOfMappedFile: fileToOpen];
	id<KdbReader> reader = [KdbReaderFactory newKdbReader: data];
	@try {
		tree = [reader load: data withPassword: [masterPassword stringValue]];
		[openWindow close];
		[NSApp stopModal];
		[groups reloadData];
	}
	@catch (NSException * e) {
		NSAlert* alert = [NSAlert new];

		[alert setMessageText: @"Invalid Password"];
		[alert addButtonWithTitle: @"OK"];
		[alert setAlertStyle: NSWarningAlertStyle];
		[alert beginSheetModalForWindow:openWindow modalDelegate:nil didEndSelector:nil contextInfo:(void *)NULL];
		[alert release];
	} @finally {

	}
}

- (void)cancelOpenDatabase: (id) sender {
	[openWindow close];
	[NSApp stopModal];
}



- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	if (searchResults != nil) {
		return [searchResults count];
	} else if (selectedGroup == nil) {
		return 0;
	} else {
		return [[selectedGroup getEntries] count];
	}
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	id<KdbEntry> entry;
	if (searchResults != nil) {
		entry = [searchResults objectAtIndex: rowIndex];
	} else if (selectedGroup == nil) {
		return nil;
	} else {
		entry = [[selectedGroup getEntries] objectAtIndex: rowIndex];
	}
	

	if ([[aTableColumn identifier] isEqual: @"title"]) {
		return [entry getEntryName];
	} else if ([[aTableColumn identifier] isEqual: @"username"]) {
		return [entry getUserName];
	} else {
		return nil;
	}
}

- (void)outlineViewSelectionDidChange: (NSNotification*) notification {
	int row = [groups selectedRow];
	if (row >= 0) {
		selectedGroup = [groups itemAtRow: row];

	} else {
		selectedGroup = nil;

	}
	[entries reloadData];
}
@end
