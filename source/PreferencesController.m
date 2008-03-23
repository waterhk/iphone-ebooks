// PreferencesView, for Books by Chris Born
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

#import "PreferencesController.h"
#import "BooksDefaultsController.h"
#import <UIKit/UIView-Animation.h>
#import "BoundsChangedNotification.h"
@implementation PreferencesController

/**
 * Notification when our bounds change - we probably rotated.
 */
- (void)boundsDidChange:(BoundsChangedNotification*)p_note
{
	GSLog(@"%s: [%s:%d]", _cmd, __FILE__, __LINE__);
	contentRect = [[[UIWindow keyWindow] contentView] bounds];
	CGRect oldFrame = [preferencesView frame];
	struct CGRect offscreenRect = CGRectMake(contentRect.origin.x,
			contentRect.size.height * (oldFrame.origin.y/oldFrame.size.height),
			contentRect.size.width,
			contentRect.size.height);
	[preferencesView setFrame:offscreenRect];
	[navigationBar setFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, TOOLBAR_HEIGHT)];
	[navigationBar setBarStyle:0];
	[navigationBar setDelegate:self]; 
	[transitionView setFrame:CGRectMake(0.0f, TOOLBAR_HEIGHT, contentRect.size.width, contentRect.size.height - TOOLBAR_HEIGHT)];
	[preferencesTable setFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, contentRect.size.height - TOOLBAR_HEIGHT)];

	UISwitchControl * invertSwitchControl = [invertPreferenceCell control];
	oldFrame = [invertSwitchControl frame];
	oldFrame.origin.x = contentRect.size.width - 114;
	[invertSwitchControl setFrame:oldFrame];
	UISwitchControl * showNavbarSwitchControl = [showNavbarPreferenceCell control];
	oldFrame = [showNavbarSwitchControl frame];
	oldFrame.origin.x = contentRect.size.width - 114;
	[showNavbarSwitchControl setFrame:oldFrame];
	UISwitchControl * showToolbarSwitchControl = [showToolbarPreferenceCell control];
	oldFrame = [showToolbarSwitchControl frame];
	oldFrame.origin.x = contentRect.size.width - 114;
	[showToolbarSwitchControl setFrame:oldFrame];
	UISwitchControl * chapterButtonsSwitchControl = [chapterButtonsPreferenceCell control];
	oldFrame = [chapterButtonsSwitchControl frame];
	oldFrame.origin.x = contentRect.size.width - 114;
	[chapterButtonsSwitchControl setFrame:oldFrame];
	UISwitchControl * pageButtonsSwitchControl = [pageButtonsPreferenceCell control];
	oldFrame = [pageButtonsSwitchControl frame];
	oldFrame.origin.x = contentRect.size.width - 114;
	[pageButtonsSwitchControl setFrame:oldFrame];
	UISwitchControl * flippedToolbarSwitchControl = [flippedToolbarPreferenceCell control];
	oldFrame = [flippedToolbarSwitchControl frame];
	oldFrame.origin.x = contentRect.size.width - 114;
	[flippedToolbarSwitchControl setFrame:oldFrame];
	UISwitchControl * invNavZoneSwitchControl = [invNavZonePreferenceCell control];
	oldFrame = [invNavZoneSwitchControl frame];
	oldFrame.origin.x = contentRect.size.width - 114;
	[invNavZoneSwitchControl setFrame:oldFrame];
	UISwitchControl * enlargeNavZoneSwitchControl = [enlargeNavZonePreferenceCell control];
	oldFrame = [enlargeNavZoneSwitchControl frame];
	oldFrame.origin.x = contentRect.size.width - 114;
	[enlargeNavZoneSwitchControl setFrame:oldFrame];
	UISwitchControl * smartConversionSwitchControl = [smartConversionPreferenceCell control];
	oldFrame = [smartConversionSwitchControl frame];
	oldFrame.origin.x = contentRect.size.width - 114;
	[smartConversionSwitchControl setFrame:oldFrame];
	UISwitchControl * renderTablesSwitchControl = [renderTablesPreferenceCell control];
	oldFrame = [renderTablesSwitchControl frame];
	oldFrame.origin.x = contentRect.size.width - 114;
	[renderTablesSwitchControl setFrame:oldFrame];
	UISwitchControl * subchapteringSwitchControl = [subchapteringPreferenceCell control];
	oldFrame = [subchapteringSwitchControl frame];
	oldFrame.origin.x = contentRect.size.width - 114;
	[subchapteringSwitchControl setFrame:oldFrame];
}

