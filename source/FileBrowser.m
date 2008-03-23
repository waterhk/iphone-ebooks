/* FileBrowser, by Stephan White
 Adapted for Books.app by Zachary Brewster-Geisz
 
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
#import <UIKit/UIImageAndTextTableCell.h>

#import "FileBrowser.h"
#import "HTMLFixer.h"
#import "BoundsChangedNotification.h"
#import "common.h"

@implementation FileBrowser 
- (id)initWithFrame:(struct CGRect)frame {
	if ((self == [super initWithFrame: frame]) != nil) {
		UITableColumn *col = [[UITableColumn alloc]
                          initWithTitle: @"FileName"
                          identifier:@"filename"
                          width: frame.size.width
                          ];
		float components[4] = {1.0, 1.0, 1.0, 1.0};
		struct CGColor *white = CGColorCreate(CGColorSpaceCreateDeviceRGB(), components);
		[self setBackgroundColor:white];
    
		_table = [[FileTable alloc] initWithFrame: CGRectMake(0, TOOLBAR_HEIGHT, frame.size.width, frame.size.height - TOOLBAR_HEIGHT)]; 
		[_table addTableColumn: col];
		[_table setSeparatorStyle: 1];
		[_table setDelegate: self];
		[_table setDataSource: self];
		[_table allowDelete:YES];
    [_table setAllowSelectionDuringRowDeletion:NO];
    
		_files = [[NSMutableArray alloc] init];
		_rowCount = 0;
    
		_delegate = nil;
    
		defaults = [BooksDefaultsController sharedBooksDefaultsController];
		[self addSubview: _table];
    
    [self setAutoresizesSubviews:NO];
    
		[[NSNotificationCenter defaultCenter] 
     addObserver:self
     selector:@selector(shouldDeleteFileFromCell:)
     name:SHOULDDELETEFILE
     object:nil];
    
		[[NSNotificationCenter defaultCenter] 
     addObserver:self
     selector:@selector(shouldReloadThisCell:)
     name:OPENEDTHISFILE
     object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boundsDidChange:)
                                                 name:[BoundsChangedNotification didChangeName]
                                               object:nil];
    
    
	}
	return self;
}

/**
 * Enable or disable interaction with the table.
 */
- (void)setEnabled:(BOOL)p_enabled {
  if(p_enabled) {
    [_table _enableInteraction];
  } else {
    [_table _disableInteraction];
  }
}

/**
 * Notification when our bounds change - we probably rotated.
 */
- (void)boundsDidChange:(BoundsChangedNotification*)p_note {
  struct CGRect newRect = [p_note newBounds];  
  [self setFrame:newRect];
  [_table setFrame:CGRectMake(0, TOOLBAR_HEIGHT, newRect.size.width, newRect.size.height - TOOLBAR_HEIGHT)];
}

/**
 * Cleanup.
 */
- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  
	[_path release];
	[_files release];
	[_extensions release];
	[_table release];
	_delegate = nil;
	[super dealloc];
}

- (NSString *)path {
	return _path;
}

- (void)setPath: (NSString *)path {
  [path retain];
	[_path release];
	_path = path;
	[self reloadData];
}

/**
 * Set the file extensions that will be displayed in this table.
 */
- (void)setExtensions: (NSArray *)extensions {
	[extensions retain];
  [_extensions release];
  _extensions = extensions;
}

/**
 * Re-read the current path and setup data for the datasource accordingly.
 */
- (void)reloadData {
	NSFileManager *fileManager = [NSFileManager defaultManager];    
  NSArray *tempArray = [fileManager directoryContentsAtPath:_path];
 	
  [_files removeAllObjects];
    
  NSString *file;
  NSEnumerator *dirEnum = [tempArray objectEnumerator];
	while (file = [dirEnum nextObject]) {
	  if ([file characterAtIndex:0] != (unichar)'.') {
      // Skip invisibles, like .DS_Store
      BOOL isDir = NO;
      if([fileManager fileExistsAtPath:[_path stringByAppendingPathComponent:file] isDirectory:&isDir]) {
        if(isDir) {
          [_files addObject:file];  //Always add visible directories!
        } else if(_extensions != nil) {
          NSString *extension = [[file pathExtension] lowercaseString];
          if ([_extensions containsObject:extension]) {
            [_files addObject: file];
          }
        } else {
          [_files addObject: file];
        }
      }
    }
 	}
  
	[_files sortUsingFunction:&numberCompare context:NULL];
	_rowCount = [_files count];
	[_table reloadData];
}

/**
 * Custom comparator to sort images below document files.
 */
int numberCompare(id firstString, id secondString, void *context) {
  // Texts should always come before pictures in the list.
  BOOL firstFileIsPicture = [HTMLFixer isDocumentImage:firstString];
  BOOL secondFileIsPicture = [HTMLFixer isDocumentImage:secondString];

  if (firstFileIsPicture && !secondFileIsPicture) {
    return NSOrderedDescending;
  } else if (!firstFileIsPicture && secondFileIsPicture) {
    return NSOrderedAscending;
  } else {
    return [firstString compare:secondString options:(NSNumericSearch | NSCaseInsensitiveSearch)];
  }
}


