//
//  CSVConfiguration.h
//  Table Tool
//
//  Created by Andreas Aigner on 21.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSVConfiguration : NSObject <NSCopying>

@property NSStringEncoding encoding;
@property NSString *columnSeparator;
@property NSString *quoteCharacter;
@property NSString *escapeCharacter;
@property NSString *decimalMark;
@property BOOL firstRowAsHeader;

@end
