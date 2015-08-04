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
    _checkBox.hidden = NO;
    _checkBox.enabled = YES;
    if([_viewTitle.stringValue isEqualToString:@"Output File Format"]){
        _checkBox.title = @"Same as Input Format";
        [[_checkBox cell] setState:1];
        _checkBoxIsChecked = YES;
        [self unableFormatting];
    }else{
        _checkBox.title = @"Use First Row as Header";
        [[_checkBox cell] setState:0];
        _checkBoxIsChecked = NO;
    }
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
    if([self.quoteControl selectedSegment] == 1){
        _config.quoteCharacter = @"";
    }else{
        _config.quoteCharacter = [self.quoteControl labelForSegment:[self.quoteControl selectedSegment]];
    }
    _config.escapeCharacter = [self.escapeControl labelForSegment:[self.escapeControl selectedSegment]];
    
    [self.delegate configurationChangedForFormatViewController:self];
}

- (IBAction)clickCheckBox:(id)sender {
    if([_viewTitle.stringValue isEqualToString:@"Output File Format"]){
        [self useInputConfig:sender];
    }else{
        [self useFirstRowAsHeader:sender];
    }
}

-(void)uncheckCheckbox{
    [[_checkBox cell] setState:0];
    [self useFirstRowAsHeader:NULL];
}

-(void)useInputConfig:(id)sender{
    if(!_checkBoxIsChecked){
        [self.delegate useInputConfig:self];
        _checkBoxIsChecked = YES;
        [self selectFormatByConfig];
        [self unableFormatting];
    }else{
        _checkBoxIsChecked = NO;
        [self enableFormatting];
    }
}

-(void)useFirstRowAsHeader:(id)sender{
    if(!_checkBoxIsChecked){
        _checkBoxIsChecked = YES;
    }else{
        _checkBoxIsChecked = NO;
    }
    [self.delegate useFirstRowAsHeader:self];
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
    if([_viewTitle.stringValue isEqualToString:@"Input File Format"]){
        _checkBox.enabled = NO;
    }
}

-(void)enableFormatting{
    _encodingMenu.enabled = YES;
    _separatorControl.enabled = YES;
    _decimalControl.enabled = YES;
    _quoteControl.enabled = YES;
    _escapeControl.enabled = YES;
    if([_viewTitle.stringValue isEqualToString:@"Input File Format"]){
        _checkBox.enabled = YES;
    }
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
    }else{
        [_quoteControl selectSegmentWithTag:1];
    }
    
    if([_config.escapeCharacter isEqualToString:@"\""]){
        [_escapeControl selectSegmentWithTag:0];
    }else{
        [_escapeControl selectSegmentWithTag:1];
    }
}

@end
