# wine-host-dlfcn

Compiles a Winelib DLL that provides access to the host's dlfcn functions (`dlopen`, `dlsym`, and `dlclose`). With
these, any host `.so` library may be linked with at runtime from "Windows" code.

