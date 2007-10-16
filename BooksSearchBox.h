// 
//  BooksSearchBox
//  Books.app
//  
//  Created by Chris Born, adapted by Zach Brewster-Geisz for Books.app.
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIView.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/CDStructures.h>
#import <UIKit/UITextView.h>
#import <UIKit/UITransformAnimation.h>
#import <UIKit/UIAnimator.h>
#import <UIKit/UIPushButton.h>
#import <UIKit/UIKeyboard.h>


@interface NSObject (TextInputDelegateMethods)

- (void)updatedPlayerNames;
- (void)setKeyboardVisible:(BOOL)newKeyboardVisible;

@end

@interface BooksSearchBox : UIView
{
  id				delegate;
		
  //FDDefaultsController	*defaults;
  
  UITextView		*inputText;
  UIPushButton	*doneButton;
		
  UITransformAnimation	*translate;
  UIAnimator				*animator;
  
  struct CGRect		_contentRect;
  struct CGRect		_offScreenRect;
  struct CGRect		_onScreenRect;		
}

- (id)initWithFrame:(struct CGRect)frame;

#pragma mark Show and Hide Methods
- (void)show;
- (void)hide;

#pragma mark Workers
- (void)doneWithEditing:(struct __GSEvent *)event;

#pragma mark Text View
- (NSString*)text;
- (void)setText:(NSString*)text;
- (void)setFocus;

#pragma mark Delegate
- (id)delegate;
- (void)setDelegate:(id)newDelegate;

- (void)dealloc;
@end