- (id)initWithAppController:(BooksApp *)appController 
{
	if(self = [super init])
	{
		controller = appController;
		contentRect = [[[UIWindow keyWindow] contentView] bounds];

		needsInAnimation = needsOutAnimation = NO;
		defaults = [BooksDefaultsController sharedBooksDefaultsController];
		_curAnimation = none;
		[self createPreferenceCells];
		[self buildPreferenceView];

	}
	return self;
}

- (void)buildPreferenceView 
{
	contentRect = [[[UIWindow keyWindow] contentView] bounds];
	if (nil == preferencesView)
	{
		GSLog(@"%s: [%s:%d] contentRect: x:%f, y:%f, w:%f, h:%f", _cmd, __FILE__, __LINE__, contentRect.origin.x, contentRect.origin.y, contentRect.size.width, contentRect.size.height);

		//Bcc the view is created bellow the screen so as to smoothly appear
		struct CGRect offscreenRect = CGRectMake(contentRect.origin.x,
				contentRect.size.height,
				contentRect.size.width,
				contentRect.size.height);
		preferencesView = [[UIView alloc] initWithFrame:offscreenRect];

		navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, TOOLBAR_HEIGHT)];
		[navigationBar showLeftButton:@"About" withStyle:0 rightButton:@"Done" withStyle:3]; // Blue Done button
		[navigationBar setBarStyle:0];
		[navigationBar setDelegate:self]; 
		[preferencesView addSubview:navigationBar];
		UINavigationItem *title = [[UINavigationItem alloc] 
			initWithTitle:@"Preferences"];
		[navigationBar pushNavigationItem:[title autorelease]];
		transitionView = [[UITransitionView alloc] initWithFrame:CGRectMake(0.0f, TOOLBAR_HEIGHT, contentRect.size.width, contentRect.size.height - TOOLBAR_HEIGHT)];	

		preferencesTable = [[UIPreferencesTable alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, contentRect.size.height - TOOLBAR_HEIGHT)];	
		[preferencesTable setDataSource:self];
		[preferencesTable setDelegate:self];
		[preferencesView addSubview:transitionView];
		[transitionView transition:0 toView:preferencesTable];
		UIWindow	*mainWindow = [controller appsMainWindow];
		appView = [[mainWindow contentView] retain];

		//	[mainWindow setContentView:preferencesView];
		[appView addSubview:preferencesView];
		translate = [[UITransformAnimation alloc] initWithTarget:preferencesView];
		animator = [[UIAnimator alloc] init];
		[[NSNotificationCenter defaultCenter]
			addObserver:self
			   selector:@selector(checkForAnimation:)
				   name:PREFS_NEEDS_ANIMATE
				 object:nil];

		[[NSNotificationCenter defaultCenter]
			addObserver:self
			   selector:@selector(shouldTransitionBackToPrefsView:)
				   name:ENCODINGSELECTED
				 object:nil];

		[[NSNotificationCenter defaultCenter]
			addObserver:self
			   selector:@selector(shouldTransitionBackToPrefsView:)
				   name:NEWFONTSELECTED
				 object:nil];
		GSLog(@"%s: [%s:%d] registerign for notification change", _cmd, __FILE__, __LINE__);
		[[NSNotificationCenter defaultCenter] 
			addObserver:self
			   selector:@selector(boundsDidChange:)
				   name:[BoundsChangedNotification didChangeName]
				 object:nil];

	} // if nil == preferencesView
	else
	{
		[self boundsDidChange:nil];
	}

	[preferencesTable reloadData];
}

- (void)showPreferences {
	needsInAnimation = YES;
	[[NSNotificationCenter defaultCenter] 
		postNotificationName:PREFS_NEEDS_ANIMATE
					  object:self];

}

- (void) animator:(UIAnimator *) animator stopAnimation:(UIAnimation *) animation
{
	//GSLog(@"animator called");
	if (_curAnimation == outAnim)
	{
		[controller preferenceAnimationDidFinish];
		[preferencesView removeFromSuperview];
	}
	_curAnimation = none;
}


