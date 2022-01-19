#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import <EventKit/EventKit.h>
#import "libpddokdo.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <MediaRemote/MediaRemote.h>
#import "GcUniversal/GcImagePickerUtils.h"
#import "GcUniversal/GcColorPickerUtils.h"
#import <Kitten/libKitten.h>
#import "../Utils/DRYLocalization.h"
#import <Cephei/HBPreferences.h>

HBPreferences* preferences = nil;
BOOL enabled = NO;


// global
BOOL hasAddedStatusBarObserver = NO;


// time and date
BOOL enableTimeAndDateSwitch = YES;
NSString* overrideTimeDateStyleValue = @"0";
NSString* timeFormatValue = @"HH:mm";
NSString* dateFormatValue = @"EEEE, d. MMMM";
BOOL useCustomDateLocaleSwitch = NO;
NSString* customDateLocaleValue = @"";
BOOL enableUpNextSwitch = NO;
NSString* defaultEventsValue = @"0";
NSString* eventRangeValue = @"3";
BOOL showCalendarEventButtonSwitch = YES;
BOOL showReminderButtonSwitch = YES;
BOOL showAlarmButtonSwitch = YES;
BOOL showWeatherSwitch = NO;
BOOL showBatteryIconSwitch = YES;
BOOL showBatteryPercentageSwitch = NO;
BOOL showWifiIconSwitch = YES;
BOOL showCellularIconSwitch = YES;
BOOL showCellularTypeSwitch = NO;
BOOL slideUpToUnlockSwitch = NO;
BOOL bounceOnTapSwitch = NO;
NSString* slideUpToUnlockPositionValue = @"0";
NSString* timeDateColorValue = @"FFFFFF";
NSString* upNextColorValue = @"FFFFFF";
NSString* connectivityColorValue = @"FFFFFF";

NSTimer* timeAndDateTimer = nil;
CAGradientLayer* notificationMask = nil;
BOOL isBouncing = NO;
BOOL isScreenOnTimeAndDate = YES;
BOOL isTimerRunning = NO;


// media player
BOOL enableMediaPlayerSwitch = YES;
BOOL artworkTransitionSwitch = NO;
BOOL adaptiveMediaPlayerBackgroundSwitch = NO;
NSString* customMediaPlayerBackgroundColorValue = @"1A1A1A";
NSString* mediaPlayerBackgroundAmountValue = @"1";
NSString* mediaPlayerOffsetValue = @"40";

// hello
BOOL enableHelloSwitch = NO;
BOOL showHelloGreetingSwitch = YES;
NSString* greetingValue = @"";

NSMutableArray* helloStartArray = nil;
NSMutableArray* helloSearchingArray = nil;
NSMutableArray* helloAuthenticatedArray = nil;
UIImage* helloStartImage = nil;
UIImage* helloSearchingImage = nil;
UIImage* helloAuthenticatedImage = nil;
BOOL shouldPlaySearchAnimation = YES;
BOOL isLockedHello = YES;
BOOL isScreenOnHello = YES;


// background
BOOL enableSpotlightSwitch = NO;
NSString* gradientColorValue = @"000000";
NSString* backgroundGradientAmountValue = @"0.6";

NSMutableArray* spotlightWallpapers = nil;


// passcode
BOOL enablePasscodeSwitch = NO;
NSString* overridePasscodeStyleValue = @"0";
NSString* passcodeTypeValue = @"1";
NSString* usernameValue = @"User";
NSString* passcodeEntryEffectColorValue = @"8580D0";
BOOL automaticallyAttemptToUnlockSwitch = YES;
BOOL automaticallyFocusTheEntryFieldSwitch = YES;

NSTimer* passcodeLeaveTimer = nil;


// miscellaneous
NSString* overrideStyleValue = @"0";
NSString* fontFamilyValue = @"1";
BOOL useCustomZIndexSwitch = NO;
NSString* customZIndexValue = @"0";
NSString* notificationOffsetValue = @"0";
BOOL hideChargingViewSwitch = YES;
BOOL disableTodaySwipeSwitch = NO;
BOOL disableCameraSwipeSwitch = NO;
BOOL hideNotificationsHeaderSwitch = YES;
BOOL alwaysShowNotificationsSwitch = YES;
BOOL hideDefaultStatusBarSwitch = YES;
BOOL hideDefaultFaceIDLockSwitch = YES;
BOOL hideDefaultTimeAndDateSwitch = YES;
BOOL hideNotificationsHintSwitch = YES;
BOOL hideDefaultQuickActionsSwitch = YES;
BOOL hideDefaultUnlockTextSwitch = YES;
BOOL hideDefaultHomebarSwitch = YES;
BOOL hideDefaultPageDotsSwitch = YES;

