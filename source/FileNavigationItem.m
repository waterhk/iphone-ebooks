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
#import "FileBrowser.h"

/**
 * This subclass of UINavigatioNItem carries with it a file path to be used
 * to draw the view associated with this item.
 */
@implementation FileNavigationItem
/**
 * Init with just a path - title is last path component.
 */
- (id)initWithPath:(NSString*)p_path browser:(FileBrowser*)p_browser {
  NSString *title = [p_path lastPathComponent];
  if(self = [super initWithTitle:title]) {
    m_isDocument = NO;
    m_path = [p_path retain];
    m_browser = [p_browser retain];
  }
  
  return self;
}

/**
 * Init with the name of a document- use last path component minus file extension as the tite.
 */
- (id)initWithDocument:(NSString*)p_path view:(UIView*)p_view {
  NSString *title = [[p_path lastPathComponent] stringByDeletingPathExtension];
  if(self = [super initWithTitle:title]) {
    m_isDocument = YES;
    m_path = [p_path retain];
    m_view = [p_view retain];
  }
  
  return self;
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
 * Get the associated browser.
 */
- (FileBrowser*)browser {
  return m_browser;
}

/**
 * Returns the view representing this item's contents.
 * Will return a FileBrowser for directories or a UIView 
 * (presumably EBookView or EBookImageView) for documents.
 */
- (UIView*)view {
  if(m_isDocument) {
    return m_view;
  } else {
    return m_browser;
  }
}

/**
 * Cleanup.
 */
- (void)dealloc {
  GSLog(@"FileNavigationItem dealloc %@", m_path);
  [m_path release];
  [m_browser release];
  [m_view release];
  
  [super dealloc];
}
@end