- (void)checkForAnimation:(id)unused
{
	if (needsInAnimation)
	{
		//GSLog(@"prefs animation in");
		struct CGRect offscreenRect = CGRectMake(contentRect.origin.x,
				contentRect.size.height,
				contentRect.size.width,
				contentRect.size.height);
		[preferencesView setFrame:offscreenRect];

		struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, -contentRect.size.height);
		[translate setStartTransform:CGAffineTransformMake(1,0,0,1,0,0)];
		[translate setEndTransform:trans];
		[translate setDelegate:self];
		_curAnimation = inAnim;
		[animator addAnimation:translate withDuration:0.5 start:YES]; 
		needsInAnimation = NO;
	}
	else if (needsOutAnimation)
	{
		//BCC the contentRect may have changed let's update it
		//GSLog(@"prefs animation out");
		[preferencesView setFrame:contentRect];
		struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, -contentRect.size.height);
		[translate setStartTransform:trans];
		[translate setEndTransform:CGAffineTransformIdentity];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:)];
		[translate setDelegate:self];
		_curAnimation = outAnim;
		[animator addAnimation:translate withDuration:0.5 start:YES];
		needsOutAnimation = NO;
	}
}

- (void)shouldTransitionBackToPrefsView:(NSNotification *)aNotification
{
	[transitionView transition:2 toView:preferencesTable];
	[navigationBar popNavigationItem];
	NSString *notifyName = [aNotification name];
	NSString *newValue = [aNotification object];
	if ([notifyName isEqualToString:ENCODINGSELECTED])
	{
		if (![newValue isEqualToString:[defaultEncodingPreferenceCell value]])
		{
			[defaultEncodingPreferenceCell setValue:newValue];
		}
		[defaultEncodingPreferenceCell setSelected:NO];
	}
	else
	{
		if (![newValue isEqualToString:[fontChoicePreferenceCell value]])
		{
			[fontChoicePreferenceCell setValue:newValue];
		}
		[fontChoicePreferenceCell setSelected:NO];
	}
}

- (void)hidePreferences {
	// Save defaults here
	NSString *proposedFont = [fontChoicePreferenceCell value];
	if (![proposedFont isEqualToString:[defaults textFont]])
	{
		[defaults setTextFont:proposedFont];
	}
	//GSLog(@"%s Font: %@", _cmd, [self fontNameForIndex:[fontChoiceControl selectedSegment]]);
	int proposedSize = [[fontSizePreferenceCell value] intValue];
	proposedSize = (proposedSize > MAX_FONT_SIZE) ? MAX_FONT_SIZE : proposedSize;
	proposedSize = (proposedSize < MIN_FONT_SIZE) ? MIN_FONT_SIZE : proposedSize;
	if ([defaults textSize] != proposedSize)
	{
		[defaults setTextSize: proposedSize];
	}

	BOOL proposedInverted = [[[invertPreferenceCell control] valueForKey:@"value"] boolValue];
	if ([defaults inverted] != proposedInverted)
	{
		[defaults setInverted:proposedInverted];
	}

	[defaults setToolbar:[[[showToolbarPreferenceCell control] valueForKey:@"value"] boolValue]];

	[defaults setNavbar:[[[showNavbarPreferenceCell control] valueForKey:@"value"] boolValue]];

	[defaults setChapternav:[[[chapterButtonsPreferenceCell control] valueForKey:@"value"] boolValue]];

	[defaults setPagenav:[[[pageButtonsPreferenceCell control] valueForKey:@"value"] boolValue]];

	[defaults setFlipped:[[[flippedToolbarPreferenceCell control] valueForKey:@"value"] boolValue]];

	[defaults setInverseNavZone:[[[invNavZonePreferenceCell control] valueForKey:@"value"] boolValue]];

	[defaults setEnlargeNavZone:[[[enlargeNavZonePreferenceCell control] valueForKey:@"value"] boolValue]];

	//FIXME: these three  should make the text refresh
	[defaults setSmartConversion:[[[smartConversionPreferenceCell control] valueForKey:@"value"] boolValue]];

	[defaults setRenderTables:[[[renderTablesPreferenceCell control] valueForKey:@"value"] boolValue]];

	[defaults setSubchapteringEnabled:[[[subchapteringPreferenceCell control] valueForKey:@"value"] boolValue]];

	[defaults setScrollSpeedIndex:[scrollSpeedControl selectedSegment]];


	if ([defaults synchronize]){
		GSLog(@"Synced defaults from prefs pane.");
	}

	needsOutAnimation = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:PREFS_NEEDS_ANIMATE object:self];

}

