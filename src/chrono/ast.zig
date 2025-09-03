const ASTNode = @This();

kind: NodeKind,
data: union(NodeKind) {
    VariableDeclaration: struct { name: []const u8, var_type: ?[]const u8 = null, expression: ?*ASTNode, mutable: bool = false },

    VariableReference: struct { name: []const u8, mutable: bool = false },

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

    FunctionDeclaration: struct {
        name: []const u8,
        fn_type: []const u8,
        body: []*ASTNode,
    },

    FunctionReference: struct { name: []const u8 },
},

pub const NodeKind = enum { VariableDeclaration, VariableReference, NumberLiteral, StringLiteral, CharLiteral, BinaryOperation, Assignment, FunctionDeclaration, FunctionReference };
