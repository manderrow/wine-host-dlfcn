const std = @import("std");

const dlfcns_lib = @import("dlfcn");

pub fn main() !void {
    const dlfcns = try dlfcns_lib.init(std.unicode.utf8ToUtf16LeStringLiteral("zig-out/lib/host_dlfcn.dll.so"));
    defer dlfcns.deinit();

    const example = dlfcns.dlopen("zig-out/lib/libexample.so", .{ .LAZY = true }) orelse @panic("Failed to load libexample.so");
    defer dlfcns.dlclose(example);

    const add: *const fn (a: i32, b: i32) callconv(.winapi) i32 = @ptrCast(dlfcns.dlsym(example, "add") orelse {
        std.debug.panic("Could not locate \"add\" in libexample: {?s}", .{std.mem.span(dlfcns.dlerror())});
    });
    const n = add(9, 12);
    try std.testing.expectEqual(21, n);
}

test {
    try main();
}
