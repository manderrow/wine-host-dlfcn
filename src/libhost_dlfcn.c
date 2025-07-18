#include <dlfcn.h>

void* host_dlopen(const char* name, int flags) {
  return dlopen(name, flags);
}

void host_dlclose(void* handle) {
  dlclose(handle);
}

void* host_dlsym(void* handle, const char* name) {
  return dlsym(handle, name);
}
