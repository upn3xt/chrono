const std = @import("std");
const Import = @import("../imports.zig");

const ASTNode = Import.ASTNode;
const Object = Import.Object;

const Analyzer = @This();

nodes: []*ASTNode,
symbols: std.StringHashMap(Object),

pub const Type = enum { Int, Float, String, Bool, Char };

pub fn init(nodes: []*ASTNode, symbols: std.StringHashMap(Object)) Analyzer {
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
            .Assignment => try self.analyzeAssignment(node),
            else => return error.SomeError,
        }
    }
}

pub fn analyzeVariableDeclaration(self: *Analyzer, node: *ASTNode) !void {
    const name = node.data.VariableDeclaration.name;

    const exp = node.data.VariableDeclaration.expression;

    const var_type = node.data.VariableDeclaration.var_type;

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

    if (var_type == null) {
        node.data.VariableDeclaration.var_type = exp_type;
    } else if (var_type.? != exp_type) return error.TypeMismatch;
}

pub fn analyzeAssignment(self: *Analyzer, node: *ASTNode) !void {
    const asg_type = node.data.Assignment.asg_type;
    const variable = node.data.Assignment.variable;

    const varvar = switch (variable.kind) {
        .VariableReference => variable.*.data.VariableReference,
        else => unreachable,
    };
    if (self.symbols.get(varvar.name)) |var_type| {
        if (varvar.mutable == true) {
            if (var_type != asg_type) {
                std.debug.print("Type TypeMismatch!\n", .{});
                return error.TypeMismatchError;
            }
        } else {
            std.debug.print("{}\n", .{varvar.mutable});
            std.debug.print("Error, trying to asign value to a constant: {s}\n", .{varvar.name});
            return error.AssignToConstantError;
        }
    } else {
        std.debug.print("Variable {s} doesnt exist!\n", .{varvar.name});
        return error.UndefinedVariable;
    }
}
