//
//  UIOrientingApplication.m
//  MobileChat
//
//  Created by Shaun Harrison on 2/21/08.
//  Copyright 2008 twenty08. All rights reserved.
//
//	Modifications made by Shaun Harrison
//	to work with MC's Transition class and
//	fix the artifact bug present in original code
//

/*
 UIOrientingApplication -- iPhone / iPod Touch UIKit Class
 ©2008 James Yopp; LGPL License
 
 Application re-orients the display automatically to match the physical orientation of the hardware.
 Display can be locked / unlocked to prevent this behavior, and can be manually oriented with lockUIToOrientation.
 */


#import "UIOrientingApplication.h"
#import <GraphicsServices/GraphicsServices.h>

#import "BoundsChangedNotification.h"

#import "common.h"

@implementation UIOrientingApplication

/* Set of Default Orientations in degrees: {Faceup, Standing, UpsideDown, Left, Right, Indeterminate, Facedown}
 VALID values here are 0, 90, 180, and -90 degrees.  Anything else may not work as expected.
 A value of -1 means that no angle is associated (do not change anything for this orientation code) */
static const int defaultOrientations[7] = {-1, 0, -1, 90, -90, -1, -1};

- (id) init {
	id rVal = [super init];
	unsigned char i = 7;
	while (i--) orientations[i] = defaultOrientations[i];
	orientationLocked = NO;
	reorientationDuration = 0.35f;
	orientationDegrees = -1;
	oldTransform = CGAffineTransformMake(1, 0, 0, 1, 0, 0);
	[self setUIOrientation: 1];
	return rVal;
}

- (void) lockUIOrientation {
	orientationLocked = YES;
}

- (void)toggleUIOrientationLocked {
  orientationLocked = !orientationLocked;
}

- (void) lockUIToOrientation: (unsigned int)o_code {
	[self setUIOrientation: o_code];
	[self lockUIOrientation];
}

- (void) unlockUIOrientation {
	orientationLocked = NO;
	[self deviceOrientationChanged: nil];
}

- (void) deviceOrientationChanged: (GSEvent*)event {
	if (orientationLocked) return;
	[self setUIOrientation: [UIHardware deviceOrientation:YES]];
}

- (void) setUIOrientation: (unsigned int)o_code {
	if (o_code > 6) return;
	/* Degrees should technically be a float, but without integers here, rounding errors seem to screw up the UI over time.
   The compiler will automatically cast to a float when appropriate API calls are made. */
	int degrees = orientations[o_code];
	if (degrees == -1) return;
	if (degrees == orientationDegrees) return;
	
	/* Find the rect a fullscreen app would use under the new rotation... */
	bool landscape = (degrees == 90 || degrees == -90);
	struct CGSize size = [UIHardware mainScreenSize];
	float statusBar = [UIHardware statusBarHeight];
	
	if (landscape) {
		size.width -= statusBar;
	} else size.height -= statusBar;
	
	m_fullKeyBounds.origin.x = (degrees == 90) ? statusBar : 0;
	m_fullKeyBounds.origin.y = 0;
	m_fullKeyBounds.size = size;
	
	m_fullContentBounds.origin.x = m_fullContentBounds.origin.y = 0;
	m_fullContentBounds.size = (landscape) ? CGSizeMake(size.height, size.width) : size; 
	
	/* Now that our member variable is set, we try to apply these changes to the key view, if present.
   If this routine is called before there is a key view, it will still set the rects and move the statusbar. */
	UIWindow *key = [UIWindow keyWindow];
	if (key) {
		
		[self setStatusBarMode:[self statusBarMode]
               orientation: (degrees == 180) ? 0 : degrees
                  duration:reorientationDuration fenceID:0 animation:3];
    
		UIView *transView = [key contentView];
    struct CGRect oldBounds = [transView bounds];
		if (transView) {
			struct CGSize oldSize = [transView bounds].size;
      
			struct CGAffineTransform transEnd;
			switch(degrees) {
				case 90:
					transEnd = CGAffineTransformMake(0, 1, -1, 0, 0, 0);
					break;
				case -90:
					transEnd = CGAffineTransformMake(0, -1, 1, 0, 0, 0);
					break;
				case 0:
				default:
          transEnd = CGAffineTransformMake(1, 0, 0, 1, 0, 0);
			}
      
      [[NSNotificationCenter defaultCenter] postNotification:[BoundsChangedNotification 
                                                              boundsWillChangeFrom:oldBounds 
                                                              to:m_fullContentBounds 
                                                              transform:transEnd
                                                              forObject:transView]];
      
      
			[UIView beginAnimations: nil];
      [transView setTransform:transEnd];
      [transView setBounds:m_fullContentBounds];
      [transView resizeSubviewsWithOldSize: oldSize];
      [transView setBounds:m_fullContentBounds];
      //[[Notifications sharedInstance] setFrame: FullContentBounds];
      
      [[NSNotificationCenter defaultCenter] postNotification:[BoundsChangedNotification 
                                                              boundsDidChangeFrom:oldBounds 
                                                              to:m_fullContentBounds 
                                                              transform:transEnd
                                                              forObject:transView]];
      
      [key setBounds: m_fullKeyBounds];
			[UIView endAnimations];
		} else [key setBounds: m_fullKeyBounds];
	} else [self setStatusBarMode: [self statusBarMode] orientation: (degrees == 180) ? 0 : degrees duration:0.0f];
	orientationDegrees = degrees;
	[super setUIOrientation: o_code];
}

- (void) setAngleForOrientation: (unsigned int)o_code toDegrees: (int)degrees {
	/* To disable transitions to a particular state, set degrees to -1. */
	if (o_code > 6) return;
	orientations[o_code] = degrees;
}

- (CGRect) windowBounds {
	return m_fullKeyBounds;
}

- (CGRect) contentBounds {
	return m_fullContentBounds;
}

- (bool) orientationLocked {
	return orientationLocked;
}
@end
