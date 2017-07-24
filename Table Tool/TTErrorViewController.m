//
//  TTErrorViewController.m
//  Table Tool
//
//  Created by Andreas Aigner on 30.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "TTErrorViewController.h"

@interface TTErrorViewController ()

@end
@implementation TTErrorViewController

-(instancetype)initWithMessage:(NSString *)errorMessage information:(NSString *)errorInformation{
    
    self = [super initWithNibName:@"TTErrorViewController" bundle:nil];
    if(self) {
        [self view];
        _information.stringValue = errorInformation ?: @"";
        _message.stringValue = errorMessage ?: @"";
        [_message setFont:[NSFont boldSystemFontOfSize:13]];
    }
    return self;
}

@end