@interface SBFLockScreenDateView : UIView
@property(nonatomic, retain)UILabel* diaryTimeLabel;
@property(nonatomic, retain)UILabel* diaryDateLabel;
- (void)layoutTimeAndDate;
- (void)updateDiaryTimeAndDate;
@end

@interface CSCoverSheetView : UIView
@property(nonatomic, retain)UIView* diaryView;
@property(nonatomic, retain)UIView* diaryGestureView;
@property(nonatomic, retain)UIPanGestureRecognizer* panGesture;
@property(nonatomic, retain)UITapGestureRecognizer* tapGesture;
@property(nonatomic, retain)UILabel* diaryTimeLabel;
@property(nonatomic, retain)UILabel* diaryDateLabel;
@property(nonatomic, retain)UILabel* diaryEventTitleLabel;
@property(nonatomic, retain)UILabel* diaryEventSubtitleLabel;
@property(nonatomic, retain)UIButton* diaryCalendarButton;
@property(nonatomic, retain)UIButton* diaryReminderButton;
@property(nonatomic, retain)UIButton* diaryAlarmButton;
@property(nonatomic, retain)UIImageView* diaryBatteryIcon;
@property(nonatomic, retain)UILabel* diaryBatteryPercentageLabel;
@property(nonatomic, retain)UIImageView* diaryWifiIcon;
@property(nonatomic, retain)UIImageView* diaryCellularIcon;
@property(nonatomic, retain)UILabel* diaryCellularTypeLabel;
@property(nonatomic, retain)UIView* diaryHelloView;
@property(nonatomic, retain)UIImageView* diaryHelloIconView;
@property(nonatomic, retain)UILabel* diaryHelloLabel;
@property(nonatomic, retain)UIView* diaryPlayerView;
@property(nonatomic, retain)UIImageView* diaryArtworkView;
@property(nonatomic, retain)UIView* diaryMusicControlsView;
@property(nonatomic, retain)UIButton* diaryRewindButton;
@property(nonatomic, retain)UIButton* diaryPauseButton;
@property(nonatomic, retain)UIButton* diarySkipButton;
@property(nonatomic, retain)UILabel* diarySongTitleLabel;
@property(nonatomic, retain)UILabel* diaryArtistLabel;
@property(nonatomic, retain)CAGradientLayer* diaryGradient;
@property(nonatomic, retain)UIImageView* diarySpotlightWallpaperView;
- (void)updateFrameAfterRotation;
- (void)layoutTimeAndDate;
- (void)updateDiaryTimeAndDate;
- (void)fetchNextCalendarEvent;
- (void)fetchNextReminder;
- (void)fetchNextAlarm;
- (void)updateWeather;
- (void)handleSlideUpToUnlockPan:(UIPanGestureRecognizer *)recognizer;
- (void)resetDiaryViewTransform;
- (void)handleBounceTap:(UITapGestureRecognizer *)recognizer;
- (void)initHelloViewWithAnimation:(int)animation;
- (void)playHelloStartAnimation;
- (void)playHelloSearchingAnimation;
- (void)playHelloAuthenticatedAnimation;
- (void)rewindSong;
- (void)skipSong;
- (void)pausePlaySong;
@end

@interface MTAlarm : NSObject
@property(nonatomic, readonly)NSDate* nextFireDate;
@end

@interface MTAlarmCache : NSObject
@property(nonatomic, retain)MTAlarm* nextAlarm; 
@end

@interface MTAlarmManager : NSObject
@property(nonatomic, retain)MTAlarmCache* cache;
@end

@interface SBScheduledAlarmObserver : NSObject {
    MTAlarmManager* _alarmManager;
}
+ (id)sharedInstance;
@end

@interface CSCoverSheetViewController : UIViewController
- (void)requestDiaryTimeAndDateUpdate;
@end

