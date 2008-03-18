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

@class UINavigationBar;
@class UITransformAnimation;
@class UIAnimator;
@class UITransitionView;
@class UIView;

@class FileNavigationItem;
@class BooksDefaultsController;


@interface HideableNavBar : UINavigationBar {
  BOOL hidden;
  BOOL isTop;
  UITransformAnimation *translate;
  UIAnimator *animator;
  UITransitionView *_transView;
  BooksDefaultsController	*defaults;
  
  UIView *m_offViewKludge;
}

- (HideableNavBar *)initWithFrame:(struct CGRect)rect delegate:(id)p_del transitionView:(UITransitionView*)p_tv;

- (void)hide;
- (void)show;
- (void)toggle;
- (BOOL)hidden;

- (void)replaceTopNavigationItem:(UINavigationItem*)p_item;
- (void)setTransitionOffView:(UIView*)p_view;
- (void)shouldReloadTopBrowser:(NSNotification *)notification;
- (FileBrowser*)topBrowser;
- (UIView*)topView;
@end

//informal protocol declaration for _browserDelegate
@interface NSObject (BrowserDelegate)
- (void)setNavForItem:(FileNavigationItem*)p_item;
@end
