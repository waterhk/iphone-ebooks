#import <stdio.h>
#import <Cocoa/Cocoa.h>
#import "../source/HTMLFixer.h"

int main(int argc, char *argv[]) {
  if(argc != 3) {
    printf("Usage: %s <input file> <output file>\n", argv[0]);
    exit(1);
  }
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSString *inFile = [NSString stringWithCString:argv[1]];
  NSString *outFile = [NSString stringWithCString:argv[2]];

  
  NSMutableString *inHtml = [NSMutableString stringWithContentsOfFile:inFile];
  
  [HTMLFixer fixHTMLString:inHtml filePath:[inFile stringByDeletingLastPathComponent] imageOnly:NO];
  
  [inHtml writeToFile:outFile atomically:NO encoding:NSUTF8StringEncoding error:nil];
  
  printf("Done.\n\n");
  
  [pool release];
  return 0;
}