@interface SBBacklightController : NSObject
- (void)requestDiaryTimeAndDateUpdate;
@end

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
- (BOOL)isLockScreenVisible;
- (BOOL)_isPasscodeVisible;
- (BOOL)isUILocked;
- (BOOL)unlockUIFromSource:(int)arg1 withOptions:(id)arg2;
- (void)attemptUnlockWithPasscode:(id)arg1 finishUIUnlock:(BOOL)arg2 completion:(id)arg3;
@end

@interface _UIStatusBar : UIView
@end

@interface UIStatusBar_Modern : UIView
- (_UIStatusBar *)statusBar;
- (void)receiveHideNotification:(NSNotification *)notification;
@end

@interface SBUIProudLockIconView : UIView
@end

@interface SBUILegibilityLabel : UILabel
@end

@interface SBFLockScreenAlternateDateLabel : UILabel
@end

@interface SBFLockScreenDateSubtitleView : UIView
@end

@interface SBLockScreenTimerDialView : UIView
@end

@interface SBFLockScreenDateSubtitleDateView : UIView
@end

@interface CSTeachableMomentsContainerView : UIView
@end

@interface UILabel (Diary)
- (void)setMarqueeEnabled:(BOOL)arg1;
- (void)setMarqueeRunning:(BOOL)arg1;
@end

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (BOOL)isPlaying;
- (BOOL)isPaused;
- (void)setNowPlayingInfo:(id)arg1;
- (BOOL)changeTrack:(int)arg1 eventSource:(long long)arg2;
- (BOOL)togglePlayPauseForEventSource:(long long)arg1;
@end

@interface CSCombinedListViewController : UIViewController
- (void)layoutListView;
@end

@interface NCNotificationStructuredListViewController : UIViewController
- (void)updateFrameAfterRotation;
@end

@interface SBUIController : NSObject
+ (id)sharedInstance;
- (int)batteryCapacityAsPercentage;
- (BOOL)isOnAC;
@end

@interface SBWiFiManager : NSObject
+ (id)sharedInstance;
- (int)signalStrengthBars;
- (BOOL)isAssociated;
@end

@interface SBAirplaneModeController : NSObject
+ (id)sharedInstance;
- (BOOL)isInAirplaneMode;
@end

@interface CSPasscodeViewController : UIViewController
@property(nonatomic, retain)UIBlurEffect* backgroundBlur;
@property(nonatomic, retain)UIVisualEffectView* backgroundBlurView;
@property(nonatomic, retain)UIImageView* userAvatar;
@property(nonatomic, retain)UILabel* usernameLabel;
@property(nonatomic, retain)UIView* passcodeEntryView;
@property(nonatomic, retain)UIBlurEffect* passcodeEntryBlur;
@property(nonatomic, retain)UIVisualEffectView* passcodeEntryBlurView;
@property(nonatomic, retain)UIView* passcodeEntryEffectView;
@property(nonatomic, retain)UIButton* passcodeEntryConfirmButton;
@property(nonatomic, retain)UITextField* passcodeEntryField;
@property(nonatomic, retain)UILabel* incorrectPasswordLabel;
@property(nonatomic, retain)UIButton* incorrectPasswordButton;
@property(nonatomic, retain)UITapGestureRecognizer* tapGesture;
- (void)leavePasscodeScreenDueToTimeout;
- (void)animatePasscodeScreenIn:(BOOL)animateIn;
- (void)updatePasscodeEntryEditingStateStyle;
- (void)attemptManualUnlock;
- (void)attemptAutomaticUnlock;
- (void)showIncorrectPasswordView;
- (void)hideIncorrectPasswordView;
- (void)dismissKeyboard;
- (void)authenticatedWithBiometrics;
- (void)passcodeLockViewCancelButtonPressed:(id)arg1;
@end

@interface SBFWallpaperView : UIView
@end

@interface SBWallpaperViewController : UIViewController
@property(nonatomic, retain)SBFWallpaperView* lockscreenWallpaperView;
@end

@interface SBSimplePasscodeEntryFieldButton : UIView
@end

@interface SBUIPasscodeLockNumberPad : UIView
@end

@interface _UIStatusBarSignalView : UIView
@property(assign, nonatomic)long long numberOfActiveBars;
@end

@interface _UIStatusBarCellularSignalView : _UIStatusBarSignalView
@end

@interface UIDevice (Diary)
+ (BOOL)currentIsIPad;
@end