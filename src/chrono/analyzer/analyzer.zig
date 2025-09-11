const std = @import("std");
const Import = @import("../imports.zig");

const ASTNode = Import.ASTNode;

const Analyzer = @This();

nodes: []*ASTNode,
symbols: std.StringHashMap(Type),

pub const Type = enum { Int, Float, String, Bool, Char };

pub fn init(nodes: []*ASTNode, symbols: std.StringHashMap(Type)) Analyzer {
    return Analyzer{ .nodes = nodes, .symbols = symbols };
}

pub fn analyzer(self: *Analyzer) !void {
    var index: usize = 0;
    while (true) : (index += 1) {
        if (index == self.nodes.len) break;
        const node = self.nodes[index];
        switch (node.kind) {
            .VariableDeclaration => {
                try self.analyzeVariableDeclaration(node);
            },
            .Assignment => {},
            else => return error.SomeError,
        }
    }
}

pub fn analyzeVariableDeclaration(self: *Analyzer, node: *ASTNode) !void {
    const name = node.data.VariableDeclaration.name;

    const exp = node.data.VariableDeclaration.expression;

    var exp_type: Type = undefined;

    if (exp == null) {
        std.debug.print("Error, expression node for variable {s} is null.", .{name});
        return error.ExpressionNodeNullError;
    }
    switch (exp.?.kind) {
        .NumberLiteral => {
            exp_type = .Int;
        },
        .StringLiteral => {
            exp_type = .String;
        },
        .CharLiteral => {
            exp_type = .Char;
        },
        else => return error.InvalidType,
    }

    if (self.symbols.get(name)) |_| {
        std.debug.print("Variable already declared.\n", .{});
        return error.RedeclarationError;
    }

    try self.symbols.put(name, exp_type);

    // node.data.VariableDeclaration.var_type = exp_type;
}
