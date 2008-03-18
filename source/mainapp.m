/* Books.app, (c)2007 by Zachary Brewster-Geisz
 
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
#import "BooksApp.h"
#import "common.h"

int main(int argc, char **argv) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // Only log if the log file already exists!
  if([[NSFileManager defaultManager] fileExistsAtPath:OUT_FILE]) {
    // Do this here instead of in BooksApp so we can get the UIApp startup stuff too.
    freopen([OUT_FILE fileSystemRepresentation], "a", stderr);
    freopen([OUT_FILE fileSystemRepresentation], "a", stdout);
    
    //[[NSNotificationCenter defaultCenter] addObserver:[BooksApp class] selector:@selector(debugNotification:) name:nil object:nil];
  }
  
  int ret = UIApplicationMain(argc, argv, [BooksApp class]);
  [pool release];
  return ret;
}
