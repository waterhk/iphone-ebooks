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

#import <UIKit/UIKit.h>
#import <UIKit/UINavigationItem.h>

@class FileBrowser;

@interface FileNavigationItem : UINavigationItem {
  FileBrowser *m_browser;
  UIView *m_view;
  NSString *m_path;
  BOOL m_isDocument;
}

- (id)initWithPath:(NSString*)p_path browser:(FileBrowser*)p_browser;
- (id)initWithDocument:(NSString*)p_path view:(UIView*)p_view;

- (NSString*)path;
- (BOOL)isDocument;
- (FileBrowser*)browser;
- (UIView*)view;

- (void)dealloc;

@end
