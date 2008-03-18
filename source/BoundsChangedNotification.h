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

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>

@interface BoundsChangedNotification : NSNotification {
  struct CGRect m_oldBounds;
  struct CGRect m_newBounds;
  struct CGAffineTransform m_transform;
  
  int m_orientationCode;
  
  id m_changedObject;
  NSString *m_name;
}

+ (NSString*)willChangeName;
+ (NSString*)didChangeName;

+ (BoundsChangedNotification*)boundsDidChangeFrom:(struct CGRect)p_old 
                                                to:(struct CGRect)p_new 
                                         transform:(struct CGAffineTransform)p_tform
                                      orientation:(int)o_code
                                         forObject:(id)p_obj;


+ (BoundsChangedNotification*)boundsWillChangeFrom:(struct CGRect)p_old 
                                             to:(struct CGRect)p_new 
                                      transform:(struct CGAffineTransform)p_tform
                                       orientation:(int)o_code
                                      forObject:(id)p_obj;


- (id)initWithOldBounds:(struct CGRect)p_old
              newBounds:(struct CGRect)p_new 
              transform:(struct CGAffineTransform)p_tform
            orientation:(int)o_code
                 object:(id)p_obj
                   name:(NSString*)p_name;

- (struct CGRect)oldBounds;
- (struct CGRect)newBounds;

- (NSString*)name;
- (struct CGAffineTransform)transformation;
- (int)uiOrientationCode;
- (id)object;
- (NSDictionary*)userInfo;
@end