#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

struct SttEngine;

struct FloatArray {
  const float *data;
  uintptr_t len;
};

struct SttEngine *create_stt_engine(const char *model_path, const char *api_key);

void destroy_stt_engine(struct SttEngine *stt_engine);

char *stt(struct SttEngine *stt_engine, struct FloatArray data);

void free_result(char *result);

void setup_logger();
