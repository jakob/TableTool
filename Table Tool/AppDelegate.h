//
//  AppDelegate.h
//  Table Tool
//
//  Created by Andreas Aigner on 06.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "OpenFromUrlWindowController.h"
#import "Document.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic,strong) OpenFromUrlWindowController *windowContoller;

- (IBAction)openFromUrl:(NSMenuItem *)sender;

@end

