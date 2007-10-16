// 
//  BooksSearchBox
//  Books.app
//  
//  Created by Chris Born, modified by Zach Brewster-Geisz for Books.app.
//  Copyright 2007 Borngraphics. All rights reserved.
//  
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or any later version.
//  
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//  
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//  
//  By contributing code you grant Chris Born and Borngraphics an
//  unlimited, non-exclusive license to your contribution.
//  
//  For support, questions, commercial use, etc...
//  E-Mail: chris <at> borngraphics <dot> com
// 

#import "BooksSearchBox.h"
#import <UIKit/UIView-Rendering.h>

// This view is holds the kyboard and text input bar for changing the player name.
// It should be 216px for the keyboard and 45px for the bar.

@implementation FDTextInputView
- (id)initWithFrame:(struct CGRect)frame
{
	if(self = [super initWithFrame:frame])
	{
		NSLog(@"TextInputView %s", _cmd);
		_contentRect = [UIHardware fullScreenApplicationContentRect];
		_offScreenRect = frame;
		_onScreenRect = frame;
		_onScreenRect.origin.y = 154.0f;
	
		defaults = [[FDDefaultsController alloc] init];
		
		UIImageView *background = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f,0.0f,frame.size.width,45.0f)];
		[background setImage:[UIImage applicationImageNamed:@"keyboardbar.png"]];	
		[self addSubview:background];
		[background release];
		
		UIKeyboard* keyboard = [[UIKeyboard alloc] initWithFrame:CGRectMake(0.0f,45.0f,frame.size.width,216.0f)];	
		[keyboard setReturnKeyEnabled:YES];
		[self addSubview:keyboard];
		[keyboard release];
		
		doneButton = [[UIPushButton alloc] initWithTitle:@"" autosizesToFit:NO];
		[doneButton setFrame:CGRectMake(frame.size.width - 64.0f,11.0f,59.0f,26.0f)];			
		[doneButton setEnabled:YES];
		[doneButton setStretchBackground: NO];
		[doneButton setBackground:[UIImage applicationImageNamed:@"done_en.png"] forState:0];
		[doneButton setBackground:[UIImage applicationImageNamed:@"done_dn.png"] forState:1];
		[doneButton addTarget:self action:@selector(doneWithEditing:) forEvents:1];
		[self addSubview: doneButton];
		[doneButton release];
		
		float clearColor[4] = {0,0,0,0};
		inputText = [[UITextView alloc] initWithFrame:CGRectMake(15.0f,16.0f,205.0f,18.0f)];
		[inputText setBackgroundColor: CGColorCreate(CGColorSpaceCreateDeviceRGB(), clearColor)];
		[inputText setTextSize: 15.0f];
		[inputText setMarginTop: 0.0f];
		[inputText setOpaque:YES];
		[inputText setDelegate: self];
		[inputText setBottomBufferHeight: 0.0f];
		[self addSubview: inputText];
		[self setText:@""];
		[self addSubview:inputText];
		[inputText release];
		
	}
	return self;
}

#pragma mark Show and Hide Methods
- (void)show
{
	translate = [[UITransformAnimation alloc] initWithTarget:self];
	animator = [[UIAnimator alloc] init];

	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, -_offScreenRect.size.height);
	
	[self setFrame:_offScreenRect];
	[translate setStartTransform:CGAffineTransformMake(1,0,0,1,0,0)];
	[translate setEndTransform:trans];
	[animator addAnimation:translate withDuration:.4 start:YES];
	[delegate setKeyboardVisible:YES];
	
	/*
		This is silly but somthing with the UITextView makes displaying text while animating
		its super view not work. So, I set a timer, then refresh the textview rect after the
		view has stared to move into place. Now we see the player name as we should.
	*/
	NSTimer		*animDelay = [NSTimer scheduledTimerWithTimeInterval:0.2
									  	  target:self
										selector:@selector(focusOnText:)
										userInfo:nil
									 	 repeats:NO];
}

- (void)hide
{
	translate = [[UITransformAnimation alloc] initWithTarget:self];
	animator = [[UIAnimator alloc] init];
	
	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, -_offScreenRect.size.height);
	
	[self setFrame:_onScreenRect];
	[translate setStartTransform:trans];
	[translate setEndTransform:CGAffineTransformMake(1,0,0,1,0,0)];
	[animator addAnimation:translate withDuration:.4 start:YES];
	[delegate setKeyboardVisible:NO];
}

- (void)focusOnText:(NSTimer *)aTimer
{
	[aTimer invalidate];
	[inputText setFrame:CGRectMake(15.0f,16.0f,205.0f,18.0f)];
	[self setFocus];
}
#pragma mark Workers
- (void)doneWithEditing:(struct __GSEvent *)event
{
	NSLog(@"%s", _cmd);
	//[defaults setPlayerOneName:[self text]];
	//[defaults synchronize];
	//[delegate updatedPlayerNames];
	[self hide];
}

#pragma mark Text View

- (NSString *)text
{
	return [inputText text];
}

- (void)setText:(NSString *)text
{
	[inputText setText: text];
}

- (void)setFocus
{
	NSRange aRange;
	aRange.location = 9999999; 
	aRange.length = 1;
	[inputText setSelectionRange:aRange];
	[inputText scrollToMakeCaretVisible:YES];
	[[[inputText _webView] webView] moveToEndOfDocument:self];
	[[inputText _webView] insertText:@""];
	[inputText setSelectionRange:aRange];
	[inputText scrollToMakeCaretVisible:YES];
}

#pragma mark Delegate
- (id)delegate
{
	return delegate;
}

- (void)setDelegate:(id)newDelegate
{
	delegate = newDelegate;
}

- (void)dealloc
{
	[animator release];
	[translate release];
	[defaults release];
	[super dealloc];
}
@end
