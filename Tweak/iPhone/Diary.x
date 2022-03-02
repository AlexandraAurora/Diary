#import "Diary.h"

CSCoverSheetView* coverSheetView = nil;
SBFLockScreenDateView* timeDateView = nil;
SBFWallpaperView* lockscreenWallpaper = nil;

%group DiaryGlobal

%hook CSCoverSheetView

- (id)initWithFrame:(CGRect)frame { // get a cscoversheetview instance, load fonts and register a notification observer

    if (coverSheetView) return %orig;
    id orig = %orig;

    coverSheetView = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFrameAfterRotation) name:@"diaryRotateNotification" object:nil];

    if ([fontFamilyValue intValue] == 0) {
        // load selawik light font
        NSData* inData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/Library/PreferenceBundles/DiaryPreferences.bundle/fonts/selawkl.ttf"]];
        CFErrorRef error;
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)inData);
        CGFontRef font = CGFontCreateWithDataProvider(provider);
        if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
            CFStringRef errorDescription = CFErrorCopyDescription(error);
            CFRelease(errorDescription);
        }
        CFRelease(font);
        CFRelease(provider);

        // load selawik regular font
        NSData* inData2 = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/Library/PreferenceBundles/DiaryPreferences.bundle/fonts/selawk.ttf"]];
        CFErrorRef error2;
        CGDataProviderRef provider2 = CGDataProviderCreateWithCFData((CFDataRef)inData2);
        CGFontRef font2 = CGFontCreateWithDataProvider(provider2);
        if (!CTFontManagerRegisterGraphicsFont(font2, &error2)) {
            CFStringRef errorDescription2 = CFErrorCopyDescription(error2);
            CFRelease(errorDescription2);
        }
        CFRelease(font2);
        CFRelease(provider2);
    } else if ([fontFamilyValue intValue] == 1) {
        // load open sans light font
        NSData* inData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/Library/PreferenceBundles/DiaryPreferences.bundle/fonts/OpenSans-Light.ttf"]];
        CFErrorRef error;
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)inData);
        CGFontRef font = CGFontCreateWithDataProvider(provider);
        if (!CTFontManagerRegisterGraphicsFont(font, &error)) {
            CFStringRef errorDescription = CFErrorCopyDescription(error);
            CFRelease(errorDescription);
        }
        CFRelease(font);
        CFRelease(provider);

        // load open sans regular font
        NSData* inData2 = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:@"/Library/PreferenceBundles/DiaryPreferences.bundle/fonts/OpenSans-Regular.ttf"]];
        CFErrorRef error2;
        CGDataProviderRef provider2 = CGDataProviderCreateWithCFData((CFDataRef)inData2);
        CGFontRef font2 = CGFontCreateWithDataProvider(provider2);
        if (!CTFontManagerRegisterGraphicsFont(font2, &error2)) {
            CFStringRef errorDescription2 = CFErrorCopyDescription(error2);
            CFRelease(errorDescription2);
        }
        CFRelease(font2);
        CFRelease(provider2);
    }

    return orig;

}

%new
- (void)updateFrameAfterRotation { // hide the player in landscape mode and update gradient frame when rotated

    if (enableMediaPlayerSwitch) {
        if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]) && ([[%c(SBMediaController) sharedInstance] isPlaying] || [[%c(SBMediaController) sharedInstance] isPaused]))
            [[self diaryPlayerView] setHidden:YES];
        else if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation]) && ([[%c(SBMediaController) sharedInstance] isPlaying] || [[%c(SBMediaController) sharedInstance] isPaused]))
            [[self diaryPlayerView] setHidden:NO];
    }

    if ([self diaryGradient]) [[self diaryGradient] setFrame:[self bounds]];

}

%end

%hook CSCombinedListViewController

- (id)init { // add a notification observer

    if (!enableTimeAndDateSwitch && !enableMediaPlayerSwitch) return %orig;
    id orig = %orig;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layoutListView) name:@"diaryUpdateNotificationList" object:nil];

    return orig;

}

- (UIEdgeInsets)_listViewDefaultContentInsets { // change notification offset

    UIEdgeInsets orig = %orig;

    if ([overrideTimeDateStyleValue intValue] == 0) {
        if ((!enableTimeAndDateSwitch && !enableMediaPlayerSwitch && !enableHelloSwitch) || !hideDefaultTimeAndDateSwitch) return orig;
        if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) return orig;

        if (enableMediaPlayerSwitch && ![[coverSheetView diaryPlayerView] isHidden]) {
            orig.top -= 90 - ([mediaPlayerOffsetValue intValue] + [notificationOffsetValue intValue]);
            return orig;
        }
        
        if (enableHelloSwitch) {
            if (![[coverSheetView diaryHelloIconView] isHidden] && showHelloGreetingSwitch && ![[coverSheetView diaryHelloLabel] isHidden]) {
                orig.top -= 40 - [notificationOffsetValue intValue];
                return orig;
            } else if (![[coverSheetView diaryHelloIconView] isHidden] && showHelloGreetingSwitch && [[coverSheetView diaryHelloLabel] isHidden]) {
                orig.top -= 100 - [notificationOffsetValue intValue];
                return orig;
            } else if (![[coverSheetView diaryHelloIconView] isHidden] && !showHelloGreetingSwitch) {
                orig.top -= 80 - [notificationOffsetValue intValue];
                return orig;
            }
        }

        orig.top -= 180 - [notificationOffsetValue intValue];
        return orig;
    } else if ([overrideTimeDateStyleValue intValue] == 1) {
        if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) return orig;

        orig.top += 40;
        return orig;
    }

    return orig;

}

%end

%hook SpringBoard

- (void)noteInterfaceOrientationChanged:(long long)arg1 duration:(double)arg2 logMessage:(id)arg3 { // update the frame of some elements when rotated

	%orig;

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.001 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter postNotificationName:@"diaryRotateNotification" object:nil];
        [notificationCenter postNotificationName:@"diaryUpdateNotificationList" object:nil];

        if ([overrideTimeDateStyleValue intValue] == 1 && [[%c(SBLockScreenManager) sharedInstance] isLockScreenVisible]) [timeDateView layoutTimeAndDate];
	});

}

%end

%hook CSTodayViewController

- (void)viewWillAppear:(BOOL)animated { // fade diary out when today view appears on ios 13

    %orig;

    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (enableTimeAndDateSwitch) [[coverSheetView diaryView] setAlpha:0];
        if (enableUpNextSwitch) {
            [[coverSheetView diaryCalendarButton] setAlpha:0];
            [[coverSheetView diaryReminderButton] setAlpha:0];
            [[coverSheetView diaryAlarmButton] setAlpha:0];
        }
        if (enableMediaPlayerSwitch) [[coverSheetView diaryPlayerView] setAlpha:0];
    } completion:nil];

}

- (void)viewWillDisappear:(BOOL)animated { // fade diary in when today view disappears

    %orig;

    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        if (enableTimeAndDateSwitch) [[coverSheetView diaryView] setAlpha:1];
        if (enableUpNextSwitch) {
            [[coverSheetView diaryCalendarButton] setAlpha:1];
            [[coverSheetView diaryReminderButton] setAlpha:1];
            [[coverSheetView diaryAlarmButton] setAlpha:1];
        }
        if (enableMediaPlayerSwitch) [[coverSheetView diaryPlayerView] setAlpha:1];
    } completion:nil];

}

%end

%hook CSCoverSheetViewController

- (void)viewDidLoad { // lastlook support

    %orig;

    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/LastLook.dylib"]) [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestDiaryTimeAndDateUpdate) name:@"requestDiaryTimeAndDateUpdate" object:nil];

}

- (void)_transitionChargingViewToVisible:(BOOL)arg1 showBattery:(BOOL)arg2 animated:(BOOL)arg3 { // hide charging view

	if (hideChargingViewSwitch)
        %orig(NO, NO, NO);
    else
        %orig;

}

%end

%hook SBMainDisplayPolicyAggregator

- (BOOL)_allowsCapabilityTodayViewWithExplanation:(id *)arg1 { // disable today view swipe

    if (disableTodaySwipeSwitch)
		return NO;
	else
		return %orig;

}

- (BOOL)_allowsCapabilityLockScreenCameraWithExplanation:(id *)arg1 { // disable camera swipe

    if (disableCameraSwipeSwitch)
		return NO;
	else
		return %orig;

}

%end

%hook NCNotificationListSectionHeaderView

- (id)initWithFrame:(CGRect)frame { // hide notification header and clear button

    if (hideNotificationsHeaderSwitch)
        return nil;
    else
        return %orig;

}

%end

%hook NCNotificationListView

- (void)setRevealed:(BOOL)arg1 { // always reveal notifications

    if (alwaysShowNotificationsSwitch)
        %orig(YES);
    else
        %orig;

}

%end

%hook UIStatusBar_Modern

- (void)setFrame:(CGRect)arg1 { // add a notification observer

    %orig;

    if (hideDefaultStatusBarSwitch && !hasAddedStatusBarObserver) {
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(receiveHideNotification:) name:@"diaryHideStatusBar" object:nil];
        [notificationCenter addObserver:self selector:@selector(receiveHideNotification:) name:@"diaryUnhideStatusBar" object:nil];
        hasAddedStatusBarObserver = YES;
    }

}

%new
- (void)receiveHideNotification:(NSNotification *)notification { // hide/unhide status bar

	if ([notification.name isEqual:@"diaryHideStatusBar"])
        [[self statusBar] setHidden:YES];
    else if ([notification.name isEqual:@"diaryUnhideStatusBar"])
        [[self statusBar] setHidden:NO];

}

%end

%hook SBUIProudLockIconView

- (void)didMoveToWindow { // remove faceid lock and label

	%orig;

	if (hideDefaultFaceIDLockSwitch) [[self superview] setHidden:YES];

}

%end

// if i removed sbflockscreendateview timer support would be broken, so i remove every label one by one

%hook SBFLockScreenDateView

- (void)didMoveToWindow { // remove original time label

	%orig;

    if (!hideDefaultTimeAndDateSwitch) return;
    SBUILegibilityLabel* originalTimeLabel = [self valueForKey:@"_timeLabel"];
    [originalTimeLabel removeFromSuperview];

}

%end

%hook SBFLockScreenDateSubtitleView

- (void)didMoveToWindow { // remove original date label

    %orig;

    if (!hideDefaultTimeAndDateSwitch) return;
    SBUILegibilityLabel* originalDateLabel = [self valueForKey:@"_label"];
    [originalDateLabel removeFromSuperview];

}

%end

%hook SBLockScreenTimerDialView

- (void)didMoveToWindow { // remove timer icon

    %orig;

    if (!hideDefaultTimeAndDateSwitch) return;
    [self removeFromSuperview];

}

%end

%hook SBFLockScreenDateSubtitleDateView

- (void)didMoveToWindow { // remove lunar label

    %orig;

    if (!hideDefaultTimeAndDateSwitch) return;
    SBFLockScreenAlternateDateLabel* lunarLabel = [self valueForKey:@"_alternateDateLabel"];
    [lunarLabel removeFromSuperview];

}

%end

%hook NCNotificationListSectionRevealHintView

- (id)initWithFrame:(CGRect)frame { // remove notifications hint

    if (hideNotificationsHintSwitch)
	    return nil;
    else
        return %orig;

}

%end

%hook CSQuickActionsButton

- (id)initWithFrame:(CGRect)frame { // remove quick actions

    if (hideDefaultQuickActionsSwitch)
	    return nil;
    else
        return %orig;

}

%end

%hook CSTeachableMomentsContainerView

- (void)didMoveToWindow { // remove unlock text and control center grabber

	%orig;
	
	if (hideDefaultUnlockTextSwitch) [self removeFromSuperview];

}

%end

%hook SBUICallToActionLabel

- (id)initWithFrame:(CGRect)frame { // remove unlock text

    if (hideDefaultUnlockTextSwitch)
	    return nil;
    else
        return %orig;

}

%end

%hook CSHomeAffordanceView

- (id)initWithFrame:(CGRect)frame { // remove homebar

    if (hideDefaultHomebarSwitch)
	    return nil;
    else
        return %orig;

}

%end

%hook CSPageControl

- (id)initWithFrame:(CGRect)frame { // remove page dots

    if (hideDefaultPageDotsSwitch)
	    return nil;
    else
        return %orig;

}

%end

%end

%group DiaryTimeAndDate

%hook SBFLockScreenDateView

%property(nonatomic, retain)UILabel* diaryTimeLabel;
%property(nonatomic, retain)UILabel* diaryDateLabel;

- (id)initWithFrame:(CGRect)frame { // get an instance of SBFLockScreenDateView

    id orig = %orig;

    if ([overrideTimeDateStyleValue intValue] == 1) timeDateView = self;

    return orig;

}

- (void)didMoveToWindow { // add the windows 11 style time

    %orig;

    if ([self diaryTimeLabel] || [overrideTimeDateStyleValue intValue] != 1) return;

    // time label
    self.diaryTimeLabel = [UILabel new];
    [[self diaryTimeLabel] setTextColor:[GcColorPickerUtils colorWithHex:timeDateColorValue]];
    if ([fontFamilyValue intValue] == 0) [[self diaryTimeLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:78]];
    else if ([fontFamilyValue intValue] == 1) [[self diaryTimeLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:78]];
    else if ([fontFamilyValue intValue] == 2) [[self diaryTimeLabel] setFont:[UIFont systemFontOfSize:78 weight:UIFontWeightMedium]];
    [[self diaryTimeLabel] setTextAlignment:NSTextAlignmentCenter];
    [self addSubview:[self diaryTimeLabel]];


    // date label
    self.diaryDateLabel = [UILabel new];
    [[self diaryDateLabel] setTextColor:[GcColorPickerUtils colorWithHex:timeDateColorValue]];
    if ([fontFamilyValue intValue] == 0) [[self diaryDateLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:20]];
    else if ([fontFamilyValue intValue] == 1) [[self diaryDateLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:20]];
    else if ([fontFamilyValue intValue] == 2) [[self diaryDateLabel] setFont:[UIFont systemFontOfSize:20 weight:UIFontWeightMedium]];
    [[self diaryDateLabel] setTextAlignment:NSTextAlignmentCenter];
    [self addSubview:[self diaryDateLabel]];

        
     [self layoutTimeAndDate];

}

