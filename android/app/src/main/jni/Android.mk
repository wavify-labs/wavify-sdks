LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := com.example.wavify

# Add your dynamic library
LOCAL_SHARED_LIBRARIES := wavify_core

include $(BUILD_EXECUTABLE)