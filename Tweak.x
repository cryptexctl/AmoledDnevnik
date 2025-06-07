#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "AmoledDnevnikSettingsVC.h"

@interface RCTView : UIView
@property (nonatomic, strong) NSNumber *reactTag;
@end

%hook RCTView

#define kAmoledDnevnikEnabledKey @"AmoledDnevnikEnabled"
#define kAmoledDnevnikColorKey @"AmoledDnevnikColor"

BOOL AmoledDnevnikIsEnabled() {
    NSNumber *val = [[NSUserDefaults standardUserDefaults] objectForKey:kAmoledDnevnikEnabledKey];
    return val ? [val boolValue] : YES;
}

UIColor *AmoledDnevnikColor() {
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kAmoledDnevnikColorKey];
    if (data) {
        NSError *error = nil;
        UIColor *color = [NSKeyedUnarchiver unarchivedObjectOfClass:[UIColor class] fromData:data error:&error];
        if (color) return color;
    }
    return [UIColor blackColor];
}

void AmoledDnevnikSetEnabled(BOOL enabled) {
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kAmoledDnevnikEnabledKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

void AmoledDnevnikSetColor(UIColor *color) {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:color requiringSecureCoding:NO error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kAmoledDnevnikColorKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (!AmoledDnevnikIsEnabled()) {
        %orig(backgroundColor);
        return;
    }
    if (backgroundColor && backgroundColor != [UIColor clearColor]) {
        %orig(AmoledDnevnikColor());
    } else {
        %orig(backgroundColor);
    }
}

- (void)didMoveToWindow {
    %orig;
    NSNumber *tag = self.reactTag;
    if (tag && [tag integerValue] == 1023) {
        self.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(amoleddnevnik_secretTap)];
        tap.numberOfTapsRequired = 1;
        [self addGestureRecognizer:tap];
    }
}

%new
- (void)amoleddnevnik_secretTap {
    static int tapCount = 0;
    static NSTimeInterval lastTapTime = 0;
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - lastTapTime > 2.0) tapCount = 0;
    lastTapTime = now;
    tapCount++;
    if (tapCount == 7) {
        tapCount = 0;
        AmoledDnevnikSettingsVC *vc = [AmoledDnevnikSettingsVC new];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        UIWindow *window = nil;
        if (@available(iOS 13.0, *)) {
            NSSet *scenes = [[UIApplication sharedApplication] connectedScenes];
            UIWindowScene *windowScene = [scenes anyObject];
            window = windowScene.windows.firstObject;
        } else {
            NSArray *windows = [[UIApplication sharedApplication] windows];
            for (UIWindow *w in windows) {
                if (w.isKeyWindow) {
                    window = w;
                    break;
                }
            }
        }
        UIViewController *rootVC = window.rootViewController;
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }
        [rootVC presentViewController:vc animated:YES completion:nil];
    }
}

%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey:@"AmoledDnevnikHasShown"]) {
            [defaults setBool:YES forKey:@"AmoledDnevnikHasShown"];
            [defaults synchronize];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"AmoledDnevnik"
                                                                           message:@"Tweak dev: @systemxplore / github.com/cryptexctl\nAntiJB-detect: @jailbreaker1337 / github.com/ghh-jb"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                    style:UIAlertActionStyleDefault
                                                  handler:nil]];
            
            UIWindow *window = nil;
            if (@available(iOS 13.0, *)) {
                NSSet *scenes = [[UIApplication sharedApplication] connectedScenes];
                UIWindowScene *windowScene = [scenes anyObject];
                window = windowScene.windows.firstObject;
            } else {
                NSArray *windows = [[UIApplication sharedApplication] windows];
                for (UIWindow *w in windows) {
                    if (w.isKeyWindow) {
                        window = w;
                        break;
                    }
                }
            }
            
            UIViewController *rootVC = window.rootViewController;
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            [rootVC presentViewController:alert animated:YES completion:nil];
        }
    });
}
