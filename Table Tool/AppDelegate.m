//
//  AppDelegate.m
//  Table Tool
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize windowContoller;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Insert code here to initialize your application
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}

- (IBAction)openFromUrl:(NSMenuItem *)sender {
  self.windowContoller = [[OpenFromUrlWindowController alloc] initWithWindowNibName:@"OpenFromUrlWindowController"];
  [[NSDocumentController sharedDocumentController] newDocument:self];
  self.windowContoller.doc = [[[[NSApplication sharedApplication] mainWindow] windowController] document];
  [self.windowContoller showWindow:self];
}
@end