%new
- (void)layoutTimeAndDate {

    if (![self diaryTimeLabel] || ![self diaryDateLabel]) return;
    [[self diaryDateLabel] removeFromSuperview];
    [[self diaryTimeLabel] removeFromSuperview];
    [self addSubview:[self diaryDateLabel]];
    [self addSubview:[self diaryTimeLabel]];

    if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
        // time label
        [[self diaryTimeLabel] setTextAlignment:NSTextAlignmentCenter];
            
        [[self diaryTimeLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryTimeLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:32],
            [self.diaryTimeLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.diaryTimeLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];


        // date label
        [[self diaryDateLabel] setTextAlignment:NSTextAlignmentCenter];

        [[self diaryDateLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryDateLabel.topAnchor constraintEqualToAnchor:self.diaryTimeLabel.bottomAnchor constant:8],
            [self.diaryDateLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.diaryDateLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];
    } else if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])) {
        // time label
        [[self diaryTimeLabel] setTextAlignment:NSTextAlignmentLeft];

        [[self diaryTimeLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryTimeLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:32],
            [self.diaryTimeLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:-8],
            [self.diaryTimeLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];


        // date label
        [[self diaryDateLabel] setTextAlignment:NSTextAlignmentLeft];

        [[self diaryDateLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryDateLabel.topAnchor constraintEqualToAnchor:self.diaryTimeLabel.bottomAnchor constant:8],
            [self.diaryDateLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:-8],
            [self.diaryDateLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];
    } else {
        // time label
        [[self diaryTimeLabel] setTextAlignment:NSTextAlignmentCenter];
            
        [[self diaryTimeLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryTimeLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:32],
            [self.diaryTimeLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.diaryTimeLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];


        // date label
        [[self diaryDateLabel] setTextAlignment:NSTextAlignmentCenter];

        [[self diaryDateLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryDateLabel.topAnchor constraintEqualToAnchor:self.diaryTimeLabel.bottomAnchor constant:8],
            [self.diaryDateLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.diaryDateLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];
    }

}

%new
- (void)updateDiaryTimeAndDate { // update diary

    NSDateFormatter* timeFormat = [NSDateFormatter new];
    [timeFormat setDateFormat:timeFormatValue];
    [[self diaryTimeLabel] setText:[timeFormat stringFromDate:[NSDate date]]];

    if (!isTimerRunning) {
        NSDateFormatter* dateFormat = [NSDateFormatter new];
        [dateFormat setDateFormat:dateFormatValue];
        if (useCustomDateLocaleSwitch) [dateFormat setLocale:[[NSLocale alloc] initWithLocaleIdentifier:customDateLocaleValue]];
        [[self diaryDateLabel] setText:[dateFormat stringFromDate:[NSDate date]]];
    }
    
}

%end

%hook CSCoverSheetView

%property(nonatomic, retain)UIView* diaryView;
%property(nonatomic, retain)UIView* diaryGestureView;
%property(nonatomic, retain)UIPanGestureRecognizer* panGesture;
%property(nonatomic, retain)UITapGestureRecognizer* tapGesture;
%property(nonatomic, retain)UILabel* diaryTimeLabel;
%property(nonatomic, retain)UILabel* diaryDateLabel;
%property(nonatomic, retain)UILabel* diaryEventTitleLabel;
%property(nonatomic, retain)UILabel* diaryEventSubtitleLabel;
%property(nonatomic, retain)UILabel* diaryCalendarButton;
%property(nonatomic, retain)UILabel* diaryReminderButton;
%property(nonatomic, retain)UILabel* diaryAlarmButton;
%property(nonatomic, retain)UIImageView* diaryBatteryIcon;
%property(nonatomic, retain)UILabel* diaryBatteryPercentageLabel;
%property(nonatomic, retain)UIImageView* diaryWifiIcon;
%property(nonatomic, retain)UIImageView* diaryCellularIcon;
%property(nonatomic, retain)UILabel* diaryCellularTypeLabel;

- (void)didMoveToWindow { // add time and date

    %orig;

    if ([self diaryView]) return;


	// diary view
	self.diaryView = [UIView new];
	[[self diaryView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[self insertSubview:[self diaryView] atIndex:useCustomZIndexSwitch ? [customZIndexValue intValue] : 0];

    [[self diaryView] setTranslatesAutoresizingMaskIntoConstraints:NO];
	[NSLayoutConstraint activateConstraints:@[
		[self.diaryView.topAnchor constraintEqualToAnchor:self.topAnchor],
		[self.diaryView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.diaryView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.diaryView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
	]];


    // gesture view
    if (slideUpToUnlockSwitch || bounceOnTapSwitch) {
        self.diaryGestureView = [UIView new];
        [[self diaryGestureView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self addSubview:[self diaryGestureView]];

        if ([slideUpToUnlockPositionValue intValue] == 0) {
            [[self diaryGestureView] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryGestureView.topAnchor constraintEqualToAnchor:self.topAnchor],
                [self.diaryGestureView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                [self.diaryGestureView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                [self.diaryGestureView.widthAnchor constraintEqualToConstant:self.bounds.size.width / 3],
            ]];
        } else if ([slideUpToUnlockPositionValue intValue] == 1) {
            [[self diaryGestureView] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryGestureView.topAnchor constraintEqualToAnchor:self.topAnchor],
                [self.diaryGestureView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
                [self.diaryGestureView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                [self.diaryGestureView.widthAnchor constraintEqualToConstant:self.bounds.size.width / 3],
            ]];
        } else if ([slideUpToUnlockPositionValue intValue] == 2) {
            [[self diaryGestureView] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryGestureView.topAnchor constraintEqualToAnchor:self.topAnchor],
                [self.diaryGestureView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                [self.diaryGestureView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
                [self.diaryGestureView.widthAnchor constraintEqualToConstant:self.bounds.size.width / 3],
            ]];
        }


        // pan gesture
        if (slideUpToUnlockSwitch) {
            self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSlideUpToUnlockPan:)];
            [[self diaryGestureView] addGestureRecognizer:[self panGesture]];
        }


        // tap gesture
        if (bounceOnTapSwitch) {
            self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBounceTap:)];
            [[self tapGesture] setNumberOfTapsRequired:1];
            [[self tapGesture] setNumberOfTouchesRequired:1];
            [[self diaryGestureView] addGestureRecognizer:[self tapGesture]];
        }
    }


    // up next
    if (enableUpNextSwitch) {
        // calendar button
        if (showCalendarEventButtonSwitch) {
            self.diaryCalendarButton = [UIButton new];
            [[self diaryCalendarButton] addTarget:self action:@selector(fetchNextCalendarEvent) forControlEvents:UIControlEventTouchUpInside];
            [[self diaryCalendarButton] setContentMode:UIViewContentModeScaleAspectFit];
            [[self diaryCalendarButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/events/calendar.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            [[self diaryCalendarButton] setTintColor:[GcColorPickerUtils colorWithHex:upNextColorValue]];
            [self addSubview:[self diaryCalendarButton]];

            [[self diaryCalendarButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryCalendarButton.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-32.5],
                [self.diaryCalendarButton.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                [self.diaryCalendarButton.widthAnchor constraintEqualToConstant:21],
                [self.diaryCalendarButton.heightAnchor constraintEqualToConstant:21],
            ]];
        }

        
        // reminder button
        if (showReminderButtonSwitch) {
            self.diaryReminderButton = [UIButton new];
            [[self diaryReminderButton] addTarget:self action:@selector(fetchNextReminder) forControlEvents:UIControlEventTouchUpInside];
            [[self diaryReminderButton] setContentMode:UIViewContentModeScaleAspectFit];
            [[self diaryReminderButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/events/reminder.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            [[self diaryReminderButton] setTintColor:[GcColorPickerUtils colorWithHex:upNextColorValue]];
            [self addSubview:[self diaryReminderButton]];

            [[self diaryReminderButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
            if (showCalendarEventButtonSwitch) {
                [NSLayoutConstraint activateConstraints:@[
                    [self.diaryReminderButton.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-32.5],
                    [self.diaryReminderButton.leadingAnchor constraintEqualToAnchor:self.diaryCalendarButton.trailingAnchor constant:16],
                    [self.diaryReminderButton.widthAnchor constraintEqualToConstant:21],
                    [self.diaryReminderButton.heightAnchor constraintEqualToConstant:21],
                ]];
            } else {
                [NSLayoutConstraint activateConstraints:@[
                    [self.diaryReminderButton.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-32.5],
                    [self.diaryReminderButton.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                    [self.diaryReminderButton.widthAnchor constraintEqualToConstant:21],
                    [self.diaryReminderButton.heightAnchor constraintEqualToConstant:21],
                ]];
            }
        }


        // alarm button
        if (showAlarmButtonSwitch) {
            self.diaryAlarmButton = [UIButton new];
            [[self diaryAlarmButton] addTarget:self action:@selector(fetchNextAlarm) forControlEvents:UIControlEventTouchUpInside];
            [[self diaryAlarmButton] setContentMode:UIViewContentModeScaleAspectFit];
            [[self diaryAlarmButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/events/alarm.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            [[self diaryAlarmButton] setTintColor:[GcColorPickerUtils colorWithHex:upNextColorValue]];
            [self addSubview:[self diaryAlarmButton]];

            [[self diaryAlarmButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
            if ((showCalendarEventButtonSwitch && showReminderButtonSwitch) || (!showCalendarEventButtonSwitch && showReminderButtonSwitch)) {
                [NSLayoutConstraint activateConstraints:@[
                    [self.diaryAlarmButton.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-32.5],
                    [self.diaryAlarmButton.leadingAnchor constraintEqualToAnchor:self.diaryReminderButton.trailingAnchor constant:16],
                    [self.diaryAlarmButton.widthAnchor constraintEqualToConstant:21],
                    [self.diaryAlarmButton.heightAnchor constraintEqualToConstant:21],
                ]];
            } else if (showCalendarEventButtonSwitch && !showReminderButtonSwitch) {
                [NSLayoutConstraint activateConstraints:@[
                    [self.diaryAlarmButton.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-32.5],
                    [self.diaryAlarmButton.leadingAnchor constraintEqualToAnchor:self.diaryCalendarButton.trailingAnchor constant:16],
                    [self.diaryAlarmButton.widthAnchor constraintEqualToConstant:21],
                    [self.diaryAlarmButton.heightAnchor constraintEqualToConstant:21],
                ]];
            } else if (!showCalendarEventButtonSwitch && !showReminderButtonSwitch) {
                [NSLayoutConstraint activateConstraints:@[
                    [self.diaryAlarmButton.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-32.5],
                    [self.diaryAlarmButton.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                    [self.diaryAlarmButton.widthAnchor constraintEqualToConstant:21],
                    [self.diaryAlarmButton.heightAnchor constraintEqualToConstant:21],
                ]];
            }
        }
    }


    if (enableUpNextSwitch || showWeatherSwitch) {
        // event subtitle label
        self.diaryEventSubtitleLabel = [UILabel new];
        [[self diaryEventSubtitleLabel] setTextColor:[GcColorPickerUtils colorWithHex:upNextColorValue]];
        if ([fontFamilyValue intValue] == 0) [[self diaryEventSubtitleLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:18]];
        else if ([fontFamilyValue intValue] == 1) [[self diaryEventSubtitleLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:18]];
        else if ([fontFamilyValue intValue] == 2) [[self diaryEventSubtitleLabel] setFont:[UIFont systemFontOfSize:18 weight:UIFontWeightRegular]];
        [[self diaryEventSubtitleLabel] setTextAlignment:NSTextAlignmentLeft];
        [[self diaryView] addSubview:[self diaryEventSubtitleLabel]];

        [[self diaryEventSubtitleLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        if (enableUpNextSwitch && (showCalendarEventButtonSwitch || showReminderButtonSwitch || showAlarmButtonSwitch)) {
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryEventSubtitleLabel.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                [self.diaryEventSubtitleLabel.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-72],
            ]];
        } else if (!enableUpNextSwitch || (!showCalendarEventButtonSwitch && !showReminderButtonSwitch && !showAlarmButtonSwitch)) {
            if ([overrideTimeDateStyleValue intValue] == 0) {
                [NSLayoutConstraint activateConstraints:@[
                    [self.diaryEventSubtitleLabel.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                    [self.diaryEventSubtitleLabel.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-56],
                ]];
            } else if ([overrideTimeDateStyleValue intValue] == 1) {
                [NSLayoutConstraint activateConstraints:@[
                    [self.diaryEventSubtitleLabel.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                    [self.diaryEventSubtitleLabel.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-29],
                ]];
            }
        }


        // event title label
        self.diaryEventTitleLabel = [UILabel new];
        [[self diaryEventTitleLabel] setTextColor:[GcColorPickerUtils colorWithHex:upNextColorValue]];
        if ([fontFamilyValue intValue] == 0) [[self diaryEventTitleLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:18]];
        else if ([fontFamilyValue intValue] == 1) [[self diaryEventTitleLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:18]];
        else if ([fontFamilyValue intValue] == 2) [[self diaryEventTitleLabel] setFont:[UIFont systemFontOfSize:18 weight:UIFontWeightRegular]];
        [[self diaryEventTitleLabel] setTextAlignment:NSTextAlignmentLeft];
        [[self diaryView] addSubview:[self diaryEventTitleLabel]];

        [[self diaryEventTitleLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryEventTitleLabel.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
            [self.diaryEventTitleLabel.bottomAnchor constraintEqualToAnchor:self.diaryEventSubtitleLabel.topAnchor],
        ]];
    }
    
    
    if ([overrideTimeDateStyleValue intValue] == 0) {
        // date label
        self.diaryDateLabel = [UILabel new];
        [[self diaryDateLabel] setTextColor:[GcColorPickerUtils colorWithHex:timeDateColorValue]];
        if ([fontFamilyValue intValue] == 0) [[self diaryDateLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:28]];
        else if ([fontFamilyValue intValue] == 1) [[self diaryDateLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:28]];
        else if ([fontFamilyValue intValue] == 2) [[self diaryDateLabel] setFont:[UIFont systemFontOfSize:28 weight:UIFontWeightRegular]];
        [[self diaryDateLabel] setTextAlignment:NSTextAlignmentLeft];

            
        // time label
        self.diaryTimeLabel = [UILabel new];
        [[self diaryTimeLabel] setTextColor:[GcColorPickerUtils colorWithHex:timeDateColorValue]];
        if ([fontFamilyValue intValue] == 0) [[self diaryTimeLabel] setFont:[UIFont fontWithName:@"Selawik-Light" size:78]];
        else if ([fontFamilyValue intValue] == 1) [[self diaryTimeLabel] setFont:[UIFont fontWithName:@"OpenSans-Light" size:78]];
        else if ([fontFamilyValue intValue] == 2) [[self diaryTimeLabel] setFont:[UIFont systemFontOfSize:78 weight:UIFontWeightLight]];
        [[self diaryTimeLabel] setTextAlignment:NSTextAlignmentLeft];


        [self layoutTimeAndDate];
    }


    // battery icon
    if (showBatteryIconSwitch) {
        self.diaryBatteryIcon = [UIImageView new];
        [[self diaryBatteryIcon] setContentMode:UIViewContentModeScaleAspectFit];
        [[self diaryView] addSubview:[self diaryBatteryIcon]];
        [[%c(SBUIController) sharedInstance] batteryCapacityAsPercentage];

        [[self diaryBatteryIcon] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryBatteryIcon.trailingAnchor constraintEqualToAnchor:self.diaryView.trailingAnchor constant:-16],
            [self.diaryBatteryIcon.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-29.5],
            [self.diaryBatteryIcon.widthAnchor constraintEqualToConstant:23],
            [self.diaryBatteryIcon.heightAnchor constraintEqualToConstant:23],
        ]];


        // battery percentage label
        if (showBatteryPercentageSwitch) {
            self.diaryBatteryPercentageLabel = [UILabel new];
            [[self diaryBatteryPercentageLabel] setTextColor:[GcColorPickerUtils colorWithHex:connectivityColorValue]];
            if ([fontFamilyValue intValue] == 0) [[self diaryBatteryPercentageLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:6]];
            else if ([fontFamilyValue intValue] == 1) [[self diaryBatteryPercentageLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:6]];
            else if ([fontFamilyValue intValue] == 2) [[self diaryBatteryPercentageLabel] setFont:[UIFont systemFontOfSize:6 weight:UIFontWeightRegular]];
            [[self diaryBatteryPercentageLabel] setTextAlignment:NSTextAlignmentLeft];
            [[self diaryBatteryIcon] addSubview:[self diaryBatteryPercentageLabel]];

            [[self diaryBatteryPercentageLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryBatteryPercentageLabel.centerXAnchor constraintEqualToAnchor:self.diaryBatteryIcon.centerXAnchor],
                [self.diaryBatteryPercentageLabel.topAnchor constraintEqualToAnchor:self.diaryBatteryIcon.topAnchor constant:-2],   
            ]];
        }
    }
	
    
    // wifi icon
    if (showWifiIconSwitch) {
        self.diaryWifiIcon = [UIImageView new];
        [[self diaryWifiIcon] setContentMode:UIViewContentModeScaleAspectFit];
        [[self diaryView] addSubview:[self diaryWifiIcon]];
        [[%c(SBWiFiManager) sharedInstance] signalStrengthBars];

        if (showBatteryIconSwitch) {
            [[self diaryWifiIcon] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryWifiIcon.trailingAnchor constraintEqualToAnchor:self.diaryBatteryIcon.leadingAnchor constant:-20],
                [self.diaryWifiIcon.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-32.5],
                [self.diaryWifiIcon.widthAnchor constraintEqualToConstant:20],
                [self.diaryWifiIcon.heightAnchor constraintEqualToConstant:20],
            ]];
        } else {
            [[self diaryWifiIcon] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryWifiIcon.trailingAnchor constraintEqualToAnchor:self.diaryView.trailingAnchor constant:-16],
                [self.diaryWifiIcon.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-32.5],
                [self.diaryWifiIcon.widthAnchor constraintEqualToConstant:20],
                [self.diaryWifiIcon.heightAnchor constraintEqualToConstant:20],
            ]];
        }
    }


    // cellular icon
    if (showCellularIconSwitch) {
        self.diaryCellularIcon = [UIImageView new];
        [[self diaryCellularIcon] setContentMode:UIViewContentModeScaleAspectFit];
        [[self diaryView] addSubview:[self diaryCellularIcon]];

        if ((showBatteryIconSwitch && showWifiIconSwitch) || (showWifiIconSwitch && showCellularIconSwitch)) {
            [[self diaryCellularIcon] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryCellularIcon.trailingAnchor constraintEqualToAnchor:self.diaryWifiIcon.leadingAnchor constant:-16],
                [self.diaryCellularIcon.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-31],
                [self.diaryCellularIcon.widthAnchor constraintEqualToConstant:22],
                [self.diaryCellularIcon.heightAnchor constraintEqualToConstant:22],
            ]];
        } else if (showBatteryIconSwitch && !showWifiIconSwitch) {
            [[self diaryCellularIcon] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryCellularIcon.trailingAnchor constraintEqualToAnchor:self.diaryBatteryIcon.leadingAnchor constant:-20],
                [self.diaryCellularIcon.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-31],
                [self.diaryCellularIcon.widthAnchor constraintEqualToConstant:22],
                [self.diaryCellularIcon.heightAnchor constraintEqualToConstant:22],
            ]];
        } else if (!showBatteryIconSwitch && !showWifiIconSwitch) {
            [[self diaryCellularIcon] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryCellularIcon.trailingAnchor constraintEqualToAnchor:self.diaryView.trailingAnchor constant:-16],
                [self.diaryCellularIcon.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-31],
                [self.diaryCellularIcon.widthAnchor constraintEqualToConstant:22],
                [self.diaryCellularIcon.heightAnchor constraintEqualToConstant:22],
            ]];
        }


        // cellular type label
        if (showCellularTypeSwitch) {
            self.diaryCellularTypeLabel = [UILabel new];
            [[self diaryCellularTypeLabel] setTextColor:[GcColorPickerUtils colorWithHex:connectivityColorValue]];
            if ([fontFamilyValue intValue] == 0) [[self diaryCellularTypeLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:6]];
            else if ([fontFamilyValue intValue] == 1) [[self diaryCellularTypeLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:6]];
            else if ([fontFamilyValue intValue] == 2) [[self diaryCellularTypeLabel] setFont:[UIFont systemFontOfSize:6 weight:UIFontWeightRegular]];
            [[self diaryCellularTypeLabel] setTextAlignment:NSTextAlignmentLeft];
            [[self diaryCellularIcon] addSubview:[self diaryCellularTypeLabel]];

            [[self diaryCellularTypeLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryCellularTypeLabel.leadingAnchor constraintEqualToAnchor:self.diaryCellularIcon.leadingAnchor],
                [self.diaryCellularTypeLabel.topAnchor constraintEqualToAnchor:self.diaryCellularIcon.topAnchor],   
            ]];
        }
    }

}

%new
- (void)layoutTimeAndDate { // update the layout of the time and date for event changes

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[self diaryDateLabel] removeFromSuperview];
        [[self diaryTimeLabel] removeFromSuperview];
        [[self diaryView] addSubview:[self diaryDateLabel]];
        [[self diaryView] addSubview:[self diaryTimeLabel]];

        if (enableUpNextSwitch || showWeatherSwitch) {
            if (![[[self diaryEventTitleLabel] text] isEqualToString:@""]) {
                // date label
                [[self diaryDateLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
                [NSLayoutConstraint activateConstraints:@[
                    [self.diaryDateLabel.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                    [self.diaryDateLabel.trailingAnchor constraintEqualToAnchor:self.diaryView.trailingAnchor],
                    [self.diaryDateLabel.bottomAnchor constraintEqualToAnchor:self.diaryEventTitleLabel.topAnchor constant:-24],
                ]];


                // time label
                [[self diaryTimeLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
                [NSLayoutConstraint activateConstraints:@[
                    [self.diaryTimeLabel.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                    [self.diaryTimeLabel.trailingAnchor constraintEqualToAnchor:self.diaryView.trailingAnchor],
                    [self.diaryTimeLabel.bottomAnchor constraintEqualToAnchor:self.diaryDateLabel.topAnchor constant:6],
                ]];
            } else {
                // date label
                [[self diaryDateLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
                [NSLayoutConstraint activateConstraints:@[
                    [self.diaryDateLabel.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                    [self.diaryDateLabel.trailingAnchor constraintEqualToAnchor:self.diaryView.trailingAnchor],
                    [self.diaryDateLabel.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-72],
                ]];


                // time label
                [[self diaryTimeLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
                [NSLayoutConstraint activateConstraints:@[
                    [self.diaryTimeLabel.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                    [self.diaryTimeLabel.trailingAnchor constraintEqualToAnchor:self.diaryView.trailingAnchor],
                    [self.diaryTimeLabel.bottomAnchor constraintEqualToAnchor:self.diaryDateLabel.topAnchor constant:6],
                ]];
            }
        } else {
            // date label
            [[self diaryDateLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryDateLabel.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                [self.diaryDateLabel.trailingAnchor constraintEqualToAnchor:self.diaryView.trailingAnchor],
                [self.diaryDateLabel.bottomAnchor constraintEqualToAnchor:self.diaryView.bottomAnchor constant:-72],
            ]];


            // time label
            [[self diaryTimeLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
            [NSLayoutConstraint activateConstraints:@[
                [self.diaryTimeLabel.leadingAnchor constraintEqualToAnchor:self.diaryView.leadingAnchor constant:16],
                [self.diaryTimeLabel.trailingAnchor constraintEqualToAnchor:self.diaryView.trailingAnchor],
                [self.diaryTimeLabel.bottomAnchor constraintEqualToAnchor:self.diaryDateLabel.topAnchor constant:6],
            ]];
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryRotateNotification" object:nil];
        });
    });

}

%new
- (void)updateDiaryTimeAndDate { // update diary

    NSDateFormatter* timeFormat = [NSDateFormatter new];
    [timeFormat setDateFormat:timeFormatValue];
    [[self diaryTimeLabel] setText:[timeFormat stringFromDate:[NSDate date]]];

    if (!isTimerRunning) {
        NSDateFormatter* dateFormat = [NSDateFormatter new];
        [dateFormat setDateFormat:dateFormatValue];
        if (useCustomDateLocaleSwitch) [dateFormat setLocale:[[NSLocale alloc] initWithLocaleIdentifier:customDateLocaleValue]];
        [[self diaryDateLabel] setText:[dateFormat stringFromDate:[NSDate date]]];
    }
    
}

%new
- (void)fetchNextCalendarEvent { // fetch the next event

    EKEventStore* store = [EKEventStore new];
    NSCalendar* calendar = [NSCalendar currentCalendar];

    NSDateComponents* todayEventsComponents = [NSDateComponents new];
    todayEventsComponents.day = 0;
    NSDate* todayEvents = [calendar dateByAddingComponents:todayEventsComponents toDate:[NSDate date] options:0];

    NSDateComponents* daysFromNowComponents = [NSDateComponents new];
    daysFromNowComponents.day = [eventRangeValue intValue];
    NSDate* daysFromNow = [calendar dateByAddingComponents:daysFromNowComponents toDate:[NSDate date] options:0];

    NSPredicate* calendarPredicate = [store predicateForEventsWithStartDate:todayEvents endDate:daysFromNow calendars:nil];

    NSArray* events = [store eventsMatchingPredicate:calendarPredicate];

    if ([events count]) {
        [[self diaryEventTitleLabel] setText:[NSString stringWithFormat:@"%@", [events[0] title]]];

        if (![events[0] isAllDay]) {
            NSDateComponents* startComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:[events[0] startDate]];
            NSDateComponents* endComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:[events[0] endDate]];
            [[self diaryEventSubtitleLabel] setText:[NSString stringWithFormat:@"%02ld:%02ld — %02ld:%02ld", [startComponents hour], [startComponents minute], [endComponents hour], [endComponents minute]]];
        } else {
            if ([[DRYLocalization stringForKey:@"ALL_DAY"] isEqual:nil]) [[self diaryEventSubtitleLabel] setText:@"All day"];
            else if (![[DRYLocalization stringForKey:@"ALL_DAY"] isEqual:nil]) [[self diaryEventSubtitleLabel] setText:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"ALL_DAY"]]];
        }
    } else {
        [[self diaryEventTitleLabel] setText:@""];
        [[self diaryEventSubtitleLabel] setText:@""];
    }

    if ([overrideTimeDateStyleValue intValue] == 0) [self layoutTimeAndDate];

}

%new
- (void)fetchNextReminder { // fetch the next reminder

    EKEventStore* store = [EKEventStore new];
    NSCalendar* calendar = [NSCalendar currentCalendar];

    NSDateComponents* todayRemindersComponents = [NSDateComponents new];
    todayRemindersComponents.day = -1;
    NSDate* todayReminders = [calendar dateByAddingComponents:todayRemindersComponents toDate:[NSDate date] options:0];

    NSDateComponents* daysFromNowComponents = [NSDateComponents new];
    daysFromNowComponents.day = [eventRangeValue intValue];
    NSDate* daysFromNow = [calendar dateByAddingComponents:daysFromNowComponents toDate:[NSDate date] options:0];

    NSPredicate* reminderPredicate = [store predicateForIncompleteRemindersWithDueDateStarting:todayReminders ending:daysFromNow calendars:nil];
    
    [store fetchRemindersMatchingPredicate:reminderPredicate completion:^(NSArray* reminders) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([reminders count]) {
                [[self diaryEventTitleLabel] setText:[NSString stringWithFormat:@"%@", [reminders[0] title]]];

                NSDateComponents* endComponents = [reminders[0] dueDateComponents];
                NSString* helloIfYoureReadingThis = [NSString stringWithFormat:@"%02ld", [endComponents hour]]; // if a reminder does not have a due time set ios will display unix things
                if ([helloIfYoureReadingThis intValue] > 999) [[self diaryEventSubtitleLabel] setText:@"—"];
                else [[self diaryEventSubtitleLabel] setText:[NSString stringWithFormat:@"%02ld:%02ld", [endComponents hour], [endComponents minute]]];
            } else {
                [[self diaryEventTitleLabel] setText:@""];
                [[self diaryEventSubtitleLabel] setText:@""];
            }

        });
    }];

    if ([overrideTimeDateStyleValue intValue] == 0) [self layoutTimeAndDate];

}

%new
- (void)fetchNextAlarm { // fetch the next alarm

    if ([[[[%c(SBScheduledAlarmObserver) sharedInstance] valueForKey:@"_alarmManager"] cache] nextAlarm]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            if ([[DRYLocalization stringForKey:@"ALARM"] isEqual:nil]) [[self diaryEventTitleLabel] setText:@"Alarm"];
            else if (![[DRYLocalization stringForKey:@"ALARM"] isEqual:nil]) [[self diaryEventTitleLabel] setText:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"ALARM"]]];

            NSDate* fireDate = [[[[[%c(SBScheduledAlarmObserver) sharedInstance] valueForKey:@"_alarmManager"] cache] nextAlarm] nextFireDate];
            NSDateComponents* fireComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:fireDate];
            [[self diaryEventSubtitleLabel] setText:[NSString stringWithFormat:@"%02ld:%02ld", [fireComponents hour], [fireComponents minute]]];
        });
    } else {
        [[self diaryEventTitleLabel] setText:@""];
        [[self diaryEventSubtitleLabel] setText:@""];
    }

    if ([overrideTimeDateStyleValue intValue] == 0) [self layoutTimeAndDate];

}

%new
- (void)updateWeather { // update weather data

    [[PDDokdo sharedInstance] refreshWeatherData];

	[[self diaryEventTitleLabel] setText:[NSString stringWithFormat:@"%@ %@", [[PDDokdo sharedInstance] currentLocation], [[PDDokdo sharedInstance] currentTemperature]]];
	[[self diaryEventSubtitleLabel] setText:[NSString stringWithFormat:@"%@", [[PDDokdo sharedInstance] currentConditions]]];

    if ([overrideTimeDateStyleValue intValue] == 0) [self layoutTimeAndDate];

}

%new
- (void)handleSlideUpToUnlockPan:(UIPanGestureRecognizer *)recognizer { // unlock device with slide up

    CGPoint translation = CGPointMake(0, 0);
    
    if ([recognizer state] == UIGestureRecognizerStateChanged) {
        translation = [recognizer translationInView:[self diaryView]];
        if (translation.y > 0) return;
        double substractedAlpha = fabs(translation.y / 200);
        
        [UIView animateWithDuration:0.1 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [[self diaryView] setTransform:CGAffineTransformMakeTranslation(0, translation.y)];
            if ([overrideTimeDateStyleValue intValue] == 1) {
                [[timeDateView diaryTimeLabel] setTransform:CGAffineTransformMakeTranslation(0, translation.y)];
                [[timeDateView diaryDateLabel] setTransform:CGAffineTransformMakeTranslation(0, translation.y)];
                [[timeDateView diaryTimeLabel] setAlpha:1 - substractedAlpha];
                [[timeDateView diaryDateLabel] setAlpha:1 - substractedAlpha];
            }
            if (enableUpNextSwitch) {
                [[self diaryCalendarButton] setTransform:CGAffineTransformMakeTranslation(0, translation.y)];
                [[self diaryReminderButton] setTransform:CGAffineTransformMakeTranslation(0, translation.y)];
                [[self diaryAlarmButton] setTransform:CGAffineTransformMakeTranslation(0, translation.y)];
            }
        } completion:nil];
        
        [[self diaryView] setAlpha:1 - substractedAlpha];
        if (enableUpNextSwitch) {
            if (showCalendarEventButtonSwitch) [[self diaryCalendarButton] setAlpha:1 - substractedAlpha];
            if (showReminderButtonSwitch) [[self diaryReminderButton] setAlpha:1 - substractedAlpha];
            if (showAlarmButtonSwitch) [[self diaryAlarmButton] setAlpha:1 - substractedAlpha];
        }
        if (translation.y <= -200) [[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:17 withOptions:nil];
    } else if ([recognizer state] == UIGestureRecognizerStateEnded) {
        if ([[%c(SBLockScreenManager) sharedInstance] _isPasscodeVisible]) return;
        [self resetDiaryViewTransform];
    }

}

%new
- (void)resetDiaryViewTransform { // transform diary back

    [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [[self diaryView] setTransform:CGAffineTransformIdentity];
        [[self diaryView] setAlpha:1];
        if ([overrideTimeDateStyleValue intValue] == 1) {
            [[timeDateView diaryTimeLabel] setTransform:CGAffineTransformIdentity];
            [[timeDateView diaryDateLabel] setTransform:CGAffineTransformIdentity];
            [[timeDateView diaryTimeLabel] setAlpha:1];
            [[timeDateView diaryDateLabel] setAlpha:1];
        }
        if (enableUpNextSwitch) {
            if (showCalendarEventButtonSwitch) {
                [[self diaryCalendarButton] setTransform:CGAffineTransformIdentity];
                [[self diaryCalendarButton] setAlpha:1];
            }
            if (showReminderButtonSwitch) {
                [[self diaryReminderButton] setTransform:CGAffineTransformIdentity];
                [[self diaryReminderButton] setAlpha:1];
            }
            if (showAlarmButtonSwitch) {
                [[self diaryAlarmButton] setTransform:CGAffineTransformIdentity];
                [[self diaryAlarmButton] setAlpha:1];
            }
        }
    } completion:nil];

}

