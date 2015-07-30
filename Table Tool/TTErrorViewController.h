//
//  TTErrorViewController.h
//  Table Tool
//
//  Created by Andreas Aigner on 30.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface TTErrorViewController : NSViewController

@property IBOutlet NSTextField *information;
@property IBOutlet NSTextField *message;

-(instancetype)initWithMessage:(NSString *)errorMessage information:(NSString *)errorInformation;


@end
