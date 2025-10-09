// const Types = @import("../types/types.zig").Types;
const Type = @import("../ast/ast.zig").Type;

const Object = @This();

identifier: []const u8,
obtype: Type = undefined,
mutable: ?bool = null,
