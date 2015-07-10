//
//  CSVReader.h
//  Table Tool
//
//  Created by Andreas Aigner on 09.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSVReader : NSObject

@property (readonly) NSData *data;
@property NSStringEncoding encoding;
@property NSString *columnSeparator;
@property NSString *quoteCharacter;
@property NSString *escapeCharacter;

-(instancetype)initWithData:(NSData *) data;

-(NSArray *)readLineWithError:(NSError **) outError;
-(BOOL)isAtEnd;

@end
