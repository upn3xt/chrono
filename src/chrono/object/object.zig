const Type = @import("../types/types.zig").Type;

const Object = @This();

identifier: []const u8,
obtype: Type = undefined,
mutable: ?bool = null,
