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
#define BOUNDSWILLCHANGENOTEIFICATION @"boundsWillChangeNotification"

#import "BoundsChangedNotification.h"

@implementation BoundsChangedNotification
/**
 * Name of event signifying bounds are about to change.
 */
+ (NSString*)willChangeName {
  return BOUNDSWILLCHANGENOTEIFICATION;  
}

/**
 *Name of event signifying bounds have changed.
 */
+ (NSString*)didChangeName {
  return BOUNDSDIDCHANGENOTEIFICATION;
}

/**
 * Return an autoreleased did change instance.
 */
+ (BoundsChangedNotification*)boundsDidChangeFrom:(struct CGRect)p_old 
                                               to:(struct CGRect)p_new 
                                        transform:(struct CGAffineTransform)p_tform
                                      orientation:(int)o_code
                                        forObject:(id)p_obj {
  return [[[BoundsChangedNotification alloc] initWithOldBounds:p_old 
                                                     newBounds:p_new 
                                                     transform:p_tform
                                                   orientation:o_code
                                                        object:p_obj
                                                          name:[BoundsChangedNotification didChangeName]] autorelease];
}


/**
 * Return an autoreleased will change instance.
 */
+ (BoundsChangedNotification*)boundsWillChangeFrom:(struct CGRect)p_old 
                                                to:(struct CGRect)p_new 
                                         transform:(struct CGAffineTransform)p_tform
                                       orientation:(int)o_code
                                         forObject:(id)p_obj {
  return [[[BoundsChangedNotification alloc] initWithOldBounds:p_old 
                                                     newBounds:p_new 
                                                     transform:p_tform
                                                   orientation:o_code
                                                        object:p_obj
                                                          name:[BoundsChangedNotification willChangeName]] autorelease];
}

/**
 * Init with old/new bounds.
 */
- (id)initWithOldBounds:(struct CGRect)p_old 
              newBounds:(struct CGRect)p_new 
              transform:(struct CGAffineTransform)p_tform
            orientation:(int)o_code
                 object:(id)p_obj
                   name:(NSString*)p_name {
  // Can't call super init for this!
  
  m_oldBounds = p_old;
  m_newBounds = p_new;
  m_transform = p_tform;
  m_orientationCode = o_code;
  m_changedObject = [p_obj retain];
  m_name = [p_name retain];
  
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
  return m_name;
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
 * Get the new orientation code.
 */
- (int)uiOrientationCode {
  return m_orientationCode;
}

/**
 * Cleanup.
 */
- (void)dealloc {
  [m_changedObject release];
  m_changedObject = nil;
  
  [m_name release];
  m_name = nil;
  
  [super dealloc];
}

@end