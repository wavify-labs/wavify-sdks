#include <cstdarg>
#include <cstdint>
#include <cstdlib>
#include <ostream>
#include <new>

/// A whisper model with a tokenizer.
struct Whisper;

struct StringArray {
  char *const *data;
  uintptr_t len;
};

struct FloatArray {
  const float *data;
  uintptr_t len;
};

extern "C" {

Whisper *create_model(const char *model_path);

void destroy_model(Whisper *model);

StringArray process(const Whisper *model, FloatArray data);

} // extern "C"