- (void)createPreferenceCells {

	// Font
	fontChoicePreferenceCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0, 0, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];

	NSString *fontString = [defaults textFont];
	[fontChoicePreferenceCell setTitle:@"Font"];
	[fontChoicePreferenceCell setValue:fontString];
	[fontChoicePreferenceCell setShowDisclosure:YES];

	// Text Display
	fontSizePreferenceCell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, PREFS_TABLE_ROW_HEIGHT, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	NSString	*str = [NSString stringWithFormat:@"%d",[defaults textSize]];
	[fontSizePreferenceCell setValue:str];
	[fontSizePreferenceCell setTitle:@"Font Size"];


	invertPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	BOOL inverted = [defaults inverted];
	[invertPreferenceCell setTitle:@"Invert Color"];
	UISwitchControl *invertSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, PREFS_TABLE_ROW_HEIGHT)] autorelease];
	[invertSwitchControl setValue:inverted];
	[invertPreferenceCell setControl:invertSwitchControl];

	// Auto-Hide
	showNavbarPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	BOOL navbar = [defaults navbar];
	[showNavbarPreferenceCell setTitle:@"Navigation Bar"];
	UISwitchControl *showNavbarSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, PREFS_TABLE_ROW_HEIGHT)] autorelease];
	[showNavbarSwitchControl setValue:navbar];
	[showNavbarPreferenceCell setControl:showNavbarSwitchControl];

	showToolbarPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	BOOL toolbar = [defaults toolbar];
	[showToolbarPreferenceCell setTitle:@"Bottom Toolbar"];
	UISwitchControl *showToolbarSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, PREFS_TABLE_ROW_HEIGHT)] autorelease];
	[showToolbarSwitchControl setValue:toolbar];
	[showToolbarPreferenceCell setControl:showToolbarSwitchControl];

	// Toolbar Options
	chapterButtonsPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	BOOL chapternav = [defaults chapternav];
	[chapterButtonsPreferenceCell setTitle:@"Chapter Navigation"];
	UISwitchControl *chapterButtonsSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, PREFS_TABLE_ROW_HEIGHT)] autorelease];
	[chapterButtonsSwitchControl setValue:chapternav];
	[chapterButtonsSwitchControl setAlternateColors:YES];
	[chapterButtonsPreferenceCell setControl:chapterButtonsSwitchControl];

	pageButtonsPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	BOOL pagenav = [defaults pagenav];
	[pageButtonsPreferenceCell setTitle:@"Page Navigation"];
	UISwitchControl *pageButtonsSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, PREFS_TABLE_ROW_HEIGHT)] autorelease];
	[pageButtonsSwitchControl setValue:pagenav];
	[pageButtonsSwitchControl setAlternateColors:YES];
	[pageButtonsPreferenceCell setControl:pageButtonsSwitchControl];

	flippedToolbarPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	BOOL flipped = [defaults flipped];
	[flippedToolbarPreferenceCell setTitle:@"Left Handed"];
	UISwitchControl *flippedToolbarSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, PREFS_TABLE_ROW_HEIGHT)] autorelease];
	[flippedToolbarSwitchControl setValue:flipped];
	[flippedToolbarSwitchControl setAlternateColors:YES];
	[flippedToolbarPreferenceCell setControl:flippedToolbarSwitchControl];	

	invNavZonePreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	BOOL invertedZones = [defaults inverseNavZone];
	[invNavZonePreferenceCell setTitle:@"invert nav zone"];
	UISwitchControl *invNavZoneSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, PREFS_TABLE_ROW_HEIGHT)] autorelease];
	[invNavZoneSwitchControl setValue:invertedZones];
	[invNavZoneSwitchControl setAlternateColors:YES];
	[invNavZonePreferenceCell setControl:invNavZoneSwitchControl];	

	enlargeNavZonePreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	BOOL enlargedZones = [defaults enlargeNavZone];
	[enlargeNavZonePreferenceCell setTitle:@"enlarge nav zone"];
	UISwitchControl *enlargeNavZoneSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, PREFS_TABLE_ROW_HEIGHT)] autorelease];
	[enlargeNavZoneSwitchControl setValue:enlargedZones];
	[enlargeNavZoneSwitchControl setAlternateColors:YES];
	[enlargeNavZonePreferenceCell setControl:enlargeNavZoneSwitchControl];	

	//CHANGED: Zach's additions 9/6/07

	defaultEncodingPreferenceCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0, 0, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];

	NSString *encString;
	NSStringEncoding enc = [defaults defaultTextEncoding];
	if (AUTOMATIC_ENCODING == enc)
		encString = @"Automatic";
	else
		encString = [NSString localizedNameOfStringEncoding:enc];

	[defaultEncodingPreferenceCell setTitle:@"Text Encoding"];
	[defaultEncodingPreferenceCell setValue:encString];
	[defaultEncodingPreferenceCell setShowDisclosure:YES];

	smartConversionPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(20.0f, 3.0f, 280.0f, 55.0f)];
	NSString *smartconvwithquotes = [NSString stringWithFormat:@"%CSmart%C conversion", 0x201C, 0x201D];  // because I love me some curly quotes
	[smartConversionPreferenceCell setTitle:smartconvwithquotes];
	UISwitchControl *smartConversionSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, PREFS_TABLE_ROW_HEIGHT)] autorelease];
	[smartConversionSwitchControl setValue:[defaults smartConversion]];
	[smartConversionPreferenceCell setControl:smartConversionSwitchControl];

	renderTablesPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(20.0f, 3.0f, 280.0f, 55.0f)];
	[renderTablesPreferenceCell setTitle:@"Render HTML tables"];
	UISwitchControl *renderTablesSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, PREFS_TABLE_ROW_HEIGHT)] autorelease];
	[renderTablesSwitchControl setValue:[defaults renderTables]];
	[renderTablesPreferenceCell setControl:renderTablesSwitchControl];

	subchapteringPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(20.0f, 3.0f, 280.0f, 55.0f)];
	[subchapteringPreferenceCell setTitle:@"Subchapter HTML"];
	UISwitchControl *subchapteringSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, PREFS_TABLE_ROW_HEIGHT)] autorelease];
	[subchapteringSwitchControl setValue:[defaults subchapteringEnabled]];
	[subchapteringPreferenceCell setControl:subchapteringSwitchControl];

	scrollSpeedControl = [[[UISegmentedControl alloc] initWithFrame:CGRectMake(20.0f, 3.0f, 280.0f, 55.0f)] autorelease];
	[scrollSpeedControl insertSegment:0 withTitle:@"Slow" animated:NO];
	[scrollSpeedControl insertSegment:1 withTitle:@"Fast" animated:NO];
	[scrollSpeedControl insertSegment:2 withTitle:@"Instant" animated:NO];
	[scrollSpeedControl selectSegment:[defaults scrollSpeedIndex]];
	scrollSpeedPreferenceCell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	[scrollSpeedPreferenceCell setDrawsBackground:NO];
	[scrollSpeedPreferenceCell addSubview:scrollSpeedControl];



	markCurrentBookAsNewCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0, 0, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	[markCurrentBookAsNewCell setTitle:@"Mark Current Folder as New"];
	[markCurrentBookAsNewCell setShowDisclosure:NO];

	markAllBooksAsNewCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0, 0, contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	[markAllBooksAsNewCell setTitle:@"Mark All Books as New"];
	[markAllBooksAsNewCell setShowDisclosure:NO];

	toBeAnnouncedCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0,0,contentRect.size.width, PREFS_TABLE_ROW_HEIGHT)];
	[toBeAnnouncedCell setTitle:@"Coming soon"];
	[toBeAnnouncedCell setShowDisclosure:NO];
}

