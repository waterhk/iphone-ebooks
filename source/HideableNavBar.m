// HideableNavBar, for Books.app by Zachary Brewster-Geisz

/*

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; version 2
   of the License.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#import <UIKit/UIHardware.h>
#import "HideableNavBar.h"
#import "FileBrowser.h"
#import "EBookView.h"
#import "FileNavigationItem.h"

//#include "dolog.h"
@implementation HideableNavBar

- (HideableNavBar *)initWithFrame:(struct CGRect)rect delegate:(id)p_del transitionView:(UITransitionView*)p_tv {
	[super initWithFrame:rect];
  
	defaults = [BooksDefaultsController sharedBooksDefaultsController];
	// Try to infer whether the navbar is on the top or bottom of the screen.
	if (rect.origin.y == 0.0f)
		isTop = YES;
	else
		isTop = NO;
	translate =  [[UITransformAnimation alloc] initWithTarget: self];
	animator = [[UIAnimator alloc] init];
	hidden = NO;
	_transView = nil;

  [self disableAnimation];
 
  [self setDelegate:p_del];
  
  _transView = [p_tv retain];

  // Only need file handling stuff on the top nav bar
  if(isTop) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReloadTopBrowser:)
                                                 name:RELOADTOPBROWSER
                                               object:nil];
  }
  
	return self;
}

/**
 * Get the currently active file browser.
 */
- (FileBrowser*)topBrowser {
  /*
   * The top item might be a document.  We'll start at the top and work backwards until
   * we find the first item that isn't a document, then return its browser.
   * If we hit the bottom of the stack and still don't find a non-document (should be can't happen)
   * then we'll end up returning nil which shouldn't cause too much trouble.
   */
  FileNavigationItem *topDir = nil;
  NSArray *items = [self navigationItems];
  int itemCount = [items count];

  for(itemCount = itemCount - 1; itemCount >=0; itemCount--) {
    topDir = [items objectAtIndex:itemCount];
    if(![topDir isDocument]) {
      break;
    }
  }
  
  return [topDir browser];
}

/**
 * Return the top EBookView or EBookImageView or file browser if not a document.
 */
- (UIView*)topView {
  FileNavigationItem *top = [self topItem];
  return [top view];
}

/**
 * Remove the top item from the navigation bar stack and adjust the on-screen views to match.
 */
- (void)popNavigationItem { 
  FileNavigationItem *poppedFi = (FileNavigationItem*)[[self topItem] retain];
  [super popNavigationItem];
  FileNavigationItem *topFi = (FileNavigationItem*)[self topItem];
  
  GSLog(@"Popped %@ %@", ([poppedFi isDocument] ? @"Document" : @"Directory"), [poppedFi path]);
  
  if([self isAnimationEnabled]) {
    [[self delegate] setNavForItem:poppedFi];
    [_transView transition:2 fromView:[poppedFi view] toView:[topFi view]];
  }
  
  [poppedFi release];
}

/**
 * Add a new item to the navigation bar stack and adjust the on-screen views to match.
 */
- (void)pushNavigationItem:(UINavigationItem*)p_item {
  FileNavigationItem *pushedFi = (FileNavigationItem*)p_item;
  FileNavigationItem *topFi = (FileNavigationItem*)[self topItem];
  [super pushNavigationItem:p_item];
  
  GSLog(@"Pushing %@ %@", ([pushedFi isDocument] ? @"Document" : @"Directory"), [pushedFi path]);
  
  if([self isAnimationEnabled]) {
    [[self delegate] setNavForItem:topFi];
    [_transView transition:1 fromView:[topFi view] toView:[pushedFi view]];
  }
}

- (void)shouldReloadTopBrowser:(NSNotification *)notification {
	[[self topBrowser] reloadData];
}

/**
 * Replace the top navigation item with a new one.
 * 
 * Intended for chapter navigation from one document to another.
 */
- (void)replaceTopNavigationItem:(UINavigationItem*)p_item {
  [self disableAnimation];
  FileNavigationItem *poppedFi = (FileNavigationItem*)[[self topItem] retain];
  FileNavigationItem *newFi = (FileNavigationItem*)p_item;
  
  [super popNavigationItem];
  [super pushNavigationItem:newFi];
  [self enableAnimation];
  
  [_transView transition:1 fromView:[poppedFi view] toView:[newFi view]];
  [[self delegate] setNavForItem:newFi];
  
  [poppedFi release];
}

/**
 * Hide this navigation bar.
 */
- (void)hide {
	if (!hidden) {	
    struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
    struct CGAffineTransform startTrans;
    struct CGAffineTransform endTrans;
    
		if (isTop) {
      [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y, hardwareRect.size.width, 48.0f)];      
      startTrans = CGAffineTransformMake(1,0,0,1,0,0);
      endTrans = CGAffineTransformMakeTranslation(0, -68.0);
		} else {
      [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.size.height - 48.0f, hardwareRect.size.width, 48.0f)];
      startTrans = CGAffineTransformMake(1,0,0,1,0,0);
      endTrans = CGAffineTransformMakeTranslation(0, 48);
		}
    [translate setStartTransform:startTrans];
    [translate setEndTransform:endTrans];
    [animator addAnimation:translate withDuration:.25 start:YES];
    hidden = YES;
  }
}

/**
 * Show the navigation bar.
 */
- (void)show {
	if (hidden) {
    struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
    struct CGAffineTransform startTrans;
    struct CGAffineTransform endTrans;
    
		if (isTop) {
      //CHANGED: The "68" comes from SummerBoard--if we just use 48, 
      // the top nav bar shows under the status bar.
      [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y - 68.0f, hardwareRect.size.width, 48.0f)];
      startTrans = CGAffineTransformMakeTranslation(0,-68);
      endTrans = CGAffineTransformIdentity;
    } else {
      [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.size.height, hardwareRect.size.width, 48.0f)];
      startTrans = CGAffineTransformMakeTranslation(0, 48);
      endTrans = CGAffineTransformMake(1,0,0,1,0,0);
    }
    
    [translate setStartTransform:startTrans];
    [translate setEndTransform:endTrans];
    [animator addAnimation:translate withDuration:.25 start:YES];
    
		hidden = NO;
	}
}

/**
 * Toggle the visibility of the nav bar.
 */
- (void)toggle {
	if (hidden) {
		[self show];
	} else {
    [self hide];
  }
}

/**
 * Return YES if the nav bar is currently hidden.
 */
- (BOOL)hidden; {
	return hidden;
}

/**
 * Cleanup.
 */
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  
	[animator release];
	[translate release];
  [_transView release];

	[defaults release];
  
	[super dealloc];
}

@end
