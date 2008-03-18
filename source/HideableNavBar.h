// HideableNavBar, (c) 2007 by Zachary Brewster-Geisz
// Creates a navBar that disappears when you ask it to.
// Also features integration with FileBrowser class.

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

@interface HideableNavBar : UINavigationBar
{
  BOOL hidden;
  BOOL isTop;
  UITransformAnimation *translate;
  UIAnimator *animator;
  UITransitionView *_transView;
  NSArray *_extensions;
  BooksDefaultsController	*defaults;
  id _browserDelegate;
  
  NSArray *m_browserList;
  int m_nCurrentBrowser;
  
  /** If currently showing a document, this is the view it's in. */
  UIView *m_topDocView;
}

- (HideableNavBar *)initWithFrame:(struct CGRect)rect delegate:(id)p_del transitionView:(UITransitionView*)p_tv;

- (void)hideTopNavBar;
- (void)showTopNavBar:(BOOL)withAnimation;
- (void)hideBotNavBar;
- (void)showBotNavBar;

- (void)setTopDocumentView:(UIView*)p_view;
- (void)hide:(BOOL)forced;
- (void)show;
- (void)toggle;
- (BOOL)hidden;
- (void)setExtensions:(NSArray *)extensions;
- (void)shouldReloadTopBrowser:(NSNotification *)notification;
- (FileBrowser*)topBrowser;
@end

//informal protocol declaration for _browserDelegate
@interface NSObject (BrowserDelegate)
- (UIView*)showDocumentAtPath:(NSString*)p_path;
- (void)closeCurrentDocument;
@end