%new
- (void)handleBounceTap:(UITapGestureRecognizer *)recognizer { // bounce on tap

    if (isBouncing) return;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect diaryViewFrame = [[self diaryView] frame];
        diaryViewFrame.origin.y -= 35;
        [[self diaryView] setFrame:diaryViewFrame];

        if ([overrideTimeDateStyleValue intValue] == 1) {
            CGRect timeLabelFrame = [[timeDateView diaryTimeLabel] frame];
            timeLabelFrame.origin.y -= 35;
            [[timeDateView diaryTimeLabel] setFrame:timeLabelFrame];

            CGRect dateLabelFrame = [[timeDateView diaryDateLabel] frame];
            dateLabelFrame.origin.y -= 35;
            [[timeDateView diaryDateLabel] setFrame:dateLabelFrame];
        }

        if (enableUpNextSwitch) {
            if (showCalendarEventButtonSwitch) {
                CGRect calendarButtonFrame = [[self diaryCalendarButton] frame];
                calendarButtonFrame.origin.y -= 35;
                [[self diaryCalendarButton] setFrame:calendarButtonFrame];
            }
            if (showReminderButtonSwitch) {
                CGRect reminderButtonFrame = [[self diaryReminderButton] frame];
                reminderButtonFrame.origin.y -= 35;
                [[self diaryReminderButton] setFrame:reminderButtonFrame];
            }
            if (showAlarmButtonSwitch) {
                CGRect alarmButtonFrame = [[self diaryAlarmButton] frame];
                alarmButtonFrame.origin.y -= 35;
                [[self diaryAlarmButton] setFrame:alarmButtonFrame];
            }
        }

        isBouncing = YES;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0.2 options:UIViewAnimationOptionCurveEaseIn animations:^{
            CGRect diaryViewFrame = [[self diaryView] frame];
            diaryViewFrame.origin.y += 35;
            [[self diaryView] setFrame:diaryViewFrame];

            if ([overrideTimeDateStyleValue intValue] == 1) {
                CGRect timeLabelFrame = [[timeDateView diaryTimeLabel] frame];
                timeLabelFrame.origin.y += 35;
                [[timeDateView diaryTimeLabel] setFrame:timeLabelFrame];

                CGRect dateLabelFrame = [[timeDateView diaryDateLabel] frame];
                dateLabelFrame.origin.y += 35;
                [[timeDateView diaryDateLabel] setFrame:dateLabelFrame];
            }

            if (enableUpNextSwitch) {
                if (showCalendarEventButtonSwitch) {
                    CGRect calendarButtonFrame = [[self diaryCalendarButton] frame];
                    calendarButtonFrame.origin.y += 35;
                    [[self diaryCalendarButton] setFrame:calendarButtonFrame];
                }
                if (showReminderButtonSwitch) {
                    CGRect reminderButtonFrame = [[self diaryReminderButton] frame];
                    reminderButtonFrame.origin.y += 35;
                    [[self diaryReminderButton] setFrame:reminderButtonFrame];
                }
                if (showAlarmButtonSwitch) {
                    CGRect alarmButtonFrame = [[self diaryAlarmButton] frame];
                    alarmButtonFrame.origin.y += 35;
                    [[self diaryAlarmButton] setFrame:alarmButtonFrame];
                }
            }
        } completion:^(BOOL finished) {
            isBouncing = NO;
        }];
    }];

}

%end

%hook CSCoverSheetViewController

- (void)viewWillAppear:(BOOL)animated { // update diary when lock screen appears

	%orig;

    [coverSheetView resetDiaryViewTransform];
	[self requestDiaryTimeAndDateUpdate];
    if (enableUpNextSwitch && [coverSheetView diaryView]) {
        if ([defaultEventsValue intValue] == 0) [coverSheetView fetchNextCalendarEvent];
        else if ([defaultEventsValue intValue] == 1) [coverSheetView fetchNextReminder];
        else if ([defaultEventsValue intValue] == 2) [coverSheetView fetchNextAlarm];
    }
    if (showWeatherSwitch && [coverSheetView diaryView]) [coverSheetView updateWeather];
	if (!timeAndDateTimer) timeAndDateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(requestDiaryTimeAndDateUpdate) userInfo:nil repeats:YES];
    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:@"diaryHideStatusBar" object:nil];
    [notificationCenter postNotificationName:@"diaryRotateNotification" object:nil];

    if ([overrideTimeDateStyleValue intValue] == 1) [timeDateView layoutTimeAndDate];

}

