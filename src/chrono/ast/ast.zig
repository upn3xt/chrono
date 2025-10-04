const Import = @import("../imports.zig");

const Analyzer = Import.Analyzer;

const Type = Import.Types.Types;

const ASTNode = @This();

kind: NodeKind,
data: union(NodeKind) {
    VariableDeclaration: struct {
        name: []const u8,
        var_type: Type,
        expression: ?*ASTNode,
        mutable: bool,
    },

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
        asg_type: ?Type = null,
        expression: *ASTNode,
    },

    FunctionDeclaration: struct {
        name: []const u8,
        fn_type: Type,
        body: []ASTNode,
        parameters: ?[]*ASTNode = null,
        value: ?[]const u8 = null,
    },

    FunctionReference: struct { name: []const u8, arguments: ?[]ASTNode = null },

    Parameter: struct {
        name: []const u8,
        par_type: Type,
    },
},

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
};
