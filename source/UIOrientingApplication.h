//
//  UIOrientingApplication.m
//  MobileChat
//
//  Created by Shaun Harrison on 2/21/08.
//  Copyright 2008 twenty08. All rights reserved.
//

/*
 UIOrientingApplication -- iPhone / iPod Touch UIKit Class
 ©2008 James Yopp; LGPL License
 
 Application re-orients the display automatically to match the physical orientation of the hardware.
 Display can be locked / unlocked to prevent this behavior, and can be manually oriented with lockUIToOrientation.
 */


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIApplication.h>
#import <UIKit/UIAnimation.h>
#import <UIKit/UIRotationAnimation.h>
#import <UIKit/UIView-Animation.h>

@class UITransitionView;

@interface UIOrientingApplication : UIApplication {
	CGRect m_fullKeyBounds;
	CGRect m_fullContentBounds;
	int orientations[7];
	int orientationDegrees;
	bool orientationLocked;
	float reorientationDuration;
	struct CGAffineTransform oldTransform;
}

- (id) init;

- (void) lockUIOrientation;
- (void) lockUIToOrientation: (unsigned int)o_code;
- (void) unlockUIOrientation;
- (void) setUIOrientation: (unsigned int)o_code;
- (void) setAngleForOrientation: (unsigned int)o_code toDegrees: (int)degrees;

- (CGRect) windowBounds;
- (CGRect) contentBounds;
- (bool) orientationLocked;

@end
