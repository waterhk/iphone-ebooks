// EncodingPrefsController.m

#import "EncodingPrefsController.h"

@implementation EncodingPrefsController

-(EncodingPrefsController *)init
{
  if (self = [super init])
    {
      NSLog(@"Creating encoding prefs!");
      struct CGRect rect = [UIHardware fullScreenApplicationContentRect];
      rect.origin.x = rect.origin.y = 0;

      encodingTable = [[UIPreferencesTable alloc] initWithFrame:CGRectMake(0,0,rect.size.width, rect.size.height-48)];
      [encodingTable setDelegate:self];
      [encodingTable setDataSource:self];
      [encodingTable reloadData];
      defaults = [[BooksDefaultsController alloc] init];
    }
  NSLog(@"Created encoding prefs!");
  return self;
}

-(void)reloadData
{
  [encodingTable reloadData];
}

-(UITable *)table
{
  return encodingTable;
}

- (int)numberOfGroupsInPreferencesTable:(id)preferencesTable
{
  return 1;
}

- (int)preferencesTable:(id)preferencesTable numberOfRowsInGroup:(int)group
{
  return 7;
}

- (id)preferencesTable:(id)preferencesTable titleForGroup:(int)group
{
  return nil;
}

- (float)preferencesTable:(id)preferencesTable heightForRow:(int)row inGroup:(int)group withProposedHeight:(float)proposedHeight;
{
  return 48.0f;
}

-(void)tableRowSelected:(NSNotification *)aNotification
{
  int i = [encodingTable selectedRow];
  UIPreferencesTableCell *cell = [encodingTable cellAtRow:i column:0];
  NSString *title = [cell title];
  int rows = [encodingTable numberOfRows];

  for (i = 0; i < rows; i++)
    [[encodingTable cellAtRow:i column:0] setChecked:NO];
  [cell setChecked:YES];
  if ([title isEqualToString:@"Automatic"])
    {
      [defaults setDefaultTextEncoding:AUTOMATIC_ENCODING];
    }
  else if ([title isEqualToString:@"Unicode (UTF-16)"])
    {
      [defaults setDefaultTextEncoding:NSUnicodeStringEncoding];
    }
  else if ([title isEqualToString:@"Unicode (UTF-8)"])
    {
      [defaults setDefaultTextEncoding:NSUTF8StringEncoding];
    }
  else if ([title isEqualToString:@"ISO Latin-1"])
    {
      [defaults setDefaultTextEncoding:NSISOLatin1StringEncoding];
    }
  else if ([title isEqualToString:@"Windows Latin-1"])
    {
      [defaults setDefaultTextEncoding:NSWindowsCP1252StringEncoding];
    }
  else if ([title isEqualToString:@"Mac OS Roman"])
    {
      [defaults setDefaultTextEncoding:NSMacOSRomanStringEncoding];
    }
  else if ([title isEqualToString:@"ASCII"])
    {
      [defaults setDefaultTextEncoding:NSASCIIStringEncoding];
    }

  [cell setSelected:NO withFade:YES];
  [[NSNotificationCenter defaultCenter] postNotificationName:ENCODINGSELECTED object:title];
}

- (id)preferencesTable:(id)preferencesTable cellForRow:(int)row inGroup:(int)group
{
  NSString *title;
  BOOL checked = NO;
  switch (row)
    {
    case 0:
      title = @"Automatic";
      checked = (AUTOMATIC_ENCODING == [defaults defaultTextEncoding]);
      break;
    case 1:
      title = @"Unicode (UTF-16)";
      checked = (NSUnicodeStringEncoding == [defaults defaultTextEncoding]);
      break;
    case 2:
      title = @"Unicode (UTF-8)";
      checked = (NSUTF8StringEncoding == [defaults defaultTextEncoding]);
      break;
    case 3:
      title = @"ISO Latin-1";
      checked = (NSISOLatin1StringEncoding == [defaults defaultTextEncoding]);
      break;
    case 4:
      title = @"Windows Latin-1";
      checked = (NSWindowsCP1252StringEncoding == [defaults defaultTextEncoding]);
      break;
    case 5:
      title = @"Mac OS Roman";
      checked = (NSMacOSRomanStringEncoding == [defaults defaultTextEncoding]);
      break;
    case 6:
      title = @"ASCII";
      checked = (NSASCIIStringEncoding == [defaults defaultTextEncoding]);
      break;
    }
  UIPreferencesTableCell *theCell = [[UIPreferencesTableCell alloc] initWithFrame:CGRectMake(0,0,320,48)];
  [theCell setTitle:title];
  [theCell setChecked:checked];
  return [theCell autorelease];
}


-(void)dealloc
{
  [encodingTable release];
  [defaults release];
  [super dealloc];
}

@end
