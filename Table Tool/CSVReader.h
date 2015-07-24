//
//  CSVReader.h
//  Table Tool
//
//  Created by Andreas Aigner on 09.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSVConfiguration.h"

@interface CSVReader : NSObject

@property (readonly) NSData *data;
@property NSString *dataString;
@property CSVConfiguration *config;

-(instancetype)initWithData:(NSData *)data configuration:(CSVConfiguration *)config;
-(instancetype)initWithString:(NSString *)dataString configuration:(CSVConfiguration *)config;

-(NSArray *)readLineWithError:(NSError **)outError;
-(NSArray *)readLineForPastingTo:(NSArray *)columnsOrder maxColumnIndex:(long)maxColumnNumber;
-(BOOL)isAtEnd;

@end