- (void)viewWillDisappear:(BOOL)animated { // stop the timers when lock screen disappears

	%orig;

	[timeAndDateTimer invalidate];
	timeAndDateTimer = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryUnhideStatusBar" object:nil];

}

%new
- (void)requestDiaryTimeAndDateUpdate { // update diary

    if ([overrideTimeDateStyleValue intValue] == 0) [coverSheetView updateDiaryTimeAndDate];
    else if ([overrideTimeDateStyleValue intValue] == 1) [timeDateView updateDiaryTimeAndDate];
    
}

%end

%hook SBBacklightController

- (void)turnOnScreenFullyWithBacklightSource:(long long)arg1 { // update diary when screen turns on

	%orig;

    if (![[%c(SBLockScreenManager) sharedInstance] isLockScreenVisible] || isScreenOnTimeAndDate) return; // this method gets called not only when the screen gets turned on, so i verify that it was turned on by checking if the lock screen is visible
	[self requestDiaryTimeAndDateUpdate];
    if (enableUpNextSwitch && [coverSheetView diaryView]) {
        if ([defaultEventsValue intValue] == 0) [coverSheetView fetchNextCalendarEvent];
        else if ([defaultEventsValue intValue] == 1) [coverSheetView fetchNextReminder];
        else if ([defaultEventsValue intValue] == 2) [coverSheetView fetchNextAlarm];
    }
    if (showWeatherSwitch && [coverSheetView diaryView]) [coverSheetView updateWeather];
	if (!timeAndDateTimer) timeAndDateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(requestDiaryTimeAndDateUpdate) userInfo:nil repeats:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryUpdateNotificationList" object:nil];
    isScreenOnTimeAndDate = YES;

}

%new
- (void)requestDiaryTimeAndDateUpdate { // update diary

    if ([overrideTimeDateStyleValue intValue] == 0) [coverSheetView updateDiaryTimeAndDate];
    else if ([overrideTimeDateStyleValue intValue] == 1) [timeDateView updateDiaryTimeAndDate];
    
}

%end

%hook SBLockScreenManager

- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 { // stop the timers when device was locked

	%orig;

	[timeAndDateTimer invalidate];
	timeAndDateTimer = nil;
    isScreenOnTimeAndDate = NO;
    [coverSheetView resetDiaryViewTransform];

}

%end

%hook SBFLockScreenDateSubtitleView

- (void)setString:(NSString *)arg1 { // apply running timer to the date label

    %orig;

    if ([arg1 containsString:@":"]) {
        isTimerRunning = YES;
        [[coverSheetView diaryDateLabel] setText:arg1];
    } else {
        isTimerRunning = NO;
    }

}

%end

%hook SBUIPasscodeLockNumberPad

- (void)_cancelButtonHit { // reset the time and date transform

    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.15 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [coverSheetView resetDiaryViewTransform];
    });

}

%end

%hook NCNotificationStructuredListViewController

- (void)viewDidLoad { // make things like notifications fade below the time and date

    %orig;

    if (notificationMask) return;
    notificationMask = [CAGradientLayer layer];
    [notificationMask setColors:[NSArray arrayWithObjects:(id)[[UIColor whiteColor] CGColor], (id)[[UIColor clearColor] CGColor], nil]];
    [self updateFrameAfterRotation];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateFrameAfterRotation) name:@"diaryRotateNotification" object:nil];

}

%new
- (void)updateFrameAfterRotation { // update mask frame when rotated

    if ([overrideTimeDateStyleValue intValue] == 0) {
        [notificationMask setFrame:[[self view] bounds]];
        if ([[[coverSheetView diaryEventTitleLabel] text] isEqualToString:@""] || ![coverSheetView diaryEventTitleLabel]) {
            if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) [notificationMask setLocations:[NSArray arrayWithObjects:@(0.7), @(0.775), nil]];
            else [notificationMask setLocations:[NSArray arrayWithObjects:@(0.75), @(0.825), nil]];
        } else {
            if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) [notificationMask setLocations:[NSArray arrayWithObjects:@(0.6), @(0.675), nil]];
            else [notificationMask setLocations:[NSArray arrayWithObjects:@(0.75), @(0.825), nil]];
        }
        [[[self view] layer] setMask:notificationMask];
    } else if ([overrideTimeDateStyleValue intValue] == 1) {
        [notificationMask setFrame:[[self view] bounds]];
        if ([[[coverSheetView diaryEventTitleLabel] text] isEqualToString:@""]) {
            if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) [notificationMask setLocations:[NSArray arrayWithObjects:@(0.825), @(0.9), nil]];
            else [notificationMask setLocations:[NSArray arrayWithObjects:@(0.75), @(0.825), nil]];
        } else if (![[[coverSheetView diaryEventTitleLabel] text] isEqualToString:@""]) {
            if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) [notificationMask setLocations:[NSArray arrayWithObjects:@(0.775), @(0.85), nil]];
            else [notificationMask setLocations:[NSArray arrayWithObjects:@(0.75), @(0.825), nil]];
        } else {
            if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation])) [notificationMask setLocations:[NSArray arrayWithObjects:@(0.775), @(0.85), nil]];
            else [notificationMask setLocations:[NSArray arrayWithObjects:@(0.75), @(0.825), nil]];
        }
        [[[self view] layer] setMask:notificationMask];
    }

}

%end

%hook SBUIController

- (id)init { // add a notification observer

    if (!showBatteryIconSwitch) return %orig;
    id orig = %orig;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(batteryCapacityAsPercentage) name:NSProcessInfoPowerStateDidChangeNotification object:nil];

    return orig;

}

