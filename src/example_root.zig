const builtin = @import("builtin");
const std = @import("std");
const testing = std.testing;

export fn add(a: i32, b: i32) callconv(.winapi) i32 {
    return a + b;
}
