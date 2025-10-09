const std = @import("std");
const Builder = @import("../src/chrono/builder/builder.zig");

pub fn main() !void {
    try Builder.build();
}