- (int)batteryCapacityAsPercentage { // update battery icon

    if (!showBatteryIconSwitch) return %orig;
    int orig = %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self isOnAC]) {
            if (![[NSProcessInfo processInfo] isLowPowerModeEnabled]) {
                if (orig == 0) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/discharging/discharging0.png"]];
                else if (orig >= 1 && orig <= 10) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/discharging/discharging1-10.png"]];
                else if (orig >= 11 && orig <= 20) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/discharging/discharging11-20.png"]];
                else if (orig >= 21 && orig <= 30) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/discharging/discharging21-30.png"]];
                else if (orig >= 31 && orig <= 40) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/discharging/discharging31-40.png"]];
                else if (orig >= 41 && orig <= 50) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/discharging/discharging41-50.png"]];
                else if (orig >= 51 && orig <= 60) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/discharging/discharging51-60.png"]];
                else if (orig >= 61 && orig <= 70) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/discharging/discharging61-70.png"]];
                else if (orig >= 71 && orig <= 80) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/discharging/discharging71-80.png"]];
                else if (orig >= 81 && orig <= 90) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/discharging/discharging81-90.png"]];
                else if (orig >= 91 && orig <= 100) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/discharging/discharging91-100.png"]];
            } else {
                if (orig == 0) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/low_power_mode/discharging_low_power_mode0.png"]];
                else if (orig >= 1 && orig <= 10) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/low_power_mode/discharging_low_power_mode1-10.png"]];
                else if (orig >= 11 && orig <= 20) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/low_power_mode/discharging_low_power_mode11-20.png"]];
                else if (orig >= 21 && orig <= 30) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/low_power_mode/discharging_low_power_mode21-30.png"]];
                else if (orig >= 31 && orig <= 40) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/low_power_mode/discharging_low_power_mode31-40.png"]];
                else if (orig >= 41 && orig <= 50) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/low_power_mode/discharging_low_power_mode41-50.png"]];
                else if (orig >= 51 && orig <= 60) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/low_power_mode/discharging_low_power_mode51-60.png"]];
                else if (orig >= 61 && orig <= 70) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/low_power_mode/discharging_low_power_mode61-70.png"]];
                else if (orig >= 71 && orig <= 80) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/low_power_mode/discharging_low_power_mode71-80.png"]];
                else if (orig >= 81 && orig <= 90) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/low_power_mode/discharging_low_power_mode81-90.png"]];
                else if (orig >= 91 && orig <= 100) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/low_power_mode/discharging_low_power_mode91-100.png"]];
            }
        } else {
            if (orig == 0) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/charging/charging0.png"]];
            else if (orig >= 1 && orig <= 10) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/charging/charging1-10.png"]];
            else if (orig >= 11 && orig <= 20) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/charging/charging11-20.png"]];
            else if (orig >= 21 && orig <= 30) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/charging/charging21-30.png"]];
            else if (orig >= 31 && orig <= 40) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/charging/charging31-40.png"]];
            else if (orig >= 41 && orig <= 50) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/charging/charging41-50.png"]];
            else if (orig >= 51 && orig <= 60) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/charging/charging51-60.png"]];
            else if (orig >= 61 && orig <= 70) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/charging/charging61-70.png"]];
            else if (orig >= 71 && orig <= 80) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/charging/charging71-80.png"]];
            else if (orig >= 81 && orig <= 90) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/charging/charging81-90.png"]];
            else if (orig >= 91 && orig <= 100) [[coverSheetView diaryBatteryIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/battery/charging/charging91-100.png"]];
        }

        coverSheetView.diaryBatteryIcon.image = [[[coverSheetView diaryBatteryIcon] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [[coverSheetView diaryBatteryIcon] setTintColor:[GcColorPickerUtils colorWithHex:connectivityColorValue]];
        if (showBatteryPercentageSwitch) [[coverSheetView diaryBatteryPercentageLabel] setText:[NSString stringWithFormat:@"%i%@", orig, @"%"]];
    });

    return orig;

}

%end

%hook SBWiFiManager

- (int)signalStrengthBars { // update wifi and cellular icon

    if (!showWifiIconSwitch) return %orig;
	int strength = %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (![[%c(SBAirplaneModeController) sharedInstance] isInAirplaneMode]) {
            if ([self isAssociated]) {
                if (strength == 1) [[coverSheetView diaryWifiIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/wifi1.png"]];
                else if (strength == 2) [[coverSheetView diaryWifiIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/wifi2.png"]];
                else if (strength == 3) [[coverSheetView diaryWifiIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/wifi3.png"]];
            } else {
                [[coverSheetView diaryWifiIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/wifi0.png"]];
            }
        } else if ([[%c(SBAirplaneModeController) sharedInstance] isInAirplaneMode] && [self isAssociated]) {
            if (strength == 1) [[coverSheetView diaryWifiIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/wifi1.png"]];
            else if (strength == 2) [[coverSheetView diaryWifiIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/wifi2.png"]];
            else if (strength == 3) [[coverSheetView diaryWifiIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/wifi3.png"]];
            [[coverSheetView diaryCellularIcon] setHidden:NO];
            [[coverSheetView diaryCellularIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/airplane.png"]];
        } else if ([[%c(SBAirplaneModeController) sharedInstance] isInAirplaneMode] && ![self isAssociated]) {
            [[coverSheetView diaryWifiIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/airplane.png"]];
            [[coverSheetView diaryCellularIcon] setHidden:YES];
        }

        coverSheetView.diaryWifiIcon.image = [[[coverSheetView diaryWifiIcon] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        coverSheetView.diaryCellularIcon.image = [[[coverSheetView diaryCellularIcon] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [[coverSheetView diaryWifiIcon] setTintColor:[GcColorPickerUtils colorWithHex:connectivityColorValue]];
        [[coverSheetView diaryCellularIcon] setTintColor:[GcColorPickerUtils colorWithHex:connectivityColorValue]];
    });

    return strength;

}

%end

%hook _UIStatusBarCellularSignalView

- (void)_updateActiveBars { // update cellular icon

    %orig;
    if (!showCellularIconSwitch) return;

    if (![[%c(SBAirplaneModeController) sharedInstance] isInAirplaneMode]) {
        int strength = [self numberOfActiveBars];

        [[coverSheetView diaryCellularIcon] setHidden:NO];
        if (strength == 1) [[coverSheetView diaryCellularIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/cellular1.png"]];
        else if (strength == 2) [[coverSheetView diaryCellularIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/cellular2.png"]];
        else if (strength == 3) [[coverSheetView diaryCellularIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/cellular3.png"]];
        else if (strength == 4) [[coverSheetView diaryCellularIcon] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/connectivity/cellular4.png"]];
        coverSheetView.diaryCellularIcon.image = [[[coverSheetView diaryCellularIcon] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [[coverSheetView diaryCellularIcon] setTintColor:[GcColorPickerUtils colorWithHex:connectivityColorValue]];

        if (showCellularTypeSwitch) {
            CTTelephonyNetworkInfo* telephonyInfo = [CTTelephonyNetworkInfo new];
            NSString* dataServiceIdentifier = [telephonyInfo dataServiceIdentifier];
            if (@available(iOS 13.0, *)) {
                if ([telephonyInfo.serviceCurrentRadioAccessTechnology[dataServiceIdentifier] isEqual:CTRadioAccessTechnologyEdge]) [[coverSheetView diaryCellularTypeLabel] setText:@"E"];
                else if ([telephonyInfo.serviceCurrentRadioAccessTechnology[dataServiceIdentifier] isEqual:CTRadioAccessTechnologyWCDMA]) [[coverSheetView diaryCellularTypeLabel] setText:@"2G"];
                else if ([telephonyInfo.serviceCurrentRadioAccessTechnology[dataServiceIdentifier] isEqual:CTRadioAccessTechnologyLTE]) [[coverSheetView diaryCellularTypeLabel] setText:@"LTE"];
                else if ([telephonyInfo.serviceCurrentRadioAccessTechnology[dataServiceIdentifier] isEqual:CTRadioAccessTechnologyGPRS]) [[coverSheetView diaryCellularTypeLabel] setText:@"2G"];
                else if ([telephonyInfo.serviceCurrentRadioAccessTechnology[dataServiceIdentifier] isEqual:CTRadioAccessTechnologyeHRPD]) [[coverSheetView diaryCellularTypeLabel] setText:@"3G"];
                else if ([telephonyInfo.serviceCurrentRadioAccessTechnology[dataServiceIdentifier] isEqual:CTRadioAccessTechnologyHSDPA]) [[coverSheetView diaryCellularTypeLabel] setText:@"3G"];
                else if ([telephonyInfo.serviceCurrentRadioAccessTechnology[dataServiceIdentifier] isEqual:CTRadioAccessTechnologyHSUPA]) [[coverSheetView diaryCellularTypeLabel] setText:@"3G"];
                else if ([telephonyInfo.serviceCurrentRadioAccessTechnology[dataServiceIdentifier] isEqual:CTRadioAccessTechnologyeHRPD]) [[coverSheetView diaryCellularTypeLabel] setText:@"3G"];
                if (@available(iOS 14.1, *)) {
                    if ([telephonyInfo.serviceCurrentRadioAccessTechnology[dataServiceIdentifier] isEqual:CTRadioAccessTechnologyNR] || [telephonyInfo.serviceCurrentRadioAccessTechnology[dataServiceIdentifier] isEqual:CTRadioAccessTechnologyNRNSA]) [[coverSheetView diaryCellularTypeLabel] setText:@"5G"];
                }
            }
        }
    }

}

%end

%end

%group DiaryHello

%hook CSCoverSheetView

%property(nonatomic, retain)UIView* diaryHelloIconView;
%property(nonatomic, retain)UILabel* diaryHelloLabel;

- (void)didMoveToWindow { // add iphone hello

    %orig;

    
    // hello label
    if (enableHelloSwitch && showHelloGreetingSwitch && ![self diaryHelloLabel]) {
        self.diaryHelloLabel = [UILabel new];
        [[self diaryHelloLabel] setTextColor:[UIColor whiteColor]];
        if ([fontFamilyValue intValue] == 0) [[self diaryHelloLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:24]];
        else if ([fontFamilyValue intValue] == 1) [[self diaryHelloLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:24]];
        else if ([fontFamilyValue intValue] == 2) [[self diaryHelloLabel] setFont:[UIFont systemFontOfSize:24 weight:UIFontWeightRegular]];
        [[self diaryHelloLabel] setText:greetingValue];
        [[self diaryHelloLabel] setTextAlignment:NSTextAlignmentCenter];
        [[self diaryHelloLabel] setAlpha:0];
        [[self diaryHelloLabel] setHidden:YES];
        [self addSubview:[self diaryHelloLabel]];

        [[self diaryHelloLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryHelloLabel.topAnchor constraintEqualToAnchor:self.topAnchor constant:150],
            [self.diaryHelloLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.diaryHelloLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        ]];
    }

}

%new
- (void)initHelloViewWithAnimation:(int)animation { // set hello view up

    if (!enableHelloSwitch) return;
    if (enableMediaPlayerSwitch && ![[self diaryPlayerView] isHidden]) return;
    [[self diaryHelloIconView] stopAnimating];
    [[self diaryHelloIconView] removeFromSuperview];
    self.diaryHelloIconView = nil;

	if (animation == 0) {
        helloStartArray = [NSMutableArray new];
        for (int i = 0; i < 24; i++) [helloStartArray addObject:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/DiaryPreferences.bundle/hello/start/%i.png", i]]];
        helloStartImage = [UIImage animatedImageWithImages:helloStartArray duration:0.6];
        self.diaryHelloIconView = [[UIImageView alloc] initWithImage:helloStartImage];

        helloSearchingArray = nil;
        helloSearchingImage = nil;
        helloAuthenticatedArray = nil;
        helloAuthenticatedImage = nil;
    } else if (animation == 1) {
        helloSearchingArray = [NSMutableArray new];
        for (int i = 0; i < 116; i++) [helloSearchingArray addObject:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/DiaryPreferences.bundle/hello/searching/%i.png", i]]];
        helloSearchingImage = [UIImage animatedImageWithImages:helloSearchingArray duration:4.28];
        self.diaryHelloIconView = [[UIImageView alloc] initWithImage:helloSearchingImage];

        helloStartArray = nil;
        helloStartImage = nil;
        helloAuthenticatedArray = nil;
        helloAuthenticatedImage = nil;
    } else if (animation == 2) {
        helloAuthenticatedArray = [NSMutableArray new];
        for (int i = 0; i < 51; i++) [helloAuthenticatedArray addObject:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/DiaryPreferences.bundle/hello/authenticated/%i.png", i]]];
        helloAuthenticatedImage = [UIImage animatedImageWithImages:helloAuthenticatedArray duration:1.12];
        self.diaryHelloIconView = [[UIImageView alloc] initWithImage:helloAuthenticatedImage];

        helloStartArray = nil;
        helloStartImage = nil;
        helloSearchingArray = nil;
        helloSearchingImage = nil;
    }

    [[self diaryHelloIconView] setContentMode:UIViewContentModeScaleAspectFit];
    [[self diaryHelloIconView] setClipsToBounds:YES];
    [[self diaryHelloIconView] setHidden:NO];
	if (![[self diaryHelloIconView] isDescendantOfView:self]) [self addSubview:[self diaryHelloIconView]];

    [[self diaryHelloIconView] setTranslatesAutoresizingMaskIntoConstraints:NO];
	[NSLayoutConstraint activateConstraints:@[
		[self.diaryHelloIconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:50],
        [self.diaryHelloIconView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [self.diaryHelloIconView.heightAnchor constraintEqualToConstant:80],
        [self.diaryHelloIconView.widthAnchor constraintEqualToConstant:80],
	]];

}

%new
- (void)playHelloStartAnimation { // play hello start animation

    if (!enableHelloSwitch) return;
    if (enableMediaPlayerSwitch && ![[self diaryPlayerView] isHidden]) return;
    shouldPlaySearchAnimation = YES;
    [self initHelloViewWithAnimation:0];
    [[self diaryHelloIconView] setAnimationRepeatCount:1];
    [[self diaryHelloIconView] startAnimating];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
	    [self playHelloSearchingAnimation];
	});

}

%new
- (void)playHelloSearchingAnimation { // play hello searching animation

    if (!enableHelloSwitch) return;
    if (enableMediaPlayerSwitch && ![[self diaryPlayerView] isHidden]) return;
    if (!shouldPlaySearchAnimation) return;
    [self initHelloViewWithAnimation:1];
    [[self diaryHelloIconView] setAnimationRepeatCount:0];
    [[self diaryHelloIconView] startAnimating];

    if (showHelloGreetingSwitch) [[self diaryHelloLabel] setAlpha:0];

}

%new
- (void)playHelloAuthenticatedAnimation { // play hello authenticated animation

    if (!enableHelloSwitch) return;
    if (enableMediaPlayerSwitch && ![[self diaryPlayerView] isHidden]) return;
    shouldPlaySearchAnimation = NO;
    [self initHelloViewWithAnimation:2];
    [[self diaryHelloIconView] setAnimationRepeatCount:1];
    [[self diaryHelloIconView] startAnimating];

    if ([overrideTimeDateStyleValue intValue] == 1) {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [[timeDateView diaryTimeLabel] setAlpha:0];
            [[timeDateView diaryDateLabel] setAlpha:0];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.25 delay:0.8 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [[timeDateView diaryTimeLabel] setAlpha:1];
                [[timeDateView diaryDateLabel] setAlpha:1];
            } completion:nil];
        }];
    }

    if (showHelloGreetingSwitch) {
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [UIView animateWithDuration:0.25 delay:0.4 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [[self diaryHelloLabel] setHidden:NO];
            [[self diaryHelloLabel] setAlpha:1];
            [notificationCenter postNotificationName:@"diaryUpdateNotificationList" object:nil];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                [[self diaryHelloLabel] setAlpha:0];
            } completion:^(BOOL finished) {
                [[self diaryHelloIconView] setHidden:YES];
                [[self diaryHelloLabel] setHidden:YES];
                [[self diaryHelloIconView] removeFromSuperview];
                [notificationCenter postNotificationName:@"diaryUpdateNotificationList" object:nil];
            }];
        }];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.8 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [[self diaryHelloIconView] setHidden:YES];
            [[self diaryHelloIconView] removeFromSuperview];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryUpdateNotificationList" object:nil];
        });
    }

}

%end

%hook CSCoverSheetViewController

- (void)viewDidDisappear:(BOOL)animated { // remove hello view when lock screen disappeared

    %orig;

    // free up memory when hello is not visible
    [[coverSheetView diaryHelloIconView] stopAnimating];
    [[coverSheetView diaryHelloIconView] removeFromSuperview];
    helloStartArray = nil;
    helloStartImage = nil;
    helloSearchingArray = nil;
    helloSearchingImage = nil;
    helloAuthenticatedArray = nil;
    helloAuthenticatedImage = nil;

}

%end

%hook SBLockScreenManager

- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 { // remove hello view when device was locked

	%orig;

    // free up memory when hello is not visible
    isLockedHello = YES;
    isScreenOnHello = NO;
    [[coverSheetView diaryHelloIconView] stopAnimating];
    [[coverSheetView diaryHelloIconView] removeFromSuperview];
    helloStartArray = nil;
    helloStartImage = nil;
    helloSearchingArray = nil;
    helloSearchingImage = nil;
    helloAuthenticatedArray = nil;
    helloAuthenticatedImage = nil;

}

%end

%hook SBBacklightController

- (void)turnOnScreenFullyWithBacklightSource:(long long)arg1 { // update diary when screen turns on

	%orig;

    if (![[%c(SBLockScreenManager) sharedInstance] isLockScreenVisible]) return; // this method gets called not only when the screen gets turned on, so i verify that it was turned on by checking if the lock screen is visible
    if (!isScreenOnHello) [coverSheetView playHelloStartAnimation];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryUpdateNotificationList" object:nil];
    isScreenOnHello = YES;

}

%end

%hook SBDashBoardBiometricUnlockController

- (void)setAuthenticated:(BOOL)arg1 { // play authenticated animation when unlocked with biometrics

	%orig;

	if (arg1 && isLockedHello) {
        isLockedHello = NO;
        [coverSheetView playHelloAuthenticatedAnimation];
    }

}

%end

%end

%group DiaryMediaPlayer

%hook CSCoverSheetView

%property(nonatomic, retain)UIView* diaryPlayerView;
%property(nonatomic, retain)UIImageView* diaryArtworkView;
%property(nonatomic, retain)UIView* diaryMusicControlsView;
%property(nonatomic, retain)UIButton* diaryRewindButton;
%property(nonatomic, retain)UIButton* diaryPauseButton;
%property(nonatomic, retain)UIButton* diarySkipButton;
%property(nonatomic, retain)UILabel* diarySongTitleLabel;
%property(nonatomic, retain)UILabel* diaryArtistLabel;

- (void)didMoveToWindow { // add media player

    %orig;

    if ([self diaryPlayerView]) return;

    if ([overrideTimeDateStyleValue intValue] == 0) {
        // player view
        self.diaryPlayerView = [UIView new];
        [[self diaryPlayerView] setBackgroundColor:[[GcColorPickerUtils colorWithHex:customMediaPlayerBackgroundColorValue] colorWithAlphaComponent:[mediaPlayerBackgroundAmountValue doubleValue]]];
        [[self diaryPlayerView] setHidden:YES];
        [self addSubview:[self diaryPlayerView]];

        [[self diaryPlayerView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryPlayerView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [self.diaryPlayerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.diaryPlayerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [self.diaryPlayerView.heightAnchor constraintEqualToConstant:140 + [mediaPlayerOffsetValue doubleValue]],
        ]];


        // artwork
        self.diaryArtworkView = [UIImageView new];
        [[self diaryArtworkView] setContentMode:UIViewContentModeScaleAspectFill];
        [[self diaryArtworkView] setClipsToBounds:YES];
        [[self diaryPlayerView] addSubview:[self diaryArtworkView]];

        [[self diaryArtworkView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryArtworkView.leadingAnchor constraintEqualToAnchor:self.diaryPlayerView.leadingAnchor],
            [self.diaryArtworkView.bottomAnchor constraintEqualToAnchor:self.diaryPlayerView.bottomAnchor],
            [self.diaryArtworkView.widthAnchor constraintEqualToConstant:140],
            [self.diaryArtworkView.heightAnchor constraintEqualToConstant:140],
        ]];


        // music controls view
        self.diaryMusicControlsView = [UIView new];
        [[self diaryPlayerView] addSubview:[self diaryMusicControlsView]];

        [[self diaryMusicControlsView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryMusicControlsView.leadingAnchor constraintEqualToAnchor:self.diaryArtworkView.trailingAnchor constant:32],
            [self.diaryMusicControlsView.trailingAnchor constraintEqualToAnchor:self.diaryPlayerView.trailingAnchor constant:-32],
            [self.diaryMusicControlsView.bottomAnchor constraintEqualToAnchor:self.diaryPlayerView.bottomAnchor constant:-12],
            [self.diaryMusicControlsView.heightAnchor constraintEqualToConstant:40],
        ]];


        // rewind button
        self.diaryRewindButton = [UIButton new];
        [[self diaryRewindButton] addTarget:self action:@selector(rewindSong) forControlEvents:UIControlEventTouchUpInside];
        [[self diaryRewindButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/music_controls/rewind.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [[self diaryRewindButton] setTintColor:[UIColor whiteColor]];
        [[self diaryRewindButton] setAdjustsImageWhenHighlighted:NO];
        [[self diaryRewindButton] setImageEdgeInsets:UIEdgeInsetsMake(7, 7, 7, 7)];
        [[self diaryMusicControlsView] addSubview:[self diaryRewindButton]];

        [[self diaryRewindButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryRewindButton.topAnchor constraintEqualToAnchor:self.diaryMusicControlsView.topAnchor],
            [self.diaryRewindButton.leadingAnchor constraintEqualToAnchor:self.diaryMusicControlsView.leadingAnchor],
            [self.diaryRewindButton.bottomAnchor constraintEqualToAnchor:self.diaryMusicControlsView.bottomAnchor],
            [self.diaryRewindButton.widthAnchor constraintEqualToConstant:40],
        ]];


        // pause button
        self.diaryPauseButton = [UIButton new];
        [[self diaryPauseButton] addTarget:self action:@selector(pausePlaySong) forControlEvents:UIControlEventTouchUpInside];
        [[self diaryPauseButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/music_controls/pause.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [[self diaryPauseButton] setTintColor:[UIColor whiteColor]];
        [[self diaryPauseButton] setAdjustsImageWhenHighlighted:NO];
        [[self diaryPauseButton] setImageEdgeInsets:UIEdgeInsetsMake(7, 7, 7, 7)];
        [[self diaryMusicControlsView] addSubview:[self diaryPauseButton]];

        [[self diaryPauseButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryPauseButton.topAnchor constraintEqualToAnchor:self.diaryMusicControlsView.topAnchor],
            [self.diaryPauseButton.centerXAnchor constraintEqualToAnchor:self.diaryMusicControlsView.centerXAnchor],
            [self.diaryPauseButton.bottomAnchor constraintEqualToAnchor:self.diaryMusicControlsView.bottomAnchor],
            [self.diaryPauseButton.widthAnchor constraintEqualToConstant:40],
        ]];


        // skip button
        self.diarySkipButton = [UIButton new];
        [[self diarySkipButton] addTarget:self action:@selector(skipSong) forControlEvents:UIControlEventTouchUpInside];
        [[self diarySkipButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/music_controls/skip.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [[self diarySkipButton] setTintColor:[UIColor whiteColor]];
        [[self diarySkipButton] setAdjustsImageWhenHighlighted:NO];
        [[self diarySkipButton] setImageEdgeInsets:UIEdgeInsetsMake(7, 7, 7, 7)];
        [[self diaryMusicControlsView] addSubview:[self diarySkipButton]];

        [[self diarySkipButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diarySkipButton.topAnchor constraintEqualToAnchor:self.diaryMusicControlsView.topAnchor],
            [self.diarySkipButton.trailingAnchor constraintEqualToAnchor:self.diaryMusicControlsView.trailingAnchor],
            [self.diarySkipButton.bottomAnchor constraintEqualToAnchor:self.diaryMusicControlsView.bottomAnchor],
            [self.diarySkipButton.widthAnchor constraintEqualToConstant:40],
        ]];


        // artist label
        self.diaryArtistLabel = [UILabel new];
        [[self diaryArtistLabel] setTextColor:[UIColor whiteColor]];
        if ([fontFamilyValue intValue] == 0) [[self diaryArtistLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:17]];
        else if ([fontFamilyValue intValue] == 1) [[self diaryArtistLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:17]];
        else if ([fontFamilyValue intValue] == 2) [[self diaryArtistLabel] setFont:[UIFont systemFontOfSize:17 weight:UIFontWeightRegular]];
        [[self diaryArtistLabel] setTextAlignment:NSTextAlignmentLeft];
        [[self diaryArtistLabel] setMarqueeEnabled:YES];
        [[self diaryArtistLabel] setMarqueeRunning:YES];
        [[self diaryPlayerView] addSubview:[self diaryArtistLabel]];

        [[self diaryArtistLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryArtistLabel.bottomAnchor constraintEqualToAnchor:self.diaryMusicControlsView.topAnchor constant:-24],
            [self.diaryArtistLabel.leadingAnchor constraintEqualToAnchor:self.diaryArtworkView.trailingAnchor constant:24],
            [self.diaryArtistLabel.trailingAnchor constraintEqualToAnchor:self.diaryPlayerView.trailingAnchor constant:-24],
        ]];


        // song title label
        self.diarySongTitleLabel = [UILabel new];
        [[self diarySongTitleLabel] setTextColor:[UIColor whiteColor]];
        if ([fontFamilyValue intValue] == 0) [[self diarySongTitleLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:23]];
        else if ([fontFamilyValue intValue] == 1) [[self diarySongTitleLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:23]];
        else if ([fontFamilyValue intValue] == 2) [[self diarySongTitleLabel] setFont:[UIFont systemFontOfSize:23 weight:UIFontWeightRegular]];
        [[self diarySongTitleLabel] setTextAlignment:NSTextAlignmentLeft];
        [[self diarySongTitleLabel] setMarqueeEnabled:YES];
        [[self diarySongTitleLabel] setMarqueeRunning:YES];
        [[self diaryPlayerView] addSubview:[self diarySongTitleLabel]];

        [[self diarySongTitleLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diarySongTitleLabel.bottomAnchor constraintEqualToAnchor:self.diaryArtistLabel.topAnchor constant:-2],
            [self.diarySongTitleLabel.leadingAnchor constraintEqualToAnchor:self.diaryArtworkView.trailingAnchor constant:24],
            [self.diarySongTitleLabel.trailingAnchor constraintEqualToAnchor:self.diaryPlayerView.trailingAnchor constant:-24],
        ]];
    } else if ([overrideTimeDateStyleValue intValue] == 1) {
        // player view
        self.diaryPlayerView = [UIView new];
        [[self diaryPlayerView] setBackgroundColor:[[GcColorPickerUtils colorWithHex:customMediaPlayerBackgroundColorValue] colorWithAlphaComponent:[mediaPlayerBackgroundAmountValue doubleValue]]];
        [[self diaryPlayerView] setHidden:YES];
        [self addSubview:[self diaryPlayerView]];

        [[self diaryPlayerView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryPlayerView.topAnchor constraintEqualToAnchor:self.topAnchor],
            [self.diaryPlayerView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [self.diaryPlayerView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [self.diaryPlayerView.heightAnchor constraintEqualToConstant:80 + [mediaPlayerOffsetValue doubleValue]],
        ]];


        // artwork
        self.diaryArtworkView = [UIImageView new];
        [[self diaryArtworkView] setContentMode:UIViewContentModeScaleAspectFill];
        [[self diaryArtworkView] setClipsToBounds:YES];
        [[self diaryPlayerView] addSubview:[self diaryArtworkView]];

        [[self diaryArtworkView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryArtworkView.leadingAnchor constraintEqualToAnchor:self.diaryPlayerView.leadingAnchor],
            [self.diaryArtworkView.bottomAnchor constraintEqualToAnchor:self.diaryPlayerView.bottomAnchor],
            [self.diaryArtworkView.widthAnchor constraintEqualToConstant:80],
            [self.diaryArtworkView.heightAnchor constraintEqualToConstant:80],
        ]];


        // music controls view
        self.diaryMusicControlsView = [UIView new];
        [[self diaryPlayerView] addSubview:[self diaryMusicControlsView]];

        [[self diaryMusicControlsView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryMusicControlsView.centerYAnchor constraintEqualToAnchor:self.diaryArtworkView.centerYAnchor],
            [self.diaryMusicControlsView.leadingAnchor constraintEqualToAnchor:self.diaryPlayerView.centerXAnchor constant:40],
            [self.diaryMusicControlsView.trailingAnchor constraintEqualToAnchor:self.diaryPlayerView.trailingAnchor constant:-12],
            [self.diaryMusicControlsView.heightAnchor constraintEqualToConstant:40],
        ]];


        // rewind button
        self.diaryRewindButton = [UIButton new];
        [[self diaryRewindButton] addTarget:self action:@selector(rewindSong) forControlEvents:UIControlEventTouchUpInside];
        [[self diaryRewindButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/music_controls/rewind.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [[self diaryRewindButton] setTintColor:[UIColor whiteColor]];
        [[self diaryRewindButton] setAdjustsImageWhenHighlighted:NO];
        [[self diaryRewindButton] setImageEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
        [[self diaryMusicControlsView] addSubview:[self diaryRewindButton]];

        [[self diaryRewindButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryRewindButton.topAnchor constraintEqualToAnchor:self.diaryMusicControlsView.topAnchor],
            [self.diaryRewindButton.leadingAnchor constraintEqualToAnchor:self.diaryMusicControlsView.leadingAnchor],
            [self.diaryRewindButton.bottomAnchor constraintEqualToAnchor:self.diaryMusicControlsView.bottomAnchor],
            [self.diaryRewindButton.widthAnchor constraintEqualToConstant:40],
        ]];


        // pause button
        self.diaryPauseButton = [UIButton new];
        [[self diaryPauseButton] addTarget:self action:@selector(pausePlaySong) forControlEvents:UIControlEventTouchUpInside];
        [[self diaryPauseButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/music_controls/pause.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [[self diaryPauseButton] setTintColor:[UIColor whiteColor]];
        [[self diaryPauseButton] setAdjustsImageWhenHighlighted:NO];
        [[self diaryPauseButton] setImageEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
        [[self diaryMusicControlsView] addSubview:[self diaryPauseButton]];

        [[self diaryPauseButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryPauseButton.topAnchor constraintEqualToAnchor:self.diaryMusicControlsView.topAnchor],
            [self.diaryPauseButton.centerXAnchor constraintEqualToAnchor:self.diaryMusicControlsView.centerXAnchor],
            [self.diaryPauseButton.bottomAnchor constraintEqualToAnchor:self.diaryMusicControlsView.bottomAnchor],
            [self.diaryPauseButton.widthAnchor constraintEqualToConstant:40],
        ]];


        // skip button
        self.diarySkipButton = [UIButton new];
        [[self diarySkipButton] addTarget:self action:@selector(skipSong) forControlEvents:UIControlEventTouchUpInside];
        [[self diarySkipButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/music_controls/skip.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [[self diarySkipButton] setTintColor:[UIColor whiteColor]];
        [[self diarySkipButton] setAdjustsImageWhenHighlighted:NO];
        [[self diarySkipButton] setImageEdgeInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
        [[self diaryMusicControlsView] addSubview:[self diarySkipButton]];

        [[self diarySkipButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diarySkipButton.topAnchor constraintEqualToAnchor:self.diaryMusicControlsView.topAnchor],
            [self.diarySkipButton.trailingAnchor constraintEqualToAnchor:self.diaryMusicControlsView.trailingAnchor],
            [self.diarySkipButton.bottomAnchor constraintEqualToAnchor:self.diaryMusicControlsView.bottomAnchor],
            [self.diarySkipButton.widthAnchor constraintEqualToConstant:40],
        ]];


        // song title label
        self.diarySongTitleLabel = [UILabel new];
        [[self diarySongTitleLabel] setTextColor:[UIColor whiteColor]];
        if ([fontFamilyValue intValue] == 0) [[self diarySongTitleLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:22]];
        else if ([fontFamilyValue intValue] == 1) [[self diarySongTitleLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:22]];
        else if ([fontFamilyValue intValue] == 2) [[self diarySongTitleLabel] setFont:[UIFont systemFontOfSize:22 weight:UIFontWeightRegular]];
        [[self diarySongTitleLabel] setTextAlignment:NSTextAlignmentLeft];
        [[self diarySongTitleLabel] setMarqueeEnabled:YES];
        [[self diarySongTitleLabel] setMarqueeRunning:YES];
        [[self diaryPlayerView] addSubview:[self diarySongTitleLabel]];

        [[self diarySongTitleLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diarySongTitleLabel.centerYAnchor constraintEqualToAnchor:self.diaryArtworkView.centerYAnchor constant:-12],
            [self.diarySongTitleLabel.leadingAnchor constraintEqualToAnchor:self.diaryArtworkView.trailingAnchor constant:12],
            [self.diarySongTitleLabel.trailingAnchor constraintEqualToAnchor:self.diaryMusicControlsView.leadingAnchor constant:-4],
        ]];


        // artist label
        self.diaryArtistLabel = [UILabel new];
        [[self diaryArtistLabel] setTextColor:[UIColor whiteColor]];
        if ([fontFamilyValue intValue] == 0) [[self diaryArtistLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:17]];
        else if ([fontFamilyValue intValue] == 1) [[self diaryArtistLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:17]];
        else if ([fontFamilyValue intValue] == 2) [[self diaryArtistLabel] setFont:[UIFont systemFontOfSize:17 weight:UIFontWeightRegular]];
        [[self diaryArtistLabel] setTextAlignment:NSTextAlignmentLeft];
        [[self diaryArtistLabel] setMarqueeEnabled:YES];
        [[self diaryArtistLabel] setMarqueeRunning:YES];
        [[self diaryPlayerView] addSubview:[self diaryArtistLabel]];

        [[self diaryArtistLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.diaryArtistLabel.centerYAnchor constraintEqualToAnchor:self.diaryArtworkView.centerYAnchor constant:12],
            [self.diaryArtistLabel.leadingAnchor constraintEqualToAnchor:self.diaryArtworkView.trailingAnchor constant:12],
            [self.diaryArtistLabel.trailingAnchor constraintEqualToAnchor:self.diaryMusicControlsView.leadingAnchor constant:-4],
        ]];
    }

}

%new
- (void)rewindSong { // rewind song

	[[%c(SBMediaController) sharedInstance] changeTrack:-1 eventSource:0];

}

%new
- (void)skipSong { // skip song

	[[%c(SBMediaController) sharedInstance] changeTrack:1 eventSource:0];

}

%new
- (void)pausePlaySong { // pause/play song

	[[%c(SBMediaController) sharedInstance] togglePlayPauseForEventSource:0];

}

%end

%hook CSCoverSheetViewController

- (void)viewWillAppear:(BOOL)animated { // hide the player in landscape mode wheen lock screen appears

	%orig;

    if (UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation]) && ([[%c(SBMediaController) sharedInstance] isPlaying] || [[%c(SBMediaController) sharedInstance] isPaused]))
        [[coverSheetView diaryPlayerView] setHidden:YES];
    else if (UIDeviceOrientationIsPortrait([[UIDevice currentDevice] orientation]) && ([[%c(SBMediaController) sharedInstance] isPlaying] || [[%c(SBMediaController) sharedInstance] isPaused]))
        [[coverSheetView diaryPlayerView] setHidden:NO];

}

%end

%hook SBMediaController

- (void)setNowPlayingInfo:(id)arg1 { // set now playing info

    %orig;

    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        if (information) {
            NSDictionary* dict = (__bridge NSDictionary *)information;

            if (dict) {
                if (dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtworkData]) {
                    UIImage* artwork = [UIImage imageWithData:[dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData]];
                    if (artworkTransitionSwitch) {
                        [UIView transitionWithView:[coverSheetView diaryArtworkView] duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
                            [[coverSheetView diaryArtworkView] setImage:artwork];
                        } completion:nil];
                    } else {
                        [[coverSheetView diaryArtworkView] setImage:artwork];
                    }
                    if (adaptiveMediaPlayerBackgroundSwitch) [[coverSheetView diaryPlayerView] setBackgroundColor:[libKitten backgroundColor:artwork]];
                }
                if (dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoTitle]) [[coverSheetView diarySongTitleLabel] setText:[NSString stringWithFormat:@"%@", [dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoTitle]]];
                if (dict[(__bridge NSString *)kMRMediaRemoteNowPlayingInfoArtist])[[coverSheetView diaryArtistLabel] setText:[NSString stringWithFormat:@"%@", [dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtist]]];

                [[coverSheetView diaryPlayerView] setHidden:NO];
            }
        } else {
            [[coverSheetView diaryPlayerView] setHidden:YES];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryUpdateNotificationList" object:nil];
  	});
    
}

- (void)_mediaRemoteNowPlayingApplicationIsPlayingDidChange:(id)arg1 { // update play/pause button image

    %orig;

    if ([self isPaused])
        [[coverSheetView diaryPauseButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/music_controls/play.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    else if (![self isPaused])
        [[coverSheetView diaryPauseButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/music_controls/pause.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)arg1 { // reload data after a respring

    %orig;

    [[%c(SBMediaController) sharedInstance] setNowPlayingInfo:0];
    
}

%end

%hook CSAdjunctItemView

- (id)initWithFrame:(CGRect)frame { // remove the default player

	return nil;

}

%end

%end

%group DiaryBackground

%hook CSCoverSheetView

%property(nonatomic, retain)UIImageView* diarySpotlightWallpaperView;
%property(nonatomic, retain)CAGradientLayer* diaryGradient;

- (void)didMoveToWindow { // add spotlight wallpaper view

    %orig;

    if (enableSpotlightSwitch && ![self diarySpotlightWallpaperView]) {
        // create an array containing the path of each image from /Library/Diary/Wallpapers/ as a string
        spotlightWallpapers = [NSMutableArray new];
        NSArray* wallpaperDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Diary/Wallpapers/" error:nil];
        for (int i = 0; i < [wallpaperDirectory count]; i++) [spotlightWallpapers addObject:[NSString stringWithFormat:@"/Library/Diary/Wallpapers/%@", [wallpaperDirectory objectAtIndex:i]]];


        self.diarySpotlightWallpaperView = [[UIImageView alloc] initWithFrame:[self bounds]];
        [[self diarySpotlightWallpaperView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [[self diarySpotlightWallpaperView] setContentMode:UIViewContentModeScaleAspectFill];
        if ([spotlightWallpapers count]) [[coverSheetView diarySpotlightWallpaperView] setImage:[UIImage imageWithContentsOfFile:[spotlightWallpapers objectAtIndex:arc4random_uniform([spotlightWallpapers count])]]];
        [self insertSubview:[self diarySpotlightWallpaperView] atIndex:0];
    }


    // gradient
    if ([self diaryGradient] || [backgroundGradientAmountValue doubleValue] == 0) return;
	self.diaryGradient = [CAGradientLayer layer];
	[[self diaryGradient] setFrame:[self bounds]];
	[[self diaryGradient] setColors:@[(id)[[UIColor clearColor] CGColor], (id)[[UIColor clearColor] CGColor], (id)[[[GcColorPickerUtils colorWithHex:gradientColorValue] colorWithAlphaComponent:[backgroundGradientAmountValue doubleValue]] CGColor]]];
	[[self layer] insertSublayer:[self diaryGradient] atIndex:enableSpotlightSwitch ? 3 : useCustomZIndexSwitch ? 1 + [customZIndexValue intValue] : 0];

}

%end

%hook CSCoverSheetViewController

- (void)viewWillAppear:(BOOL)animated { // update gradient frame when lock screen appears

	%orig;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryRotateNotification" object:nil];

}

%end

%hook SBLockScreenManager

- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 { // change wallpaper when locked

	%orig;

    if ([spotlightWallpapers count]) [[coverSheetView diarySpotlightWallpaperView] setImage:[UIImage imageWithContentsOfFile:[spotlightWallpapers objectAtIndex:arc4random_uniform([spotlightWallpapers count] - 1)]]];

}

%end

%end

%group DiaryPasscode

%hook CSPasscodeViewController

%property(nonatomic, retain)UIBlurEffect* backgroundBlur;
%property(nonatomic, retain)UIVisualEffectView* backgroundBlurView;
%property(nonatomic, retain)UIImageView* userAvatar;
%property(nonatomic, retain)UILabel* usernameLabel;
%property(nonatomic, retain)UIView* passcodeEntryView;
%property(nonatomic, retain)UIBlurEffect* passcodeEntryBlur;
%property(nonatomic, retain)UIVisualEffectView* passcodeEntryBlurView;
%property(nonatomic, retain)UIView* passcodeEntryEffectView;
%property(nonatomic, retain)UIButton* passcodeEntryConfirmButton;
%property(nonatomic, retain)UITextField* passcodeEntryField;
%property(nonatomic, retain)UILabel* incorrectPasswordLabel;
%property(nonatomic, retain)UIButton* incorrectPasswordButton;
%property(nonatomic, retain)UITapGestureRecognizer* tapGesture;

- (void)viewDidLoad { // add the diary passcode view

    %orig;


    // background blur
    self.backgroundBlur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark];
    self.backgroundBlurView = [[UIVisualEffectView alloc] initWithEffect:[self backgroundBlur]];
	[[self backgroundBlurView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [[self backgroundBlurView] setAlpha:0];
	[[self view] addSubview:[self backgroundBlurView]];

    [[self backgroundBlurView] setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundBlurView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backgroundBlurView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backgroundBlurView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backgroundBlurView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];


    // username label
    self.usernameLabel = [UILabel new];
    [[self usernameLabel] setTextColor:[UIColor whiteColor]];
    [[self usernameLabel] setText:usernameValue];
    if ([overridePasscodeStyleValue intValue] == 0) {
        if ([fontFamilyValue intValue] == 0) [[self usernameLabel] setFont:[UIFont fontWithName:@"Selawik-Light" size:40]];
        else if ([fontFamilyValue intValue] == 1) [[self usernameLabel] setFont:[UIFont fontWithName:@"OpenSans-Light" size:40]];
        else if ([fontFamilyValue intValue] == 2) [[self usernameLabel] setFont:[UIFont systemFontOfSize:40 weight:UIFontWeightLight]];
    } else if ([overridePasscodeStyleValue intValue] == 1) {
        if ([fontFamilyValue intValue] == 0) [[self usernameLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:32]];
        else if ([fontFamilyValue intValue] == 1) [[self usernameLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:32]];
        else if ([fontFamilyValue intValue] == 2) [[self usernameLabel] setFont:[UIFont systemFontOfSize:32 weight:UIFontWeightMedium]];
    }
    [[self usernameLabel] setAlpha:0];
    [[self view] addSubview:[self usernameLabel]];

    [[self usernameLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [self.usernameLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.usernameLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-32],
    ]];


    // user avatar
	self.userAvatar = [UIImageView new];
    UIImage* avatarImage = [GcImagePickerUtils imageFromDefaults:@"love.litten.diarypreferences" withKey:@"avatar"];
    if (avatarImage) [[self userAvatar] setImage:avatarImage];
    else [[self userAvatar] setImage:[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/passcode/avatarPlaceholder.png"]];
    [[self userAvatar] setContentMode:UIViewContentModeScaleAspectFill];
    [[self userAvatar] setClipsToBounds:YES];
    [[[self userAvatar] layer] setCornerRadius:85];
    [[self userAvatar] setAlpha:0];
	[[self view] addSubview:[self userAvatar]];

	[[self userAvatar] setTranslatesAutoresizingMaskIntoConstraints:NO];
	[NSLayoutConstraint activateConstraints:@[
        [self.userAvatar.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.userAvatar.bottomAnchor constraintEqualToAnchor:self.usernameLabel.topAnchor constant:-16],
        [self.userAvatar.widthAnchor constraintEqualToConstant:170],
        [self.userAvatar.heightAnchor constraintEqualToConstant:170],
	]];


    // passcode entry field
    if ([overridePasscodeStyleValue intValue] == 0) {
        // view
        self.passcodeEntryView = [UIView new];
        [[[self passcodeEntryView] layer] setBorderColor:[[[UIColor whiteColor] colorWithAlphaComponent:0.4] CGColor]];
        [[[self passcodeEntryView] layer] setBorderWidth:2];
        [[self passcodeEntryView] setAlpha:0];
        [[self view] addSubview:[self passcodeEntryView]];

        [[self passcodeEntryView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.passcodeEntryView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [self.passcodeEntryView.topAnchor constraintEqualToAnchor:self.usernameLabel.bottomAnchor constant:28],
            [self.passcodeEntryView.widthAnchor constraintEqualToConstant:260],
            [self.passcodeEntryView.heightAnchor constraintEqualToConstant:35],
        ]];


        // button
        self.passcodeEntryConfirmButton = [UIButton new];
        [[self passcodeEntryConfirmButton] addTarget:self action:@selector(attemptManualUnlock) forControlEvents:UIControlEventTouchUpInside];
        [[self passcodeEntryConfirmButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/passcode/confirmButtonArrow.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [[self passcodeEntryConfirmButton] setTintColor:[UIColor whiteColor]];
        [[self passcodeEntryConfirmButton] setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0.2]];
        [[self passcodeEntryConfirmButton] setImageEdgeInsets:UIEdgeInsetsMake(7, 7, 7, 7)];
        [[self passcodeEntryView] addSubview:[self passcodeEntryConfirmButton]];

        [[self passcodeEntryConfirmButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.passcodeEntryConfirmButton.topAnchor constraintEqualToAnchor:self.passcodeEntryView.topAnchor],
            [self.passcodeEntryConfirmButton.trailingAnchor constraintEqualToAnchor:self.passcodeEntryView.trailingAnchor],
            [self.passcodeEntryConfirmButton.bottomAnchor constraintEqualToAnchor:self.passcodeEntryView.bottomAnchor],
            [self.passcodeEntryConfirmButton.widthAnchor constraintEqualToConstant:35],
        ]];


        // passcode entry blur
        self.passcodeEntryBlur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        self.passcodeEntryBlurView = [[UIVisualEffectView alloc] initWithEffect:[self passcodeEntryBlur]];
        [[self passcodeEntryBlurView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [[self passcodeEntryView] addSubview:[self passcodeEntryBlurView]];

        [[self passcodeEntryBlurView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.passcodeEntryBlurView.topAnchor constraintEqualToAnchor:self.passcodeEntryView.topAnchor],
            [self.passcodeEntryBlurView.leadingAnchor constraintEqualToAnchor:self.passcodeEntryView.leadingAnchor],
            [self.passcodeEntryBlurView.trailingAnchor constraintEqualToAnchor:self.passcodeEntryConfirmButton.leadingAnchor],
            [self.passcodeEntryBlurView.bottomAnchor constraintEqualToAnchor:self.passcodeEntryView.bottomAnchor],
        ]];


        // text field
        self.passcodeEntryField = [UITextField new];
        if (automaticallyAttemptToUnlockSwitch && ([passcodeTypeValue intValue] == 0 || [passcodeTypeValue intValue] == 1)) [[self passcodeEntryField] addTarget:self action:@selector(attemptAutomaticUnlock) forControlEvents:UIControlEventEditingChanged];
        [[self passcodeEntryField] addTarget:self action:@selector(updatePasscodeEntryEditingStateStyle) forControlEvents:UIControlEventEditingDidBegin];
        [[self passcodeEntryField] addTarget:self action:@selector(updatePasscodeEntryEditingStateStyle) forControlEvents:UIControlEventEditingDidEnd];
        [[self passcodeEntryField] setTextColor:[UIColor whiteColor]];
        if ([[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName:[[UIColor whiteColor] colorWithAlphaComponent:0.4]}]];
        else if (![[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"PASSWORD"]] attributes:@{NSForegroundColorAttributeName:[[UIColor whiteColor] colorWithAlphaComponent:0.4]}]];
        if ([fontFamilyValue intValue] == 0) [[self passcodeEntryField] setFont:[UIFont fontWithName:@"Selawik-Regular" size:15]];
        else if ([fontFamilyValue intValue] == 1) [[self passcodeEntryField] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:15]];
        else if ([fontFamilyValue intValue] == 2) [[self passcodeEntryField] setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightRegular]];
        if ([passcodeTypeValue intValue] == 0 || [passcodeTypeValue intValue] == 1 || [passcodeTypeValue intValue] == 3) [[self passcodeEntryField] setKeyboardType:UIKeyboardTypeNumberPad];
        [[self passcodeEntryField] setSecureTextEntry:YES];
        [[self passcodeEntryView] addSubview:[self passcodeEntryField]];

        [[self passcodeEntryField] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.passcodeEntryField.topAnchor constraintEqualToAnchor:self.passcodeEntryView.topAnchor],
            [self.passcodeEntryField.leadingAnchor constraintEqualToAnchor:self.passcodeEntryView.leadingAnchor constant:8],
            [self.passcodeEntryField.trailingAnchor constraintEqualToAnchor:self.passcodeEntryConfirmButton.leadingAnchor],
            [self.passcodeEntryField.bottomAnchor constraintEqualToAnchor:self.passcodeEntryView.bottomAnchor],
        ]];
    } else if ([overridePasscodeStyleValue intValue] == 1) {
        // view
        self.passcodeEntryView = [UIView new];
        [[[self passcodeEntryView] layer] setBorderColor:[[[UIColor whiteColor] colorWithAlphaComponent:0.1] CGColor]];
        [[[self passcodeEntryView] layer] setBorderWidth:2];
        [[self passcodeEntryView] setClipsToBounds:YES];
        [[[self passcodeEntryView] layer] setCornerRadius:5];
        [[self passcodeEntryView] setAlpha:0];
        [[self view] addSubview:[self passcodeEntryView]];

        [[self passcodeEntryView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.passcodeEntryView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [self.passcodeEntryView.topAnchor constraintEqualToAnchor:self.usernameLabel.bottomAnchor constant:28],
            [self.passcodeEntryView.widthAnchor constraintEqualToConstant:260],
            [self.passcodeEntryView.heightAnchor constraintEqualToConstant:35],
        ]];


        // passcode entry blur
        self.passcodeEntryBlur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThickMaterialDark];
        self.passcodeEntryBlurView = [UIVisualEffectView new];
        [[self passcodeEntryBlurView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [[self passcodeEntryBlurView] setClipsToBounds:YES];
        [[[self passcodeEntryBlurView] layer] setCornerRadius:4];
        [[self passcodeEntryView] addSubview:[self passcodeEntryBlurView]];

        [[self passcodeEntryBlurView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.passcodeEntryBlurView.topAnchor constraintEqualToAnchor:self.passcodeEntryView.topAnchor constant:2],
            [self.passcodeEntryBlurView.leadingAnchor constraintEqualToAnchor:self.passcodeEntryView.leadingAnchor constant:2],
            [self.passcodeEntryBlurView.trailingAnchor constraintEqualToAnchor:self.passcodeEntryView.trailingAnchor constant:-2],
            [self.passcodeEntryBlurView.bottomAnchor constraintEqualToAnchor:self.passcodeEntryView.bottomAnchor constant:-2],
        ]];


        // button
        self.passcodeEntryConfirmButton = [UIButton new];
        [[self passcodeEntryConfirmButton] addTarget:self action:@selector(attemptManualUnlock) forControlEvents:UIControlEventTouchUpInside];
        [[self passcodeEntryConfirmButton] setImage:[[UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/DiaryPreferences.bundle/passcode/confirmButtonArrow.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [[self passcodeEntryConfirmButton] setTintColor:[UIColor whiteColor]];
        [[self passcodeEntryConfirmButton] setImageEdgeInsets:UIEdgeInsetsMake(7, 7, 7, 7)];
        [[self passcodeEntryView] addSubview:[self passcodeEntryConfirmButton]];

        [[self passcodeEntryConfirmButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.passcodeEntryConfirmButton.topAnchor constraintEqualToAnchor:self.passcodeEntryView.topAnchor],
            [self.passcodeEntryConfirmButton.trailingAnchor constraintEqualToAnchor:self.passcodeEntryView.trailingAnchor],
            [self.passcodeEntryConfirmButton.bottomAnchor constraintEqualToAnchor:self.passcodeEntryView.bottomAnchor],
            [self.passcodeEntryConfirmButton.widthAnchor constraintEqualToConstant:35],
        ]];


        // text field
        self.passcodeEntryField = [UITextField new];
        [[self passcodeEntryField] addTarget:self action:@selector(attemptAutomaticUnlock) forControlEvents:UIControlEventEditingChanged];
        [[self passcodeEntryField] addTarget:self action:@selector(updatePasscodeEntryEditingStateStyle) forControlEvents:UIControlEventEditingDidBegin];
        [[self passcodeEntryField] addTarget:self action:@selector(updatePasscodeEntryEditingStateStyle) forControlEvents:UIControlEventEditingDidEnd];
        [[self passcodeEntryField] setTextColor:[UIColor whiteColor]];
        if ([[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
        else if (![[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"PASSWORD"]] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
        if ([fontFamilyValue intValue] == 0) [[self passcodeEntryField] setFont:[UIFont fontWithName:@"Selawik-Regular" size:15]];
        else if ([fontFamilyValue intValue] == 1) [[self passcodeEntryField] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:15]];
        else if ([fontFamilyValue intValue] == 2) [[self passcodeEntryField] setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightRegular]];
        if ([passcodeTypeValue intValue] == 0 || [passcodeTypeValue intValue] == 1 || [passcodeTypeValue intValue] == 3) [[self passcodeEntryField] setKeyboardType:UIKeyboardTypeNumberPad];
        [[self passcodeEntryField] setSecureTextEntry:YES];
        [[self passcodeEntryView] addSubview:[self passcodeEntryField]];

        [[self passcodeEntryField] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.passcodeEntryField.topAnchor constraintEqualToAnchor:self.passcodeEntryView.topAnchor],
            [self.passcodeEntryField.leadingAnchor constraintEqualToAnchor:self.passcodeEntryView.leadingAnchor constant:8],
            [self.passcodeEntryField.trailingAnchor constraintEqualToAnchor:self.passcodeEntryConfirmButton.leadingAnchor],
            [self.passcodeEntryField.bottomAnchor constraintEqualToAnchor:self.passcodeEntryView.bottomAnchor],
        ]];


        // text field effect view
        self.passcodeEntryEffectView = [UIView new];
        [[self passcodeEntryView] addSubview:[self passcodeEntryEffectView]];

        [[self passcodeEntryEffectView] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.passcodeEntryEffectView.leadingAnchor constraintEqualToAnchor:self.passcodeEntryView.leadingAnchor],
            [self.passcodeEntryEffectView.trailingAnchor constraintEqualToAnchor:self.passcodeEntryView.trailingAnchor],
            [self.passcodeEntryEffectView.bottomAnchor constraintEqualToAnchor:self.passcodeEntryView.bottomAnchor],
            [self.passcodeEntryEffectView.heightAnchor constraintEqualToConstant:2],
        ]];
    }


    // incorrect password label
    self.incorrectPasswordLabel = [UILabel new];
    [[self incorrectPasswordLabel] setTextColor:[UIColor whiteColor]];
    if ([[DRYLocalization stringForKey:@"INCORRECT_PASSWORD"] isEqual:nil]) [[self incorrectPasswordLabel] setText:@"The password is incorrect. Try again."];
    else if (![[DRYLocalization stringForKey:@"INCORRECT_PASSWORD"] isEqual:nil]) [[self incorrectPasswordLabel] setText:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"INCORRECT_PASSWORD"]]];
    if ([fontFamilyValue intValue] == 0) [[self incorrectPasswordLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:14]];
    else if ([fontFamilyValue intValue] == 1) [[self incorrectPasswordLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:14]];
    else if ([fontFamilyValue intValue] == 2) [[self incorrectPasswordLabel] setFont:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular]];
    [[self incorrectPasswordLabel] setHidden:YES];
    [[self view] addSubview:[self incorrectPasswordLabel]];

    [[self incorrectPasswordLabel] setTranslatesAutoresizingMaskIntoConstraints:NO];
    [NSLayoutConstraint activateConstraints:@[
        [self.incorrectPasswordLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.incorrectPasswordLabel.topAnchor constraintEqualToAnchor:self.usernameLabel.bottomAnchor constant:24],
    ]];


    // incorrect password button
    if ([overridePasscodeStyleValue intValue] == 0) {
        self.incorrectPasswordButton = [UIButton new];
        [[self incorrectPasswordButton] addTarget:self action:@selector(hideIncorrectPasswordView) forControlEvents:UIControlEventTouchUpInside];
        if ([[DRYLocalization stringForKey:@"OK"] isEqual:nil]) [[self incorrectPasswordButton] setTitle:@"OK" forState:UIControlStateNormal];
        else if (![[DRYLocalization stringForKey:@"OK"] isEqual:nil]) [[self incorrectPasswordButton] setTitle:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"OK"]] forState:UIControlStateNormal];
        if ([fontFamilyValue intValue] == 0) [[[self incorrectPasswordButton] titleLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:15]];
        if ([fontFamilyValue intValue] == 1) [[[self incorrectPasswordButton] titleLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:15]];
        else if ([fontFamilyValue intValue] == 2) [[[self incorrectPasswordButton] titleLabel] setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightRegular]];
        [[self incorrectPasswordButton] setTintColor:[UIColor whiteColor]];
        [[self incorrectPasswordButton] setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3]];
        [[[self incorrectPasswordButton] layer] setBorderColor:[[UIColor whiteColor] CGColor]];
        [[[self incorrectPasswordButton] layer] setBorderWidth:2];
        [[self incorrectPasswordButton] setHidden:YES];
        [[self view] addSubview:[self incorrectPasswordButton]];

        [[self incorrectPasswordButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.incorrectPasswordButton.topAnchor constraintEqualToAnchor:self.incorrectPasswordLabel.bottomAnchor constant:16],
            [self.incorrectPasswordButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [self.incorrectPasswordButton.widthAnchor constraintEqualToConstant:110],
            [self.incorrectPasswordButton.heightAnchor constraintEqualToConstant:35],
        ]];
    } else if ([overridePasscodeStyleValue intValue] == 1) {
        self.incorrectPasswordButton = [UIButton new];
        [[self incorrectPasswordButton] addTarget:self action:@selector(hideIncorrectPasswordView) forControlEvents:UIControlEventTouchUpInside];
        if ([[DRYLocalization stringForKey:@"OK"] isEqual:nil]) [[self incorrectPasswordButton] setTitle:@"OK" forState:UIControlStateNormal];
        else if (![[DRYLocalization stringForKey:@"OK"] isEqual:nil]) [[self incorrectPasswordButton] setTitle:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"OK"]] forState:UIControlStateNormal];
        if ([fontFamilyValue intValue] == 0) [[[self incorrectPasswordButton] titleLabel] setFont:[UIFont fontWithName:@"Selawik-Regular" size:15]];
        else if ([fontFamilyValue intValue] == 1) [[[self incorrectPasswordButton] titleLabel] setFont:[UIFont fontWithName:@"OpenSans-Regular" size:15]];
        else if ([fontFamilyValue intValue] == 2) [[[self incorrectPasswordButton] titleLabel] setFont:[UIFont systemFontOfSize:15 weight:UIFontWeightRegular]];
        [[self incorrectPasswordButton] setTintColor:[UIColor whiteColor]];
        [[self incorrectPasswordButton] setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0.3]];
        [[[self incorrectPasswordButton] layer] setBorderColor:[[UIColor whiteColor] CGColor]];
        [[[self incorrectPasswordButton] layer] setBorderWidth:2];
        [[self incorrectPasswordButton] setClipsToBounds:YES];
        [[[self incorrectPasswordButton] layer] setCornerRadius:7];
        [[self incorrectPasswordButton] setHidden:YES];
        [[self view] addSubview:[self incorrectPasswordButton]];

        [[self incorrectPasswordButton] setTranslatesAutoresizingMaskIntoConstraints:NO];
        [NSLayoutConstraint activateConstraints:@[
            [self.incorrectPasswordButton.topAnchor constraintEqualToAnchor:self.incorrectPasswordLabel.bottomAnchor constant:16],
            [self.incorrectPasswordButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
            [self.incorrectPasswordButton.widthAnchor constraintEqualToConstant:110],
            [self.incorrectPasswordButton.heightAnchor constraintEqualToConstant:35],
        ]];
    }


    // tap gesture
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [[self tapGesture] setNumberOfTapsRequired:1];
    [[self tapGesture] setNumberOfTouchesRequired:1];
    [[self view] addGestureRecognizer:[self tapGesture]];

    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(dismissKeyboard) name:@"diaryDismissPasscodeKeyboard" object:nil];
    [notificationCenter addObserver:self selector:@selector(authenticatedWithBiometrics) name:@"diaryBiometricPasscodeAuthentication" object:nil];

}

- (void)viewWillAppear:(BOOL)animated { // animate the passcode screen in when the passcode appears

    %orig;

    [self animatePasscodeScreenIn:YES];

}

- (void)viewDidAppear:(BOOL)animated { // automatically focus the entry field when the passcode view appeared

    %orig;

    if (automaticallyFocusTheEntryFieldSwitch && [[%c(SBLockScreenManager) sharedInstance] isLockScreenVisible]) [[self passcodeEntryField] becomeFirstResponder];
    passcodeLeaveTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(leavePasscodeScreenDueToTimeout) userInfo:nil repeats:NO];

}

- (void)viewWillDisappear:(BOOL)animated { // reset the passcode screen when it disappears

    %orig;

    [self animatePasscodeScreenIn:NO];

}

- (void)passcodeLockViewCancelButtonPressed:(id)arg1 { // animate the passcode screen out when the passcode disappears and reset the time and date transform

    %orig;

    [self animatePasscodeScreenIn:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.35 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [coverSheetView resetDiaryViewTransform];
    });

}

%new
- (void)leavePasscodeScreenDueToTimeout {

    [self passcodeLockViewCancelButtonPressed:0];

}

%new
- (void)animatePasscodeScreenIn:(BOOL)animateIn { // animate the passcode screen in

    if (animateIn) {
        [[self backgroundBlurView] setAlpha:0];
        [[self userAvatar] setAlpha:0];
        [[self usernameLabel] setAlpha:0];
        [[self passcodeEntryView] setAlpha:0];

        if (!enableSpotlightSwitch) {
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:3 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [lockscreenWallpaper setTransform:CGAffineTransformMakeScale(1.05, 1.05)];
            } completion:nil];
        } else {
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:3 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [[coverSheetView diarySpotlightWallpaperView] setTransform:CGAffineTransformMakeScale(1.05, 1.05)];
            } completion:nil];
        }

        [UIView animateWithDuration:0.6 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [[self backgroundBlurView] setAlpha:1];
        } completion:nil];

        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [[self userAvatar] setAlpha:1];
            [[self usernameLabel] setAlpha:1];
            [[self passcodeEntryView] setAlpha:1];
        } completion:nil];
    } else {
        [passcodeLeaveTimer invalidate];
        passcodeLeaveTimer = nil;

        if (!enableSpotlightSwitch) {
            [UIView animateWithDuration:0.5 delay:0.2 usingSpringWithDamping:3 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [lockscreenWallpaper setTransform:CGAffineTransformIdentity];
            } completion:nil];
        } else {
            [UIView animateWithDuration:0.5 delay:0.2 usingSpringWithDamping:3 initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                [[coverSheetView diarySpotlightWallpaperView] setTransform:CGAffineTransformIdentity];
            } completion:nil];
        }
        
        [UIView animateWithDuration:0.25 delay:0.15 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [[self backgroundBlurView] setAlpha:0];
        } completion:nil];

        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [[self userAvatar] setAlpha:0];
            [[self usernameLabel] setAlpha:0];
            [[self passcodeEntryView] setAlpha:0];
        } completion:nil];
    }

}

%new
- (void)updatePasscodeEntryEditingStateStyle { // update the passcode entry field style depending if the user is editing or not

    if ([overridePasscodeStyleValue intValue] == 0) {
        if ([[self passcodeEntryField] isEditing]) {
            [[self passcodeEntryField] setTextColor:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1]];
            if ([[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1]}]];
            else if (![[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"PASSWORD"]] attributes:@{NSForegroundColorAttributeName:[UIColor colorWithRed:0.6 green:0.6 blue:0.6 alpha:1]}]];
            [[self passcodeEntryBlurView] setEffect:nil];
            [[self passcodeEntryBlurView] setBackgroundColor:[UIColor whiteColor]];
        } else {
            [[self passcodeEntryField] setTextColor:[UIColor whiteColor]];
            if ([[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName:[[UIColor whiteColor] colorWithAlphaComponent:0.4]}]];
            else if (![[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"PASSWORD"]] attributes:@{NSForegroundColorAttributeName:[[UIColor whiteColor] colorWithAlphaComponent:0.4]}]];
            [[self passcodeEntryBlurView] setEffect:[self passcodeEntryBlur]];
            [[self passcodeEntryBlurView] setBackgroundColor:[UIColor clearColor]];
        }
    } else if ([overridePasscodeStyleValue intValue] == 1) {
        if ([[self passcodeEntryField] isEditing]) {
            if ([[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
            else if (![[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"PASSWORD"]] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
            [[self passcodeEntryBlurView] setEffect:[self passcodeEntryBlur]];
            [[self passcodeEntryEffectView] setBackgroundColor:[GcColorPickerUtils colorWithHex:passcodeEntryEffectColorValue]];
        } else {
            if ([[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:@"Password" attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
            else if (![[DRYLocalization stringForKey:@"PASSWORD"] isEqual:nil]) [[self passcodeEntryField] setAttributedPlaceholder:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"PASSWORD"]] attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}]];
            [[self passcodeEntryBlurView] setEffect:nil];
            [[self passcodeEntryEffectView] setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0.4]];
        }
    }

}

%new
- (void)attemptManualUnlock { // attempt to unlock the device with the entered passcode

    [passcodeLeaveTimer invalidate];
    passcodeLeaveTimer = nil;

    if ([[%c(SBLockScreenManager) sharedInstance] isUILocked]) [self showIncorrectPasswordView];
    if ((([passcodeTypeValue intValue] == 0 || [passcodeTypeValue intValue] == 1) && [[[self passcodeEntryField] text] length] < 4) || ([passcodeTypeValue intValue] == 2 && [[[self passcodeEntryField] text] length] == 0)) return;
    [[%c(SBLockScreenManager) sharedInstance] attemptUnlockWithPasscode:[NSString stringWithFormat:@"%@", [[self passcodeEntryField] text]] finishUIUnlock:1 completion:nil];
    [[self passcodeEntryField] setText:@""];
    if (![[%c(SBLockScreenManager) sharedInstance] isUILocked]) [[self passcodeEntryField] resignFirstResponder];

}

%new
- (void)attemptAutomaticUnlock { // automatically attempt to unlock if the input is 4 or 6 characters long

    [passcodeLeaveTimer invalidate];
    passcodeLeaveTimer = nil;
    
    if (([passcodeTypeValue intValue] == 0 && [[[self passcodeEntryField] text] length] == 4) || ([passcodeTypeValue intValue] == 1 && [[[self passcodeEntryField] text] length] == 6)) {
        [[%c(SBLockScreenManager) sharedInstance] attemptUnlockWithPasscode:[NSString stringWithFormat:@"%@", [[self passcodeEntryField] text]] finishUIUnlock:1 completion:nil];
        if ([[%c(SBLockScreenManager) sharedInstance] isUILocked]) [self showIncorrectPasswordView];
        [[self passcodeEntryField] setText:@""];
        if (![[%c(SBLockScreenManager) sharedInstance] isUILocked]) [[self passcodeEntryField] resignFirstResponder];
    }

}

%new
- (void)showIncorrectPasswordView { // show the incorrect password view

    if ([[[self passcodeEntryField] text] length] == 0) {
        if ([[DRYLocalization stringForKey:@"PROVIDE_PASSWORD"] isEqual:nil]) [[self incorrectPasswordLabel] setText:@"Provide a PIN."];
        else if (![[DRYLocalization stringForKey:@"PROVIDE_PASSWORD"] isEqual:nil]) [[self incorrectPasswordLabel] setText:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"PROVIDE_PASSWORD"]]];
    } else {
        if ([[DRYLocalization stringForKey:@"INCORRECT_PASSWORD"] isEqual:nil]) [[self incorrectPasswordLabel] setText:@"The password is incorrect. Try again."];
        else if (![[DRYLocalization stringForKey:@"INCORRECT_PASSWORD"] isEqual:nil]) [[self incorrectPasswordLabel] setText:[NSString stringWithFormat:@"%@", [DRYLocalization stringForKey:@"INCORRECT_PASSWORD"]]];
    }
    [[self passcodeEntryField] resignFirstResponder];
    [[self incorrectPasswordLabel] setHidden:NO];
    [[self incorrectPasswordButton] setHidden:NO];
    [[self passcodeEntryView] setHidden:YES];

}

