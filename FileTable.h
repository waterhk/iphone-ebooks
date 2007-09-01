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
#import <UIKit/UIImageAndTextTableCell.h>

#define SHOULDDELETEFILE @"FileBrowserShouldDeleteFile"
#define PATHTODELETE @"FileBrowserFullPathToDelete"

@interface FileTable : UITable
{
    BOOL _allowDelete;
}

- (void)allowDelete:(BOOL)allow;

@end


@interface DeletableCell : UIImageAndTextTableCell 
{
    FileTable *_table;
    NSString *_path;
    NSMutableArray *_files; 
}

- (void)setTable:(FileTable *)table;
- (void)setFiles:(NSMutableArray *)_files;
- (void)setPath: (NSString *)path;
- (NSString *)path;

@end
