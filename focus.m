/* focus -- focus one one app, blur the rest
   [https://github.com/takeiteasy/Focus]
 
 build: clang focus.m -framework Cocoa -o focus
 
 The MIT License (MIT)

 Copyright (c) 2022 George Watson

 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without restriction,
 including without limitation the rights to use, copy, modify, merge,
 publish, distribute, sublicense, and/or sell copies of the Software,
 and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Cocoa/Cocoa.h>

#define RES_PATH  "resources"
#define RES_MERGE(X,Y) (X "/" Y)
#if defined(FOCUS_APP)
#define RES(X) [[NSBundle mainBundle] pathForResource:@RES_MERGE(RES_PATH, X) ofType:nil]
#define readFileContents(X) [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:X] encoding:NSASCIIStringEncoding error:&error]
#else
#define RES(X) (RES_MERGE(RES_PATH, X))

NSString* readFileContents(const char* path) {
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

#include <stdlib.h>
#include <getopt.h>

static struct option long_options[] = {
    {"app", required_argument, NULL, 'a'},
    {"opacity", required_argument, NULL, 'o'},
    {"color", required_argument, NULL, 'c'},
    {"blur", required_argument, NULL, 'b'},
    {"help", no_argument, NULL, 'h'},
    {NULL, 0, NULL, 0}
};

static void usage(void) {
    puts("usage: focus -a [app] [options]\n");
    puts("\t-a/--app\tApp name to focus\t[default: Currently running app]");
    puts("\t-o/--opacity\tBackground opacity\t[value: 0-1, default: .5]");
    puts("\t-c/--color\tBackground color\t[value: #hex, default: #333333]");
    puts("\t-b/--blur\tBlur radius\t\t[value: 1-100, default: 20]");
    puts("\t-h/--help\tShow this message");
}

#if !defined(MIN)
#define MIN(a, b) (a < b ? a : b)
#endif
#if !defined(MAX)
#define MAX(a, b) (a > b ? a : b)
#endif
#if !defined(CLAMP)
#define CLAMP(n, min, max) (MIN(MAX(n, min), max))
#endif
#endif

typedef void* CGSConnection;
extern OSStatus CGSSetWindowBackgroundBlurRadius(CGSConnection connection, NSInteger windowNumber, int radius);
extern CGSConnection CGSDefaultConnectionForThread(void);

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate> {
    NSString *oldAppStr;
    NSWindow *window;
    NSTimer *timer;
}
@end

static const char *appName = NULL;
static double r = .2, g = .2, b = .2, a = .5;
static int blur = 20;

@implementation AppDelegate : NSObject
-(id)init {
    if (self = [super init]) {
        NSError *error = NULL;
        NSDictionary *osaError = nil;
        if (!appName) {
            NSAppleScript* runningScript = [[NSAppleScript alloc] initWithSource:readFileContents(RES("running.scpt"))];
            if (error)
                NSLog(@"ERROR! Failed to load running.scpt! %@", error);
            else {
                NSAppleEventDescriptor *result = [runningScript executeAndReturnError:&osaError];
                if (!result)
                    NSLog(@"ERROR! Failed to execute running.scpt! %@", osaError);
                appName = [[result stringValue] UTF8String];
            }
            if (!appName)
                NSLog(@"WARNING! No application name passed!");
        }

        window = [[NSWindow alloc] initWithContentRect:[[NSScreen mainScreen] visibleFrame]
                                             styleMask:NSWindowStyleMaskBorderless
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
        [window setTitle:NSProcessInfo.processInfo.processName];
        [window center];
        [window setOpaque:NO];
        [window setCanHide:NO];
        [window setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorStationary];
        [window setExcludedFromWindowsMenu:YES];
        [window makeKeyAndOrderFront:self];
        [window setExcludedFromWindowsMenu:NO];
        [window setOpaque:NO];
        [window setBackgroundColor: [NSColor colorWithCalibratedRed:r
                                                              green:g
                                                               blue:b
                                                              alpha:a]];
        CGSConnection connection = CGSDefaultConnectionForThread();
        CGSSetWindowBackgroundBlurRadius(connection, [window windowNumber], blur);
        [window setDelegate:self];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
    }
    return self;
}

-(void)update {
    NSString *now = [[[NSWorkspace sharedWorkspace] frontmostApplication] bundleIdentifier];
    if (!now || [now compare:oldAppStr])
        [NSApp terminate:nil];
}

-(void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSError *error = NULL;
    NSDictionary *osaError = nil;
    NSAppleScript* focusScript = [[NSAppleScript alloc] initWithSource:[NSString stringWithFormat:readFileContents(RES("focus.scpt")), appName]];
    if (error) {
        NSLog(@"ERROR! Failed to load focus.scpt! %@", error);
        [NSApp terminate:nil];
    }
    if (![focusScript executeAndReturnError:&osaError]) {
        NSLog(@"ERROR! Failed to execute focus.scpt! %@", osaError);
        [NSApp terminate:nil];
    }
    timer = [NSTimer scheduledTimerWithTimeInterval:.1
                                             target:self
                                           selector:@selector(update)
                                           userInfo:nil
                                            repeats:YES];
    NSRunningApplication *oldApp = [[NSWorkspace sharedWorkspace] frontmostApplication];
    oldAppStr = [oldApp bundleIdentifier];
    [oldApp activateWithOptions:NSApplicationActivateIgnoringOtherApps];
}
@end

int main(int argc, char *argv[]) {
#if !defined(FOCUS_APP)
    int opt;
    extern char* optarg;
    extern int optopt;
    while ((opt = getopt_long(argc, argv, ":a:o:c:b:h", long_options, NULL)) != -1) {
        switch (opt) {
            case 'a':
                appName = optarg;
                break;
            case 'o':
                a = CLAMP(atof(optarg), 0.0, 1.0);
                break;
            case 'c': {
                const char *opt = optarg;
                if (opt[0] == '#')
                    opt++;
                int _r, _g, _b;
                sscanf(opt, "%02x%02x%02x", &_r, &_g, &_b);
                r = CLAMP((double)_r, 0., 255.) / 255.;
                g = CLAMP((double)_g, 0., 255.) / 255.;
                b = CLAMP((double)_b, 0., 255.) / 255.;
                break;
            }
            case 'b':
                blur = CLAMP(atoi(optarg), 1, 100);
                break;
            case 'h':
                usage();
                return EXIT_SUCCESS;
            case ':':
                printf("ERROR: \"-%c\" requires an value!\n", optopt);
                usage();
                return EXIT_FAILURE;
            case '?':
                printf("ERROR: Unknown argument \"-%c\"\n", optopt);
                usage();
                return EXIT_FAILURE;
        }
    }
#endif
    
    @autoreleasepool {
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [NSApp setDelegate:[AppDelegate new]];
        [NSApp activateIgnoringOtherApps:YES];
        [NSApp run];
    }
    return 0;
}
