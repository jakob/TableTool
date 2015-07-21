//
//  CSVWriter.h
//  Table Tool
//
//  Created by Andreas Aigner on 10.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSVConfiguration.h"

@interface CSVWriter : NSObject

@property (readonly) NSArray *dataArray;
@property NSArray *columnsOrder;
@property CSVConfiguration *config;

-(instancetype)initWithDataArray:(NSArray *) dataArray columnsOrder:(NSArray *)columnsOrder configuration:(CSVConfiguration *)config;

-(NSData *)writeDataWithError:(NSError **) outError;

@end
