//
//  main.m
//  test_focus
//
//  Created by George Watson on 05/07/2017.
//  Copyright © 2017 George Watson. All rights reserved.
//

#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
  @autoreleasepool {
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    
    id menubar = [NSMenu alloc];
    id appMenuItem = [NSMenuItem alloc];
    [menubar addItem:appMenuItem];
    [NSApp setMainMenu:menubar];
    id appMenu = [NSMenu alloc];
    id appName = [[NSProcessInfo processInfo] processName];
    id quitTitle = [@"Quit " stringByAppendingString:appName];
    id quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle
                                                 action:@selector(terminate:) keyEquivalent:@"q"];
    [appMenu addItem:quitMenuItem];
    [appMenuItem setSubmenu:appMenu];
    
    id app_del = [[AppDelegate alloc] init];
    if (!app_del)
      [NSApp terminate:nil];
    [NSApp setDelegate:app_del];
    
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp run];
  }
  return 0;
}
