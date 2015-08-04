//
//  CSVHeuristic.m
//  Table Tool
//
//  Created by Andreas Aigner on 04.08.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "CSVHeuristic.h"
#import "CSVReader.h"

@implementation CSVHeuristic {
    NSMutableArray *scores;
    NSArray *readerArray;
    NSMutableArray *readLines;
}

-(instancetype)initWithData:(NSData *)data {
    self = [super init];
    if(self){
        _data = data;
        [self setConfigs];
    }
    return self;
}

-(void)setConfigs{
    _config1 = [[CSVConfiguration alloc]init];
    _config1.columnSeparator = @",";
    _config1.decimalMark = @".";
    
    _config2 = [[CSVConfiguration alloc]init];
    _config2.columnSeparator = @";";
    _config2.decimalMark = @",";
    
    _config3 = [[CSVConfiguration alloc]init];
    _config3.columnSeparator = @"\t";
    _config3.decimalMark = @".";
    
    _config4 = [[CSVConfiguration alloc]init];
    _config4.columnSeparator = @"\t";
    _config4.decimalMark = @",";
    
    _config5 = [[CSVConfiguration alloc]init];
    _config5.columnSeparator = @";";
    _config5.decimalMark = @",";
    _config5.escapeCharacter = @"\\";
}

-(void)initializeArrays{
    CSVReader *reader1 = [[CSVReader alloc]initWithData:_data configuration:_config1];
    CSVReader *reader2 = [[CSVReader alloc]initWithData:_data configuration:_config2];
    CSVReader *reader3 = [[CSVReader alloc]initWithData:_data configuration:_config3];
    CSVReader *reader4 = [[CSVReader alloc]initWithData:_data configuration:_config4];
    CSVReader *reader5 = [[CSVReader alloc]initWithData:_data configuration:_config5];
    readerArray = [[NSArray alloc]initWithObjects:reader1,reader2,reader3,reader4,reader5,nil];
    scores = [[NSMutableArray alloc]initWithObjects:[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],nil];
}

-(CSVConfiguration *)calculatePossibleFormat{
    [self initializeArrays];
    if(![self useSimpleHeuristic]){
        for(CSVReader *reader in readerArray){
            [reader reset];
            reader.config.encoding = NSWindowsCP1252StringEncoding;
        }
        [self useSimpleHeuristic];
    }
    
    return [self getBestConfiguration];
}

-(BOOL)useSimpleHeuristic{
    for(int i = 0; i < 5; i++){
        CSVReader *reader = readerArray[i];
        readLines = [[NSMutableArray alloc]initWithCapacity:5];
        NSError *error = nil;
        for(int i = 0; i < 5; i++){
            NSArray *line = [reader readLineWithError:&error];
            if(error) break;
            [readLines addObject:line];
        }
        
        if(error) {
            if(error.code == 1){
                return NO;
            }
            continue;
        }
        scores[i] = [NSNumber numberWithInt:([scores[i] intValue] + 1)];
        [self checkForRowLengthsFromReader:i];
        [self checkForNumbersFromReader:i];
    }
    return YES;
}

-(void)checkForRowLengthsFromReader:(int)index{
    if(readLines.count == 0) return;
    long count = ((NSArray *)readLines[0]).count;
    BOOL sameLength = YES;
    for(int i = 1; i < readLines.count; i++){
        sameLength |= (((NSArray *)readLines[i]).count == count);
    }
    if(sameLength){
        scores[index] = [NSNumber numberWithInt:([scores[index] intValue] + 5)];
    }
}

-(void)checkForNumbersFromReader:(int)index{
    int numbers = 0;
    for(int i = 0; i < readLines.count; i++){
        NSMutableArray * line = readLines[i];
        for(int j = 0; j < line.count; j++){
            if([line[j] isKindOfClass:[NSDecimalNumber class]]){
                numbers++;
            }
        }
    }
    scores[index] = [NSNumber numberWithInt:([scores[index] intValue] + numbers)];
}

-(CSVConfiguration *)getBestConfiguration{
    NSNumber *highestScore = scores[0];
    int highestScoreIndex = 0;
    for(int i = 1; i < 5; i++){
        NSNumber *score = scores[i];
        if([score intValue] > [highestScore intValue]){
            highestScore = score;
            highestScoreIndex = i;
        }
    }
    return ((CSVReader *)readerArray[highestScoreIndex]).config;
}

@end