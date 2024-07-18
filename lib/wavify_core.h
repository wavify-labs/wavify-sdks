#include <cstdarg>
#include <cstdint>
#include <cstdlib>
#include <ostream>
#include <new>

struct SttEngine;

struct FloatArray {
  const float *data;
  uintptr_t len;
};

extern "C" {

SttEngine *create_stt_engine(const char *model_path, const char *api_key);

void destroy_stt_engine(SttEngine *stt_engine);

char *stt(SttEngine *stt_engine, FloatArray data);

void free_result(char *result);

void setup_logger();

jlong Java_dev_wavify_SttEngine_createFfi(JNIEnv env,
                                          JClass,
                                          JString java_model_path,
                                          JString java_api_key,
                                          JString java_app_name);

void Java_dev_wavify_SttEngine_destroyFfi(JNIEnv env, JClass, JString java_model);

jstring Java_dev_wavify_SttEngine_sttFfi(JNIEnv env, JClass, JFloatArray data, jlong java_model);

void Java_dev_wavify_SttEngine_setupLoggerFfi(JNIEnv env, JClass);

} // extern "C"