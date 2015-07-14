//
//  CSVWriter.h
//  Table Tool
//
//  Created by Andreas Aigner on 10.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CSVWriter : NSObject

@property (readonly) NSArray *dataArray;
@property NSArray *columnsOrder;
@property NSStringEncoding encoding;
@property NSString *columnSeparator;
@property NSString *quoteCharacter;
@property NSString *escapeCharacter;

-(instancetype)initWithDataArray:(NSArray *) dataArray;

-(NSData *)writeDataWithError:(NSError **) outError;

@end
