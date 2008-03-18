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

  [self disableAnimation];
  
  m_nCurrentBrowser = 0;
  
  [self setDelegate:p_del];
  _browserDelegate = [p_del retain];
  
  _transView = [p_tv retain];

  // Only need file handling stuff on the top nav bar
  if(isTop) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(shouldReloadTopBrowser:)
                                                 name:RELOADTOPBROWSER
                                               object:nil];
    
    
    FileBrowser *fb1 = [[FileBrowser alloc] initWithFrame:[p_tv bounds]];
    FileBrowser *fb2 = [[FileBrowser alloc] initWithFrame:[p_tv bounds]];
    
    [fb1 setDelegate:p_del];
    [fb2 setDelegate:p_del];
    
    m_browserList = [[NSArray alloc] initWithObjects:fb1, fb2, nil];
    
    GSLog(@"FileBrowser1: %@, FileBrowser2: %@", fb1, fb2);
    
    [fb1 release];
    [fb2 release];
  }
  
	return self;
}

/**
 * Get the currently active file browser.
 */
- (FileBrowser*)topBrowser {
  return [m_browserList objectAtIndex:m_nCurrentBrowser];
}

- (void)popNavigationItem { 
  FileNavigationItem *poppedFi = (FileNavigationItem*)[self topItem];
  [super popNavigationItem];
  FileNavigationItem *topFi = (FileNavigationItem*)[self topItem];
  
  GSLog(@"Popped item at %@, new top is %@", [poppedFi path], [topFi path]);
  
  FileBrowser *oldBrowser = [m_browserList objectAtIndex:m_nCurrentBrowser];
  FileBrowser *newBrowser = [m_browserList objectAtIndex:!m_nCurrentBrowser];
  
  if([poppedFi isDocument]) {
    // We're currently going from text to file
    if([_browserDelegate respondsToSelector:@selector(closeCurrentDocument)]) {
      [_browserDelegate closeCurrentDocument];
    } 
    
    if([self isAnimationEnabled]) {
      if(![[oldBrowser path] isEqualToString:[topFi path]]) {
        [oldBrowser setPath:[topFi path]];
        [oldBrowser reloadData];  
      }
      [_transView transition:2 fromView:nil toView:oldBrowser];
    }
  } else {
    // Going file to file
    if([self isAnimationEnabled]) {
      m_nCurrentBrowser = !m_nCurrentBrowser;
      if(![[newBrowser path] isEqualToString:[topFi path]]) {
        [newBrowser setPath:[topFi path]];
        [newBrowser reloadData];
      }
      [_transView transition:2 fromView:oldBrowser toView:newBrowser];
    }
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
  
  // Hack old view: Either it's a file browser OR if we starting up, it's the image view.
  // It's up to BooksApp to call setOldView: if it needs us to clean up after it.
  UIView *oldView = oldBrowser;
  if(m_oldView != nil) {
    GSLog(@"Startup oldView hack triggered...");
    oldView = m_oldView;
  }
  
  if([pushedFi isDocument]) {
    UIView *newView = nil;
    if([_browserDelegate respondsToSelector:@selector(showDocumentAtPath:)]) {
      newView = [_browserDelegate showDocumentAtPath:[pushedFi path]];
    }
    
    if([self isAnimationEnabled]) {
       GSLog(@"Transitioning from %@ to %@", oldView, newView);
      [_transView transition:1 fromView:oldView toView:newView];
    }
  } else {
    // FileBrowser
    if([self isAnimationEnabled]) {      
      GSLog(@"Transitioning from %@ to %@", oldView, newBrowser);
      m_nCurrentBrowser = !m_nCurrentBrowser;
      if(![[newBrowser path] isEqualToString:[pushedFi path]]) {        
        [newBrowser setPath:[pushedFi path]];
        [newBrowser reloadData];
      }
      [_transView transition:1 fromView:oldView toView:newBrowser];
    }
  }
  
  [self setOldView:nil];
}

/**
 * Before pushing a navigation item, set the old view to be transitioned off
 * from.  Should only be necessary at startup to get the book image off.
 */
- (void)setOldView:(UIView*)p_view {
  [p_view retain];
  [m_oldView release];
  m_oldView = p_view;
}

- (void)shouldReloadTopBrowser:(NSNotification *)notification {
	[[m_browserList objectAtIndex:m_nCurrentBrowser] reloadData];
}

- (void)hide:(BOOL)forced {
	if (!hidden) {	
		if (isTop && forced) {
			[self hideTopNavBar];
		} else if (forced) {
			[self hideBotNavBar];
		}

    // FIXME: What's this forced thing do?
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
  GSLog(@"Show Top Nav Bar");
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
  GSLog(@"Hide Top Nav Bar");
	struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
	[self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y, hardwareRect.size.width, 48.0f)];

	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, -68.0);
	[translate setStartTransform: CGAffineTransformMake(1,0,0,1,0,0)];
	[translate setEndTransform: trans];
	[animator addAnimation:translate withDuration:.25 start:YES];
	hidden = YES;
}

- (void)showBotNavBar {
  GSLog(@"Show Bottom Nav Bar");
	struct CGRect hardwareRect = [defaults fullScreenApplicationContentRect];
	[self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.size.height, hardwareRect.size.width, 48.0f)];
	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, 48);
	[translate setStartTransform: trans];
	[translate setEndTransform: CGAffineTransformMake(1,0,0,1,0,0)];
	[animator addAnimation:translate withDuration:.25 start:YES];

}

- (void)hideBotNavBar {
  GSLog(@"Hide Bottom Nav Bar");
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
  
  [m_oldView release];
  [m_browserList release];
	[animator release];
	[translate release];
  [_transView release];
  [_extensions release];
  [_browserDelegate release];

	[defaults release];
  
	[super dealloc];
}

@end
