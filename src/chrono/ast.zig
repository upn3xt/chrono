const ASTNode = @This();

kind: NodeKind,
data: union(NodeKind) {
    VariableDeclaration: struct { name: []const u8, var_type: ?[]const u8 = null, expression: ?*ASTNode },

    VariableReference: struct {
        name: []const u8,
    },

    NumberLiteral: struct {
        value: i64,
    },

    StringLiteral: struct { value: []const u8 },

    CharLiteral: struct { value: u8 },

    BinaryOperation: struct {
        left: *ASTNode,
        operator: u8,
        right: *ASTNode,
    },

    Assignment: struct {
        variable: *ASTNode,
        asg_type: ?[]const u8 = null,
        expression: *ASTNode,
    },
},

pub const NodeKind = enum { VariableDeclaration, VariableReference, NumberLiteral, StringLiteral, CharLiteral, BinaryOperation, Assignment };
