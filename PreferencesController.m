// PreferencesView, for Books by Chris Born

#import "PreferencesController.h"

@implementation PreferencesController

- (id)initWithAppController:(BooksApp *)appController {
	if(self = [super init])
	{
		controller = appController;
		contentRect = [UIHardware fullScreenApplicationContentRect];
		contentRect.origin.x = 0.0f;
		contentRect.origin.y = 0.0f;

		needsInAnimation = needsOutAnimation = NO;
		defaults = [[BooksDefaultsController alloc] init];
		[self createPreferenceCells];
		[self showPreferences];
				
	}
	return self;
}

- (void)showPreferences {
  if (nil == preferencesView)
    {
        struct CGRect offscreenRect = CGRectMake(contentRect.origin.x,
				    contentRect.size.height,
				    contentRect.size.width,
				    contentRect.size.height);
	preferencesView = [[UIView alloc] initWithFrame:offscreenRect];
	
	UINavigationBar *navigationBar = [[[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, 48.0f)] autorelease];
	[navigationBar showLeftButton:@"About..." withStyle:0 rightButton:@"Done" withStyle:3]; // Blue Done button
	[navigationBar setBarStyle:0];
	[navigationBar setDelegate:self]; 
	[preferencesView addSubview:navigationBar];
	UINavigationItem *title = [[UINavigationItem alloc] 
				    initWithTitle:@"Preferences"];
	[navigationBar pushNavigationItem:[title autorelease]];
	
	preferencesTable = [[UIPreferencesTable alloc] initWithFrame:CGRectMake(0.0f, 48.0f, contentRect.size.width, contentRect.size.height - 48.0f)];	
	[preferencesTable setDataSource:self];
	[preferencesTable setDelegate:self];
	[preferencesView addSubview:preferencesTable];
	
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
    } // if nil == preferencesView
  
  [preferencesTable reloadData];

  needsInAnimation = YES;
  [[NSNotificationCenter defaultCenter] 
    postNotificationName:PREFS_NEEDS_ANIMATE
    object:self];

}

- (void)checkForAnimation:(id)unused
{
  if (needsInAnimation)
    {
        struct CGRect offscreenRect = CGRectMake(contentRect.origin.x,
				    contentRect.size.height,
				    contentRect.size.width,
				    contentRect.size.height);
	[preferencesView setFrame:offscreenRect];
	
	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, -contentRect.size.height);
	[translate setStartTransform:CGAffineTransformMake(1,0,0,1,0,0)];
	[translate setEndTransform:trans];
	[animator addAnimation:translate withDuration:0.5 start:YES]; 
	needsInAnimation = NO;
    }
  else if (needsOutAnimation)
    {

	[preferencesView setFrame:contentRect];
	struct CGAffineTransform trans = CGAffineTransformMakeTranslation(0, -contentRect.size.height);
	[translate setStartTransform:trans];
	[translate setEndTransform:CGAffineTransformMake(1,0,0,1,0,0)];
	[animator addAnimation:translate withDuration:0.5 start:YES];

	needsOutAnimation = NO;

    }
}

- (void)hidePreferences {
	// Save defaults here
	[defaults setTextFont:[self fontNameForIndex:[fontChoiceControl selectedSegment]]];
	NSLog(@"%s Font: %@", _cmd, [self fontNameForIndex:[fontChoiceControl selectedSegment]]);
	int proposedSize = [[fontSizePreferenceCell value] intValue];
	proposedSize = (proposedSize > 36) ? 36 : proposedSize;
	proposedSize = (proposedSize < 10) ? 10 : proposedSize;
	//FIXME: should probably set max and min font sizes via a constant
	//in common.h
	[defaults setTextSize: proposedSize];
	[defaults setInverted:[[[invertPreferenceCell control] valueForKey:@"value"] boolValue]];
	[defaults setToolbar:[[[showToolbarPreferenceCell control] valueForKey:@"value"] boolValue]];
	[defaults setNavbar:[[[showNavbarPreferenceCell control] valueForKey:@"value"] boolValue]];
	[defaults setChapternav:[[[chapterButtonsPreferenceCell control] valueForKey:@"value"] boolValue]];
	[defaults setPagenav:[[[pageButtonsPreferenceCell control] valueForKey:@"value"] boolValue]];
	[defaults setFlipped:[[[flippedToolbarPreferenceCell control] valueForKey:@"value"] boolValue]];


	if ([defaults synchronize]){
		NSLog(@"Synced defaults from prefs pane.");
	}
	

	[controller refreshTextViewFromDefaults];
	needsOutAnimation = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:PREFS_NEEDS_ANIMATE object:self];

}