- (void)tableRowSelected:(NSNotification *)notification 
{
	int i = [preferencesTable selectedRow];
	GSLog(@"Selected!Prefs! Row %d!", i);
	switch (i)
	{
		case 1: // font
			[self makeFontPrefsPane];
			break;
		case 14: // text encoding
			[self makeEncodingPrefsPane];
			break;
		case 21: // mark current book as new
			GSLog(@"mark current book as new");
			[defaults removePerFileDataForDirectory:[controller currentBrowserPath]];
			[[NSNotificationCenter defaultCenter] postNotificationName:RELOADTOPBROWSER object:self];
			[markCurrentBookAsNewCell setEnabled:NO];
			[markCurrentBookAsNewCell setSelected:NO withFade:YES];
			break;
		case 22: // mark all books as new
			GSLog(@"mark all book as new");
			[defaults removePerFileDataForDirectory:[controller currentBrowserPath]];
			[defaults removePerFileData];
			[[NSNotificationCenter defaultCenter] postNotificationName:RELOADTOPBROWSER object:self];
			[markAllBooksAsNewCell setEnabled:NO];
			[markAllBooksAsNewCell setSelected:NO withFade:YES];
			break;
		default:
	  [[preferencesTable cellAtRow:i column:0] setSelected:NO];
	  break;
	}
}

