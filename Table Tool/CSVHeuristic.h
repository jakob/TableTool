//
//  CSVHeuristic.h
//  Table Tool
//
//  Created by Andreas Aigner on 04.08.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSVConfiguration.h"

@interface CSVHeuristic : NSObject

@property CSVConfiguration *config1;
@property CSVConfiguration *config2;
@property CSVConfiguration *config3;
@property CSVConfiguration *config4;
@property CSVConfiguration *config5;
@property NSData *data;

-(instancetype)initWithData:(NSData *)data;
-(CSVConfiguration *)calculatePossibleFormat;
@end
