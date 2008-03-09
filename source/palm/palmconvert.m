#import <Foundation/Foundation.h>
#include <stdio.h>

#include "txt2pdbdoc.h"
#include "pluckhtml.h"


/**
 * Opens filename and attempts to decode its contents using several PalmOS
 * encodings.
 *
 * This method can return either NSData or NSMutableString, depending on the
 * file type.  The retObject pointer will be set to either "DATA" or "STRING"
 * to indicate.  
 *
 * Plain-text files (TEXt) are returned as NSData, and the usual Books text
 * encoding routines should be used to convert to a string.
 *
 * File types which contain an encoding setting of their own (Plucker) will
 * by converted to a string on the fly using the encoding specified in the file.
 *
 * @param filename full path/filename of PDB file
 * @param retType reference var to NSString.  Will be set to txt or htm
 *  to reflect type of content returned.  txt might need further processing
 *
 * @return text or html contents of the PDB or an error message if read or
 *  decode fails or if PDB is not one of the supported types
 */
id ReadPDBFile(NSString *filename, NSString **retType, NSString **retObject) {
  FILE *src = fopen([filename cString], "rb");
  id ret = nil;
  
  // Check magic to figure out what kind of PDB we have.
  char sMagic[9];
  fseek(src, 60, SEEK_SET);
  fread(sMagic, 1, 8, src);
  fseek(src, 0, SEEK_SET);
  sMagic[8] = 0;
  
  GSLog(@"Opening %@, Magic: %s", filename, sMagic);
  
  if(!strncmp("DataPlkr", sMagic, 8)) {
    // It's a plucker file
    ret = HTMLFromPluckerFile(src, [filename stringByDeletingLastPathComponent]);
    *retType = @"htm";
    *retObject = @"STRING";
  } else if(!strncmp("TEXt", sMagic, 4)) { 
    /*
     * It's a PalmDOC format.
     * Multiple creator codes exist for PalmDoc, but as long as the file type attribute is 
     * TEXt, it should be readable.  Known types include: TEXtREAd, TEXtTlDc
     */    
    ret = decodePalmDoc(src);
    *retType = @"txt";
    *retObject = @"DATA";
  } else {
    // We don't know how to deal with this!
    ret = [NSMutableString stringWithFormat:@"Got unknown PDB magic of %s\n", sMagic];
    *retType = @"txt";
    *retObject = @"STRING";
  }
  
  fclose(src);

  return ret;
}