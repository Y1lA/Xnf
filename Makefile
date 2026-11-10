export TARGET = iphone:clang:latest:15.0
export ARCHS = arm64

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = XnfAlMufakkir

XnfAlMufakkir_FILES = $(wildcard *.m)
XnfAlMufakkir_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore PencilKit PDFKit
XnfAlMufakkir_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-unused-parameter

include $(THEOS_MAKE_PATH)/application.mk
