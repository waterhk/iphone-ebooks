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


#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UINavigationBar.h>
#import <UIKit/UITransformAnimation.h>
#import <UIKit/UIAnimator.h>
#import <UIKit/UITransitionView.h>
#import <UIKit/UINavigationItem.h>
#import "FileBrowser.h"
#import "BooksDefaultsController.h"
#import "common.h"

#import <UIKit/UIHardware.h>
#import "HideableNavBar.h"
#import "FileBrowser.h"
#import "EBookView.h"
#import "FileNavigationItem.h"

#define READY_FROM_VIEW @"fromView"
#define READY_TO_VIEW @"toView"
#define READY_TRANSITION @"transition"
#define READY_DEST_NAV @"destNav"

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
 * Perform an action on all item views in the stack.
 */
- (void)performSelectorOnItemViews:(SEL)p_sel withObject:(id)p_obj {
  NSArray *items = [self navigationItems];
  int itemCount = [items count];
  
  for(itemCount = itemCount - 1; itemCount >=0; itemCount--) {
    FileNavigationItem *fni = (FileNavigationItem*)[items objectAtIndex:itemCount];
    UIView *view = [fni view];
    GSLog(@"Performing %@ on %@", p_sel, view);
    [view performSelector:p_sel withObject:p_obj];
  }
}


/**
 * Defer transition until the ebook is ready.
 *
 * When we're loading a book, we want a nice spinny progress indicator thing.  Cocoa is rather
 * particular about how things are threaded and when we get back to runLoops for that to work.
 * So...  We let the push/pop's call here and end up looping until the book is loaded and we're
 * ready to go.  Then we transition, call the book to finish getting its act together, and we're
 * done!  It's ugly as sin, but it works, and it's something approaching encapsulated...
 *
 * Future enhancements should make a single base class for all of the various views that can
 * end up in a navbar (FileBrowser, EBookView, EBookImageView) or at least a common interface
 * between them.  For now, we cast over to EBookView to call the methods we know are there.
 */
- (void)transitionViewsWhenReady:(id)p_tmr {
  NSDictionary *info;
  
  // We can either get a timer w/ user info, or just pass the dictionary directly.
  if([p_tmr respondsToSelector:@selector(userInfo)]) {
    NSTimer *tmr = (NSTimer*)p_tmr;
    info = [p_tmr userInfo];
  } else {
    info = (NSDictionary*)p_tmr;
  }
  
  UIView *fromView = (UIView*)[info objectForKey:READY_FROM_VIEW];
  UIView *toView = (UIView*)[info objectForKey:READY_TO_VIEW];
  NSNumber *transition = (NSNumber*)[info objectForKey:READY_TRANSITION];
  FileNavigationItem *destItem = (FileNavigationItem*)[info objectForKey:READY_DEST_NAV];
  
  // By default, we're ready.
  BOOL bCanShow = YES;
  
  // If it's a book and it's not ready, then we're not ready.  Otherwise, we are.
  if([toView respondsToSelector:@selector(isReadyToShow)]) {
    EBookView *ebv = (EBookView*)toView;
    bCanShow = [ebv isReadyToShow];
  } 
  
  if(bCanShow) {
    // Do the transition        
    [[self delegate] setNavForItem:destItem];
    [_transView transition:[transition intValue] fromView:fromView toView:toView];
    
    // If it's a book, call cleanup on the progress bar and also get the book prefs loaded.
    if([toView respondsToSelector:@selector(isReadyToShow)]) {
      EBookView *ebv = (EBookView*)toView;     
      [ebv hidePleaseWait];
    }
    
    // Cleanup the startup image later so we can still use it to transition.
    [NSTimer scheduledTimerWithTimeInterval:0.5f target:[self delegate] selector:@selector(cleanupStartupImage) userInfo:nil repeats:NO];
  } else {
    // Reschedule
    [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(transitionViewsWhenReady:) userInfo:info repeats:NO];
  }
}

/**
 * Helper to create a userInfo dictionary for transitionViewsWhenReady:
 */
- (NSDictionary*)transitionDictFromView:(UIView*)p_from toView:(UIView*)p_to destItem:(FileNavigationItem*)p_item transition:(int)p_trans {
  return [NSDictionary dictionaryWithObjectsAndKeys:
                       p_from, READY_FROM_VIEW,
                       p_to, READY_TO_VIEW,
                       p_item, READY_DEST_NAV,
                       [NSNumber numberWithInt:p_trans], READY_TRANSITION,
                       nil];
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
    [self transitionViewsWhenReady:[self transitionDictFromView:[poppedFi view] toView:[topFi view] destItem:topFi transition:2]];
  }
  
  [poppedFi release];
}


/**
 * Add a new item to the navigation bar stack and adjust the on-screen views to match.
 * If p_repView is not nil, it will be used as the fromView for the transition instead
 * of the view we think we should use - kludge for startup image.
 */
- (void)pushNavigationItem:(UINavigationItem*)p_item {
  FileNavigationItem *pushedFi = (FileNavigationItem*)p_item;
  FileNavigationItem *topFi = (FileNavigationItem*)[self topItem];
  [super pushNavigationItem:p_item];
  
  GSLog(@"Pushing %@ %@", ([pushedFi isDocument] ? @"Document" : @"Directory"), [pushedFi path]);
  
  if([self isAnimationEnabled]) {
    UIView *fromView = [topFi view];
    if(m_offViewKludge != nil) {
      fromView = m_offViewKludge;
    }
    
    [self transitionViewsWhenReady:[self transitionDictFromView:fromView toView:[pushedFi view] destItem:pushedFi transition:1]];
    
    [self setTransitionOffView:nil];
  }
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
  
  [self transitionViewsWhenReady:[self transitionDictFromView:[poppedFi view] toView:[newFi view] destItem:newFi transition:1]];
  
  [poppedFi release];
}

/**
 * Set a view which will override the next animated view transition.
 * This is a kludge to get the startup image view to work properly.
 */
- (void)setTransitionOffView:(UIView*)p_view {
  [p_view retain];
  [m_offViewKludge release];
  m_offViewKludge = p_view;
}

- (void)shouldReloadTopBrowser:(NSNotification *)notification {
	[[self topBrowser] reloadData];
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
      [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y, hardwareRect.size.width, TOOLBAR_HEIGHT)];      
      startTrans = CGAffineTransformMake(1,0,0,1,0,0);
      endTrans = CGAffineTransformMakeTranslation(0, -(TOOLBAR_HEIGHT+TOOLBAR_FUDGE));
		} else {
      [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.size.height - TOOLBAR_HEIGHT, hardwareRect.size.width, TOOLBAR_HEIGHT)];
      startTrans = CGAffineTransformMake(1,0,0,1,0,0);
      endTrans = CGAffineTransformMakeTranslation(0, TOOLBAR_HEIGHT);
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
      [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y - (TOOLBAR_FUDGE+TOOLBAR_HEIGHT), hardwareRect.size.width, TOOLBAR_HEIGHT)];
      startTrans = CGAffineTransformMakeTranslation(0,-(TOOLBAR_FUDGE+TOOLBAR_HEIGHT));
      endTrans = CGAffineTransformIdentity;
    } else {
      [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.size.height, hardwareRect.size.width, TOOLBAR_HEIGHT)];
      startTrans = CGAffineTransformMakeTranslation(0, TOOLBAR_HEIGHT);
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
  
  [m_offViewKludge release];
	[animator release];
	[translate release];
  [_transView release];

	[defaults release];
  
	[super dealloc];
}

@end
