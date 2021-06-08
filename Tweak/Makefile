TWEAK_NAME = DiaryiPhone DiaryiPad

DiaryiPhone_FILES = iPhone/Diary.x DRYLocalization.m
DiaryiPhone_CFLAGS = -fobjc-arc -DTHEOS_LEAN_AND_MEAN
DiaryiPhone_FRAMEWORKS = UIKit CoreText CoreTelephony EventKit
DiaryiPhone_PRIVATE_FRAMEWORKS = MediaRemote
DiaryiPhone_LIBRARIES = gcuniversal pddokdo

DiaryiPad_FILES = iPad/Diary.x DRYLocalization.m
DiaryiPad_CFLAGS = -fobjc-arc -DTHEOS_LEAN_AND_MEAN
DiaryiPad_FRAMEWORKS = UIKit CoreText CoreTelephony EventKit
DiaryiPad_PRIVATE_FRAMEWORKS = MediaRemote
DiaryiPad_LIBRARIES = gcuniversal pddokdo

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