- (void)makeEncodingPrefsPane
{
	UINavigationItem *encodingItem = [[UINavigationItem alloc] initWithTitle:@"Text Encoding"];
	if (nil == encodingPrefs)
		encodingPrefs = [[EncodingPrefsController alloc] init];
	//GSLog(@"pushing nav item...");
	[navigationBar pushNavigationItem:encodingItem];
	//GSLog(@"attempting transition...");
	[transitionView transition:1 toView:[encodingPrefs table]];

	//GSLog(@"attempted transition...");
	[encodingPrefs reloadData];
	[encodingItem release];
	//  [encodingPrefs autorelease];
}

- (void)makeFontPrefsPane
{
	UINavigationItem *fontItem = [[UINavigationItem alloc] initWithTitle:@"Font"];
	if (nil == fontChoicePrefs)
		fontChoicePrefs = [[FontChoiceController alloc] init];
	//GSLog(@"pushing nav item...");
	[navigationBar pushNavigationItem:fontItem];
	//GSLog(@"attempting transition...");
	[transitionView transition:1 toView:[fontChoicePrefs table]];

	//GSLog(@"attempted transition...");
	[fontChoicePrefs reloadData];
	[fontItem release];
	//  [encodingPrefs autorelease];
}

- (void)aboutAlert { // I like it, good idea.
	NSString *version = [[NSBundle mainBundle]
		objectForInfoDictionaryKey:@"CFBundleVersion"];
	if (nil == version)
		version = @"??";
	NSString *bodyText = [NSString stringWithFormat:@"Books.app version %@, by Zachary Brewster-Geisz, Chris Born, Benoit Cerrina, and Zachary Bedell.", version];
	CGRect rect = [[UIWindow keyWindow] bounds];
	alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,rect.size.height - 240, rect.size.width,240)];
	[alertSheet setTitle:@"About Books"];
	[alertSheet setBodyText:bodyText];
	[alertSheet addButtonWithTitle:@"Website"];
	[alertSheet addButtonWithTitle:@"OK"];
	[alertSheet setDelegate: self];
	[alertSheet popupAlertAnimated:YES];
}

// TODO: Figure out the UIFontChooser and let them choose anything. Important for internationalization

- (int)currentFontIndex {

	NSString	*font = [defaults textFont];	
	if ([font isEqualToString:@"TimesNewRoman"]) {
		return TIMES;
	} else if ([font isEqualToString:@"Helvetica"]) {
		return HELVETICA;
	} else if ([font isEqualToString:@"Georgia"]) {
		return GEORGIA;
	} else {
		return TIMES;
	}
}

- (NSString *)fontNameForIndex:(int)index {
	NSString 	*font;
	switch (index)
	{
		case 0:
			font = [NSString stringWithString:@"Georgia"];
			break;
		case 1:
			font = [NSString stringWithString:@"Helvetica"];
			break;
		case 2:
			font = [NSString stringWithString:@"TimesNewRoman"];
			break;	
	}
	GSLog(@"%s Font selected is %@", _cmd, font);
	return font;
}


