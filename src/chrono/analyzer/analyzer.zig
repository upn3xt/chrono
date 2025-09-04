const std = @import("std");
const Import = @import("../imports.zig");

const ASTNode = Import.ASTNode;

const Analyzer = @This();

pub const Type = enum { Int, Float, String, Bool };

pub fn analyzeVariableDeclaration(
    symbols: *std.StringHashMap(Type),
    node: *ASTNode,
) !void {
    // Assume node.kind == .VariableDeclaration
    const name = node.data.VariableDeclaration.name;
    const expr_node = node.data.VariableDeclaration.expression;

    // Type inference from expression node
    var expr_type: Type = undefined;
    switch (expr_node.?.kind) {
        .NumberLiteral => expr_type = Type.Int,
        // add other cases (FloatLiteral, StringLiteral, etc.)
        else => return error.InvalidType,
    }

    // Check redeclaration
    if (symbols.get(name)) |x| {
        _ = x;
        return error.DuplicateDeclaration;
    }

    // Add to symbol table
    try symbols.put(name, expr_type);

    // Optionally annotate node type for codegen
    // node.annotation_type = expr_type; (requires field added to ASTNode)
}
