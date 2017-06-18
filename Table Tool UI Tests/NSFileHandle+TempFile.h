//
//  NSFileHandle+TempFile.h
//  Table Tool
//
//  Created by Martin Köhler on 18.06.17.
//  Copyright © 2017 Egger Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSFileHandle (TempFile)

+ (NSFileHandle * _Nullable)tempFileForTestClass:(NSString * _Nonnull)className
                                        selector:(NSString * _Nonnull)selector
                        fileNameWithoutExtension:(NSString * _Nonnull)fileName
                                       extension:(NSString * _Nonnull)extension
                                         getPath:(NSMutableString * _Nonnull)outPath
                                           error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end
