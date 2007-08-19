// HideableNavBar, (c) 2007 by Zachary Brewster-Geisz

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



#include <Foundation/Foundation.h>
#include <CoreGraphics/CoreGraphics.h>
#include <UIKit/UINavigationBar.h>
#import <UIKit/UITransformAnimation.h>
#import <UIKit/UIAnimator.h>

@interface HideableNavBar : UINavigationBar
{
  BOOL hidden;
  BOOL isTop;
  UITransformAnimation *translate;
  UIAnimator *animator;
}
- (HideableNavBar *)initWithFrame:(struct CGRect)rect isTop:(BOOL)top;
- (void)hide;
- (void)show;
- (void)toggle;
- (BOOL)hidden;

@end
