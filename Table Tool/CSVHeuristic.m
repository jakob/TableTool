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
    NSMutableArray *firstRowArray;
    NSMutableArray *readLines;
}

-(instancetype)initWithData:(NSData *)data {
    self = [super init];
    if(self){
        if (data == nil) {
            [[NSException exceptionWithName:@"InvalidArgumentException" reason:@"data may not be nil" userInfo:nil] raise];
        }
        _data = data;
        [self setConfigs];
    }
    return self;
}

/*WARNING: used order for calculating differs from configuration name:
1.  _config1
2.  _config10
3.  _config6
4.  _config2
5.  _config5
6.  _config7
7.  _config3
8.  _config8
9.  _config4
10. _config9
11. _config11
*/

-(void)setConfigs{
    _config1 = [[CSVConfiguration alloc]init];
    _config1.columnSeparator = @",";
    _config1.decimalMark = @".";
    
    _config10 = _config1.copy;
    _config10.escapeCharacter = @"\\";
    
    _config6 = _config1.copy;
    _config6.quoteCharacter = @"";
    
    _config2 = [[CSVConfiguration alloc]init];
    _config2.columnSeparator = @";";
    _config2.decimalMark = @",";
    
    _config5 = _config2.copy;
    _config5.escapeCharacter = @"\\";
    
    _config7 = _config2.copy;
    _config7.quoteCharacter = @"";
    
    _config3 = [[CSVConfiguration alloc]init];
    _config3.columnSeparator = @"\t";
    _config3.decimalMark = @".";
    
    _config8 = _config3.copy;
    _config8.quoteCharacter = @"";
    
    _config4 = [[CSVConfiguration alloc]init];
    _config4.columnSeparator = @"\t";
    _config4.decimalMark = @",";
    
    _config9 = _config4.copy;
    _config9.quoteCharacter = @"";
    
    _config11 = _config1.copy;
    _config11.decimalMark = @",";
}

-(void)initializeArrays{
    CSVReader *reader1 = [[CSVReader alloc]initWithData:_data configuration:_config1];
    CSVReader *reader2 = [[CSVReader alloc]initWithData:_data configuration:_config2];
    CSVReader *reader3 = [[CSVReader alloc]initWithData:_data configuration:_config3];
    CSVReader *reader4 = [[CSVReader alloc]initWithData:_data configuration:_config4];
    CSVReader *reader5 = [[CSVReader alloc]initWithData:_data configuration:_config5];
    CSVReader *reader6 = [[CSVReader alloc]initWithData:_data configuration:_config6];
    CSVReader *reader7 = [[CSVReader alloc]initWithData:_data configuration:_config7];
    CSVReader *reader8 = [[CSVReader alloc]initWithData:_data configuration:_config8];
    CSVReader *reader9 = [[CSVReader alloc]initWithData:_data configuration:_config9];
    CSVReader *reader10 = [[CSVReader alloc]initWithData:_data configuration:_config10];
    CSVReader *reader11 = [[CSVReader alloc]initWithData:_data configuration:_config11];

    firstRowArray = [[NSMutableArray alloc]initWithObjects:[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO],[NSNumber numberWithBool:NO], nil];
    readerArray = [[NSArray alloc]initWithObjects:reader1,reader10,reader6,reader2,reader5,reader7,reader3,reader8,reader4,reader9,reader11,nil];
    scores = [[NSMutableArray alloc]initWithObjects:[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],[NSNumber numberWithInt:0],nil];
    readLines = [[NSMutableArray alloc]init];
}

-(void)setEncoding:(NSStringEncoding)encoding {
	for(CSVReader *reader in readerArray){
		[reader reset];
		reader.config.encoding = encoding;
	}
}

-(CSVConfiguration *)calculatePossibleFormat{
    [self initializeArrays];

    NSArray *encodingTestList = @[
            @(NSUTF8StringEncoding), // UTF-8
            @(CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)), // GBK
            @(NSWindowsCP1252StringEncoding),
            @(NSMacOSRomanStringEncoding),
    ];

    for (int i = 0; i < encodingTestList.count; ++i) {
        int encoding = [encodingTestList[(NSUInteger) i] intValue];
        self.encoding = (NSStringEncoding) encoding;
        if([self useSimpleHeuristic]){
            break;
        }
    }
    
    return [self getBestConfiguration];
}

-(BOOL)useSimpleHeuristic{
    for(int i = 0; i < readerArray.count; i++){
        CSVReader *reader = readerArray[i];
        readLines = [[NSMutableArray alloc]initWithCapacity:5];
        NSError *error = nil;
        for(int i = 0; i < 5; i++){
            NSArray *line = [reader readLineWithError:&error];
            if(line.count == 0 || line == nil) break;
            [readLines addObject:line];
        }
        
        if(error.code == 1) return NO;
        if(error) continue;
        scores[i] = [NSNumber numberWithInteger:([scores[i] integerValue] + readLines.count)];
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
        sameLength &= (((NSArray *)readLines[i]).count == count);
        if(((NSArray *)readLines[i]).count <= count) scores[index] = [NSNumber numberWithInt:([scores[index] intValue] + 1)];
    }
    if(sameLength){
        scores[index] = [NSNumber numberWithInt:([scores[index] intValue] + 5)];
        [firstRowArray replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:YES]];
    }
}

-(void)checkForNumbersFromReader:(int)index{
    int numbers = 0;
    for(int i = 0; i < readLines.count; i++){
        NSMutableArray * line = readLines[i];
        for(int j = 0; j < line.count; j++){
            if([line[j] isKindOfClass:[NSDecimalNumber class]]){
                numbers++;
                if(i == 0) {
                    [firstRowArray replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:NO]];
                }
            }else if(i == 0 && ((NSString *)line[j]).length == 0){
                [firstRowArray replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:NO]];
            }
        }
    }
    if (numbers > 5) numbers = 5;
    scores[index] = [NSNumber numberWithInt:([scores[index] intValue] + numbers)];
}

-(CSVConfiguration *)getBestConfiguration{
    NSNumber *highestScore = scores[0];
    int highestScoreIndex = 0;
    for(int i = 1; i < readerArray.count; i++){
        NSNumber *score = scores[i];
        if([score intValue] > [highestScore intValue]){
            highestScore = score;
            highestScoreIndex = i;
        }
    }
    CSVConfiguration *finalConfig = ((CSVReader *)readerArray[highestScoreIndex]).config;
    finalConfig.firstRowAsHeader = [firstRowArray[highestScoreIndex] boolValue];
    
    return finalConfig;
}

@end