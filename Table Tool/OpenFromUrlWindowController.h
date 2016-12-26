//
//  OpenFromUrlWindowController.h
//  Table Tool
//
//  Created by GuZhangYiDong on 2016/12/19.
//  Copyright © 2016年 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Document.h"

@interface OpenFromUrlWindowController : NSWindowController

@property (strong) IBOutlet NSTextFieldCell *urlInputTextField;

@property (nonatomic,strong) Document *doc;

@end
