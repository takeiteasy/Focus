//
//  helper.h
//  test_focus
//
//  Created by George Watson on 06/07/2017.
//  Copyright © 2017 George Watson. All rights reserved.
//

#ifdef NO_XCODE
#ifdef RES_PATH
#define __RES(X,Y) (X "/" Y)
#define RES(X) (__RES(RES_PATH, X))
#else
#define RES(X) ("/Users/rusty/git/window-focus/window_focus/window_focus/" X)
#endif
#else
#define RES(X) ([[NSBundle mainBundle] pathForResource:@X ofType:nil])
#endif
#define TMP_BG_LOC ("/tmp/tmp_focus_bg.png")

#ifdef NO_XCODE
NSString* get_file_contents(const char* path) {
  FILE *file = fopen(path, "rb");
  if (!file) {
    fprintf(stderr, "fopen \"%s\" failed: %d %s\n", path, errno, strerror(errno));
    exit(1);
  }
  
  fseek(file, 0, SEEK_END);
  size_t length = ftell(file);
  rewind(file);
  
  char *data = (char*)calloc(length + 1, sizeof(char));
  fread(data, 1, length, file);
  fclose(file);
  
  id ret = [[NSString alloc] initWithUTF8String:data];
  free(data);
  
  return ret;
}
#else
#define get_file_contents(X) ([NSString stringWithContentsOfURL:[NSURL fileURLWithPath:X] encoding:NSASCIIStringEncoding error:&error])
#endif