- (void)createPreferenceCells {
	
	// Font
	fontChoiceControl = [[[UISegmentedControl alloc] initWithFrame:CGRectMake(20.0f, 3.0f, 280.0f, 55.0f)] autorelease];
    [fontChoiceControl insertSegment:0 withTitle:@"Georgia" animated:NO];
    [fontChoiceControl insertSegment:1 withTitle:@"Helvetica" animated:NO];
    [fontChoiceControl insertSegment:2 withTitle:@"Times" animated:NO];
    [fontChoiceControl selectSegment:[self currentFontIndex]];
	fontChoicePreferenceCell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, 48.0f)];
	[fontChoicePreferenceCell setDrawsBackground:NO];
	[fontChoicePreferenceCell addSubview:fontChoiceControl];

	// Text Display
	fontSizePreferenceCell = [[UIPreferencesTextTableCell alloc] initWithFrame:CGRectMake(0.0f, 48.0f, contentRect.size.width, 48.0f)];
	NSString	*str = [NSString stringWithFormat:@"%d",[defaults textSize]];
	[fontSizePreferenceCell setValue:str];
	[fontSizePreferenceCell setTitle:@"Font Size"];
	
	invertPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, 48.0f)];
	BOOL inverted = [defaults inverted];
	[invertPreferenceCell setTitle:@"Invert Color"];
	UISwitchControl *invertSwitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, 48.0f)] autorelease];
	[invertSwitchControl setValue:inverted];
	[invertPreferenceCell setControl:invertSwitchControl];
	
	// Auto-Hide
	showNavbarPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, 48.0f)];
	BOOL navbar = [defaults navbar];
	[showNavbarPreferenceCell setTitle:@"Navigation Bar"];
	UISwitchControl *showNavSitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, 48.0f)] autorelease];
	[showNavSitchControl setValue:navbar];
	[showNavbarPreferenceCell setControl:showNavSitchControl];

	showToolbarPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, 48.0f)];
	BOOL toolbar = [defaults toolbar];
	[showToolbarPreferenceCell setTitle:@"Bottom Toolbar"];
	UISwitchControl *showToolbarSitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, 48.0f)] autorelease];
	[showToolbarSitchControl setValue:toolbar];
	[showToolbarPreferenceCell setControl:showToolbarSitchControl];
	
	// Toolbar Options
	chapterButtonsPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, 48.0f)];
	BOOL chapternav = [defaults chapternav];
	[chapterButtonsPreferenceCell setTitle:@"Chapter Navigation"];
	UISwitchControl *showChapternavSitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, 48.0f)] autorelease];
	[showChapternavSitchControl setValue:chapternav];
	[showChapternavSitchControl setAlternateColors:YES];
	[chapterButtonsPreferenceCell setControl:showChapternavSitchControl];
	
	pageButtonsPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, 48.0f)];
	BOOL pagenav = [defaults pagenav];
	[pageButtonsPreferenceCell setTitle:@"Page Navigation"];
	UISwitchControl *showPagenavSitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, 48.0f)] autorelease];
	[showPagenavSitchControl setValue:pagenav];
	[showPagenavSitchControl setAlternateColors:YES];
	[pageButtonsPreferenceCell setControl:showPagenavSitchControl];
	
	flippedToolbarPreferenceCell = [[UIPreferencesControlTableCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, contentRect.size.width, 48.0f)];
	BOOL flipped = [defaults flipped];
	[flippedToolbarPreferenceCell setTitle:@"Left Handed"];
	UISwitchControl *flippedSitchControl = [[[UISwitchControl alloc] initWithFrame:CGRectMake(contentRect.size.width - 114.0, 11.0f, 114.0f, 48.0f)] autorelease];
	[flippedSitchControl setValue:flipped];
	[flippedSitchControl setAlternateColors:YES];
	[flippedToolbarPreferenceCell setControl:flippedSitchControl];	

}

- (void)aboutAlert { // I like it, good idea.
    NSString *version = [[NSBundle mainBundle]
			      objectForInfoDictionaryKey:@"CFBundleVersion"];
	if (nil == version)
	  version = @"??";
	NSString *bodyText = [NSString stringWithFormat:@"Books.app version %@, by Zachary Brewster-Geisz and Chris Born.\niphoneebooks.googlecode.com", version];
	alertSheet = [[UIAlertSheet alloc] initWithFrame:CGRectMake(0,240,320,240)];
	[alertSheet setTitle:@"About Books"];
	[alertSheet setBodyText:bodyText];
	[alertSheet addButtonWithTitle:@"Zowie!"];
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
	NSLog(@"%s Font selected is %@", _cmd, font);
	return font;
}


// Delegate methods
- (void)alertSheet:(UIAlertSheet *)sheet buttonClicked:(int)button {
	if (sheet == alertSheet) {
		NSLog(@"%s", _cmd);
	} else {
		NSLog(@"%s", _cmd);
	}
	[sheet dismissAnimated:YES];
}

- (void)navigationBar:(UINavigationBar*)navbar buttonClicked:(int)button 
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

- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
	return 4;
}

- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
	int rowCount = 0;
	switch (group)
	{
	case 0:
		rowCount = 1;
		break;
	case 1:
		rowCount = 2;
		break;
	case 2:
		rowCount = 2;
		break;
	case 3:
		rowCount = 3;
		break;
	}
	return rowCount;
}

- (id)preferencesTable:(id)preferencesTable cellForRow:(int)row inGroup:(int)group
{
	NSLog(@"PreferencesController: cellForRow:");
	id prefCell = nil;
	switch (group)
	{
	case 0:
		switch (row)
		{
		case 0:
			prefCell = fontChoicePreferenceCell;
			break;
		}
		break;
	case 1:
		switch (row)
		{
		case 0:
			prefCell = fontSizePreferenceCell;
			break;
		case 1:
			prefCell = invertPreferenceCell;
			break;
		}
		break;
	case 2:
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
	case 3:
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
		title = @"Font";
		break;
	case 1:
		title = @"Text Display";
		break;
	case 2:
		title = @"Auto-Hide";
		break;
	case 3:
		title = @"Toolbar Options";
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
    }
  [defaults release];
  [controller release];
  [super dealloc];
}

@end