// Delegate methods
- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int)button {
	if (sheet == alertSheet) {
		GSLog(@"%s", _cmd);
	} else {
		GSLog(@"%s", _cmd);
	}
	[sheet dismissAnimated:YES];
	if (1 == button)
	{
		NSURL *websiteURL = [NSURL URLWithString:WEBSITE_URL_STRING];
		[controller openURL:websiteURL];
	}
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
{
	//GSLog(@"curanim %d", (int)_curAnimation);
	//GSLog(@"none %d, inAnim %d, outAnim %d", (int)none, (int)inAnim, (int)outAnim);
	if (_curAnimation == none)
	{
		switch (button) 
		{
			case 0: // Changed to comport with Apple's UI
				[self hidePreferences]; 
				break;
			case 1:
				[self aboutAlert];
				break;
		}
	}

}

- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
	return 6;
}

- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
	int rowCount = 0;
	switch (group)
	{
		case 0: //text display
			rowCount = 3;
			break;
		case 1: //auto-hide
			rowCount = 2;
			break;
		case 2: //toolbar options
			rowCount = 5;
			break;
		case 3: //file import
			rowCount = 4;
			break;
		case 4: //tap-scroll speed
			rowCount = 1;
			break;
		case 5: //new books
			rowCount = 2;
			break;
	}
	return rowCount;
}

- (id)preferencesTable:(id)preferencesTable cellForRow:(int)row inGroup:(int)group
{
	GSLog(@"PreferencesController: cellForRow:%d inGroup:%d", row, group);
	id prefCell = nil;
	switch (group)
	{
		case 0:
			switch (row)
			{
				case 0:
					prefCell = fontChoicePreferenceCell;
					break;
				case 1: 
					prefCell = fontSizePreferenceCell;
					break;
				case 2:
					prefCell = invertPreferenceCell;
					break;
			}
			break;
		case 1:
			switch (row)
			{
				case 0:
					prefCell = showNavbarPreferenceCell;
					break;
				case 1:
					prefCell = showToolbarPreferenceCell;
					break;
			}
			break;
		case 2:
			switch (row)
			{
				case 0:
					prefCell = chapterButtonsPreferenceCell;
					break;
				case 1:
					prefCell = pageButtonsPreferenceCell;
					break;
				case 2:
					prefCell = flippedToolbarPreferenceCell;
					break;
				case 3:
					prefCell = invNavZonePreferenceCell;
					break;
				case 4:
					prefCell = enlargeNavZonePreferenceCell;
					break;
			}
			break;
		case 3:
			switch (row)
			{
				case 0:
					prefCell = defaultEncodingPreferenceCell;
					break;
				case 1:
					prefCell = smartConversionPreferenceCell;
					break;
				case 2:
					prefCell = renderTablesPreferenceCell;
					break;
				case 3:
					prefCell = subchapteringPreferenceCell;
					break;
			}
			break;
		case 4:
			switch (row)
			{
				case 0:
					prefCell = scrollSpeedPreferenceCell;
					break;
			}
			break;
		case 5:
			switch (row)
			{
				case 0:
					prefCell = markCurrentBookAsNewCell;
					break;
				case 1:
					prefCell = markAllBooksAsNewCell;
					break;
			}
			break;
	}
	return prefCell;
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group
{
	NSString *title = nil;
	switch (group)
	{
		case 0:
			title = @"Text Display";
			break;
		case 1:
			title = @"Auto-Hide";
			break;
		case 2:
			title = @"Toolbar Options";
			break;
		case 3:
			title = @"File Import";
			break;
		case 4:
			title = @"Tap-Scroll Speed";
			break;
		case 5:
			title = @"New Books";
			break;
	}
	return title;
}

- (float)preferencesTable:(id)preferencesTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposedHeight;
{
	return 48.0f;
}



	- (void)dealloc {
		if (preferencesView != nil)
		{
			[[NSNotificationCenter defaultCenter] removeObserver:self];
			[preferencesView release];
			[appView release];
			[preferencesTable release];
			[translate release];
			[animator release];
			[transitionView release];
			[navigationBar release];
		}
		if (encodingPrefs != nil)
			[encodingPrefs release];
		if (fontChoicePrefs != nil)
			[fontChoicePrefs release];
		[defaults release];
		[controller release];
		[super dealloc];
	}

@end
