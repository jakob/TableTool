//
//  CSVHeuristic.h
//  Table Tool
//
//  Created by Andreas Aigner on 04.08.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSVConfiguration.h"
#import "CSVReader.h"

@interface CSVHeuristic : NSObject

@property CSVConfiguration *config1;
@property CSVConfiguration *config2;
@property CSVConfiguration *config3;
@property CSVConfiguration *config4;
@property CSVConfiguration *config5;
@property CSVConfiguration *config6;
@property CSVConfiguration *config7;
@property CSVConfiguration *config8;
@property CSVConfiguration *config9;
@property CSVConfiguration *config10;
@property CSVConfiguration *config11;
@property NSData *data;
@property BOOL preferChineseEncoding;

-(instancetype)initWithData:(NSData *)data;
-(CSVReader *)calculatePossibleFormat;
-(void)setEncoding:(NSStringEncoding)encoding;

@end
