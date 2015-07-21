//
//  CSVConfiguration.h
//  Table Tool
//
//  Created by Andreas Aigner on 21.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSVConfiguration : NSObject <NSCopying>

@property(readonly) NSStringEncoding encoding;
@property(readonly) NSString *columnSeparator;
@property(readonly) NSString *quoteCharacter;
@property(readonly) NSString *escapeCharacter;
@property(readonly) NSString *decimalMark;

-(instancetype)init;

@end
