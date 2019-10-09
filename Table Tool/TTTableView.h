//
//  TTTableView.h
//  Table Tool
//
//  Created by Rob Warner on 10/7/19.
//  Copyright © 2019 Egger Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTTableView : NSTableView<NSTableViewDelegate>

-(void)resetAnchor;

@end

NS_ASSUME_NONNULL_END
