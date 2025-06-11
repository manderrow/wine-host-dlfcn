#include <dlfcn.h>
#include <windef.h>

void* WINAPI host_dlopen(const char* name, int flags) {
  return dlopen(name, flags);
}

void WINAPI host_dlclose(void* handle) {
  dlclose(handle);
}

void* WINAPI host_dlsym(void* handle, const char* name) {
  return dlsym(handle, name);
}
