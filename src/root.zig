const std = @import("std");

handle: std.os.windows.HMODULE,

dlopen_fn: *const HostDlOpen,
dlclose_fn: *const HostDlClose,
dlsym_fn: *const HostDlSym,
dlerror_fn: *const HostDlError,

const Dlfcns = @This();

pub const Library = struct {
    handle: Handle,

    pub const Handle = *opaque {};
};

pub const HostDlOpen = fn (name: [*:0]const u8, flags: RTLD) callconv(.c) ?Library.Handle;
pub const HostDlClose = fn (handle: Library.Handle) callconv(.c) void;
pub const HostDlSym = fn (handle: Library.Handle, name: [*:0]const u8) callconv(.c) ?*anyopaque;
pub const HostDlError = fn () callconv(.c) ?[*:0]u8;

pub const RTLD = packed struct(u32) {
    LAZY: bool = false,
    NOW: bool = false,
    _: u30 = 0,
};

pub fn init(name: [*:0]const u16) !Dlfcns {
    const module = kernel32.LoadLibraryW(name) orelse switch (std.os.windows.GetLastError()) {
        .FILE_NOT_FOUND, .PATH_NOT_FOUND, .MOD_NOT_FOUND => return error.FileNotFound,
        else => |err| return std.os.windows.unexpectedError(err),
    };
    return .{
        .handle = module,

        .dlopen_fn = @ptrCast(kernel32.GetProcAddress(module, "host_dlopen") orelse return error.FunctionNotFound),
        .dlclose_fn = @ptrCast(kernel32.GetProcAddress(module, "host_dlclose") orelse return error.FunctionNotFound),
        .dlsym_fn = @ptrCast(kernel32.GetProcAddress(module, "host_dlsym") orelse return error.FunctionNotFound),
        .dlerror_fn = @ptrCast(kernel32.GetProcAddress(module, "host_dlerror") orelse return error.FunctionNotFound),
    };
}

pub fn deinit(self: Dlfcns) void {
    std.debug.assert(kernel32.FreeLibrary(self.handle).toBool());
}

pub fn dlopen(self: Dlfcns, name: [*:0]const u8, flags: RTLD) ?Library {
    return .{ .handle = self.dlopen_fn(name, flags) orelse return null };
}

pub fn dlsym(self: Dlfcns, library: Library, name: [*:0]const u8) ?*anyopaque {
    return self.dlsym_fn(library.handle, name);
}

pub fn dlclose(self: Dlfcns, library: Library) void {
    self.dlclose_fn(library.handle);
}

pub fn dlerror(self: Dlfcns) ?[*:0]u8 {
    return self.dlerror_fn();
}

// the standard library no longer binds kernel32
const kernel32 = struct {
    extern "kernel32" fn LoadLibraryW(lpLibFileName: [*:0]const u16) callconv(.winapi) ?std.os.windows.HMODULE;
    extern "kernel32" fn GetProcAddress(hModule: std.os.windows.HMODULE, lpProcName: [*:0]const u8) callconv(.winapi) ?*anyopaque;
    extern "kernel32" fn FreeLibrary(hLibModule: std.os.windows.HMODULE) callconv(.winapi) std.os.windows.BOOL;
};
