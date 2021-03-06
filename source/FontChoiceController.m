// EncodingPrefsController.m, by Zachary Brewster-Geisz
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

#import "common.h"
#import "FontChoiceController.h"
#import "BoundsChangedNotification.h"

@implementation FontChoiceController

-(FontChoiceController *)init
{
	if (self = [super init])
	{
		defaults = [BooksDefaultsController sharedBooksDefaultsController];
		struct CGRect rect = [[[UIWindow keyWindow] contentView] bounds];
		//    struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
		//  rect.origin.x = rect.origin.y = 0;

		fontTable = [[UIPreferencesTable alloc] initWithFrame:CGRectMake(0,0,rect.size.width, rect.size.height-TOOLBAR_HEIGHT)];
		NSString *fontFolderPath = @"/System/Library/Fonts/";
		// If Apple ever adds the ability to add fonts to a different
		// directory, define it here.
		NSArray *fontsFolderContents = [[NSFileManager defaultManager] directoryContentsAtPath:fontFolderPath];
		NSEnumerator *enumerator = [fontsFolderContents objectEnumerator];
		NSString *currentFont;
		NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:[fontsFolderContents count]];

		// Some fonts render as an ugly default.  These are them.
		NSArray *fontsKnownToNotWork = 
			[NSArray arrayWithObjects:@"AmericanTypewriterBold.ttf",
			@"AmericanTypewriterCondensed.ttf",
			@"AmericanTypewriterCondensedBold.ttf",
			@"AmericanTypewriterCondensedLight.ttf",
			@"AmericanTypewriterLight.ttf",
			@"LockClock.ttf",
			@"MarkerFeltWide.ttf", nil];

		while (nil != (currentFont = [enumerator nextObject]))
		{
			if ([[currentFont pathExtension] isEqualToString:@"ttf"] &&
						![fontsKnownToNotWork containsObject:currentFont])
			{
				[tempArray addObject:currentFont];
			}
		}
		availableFonts = [[NSArray alloc] initWithArray:tempArray];
		[tempArray release];
		[fontTable setDelegate:self];
		[fontTable setDataSource:self];
		[fontTable reloadData];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(boundsDidChange:)
													 name:[BoundsChangedNotification didChangeName]
												   object:nil];
		//      defaults = [[BooksDefaultsController alloc] init];
	}

	return self;
}

-(void)reloadData
{
	[fontTable reloadData];
}

-(UITable *)table
{
	return fontTable;
}

- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
	return 1;
}

- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
	return [availableFonts count];
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group
{
	return @"Fonts";
}

- (float)preferencesTable:(id)preferencesTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposedHeight;
{
	return PREFS_TABLE_ROW_HEIGHT;
}

-(void)tableRowSelected:(NSNotification *)aNotification
{
	int i = [fontTable selectedRow];
	UIPreferencesTableCell *cell = [fontTable cellAtRow:i column:0];
	NSString *title = [cell title];
	int rows = [fontTable numberOfRows];

	for (i = 0; i < rows; i++)
		[[fontTable cellAtRow:i column:0] setChecked:NO];
	[cell setChecked:YES];
	[cell setSelected:NO withFade:YES];
	[[NSNotificationCenter defaultCenter] postNotificationName:NEWFONTSELECTED object:title];

}

- (id)preferencesTable:(id)preferencesTable cellForRow:(int)row inGroup:(int)group
{
	NSString *title;
	BOOL checked = NO;

	CGRect rect = [[[UIWindow keyWindow] contentView] bounds];
	UIPreferencesTableCell *theCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0,0,rect.size.width,TOOLBAR_HEIGHT)];

	//UIPreferencesTableCell *theCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0,0,320,TOOLBAR_HEIGHT)];
	[theCell setTitle:[[availableFonts objectAtIndex:row] stringByDeletingPathExtension]];
	[theCell setChecked:([[theCell title] isEqualToString:[defaults textFont]])];
	return [theCell autorelease];
}


-(void)dealloc
{
	[availableFonts release];
	[fontTable release];
	[defaults release];
	[super dealloc];
}

/**
 * Notification when our bounds change - we probably rotated.
 */
- (void)boundsDidChange:(BoundsChangedNotification*)p_note {
	struct CGRect rect = [p_note newBounds];  
	[fontTable setFrame:CGRectMake(0,0,rect.size.width, rect.size.height-TOOLBAR_HEIGHT)];
}

@end
