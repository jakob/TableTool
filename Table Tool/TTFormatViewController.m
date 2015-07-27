//
//  TTFormatViewController.m
//  Table Tool
//
//  Created by Andreas Aigner on 24.07.15.
//  Copyright (c) 2015 Egger Apps. All rights reserved.
//

#import "TTFormatViewController.h"

@interface TTFormatViewController ()

@end

@implementation TTFormatViewController

-(instancetype) init {
    self = [super initWithNibName:@"TTFormatViewController" bundle:nil];
    if(self) {
        _config = [[CSVConfiguration alloc]init];
        _viewTitle.stringValue = @"";
        [self selectFormatByConfig];
        _sameAsInput = YES;
    }
    return self;
}

- (void)viewDidLoad {
    _bottomConstraint.active = NO;
    [super viewDidLoad];
}

- (void)setControlTitle:(NSString *)title {
    _viewTitle.stringValue = title;
}

- (void)setCheckButton {
    _sameAsInputButton.hidden = NO;
    _sameAsInputButton.enabled = YES;
    [self unableFormatting];
}

- (void)showRevertMessage {
    _helpText.hidden = NO;
    _revertButton.hidden = NO;
    _revertButton.enabled = YES;
    _bottomConstraint.active = YES;
    [self unableFormatting];
}

- (IBAction)updateConfiguration:(id)sender {
    
    _config.encoding = [self.encodingMenu selectedTag];
    if([self.separatorControl selectedSegment] == 2) {
        _config.columnSeparator = @"\t";
    }else{
        _config.columnSeparator = [self.separatorControl labelForSegment:[self.separatorControl selectedSegment] ];
    }
    _config.decimalMark = [self.decimalControl labelForSegment:[self.decimalControl selectedSegment]];
    _config.quoteCharacter = [self.quoteControl labelForSegment:[self.quoteControl selectedSegment]];
    [self.escapeControl setLabel:_config.quoteCharacter forSegment:1];
    _config.escapeCharacter = [self.escapeControl labelForSegment:[self.escapeControl selectedSegment]];
    
    [self.delegate configurationChangedForFormatViewController:self];
}

- (IBAction)useInputConfig:(id)sender {
    if(!_sameAsInput){
        [self.delegate useInputConfig:self];
        _sameAsInput = YES;
        [self selectFormatByConfig];
        [self unableFormatting];
    }else{
        _sameAsInput = NO;
        [self enableFormatting];
    }
}

- (IBAction)revertEditing:(id)sender {
    [self.delegate revertEditing];
    _revertButton.hidden = YES;
    _revertButton.enabled = NO;
    _helpText.hidden = YES;
    _bottomConstraint.active = NO;
    [self enableFormatting];
}

-(void)unableFormatting{
    _encodingMenu.enabled = NO;
    _escapeControl.enabled = NO;
    _separatorControl.enabled = NO;
    _decimalControl.enabled = NO;
    _quoteControl.enabled = NO;
}

-(void)enableFormatting{
    _encodingMenu.enabled = YES;
    _separatorControl.enabled = YES;
    _decimalControl.enabled = YES;
    _quoteControl.enabled = YES;
    _escapeControl.enabled = YES;
}

-(void)selectFormatByConfig{
    [_encodingMenu selectItemWithTag:_config.encoding];
    if([_config.columnSeparator isEqualToString:@","]){
        [_separatorControl selectSegmentWithTag:0];
    }else if([_config.columnSeparator isEqualToString:@";"]){
        [_separatorControl selectSegmentWithTag:1];
    }else {
        [_separatorControl selectSegmentWithTag:2];
    }
    
    if([_config.decimalMark isEqualToString:@"."]){
        [_decimalControl selectSegmentWithTag:0];
    }else{
        [_decimalControl selectSegmentWithTag:1];
    }
    
    if([_config.quoteCharacter isEqualToString:@"\""]){
        [_quoteControl selectSegmentWithTag:0];
        [_escapeControl setLabel:@"\"" forSegment:1];
    }else{
        [_quoteControl selectSegmentWithTag:1];
        [_escapeControl setLabel:@"'" forSegment:1];
    }
    
    if([_config.escapeCharacter isEqualToString:@"\\"]){
        [_escapeControl selectSegmentWithTag:0];
    }else{
        [_escapeControl selectSegmentWithTag:1];
    }
}

@end
