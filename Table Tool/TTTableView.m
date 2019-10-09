//
//  TTTableView.m
//  Table Tool
//
//  Created by Rob Warner on 10/7/19.
//  Copyright © 2019 Egger Apps. All rights reserved.
//

#import <math.h>
#import "TTTableView.h"

const int NONE_SELECTED = -1;

@implementation TTTableView

NSInteger anchor = NONE_SELECTED;

- (void)keyDown:(NSEvent *)event {
    unichar character = [[event characters] characterAtIndex:0];
    if (character == NSLeftArrowFunctionKey || character == NSRightArrowFunctionKey) {
        BOOL handled = (event.modifierFlags & NSShiftKeyMask) ?
        [self selectMultipleColumns: character] :
            [self selectSingleColumn: character];
        if (handled) {
            return;
        }
    }
    [super keyDown:event];
}

- (BOOL)selectMultipleColumns:(unichar)character {
    NSInteger selected = self.selectedColumn;
    if (anchor == NONE_SELECTED) {
        anchor = selected;
    }

    NSInteger newColumn = character == NSLeftArrowFunctionKey ? selected - 1 : selected + 1;
    if (newColumn >= 0 && newColumn < self.numberOfColumns) {
        if ((character == NSLeftArrowFunctionKey && newColumn >= anchor) || (character == NSRightArrowFunctionKey && newColumn <= anchor)) {
            [self deselectColumn:selected];
        }
        
        [self selectColumnIndexes:[NSIndexSet indexSetWithIndex:newColumn] byExtendingSelection:YES];

        return YES;
    }
    
    return NO;
}

- (BOOL)selectSingleColumn:(unichar)character {
    [self resetAnchor];
    
    NSInteger newColumn = character == NSLeftArrowFunctionKey ? self.selectedColumn - 1 : self.selectedColumn + 1;
    if (newColumn >= 0 && newColumn < self.numberOfColumns) {
        [self selectColumnIndexes:[NSIndexSet indexSetWithIndex:newColumn] byExtendingSelection:NO];
        return YES;
    }
    
    return NO;
}

- (void)resetAnchor {
    anchor = NONE_SELECTED;
}

@end
