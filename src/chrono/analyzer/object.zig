const Import = @import("../imports.zig");
const Types = Import.Types.Types;

const Object = @This();

identifier: []const u8,
obtype: Types = undefined,
mutable: ?bool = null,
