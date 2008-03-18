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

#import "FileNavigationItem.h"

/**
 * This subclass of UINavigatioNItem carries with it a file path to be used
 * to draw the view associated with this item.
 */
@implementation FileNavigationItem

/**
 * Init with a title (passed to super) and a path.
 */
- (id)initWithTitle:(NSString*)p_title forPath:(NSString*)p_path {
  if(self = [super initWithTitle:p_title]) {
    m_isDocument = NO;
    m_path = [p_path retain];
  }
  
  return self;
}

/**
 * Init with just a path - title is last path component.
 */
- (id)initWithPath:(NSString*)p_path {
  NSString *title = [p_path lastPathComponent];
  id tmp = [self initWithTitle:title forPath:p_path];
  m_isDocument = NO; // override the designated init.
  return tmp;
}

/**
 * Init with the name of a document- use last path component minus file extension as the tite.
 */
- (id)initWithDocument:(NSString*)p_path {
  NSString *title = [[p_path lastPathComponent] stringByDeletingPathExtension];
  id tmp = [self initWithTitle:title forPath:p_path];
  m_isDocument = YES; // override the designated init.
  return tmp;
}

/**
 * Get the path.
 */
- (NSString*)path {
  return m_path;
}

/**
 * Return YES if this is a document, NO if a directory.
 */
- (BOOL)isDocument {
  return m_isDocument;
}

/**
 * Cleanup.
 */
- (void)dealloc {
  [m_path release];
  
  [super dealloc];
}
@end
