const Type = @import("../types/types.zig").Type;
const Data = @import("../object/data.zig");

const Object = @This();

identifier: []const u8,
obtype: Type = undefined,
mutable: bool = false,
data: ?Data,
