const std = @import("std");
const Import = @import("chrono/imports.zig");
const Builder = Import.Builder;

pub fn main() !void {
    try Builder.build();
}
