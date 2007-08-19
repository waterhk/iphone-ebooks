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

#import <UIKit/UIHardware.h>
#import "HideableNavBar.h"

@implementation HideableNavBar

- (HideableNavBar *)initWithFrame:(struct CGRect)rect
{
  [super initWithFrame:rect];
  // Try to infer whether the navbar is on the top or bottom of the screen.
  if (rect.origin.y == 0.0f)
    isTop = YES;
  else
    isTop = NO;
  translate =  [[UITransformAnimation alloc] initWithTarget: self];
  animator = [[UIAnimator alloc] init];
  hidden = NO;
  return self;
}

- (HideableNavBar *)initWithFrame:(struct CGRect)rect isTop:(BOOL)top
{
  [super initWithFrame:rect];
  // If we can't infer, use this method instead.
  isTop = top;

  translate =  [[UITransformAnimation alloc] initWithTarget: self];
  animator = [[UIAnimator alloc] init];
  hidden = NO;
  return self;
}



- (void)hide
{
  if (!hidden)
    {
      if (isTop)
	[self hideTopNavBar];
      else
	[self hideBotNavBar];
      hidden = YES;
    }
}

- (void)show
{
  if (hidden)
    {
      if (isTop)
	[self showTopNavBar];
      else
	[self showBotNavBar];
      hidden = NO;
    }
}

- (void)toggle
{
  if (hidden)
    [self show];
  else
    [self hide];
}
- (BOOL)hidden;
{
  return hidden;
}

- (void)showTopNavBar
{
  struct CGRect hardwareRect = [UIHardware fullScreenApplicationContentRect];
  hardwareRect.origin.x = hardwareRect.origin.y = 0.0f;
  [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y - 48.0f, hardwareRect.size.width, 48.0f)];
  //  [self setTransform:CGAffineTransformMake(1,0,0,1,0,0)];
  struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0,-48);
  [translate setStartTransform: trans];
  [translate setEndTransform: CGAffineTransformMake(1,0,0,1,0,0)];
 
  [animator addAnimation:translate withDuration:.25 start:YES];
  //  [animator release];
  //  [translate release];

}

- (void)hideTopNavBar
{
  struct CGRect hardwareRect = [UIHardware fullScreenApplicationContentRect];
  hardwareRect.origin.x = hardwareRect.origin.y = 0.0f;
  [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.origin.y, hardwareRect.size.width, 48.0f)];
  //  [self setTransform:CGAffineTransformMake(1,0,0,1,0,0)];
  struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, -48.0);
  [translate setStartTransform: CGAffineTransformMake(1,0,0,1,0,0)];
  [translate setEndTransform: trans];
  [animator addAnimation:translate withDuration:.25 start:YES];
  //  [animator release];
  //  [translate release];

}

- (void)showBotNavBar
{
  struct CGRect hardwareRect = [UIHardware fullScreenApplicationContentRect];
  [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.size.height, hardwareRect.size.width, 48.0f)];
  struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, 48);
  [translate setStartTransform: trans];
  [translate setEndTransform: CGAffineTransformMake(1,0,0,1,0,0)];
  [animator addAnimation:translate withDuration:.25 start:YES];
  //animation goeth here?
}

- (void)hideBotNavBar
{
  struct CGRect hardwareRect = [UIHardware fullScreenApplicationContentRect];
  [self setFrame:CGRectMake(hardwareRect.origin.x, hardwareRect.size.height - 48.0f, hardwareRect.size.width, 48.0f)];
  struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, 48);
  [translate setStartTransform: CGAffineTransformMake(1,0,0,1,0,0)];
  [translate setEndTransform: trans];
  [animator addAnimation:translate withDuration:.25 start:YES];
  //animation goeth here?
}

- (void)dealloc
{
  [animator release];
  [translate release];
  [super dealloc];
}

@end
