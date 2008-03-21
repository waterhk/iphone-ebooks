// EBookImageView, for Books.app by Zach Brewster-Geisz
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
#import <UIKit/UIKit.h>
#import <UIKit/UIView-Geometry.h>
#import <UIKit/UIView-Rendering.h>
#import <CoreGraphics/CoreGraphics.h>
#import "common.h"

@interface EBookImageView : UIScroller {
  UIImageView *_imgView;
  
  /**
	 * stores the X coordinate of the last mouse down event for swipe detection
	 */
	float _MouseDownX;
	/**
	 * stores the Y coordinate of the last mouse down event for swipe detection
	 */
	float _MouseDownY;
  
  BOOL m_showingToolbars;
  
}

- (EBookImageView *)initWithContentsOfFile:(NSString *)file withFrame:(struct CGRect)p_frame scaleAspect:(BOOL)p_aspect;
- (void)showImage:(NSString*)p_path inFrame:(struct CGRect)p_frame scaleAspect:(BOOL)p_aspect;
- (void)showImage:(NSString*)p_path;
+ (NSString *)coverArtForBookPath:(NSString *)path;
@end
