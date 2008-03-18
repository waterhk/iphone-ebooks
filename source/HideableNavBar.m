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
	_extensions = nil;
	_browserArray = [[NSMutableArray alloc] initWithCapacity:3]; // eh?
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(shouldReloadTopBrowser:)
												 name:RELOADTOPBROWSER
											   object:nil];
  [self disableAnimation];
  
  m_nCurrentBrowser = 0;
  
  [self setDelegate:p_del];
  _browserDelegate = [p_del retain];
  
  _transView = [p_tv retain];
  
  FileBrowser *fb1 = [[[FileBrowser alloc] initWithFrame:[p_tv bounds]] autorelease];
  FileBrowser *fb2 = [[[FileBrowser alloc] initWithFrame:[p_tv bounds]] autorelease];
  
  [fb1 setDelegate:p_del];
  [fb2 setDelegate:p_del];
  
  m_browserList = [[NSArray alloc] initWithObjects:fb1, fb1, nil];
  
	return self;
}

/**
 * Get the currently active file browser.
 */
- (FileBrowser*)topBrowser {
  return [m_browserList objectAtIndex:m_nCurrentBrowser];
}

- (void)popNavigationItem {
  /*
   * MOZART: We need two file views and a text view.  Use the file views to transition/slide
   * left/right.
   *
   * Popping will always show a FileBrowser.
   
   Pushing should always be the result of the user clicking on a file view.
   Popping should always be the result of clicking the back button in the navbar.
   
   Both popping and clicking the filebrowser may cause a new filebrowser to be shown.
   
   Only tapping on the filebrowser should show a new document view.
   */  
  FileNavigationItem *poppedFi = (FileNavigationItem*)[self topItem];
  [super popNavigationItem];
  FileNavigationItem *topFi = (FileNavigationItem*)[self topItem];
  
  GSLog(@"Popped item at %@, new top is %@", [poppedFi path], [topFi path]);
  
  FileBrowser *oldBrowser = [m_browserList objectAtIndex:m_nCurrentBrowser];
  FileBrowser *newBrowser = [m_browserList objectAtIndex:!m_nCurrentBrowser];

  if(m_topDocView != nil) {
    // We're currently going from text to file
    [_transView transition:([self isAnimationEnabled]? 2 : 0) fromView:m_topDocView toView:oldBrowser];  
    [m_topDocView release];
    m_topDocView = nil;
  } else {
    // Going file to file
    m_nCurrentBrowser = !m_nCurrentBrowser;
    [newBrowser setPath:[topFi path]];
    [_transView transition:([self isAnimationEnabled]? 2 : 0) fromView:oldBrowser toView:newBrowser];  
  }
}

- (void)pushNavigationItem:(UINavigationItem*)p_item {
  /* Pushing may reveal a FileBrowser, EBookView, or EBookImageView. */
  FileNavigationItem *pushedFi = (FileNavigationItem*)p_item;
  FileNavigationItem *topFi = (FileNavigationItem*)[self topItem];
  [super pushNavigationItem:p_item];
  
  GSLog(@"Pushing item at %@, old top is %@", [pushedFi path], [topFi path]);
  
  FileBrowser *oldBrowser = [m_browserList objectAtIndex:m_nCurrentBrowser];
  FileBrowser *newBrowser = [m_browserList objectAtIndex:!m_nCurrentBrowser];
  
  if([pushedFi isDocument]) {
    // EBookView or EBookImageView
    UIView *newView = nil;
    if([_browserDelegate respondsToSelector:@selector(showDocumentAtPath:)]) {
      newView = [_browserDelegate showDocumentAtPath:[pushedFi path]];
    } 
    [_transView transition:([self isAnimationEnabled]? 2 : 0) 
                  fromView:(m_topDocView == nil ? oldBrowser : m_topDocView) // Hack for startup cover image
                    toView:newView];
    [m_topDocView autorelease];
    m_topDocView = [newView retain];
  } else {
    // FileBrowser
    m_nCurrentBrowser = !m_nCurrentBrowser;
    [newBrowser setPath:[pushedFi path]];
    [_transView transition:([self isAnimationEnabled]? 2 : 0) fromView:oldBrowser toView:newBrowser];
    [m_topDocView release];
    m_topDocView = nil;
  }
}

/**
 * This hack exists only to make the startup image->text transition work.
 */
- (void)setTopDocumentView:(UIView*)p_view {
  [m_topDocView autorelease];
  m_topDocView = [p_view retain];
}

- (void)shouldReloadTopBrowser:(NSNotification *)notification {
	if (isTop) {
		[[_browserArray lastObject] reloadData];
	}
}

- (void)hide:(BOOL)forced {
	if (!hidden) {	
		if (isTop && forced) {
			[self hideTopNavBar];
		} else if (forced) {
			[self hideBotNavBar];
		}

		if (!forced) {
			if (isTop) {
				if ([defaults navbar]) {
          [self hideTopNavBar];
        }
			} else {
				if ([defaults toolbar]) {
          [self hideBotNavBar];
        }
			}
		}
	}
}

- (void)show {
	if (hidden) {
		if (isTop) {
      [self showTopNavBar:YES];
    } else {
      [self showBotNavBar];
    }
		hidden = NO;
	}
}

- (void)toggle {
	if (hidden) {
		[self show];
	} else {
    [self hide:NO];
  }
}

- (BOOL)hidden; {
	return hidden;
}

// FIXME: These four hide/show functions should all be a single function with a couple of parameters.
- (void)showTopNavBar:(BOOL)withAnimation {
	struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
	//CHANGED: The "68" comes from SummerBoard--if we just use 48, 
	// the top nav bar shows under the status bar.
	[self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y - 68.0f, hardwareRect.size.width, 48.0f)];

	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0,-68);
	if (withAnimation) {
		[translate setStartTransform: trans];
		[translate setEndTransform: CGAffineTransformIdentity];
		[animator addAnimation:translate withDuration:.25 start:YES];
	} else {
    [self setFrame: CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y, hardwareRect.size.width, 48.0f)];
  }

}

- (void)hideTopNavBar {
	struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
	[self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y, hardwareRect.size.width, 48.0f)];

	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, -68.0);
	[translate setStartTransform: CGAffineTransformMake(1,0,0,1,0,0)];
	[translate setEndTransform: trans];
	[animator addAnimation:translate withDuration:.25 start:YES];
	hidden = YES;
}

- (void)showBotNavBar {
	struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
	[self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.size.height, hardwareRect.size.width, 48.0f)];
	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, 48);
	[translate setStartTransform: trans];
	[translate setEndTransform: CGAffineTransformMake(1,0,0,1,0,0)];
	[animator addAnimation:translate withDuration:.25 start:YES];

}

- (void)hideBotNavBar {
	struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
	[self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.size.height - 48.0f, hardwareRect.size.width, 48.0f)];
	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, 48);
	[translate setStartTransform: CGAffineTransformMake(1,0,0,1,0,0)];
	[translate setEndTransform: trans];
	[animator addAnimation:translate withDuration:.25 start:YES];
	hidden = YES;
}

- (void)setExtensions:(NSArray *)extensions {
	_extensions = [extensions retain];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
  
  [m_browserList release];
  [m_topDocView release];
	[animator release];
	[translate release];
  [_transView release];
  [_extensions release];
  [_browserDelegate release];
	[_browserArray release];
	[defaults release];
  
	[super dealloc];
}

@end
