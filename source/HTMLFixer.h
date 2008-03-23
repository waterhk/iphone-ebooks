// HTMLFixer.h, for Books.app by Zachary Brewster-Geisz

#import <Foundation/Foundation.h>


@class AGRegex;

@interface HTMLFixer : NSObject {
  
}

+ (NSString *)fixedImageTagForString:(NSString *)str basePath:(NSString *)path returnImageHeight:(int *)height;
+ (void)fixHTMLString:(NSMutableString *)theOldHTML filePath:(NSString *)thePath imageOnly:(BOOL)p_imgOnly;
+ (int)replaceRegex:(AGRegex*)p_regex withString:(NSString*)p_repl inMutableString:(NSMutableString*)p_mut;

+ (BOOL)isRenderTables;
+ (BOOL)isDocumentImage:(NSString*)p_path;

+ (NSString*)tableStartReplacement;
+ (NSString*)tdStartReplacement;
+ (NSString*)trStartReplacement;
+ (NSString*)thStartReplacement;
+ (NSString*)tableEndReplacement;
+ (NSString*)tdEndReplacement;
+ (NSString*)trEndReplacement;
+ (NSString*)thEndReplacement;

@end