%new
- (void)hideIncorrectPasswordView { // hide the incorrect password view

    [[self passcodeEntryField] setText:@""];
    [[self passcodeEntryField] becomeFirstResponder];
    [[self incorrectPasswordLabel] setHidden:YES];
    [[self incorrectPasswordButton] setHidden:YES];
    [[self passcodeEntryView] setHidden:NO];

}

%new
- (void)dismissKeyboard { // hide the keyboard after tapping anywhere or when unlocking

    if ([[self incorrectPasswordLabel] isHidden] && [[self passcodeEntryField] isEditing]) [[self passcodeEntryField] resignFirstResponder];
    else if ([[self incorrectPasswordLabel] isHidden] && ![[self passcodeEntryField] isEditing]) [self passcodeLockViewCancelButtonPressed:nil];

}

%new
- (void)authenticatedWithBiometrics { // automatically unlock when authenticated with biometrics

    [[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:17 withOptions:nil];

}

%end

%hook SBLockScreenManager

- (void)lockUIFromSource:(int)arg1 withOptions:(id)arg2 { // change wallpaper when locked

	%orig;

    [passcodeLeaveTimer invalidate];
    passcodeLeaveTimer = nil;

}

%end

%hook SBWallpaperViewController

- (void)viewDidLoad { // get an instance of the lock screen wallpaper view

    %orig;

    if (enableSpotlightSwitch) return;
    lockscreenWallpaper = [self lockscreenWallpaperView];

}

%end

%hook CSCoverSheetViewController

- (void)viewWillDisappear:(BOOL)animated { // dismiss keyboard when unlocking

    %orig;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryDismissPasscodeKeyboard" object:nil];

}

%end

%hook SBDashBoardBiometricUnlockController

- (void)setAuthenticated:(BOOL)arg1 { // automatically unlock when authenticated with biometrics

	%orig;

    [passcodeLeaveTimer invalidate];
    passcodeLeaveTimer = nil;
    
	if (arg1) [[NSNotificationCenter defaultCenter] postNotificationName:@"diaryBiometricPasscodeAuthentication" object:nil];

}

%end

%hook CSPasscodeBackgroundView

- (id)initWithFrame:(CGRect)frame { // remove default background blur and dim

	return nil;

}

%end

%hook SBUIPasscodeLockViewWithKeypad

- (void)updateStatusText:(id)arg1 subtitle:(id)arg2 animated:(BOOL)arg3 { // remove default passcode labels

    %orig(nil, nil, NO);

}

%end

%hook SBSimplePasscodeEntryFieldButton

- (void)didMoveToWindow { // remove default passcode entry indicator

	%orig;
	
	[self removeFromSuperview];

}

%end

%hook SBUIPasscodeLockNumberPad

- (void)didMoveToWindow { // remove default passcode keypad

	%orig;
	
	[self removeFromSuperview];

}

%end

%hook SBUIPasscodeBiometricResource

- (BOOL)hasBiometricAuthenticationCapabilityEnabled { // skip faceid animation when swiping up

	return NO;

}

%end

%end

%ctor {

    if ([UIDevice currentIsIPad]) return;

    preferences = [[HBPreferences alloc] initWithIdentifier:@"love.litten.diarypreferences"];
    
    [preferences registerBool:&enabled default:NO forKey:@"Enabled"];
    if (!enabled) return;

    // time and date
    [preferences registerBool:&enableTimeAndDateSwitch default:YES forKey:@"enableTimeAndDate"];
    if (enableTimeAndDateSwitch) {
        [preferences registerObject:&overrideTimeDateStyleValue default:@"0" forKey:@"overrideTimeDateStyle"];
        [preferences registerObject:&timeFormatValue default:@"HH:mm" forKey:@"timeFormat"];
        [preferences registerObject:&dateFormatValue default:@"EEEE, d. MMMM" forKey:@"dateFormat"];
        [preferences registerBool:&useCustomDateLocaleSwitch default:NO forKey:@"useCustomDateLocale"];
        [preferences registerObject:&customDateLocaleValue default:@"" forKey:@"customDateLocale"];
        [preferences registerBool:&enableUpNextSwitch default:NO forKey:@"enableUpNext"];
        if (enableUpNextSwitch) {
            [preferences registerObject:&defaultEventsValue default:@"0" forKey:@"defaultEvents"];
            [preferences registerObject:&eventRangeValue default:@"3" forKey:@"eventRange"];
            [preferences registerBool:&showCalendarEventButtonSwitch default:YES forKey:@"showCalendarEventButton"];
            [preferences registerBool:&showReminderButtonSwitch default:YES forKey:@"showReminderButton"];
            [preferences registerBool:&showAlarmButtonSwitch default:YES forKey:@"showAlarmButton"];
        }
        [preferences registerBool:&showWeatherSwitch default:NO forKey:@"showWeather"];
        [preferences registerBool:&showBatteryIconSwitch default:YES forKey:@"showBatteryIcon"];
        [preferences registerBool:&showBatteryPercentageSwitch default:NO forKey:@"showBatteryPercentage"];
        [preferences registerBool:&showWifiIconSwitch default:YES forKey:@"showWifiIcon"];
        [preferences registerBool:&showCellularIconSwitch default:YES forKey:@"showCellularIcon"];
        [preferences registerBool:&showCellularTypeSwitch default:NO forKey:@"showCellularType"];
        [preferences registerBool:&slideUpToUnlockSwitch default:NO forKey:@"slideUpToUnlock"];
        [preferences registerBool:&bounceOnTapSwitch default:NO forKey:@"bounceOnTap"];
        if (slideUpToUnlockSwitch || bounceOnTapSwitch) [preferences registerObject:&slideUpToUnlockPositionValue default:@"0" forKey:@"slideUpToUnlockPosition"];
        [preferences registerObject:&timeDateColorValue default:@"FFFFFF" forKey:@"timeDateColor"];
        [preferences registerObject:&upNextColorValue default:@"FFFFFF" forKey:@"upNextColor"];
        [preferences registerObject:&connectivityColorValue default:@"FFFFFF" forKey:@"connectivityColor"];
    }

    // hello
    [preferences registerBool:&enableHelloSwitch default:NO forKey:@"enableHello"];
    if (enableHelloSwitch) {
        [preferences registerBool:&showHelloGreetingSwitch default:YES forKey:@"showHelloGreeting"];
        [preferences registerObject:&greetingValue default:@"" forKey:@"greeting"];
    }

    // media player
    [preferences registerBool:&enableMediaPlayerSwitch default:YES forKey:@"enableMediaPlayer"];
    if (enableMediaPlayerSwitch) {
        [preferences registerBool:&artworkTransitionSwitch default:NO forKey:@"artworkTransition"];
        [preferences registerBool:&adaptiveMediaPlayerBackgroundSwitch default:NO forKey:@"adaptiveMediaPlayerBackground"];
        [preferences registerObject:&customMediaPlayerBackgroundColorValue default:@"1A1A1A" forKey:@"customMediaPlayerBackgroundColor"];
        [preferences registerObject:&mediaPlayerBackgroundAmountValue default:@"1" forKey:@"mediaPlayerBackgroundAmount"];
        [preferences registerObject:&mediaPlayerOffsetValue default:@"40" forKey:@"mediaPlayerOffset"];
    }

    // background
    [preferences registerBool:&enableSpotlightSwitch default:NO forKey:@"enableSpotlight"];
    [preferences registerObject:&gradientColorValue default:@"000000" forKey:@"gradientColor"];
    [preferences registerObject:&backgroundGradientAmountValue default:@"0.6" forKey:@"backgroundGradientAmount"];

    // passcode
    [preferences registerBool:&enablePasscodeSwitch default:NO forKey:@"enablePasscode"];
    if (enablePasscodeSwitch) {
        [preferences registerObject:&overridePasscodeStyleValue default:@"0" forKey:@"overridePasscodeStyle"];
        [preferences registerObject:&passcodeTypeValue default:@"1" forKey:@"passcodeType"];
        [preferences registerObject:&usernameValue default:@"User" forKey:@"username"];
        [preferences registerObject:&passcodeEntryEffectColorValue default:@"8580D0" forKey:@"passcodeEntryEffectColor"];
        [preferences registerBool:&automaticallyAttemptToUnlockSwitch default:YES forKey:@"automaticallyAttemptToUnlock"];
        [preferences registerBool:&automaticallyFocusTheEntryFieldSwitch default:YES forKey:@"automaticallyFocusTheEntryField"];
    }

    // miscellaneous
    [preferences registerBool:&useCustomZIndexSwitch default:NO forKey:@"useCustomZIndex"];
    [preferences registerObject:&customZIndexValue default:@"0" forKey:@"customZIndex"];
    [preferences registerObject:&fontFamilyValue default:@"1" forKey:@"fontFamily"];
    [preferences registerObject:&notificationOffsetValue default:@"0" forKey:@"notificationOffset"];
    [preferences registerBool:&hideChargingViewSwitch default:YES forKey:@"hideChargingView"];
    [preferences registerBool:&disableTodaySwipeSwitch default:NO forKey:@"disableTodaySwipe"];
    [preferences registerBool:&disableCameraSwipeSwitch default:NO forKey:@"disableCameraSwipe"];
    [preferences registerBool:&hideNotificationsHeaderSwitch default:YES forKey:@"hideNotificationsHeader"];
    [preferences registerBool:&alwaysShowNotificationsSwitch default:YES forKey:@"alwaysShowNotifications"];
    [preferences registerBool:&hideDefaultStatusBarSwitch default:YES forKey:@"hideDefaultStatusBar"];
    [preferences registerBool:&hideDefaultFaceIDLockSwitch default:YES forKey:@"hideDefaultFaceIDLock"];
    [preferences registerBool:&hideDefaultTimeAndDateSwitch default:YES forKey:@"hideDefaultTimeAndDate"];
    [preferences registerBool:&hideNotificationsHintSwitch default:YES forKey:@"hideNotificationsHint"];
    [preferences registerBool:&hideDefaultQuickActionsSwitch default:YES forKey:@"hideDefaultQuickActions"];
    [preferences registerBool:&hideDefaultUnlockTextSwitch default:YES forKey:@"hideDefaultUnlockText"];
    [preferences registerBool:&hideDefaultHomebarSwitch default:YES forKey:@"hideDefaultHomebar"];
    [preferences registerBool:&hideDefaultPageDotsSwitch default:YES forKey:@"hideDefaultPageDots"];

    %init(DiaryGlobal);
	if (enableTimeAndDateSwitch) %init(DiaryTimeAndDate);
    if (enableHelloSwitch) %init(DiaryHello);
	if (enableMediaPlayerSwitch) %init(DiaryMediaPlayer);
    %init(DiaryBackground);
    if (enablePasscodeSwitch) %init(DiaryPasscode);

}