pub const Type = @import("../types/types.zig").Type;
pub const ASTNode = struct {
    kind: NodeKind,
    data: union(NodeKind) {
        VariableDeclaration: struct {
            name: []const u8,
            var_type: Type,
            expression: *ASTNode,
            mutable: bool,
        },

        VariableReference: struct { name: []const u8, var_type: Type, mutable: bool = false },

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
            asg_type: Type,
            expression: *ASTNode,
        },

        FunctionDeclaration: struct {
            name: []const u8,
            fn_type: Type,
            body: []*ASTNode,
            parameters: []*ASTNode,
            value: []const u8,
        },

        FunctionReference: struct { name: []const u8, arguments: []*ASTNode },

        Parameter: struct {
            name: []const u8,
            par_type: Type,
        },

        Return: struct {
            value: *ASTNode,
        },
        Undefined: struct {},
    },
};

pub const NodeKind = enum {
    VariableDeclaration,
    VariableReference,
    NumberLiteral,
    StringLiteral,
    CharLiteral,
    BinaryOperation,
    Assignment,
    FunctionDeclaration,
    FunctionReference,
    Parameter,
    Return,
    Undefined,
};