- (void)setDelegate:(id)delegate {
	_delegate = delegate;
}

- (int)numberOfRowsInTable:(UITable *)table {
	return _rowCount;
}

- (UITableCell *)table:(UITable *)table cellForRow:(int)row column:(UITableColumn *)col {
  BOOL isDir = NO;
	DeletableCell *cell = [[DeletableCell alloc] init];
	NSString *fullPath = [_path stringByAppendingPathComponent:[_files objectAtIndex:row]];
	[cell setPath:fullPath];
	if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir] && isDir)
  {
    [cell setTitle: [_files objectAtIndex: row]];
    [cell setShowDisclosure:YES];
    NSString *coverartPath = [EBookImageView coverArtForBookPath:fullPath];
    if (nil != coverartPath)
    {
      UIImage *coverart = [UIImage imageAtPath:coverartPath];
      struct CGImage *coverRef = [coverart imageRef];
      int height = CGImageGetHeight(coverRef);
      int width = CGImageGetWidth(coverRef);
      if (height >= width)
      {
        float frac = (float)width / height;
        width = (int)(46*frac);
        height = 46;
      }
      else
      {
        float frac = (float)height / width;
        height = (int)(46*frac);
        width = 46;
      }
      //GSLog("new w: %d h: %d", width, height);
      [cell setImage:coverart];
      [[cell iconImageView] setFrame:CGRectMake(-10,0,width,height)];
    }
  }
	else if (![defaults dataExistsForFile:fullPath])
  {
    //FIXME: It'd be great to have unread indicators for directories,
	  //a la podcast dirs & episodes.  For now, unread indicators only
	  //apply for text/HTML files.
    [cell setTitle: [[_files objectAtIndex: row] stringByDeletingPathExtension]];
    UIImage *img = [UIImage applicationImageNamed:@"UnreadIndicator.png"];
    [cell setImage:img];
  }
	else // just to make things look nicer.
  {
    [cell setTitle: [[_files objectAtIndex: row] stringByDeletingPathExtension]];
    
    UIImage *img2 = [UIImage applicationImageNamed:@"ReadIndicator.png"];
    [cell setImage:img2];
    
  }
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

- (void)shouldReloadThisCell:(NSNotification *)aNotification {
  NSString *theFilepath = [aNotification object];
  NSString *basePath = [theFilepath stringByDeletingLastPathComponent];
  if ([basePath isEqualToString:_path]) {
    [self reloadCellForFilename:theFilepath];
  }
}

- (void)reloadCellForFilename:(NSString *)thePath {
  NSString *filename = [thePath lastPathComponent];
  int i;
  for (i = 0; i < _rowCount ; i++) {
    if ([filename isEqualToString:[_files objectAtIndex:i]]) {
      [_table reloadCellAtRow:i column:0 animated:NO];
      return;
    }
  }
}

- (NSString *)fileBeforeFileNamed:(NSString *)thePath
{
  int theRow = -1;
  NSString *filename = [thePath lastPathComponent];
  int i;
  for (i = 0; i < _rowCount ; i++)
  {
    if ([filename isEqualToString:[_files objectAtIndex:i]])
    {
      theRow = i;
    }
  }
  if (theRow < 1)
    return nil;
  
  return [_path stringByAppendingPathComponent: 
          [_files objectAtIndex: theRow - 1]];
}


- (NSString *)fileAfterFileNamed:(NSString *)thePath
{
  int theRow = -1;
  NSString *filename = [thePath lastPathComponent];
  int i;
  for (i = 0; i < _rowCount ; i++)
  {
    if ([filename isEqualToString:[_files objectAtIndex:i]])
    {
      theRow = i;
    }
  }
  if ((theRow < 0) || (theRow+1 >= _rowCount))
    return nil;
  
  return [_path stringByAppendingPathComponent: 
          [_files objectAtIndex: theRow + 1]];
}

/**
 * Triggered by notification from the FilTable.  Deletes the file
 * and updates the table datasource to match.
 */
- (void)shouldDeleteFileFromCell:(NSNotification *)aNotification {
  DeletableCell *theCell = (DeletableCell *)[aNotification object];
  NSString *path = [theCell path];
  BOOL isDir = [(NSNumber*)[[aNotification userInfo] objectForKey:@"wasDirectory"] boolValue];
  
  if([_files containsObject:[path lastPathComponent]]) {
    // FIXME:This could cause side effects in the rare case where a
    // FileBrowser contains cells with the same name!!!!
    
    // Clean up settings for the file/directory
    if(isDir) {
      [defaults removePerFileDataForDirectory:path];
    } else {
      [defaults removePerFileDataForFile:path];
    }
  }
  
  // Remove it from the list
  [_files removeObject:[path lastPathComponent]];
  _rowCount--;
  // FIXME: Need a reloadData here?
}

@end
