// FileTable.m, by Nate True and the NES.app team, 
// with additions by Zachary Brewster-Geisz

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

#import <GraphicsServices/GraphicsServices.h>
#import "FileTable.h"
#import "common.h"

@implementation FileTable

- (int)swipe:(int)type withEvent:(struct __GSEvent *)event {
  if ((_allowDelete == YES) && ((4 == type) || (8 == type))) {
    CGPoint rect = GSEventGetLocationInWindow(event);
    CGPoint point = CGPointMake(rect.x, rect.y - 45);
    CGPoint offset = _startOffset; 
    //GSLog(@"FileTable.swipe: %d %f, %f", type, point.x, point.y);

    point.x += offset.x;
    point.y += offset.y;
    int row = [ self rowAtPoint:point ];

    [ [ self visibleCellForRow:row column:0] 
       _showDeleteOrInsertion:YES 
       withDisclosure:NO
       animated:YES 
       isDelete:YES 
       andRemoveConfirmation:NO
    ];

  }
  
  return [ super swipe:type withEvent:event ];
}

- (void)allowDelete:(BOOL)allow {
    _allowDelete = allow;
}

@end

@implementation DeletableCell

- (void)removeControlWillHideRemoveConfirmation:(id)fp8 {
    [ self _showDeleteOrInsertion:NO
          withDisclosure:NO
          animated:YES
          isDelete:YES
          andRemoveConfirmation:YES
    ];
}

- (BOOL)removeControl:(id)fp8 shouldRemoveTarget:(id)cell {
  NSString *path = [self path];
  
  BOOL isDir = NO;
  BOOL bExists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
  
  if(bExists) {
    // Only delete if it's still there.
    if(![[NSFileManager defaultManager] removeFileAtPath:path handler:nil]) {
      // it exists, but we failed to delete it.  Probably a rights thing...
      CGRect rect = [[UIWindow keyWindow] bounds];
      UIAlertSheet * alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - TOOLBAR_HEIGHT, rect.size.width,240)];
      // NOTE: Leave this retained - we'll release it in the delegate callback.
      [alertSheet setTitle:@"Delete Failed"];
      [alertSheet setBodyText:[NSString stringWithFormat:@"Error deleting %@.  Perhaps user mobile lacks the rights to do so?", path]];
      [alertSheet addButtonWithTitle:@"OK"]; // buttonIdx == 1
      [alertSheet addButtonWithTitle:@"Help (Wiki)"];
      [alertSheet setDelegate: self];
      [alertSheet popupAlertAnimated:YES];
      return NO;
    }
  } // else - it was already gone, so update tables to match.

  [[NSNotificationCenter defaultCenter] postNotificationName:SHOULDDELETEFILE 
                                                      object:self
                                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                              [NSNumber numberWithBool:isDir], @"wasDirectory", nil]
   ];
  
  return YES;
}


/**
 * Button delegate method for warning sheet on file access errors.
 */
- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int)button {
	[sheet dismissAnimated:YES];
  [sheet release];
  
  if(button == 1) {
    // OK
  } else {
    // Help
    NSURL *websiteURL = [NSURL URLWithString:PERMISSION_HELP_URL_STRING];
		[UIApp openURL:websiteURL];
  }
}

- (void)_willBeDeleted {

}

- (void)setTable:(FileTable *)table {
    _table = table;
}

- (void)setFiles:(NSMutableArray *)files {
    _files = files;
}

- (NSString *)path {
        return _path;
}

- (void)setPath: (NSString *)path {
  [path retain];
  [_path release];
  _path = path;
}

@end

