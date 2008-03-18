/* BoundsChangedNotification, by Zachary Brewster-Geisz et al. for Books.app
 
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

/** Notification for rotate/resize events. */
#define BOUNDSDIDCHANGENOTEIFICATION @"boundsDidChangeNotification"

#import "BoundsChangedNotification.h"

@implementation BoundsChangedNotification
/**
 * Name for this type of notification.
 */
+ (NSString*)name {
  return BOUNDSDIDCHANGENOTEIFICATION;
}

/**
 * Return an autoreleased instance.
 */
+ (BoundsChangedNotification*)boundsChangedFrom:(struct CGRect)p_old 
                                             to:(struct CGRect)p_new 
                                      transform:(struct CGAffineTransform)p_tform
                                      forObject:(id)p_obj {
  return [[[BoundsChangedNotification alloc] initWithOldBounds:p_old 
                                                     newBounds:p_new 
                                                     transform:p_tform
                                                        object:p_obj] autorelease];
}

/**
 * Init with old/new bounds.
 */
- (id)initWithOldBounds:(struct CGRect)p_old 
              newBounds:(struct CGRect)p_new 
              transform:(struct CGAffineTransform)p_tform
                 object:(id)p_obj {
  // Can't call super init for this!
  
  m_oldBounds = p_old;
  m_newBounds = p_new;
  m_transform = p_tform;
  m_changedObject = [p_obj retain];
  
  return self;
}

/**
 * Get the bounds from before the change.
 */
- (struct CGRect)oldBounds {
  return m_oldBounds;
}

/**
 * Get the bounds after the change.
 */
- (struct CGRect)newBounds {
  return m_newBounds;
}

/**
 * Always the same name.
 */
- (NSString*)name {
  return BOUNDSDIDCHANGENOTEIFICATION;
}

/**
 * Return the transform used in this bounds change.
 */
- (struct CGAffineTransform)transformation {
  return m_transform;
}

/**
 * Return the changed object.
 */
- (id)object {
  return m_changedObject;
}

/**
 * No userinfo.
 */
- (NSDictionary*)userInfo {
  return nil;
}

/**
 * Cleanup.
 */
- (void)dealloc {
  [m_changedObject release];
  m_changedObject = nil;
  
  [super dealloc];
}

@end