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

#import "FileBrowser.h"
#import <UIKit/UISimpleTableCell.h>

@implementation FileBrowser 
- (id)initWithFrame:(struct CGRect)frame{
	if ((self == [super initWithFrame: frame]) != nil) {
		UITableColumn *col = [[UITableColumn alloc]
			initWithTitle: @"FileName"
			identifier:@"filename"
			width: frame.size.width
		];
		float components[4] = {1.0, 1.0, 1.0, 1.0};
		struct CGColor *white = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
		[self setBackgroundColor:white];
		_table = [[UITable alloc] initWithFrame: CGRectMake(0, 48.0f, frame.size.width, frame.size.height - 48.0f)]; //assume we have a bottom navbar !let's not
		[_table addTableColumn: col];
		[_table setSeparatorStyle: 1];
		[_table setDelegate: self];
		[_table setDataSource: self];

		_extensions = [[NSMutableArray alloc] init];
		_files = [[NSMutableArray alloc] init];
		_rowCount = 0;

		_delegate = nil;

		[self addSubview: _table];
	}
	return self;
}

- (void)dealloc {
	[_path release];
	[_files release];
	[_extensions release];
	[_table release];
	_delegate = nil;
	[super dealloc];
}

- (NSString *)path {
	return [[_path retain] autorelease];
}

- (void)setPath: (NSString *)path {
	[_path release];
	_path = [path copy];

	[self reloadData];
}

- (void)addExtension: (NSString *)extension {
	if (![_extensions containsObject:[extension lowercaseString]]) {
		[_extensions addObject: [extension lowercaseString]];
	}
}

- (void)setExtensions: (NSArray *)extensions {
	[_extensions setArray: extensions];
}

- (void)reloadData {
        BOOL isDir;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSArray *tempArray = [[NSArray alloc] initWithArray:[fileManager directoryContentsAtPath:_path]];

	if ([fileManager fileExistsAtPath: _path] == NO) {
		return;
	}

	[_files removeAllObjects];

        NSString *file;
        NSEnumerator *dirEnum = [tempArray objectEnumerator];
	while (file = [dirEnum nextObject]) {
	  if ([file characterAtIndex:0] != (unichar)'.')
	    {  // Skip invisibles, like .DS_Store
	      if (_extensions != nil && [_extensions count] > 0) {
		NSString *extension = [[file pathExtension] lowercaseString];
		if ([_extensions containsObject: extension]) {
		  [_files addObject: file];
		}
		} else {
			[_files addObject: file];
		}
	    }
 	}

	[_files sortUsingFunction:&numberCompare context:NULL];
	_rowCount = [_files count];
	[_table reloadData];
	[tempArray release];
}

int numberCompare(id firstString, id secondString, void *context)
{
  return [firstString compare:secondString options:NSNumericSearch];
}

- (void)setDelegate:(id)delegate {
	_delegate = delegate;
}

- (int)numberOfRowsInTable:(UITable *)table {
	return _rowCount;
}

- (UITableCell *)table:(UITable *)table cellForRow:(int)row column:(UITableColumn *)col {
        BOOL isDir = NO;
	UISimpleTableCell *cell = [[UISimpleTableCell alloc] init];
	[cell setTitle: [[_files objectAtIndex: row] stringByDeletingPathExtension]];
	if ([[NSFileManager defaultManager] fileExistsAtPath:[_path stringByAppendingPathComponent:[_files objectAtIndex:row]] isDirectory:&isDir] && isDir)
	     [cell setShowDisclosure:YES];
	return cell;
}

- (void)tableRowSelected:(NSNotification *)notification {
	if( [_delegate respondsToSelector:@selector( fileBrowser:fileSelected: )] )
		[_delegate fileBrowser:self fileSelected:[self selectedFile]];
}

- (NSString *)selectedFile {
	if ([_table selectedRow] == -1)
		return nil;

	return [_path stringByAppendingPathComponent: [_files objectAtIndex: [_table selectedRow]]];
}

@end
